# =============================================================================
# Export-Dialog für Markdown und HTML Export
# Ermöglicht den Export von Journal-Einträgen in verschiedene Formate
# =============================================================================

# Namespace für Export-Funktionalität
namespace eval ::export {
    # Dialog-Variablen
    variable fenster ""
    variable export_format ""

    # Zeitraum-Auswahl
    variable zeitraum_modus "alles"  ;# "alles" oder "zeitraum"
    variable von_datum ""
    variable bis_datum ""

    # Personen-Filter
    variable person_modus "alle"  ;# "alle" oder "person"
    variable person_suche ""
    variable person_ausgewaehlt ""

    # Mitgliederliste für Suche
    variable mitglieder_liste [list]

    # Autovervollständigungs-Listbox
    variable person_listbox ""
    variable person_listbox_visible 0
}

# =============================================================================
# Prozedur: lade_mitglieder_fuer_suche
# Lädt die Mitgliederliste für die Personensuche
# =============================================================================
proc ::export::lade_mitglieder_fuer_suche {} {
    variable mitglieder_liste
    global mitglieder_json

    # Liste leeren
    set mitglieder_liste [list]

    # Prüfen, ob Datei existiert
    if {![file exists $mitglieder_json]} {
        return
    }

    # Datei öffnen und parsen
    set fp [open $mitglieder_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Mitglieder extrahieren (Nachname und Vorname)
    set lines [split $json_content "\n"]
    set aktueller_nachname ""
    set aktueller_vorname ""

    foreach line $lines {
        # Nachname extrahieren
        if {[regexp {"nachname":\s*"([^"]*)"} $line -> nachname]} {
            set aktueller_nachname [string trim $nachname]
        }
        # Vorname extrahieren
        if {[regexp {"vorname":\s*"([^"]*)"} $line -> vorname]} {
            set aktueller_vorname [string trim $vorname]

            # Wenn beide vorhanden, zur Liste hinzufügen
            if {$aktueller_nachname ne "" && $aktueller_vorname ne ""} {
                lappend mitglieder_liste "$aktueller_nachname, $aktueller_vorname"
                set aktueller_nachname ""
                set aktueller_vorname ""
            }
        }
    }

    # Liste alphabetisch sortieren
    set mitglieder_liste [lsort -dictionary $mitglieder_liste]
}

# =============================================================================
# Prozedur: person_suche_geaendert
# Wird aufgerufen, wenn sich die Personensuche ändert
# Zeigt passende Mitglieder in einer Listbox an
# =============================================================================
proc ::export::person_suche_geaendert {args} {
    variable person_suche
    variable person_listbox
    variable person_listbox_visible
    variable mitglieder_liste
    variable fenster

    # Wenn Suchfeld leer, Listbox ausblenden
    if {$person_suche eq ""} {
        if {$person_listbox_visible} {
            pack forget $person_listbox
            set person_listbox_visible 0
        }
        return
    }

    # Suche nach passenden Mitgliedern
    set matches [list]
    set suchbegriff_lower [string tolower $person_suche]

    foreach mitglied $mitglieder_liste {
        # Case-insensitive Matching
        if {[string match -nocase "*${suchbegriff_lower}*" [string tolower $mitglied]]} {
            lappend matches $mitglied
        }
    }

    # Listbox aktualisieren
    $person_listbox delete 0 end
    foreach match $matches {
        $person_listbox insert end $match
    }

    # Listbox anzeigen, wenn Treffer vorhanden
    if {[llength $matches] > 0} {
        if {!$person_listbox_visible} {
            pack $person_listbox -in $fenster.person_frame.person_content -side bottom -fill x -after $fenster.person_frame.person_content.entry
            set person_listbox_visible 1
        }
    } else {
        # Keine Treffer - ausblenden
        if {$person_listbox_visible} {
            pack forget $person_listbox
            set person_listbox_visible 0
        }
    }
}

# =============================================================================
# Prozedur: person_ausgewaehlt
# Wird aufgerufen, wenn ein Mitglied aus der Listbox ausgewählt wird
# =============================================================================
proc ::export::person_ausgewaehlt {args} {
    variable person_suche
    variable person_ausgewaehlt
    variable person_listbox
    variable person_listbox_visible

    # Aktuell ausgewählten Eintrag holen
    set selection [$person_listbox curselection]
    if {$selection eq ""} {
        return
    }

    set selected_person [$person_listbox get $selection]
    set person_suche $selected_person
    set person_ausgewaehlt $selected_person

    # Listbox ausblenden
    pack forget $person_listbox
    set person_listbox_visible 0
}

# =============================================================================
# Prozedur: pruefe_export_button
# Prüft, ob der Export-Button aktiviert werden kann
# Aktivierung erfolgt wenn: "Alles" gewählt ODER "Zeitraum" mit beiden Datumsfeldern
# =============================================================================
proc ::export::pruefe_export_button {args} {
    variable fenster
    variable zeitraum_modus
    variable von_datum
    variable bis_datum

    set button_aktivieren 0

    # Prüfen ob Export-Button aktiviert werden kann
    if {$zeitraum_modus eq "alles"} {
        # "Alles exportieren" ist gewählt - Button aktivieren
        set button_aktivieren 1
    } elseif {$zeitraum_modus eq "zeitraum"} {
        # "Zeitraum" ist gewählt - prüfen ob beide Datumsfelder ausgefüllt sind
        if {[string trim $von_datum] ne "" && [string trim $bis_datum] ne ""} {
            set button_aktivieren 1
        }
    }

    # Button aktivieren oder deaktivieren
    if {$button_aktivieren} {
        $fenster.button_frame.export configure -state normal
    } else {
        $fenster.button_frame.export configure -state disabled
    }
}

# =============================================================================
# Prozedur: zeitraum_modus_geaendert
# Wird aufgerufen, wenn der Zeitraum-Modus geändert wird
# Aktiviert/Deaktiviert die Datumsfelder je nach Auswahl
# =============================================================================
proc ::export::zeitraum_modus_geaendert {args} {
    variable fenster
    variable zeitraum_modus

    if {$zeitraum_modus eq "alles"} {
        # Datumsfelder deaktivieren
        $fenster.zeitraum_frame.zeitraum_content.von_entry configure -state disabled
        $fenster.zeitraum_frame.zeitraum_content.bis_entry configure -state disabled
    } else {
        # Datumsfelder aktivieren
        $fenster.zeitraum_frame.zeitraum_content.von_entry configure -state normal
        $fenster.zeitraum_frame.zeitraum_content.bis_entry configure -state normal
    }

    # Export-Button-Status prüfen
    pruefe_export_button
}

# =============================================================================
# Prozedur: person_modus_geaendert
# Wird aufgerufen, wenn der Personen-Modus geändert wird
# Aktiviert/Deaktiviert das Suchfeld je nach Auswahl
# =============================================================================
proc ::export::person_modus_geaendert {args} {
    variable fenster
    variable person_modus

    if {$person_modus eq "alle"} {
        # Suchfeld deaktivieren
        $fenster.person_frame.person_content.entry configure -state disabled
    } else {
        # Suchfeld aktivieren
        $fenster.person_frame.person_content.entry configure -state normal
        focus $fenster.person_frame.person_content.entry
    }
}

# =============================================================================
# Prozedur: lade_alle_eintraege
# Lädt alle Einträge aus den JSON-Dateien (daten/ und daten/archiv/)
# Rückgabe: Liste von Eintrags-Dictionaries
# =============================================================================
proc ::export::lade_alle_eintraege {} {
    global script_dir

    # Liste für alle Einträge
    set alle_eintraege [list]

    # Daten-Verzeichnis
    set daten_dir [file join $script_dir daten]

    # Archiv-Verzeichnis
    set archiv_dir [file join $script_dir daten archiv]

    # Alle JSON-Dateien im daten-Verzeichnis laden
    if {[file exists $daten_dir]} {
        foreach datei [glob -nocomplain -directory $daten_dir *.json] {
            # Nur Jahres-JSON-Dateien laden (nicht mitglieder.json)
            if {[file tail $datei] ne "mitglieder.json"} {
                set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]
                set alle_eintraege [concat $alle_eintraege $eintraege]
            }
        }
    }

    # Alle JSON-Dateien im archiv-Verzeichnis laden
    if {[file exists $archiv_dir]} {
        foreach datei [glob -nocomplain -directory $archiv_dir *.json] {
            set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]
            set alle_eintraege [concat $alle_eintraege $eintraege]
        }
    }

    # Nach Datum und Uhrzeit sortieren
    set alle_eintraege [lsort -command {::neuer_eintrag::vergleiche_eintraege} $alle_eintraege]

    return $alle_eintraege
}

