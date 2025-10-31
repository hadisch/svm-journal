# =============================================================================
# Eintrag-Löschen-Funktionalität
# Ermöglicht das Löschen von Journal-Einträgen aus dem Hauptfenster
# =============================================================================

# Globale Variable für den ausgewählten Eintrag
set ::ausgewaehlter_eintrag ""

# =============================================================================
# Prozedur: zeige_kontext_menu
# Zeigt ein Kontextmenü beim Rechtsklick auf einen Eintrag
# Parameter:
#   x, y - Koordinaten des Mausklicks
# =============================================================================
proc zeige_kontext_menu {x y} {
    # Treeview-Widget
    set tree .main.tree

    # Eintrag an der Klickposition ermitteln
    set item [$tree identify item $x $y]

    # Wenn kein Eintrag geklickt wurde, abbrechen
    if {$item eq ""} {
        return
    }

    # Eintrag auswählen (visuelles Feedback)
    $tree selection set $item

    # Ausgewählten Eintrag global speichern
    set ::ausgewaehlter_eintrag $item

    # Kontextmenü erstellen (falls noch nicht vorhanden)
    if {![winfo exists .context_menu]} {
        menu .context_menu -tearoff 0
        .context_menu add command -label "Löschen" -command {loesche_ausgewaehlten_eintrag}
    }

    # Kontextmenü an Mausposition anzeigen
    tk_popup .context_menu [winfo pointerx .] [winfo pointery .]
}

# =============================================================================
# Prozedur: loesche_ausgewaehlten_eintrag
# Löscht den aktuell ausgewählten Eintrag nach Bestätigung
# =============================================================================
proc loesche_ausgewaehlten_eintrag {} {
    global script_dir

    # Prüfen ob ein Eintrag ausgewählt ist
    if {$::ausgewaehlter_eintrag eq ""} {
        return
    }

    # Treeview-Widget
    set tree .main.tree

    # Daten des ausgewählten Eintrags holen
    set values [$tree item $::ausgewaehlter_eintrag -values]

    # Einzelne Felder extrahieren
    lassign $values datum nachname vorname kw lw typ kaliber startgeld munition munpreis

    # Sicherheitsabfrage anzeigen
    set antwort [tk_messageBox -icon question \
                                -type yesno \
                                -title "Eintrag löschen" \
                                -message "Diesen Eintrag wirklich löschen?\n\nDatum: $datum\nName: $nachname, $vorname\nKaliber: $kaliber"]

    # Wenn "Nein" geklickt wurde, abbrechen
    if {$antwort eq "no"} {
        return
    }

    # Jahr aus dem Datum extrahieren (Format: DD.MM.YYYY)
    if {[regexp {^\d{2}\.\d{2}\.(\d{4})$} $datum -> jahr]} {
        # Jahr erfolgreich extrahiert
    } else {
        tk_messageBox -icon error -title "Fehler" \
            -message "Ungültiges Datumsformat. Eintrag konnte nicht gelöscht werden."
        return
    }

    # Aktuelles Jahr ermitteln (für Prüfung ob Archiv)
    set aktuelles_jahr [clock format [clock seconds] -format "%Y"]

    # Pfad zur Jahres-JSON-Datei bestimmen
    if {$jahr < $aktuelles_jahr} {
        # Archiv-Datei
        set archiv_dir [::pfad::get_archiv_directory]
        set jahres_json [file join $archiv_dir "${jahr}.json"]
    } else {
        # Aktuelle Datei
        set jahres_json [::pfad::get_jahres_json_path $jahr]
    }

    # Prüfen ob die Datei existiert
    if {![file exists $jahres_json]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "JSON-Datei für Jahr $jahr nicht gefunden:\n$jahres_json"
        return
    }

    # Backup erstellen
    set backup_dir [::pfad::get_backups_directory]
    if {![file exists $backup_dir]} {
        file mkdir $backup_dir
    }

    # Backup-Dateiname mit Zeitstempel
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set backup_file [file join $backup_dir "[file tail $jahres_json].${timestamp}.bak"]

    # JSON-Datei als Backup kopieren
    file copy -force $jahres_json $backup_file

    # Alle Einträge aus der Datei laden
    set alle_eintraege [::neuer_eintrag::lade_eintraege_aus_datei $jahres_json]

    # Zu löschenden Eintrag finden und entfernen
    set neue_eintraege [list]
    set eintrag_gefunden 0

    foreach eintrag $alle_eintraege {
        # Prüfen ob dies der zu löschende Eintrag ist
        # Vergleich: Datum, Nachname, Vorname, Kaliber
        set e_datum [dict get $eintrag datum]
        set e_nachname [dict get $eintrag nachname]
        set e_vorname [dict get $eintrag vorname]
        set e_kaliber [dict get $eintrag kaliber]

        if {$e_datum eq $datum && $e_nachname eq $nachname && $e_vorname eq $vorname && $e_kaliber eq $kaliber} {
            # Dies ist der zu löschende Eintrag - nicht zur neuen Liste hinzufügen
            set eintrag_gefunden 1
        } else {
            # Eintrag behalten
            lappend neue_eintraege $eintrag
        }
    }

    # Prüfen ob Eintrag gefunden wurde
    if {!$eintrag_gefunden} {
        tk_messageBox -icon warning -title "Warnung" \
            -message "Eintrag konnte in der JSON-Datei nicht gefunden werden."
        return
    }

    # JSON-Datei neu schreiben
    schreibe_eintraege_json $jahres_json $neue_eintraege

    # Treeview aktualisieren
    aktualisiere_treeview

    # Erfolgs-Meldung
    tk_messageBox -icon info -title "Löschen erfolgreich" \
        -message "Der Eintrag wurde erfolgreich gelöscht.\n\nEin Backup wurde erstellt unter:\n$backup_file"

    # Auswahl zurücksetzen
    set ::ausgewaehlter_eintrag ""
}

