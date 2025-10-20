# =============================================================================
# Neuer-Eintrag-Fenster für das svm-journal Projekt
# Erstellt ein Fenster zur Erfassung neuer Schießstand-Einträge
# =============================================================================

# Globale Variablen für das Neuer-Eintrag-Fenster
namespace eval ::neuer_eintrag {
    # Variablen für die Eingabefelder
    variable datum ""
    variable nachname ""
    variable vorname ""
    variable kurzwaffe 0
    variable langwaffe 0
    variable waffentyp ""
    variable kaliber ""
    variable startgeld "0,00"
    variable munition "Keine"
    variable munitionspreis "0,00"

    # Mitgliederliste für Autovervollständigung
    variable mitglieder_dict [dict create]

    # Kaliber-Preisliste
    variable kaliber_preise_dict [dict create]

    # Stand-Nutzungs-Preise
    variable stand_preise [dict create]

    # Fenster-Referenz
    variable fenster ""

    # Autovervollständigungs-Listbox
    variable autocomplete_listbox ""
    variable autocomplete_visible 0
}

# =============================================================================
# Prozedur: lade_mitglieder_daten
# Lädt die Mitgliederdaten aus der JSON-Datei in ein Dictionary
# =============================================================================
proc ::neuer_eintrag::lade_mitglieder_daten {} {
    variable mitglieder_dict
    global mitglieder_json

    # Mitglieder-Dictionary leeren
    set mitglieder_dict [dict create]

    # Prüfen, ob Datei existiert
    if {![file exists $mitglieder_json]} {
        return
    }

    # Datei öffnen und parsen
    set fp [open $mitglieder_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Einfaches Parsing der Mitglieder (Zeile für Zeile)
    # Suche nach "nachname" und "vorname" Paaren
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

            # Wenn beide vorhanden, zum Dictionary hinzufügen
            if {$aktueller_nachname ne "" && $aktueller_vorname ne ""} {
                # Dictionary: Nachname -> Liste von Vornamen
                if {[dict exists $mitglieder_dict $aktueller_nachname]} {
                    dict lappend mitglieder_dict $aktueller_nachname $aktueller_vorname
                } else {
                    dict set mitglieder_dict $aktueller_nachname [list $aktueller_vorname]
                }
                set aktueller_nachname ""
                set aktueller_vorname ""
            }
        }
    }
}

