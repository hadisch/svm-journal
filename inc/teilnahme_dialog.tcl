# =============================================================================
# teilnahme_dialog.tcl - Teilnahme am Training (Bedürfnisnachweis)
# =============================================================================
# Dieses Modul wertet aus, wie oft jedes Vereinsmitglied im gewählten Zeitraum
# mit Kurz- bzw. Langwaffe am Schießtraining teilgenommen hat.
#
# Hintergrund: Sportschützen müssen je Waffengattung, die sie besitzen,
# mindestens 6 Trainingsteilnahmen pro Jahr nachweisen, um das Bedürfnis zum
# Waffenbesitz aufrechtzuerhalten. Vereine sind zur Meldung säumiger Schützen
# verpflichtet.
#
# Zählweise: Pro Trainingstag (mehrere Einträge am selben Datum mit derselben
# Waffengattung zählen als eine Teilnahme). Es werden nur Vereinsmitglieder
# (aus mitglieder.json) berücksichtigt.
#
# Darstellung im Ergebnisfenster:
#   - Grün:    bei beiden Waffengattungen mindestens 6 Teilnahmen
#   - Rot:     noch gar keine Teilnahme
#   - Schwarz: alle übrigen
# =============================================================================

# Namespace für Teilnahme-Funktionalität
namespace eval ::teilnahme {
    # Dialog-Variablen
    variable fenster ""
    variable ergebnis_fenster ""

    # Zeitraum-Auswahl (vorausgefüllt mit 01.01.aktuelles Jahr bis heute)
    variable von_datum ""
    variable bis_datum ""

    # Mindestanzahl Teilnahmen je Waffengattung (gesetzliche Vorgabe)
    variable mindest_teilnahmen 6

    # Ergebnisliste: jede Zeile ist ein Dict mit name, kurz, lang, gesamt
    variable ergebnis_liste [list]
}

