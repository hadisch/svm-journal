# =============================================================================
# blacklist_dialog.tcl - Verwaltung der vom Schießbetrieb gesperrten Personen
# =============================================================================
# Dieses Modul stellt ein Fenster zur Verwaltung der Blacklist bereit.
# Gesperrte Personen werden in daten/blacklist.json gespeichert.
# Die Datei wird beim ersten Aufruf automatisch angelegt.
# =============================================================================

# Namespace für die Blacklist-Verwaltung
namespace eval ::blacklist {
    # Interne Liste der gesperrten Personen: jeder Eintrag ist eine Liste {nachname vorname}
    variable blacklist_liste [list]

    # Index des aktuell markierten Eintrags im Treeview (-1 = nichts markiert)
    variable ausgewaehlter_index -1
}

# =============================================================================
# ::blacklist::lade_blacklist
# Liest blacklist.json und befüllt blacklist_liste.
# Falls die Datei noch nicht existiert, wird die Liste leer initialisiert.
# =============================================================================
proc ::blacklist::lade_blacklist {} {
    variable blacklist_liste

    # Liste zurücksetzen
    set blacklist_liste [list]

    # Dateipfad aus dem zentralen Pfad-Management holen
    set pfad $::blacklist_json

    # Falls Datei noch nicht existiert, einfach leere Liste behalten
    if {![file exists $pfad]} {
        return
    }

    # Datei mit UTF-8-Encoding öffnen und lesen
    if {[catch {
        set fp [open $pfad r]
        fconfigure $fp -encoding utf-8
        set inhalt [read $fp]
        close $fp
    } err]} {
        # Lesefehler: Warnung ausgeben, leere Liste behalten
        puts stderr "Fehler beim Lesen der Blacklist: $err"
        return
    }

    # JSON zeilenweise parsen: Nachname/Vorname-Paare extrahieren
    # Gleiche Methode wie in neuer_eintrag.tcl für mitglieder.json
    set zeilen [split $inhalt "\n"]
    set aktueller_nachname ""

    foreach zeile $zeilen {
        # "nachname"-Feld gefunden
        if {[regexp {"nachname":\s*"([^"]*)"} $zeile -> nachname]} {
            set aktueller_nachname [string trim $nachname]
        }
        # "vorname"-Feld gefunden: Paar vervollständigen und zur Liste hinzufügen
        if {[regexp {"vorname":\s*"([^"]*)"} $zeile -> vorname]} {
            set vorname [string trim $vorname]
            if {$aktueller_nachname ne "" && $vorname ne ""} {
                lappend blacklist_liste [list $aktueller_nachname $vorname]
            }
            # Nachname-Zwischenspeicher zurücksetzen für nächstes Paar
            set aktueller_nachname ""
        }
    }

    # Liste alphabetisch nach Nachname, dann Vorname sortieren
    set blacklist_liste [lsort -index 0 [lsort -index 1 $blacklist_liste]]
}