# =============================================================================
# Prozedur: lade_kaliber_preise
# Lädt die Kaliber-Preise aus der JSON-Datei
# =============================================================================
proc ::neuer_eintrag::lade_kaliber_preise {} {
    variable kaliber_preise_dict
    global kaliber_preise_json

    # Dictionary leeren
    set kaliber_preise_dict [dict create]

    # Prüfen, ob Datei existiert
    if {![file exists $kaliber_preise_json]} {
        return
    }

    # Datei öffnen und parsen
    set fp [open $kaliber_preise_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Einfaches Parsing der Kaliber-Preise
    set lines [split $json_content "\n"]
    set aktuelles_kaliber ""
    set aktueller_preis ""

    foreach line $lines {
        # Kaliber extrahieren
        if {[regexp {"kaliber":\s*"([^"]*)"} $line -> kaliber]} {
            set aktuelles_kaliber [string trim $kaliber]
        }
        # Preis extrahieren
        if {[regexp {"preis":\s*"([^"]*)"} $line -> preis]} {
            set aktueller_preis [string trim $preis]

            # Wenn beide vorhanden, zum Dictionary hinzufügen
            if {$aktuelles_kaliber ne "" && $aktueller_preis ne ""} {
                dict set kaliber_preise_dict $aktuelles_kaliber $aktueller_preis
                set aktuelles_kaliber ""
                set aktueller_preis ""
            }
        }
    }
}

# =============================================================================
# Prozedur: lade_stand_preise
# Lädt die Stand-Nutzungs-Preise aus der JSON-Datei
# =============================================================================
proc ::neuer_eintrag::lade_stand_preise {} {
    variable stand_preise
    global stand_nutzung_json

    # Dictionary leeren
    set stand_preise [dict create]

    # Prüfen, ob Datei existiert
    if {![file exists $stand_nutzung_json]} {
        return
    }

    # Datei öffnen und parsen
    set fp [open $stand_nutzung_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Einfaches Parsing der Stand-Preise
    set lines [split $json_content "\n"]

    foreach line $lines {
        # Mitglied Luftdruck
        if {[regexp {"Mitglied Luftdruck":\s*"([^"]*)"} $line -> preis]} {
            dict set stand_preise "Mitglied Luftdruck" [string trim $preis]
        }
        # Mitglied Kleinkaliber
        if {[regexp {"Mitglied Kleinkaliber":\s*"([^"]*)"} $line -> preis]} {
            dict set stand_preise "Mitglied Kleinkaliber" [string trim $preis]
        }
        # Mitglied Grosskaliber
        if {[regexp {"Mitglied Grosskaliber":\s*"([^"]*)"} $line -> preis]} {
            dict set stand_preise "Mitglied Grosskaliber" [string trim $preis]
        }
        # Gast
        if {[regexp {"Gast":\s*"([^"]*)"} $line -> preis]} {
            dict set stand_preise "Gast" [string trim $preis]
        }
        # Gilde
        if {[regexp {"Gilde":\s*"([^"]*)"} $line -> preis]} {
            dict set stand_preise "Gilde" [string trim $preis]
        }
    }
}

# =============================================================================
# Prozedur: berechne_startgeld
# Berechnet das Startgeld basierend auf den eingegebenen Daten
# =============================================================================
proc ::neuer_eintrag::berechne_startgeld {} {
    variable nachname
    variable waffentyp
    variable mitglieder_dict
    variable stand_preise
    variable startgeld

    # Prüfen, ob der Schütze ein Mitglied ist
    set ist_mitglied [dict exists $mitglieder_dict $nachname]

    # Startgeld basierend auf Waffentyp und Mitgliedschaft berechnen
    if {$ist_mitglied} {
        # Mitglied - Preis nach Waffentyp
        switch -exact $waffentyp {
            "LD" {
                if {[dict exists $stand_preise "Mitglied Luftdruck"]} {
                    set startgeld [dict get $stand_preise "Mitglied Luftdruck"]
                }
            }
            "KK" {
                if {[dict exists $stand_preise "Mitglied Kleinkaliber"]} {
                    set startgeld [dict get $stand_preise "Mitglied Kleinkaliber"]
                }
            }
            "GK" {
                if {[dict exists $stand_preise "Mitglied Grosskaliber"]} {
                    set startgeld [dict get $stand_preise "Mitglied Grosskaliber"]
                }
            }
        }
    } else {
        # Gast - Pauschalpreis
        if {[dict exists $stand_preise "Gast"]} {
            set startgeld [dict get $stand_preise "Gast"]
        }
    }
}

# =============================================================================
# Prozedur: nachname_geaendert
# Wird aufgerufen, wenn sich der Nachname ändert
# Zeigt Autovervollständigung an und füllt ggf. Vorname aus
# =============================================================================
proc ::neuer_eintrag::nachname_geaendert {args} {
    variable nachname
    variable vorname
    variable mitglieder_dict
    variable fenster
    variable autocomplete_listbox
    variable autocomplete_visible

    # Startgeld neu berechnen
    berechne_startgeld

    # Wenn Nachname leer, Autovervollständigung ausblenden
    if {$nachname eq ""} {
        if {$autocomplete_visible} {
            pack forget $autocomplete_listbox
            set autocomplete_visible 0
        }
        return
    }

    # Suche nach passenden Nachnamen
    set matches [list]
    dict for {name vornamen} $mitglieder_dict {
        # Case-insensitive Matching
        if {[string match -nocase "${nachname}*" $name]} {
            lappend matches $name
        }
    }

    # Autovervollständigungs-Listbox aktualisieren
    $autocomplete_listbox delete 0 end
    foreach match $matches {
        $autocomplete_listbox insert end $match
    }

    # Listbox anzeigen, wenn Treffer vorhanden
    if {[llength $matches] > 0} {
        if {!$autocomplete_visible} {
            pack $autocomplete_listbox -in $fenster.name_frame -side bottom -fill x -after $fenster.name_frame.name_entry
            set autocomplete_visible 1
        }

        # Wenn genau ein Treffer und exakte Übereinstimmung, Vorname ausfüllen
        if {[llength $matches] == 1} {
            set exact_match [lindex $matches 0]
            if {[string equal -nocase $nachname $exact_match]} {
                # Nachname genau gefunden - Vorname ausfüllen
                set vornamen_liste [dict get $mitglieder_dict $exact_match]
                if {[llength $vornamen_liste] == 1} {
                    # Eindeutiger Vorname - automatisch ausfüllen
                    set vorname [lindex $vornamen_liste 0]
                    # Korrekten Nachnamen setzen (mit richtiger Groß-/Kleinschreibung)
                    set nachname $exact_match
                    # Autovervollständigung ausblenden
                    pack forget $autocomplete_listbox
                    set autocomplete_visible 0
                }
            }
        }
    } else {
        # Keine Treffer - ausblenden
        if {$autocomplete_visible} {
            pack forget $autocomplete_listbox
            set autocomplete_visible 0
        }
    }
}

# =============================================================================
# Prozedur: autocomplete_ausgewaehlt
# Wird aufgerufen, wenn ein Eintrag aus der Autovervollständigung gewählt wird
# =============================================================================
proc ::neuer_eintrag::autocomplete_ausgewaehlt {args} {
    variable nachname
    variable vorname
    variable mitglieder_dict
    variable autocomplete_listbox
    variable autocomplete_visible

    # Aktuell ausgewählten Eintrag holen
    set selection [$autocomplete_listbox curselection]
    if {$selection eq ""} {
        return
    }

    set selected_name [$autocomplete_listbox get $selection]
    set nachname $selected_name

    # Vorname ausfüllen, wenn eindeutig
    if {[dict exists $mitglieder_dict $selected_name]} {
        set vornamen_liste [dict get $mitglieder_dict $selected_name]
        if {[llength $vornamen_liste] == 1} {
            set vorname [lindex $vornamen_liste 0]
        } else {
            # Mehrere Vornamen - Vorname-Feld leeren
            set vorname ""
        }
    }

    # Autovervollständigung ausblenden
    pack forget $autocomplete_listbox
    set autocomplete_visible 0

    # Startgeld neu berechnen
    berechne_startgeld
}

# =============================================================================
# Prozedur: waffentyp_geaendert
# Wird aufgerufen, wenn sich der Waffentyp ändert
# =============================================================================
proc ::neuer_eintrag::waffentyp_geaendert {args} {
    # Startgeld neu berechnen
    berechne_startgeld
}

# =============================================================================
# Prozedur: munition_geaendert
# Wird aufgerufen, wenn sich die Munitionsauswahl ändert
# =============================================================================
proc ::neuer_eintrag::munition_geaendert {args} {
    variable munition
    variable munitionspreis
    variable kaliber_preise_dict

    # Preis für gewähltes Kaliber setzen
    if {$munition eq "Keine"} {
        set munitionspreis "0,00"
    } elseif {[dict exists $kaliber_preise_dict $munition]} {
        set munitionspreis [dict get $kaliber_preise_dict $munition]
    }
}

# =============================================================================
# Prozedur: pruefe_speichern_button
# Wird aufgerufen, wenn sich ein Eingabefeld ändert
# Aktiviert/Deaktiviert den Speichern-Button basierend auf allen Pflichtfeldern
# =============================================================================
proc ::neuer_eintrag::pruefe_speichern_button {args} {
    variable datum
    variable nachname
    variable vorname
    variable kurzwaffe
    variable langwaffe
    variable waffentyp
    variable kaliber
    variable fenster

    # Prüfen ob alle Pflichtfelder ausgefüllt sind
    set alle_felder_ok 1

    # Datum muss ausgefüllt sein
    if {[string trim $datum] eq ""} {
        set alle_felder_ok 0
    }

    # Nachname muss ausgefüllt sein
    if {[string trim $nachname] eq ""} {
        set alle_felder_ok 0
    }

    # Vorname muss ausgefüllt sein
    if {[string trim $vorname] eq ""} {
        set alle_felder_ok 0
    }

    # Mindestens eine Waffe muss ausgewählt sein
    if {!$kurzwaffe && !$langwaffe} {
        set alle_felder_ok 0
    }

    # Waffentyp muss ausgewählt sein
    if {$waffentyp eq ""} {
        set alle_felder_ok 0
    }

    # Kaliber muss ausgefüllt sein
    if {[string trim $kaliber] eq ""} {
        set alle_felder_ok 0
    }

    # Button aktivieren oder deaktivieren
    if {$alle_felder_ok} {
        $fenster.button_frame.save configure -state normal
    } else {
        $fenster.button_frame.save configure -state disabled
    }
}

# =============================================================================
# Prozedur: validiere_eingaben
# Validiert alle Eingaben vor dem Speichern
# Rückgabe: 1 bei Erfolg, 0 bei Fehler
# =============================================================================
proc ::neuer_eintrag::validiere_eingaben {} {
    variable datum
    variable nachname
    variable vorname
    variable kurzwaffe
    variable langwaffe
    variable kaliber
    variable fenster

    # Prüfen, ob Datum ausgefüllt ist
    if {$datum eq ""} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Bitte geben Sie ein Datum ein."
        return 0
    }

    # Prüfen, ob Datum gültiges Format hat (DD.MM.YYYY)
    if {![regexp {^(\d{2})\.(\d{2})\.(\d{4})$} $datum -> tag monat jahr]} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Ungültiges Datumsformat. Bitte verwenden Sie das Format TT.MM.JJJJ (z.B. 19.10.2025)."
        return 0
    }

    # Prüfen, ob das Datum in der Zukunft liegt
    # Aktuelles Datum als Vergleichswert (Format: YYYYMMDD)
    set heute [clock format [clock seconds] -format "%Y%m%d"]

    # Eingegebenes Datum als Vergleichswert konvertieren
    set eingabe_datum "${jahr}${monat}${tag}"

    # Vergleich: Wenn eingegebenes Datum größer als heute, liegt es in der Zukunft
    if {$eingabe_datum > $heute} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Das eingegebene Datum ($datum) liegt in der Zukunft.\n\nBitte geben Sie ein heutiges oder vergangenes Datum ein."
        return 0
    }

    # Prüfen, ob Name ausgefüllt ist
    if {$nachname eq ""} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Bitte geben Sie einen Nachnamen ein."
        return 0
    }

    # Prüfen, ob Vorname ausgefüllt ist
    if {$vorname eq ""} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Bitte geben Sie einen Vornamen ein."
        return 0
    }

    # Prüfen, ob mindestens eine Waffe ausgewählt ist
    if {!$kurzwaffe && !$langwaffe} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Bitte wählen Sie mindestens eine Waffe aus (Kurzwaffe oder Langwaffe)."
        return 0
    }

    # Prüfen, ob Kaliber ausgefüllt ist
    if {$kaliber eq ""} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" -message "Bitte geben Sie ein Kaliber ein."
        return 0
    }

    return 1
}