# =============================================================================
# Prozedur: open_zeitraum_dialog
# Öffnet den Dialog zur Auswahl des Zeitraums für die Teilnahme-Auswertung
# =============================================================================
proc ::teilnahme::open_zeitraum_dialog {} {
    variable fenster
    variable von_datum
    variable bis_datum

    # Fenster-Widget-Name
    set w .teilnahme_zeitraum
    set fenster $w

    # Prüfen ob Dialog bereits geöffnet ist
    if {[winfo exists $w]} {
        # Falls ja, in den Vordergrund bringen
        raise $w
        focus $w
        return
    }

    # Standardwerte für Datumsfelder setzen
    # Von: 01.01. des aktuellen Jahres
    set aktuelles_jahr [clock format [clock seconds] -format "%Y"]
    set von_datum "01.01.$aktuelles_jahr"
    # Bis: Heutiges Datum
    set bis_datum [clock format [clock seconds] -format "%d.%m.%Y"]

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Teilnahme am Training - Zeitraum w\u00e4hlen"
    wm geometry $w "450x250"
    wm resizable $w 0 0

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 15
    pack $w.main -fill both -expand 1

    # Labelframe für Zeitraum-Eingabe
    labelframe $w.main.zeitraum -text "Zeitraum" -padx 15 -pady 10
    pack $w.main.zeitraum -fill x -pady 10

    # Frame für "Von"-Datum
    frame $w.main.zeitraum.von_frame
    pack $w.main.zeitraum.von_frame -fill x -pady 5

    # Label "Von:"
    label $w.main.zeitraum.von_frame.label -text "Von:" -width 8 -anchor w
    pack $w.main.zeitraum.von_frame.label -side left

    # Entry für "Von"-Datum
    entry $w.main.zeitraum.von_frame.entry -textvariable ::teilnahme::von_datum -width 20
    pack $w.main.zeitraum.von_frame.entry -side left -padx 5

    # Hinweis-Label für Datumsformat
    label $w.main.zeitraum.von_frame.hint -text "(TT.MM.JJJJ)" -fg gray
    pack $w.main.zeitraum.von_frame.hint -side left

    # Frame für "Bis"-Datum
    frame $w.main.zeitraum.bis_frame
    pack $w.main.zeitraum.bis_frame -fill x -pady 5

    # Label "Bis:"
    label $w.main.zeitraum.bis_frame.label -text "Bis:" -width 8 -anchor w
    pack $w.main.zeitraum.bis_frame.label -side left

    # Entry für "Bis"-Datum
    entry $w.main.zeitraum.bis_frame.entry -textvariable ::teilnahme::bis_datum -width 20
    pack $w.main.zeitraum.bis_frame.entry -side left -padx 5

    # Hinweis-Label für Datumsformat
    label $w.main.zeitraum.bis_frame.hint -text "(TT.MM.JJJJ)" -fg gray
    pack $w.main.zeitraum.bis_frame.hint -side left

    # Button-Frame
    frame $w.main.buttons
    pack $w.main.buttons -fill x -pady 15

    # Button "Auswerten" (grün) - mit Padding für angemessene Button-Höhe
    button $w.main.buttons.auswerten -text "Auswerten" -bg "#569A40" -fg white -width 15 \
        -command {::teilnahme::berechne_teilnahme}
    pack $w.main.buttons.auswerten -side left -padx 10 -ipady 8

    # Button "Abbrechen" (rosa) - mit Padding für angemessene Button-Höhe
    button $w.main.buttons.abbrechen -text "Abbrechen" -bg "#E0E0E0" -width 15 \
        -command {::teilnahme::schliesse_zeitraum_dialog}
    pack $w.main.buttons.abbrechen -side right -padx 10 -ipady 8

    # Traces für Datumseingaben hinzufügen (zur Validierung)
    trace add variable ::teilnahme::von_datum write ::teilnahme::pruefe_datum_button
    trace add variable ::teilnahme::bis_datum write ::teilnahme::pruefe_datum_button

    # Enter-Taste zum Auswerten binden
    bind $w <Return> {::teilnahme::berechne_teilnahme}
    # Escape-Taste zum Schließen binden
    bind $w <Escape> {::teilnahme::schliesse_zeitraum_dialog}

    # Fokus auf das Fenster setzen
    focus $w
}

# =============================================================================
# Prozedur: pruefe_datum_button
# Validiert die Datumseingaben und aktiviert/deaktiviert den Auswerten-Button
# =============================================================================
proc ::teilnahme::pruefe_datum_button {args} {
    variable fenster
    variable von_datum
    variable bis_datum

    # Prüfen ob Fenster existiert
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

    # Prüfen ob Button existiert
    if {![winfo exists $fenster.main.buttons.auswerten]} {
        return
    }

    # Beide Datumsfelder müssen ausgefüllt sein
    if {[string trim $von_datum] ne "" && [string trim $bis_datum] ne ""} {
        # Button aktivieren
        $fenster.main.buttons.auswerten configure -state normal
    } else {
        # Button deaktivieren
        $fenster.main.buttons.auswerten configure -state disabled
    }
}

# =============================================================================
# Prozedur: schliesse_zeitraum_dialog
# Schließt den Zeitraum-Dialog und entfernt alle Traces
# =============================================================================
proc ::teilnahme::schliesse_zeitraum_dialog {} {
    variable fenster

    # Traces entfernen (wichtig um Memory Leaks zu vermeiden)
    catch {trace remove variable ::teilnahme::von_datum write ::teilnahme::pruefe_datum_button}
    catch {trace remove variable ::teilnahme::bis_datum write ::teilnahme::pruefe_datum_button}

    # Fenster zerstören
    if {[winfo exists $fenster]} {
        destroy $fenster
    }

    # Variable zurücksetzen
    set fenster ""
}

