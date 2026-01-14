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

    # Feldauswahl-Variablen (1 = ausgewählt, 0 = nicht ausgewählt)
    variable feld_datum 1
    variable feld_nachname 1
    variable feld_vorname 1
    variable feld_kw 1
    variable feld_lw 1
    variable feld_typ 1
    variable feld_kaliber 1
    variable feld_startgeld 0
    variable feld_munition 0
    variable feld_munpreis 0
}

# =============================================================================
# Prozedur: get_feld_definitionen
# Gibt eine Liste aller verfügbaren Exportfelder zurück
# Jedes Feld ist eine Liste mit: {anzeigename dict_key variable_name}
# Rückgabe: Liste von Feld-Definitionen
# =============================================================================
proc ::export::get_feld_definitionen {} {
    return [list \
        [list "Datum" "datum" "::export::feld_datum"] \
        [list "Nachname" "nachname" "::export::feld_nachname"] \
        [list "Vorname" "vorname" "::export::feld_vorname"] \
        [list "KW" "kurzwaffe" "::export::feld_kw"] \
        [list "LW" "langwaffe" "::export::feld_lw"] \
        [list "Typ" "waffentyp" "::export::feld_typ"] \
        [list "Kaliber" "kaliber" "::export::feld_kaliber"] \
        [list "Startgeld" "startgeld" "::export::feld_startgeld"] \
        [list "Munition" "munition" "::export::feld_munition"] \
        [list "Mun.Preis" "munitionspreis" "::export::feld_munpreis"] \
    ]
}

# =============================================================================
# Prozedur: get_ausgewaehlte_felder
# Filtert die Feld-Definitionen nach ausgewählten Checkboxen
# Rückgabe: Liste von Feld-Definitionen, die exportiert werden sollen
# =============================================================================
proc ::export::get_ausgewaehlte_felder {} {
    set alle_felder [get_feld_definitionen]
    set ausgewaehlte [list]

    # Durch alle Felder iterieren und nur die ausgewählten behalten
    foreach feld $alle_felder {
        lassign $feld anzeigename dict_key var_name

        # Prüfen, ob die zugehörige Variable auf 1 gesetzt ist
        if {[set $var_name] == 1} {
            lappend ausgewaehlte $feld
        }
    }

    return $ausgewaehlte
}

# =============================================================================
# Prozedur: pruefe_feldauswahl
# Prüft, ob mindestens ein Feld ausgewählt ist
# Wird aufgerufen, wenn eine Checkbox geändert wird
# Deaktiviert den Export-Button, wenn keine Felder ausgewählt sind
# =============================================================================
proc ::export::pruefe_feldauswahl {args} {
    variable fenster

    # Prüfen ob das Fenster noch existiert (wichtig bei Traces!)
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

    # Prüfen ob mindestens ein Feld ausgewählt ist
    set ausgewaehlte_felder [get_ausgewaehlte_felder]

    # Export-Button existiert und ist normal aktiviert
    if {[winfo exists $fenster.button_frame.export]} {
        # Wenn keine Felder ausgewählt: deaktivieren
        if {[llength $ausgewaehlte_felder] == 0} {
            $fenster.button_frame.export configure -state disabled
        } else {
            # Sonst: normale Prüfung über pruefe_export_button
            pruefe_export_button
        }
    }
}

# =============================================================================
# Prozedur: waehle_alle_felder
# Setzt alle Feldauswahl-Variablen auf 1 (ausgewählt)
# =============================================================================
proc ::export::waehle_alle_felder {} {
    variable feld_datum
    variable feld_nachname
    variable feld_vorname
    variable feld_kw
    variable feld_lw
    variable feld_typ
    variable feld_kaliber
    variable feld_startgeld
    variable feld_munition
    variable feld_munpreis

    # Alle Felder auf 1 setzen
    set feld_datum 1
    set feld_nachname 1
    set feld_vorname 1
    set feld_kw 1
    set feld_lw 1
    set feld_typ 1
    set feld_kaliber 1
    set feld_startgeld 1
    set feld_munition 1
    set feld_munpreis 1
}