# =============================================================================
# Prozedur: speichern_und_anzeigen
# Speichert den Eintrag in der JSON-Datei und zeigt ihn im Hauptfenster an
# =============================================================================
proc ::neuer_eintrag::speichern_und_anzeigen {} {
    variable datum
    variable nachname
    variable vorname
    variable kurzwaffe
    variable langwaffe
    variable waffentyp
    variable kaliber
    variable startgeld
    variable munition
    variable munitionspreis
    variable fenster
    global script_dir

    # Eingaben validieren
    if {![validiere_eingaben]} {
        return
    }

    # Jahr aus dem eingegebenen Datum extrahieren (Format: DD.MM.YYYY)
    if {[regexp {^\d{2}\.\d{2}\.(\d{4})$} $datum -> jahr]} {
        # Jahr erfolgreich extrahiert
    } else {
        # Fallback: Aktuelles Jahr verwenden, falls Datum ungültig
        set jahr [clock format [clock seconds] -format "%Y"]
    }

    # Uhrzeit für JSON-Datei ermitteln
    set uhrzeit [clock format [clock seconds] -format "%H:%M:%S"]

    # Aktuelles Jahr ermitteln (für Prüfung ob Archiv)
    set aktuelles_jahr [clock format [clock seconds] -format "%Y"]

    # Pfad zur Jahres-JSON-Datei bestimmen
    # Wenn das Jahr des Eintrags kleiner als das aktuelle Jahr ist, ins Archiv
    if {$jahr < $aktuelles_jahr} {
        # Archiv-Verzeichnis erstellen falls nicht vorhanden
        set archiv_dir [file join $script_dir daten archiv]
        if {![file exists $archiv_dir]} {
            file mkdir $archiv_dir
        }
        set jahres_json [file join $archiv_dir "${jahr}.json"]
    } else {
        # Aktuelles Jahr - in daten/ speichern
        set jahres_json [file join $script_dir daten "${jahr}.json"]
    }

    # Eintrag als Dictionary erstellen
    set eintrag [dict create \
        "datum" $datum \
        "uhrzeit" $uhrzeit \
        "nachname" $nachname \
        "vorname" $vorname \
        "kurzwaffe" [expr {$kurzwaffe ? "Ja" : "Nein"}] \
        "langwaffe" [expr {$langwaffe ? "Ja" : "Nein"}] \
        "waffentyp" $waffentyp \
        "kaliber" $kaliber \
        "startgeld" $startgeld \
        "munition" $munition \
        "munitionspreis" $munitionspreis \
    ]

    # Eintrag zur JSON-Datei hinzufügen
    speichere_eintrag_json $jahres_json $eintrag

    # Eintrag im Hauptfenster anzeigen
    zeige_eintrag_im_hauptfenster $eintrag

    # Fenster schließen (ohne Erfolgsmeldung)
    destroy $fenster
}