# =============================================================================
# Prozedur: lade_eintraege_im_zeitraum
# Lädt alle Schießbetrieb-Einträge die im gewählten Zeitraum liegen
# (verwendet die bereits vorhandenen Datums-Hilfsfunktionen aus ::statistik)
# Rückgabe: Liste von Eintrags-Dictionaries
# =============================================================================
proc ::teilnahme::lade_eintraege_im_zeitraum {} {
    variable von_datum
    variable bis_datum

    # Daten-Verzeichnis ermitteln
    set daten_dir [::pfad::get_daten_directory]

    # Liste für alle Einträge
    set alle_eintraege [list]

    # Alle JSON-Dateien im Daten-Verzeichnis durchsuchen
    foreach datei [glob -nocomplain -directory $daten_dir *.json] {
        # mitglieder.json überspringen (enthält keine Schießbetrieb-Einträge)
        if {[file tail $datei] eq "mitglieder.json"} {
            continue
        }

        # Einträge aus dieser Datei laden
        set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]

        # Zur Gesamtliste hinzufügen
        set alle_eintraege [concat $alle_eintraege $eintraege]
    }

    # Nach Zeitraum filtern
    set gefilterte_eintraege [list]

    foreach eintrag $alle_eintraege {
        # Datum des Eintrags holen (fehlt es, Eintrag überspringen)
        if {![dict exists $eintrag datum]} {
            continue
        }
        set datum [dict get $eintrag datum]

        # Prüfen ob im Zeitraum (Hilfsfunktion aus ::statistik wiederverwenden)
        if {[::statistik::datum_im_zeitraum $datum $von_datum $bis_datum]} {
            lappend gefilterte_eintraege $eintrag
        }
    }

    return $gefilterte_eintraege
}