# =============================================================================
# Prozedur: filtere_eintraege
# Filtert Einträge nach Zeitraum und optional nach Person
# Parameter:
#   eintraege - Liste von Eintrags-Dictionaries
# Rückgabe: Gefilterte Liste von Eintrags-Dictionaries
# =============================================================================
proc ::export::filtere_eintraege {eintraege} {
    variable zeitraum_modus
    variable von_datum
    variable bis_datum
    variable person_modus
    variable person_suche

    set gefilterte_eintraege [list]

    foreach eintrag $eintraege {
        set eintrag_behalten 1

        # Zeitraum-Filter anwenden
        if {$zeitraum_modus eq "zeitraum"} {
            set datum [dict get $eintrag datum]

            # Datum in vergleichbares Format konvertieren (YYYYMMDD)
            if {[regexp {^(\d{2})\.(\d{2})\.(\d{4})$} $datum -> tag monat jahr]} {
                set datum_vgl "${jahr}${monat}${tag}"
            } else {
                # Ungültiges Datum - überspringen
                continue
            }

            # Von-Datum prüfen
            if {[regexp {^(\d{2})\.(\d{2})\.(\d{4})$} $von_datum -> tag monat jahr]} {
                set von_vgl "${jahr}${monat}${tag}"
                if {$datum_vgl < $von_vgl} {
                    set eintrag_behalten 0
                }
            }

            # Bis-Datum prüfen
            if {[regexp {^(\d{2})\.(\d{2})\.(\d{4})$} $bis_datum -> tag monat jahr]} {
                set bis_vgl "${jahr}${monat}${tag}"
                if {$datum_vgl > $bis_vgl} {
                    set eintrag_behalten 0
                }
            }
        }

        # Personen-Filter anwenden
        if {$person_modus eq "person" && $person_suche ne ""} {
            set nachname [dict get $eintrag nachname]
            set vorname [dict get $eintrag vorname]
            set person_string "$nachname, $vorname"

            # Case-insensitive Vergleich
            if {[string tolower $person_string] ne [string tolower $person_suche]} {
                set eintrag_behalten 0
            }
        }

        # Eintrag zur gefilterten Liste hinzufügen
        if {$eintrag_behalten} {
            lappend gefilterte_eintraege $eintrag
        }
    }

    return $gefilterte_eintraege
}