# =============================================================================
# Hilfsprozedur: datum_zu_vergleichswert
# Konvertiert ein Datum im Format DD.MM.YYYY zu YYYYMMDD für Vergleiche
# Parameter:
#   datum_str - Datumsstring im Format DD.MM.YYYY
# Rückgabe: String im Format YYYYMMDD oder leerer String bei Fehler
# =============================================================================
proc ::neuer_eintrag::datum_zu_vergleichswert {datum_str} {
    # Datum im Format DD.MM.YYYY parsen
    if {[regexp {^(\d{2})\.(\d{2})\.(\d{4})$} $datum_str -> tag monat jahr]} {
        # In YYYYMMDD Format konvertieren für einfachen Vergleich
        return "${jahr}${monat}${tag}"
    }
    # Bei Fehler: aktuelles Datum zurückgeben
    return [clock format [clock seconds] -format "%Y%m%d"]
}

# =============================================================================
# Hilfsprozedur: vergleiche_eintraege
# Vergleichsfunktion für lsort zum Sortieren von Einträgen nach Datum und Uhrzeit
# Parameter:
#   eintrag1, eintrag2 - Zwei Eintrags-Dictionaries
# Rückgabe: -1 wenn eintrag1 < eintrag2, 0 wenn gleich, 1 wenn eintrag1 > eintrag2
# =============================================================================
proc ::neuer_eintrag::vergleiche_eintraege {eintrag1 eintrag2} {
    # Datum und Uhrzeit aus beiden Einträgen extrahieren
    set datum1 [dict get $eintrag1 datum]
    set uhrzeit1 [dict get $eintrag1 uhrzeit]
    set datum2 [dict get $eintrag2 datum]
    set uhrzeit2 [dict get $eintrag2 uhrzeit]

    # Datum in vergleichbares Format konvertieren
    set datum1_vgl [datum_zu_vergleichswert $datum1]
    set datum2_vgl [datum_zu_vergleichswert $datum2]

    # Zuerst nach Datum sortieren
    if {$datum1_vgl < $datum2_vgl} {
        return -1
    } elseif {$datum1_vgl > $datum2_vgl} {
        return 1
    }

    # Bei gleichem Datum nach Uhrzeit sortieren
    if {$uhrzeit1 < $uhrzeit2} {
        return -1
    } elseif {$uhrzeit1 > $uhrzeit2} {
        return 1
    }

    # Beide Einträge sind gleich
    return 0
}