# =============================================================================
# Prozedur: berechne_teilnahme
# Hauptprozedur: Validiert, lädt Daten, zählt Trainingstage je Mitglied und
# Waffengattung und zeigt das Ergebnisfenster.
# =============================================================================
proc ::teilnahme::berechne_teilnahme {} {
    variable fenster
    variable von_datum
    variable bis_datum
    variable ergebnis_liste

    # Datumsvalidierung (Hilfsfunktionen aus ::statistik wiederverwenden)
    if {![::statistik::validiere_datum $von_datum]} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" \
            -message "Das Von-Datum ist ung\u00fcltig.\nBitte im Format TT.MM.JJJJ eingeben."
        return
    }

    if {![::statistik::validiere_datum $bis_datum]} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" \
            -message "Das Bis-Datum ist ung\u00fcltig.\nBitte im Format TT.MM.JJJJ eingeben."
        return
    }

    # Prüfen ob Von-Datum vor Bis-Datum liegt
    set von_vgl [::statistik::datum_zu_vergleichswert $von_datum]
    set bis_vgl [::statistik::datum_zu_vergleichswert $bis_datum]

    if {$von_vgl > $bis_vgl} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" \
            -message "Das Von-Datum muss vor dem Bis-Datum liegen."
        return
    }

    # Einträge im Zeitraum laden
    set eintraege [lade_eintraege_im_zeitraum]

    # Mitgliederliste laden (Auswertung betrifft nur Vereinsmitglieder)
    set mitglieder [::statistik::lade_mitglieder]

    # Prüfen ob überhaupt Mitglieder vorhanden sind
    if {[llength $mitglieder] == 0} {
        tk_messageBox -parent $fenster -icon warning -title "Keine Mitglieder" \
            -message "Es sind keine Vereinsmitglieder erfasst.\nBitte zuerst Mitglieder in der Mitgliederliste anlegen."
        return
    }

    # Pro Mitglied: Sets der eindeutigen Trainingstage je Waffengattung aufbauen
    # Key = "nachname|vorname"; Wert = Dict mit je einem Tage-Set für kurz/lang
    set tage [dict create]

    # Mitglieder als gültige Schlüssel registrieren (auch ohne Teilnahme sichtbar)
    foreach mitglied $mitglieder {
        set key "[dict get $mitglied nachname]|[dict get $mitglied vorname]"
        dict set tage $key [dict create kurz [dict create] lang [dict create]]
    }

    # Einträge durchgehen und Trainingstage zählen
    foreach eintrag $eintraege {
        # Eintrag muss Namensfelder besitzen
        if {![dict exists $eintrag nachname] || ![dict exists $eintrag vorname]} {
            continue
        }
        set key "[dict get $eintrag nachname]|[dict get $eintrag vorname]"

        # Nur Vereinsmitglieder berücksichtigen
        if {![dict exists $tage $key]} {
            continue
        }

        # Datum als Tag-Schlüssel (Vergleichswert JJJJMMTT je Tag eindeutig)
        set tag [::statistik::datum_zu_vergleichswert [dict get $eintrag datum]]

        # Waffengattungen des Eintrags ("Ja"/"Nein")
        set ist_kurz [expr {[dict exists $eintrag kurzwaffe] && [dict get $eintrag kurzwaffe] eq "Ja"}]
        set ist_lang [expr {[dict exists $eintrag langwaffe] && [dict get $eintrag langwaffe] eq "Ja"}]

        # Eintrag dieser Person holen, ergänzen, zurückschreiben
        set person [dict get $tage $key]

        if {$ist_kurz} {
            dict set person kurz $tag 1
        }
        if {$ist_lang} {
            dict set person lang $tag 1
        }

        dict set tage $key $person
    }

    # Ergebnisliste aufbauen (alphabetisch nach Name sortiert)
    set ergebnis_liste [list]
    foreach key [lsort -dictionary [dict keys $tage]] {
        lassign [split $key "|"] nachname vorname
        set person [dict get $tage $key]

        # Anzahl eindeutiger Trainingstage je Kategorie
        set kurz_anzahl [dict size [dict get $person kurz]]
        set lang_anzahl [dict size [dict get $person lang]]
        # Gesamt = Summe der Teilnahmen beider Waffengattungen
        set gesamt_anzahl [expr {$kurz_anzahl + $lang_anzahl}]

        lappend ergebnis_liste [dict create \
            name "$nachname, $vorname" \
            kurz $kurz_anzahl \
            lang $lang_anzahl \
            gesamt $gesamt_anzahl]
    }

    # Zeitraum-Dialog schließen
    schliesse_zeitraum_dialog

    # Ergebnis-Fenster anzeigen
    zeige_ergebnis_fenster
}

# =============================================================================
# Prozedur: bestimme_farbtag
# Ermittelt für eine Ergebniszeile den Farb-Tag (gruen/rot/schwarz)
# Parameter: zeile - Dict mit kurz/lang/gesamt
# Rückgabe: Tag-Name als String
# =============================================================================
proc ::teilnahme::bestimme_farbtag {zeile} {
    variable mindest_teilnahmen

    set kurz [dict get $zeile kurz]
    set lang [dict get $zeile lang]
    set gesamt [dict get $zeile gesamt]

    # Grün: beide Waffengattungen erfüllen die Mindestanzahl
    if {$kurz >= $mindest_teilnahmen && $lang >= $mindest_teilnahmen} {
        return "gruen"
    }
    # Rot: noch gar keine Teilnahme
    if {$gesamt == 0} {
        return "rot"
    }
    # Schwarz: alle übrigen
    return "schwarz"
}