# =============================================================================
# Prozedur: erstelle_markdown_tabelle
# Konvertiert Einträge in eine Markdown-Tabelle
# Parameter:
#   eintraege - Liste von Eintrags-Dictionaries
# Rückgabe: Markdown-String
# =============================================================================
proc ::export::erstelle_markdown_tabelle {eintraege} {
    # Markdown-Tabellen-Header erstellen
    set markdown "# SVM Journal Export\n\n"
    append markdown "Exportiert am: [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]\n\n"
    append markdown "| Datum | Nachname | Vorname | KW | LW | Typ | Kaliber | Startgeld | Munition | Mun.Preis |\n"
    append markdown "|-------|----------|---------|----|----|-----|---------|-----------|----------|----------|\n"

    # Einträge zur Tabelle hinzufügen
    foreach eintrag $eintraege {
        append markdown "| "
        append markdown [dict get $eintrag datum] " | "
        append markdown [dict get $eintrag nachname] " | "
        append markdown [dict get $eintrag vorname] " | "
        append markdown [dict get $eintrag kurzwaffe] " | "
        append markdown [dict get $eintrag langwaffe] " | "
        append markdown [dict get $eintrag waffentyp] " | "
        append markdown [dict get $eintrag kaliber] " | "
        append markdown [dict get $eintrag startgeld] " | "
        append markdown [dict get $eintrag munition] " | "
        append markdown [dict get $eintrag munitionspreis] " |\n"
    }

    append markdown "\n---\n\n"
    append markdown "Anzahl Einträge: [llength $eintraege]\n"

    return $markdown
}