# =============================================================================
# Prozedur: speichere_eintrag_json
# Speichert einen Eintrag in die JSON-Datei
# Parameter:
#   dateiPfad - Pfad zur JSON-Datei
#   eintrag - Dictionary mit dem Eintrag
# =============================================================================
proc ::neuer_eintrag::speichere_eintrag_json {dateiPfad eintrag} {
    # Existierende Einträge laden (falls Datei existiert)
    set eintraege [list]

    if {[file exists $dateiPfad]} {
        # Datei einlesen
        set fp [open $dateiPfad r]
        fconfigure $fp -encoding utf-8
        set json_content [read $fp]
        close $fp

        # Existierende Einträge extrahieren und parsen
        set lines [split $json_content "\n"]
        set eintrag_data [dict create]

        foreach line $lines {
            # Felder des aktuellen Eintrags sammeln
            if {[regexp {"datum":\s*"([^"]*)"} $line -> datum]} {
                dict set eintrag_data datum $datum
            }
            if {[regexp {"uhrzeit":\s*"([^"]*)"} $line -> uhrzeit]} {
                dict set eintrag_data uhrzeit $uhrzeit
            }
            if {[regexp {"nachname":\s*"([^"]*)"} $line -> nachname]} {
                dict set eintrag_data nachname $nachname
            }
            if {[regexp {"vorname":\s*"([^"]*)"} $line -> vorname]} {
                dict set eintrag_data vorname $vorname
            }
            if {[regexp {"kurzwaffe":\s*"([^"]*)"} $line -> kurzwaffe]} {
                dict set eintrag_data kurzwaffe $kurzwaffe
            }
            if {[regexp {"langwaffe":\s*"([^"]*)"} $line -> langwaffe]} {
                dict set eintrag_data langwaffe $langwaffe
            }
            if {[regexp {"waffentyp":\s*"([^"]*)"} $line -> waffentyp]} {
                dict set eintrag_data waffentyp $waffentyp
            }
            if {[regexp {"kaliber":\s*"([^"]*)"} $line -> kaliber]} {
                dict set eintrag_data kaliber $kaliber
            }
            if {[regexp {"startgeld":\s*"([^"]*)"} $line -> startgeld]} {
                dict set eintrag_data startgeld $startgeld
            }
            if {[regexp {"munition":\s*"([^"]*)"} $line -> munition]} {
                dict set eintrag_data munition $munition
            }
            if {[regexp {"munitionspreis":\s*"([^"]*)"} $line -> munitionspreis]} {
                dict set eintrag_data munitionspreis $munitionspreis

                # Vollständiger Eintrag gefunden - zur Liste hinzufügen
                if {[dict size $eintrag_data] == 11} {
                    lappend eintraege $eintrag_data
                    set eintrag_data [dict create]
                }
            }
        }
    }

    # Neuen Eintrag zur Liste hinzufügen
    lappend eintraege $eintrag

    # Einträge nach Datum sortieren (älteste zuerst)
    # Sortierung basierend auf Datum und Uhrzeit
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
# Prozedur: zeige_eintraege_header
# Header-Zeile wird nicht mehr benötigt - Treeview hat eigene Header
# Diese Funktion bleibt als Platzhalter für Kompatibilität
# =============================================================================
proc zeige_eintraege_header {} {
    # Nichts zu tun - Treeview-Widget hat bereits Header
}

# =============================================================================
# Hilfsprozedur: lade_eintraege_aus_datei
# Lädt Einträge aus einer einzelnen JSON-Datei
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
# Rückgabe: Liste von Eintrags-Dictionaries
# =============================================================================
proc ::neuer_eintrag::lade_eintraege_aus_datei {datei_pfad} {
    # Prüfen, ob Datei existiert
    if {![file exists $datei_pfad]} {
        return [list]
    }

    # Datei öffnen und lesen
    set fp [open $datei_pfad r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Einträge aus JSON parsen und in Liste sammeln
    # Einfaches Parsing: Zeile für Zeile nach Feldern suchen
    set lines [split $json_content "\n"]
    set eintrag_data [dict create]
    set eintraege [list]

    foreach line $lines {
        # Felder des aktuellen Eintrags sammeln
        if {[string match "*\"datum\":*" $line]} {
            if {[regexp {"datum":\s*"([^"]*)"} $line -> datum]} {
                dict set eintrag_data datum $datum
            }
        }
        if {[string match "*\"uhrzeit\":*" $line]} {
            if {[regexp {"uhrzeit":\s*"([^"]*)"} $line -> uhrzeit]} {
                dict set eintrag_data uhrzeit $uhrzeit
            }
        }
        if {[string match "*\"nachname\":*" $line]} {
            if {[regexp {"nachname":\s*"([^"]*)"} $line -> nachname]} {
                dict set eintrag_data nachname $nachname
            }
        }
        if {[string match "*\"vorname\":*" $line]} {
            if {[regexp {"vorname":\s*"([^"]*)"} $line -> vorname]} {
                dict set eintrag_data vorname $vorname
            }
        }
        if {[string match "*\"kurzwaffe\":*" $line]} {
            if {[regexp {"kurzwaffe":\s*"([^"]*)"} $line -> kurzwaffe]} {
                dict set eintrag_data kurzwaffe $kurzwaffe
            }
        }
        if {[string match "*\"langwaffe\":*" $line]} {
            if {[regexp {"langwaffe":\s*"([^"]*)"} $line -> langwaffe]} {
                dict set eintrag_data langwaffe $langwaffe
            }
        }
        if {[string match "*\"waffentyp\":*" $line]} {
            if {[regexp {"waffentyp":\s*"([^"]*)"} $line -> waffentyp]} {
                dict set eintrag_data waffentyp $waffentyp
            }
        }
        if {[string match "*\"kaliber\":*" $line]} {
            if {[regexp {"kaliber":\s*"([^"]*)"} $line -> kaliber]} {
                dict set eintrag_data kaliber $kaliber
            }
        }
        if {[string match "*\"startgeld\":*" $line]} {
            if {[regexp {"startgeld":\s*"([^"]*)"} $line -> startgeld]} {
                dict set eintrag_data startgeld $startgeld
            }
        }
        if {[string match "*\"munition\":*" $line]} {
            if {[regexp {"munition":\s*"([^"]*)"} $line -> munition]} {
                dict set eintrag_data munition $munition
            }
        }
        if {[string match "*\"munitionspreis\":*" $line]} {
            if {[regexp {"munitionspreis":\s*"([^"]*)"} $line -> munitionspreis]} {
                dict set eintrag_data munitionspreis $munitionspreis

                # Alle Felder gesammelt - Eintrag zur Liste hinzufügen
                if {[dict size $eintrag_data] == 11} {
                    lappend eintraege $eintrag_data
                    # Dictionary für nächsten Eintrag zurücksetzen
                    set eintrag_data [dict create]
                }
            }
        }
    }

    return $eintraege
}

# =============================================================================
# Prozedur: lade_existierende_eintraege
# Lädt existierende Einträge aus allen Jahres-JSON-Dateien und zeigt sie an
# Lädt sowohl aus daten/ als auch aus daten/archiv/
# Einträge werden nach Datum und Uhrzeit sortiert angezeigt
# =============================================================================
proc lade_existierende_eintraege {} {
    global script_dir

    # Treeview-Widget des Hauptfensters
    set treeview .main.tree

    # Liste für alle Einträge aus allen Dateien
    set alle_eintraege [list]

    # Daten-Verzeichnis
    set daten_dir [file join $script_dir daten]

    # Archiv-Verzeichnis
    set archiv_dir [file join $script_dir daten archiv]

    # Alle JSON-Dateien im daten-Verzeichnis finden und laden
    if {[file exists $daten_dir]} {
        foreach datei [glob -nocomplain -directory $daten_dir *.json] {
            # Einträge aus dieser Datei laden und zur Gesamtliste hinzufügen
            set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]
            set alle_eintraege [concat $alle_eintraege $eintraege]
        }
    }

    # Alle JSON-Dateien im archiv-Verzeichnis finden und laden
    if {[file exists $archiv_dir]} {
        foreach datei [glob -nocomplain -directory $archiv_dir *.json] {
            # Einträge aus dieser Datei laden und zur Gesamtliste hinzufügen
            set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]
            set alle_eintraege [concat $alle_eintraege $eintraege]
        }
    }

    # Alle Einträge nach Datum und Uhrzeit sortieren
    set alle_eintraege [lsort -command {::neuer_eintrag::vergleiche_eintraege} $alle_eintraege]

    # Sortierte Einträge ins Treeview einfügen
    foreach eintrag $alle_eintraege {
        $treeview insert {} end -values [list \
            [dict get $eintrag datum] \
            [dict get $eintrag nachname] \
            [dict get $eintrag vorname] \
            [dict get $eintrag kurzwaffe] \
            [dict get $eintrag langwaffe] \
            [dict get $eintrag waffentyp] \
            [dict get $eintrag kaliber] \
            [dict get $eintrag startgeld] \
            [dict get $eintrag munition] \
            [dict get $eintrag munitionspreis]]
    }
}