# =============================================================================
# Prozedur: zeige_ergebnis_fenster
# Zeigt das Ergebnisfenster mit der Teilnahme-Tabelle
# =============================================================================
proc ::teilnahme::zeige_ergebnis_fenster {} {
    variable ergebnis_fenster
    variable von_datum
    variable bis_datum
    variable ergebnis_liste
    variable mindest_teilnahmen

    # Fenster-Widget-Name
    set w .teilnahme_ergebnis
    set ergebnis_fenster $w

    # Prüfen ob Dialog bereits geöffnet ist
    if {[winfo exists $w]} {
        destroy $w
    }

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Teilnahme am Training vom $von_datum bis $bis_datum"

    # Fenstergröße wie die Mitgliederverwaltung (Adressenverzeichnis)
    wm minsize $w 1600 800
    wm geometry $w "1600x800"

    # GUI-Update erzwingen, damit das Fenster existiert
    update idletasks

    # Fenster zentriert über dem Hauptfenster positionieren
    set main_x [winfo x .]
    set main_y [winfo y .]
    set main_width [winfo width .]
    set main_height [winfo height .]

    # Neue Position berechnen (zentriert über dem Hauptfenster)
    set x_pos [expr {$main_x + ($main_width - 1600) / 2}]
    set y_pos [expr {$main_y + ($main_height - 800) / 2}]

    # Sicherstellen, dass die Position nicht negativ wird
    if {$x_pos < 0} { set x_pos 0 }
    if {$y_pos < 0} { set y_pos 0 }

    # Fensterposition setzen
    wm geometry $w +${x_pos}+${y_pos}

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 15
    pack $w.main -fill both -expand 1

    # Titel
    label $w.main.titel -text "Teilnahme am Training" \
        -font {Helvetica 14 bold} -fg "#333333"
    pack $w.main.titel -pady {5 0}

    # Untertitel mit Zeitraum
    label $w.main.untertitel -text "Zeitraum: $von_datum bis $bis_datum" \
        -font {Helvetica 10} -fg "#666666"
    pack $w.main.untertitel -pady {0 10}

    # Tabellen-Frame mit Scrollbar
    frame $w.main.tabelle
    pack $w.main.tabelle -fill both -expand 1

    # Treeview für die Teilnahme-Tabelle
    ttk::treeview $w.main.tabelle.tree \
        -columns {name kurz lang gesamt} \
        -show headings \
        -yscrollcommand "$w.main.tabelle.scroll set"
    pack $w.main.tabelle.tree -side left -fill both -expand 1

    # Vertikale Scrollbar
    scrollbar $w.main.tabelle.scroll -orient vertical \
        -command "$w.main.tabelle.tree yview"
    pack $w.main.tabelle.scroll -side right -fill y

    # Spaltenüberschriften
    $w.main.tabelle.tree heading name -text "Name"
    $w.main.tabelle.tree heading kurz -text "Kurzwaffe"
    $w.main.tabelle.tree heading lang -text "Langwaffe"
    $w.main.tabelle.tree heading gesamt -text "Summe Kurz+Lang"

    # Spaltenbreiten und Ausrichtung (füllen die breite Fensterfläche aus)
    $w.main.tabelle.tree column name -width 700 -anchor w
    $w.main.tabelle.tree column kurz -width 280 -anchor center
    $w.main.tabelle.tree column lang -width 280 -anchor center
    $w.main.tabelle.tree column gesamt -width 280 -anchor center

    # Farb-Tags definieren (Darstellung je nach Erfüllungsgrad)
    $w.main.tabelle.tree tag configure gruen -foreground "#1a9641"
    $w.main.tabelle.tree tag configure rot -foreground "#d7191c"
    $w.main.tabelle.tree tag configure schwarz -foreground "#000000"

    # Zeilen einfügen
    foreach zeile $ergebnis_liste {
        set tag [bestimme_farbtag $zeile]
        $w.main.tabelle.tree insert {} end -tags $tag -values [list \
            [dict get $zeile name] \
            "[dict get $zeile kurz] mal" \
            "[dict get $zeile lang] mal" \
            "[dict get $zeile gesamt] mal"]
    }

    # Legende
    labelframe $w.main.legende -text "Legende" -padx 10 -pady 5
    pack $w.main.legende -fill x -pady {10 5}

    # Grün-Legende
    label $w.main.legende.gruen \
        -text "Gr\u00fcn: mind. $mindest_teilnahmen Teilnahmen bei beiden Waffengattungen" \
        -fg "#1a9641" -anchor w
    pack $w.main.legende.gruen -fill x

    # Rot-Legende
    label $w.main.legende.rot \
        -text "Rot: noch keine Teilnahme" \
        -fg "#d7191c" -anchor w
    pack $w.main.legende.rot -fill x

    # Schwarz-Legende
    label $w.main.legende.schwarz \
        -text "Schwarz: Teilnahmen vorhanden, aber Mindestanzahl noch nicht erreicht" \
        -fg "#000000" -anchor w
    pack $w.main.legende.schwarz -fill x

    # Button-Frame
    frame $w.main.buttons
    pack $w.main.buttons -fill x -pady {10 5}

    # Button "HTML Export" (hellblau)
    button $w.main.buttons.export -text "HTML Export" -bg "#ADD8E6" -width 15 \
        -command {::teilnahme::exportiere_html}
    pack $w.main.buttons.export -side left -padx 10 -ipady 8

    # Button "Schließen" (rosa)
    button $w.main.buttons.schliessen -text "Schlie\u00dfen" -bg "#E0E0E0" -width 15 \
        -command {::teilnahme::schliesse_ergebnis_fenster}
    pack $w.main.buttons.schliessen -side right -padx 10 -ipady 8

    # Escape-Taste zum Schließen binden
    bind $w <Escape> {::teilnahme::schliesse_ergebnis_fenster}

    # Fokus auf das Fenster setzen
    focus $w
}