# =============================================================================
# Prozedur: erstelle_html_tabelle
# Konvertiert Einträge in eine HTML-Tabelle mit CSS
# Parameter:
#   eintraege - Liste von Eintrags-Dictionaries
# Rückgabe: HTML-String
# =============================================================================
proc ::export::erstelle_html_tabelle {eintraege} {
    # HTML-Dokument erstellen
    set html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n"
    append html "<head>\n"
    append html "  <meta charset=\"UTF-8\">\n"
    append html "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
    append html "  <title>SVM Journal Export</title>\n"
    append html "  <style>\n"
    append html "    body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }\n"
    append html "    h1 { color: #333; }\n"
    append html "    .info { color: #666; margin-bottom: 20px; }\n"
    append html "    table { width: 100%; border-collapse: collapse; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\n"
    append html "    th { background-color: #4ACEFA; color: white; padding: 12px; text-align: left; font-weight: bold; }\n"
    append html "    td { padding: 10px; border-bottom: 1px solid #ddd; }\n"
    append html "    tr:hover { background-color: #f9f9f9; }\n"
    append html "    .footer { margin-top: 20px; color: #666; font-size: 0.9em; }\n"
    append html "  </style>\n"
    append html "</head>\n"
    append html "<body>\n"
    append html "  <h1>SVM Journal Export</h1>\n"
    append html "  <div class=\"info\">Exportiert am: [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]</div>\n"
    append html "  <table>\n"
    append html "    <thead>\n"
    append html "      <tr>\n"
    append html "        <th>Datum</th>\n"
    append html "        <th>Nachname</th>\n"
    append html "        <th>Vorname</th>\n"
    append html "        <th>KW</th>\n"
    append html "        <th>LW</th>\n"
    append html "        <th>Typ</th>\n"
    append html "        <th>Kaliber</th>\n"
    append html "        <th>Startgeld</th>\n"
    append html "        <th>Munition</th>\n"
    append html "        <th>Mun.Preis</th>\n"
    append html "      </tr>\n"
    append html "    </thead>\n"
    append html "    <tbody>\n"

    # Einträge zur Tabelle hinzufügen
    foreach eintrag $eintraege {
        append html "      <tr>\n"
        append html "        <td>[dict get $eintrag datum]</td>\n"
        append html "        <td>[dict get $eintrag nachname]</td>\n"
        append html "        <td>[dict get $eintrag vorname]</td>\n"
        append html "        <td>[dict get $eintrag kurzwaffe]</td>\n"
        append html "        <td>[dict get $eintrag langwaffe]</td>\n"
        append html "        <td>[dict get $eintrag waffentyp]</td>\n"
        append html "        <td>[dict get $eintrag kaliber]</td>\n"
        append html "        <td>[dict get $eintrag startgeld]</td>\n"
        append html "        <td>[dict get $eintrag munition]</td>\n"
        append html "        <td>[dict get $eintrag munitionspreis]</td>\n"
        append html "      </tr>\n"
    }

    append html "    </tbody>\n"
    append html "  </table>\n"
    append html "  <div class=\"footer\">Anzahl Einträge: [llength $eintraege]</div>\n"
    append html "</body>\n"
    append html "</html>\n"

    return $html
}