# =============================================================================
# Prozedur: zeige_eintrag_im_hauptfenster
# Zeigt einen Eintrag im Hauptfenster-Treeview an
# Da die Einträge sortiert werden sollen, wird die gesamte Tabelle neu geladen
# Parameter:
#   eintrag - Dictionary mit dem Eintrag (wird nicht verwendet, nur für Kompatibilität)
# =============================================================================
proc ::neuer_eintrag::zeige_eintrag_im_hauptfenster {eintrag} {
    # Treeview-Widget des Hauptfensters
    set treeview .main.tree

    # Alle Einträge aus dem Treeview löschen
    $treeview delete [$treeview children {}]

    # Einträge neu laden (sortiert)
    lade_existierende_eintraege

    # Zum letzten Eintrag scrollen
    set items [$treeview children {}]
    if {[llength $items] > 0} {
        $treeview see [lindex $items end]
    }
}

# =============================================================================
# Prozedur: open_neuer_eintrag_fenster
# Öffnet das Fenster für einen neuen Eintrag
# =============================================================================
proc open_neuer_eintrag_fenster {} {
    # Namespace-Variablen zurücksetzen
    # Datum mit aktuellem Datum vorausfüllen
    set ::neuer_eintrag::datum [clock format [clock seconds] -format "%d.%m.%Y"]
    set ::neuer_eintrag::nachname ""
    set ::neuer_eintrag::vorname ""
    set ::neuer_eintrag::kurzwaffe 0
    set ::neuer_eintrag::langwaffe 0
    set ::neuer_eintrag::waffentyp ""
    set ::neuer_eintrag::kaliber ""
    set ::neuer_eintrag::startgeld "0,00"
    set ::neuer_eintrag::munition "Keine"
    set ::neuer_eintrag::munitionspreis "0,00"

    # Daten laden
    ::neuer_eintrag::lade_mitglieder_daten
    ::neuer_eintrag::lade_kaliber_preise
    ::neuer_eintrag::lade_stand_preise

    # Startgeld initial berechnen
    ::neuer_eintrag::berechne_startgeld

    # Toplevel-Fenster erstellen
    set w .neuer_eintrag
    set ::neuer_eintrag::fenster $w

    # Falls Fenster bereits existiert, schließen
    if {[winfo exists $w]} {
        destroy $w
    }

    # Neues Toplevel-Fenster
    toplevel $w
    wm title $w "Neuer Eintrag"
    # Höhe um 30% verringert (700 * 0.7 = 490), Breite um 20% erhöht (600 * 1.2 = 720)
    wm geometry $w "720x490"

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # =========================================================================
    # Datum-Eingabefeld
    # =========================================================================
    frame $w.datum_frame
    pack $w.datum_frame -in $w.main -fill x -pady 5

    label $w.datum_frame.label -text "Datum:" -width 20 -anchor w
    pack $w.datum_frame.label -side left

    entry $w.datum_frame.entry -textvariable ::neuer_eintrag::datum -width 40
    pack $w.datum_frame.entry -side left -fill x -expand 1

    # Trace für Validierung des Speichern-Buttons
    trace add variable ::neuer_eintrag::datum write ::neuer_eintrag::pruefe_speichern_button

    # =========================================================================
    # Name-Eingabefeld mit Autovervollständigung
    # =========================================================================
    frame $w.name_frame
    pack $w.name_frame -in $w.main -fill x -pady 5

    label $w.name_frame.label -text "Nachname:" -width 20 -anchor w
    pack $w.name_frame.label -side left

    entry $w.name_frame.name_entry -textvariable ::neuer_eintrag::nachname -width 40
    pack $w.name_frame.name_entry -side left -fill x -expand 1

    # Autovervollständigungs-Listbox (initial versteckt)
    listbox $w.name_frame.autocomplete -height 5 -exportselection 0
    set ::neuer_eintrag::autocomplete_listbox $w.name_frame.autocomplete
    set ::neuer_eintrag::autocomplete_visible 0

    # Bindings für Autovervollständigung
    trace add variable ::neuer_eintrag::nachname write ::neuer_eintrag::nachname_geaendert
    bind $w.name_frame.autocomplete <<ListboxSelect>> ::neuer_eintrag::autocomplete_ausgewaehlt
    bind $w.name_frame.autocomplete <Double-Button-1> ::neuer_eintrag::autocomplete_ausgewaehlt

    # Trace für Validierung des Speichern-Buttons
    trace add variable ::neuer_eintrag::nachname write ::neuer_eintrag::pruefe_speichern_button

    # =========================================================================
    # Vorname-Eingabefeld
    # =========================================================================
    frame $w.vorname_frame
    pack $w.vorname_frame -in $w.main -fill x -pady 5

    label $w.vorname_frame.label -text "Vorname:" -width 20 -anchor w
    pack $w.vorname_frame.label -side left

    entry $w.vorname_frame.entry -textvariable ::neuer_eintrag::vorname -width 40
    pack $w.vorname_frame.entry -side left -fill x -expand 1

    # Trace für Validierung des Speichern-Buttons
    trace add variable ::neuer_eintrag::vorname write ::neuer_eintrag::pruefe_speichern_button

    # =========================================================================
    # Waffen-Checkboxen (KW/LW)
    # =========================================================================
    frame $w.waffen_frame
    pack $w.waffen_frame -in $w.main -fill x -pady 5

    label $w.waffen_frame.label -text "Waffe:" -width 20 -anchor w
    pack $w.waffen_frame.label -side left

    checkbutton $w.waffen_frame.kw -text "Kurzwaffe (KW)" -variable ::neuer_eintrag::kurzwaffe \
        -command ::neuer_eintrag::pruefe_speichern_button
    pack $w.waffen_frame.kw -side left -padx 5

    checkbutton $w.waffen_frame.lw -text "Langwaffe (LW)" -variable ::neuer_eintrag::langwaffe \
        -command ::neuer_eintrag::pruefe_speichern_button
    pack $w.waffen_frame.lw -side left -padx 5

    # =========================================================================
    # Waffentyp-Auswahl (LD/KK/GK)
    # =========================================================================
    frame $w.typ_frame
    pack $w.typ_frame -in $w.main -fill x -pady 5

    label $w.typ_frame.label -text "Waffentyp:" -width 20 -anchor w
    pack $w.typ_frame.label -side left

    radiobutton $w.typ_frame.ld -text "Luftdruck (LD)" -variable ::neuer_eintrag::waffentyp -value "LD" \
        -command {::neuer_eintrag::waffentyp_geaendert; ::neuer_eintrag::pruefe_speichern_button}
    pack $w.typ_frame.ld -side left -padx 5

    radiobutton $w.typ_frame.kk -text "Kleinkaliber (KK)" -variable ::neuer_eintrag::waffentyp -value "KK" \
        -command {::neuer_eintrag::waffentyp_geaendert; ::neuer_eintrag::pruefe_speichern_button}
    pack $w.typ_frame.kk -side left -padx 5

    radiobutton $w.typ_frame.gk -text "Großkaliber (GK)" -variable ::neuer_eintrag::waffentyp -value "GK" \
        -command {::neuer_eintrag::waffentyp_geaendert; ::neuer_eintrag::pruefe_speichern_button}
    pack $w.typ_frame.gk -side left -padx 5

    # =========================================================================
    # Kaliber-Eingabefeld
    # =========================================================================
    frame $w.kaliber_frame
    pack $w.kaliber_frame -in $w.main -fill x -pady 5

    label $w.kaliber_frame.label -text "Kaliber:" -width 20 -anchor w
    pack $w.kaliber_frame.label -side left

    entry $w.kaliber_frame.entry -textvariable ::neuer_eintrag::kaliber -width 40
    pack $w.kaliber_frame.entry -side left -fill x -expand 1

    # Trace für Validierung des Speichern-Buttons
    trace add variable ::neuer_eintrag::kaliber write ::neuer_eintrag::pruefe_speichern_button

    # =========================================================================
    # Startgeld-Anzeige (readonly)
    # =========================================================================
    frame $w.startgeld_frame
    pack $w.startgeld_frame -in $w.main -fill x -pady 5

    label $w.startgeld_frame.label -text "Startgeld (€):" -width 20 -anchor w
    pack $w.startgeld_frame.label -side left

    entry $w.startgeld_frame.entry -textvariable ::neuer_eintrag::startgeld -width 40 -state readonly
    pack $w.startgeld_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Munitions-Auswahl
    # =========================================================================
    frame $w.munition_frame
    pack $w.munition_frame -in $w.main -fill x -pady 5

    label $w.munition_frame.label -text "Munition:" -width 20 -anchor w
    pack $w.munition_frame.label -side left

    # Munitions-Optionen aus Kaliber-Preisen erstellen
    set munitions_optionen [list "Keine"]
    dict for {kaliber preis} $::neuer_eintrag::kaliber_preise_dict {
        lappend munitions_optionen $kaliber
    }

    ttk::combobox $w.munition_frame.combo -textvariable ::neuer_eintrag::munition \
        -values $munitions_optionen -state readonly -width 37
    pack $w.munition_frame.combo -side left -fill x -expand 1

    # Binding für Munitionsänderung
    bind $w.munition_frame.combo <<ComboboxSelected>> ::neuer_eintrag::munition_geaendert

    # =========================================================================
    # Munitionspreis-Anzeige (readonly)
    # =========================================================================
    frame $w.munitionspreis_frame
    pack $w.munitionspreis_frame -in $w.main -fill x -pady 5

    label $w.munitionspreis_frame.label -text "Munitionspreis (€):" -width 20 -anchor w
    pack $w.munitionspreis_frame.label -side left

    entry $w.munitionspreis_frame.entry -textvariable ::neuer_eintrag::munitionspreis -width 40 -state readonly
    pack $w.munitionspreis_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Buttons (Speichern / Abbrechen)
    # =========================================================================
    frame $w.button_frame
    pack $w.button_frame -in $w.main -fill x -pady 20

    # Button "Speichern" - initial deaktiviert, wird aktiviert wenn Kaliber ausgefüllt
    button $w.button_frame.save -text "Speichern" -bg "#90EE90" -width 15 \
        -command ::neuer_eintrag::speichern_und_anzeigen -state disabled
    pack $w.button_frame.save -side left -padx 5

    button $w.button_frame.cancel -text "Abbrechen" -bg "#FFB6C1" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.cancel -side right -padx 5

    # =========================================================================
    # Event-Bindings für Validierung
    # =========================================================================

    # Initiale Prüfung des Speichern-Buttons durchführen
    ::neuer_eintrag::pruefe_speichern_button

    # Fenster modal machen (optional)
    # grab $w

    # Focus auf Datum-Eingabefeld setzen
    focus $w.datum_frame.entry
}