# =============================================================================
# Prozedur: schliesse_ergebnis_fenster
# Schließt das Ergebnisfenster
# =============================================================================
proc ::teilnahme::schliesse_ergebnis_fenster {} {
    variable ergebnis_fenster

    # Fenster zerstören
    if {[winfo exists $ergebnis_fenster]} {
        destroy $ergebnis_fenster
    }

    # Variable zurücksetzen
    set ergebnis_fenster ""
}

# =============================================================================
# Prozedur: erstelle_html_dokument
# Erstellt das komplette HTML-Dokument für den Export
# Rückgabe: HTML-Code als String
# =============================================================================
proc ::teilnahme::erstelle_html_dokument {} {
    variable von_datum
    variable bis_datum
    variable ergebnis_liste
    variable mindest_teilnahmen

    # HTML-Dokument mit eingebettetem CSS
    set html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n"
    append html "<head>\n"
    append html "  <meta charset=\"UTF-8\">\n"
    append html "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
    append html "  <title>SVM Journal - Teilnahme am Training</title>\n"
    append html "  <style>\n"

    # CSS-Styles
    append html "    * { box-sizing: border-box; }\n"
    append html "    body { font-family: Arial, Helvetica, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; color: #333; }\n"
    append html "    h1 { color: #333; text-align: center; margin-bottom: 5px; }\n"
    append html "    .subtitle { text-align: center; color: #666; margin-bottom: 30px; font-size: 1.1em; }\n"
    append html "    table { border-collapse: collapse; width: 100%; max-width: 800px; margin: 0 auto; background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }\n"
    append html "    th, td { padding: 10px 14px; border-bottom: 1px solid #eee; text-align: center; }\n"
    append html "    th { background-color: #4ACEFA; color: white; }\n"
    append html "    td.name { text-align: left; }\n"
    append html "    tr.gruen td { color: #1a9641; font-weight: bold; }\n"
    append html "    tr.rot td { color: #d7191c; font-weight: bold; }\n"
    append html "    tr.schwarz td { color: #000000; }\n"
    append html "    .legend { max-width: 800px; margin: 20px auto; padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }\n"
    append html "    .legend div { margin: 6px 0; }\n"
    append html "    .legend .gruen { color: #1a9641; font-weight: bold; }\n"
    append html "    .legend .rot { color: #d7191c; font-weight: bold; }\n"
    append html "    .legend .schwarz { color: #000000; }\n"
    append html "    .footer { margin-top: 40px; text-align: center; color: #888; font-size: 0.9em; padding-top: 20px; border-top: 1px solid #ddd; }\n"
    append html "    @media print { body { background: white; } table, .legend { box-shadow: none; border: 1px solid #ddd; } }\n"
    append html "  </style>\n"
    append html "</head>\n"
    append html "<body>\n"

    # Titel
    append html "  <h1>SVM Journal - Teilnahme am Training</h1>\n"
    append html "  <div class=\"subtitle\">Zeitraum: $von_datum bis $bis_datum</div>\n"

    # Tabelle
    append html "  <table>\n"
    append html "    <thead>\n"
    append html "      <tr><th>Name</th><th>Kurzwaffe</th><th>Langwaffe</th><th>Summe Kurz+Lang</th></tr>\n"
    append html "    </thead>\n"
    append html "    <tbody>\n"

    # Tabellenzeilen
    foreach zeile $ergebnis_liste {
        set tag [bestimme_farbtag $zeile]
        set name [::statistik::html_escape [dict get $zeile name]]
        set kurz [dict get $zeile kurz]
        set lang [dict get $zeile lang]
        set gesamt [dict get $zeile gesamt]
        append html "      <tr class=\"$tag\"><td class=\"name\">$name</td><td>$kurz mal</td><td>$lang mal</td><td>$gesamt mal</td></tr>\n"
    }

    append html "    </tbody>\n"
    append html "  </table>\n"

    # Legende
    append html "  <div class=\"legend\">\n"
    append html "    <div class=\"gruen\">Gr&uuml;n: mind. $mindest_teilnahmen Teilnahmen bei beiden Waffengattungen</div>\n"
    append html "    <div class=\"rot\">Rot: noch keine Teilnahme</div>\n"
    append html "    <div class=\"schwarz\">Schwarz: Teilnahmen vorhanden, aber Mindestanzahl noch nicht erreicht</div>\n"
    append html "  </div>\n"

    # Footer
    set timestamp [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]
    append html "  <div class=\"footer\">Erstellt am: $timestamp mit SVM Journal</div>\n"

    append html "</body>\n"
    append html "</html>\n"

    return $html
}