# =============================================================================
# Prozedur: schreibe_eintraege_json
# Schreibt eine Liste von Einträgen in eine JSON-Datei
# Parameter:
#   dateiPfad - Pfad zur JSON-Datei
#   eintraege - Liste von Eintrags-Dictionaries
# =============================================================================
proc schreibe_eintraege_json {dateiPfad eintraege} {
    # Einträge nach Datum sortieren (älteste zuerst)
    set eintraege [lsort -command {::neuer_eintrag::vergleiche_eintraege} $eintraege]

    # JSON-Datei schreiben
    set lines [list]
    lappend lines "\{"
    lappend lines "  \"eintraege\": \["

    set anzahl [llength $eintraege]
    set counter 0

    foreach entry $eintraege {
        lappend lines "    \{"
        lappend lines "      \"datum\": \"[dict get $entry datum]\","
        lappend lines "      \"uhrzeit\": \"[dict get $entry uhrzeit]\","
        lappend lines "      \"nachname\": \"[dict get $entry nachname]\","
        lappend lines "      \"vorname\": \"[dict get $entry vorname]\","
        lappend lines "      \"kurzwaffe\": \"[dict get $entry kurzwaffe]\","
        lappend lines "      \"langwaffe\": \"[dict get $entry langwaffe]\","
        lappend lines "      \"waffentyp\": \"[dict get $entry waffentyp]\","
        lappend lines "      \"kaliber\": \"[dict get $entry kaliber]\","
        lappend lines "      \"startgeld\": \"[dict get $entry startgeld]\","
        lappend lines "      \"munition\": \"[dict get $entry munition]\","
        lappend lines "      \"munitionspreis\": \"[dict get $entry munitionspreis]\""

        incr counter
        if {$counter < $anzahl} {
            lappend lines "    \},"
        } else {
            lappend lines "    \}"
        }
    }

    lappend lines "  \],"

    set timestamp [clock format [clock seconds] -format "%d.%m.%Y, %H:%M:%S"]
    lappend lines "  \"erstellt_am\": \"$timestamp\","
    lappend lines "  \"anzahl\": $anzahl"
    lappend lines "\}"

    set json_content [join $lines "\n"]

    # Datei schreiben
    set fp [open $dateiPfad w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp
}

# =============================================================================
# Prozedur: aktualisiere_treeview
# Aktualisiert das Treeview im Hauptfenster
# Lädt alle Einträge neu und zeigt sie an
# =============================================================================
proc aktualisiere_treeview {} {
    # Treeview-Widget
    set tree .main.tree

    # Alle Einträge aus dem Treeview löschen
    $tree delete [$tree children {}]

    # Einträge neu laden (sortiert)
    lade_existierende_eintraege
}