# =============================================================================
# Prozedur: waehle_keine_felder
# Setzt alle Feldauswahl-Variablen auf 0 (nicht ausgewählt)
# =============================================================================
proc ::export::waehle_keine_felder {} {
    variable feld_datum
    variable feld_nachname
    variable feld_vorname
    variable feld_kw
    variable feld_lw
    variable feld_typ
    variable feld_kaliber
    variable feld_startgeld
    variable feld_munition
    variable feld_munpreis

    # Alle Felder auf 0 setzen
    set feld_datum 0
    set feld_nachname 0
    set feld_vorname 0
    set feld_kw 0
    set feld_lw 0
    set feld_typ 0
    set feld_kaliber 0
    set feld_startgeld 0
    set feld_munition 0
    set feld_munpreis 0
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

    # Prüfen ob das Fenster noch existiert (wichtig bei Traces!)
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

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
# Prozedur: schliesse_export_dialog
# Entfernt alle Traces und schließt den Dialog
# Diese Prozedur verhindert, dass Traces auf zerstörte Widgets zugreifen
# =============================================================================
proc ::export::schliesse_export_dialog {} {
    variable fenster

    # Alle Traces entfernen, um Fehler beim nächsten Öffnen zu vermeiden
    trace remove variable ::export::von_datum write ::export::pruefe_export_button
    trace remove variable ::export::bis_datum write ::export::pruefe_export_button
    trace remove variable ::export::person_suche write ::export::person_suche_geaendert

    # Traces für Feldauswahl entfernen
    trace remove variable ::export::feld_datum write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_nachname write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_vorname write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_kw write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_lw write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_typ write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_kaliber write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_startgeld write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_munition write ::export::pruefe_feldauswahl
    trace remove variable ::export::feld_munpreis write ::export::pruefe_feldauswahl

    # Fenster schließen
    if {[winfo exists $fenster]} {
        destroy $fenster
    }
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

    # Prüfen ob das Fenster noch existiert (wichtig bei Traces!)
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

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

    # Prüfen ob das Fenster noch existiert (wichtig bei Traces!)
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

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

    # Prüfen ob das Fenster noch existiert (wichtig bei Traces!)
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

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
# Lädt alle Einträge aus den JSON-Dateien im daten-Verzeichnis
# Rückgabe: Liste von Eintrags-Dictionaries
# =============================================================================
proc ::export::lade_alle_eintraege {} {
    global script_dir

    # Liste für alle Einträge
    set alle_eintraege [list]

    # Daten-Verzeichnis vom Pfad-Management abrufen
    set daten_dir [::pfad::get_daten_directory]

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
# Exportiert nur die ausgewählten Felder
# Parameter:
#   eintraege - Liste von Eintrags-Dictionaries
# Rückgabe: Markdown-String
# =============================================================================
proc ::export::erstelle_markdown_tabelle {eintraege} {
    # Ausgewählte Felder ermitteln
    set felder [get_ausgewaehlte_felder]

    # Markdown-Header erstellen
    set markdown "# SVM Journal Export\n\n"
    append markdown "Exportiert am: [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]\n\n"

    # Tabellen-Header-Zeile erstellen (| Feld1 | Feld2 | ... |)
    append markdown "|"
    foreach feld $felder {
        lassign $feld anzeigename dict_key var_name
        append markdown " $anzeigename |"
    }
    append markdown "\n"

    # Trennlinie erstellen (|-------|-------|-----|)
    append markdown "|"
    foreach feld $felder {
        append markdown "-------|"
    }
    append markdown "\n"

    # Einträge zur Tabelle hinzufügen
    foreach eintrag $eintraege {
        append markdown "|"
        foreach feld $felder {
            lassign $feld anzeigename dict_key var_name
            set wert [dict get $eintrag $dict_key]
            append markdown " $wert |"
        }
        append markdown "\n"
    }

    # Fußzeile
    append markdown "\n---\n\n"
    append markdown "Anzahl Einträge: [llength $eintraege]\n"

    return $markdown
}

# =============================================================================
# Prozedur: erstelle_html_tabelle
# Konvertiert Einträge in eine HTML-Tabelle mit CSS
# Exportiert nur die ausgewählten Felder
# Parameter:
#   eintraege - Liste von Eintrags-Dictionaries
# Rückgabe: HTML-String
# =============================================================================
proc ::export::erstelle_html_tabelle {eintraege} {
    # Ausgewählte Felder ermitteln
    set felder [get_ausgewaehlte_felder]

    # HTML-Dokument erstellen mit CSS
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

    # Tabellen-Header (TH-Elemente)
    foreach feld $felder {
        lassign $feld anzeigename dict_key var_name
        append html "        <th>$anzeigename</th>\n"
    }

    append html "      </tr>\n"
    append html "    </thead>\n"
    append html "    <tbody>\n"

    # Einträge zur Tabelle hinzufügen
    foreach eintrag $eintraege {
        append html "      <tr>\n"

        # Daten-Zellen (TD-Elemente)
        foreach feld $felder {
            lassign $feld anzeigename dict_key var_name
            set wert [dict get $eintrag $dict_key]
            append html "        <td>$wert</td>\n"
        }

        append html "      </tr>\n"
    }

    # Abschluss der Tabelle und Dokument
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

    # Prüfen ob mindestens ein Feld ausgewählt ist
    set ausgewaehlte_felder [get_ausgewaehlte_felder]
    if {[llength $ausgewaehlte_felder] == 0} {
        tk_messageBox -parent $fenster -icon warning -title "Export" \
            -message "Bitte w\u00e4hlen Sie mindestens ein Feld f\u00fcr den Export aus."
        return
    }

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

    # Dialog schließen (mit Trace-Cleanup)
    schliesse_export_dialog
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

    # Feldauswahl zurücksetzen (Standard-Vorauswahl)
    set ::export::feld_datum 1
    set ::export::feld_nachname 1
    set ::export::feld_vorname 1
    set ::export::feld_kw 1
    set ::export::feld_lw 1
    set ::export::feld_typ 1
    set ::export::feld_kaliber 1
    set ::export::feld_startgeld 0
    set ::export::feld_munition 0
    set ::export::feld_munpreis 0

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

    wm geometry $w "600x700"

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
    # Feldauswahl - Checkboxen für zu exportierende Felder
    # =========================================================================
    labelframe $w.felder_frame -text "Felder f\u00fcr Export" -padx 10 -pady 10
    pack $w.felder_frame -in $w.main -fill x -pady 10

    # Frame für "Alle auswählen" / "Alle abwählen" Buttons
    frame $w.felder_frame.button_row
    pack $w.felder_frame.button_row -anchor w -pady 5

    # Button "Alle auswählen"
    button $w.felder_frame.button_row.alle -text "Alle ausw\u00e4hlen" -bg "#E0E0E0" -width 15 \
        -command ::export::waehle_alle_felder
    pack $w.felder_frame.button_row.alle -side left -padx 5

    # Button "Alle abwählen"
    button $w.felder_frame.button_row.keine -text "Alle abw\u00e4hlen" -bg "#E0E0E0" -width 15 \
        -command ::export::waehle_keine_felder
    pack $w.felder_frame.button_row.keine -side left -padx 5

    # Frame für Checkboxen (2 Spalten Layout)
    frame $w.felder_frame.checks
    pack $w.felder_frame.checks -fill x

    # Linke Spalte (Felder 1-5)
    frame $w.felder_frame.checks.left
    pack $w.felder_frame.checks.left -side left -fill both -expand 1

    checkbutton $w.felder_frame.checks.left.datum -text "Datum" \
        -variable ::export::feld_datum -font {Arial 11}
    pack $w.felder_frame.checks.left.datum -anchor w -pady 3

    checkbutton $w.felder_frame.checks.left.nachname -text "Nachname" \
        -variable ::export::feld_nachname -font {Arial 11}
    pack $w.felder_frame.checks.left.nachname -anchor w -pady 3

    checkbutton $w.felder_frame.checks.left.vorname -text "Vorname" \
        -variable ::export::feld_vorname -font {Arial 11}
    pack $w.felder_frame.checks.left.vorname -anchor w -pady 3

    checkbutton $w.felder_frame.checks.left.kw -text "KW" \
        -variable ::export::feld_kw -font {Arial 11}
    pack $w.felder_frame.checks.left.kw -anchor w -pady 3

    checkbutton $w.felder_frame.checks.left.lw -text "LW" \
        -variable ::export::feld_lw -font {Arial 11}
    pack $w.felder_frame.checks.left.lw -anchor w -pady 3

    # Rechte Spalte (Felder 6-10)
    frame $w.felder_frame.checks.right
    pack $w.felder_frame.checks.right -side right -fill both -expand 1

    checkbutton $w.felder_frame.checks.right.typ -text "Typ" \
        -variable ::export::feld_typ -font {Arial 11}
    pack $w.felder_frame.checks.right.typ -anchor w -pady 3

    checkbutton $w.felder_frame.checks.right.kaliber -text "Kaliber" \
        -variable ::export::feld_kaliber -font {Arial 11}
    pack $w.felder_frame.checks.right.kaliber -anchor w -pady 3

    checkbutton $w.felder_frame.checks.right.startgeld -text "Startgeld" \
        -variable ::export::feld_startgeld -font {Arial 11}
    pack $w.felder_frame.checks.right.startgeld -anchor w -pady 3

    checkbutton $w.felder_frame.checks.right.munition -text "Munition" \
        -variable ::export::feld_munition -font {Arial 11}
    pack $w.felder_frame.checks.right.munition -anchor w -pady 3

    checkbutton $w.felder_frame.checks.right.munpreis -text "Mun.Preis" \
        -variable ::export::feld_munpreis -font {Arial 11}
    pack $w.felder_frame.checks.right.munpreis -anchor w -pady 3

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
        -command ::export::schliesse_export_dialog
    pack $w.button_frame.cancel -side right -padx 5

    # =========================================================================
    # Traces für Validierung setzen (nach Button-Erstellung!)
    # =========================================================================
    # Trace für Datumsfelder - Export-Button-Validierung
    trace add variable ::export::von_datum write ::export::pruefe_export_button
    trace add variable ::export::bis_datum write ::export::pruefe_export_button

    # Trace für Live-Suche
    trace add variable ::export::person_suche write ::export::person_suche_geaendert

    # Traces für Feldauswahl-Checkboxen - Validierung
    trace add variable ::export::feld_datum write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_nachname write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_vorname write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_kw write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_lw write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_typ write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_kaliber write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_startgeld write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_munition write ::export::pruefe_feldauswahl
    trace add variable ::export::feld_munpreis write ::export::pruefe_feldauswahl

    # =========================================================================
    # Initiale Prüfung des Export-Buttons
    # =========================================================================
    ::export::pruefe_export_button

    # Focus auf Fenster setzen
    focus $w
}