# =============================================================================
# Prozedur: exportiere_html
# Exportiert die Teilnahme-Auswertung als HTML-Datei
# =============================================================================
proc ::teilnahme::exportiere_html {} {
    variable ergebnis_fenster
    variable von_datum
    variable bis_datum

    # Standarddateiname mit Zeitraum
    set von_kurz [string map {"." ""} $von_datum]
    set bis_kurz [string map {"." ""} $bis_datum]
    set standard_name "Teilnahme_${von_kurz}_bis_${bis_kurz}.html"

    # Datei-Dialog öffnen
    set dateiname [tk_getSaveFile \
        -parent $ergebnis_fenster \
        -title "Teilnahme am Training als HTML speichern" \
        -defaultextension ".html" \
        -initialfile $standard_name \
        -filetypes {{"HTML-Dateien" {.html .htm}} {"Alle Dateien" {*}}}]

    # Abbruch wenn kein Dateiname gewählt
    if {$dateiname eq ""} {
        return
    }

    # HTML-Dokument erstellen
    set html [erstelle_html_dokument]

    # Datei schreiben
    if {[catch {
        set fh [open $dateiname w]
        fconfigure $fh -encoding utf-8
        puts $fh $html
        close $fh
    } err]} {
        tk_messageBox -parent $ergebnis_fenster -icon error -title "Fehler" \
            -message "Fehler beim Speichern der Datei:\n$err"
        return
    }

    # Erfolgsmeldung
    tk_messageBox -parent $ergebnis_fenster -icon info -title "Export erfolgreich" \
        -message "Die Auswertung wurde erfolgreich exportiert nach:\n$dateiname"
}