# =============================================================================
# Prozedur: exportiere_daten
# Hauptprozedur für den Export
# Lädt, filtert und exportiert die Daten in das gewählte Format
# =============================================================================
proc ::export::exportiere_daten {} {
    variable fenster
    variable export_format

    # Alle Einträge laden
    set alle_eintraege [lade_alle_eintraege]

    # Einträge filtern
    set gefilterte_eintraege [filtere_eintraege $alle_eintraege]

    # Prüfen ob Einträge vorhanden
    if {[llength $gefilterte_eintraege] == 0} {
        tk_messageBox -parent $fenster -icon warning -title "Export" \
            -message "Keine Einträge für den gewählten Zeitraum/Filter gefunden."
        return
    }

    # Dateiformat bestimmen
    if {$export_format eq "markdown"} {
        set datei_extension ".md"
        set datei_types {{"Markdown-Dateien" {.md}} {"Alle Dateien" {*}}}
    } else {
        set datei_extension ".html"
        set datei_types {{"HTML-Dateien" {.html}} {"Alle Dateien" {*}}}
    }

    # Standard-Dateiname mit Zeitstempel
    set standard_dateiname "svm-journal-export-[clock format [clock seconds] -format "%Y-%m-%d"]${datei_extension}"

    # Dateiauswahl-Dialog öffnen
    set datei [tk_getSaveFile -parent $fenster \
        -title "Export speichern" \
        -defaultextension $datei_extension \
        -initialfile $standard_dateiname \
        -filetypes $datei_types]

    # Prüfen ob Benutzer abgebrochen hat
    if {$datei eq ""} {
        return
    }

    # Daten in gewähltes Format konvertieren
    if {$export_format eq "markdown"} {
        set export_inhalt [erstelle_markdown_tabelle $gefilterte_eintraege]
    } else {
        set export_inhalt [erstelle_html_tabelle $gefilterte_eintraege]
    }

    # Datei schreiben
    set fp [open $datei w]
    fconfigure $fp -encoding utf-8
    puts $fp $export_inhalt
    close $fp

    # Erfolgs-Meldung
    tk_messageBox -parent $fenster -icon info -title "Export erfolgreich" \
        -message "Export erfolgreich!\n\n[llength $gefilterte_eintraege] Einträge wurden exportiert nach:\n$datei"

    # Dialog schließen
    destroy $fenster
}