# =============================================================================
# ::blacklist::speichere_blacklist
# Schreibt blacklist_liste als JSON in blacklist.json.
# =============================================================================
proc ::blacklist::speichere_blacklist {} {
    variable blacklist_liste

    # Dateipfad aus dem zentralen Pfad-Management holen
    set pfad $::blacklist_json

    # JSON-Inhalt manuell zusammenbauen (wie in json_writer.tcl üblich)
    set zeilen [list]
    lappend zeilen "\{"
    lappend zeilen "  \"blacklist\": \["

    set anzahl [llength $blacklist_liste]
    set idx 0

    foreach eintrag $blacklist_liste {
        # Nachname und Vorname aus der internen Liste extrahieren
        set nachname [lindex $eintrag 0]
        set vorname  [lindex $eintrag 1]

        # Sonderzeichen für JSON escapen (Backslash und Anführungszeichen)
        set nachname [string map {\\ \\\\ \" \\\"} $nachname]
        set vorname  [string map {\\ \\\\ \" \\\"} $vorname]

        lappend zeilen "    \{"
        lappend zeilen "      \"nachname\": \"$nachname\","
        lappend zeilen "      \"vorname\": \"$vorname\""

        incr idx
        # Letzter Eintrag ohne abschließendes Komma
        if {$idx < $anzahl} {
            lappend zeilen "    \},"
        } else {
            lappend zeilen "    \}"
        }
    }

    lappend zeilen "  \],"
    # Zeitstempel und Anzahl als Metadaten speichern
    lappend zeilen "  \"erstellt_am\": \"[clock format [clock seconds] -format {%d.%m.%Y, %H:%M:%S}]\","
    lappend zeilen "  \"anzahl\": $anzahl"
    lappend zeilen "\}"

    set json_inhalt [join $zeilen "\n"]

    # In Datei schreiben mit UTF-8-Encoding
    if {[catch {
        set fp [open $pfad w]
        fconfigure $fp -encoding utf-8
        puts $fp $json_inhalt
        close $fp
    } err]} {
        tk_messageBox -icon error -type ok \
            -title "Fehler" \
            -message "Blacklist konnte nicht gespeichert werden:\n$err"
    }
}

# =============================================================================
# ::blacklist::aktualisiere_anzeige
# Leert den Treeview und befüllt ihn neu aus blacklist_liste.
# =============================================================================
proc ::blacklist::aktualisiere_anzeige {} {
    variable blacklist_liste

    # Sicherheitscheck: Treeview muss existieren
    if {![winfo exists .blacklist.main.tree]} {
        return
    }

    # Alle vorhandenen Einträge entfernen
    .blacklist.main.tree delete [.blacklist.main.tree children {}]

    # Liste sortiert einfügen
    foreach eintrag $blacklist_liste {
        set nachname [lindex $eintrag 0]
        set vorname  [lindex $eintrag 1]
        .blacklist.main.tree insert {} end -values [list $nachname $vorname]
    }
}

# =============================================================================
# ::blacklist::oeffne_hinzufuegen_dialog
# Öffnet einen Sub-Dialog zum Hinzufügen einer neuen gesperrten Person.
# =============================================================================
proc ::blacklist::oeffne_hinzufuegen_dialog {} {
    variable blacklist_liste

    # Verhindert mehrfaches Öffnen des Dialogs
    if {[winfo exists .blacklist.hinzufuegen]} {
        raise .blacklist.hinzufuegen
        focus .blacklist.hinzufuegen
        return
    }

    # Sub-Dialog-Fenster erstellen
    toplevel .blacklist.hinzufuegen
    wm title .blacklist.hinzufuegen "Person zur Blacklist hinzuf\u00fcgen"
    wm geometry .blacklist.hinzufuegen 420x180
    wm transient .blacklist.hinzufuegen .blacklist
    wm resizable .blacklist.hinzufuegen 0 0

    # Dialog auf dem Elternfenster zentrieren
    update idletasks
    set px [winfo x .blacklist]
    set py [winfo y .blacklist]
    set pw [winfo width .blacklist]
    set ph [winfo height .blacklist]
    set dw 420
    set dh 180
    set dx [expr {$px + ($pw - $dw) / 2}]
    set dy [expr {$py + ($ph - $dh) / 2}]
    wm geometry .blacklist.hinzufuegen +${dx}+${dy}

    # Hauptrahmen mit Innenabstand
    frame .blacklist.hinzufuegen.main -padx 15 -pady 10
    pack .blacklist.hinzufuegen.main -fill both -expand 1

    # Nachname-Eingabefeld
    frame .blacklist.hinzufuegen.main.nn_frame
    pack .blacklist.hinzufuegen.main.nn_frame -fill x -pady 5

    label .blacklist.hinzufuegen.main.nn_frame.label \
        -text "Nachname *:" -width 14 -anchor w
    pack .blacklist.hinzufuegen.main.nn_frame.label -side left

    entry .blacklist.hinzufuegen.main.nn_frame.entry \
        -textvariable ::blacklist::neu_nachname -width 30
    pack .blacklist.hinzufuegen.main.nn_frame.entry -side left -fill x -expand 1

    # Vorname-Eingabefeld
    frame .blacklist.hinzufuegen.main.vn_frame
    pack .blacklist.hinzufuegen.main.vn_frame -fill x -pady 5

    label .blacklist.hinzufuegen.main.vn_frame.label \
        -text "Vorname *:" -width 14 -anchor w
    pack .blacklist.hinzufuegen.main.vn_frame.label -side left

    entry .blacklist.hinzufuegen.main.vn_frame.entry \
        -textvariable ::blacklist::neu_vorname -width 30
    pack .blacklist.hinzufuegen.main.vn_frame.entry -side left -fill x -expand 1

    # Hinweistext für Pflichtfelder
    label .blacklist.hinzufuegen.main.hinweis \
        -text "* Pflichtfelder" -fg gray -anchor w
    pack .blacklist.hinzufuegen.main.hinweis -fill x

    # Button-Leiste
    frame .blacklist.hinzufuegen.main.buttons
    pack .blacklist.hinzufuegen.main.buttons -fill x -pady 8

    # Speichern-Button (initial deaktiviert, bis beide Felder gefüllt sind)
    button .blacklist.hinzufuegen.main.buttons.save \
        -text "Hinzuf\u00fcgen" -bg #569A40 -fg white -activebackground #4a8735 \
        -state disabled \
        -command ::blacklist::speichere_neuen_eintrag
    pack .blacklist.hinzufuegen.main.buttons.save -side left -padx 5

    # Abbrechen-Button
    button .blacklist.hinzufuegen.main.buttons.cancel \
        -text "Abbrechen" -bg #E0E0E0 -activebackground #C8C8C8 \
        -command {destroy .blacklist.hinzufuegen}
    pack .blacklist.hinzufuegen.main.buttons.cancel -side left -padx 5

    # Eingabevariablen initialisieren
    set ::blacklist::neu_nachname ""
    set ::blacklist::neu_vorname ""

    # Trace: Speichern-Button aktivieren wenn beide Felder gefüllt
    trace add variable ::blacklist::neu_nachname write ::blacklist::pruefe_hinzufuegen_button
    trace add variable ::blacklist::neu_vorname  write ::blacklist::pruefe_hinzufuegen_button

    # ESC schließt den Dialog
    bind .blacklist.hinzufuegen <Escape> {destroy .blacklist.hinzufuegen}

    # Enter im letzten Feld löst Speichern aus
    bind .blacklist.hinzufuegen.main.vn_frame.entry <Return> {
        if {[.blacklist.hinzufuegen.main.buttons.save cget -state] eq "normal"} {
            ::blacklist::speichere_neuen_eintrag
        }
    }

    # Traces beim Schließen des Dialogs entfernen
    bind .blacklist.hinzufuegen <Destroy> {
        catch {trace remove variable ::blacklist::neu_nachname write ::blacklist::pruefe_hinzufuegen_button}
        catch {trace remove variable ::blacklist::neu_vorname  write ::blacklist::pruefe_hinzufuegen_button}
    }

    # Fokus auf Nachname-Feld setzen
    focus .blacklist.hinzufuegen.main.nn_frame.entry
}

# =============================================================================
# ::blacklist::pruefe_hinzufuegen_button
# Aktiviert/Deaktiviert den "Hinzufügen"-Button je nach Eingabestand.
# =============================================================================
proc ::blacklist::pruefe_hinzufuegen_button {args} {
    # Sicherheitscheck: Dialog muss noch existieren
    if {![winfo exists .blacklist.hinzufuegen.main.buttons.save]} {
        return
    }

    # Beide Felder müssen mindestens ein Zeichen enthalten
    if {[string trim $::blacklist::neu_nachname] ne "" &&
        [string trim $::blacklist::neu_vorname] ne ""} {
        .blacklist.hinzufuegen.main.buttons.save configure -state normal
    } else {
        .blacklist.hinzufuegen.main.buttons.save configure -state disabled
    }
}

# =============================================================================
# ::blacklist::speichere_neuen_eintrag
# Fügt einen neuen Eintrag zur Blacklist hinzu und speichert.
# =============================================================================
proc ::blacklist::speichere_neuen_eintrag {} {
    variable blacklist_liste

    # Eingaben trimmen
    set nachname [string trim $::blacklist::neu_nachname]
    set vorname  [string trim $::blacklist::neu_vorname]

    # Doppelten Eintrag prüfen (case-insensitive)
    foreach eintrag $blacklist_liste {
        if {[string equal -nocase [lindex $eintrag 0] $nachname] &&
            [string equal -nocase [lindex $eintrag 1] $vorname]} {
            tk_messageBox -icon info -type ok \
                -title "Bereits vorhanden" \
                -parent .blacklist.hinzufuegen \
                -message "$vorname $nachname ist bereits in der Blacklist eingetragen."
            return
        }
    }

    # Neuen Eintrag zur Liste hinzufügen
    lappend blacklist_liste [list $nachname $vorname]

    # Alphabetisch sortieren (Nachname, dann Vorname)
    set blacklist_liste [lsort -index 0 [lsort -index 1 $blacklist_liste]]

    # In Datei speichern und Anzeige aktualisieren
    speichere_blacklist
    aktualisiere_anzeige

    # Dialog schließen
    destroy .blacklist.hinzufuegen
}

# =============================================================================
# ::blacklist::loesche_eintrag
# Löscht den aktuell markierten Eintrag nach Bestätigung.
# =============================================================================
proc ::blacklist::loesche_eintrag {} {
    variable blacklist_liste
    variable ausgewaehlter_index

    # Prüfen ob ein Eintrag ausgewählt ist
    if {$ausgewaehlter_index < 0} {
        tk_messageBox -icon info -type ok \
            -title "Kein Eintrag ausgew\u00e4hlt" \
            -parent .blacklist \
            -message "Bitte w\u00e4hlen Sie zuerst einen Eintrag aus der Liste aus."
        return
    }

    # Namen des zu löschenden Eintrags ermitteln
    set eintrag [lindex $blacklist_liste $ausgewaehlter_index]
    set nachname [lindex $eintrag 0]
    set vorname  [lindex $eintrag 1]

    # Bestätigungsdialog anzeigen
    set antwort [tk_messageBox -icon question -type yesno \
        -title "Eintrag l\u00f6schen" \
        -parent .blacklist \
        -message "$vorname $nachname aus der Blacklist entfernen?\n\nDiese Person kann dann wieder am Schie\u00dfbetrieb teilnehmen."]

    if {$antwort ne "yes"} {
        return
    }

    # Eintrag aus der Liste entfernen
    set blacklist_liste [lreplace $blacklist_liste $ausgewaehlter_index $ausgewaehlter_index]

    # Auswahl zurücksetzen
    set ausgewaehlter_index -1

    # Speichern und Anzeige aktualisieren
    speichere_blacklist
    aktualisiere_anzeige
}

# =============================================================================
# open_blacklist_dialog
# Öffnet das Blacklist-Verwaltungsfenster.
# Wird aus dem Menü und dem Toolbar-Button aufgerufen.
# =============================================================================
proc open_blacklist_dialog {} {
    # Verhindert mehrfaches Öffnen des Fensters
    if {[winfo exists .blacklist]} {
        raise .blacklist
        focus .blacklist
        return
    }

    # Auswahl zurücksetzen
    set ::blacklist::ausgewaehlter_index -1

    # Hauptfenster erstellen
    toplevel .blacklist
    wm title .blacklist "Blacklist - Gesperrte Personen"
    wm geometry .blacklist 700x500
    wm minsize .blacklist 600 400

    # Fenster auf dem Hauptfenster zentrieren
    update idletasks
    set px [winfo x .]
    set py [winfo y .]
    set pw [winfo width .]
    set ph [winfo height .]
    set dw 700
    set dh 500
    set dx [expr {$px + ($pw - $dw) / 2}]
    set dy [expr {$py + ($ph - $dh) / 2}]
    if {$dy < 0} { set dy 0 }
    wm geometry .blacklist +${dx}+${dy}

    # =========================================================================
    # Toolbar mit Buttons für CRUD-Operationen
    # =========================================================================
    frame .blacklist.toolbar -bg #E0E0E0 -relief raised -bd 1
    pack .blacklist.toolbar -fill x

    # Button "Neuer Eintrag" - fügt eine neue gesperrte Person hinzu
    button .blacklist.toolbar.add \
        -image [::toolbar_icons::get neuer_eintrag] \
        -command ::blacklist::oeffne_hinzufuegen_dialog \
        -bg #569A40 -fg white -activebackground #4a8735 -relief flat -bd 1
    pack .blacklist.toolbar.add -side left -padx 5 -pady 3
    ::tooltip::register .blacklist.toolbar.add "Person zur Blacklist hinzuf\u00fcgen"

    # Button "Löschen" - entfernt den markierten Eintrag
    button .blacklist.toolbar.delete \
        -image [::toolbar_icons::get loeschen] \
        -command ::blacklist::loesche_eintrag \
        -bg #E0E0E0 -activebackground #C8C8C8 -relief flat -bd 1
    pack .blacklist.toolbar.delete -side left -padx 5 -pady 3
    ::tooltip::register .blacklist.toolbar.delete "Ausgew\u00e4hlte Person aus Blacklist entfernen"

    # Button "Schließen" - schließt das Fenster (rechts ausgerichtet)
    button .blacklist.toolbar.close \
        -image [::toolbar_icons::get schliessen] \
        -command {destroy .blacklist} \
        -bg #E0E0E0 -activebackground #C8C8C8 -relief flat -bd 1
    pack .blacklist.toolbar.close -side right -padx 5 -pady 3
    ::tooltip::register .blacklist.toolbar.close "Fenster schlie\u00dfen"

    # =========================================================================
    # Hauptbereich: Treeview mit Scrollbars
    # =========================================================================
    frame .blacklist.main -bg white
    pack .blacklist.main -fill both -expand 1

    # Treeview mit den Spalten Nachname und Vorname
    ttk::treeview .blacklist.main.tree \
        -columns {nachname vorname} \
        -show headings \
        -selectmode browse \
        -yscrollcommand {.blacklist.main.yscroll set} \
        -xscrollcommand {.blacklist.main.xscroll set}

    # Vertikale Scrollbar
    scrollbar .blacklist.main.yscroll -orient vertical \
        -command {.blacklist.main.tree yview}

    # Horizontale Scrollbar
    scrollbar .blacklist.main.xscroll -orient horizontal \
        -command {.blacklist.main.tree xview}

    # Spaltenüberschriften und Breiten setzen
    .blacklist.main.tree heading nachname -text "Nachname" -anchor w
    .blacklist.main.tree heading vorname  -text "Vorname"  -anchor w
    .blacklist.main.tree column  nachname -width 250 -anchor w
    .blacklist.main.tree column  vorname  -width 250 -anchor w

    # Treeview und Scrollbars im Grid anordnen
    grid .blacklist.main.tree    -row 0 -column 0 -sticky nsew
    grid .blacklist.main.yscroll -row 0 -column 1 -sticky ns
    grid .blacklist.main.xscroll -row 1 -column 0 -sticky ew

    # Grid-Gewichtung für korrekte Größenanpassung
    grid rowconfigure    .blacklist.main 0 -weight 1
    grid columnconfigure .blacklist.main 0 -weight 1

    # =========================================================================
    # Statuszeile mit Hinweis
    # =========================================================================
    frame .blacklist.status -bg #F0F0F0 -relief sunken -bd 1
    pack .blacklist.status -fill x -side bottom

    label .blacklist.status.info \
        -text "Gesperrte Personen d\u00fcrfen nicht am Schie\u00dfbetrieb teilnehmen." \
        -bg #F0F0F0 -fg #666666 -anchor w -padx 5
    pack .blacklist.status.info -side left

    # =========================================================================
    # Treeview-Selektion: Index des markierten Eintrags merken
    # =========================================================================
    bind .blacklist.main.tree <<TreeviewSelect>> {
        set selected_items [.blacklist.main.tree selection]
        if {[llength $selected_items] > 0} {
            set item_id [lindex $selected_items 0]
            set all_items [.blacklist.main.tree children {}]
            set ::blacklist::ausgewaehlter_index [lsearch $all_items $item_id]
        } else {
            set ::blacklist::ausgewaehlter_index -1
        }
    }

    # Doppelklick öffnet Löschen-Dialog
    bind .blacklist.main.tree <Double-Button-1> {::blacklist::loesche_eintrag}

    # ESC schließt das Fenster
    bind .blacklist <Escape> {destroy .blacklist}

    # Daten laden und Anzeige aktualisieren
    ::blacklist::lade_blacklist
    ::blacklist::aktualisiere_anzeige

    # Fokus auf den Treeview setzen
    focus .blacklist.main.tree
}