# =============================================================================
# Prozedur: open_export_dialog
# Öffnet den Export-Dialog
# Parameter:
#   format - "markdown" oder "html"
# =============================================================================
proc open_export_dialog {format} {
    # Namespace-Variablen zurücksetzen
    set ::export::export_format $format
    set ::export::zeitraum_modus "alles"
    set ::export::von_datum ""
    set ::export::bis_datum ""
    set ::export::person_modus "alle"
    set ::export::person_suche ""
    set ::export::person_ausgewaehlt ""

    # Mitglieder für Suche laden
    ::export::lade_mitglieder_fuer_suche

    # Toplevel-Fenster erstellen
    set w .export_dialog
    set ::export::fenster $w

    # Falls Fenster bereits existiert, schließen
    if {[winfo exists $w]} {
        destroy $w
    }

    # Neues Toplevel-Fenster
    toplevel $w

    # Titel je nach Format
    if {$format eq "markdown"} {
        wm title $w "Export als Markdown"
    } else {
        wm title $w "Export als HTML"
    }

    wm geometry $w "600x450"

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # =========================================================================
    # Zeitraum-Auswahl
    # =========================================================================
    labelframe $w.zeitraum_frame -text "Zeitraum" -padx 10 -pady 10
    pack $w.zeitraum_frame -in $w.main -fill x -pady 10

    # Radiobutton "Alles exportieren"
    radiobutton $w.zeitraum_frame.alles -text "Alles exportieren" \
        -variable ::export::zeitraum_modus -value "alles" \
        -command ::export::zeitraum_modus_geaendert
    pack $w.zeitraum_frame.alles -anchor w

    # Radiobutton "Zeitraum" mit Datumsfeldern
    radiobutton $w.zeitraum_frame.zeitraum -text "Zeitraum:" \
        -variable ::export::zeitraum_modus -value "zeitraum" \
        -command ::export::zeitraum_modus_geaendert
    pack $w.zeitraum_frame.zeitraum -anchor w -pady 5

    # Frame für Datumsfelder
    frame $w.zeitraum_frame.zeitraum_content
    pack $w.zeitraum_frame.zeitraum_content -fill x -padx 20

    # Von-Datum
    label $w.zeitraum_frame.zeitraum_content.von_label -text "Von:" -width 8 -anchor w
    entry $w.zeitraum_frame.zeitraum_content.von_entry -textvariable ::export::von_datum \
        -state disabled -font {Arial 11}
    pack $w.zeitraum_frame.zeitraum_content.von_label -side left
    pack $w.zeitraum_frame.zeitraum_content.von_entry -side left -fill x -expand 1 -padx 5

    # Bis-Datum
    label $w.zeitraum_frame.zeitraum_content.bis_label -text "Bis:" -width 8 -anchor w
    entry $w.zeitraum_frame.zeitraum_content.bis_entry -textvariable ::export::bis_datum \
        -state disabled -font {Arial 11}
    pack $w.zeitraum_frame.zeitraum_content.bis_label -side left
    pack $w.zeitraum_frame.zeitraum_content.bis_entry -side left -fill x -expand 1

    # =========================================================================
    # Personen-Filter
    # =========================================================================
    labelframe $w.person_frame -text "Personen-Filter" -padx 10 -pady 10
    pack $w.person_frame -in $w.main -fill x -pady 10

    # Radiobutton "Alle Daten"
    radiobutton $w.person_frame.alle -text "Alle Daten" \
        -variable ::export::person_modus -value "alle" \
        -command ::export::person_modus_geaendert
    pack $w.person_frame.alle -anchor w

    # Radiobutton "Nur Person" mit Suchfeld
    radiobutton $w.person_frame.person -text "Nur Person:" \
        -variable ::export::person_modus -value "person" \
        -command ::export::person_modus_geaendert
    pack $w.person_frame.person -anchor w -pady 5

    # Frame für Suchfeld
    frame $w.person_frame.person_content
    pack $w.person_frame.person_content -fill x -padx 20

    # Suchfeld
    entry $w.person_frame.person_content.entry -textvariable ::export::person_suche \
        -state disabled -font {Arial 11}
    pack $w.person_frame.person_content.entry -fill x

    # Listbox für Suchergebnisse (initial versteckt)
    listbox $w.person_frame.person_content.listbox -height 5 -exportselection 0 -font {Arial 11}
    set ::export::person_listbox $w.person_frame.person_content.listbox
    set ::export::person_listbox_visible 0

    # Bindings für Listbox-Auswahl
    bind $w.person_frame.person_content.listbox <<ListboxSelect>> ::export::person_ausgewaehlt
    bind $w.person_frame.person_content.listbox <Double-Button-1> ::export::person_ausgewaehlt

    # =========================================================================
    # Buttons (Exportieren / Abbrechen)
    # =========================================================================
    frame $w.button_frame
    pack $w.button_frame -in $w.main -fill x -pady 20

    # Button "Exportieren" - initial deaktiviert
    button $w.button_frame.export -text "Exportieren" -bg "#90EE90" -width 15 \
        -command ::export::exportiere_daten -state disabled
    pack $w.button_frame.export -side left -padx 5

    # Button "Abbrechen"
    button $w.button_frame.cancel -text "Abbrechen" -bg "#FFB6C1" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.cancel -side right -padx 5

    # =========================================================================
    # Traces für Validierung setzen (nach Button-Erstellung!)
    # =========================================================================
    # Trace für Datumsfelder - Export-Button-Validierung
    trace add variable ::export::von_datum write ::export::pruefe_export_button
    trace add variable ::export::bis_datum write ::export::pruefe_export_button

    # Trace für Live-Suche
    trace add variable ::export::person_suche write ::export::person_suche_geaendert

    # =========================================================================
    # Initiale Prüfung des Export-Buttons
    # =========================================================================
    ::export::pruefe_export_button

    # Focus auf Fenster setzen
    focus $w
}
