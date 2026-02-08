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
    variable anzahl "1"
    variable munition "Keine"
    variable munitionspreis "0,00"
    variable bemerkungen ""

    # Mitgliederliste für Autovervollständigung
    variable mitglieder_dict [dict create]

    # Kaliber-Preisliste
    variable kaliber_preise_dict [dict create]

    # Einzelpreis pro Munitionseinheit (wird gespeichert wenn Munition gewählt wird)
    variable munitions_einzelpreis "0,00"

    # Liste der hinzugefügten Munitionskäufe (jeder Eintrag: dict mit kaliber, anzahl, einzelpreis, gesamtpreis)
    variable munitions_liste [list]

    # Stand-Nutzungs-Preise
    variable stand_preise [dict create]

    # Fenster-Referenz
    variable fenster ""

    # Autovervollständigungs-Listbox für Nachnamen
    variable autocomplete_listbox ""
    variable autocomplete_visible 0

    # Autovervollständigungs-Listbox für Vornamen
    variable vorname_autocomplete_listbox ""
    variable vorname_autocomplete_visible 0
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
# Prozedur: validiere_preis_eingabe
# Validiert Eingaben für Preis-Felder (Startgeld, Munitionspreis)
# Erlaubt nur numerische Werte mit optionalem Komma oder Punkt
# Parameter:
#   neuer_wert - Der neue eingegebene Wert
# Rückgabe: 1 wenn gültig, 0 wenn ungültig (blockiert Eingabe)
# =============================================================================
proc ::neuer_eintrag::validiere_preis_eingabe {neuer_wert} {
    # Leerer String ist erlaubt (Feld kann leer sein während der Eingabe)
    if {$neuer_wert eq ""} {
        return 1
    }

    # Nur Ziffern, Komma und Punkt erlauben
    # Regex: Optional ein Minus am Anfang, dann Ziffern, optional ein Komma/Punkt, dann weitere Ziffern
    # Beispiele: "5", "5,00", "5.50", "12,5"
    if {[regexp {^[0-9]*[,.]?[0-9]*$} $neuer_wert]} {
        return 1
    }

    # Ungültiger Wert - Eingabe blockieren
    return 0
}

# =============================================================================
# Prozedur: normalisiere_preis
# Normalisiert einen Preis-Wert zu einem gültigen Format
# Wandelt nicht-numerische Werte in "0,00" um
# Parameter:
#   wert - Der zu normalisierende Wert
# Rückgabe: Normalisierter Preis im Format "0,00"
# =============================================================================
proc ::neuer_eintrag::normalisiere_preis {wert} {
    # Wert trimmen
    set wert [string trim $wert]

    # Prüfen, ob Wert leer ist
    if {$wert eq ""} {
        return "0,00"
    }

    # Komma durch Punkt ersetzen für numerische Prüfung
    set wert_numerisch [string map {"," "."} $wert]

    # Prüfen, ob der Wert numerisch ist
    if {[catch {expr {$wert_numerisch + 0}}]} {
        # Nicht numerisch - auf 0,00 setzen
        return "0,00"
    }

    # Numerisch - Format normalisieren auf 2 Dezimalstellen
    set wert_float [expr {$wert_numerisch + 0.0}]
    set wert_formatiert [format "%.2f" $wert_float]

    # Punkt zurück zu Komma für deutsches Format
    set wert_formatiert [string map {"." ","} $wert_formatiert]

    return $wert_formatiert
}

# =============================================================================
# Prozedur: startgeld_fokus_verloren
# Wird aufgerufen, wenn das Startgeld-Feld den Fokus verliert
# Normalisiert den eingegebenen Wert
# =============================================================================
proc ::neuer_eintrag::startgeld_fokus_verloren {} {
    variable startgeld

    # Wert normalisieren
    set startgeld [normalisiere_preis $startgeld]
}

# =============================================================================
# Prozedur: validiere_anzahl_eingabe
# Validiert Eingaben für das Anzahl-Feld
# Erlaubt nur numerische Werte (für Stückzahlen)
# Parameter:
#   neuer_wert - Der neue eingegebene Wert
# Rückgabe: 1 wenn gültig, 0 wenn ungültig (blockiert Eingabe)
# =============================================================================
proc ::neuer_eintrag::validiere_anzahl_eingabe {neuer_wert} {
    # Leerer String ist erlaubt (Feld kann leer sein während der Eingabe)
    if {$neuer_wert eq ""} {
        return 1
    }

    # Nur Ziffern, Komma und Punkt erlauben (für Dezimalzahlen)
    # Beispiele: "1", "10", "2,5", "3.5"
    if {[regexp {^[0-9]*[,.]?[0-9]*$} $neuer_wert]} {
        return 1
    }

    # Ungültiger Wert - Eingabe blockieren
    return 0
}

# =============================================================================
# Prozedur: normalisiere_anzahl
# Normalisiert einen Anzahl-Wert zu einem gültigen Format
# Wandelt nicht-numerische Werte in "1" um
# Parameter:
#   wert - Der zu normalisierende Wert
# Rückgabe: Normalisierte Anzahl (mindestens "1")
# =============================================================================
proc ::neuer_eintrag::normalisiere_anzahl {wert} {
    # Wert trimmen
    set wert [string trim $wert]

    # Prüfen, ob Wert leer ist
    if {$wert eq ""} {
        return "1"
    }

    # Komma durch Punkt ersetzen für numerische Prüfung
    set wert_numerisch [string map {"," "."} $wert]

    # Prüfen, ob der Wert numerisch ist
    if {[catch {expr {$wert_numerisch + 0}}]} {
        # Nicht numerisch - auf 1 setzen
        return "1"
    }

    # Numerisch - prüfen, ob größer als 0
    set wert_float [expr {$wert_numerisch + 0.0}]

    if {$wert_float <= 0} {
        # Null oder negativ - auf 1 setzen
        return "1"
    }

    # Wenn es eine Ganzzahl ist, ohne Dezimalstellen ausgeben
    if {$wert_float == int($wert_float)} {
        return [format "%.0f" $wert_float]
    }

    # Dezimalzahl - auf 2 Stellen formatieren mit deutschem Komma
    set wert_formatiert [format "%.2f" $wert_float]
    set wert_formatiert [string map {"." ","} $wert_formatiert]

    return $wert_formatiert
}

# =============================================================================
# Prozedur: anzahl_fokus_verloren
# Wird aufgerufen, wenn das Anzahl-Feld den Fokus verliert
# Normalisiert den eingegebenen Wert
# =============================================================================
proc ::neuer_eintrag::anzahl_fokus_verloren {} {
    variable anzahl

    # Wert normalisieren
    set anzahl [normalisiere_anzahl $anzahl]
}

# =============================================================================
# Prozedur: berechne_startgeld
# Berechnet das Startgeld basierend auf den eingegebenen Daten
# Prüft Mitgliedschaft anhand von Nachname UND Vorname
# =============================================================================
proc ::neuer_eintrag::berechne_startgeld {} {
    variable nachname
    variable vorname
    variable waffentyp
    variable mitglieder_dict
    variable stand_preise
    variable startgeld

    # Prüfen, ob der Schütze ein Mitglied ist (case-insensitive)
    # Wichtig: Sowohl Nachname ALS AUCH Vorname müssen übereinstimmen
    # Damit wird verhindert, dass z.B. "Anna Müller" als Mitglied erkannt wird,
    # nur weil "Karl Müller" Mitglied ist
    set ist_mitglied 0
    dict for {name vornamen} $mitglieder_dict {
        # Case-insensitive Vergleich des Nachnamens
        if {[string equal -nocase $nachname $name]} {
            # Nachname gefunden - jetzt prüfen, ob der Vorname auch in der Liste ist
            foreach vn $vornamen {
                if {[string equal -nocase $vorname $vn]} {
                    # Vollständige Übereinstimmung: Nachname + Vorname
                    set ist_mitglied 1
                    break
                }
            }
            # Wenn Mitglied gefunden, Schleife beenden
            if {$ist_mitglied} {
                break
            }
        }
    }

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
            default {
                # Kein Waffentyp gewählt - Standardpreis für Mitglieder (Kleinkaliber) setzen
                if {[dict exists $stand_preise "Mitglied Kleinkaliber"]} {
                    set startgeld [dict get $stand_preise "Mitglied Kleinkaliber"]
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
# Prozedur: vorname_geaendert
# Beschreibung: Wird aufgerufen, wenn sich das Vorname-Feld ändert
#               Zeigt passende Vornamen für den aktuellen Nachnamen an
# =============================================================================
proc ::neuer_eintrag::vorname_geaendert {args} {
    variable nachname
    variable vorname
    variable mitglieder_dict
    variable fenster
    variable vorname_autocomplete_listbox
    variable vorname_autocomplete_visible

    # Startgeld neu berechnen
    berechne_startgeld

    # Wenn Vorname leer oder kein Nachname vorhanden, Autovervollständigung ausblenden
    if {$vorname eq "" || $nachname eq ""} {
        if {$vorname_autocomplete_visible} {
            pack forget $vorname_autocomplete_listbox
            set vorname_autocomplete_visible 0
        }
        return
    }

    # Prüfen ob Nachname im Dictionary existiert
    set nachname_gefunden ""
    dict for {name vornamen} $mitglieder_dict {
        if {[string equal -nocase $nachname $name]} {
            set nachname_gefunden $name
            break
        }
    }

    if {$nachname_gefunden eq ""} {
        # Nachname nicht gefunden - keine Vorschläge
        if {$vorname_autocomplete_visible} {
            pack forget $vorname_autocomplete_listbox
            set vorname_autocomplete_visible 0
        }
        return
    }

    # Vornamen für diesen Nachnamen holen
    set vornamen_liste [dict get $mitglieder_dict $nachname_gefunden]

    # Nach passenden Vornamen suchen
    set matches [list]
    foreach vn $vornamen_liste {
        # Case-insensitive Matching
        if {[string match -nocase "${vorname}*" $vn]} {
            lappend matches $vn
        }
    }

    # Autovervollständigungs-Listbox aktualisieren
    $vorname_autocomplete_listbox delete 0 end
    foreach match $matches {
        $vorname_autocomplete_listbox insert end $match
    }

    # Listbox anzeigen, wenn Treffer vorhanden
    if {[llength $matches] > 0} {
        if {!$vorname_autocomplete_visible} {
            pack $vorname_autocomplete_listbox -in $fenster.vorname_frame -side bottom -fill x -after $fenster.vorname_frame.vorname_entry
            set vorname_autocomplete_visible 1
        }

        # Wenn genau ein Treffer und exakte Übereinstimmung, Vorname korrigieren
        if {[llength $matches] == 1} {
            set exact_match [lindex $matches 0]
            if {[string equal -nocase $vorname $exact_match]} {
                # Korrekten Vornamen setzen (mit richtiger Groß-/Kleinschreibung)
                set vorname $exact_match
                # Autovervollständigung ausblenden
                pack forget $vorname_autocomplete_listbox
                set vorname_autocomplete_visible 0
            }
        }
    } else {
        # Keine Treffer - ausblenden
        if {$vorname_autocomplete_visible} {
            pack forget $vorname_autocomplete_listbox
            set vorname_autocomplete_visible 0
        }
    }
}

# =============================================================================
# Prozedur: vorname_autocomplete_ausgewaehlt
# Beschreibung: Wird aufgerufen, wenn ein Eintrag aus der Vorname-Autovervollständigung ausgewählt wird
# =============================================================================
proc ::neuer_eintrag::vorname_autocomplete_ausgewaehlt {} {
    variable vorname
    variable vorname_autocomplete_listbox
    variable vorname_autocomplete_visible

    # Ausgewählten Vornamen holen
    set selection [$vorname_autocomplete_listbox curselection]
    if {$selection ne ""} {
        set selected_vorname [$vorname_autocomplete_listbox get $selection]

        # Vorname setzen
        set vorname $selected_vorname

        # Autovervollständigung ausblenden
        pack forget $vorname_autocomplete_listbox
        set vorname_autocomplete_visible 0
    }
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
    variable munitions_einzelpreis
    variable kaliber_preise_dict

    # Einzelpreis für gewähltes Kaliber setzen
    if {$munition eq "Keine"} {
        set munitions_einzelpreis "0,00"
    } elseif {[dict exists $kaliber_preise_dict $munition]} {
        set munitions_einzelpreis [dict get $kaliber_preise_dict $munition]
    }

    # Gesamtpreis basierend auf Anzahl berechnen
    berechne_munitionspreis
}

# =============================================================================
# Prozedur: berechne_munitionspreis
# Berechnet den Gesamtpreis der Munition über alle hinzugefügten Kaliber
# =============================================================================
proc ::neuer_eintrag::berechne_munitionspreis {args} {
    variable munitions_liste
    variable munitionspreis

    # Gesamtpreis über alle hinzugefügten Kaliber berechnen
    set gesamt_preis 0.0

    foreach munitions_eintrag $munitions_liste {
        # Gesamtpreis für diesen Eintrag holen und addieren
        set preis_str [dict get $munitions_eintrag gesamtpreis]
        set preis_numerisch [string map {"," "."} $preis_str]
        set gesamt_preis [expr {$gesamt_preis + $preis_numerisch}]
    }

    # Zurück zu deutschem Format konvertieren (Punkt → Komma)
    set munitionspreis [format "%.2f" $gesamt_preis]
    set munitionspreis [string map {"." ","} $munitionspreis]
}

# =============================================================================
# Prozedur: munition_hinzufuegen
# Fügt das aktuell gewählte Kaliber mit Anzahl zur Munitionsliste hinzu
# =============================================================================
proc ::neuer_eintrag::munition_hinzufuegen {} {
    variable munition
    variable anzahl
    variable munitions_einzelpreis
    variable munitions_liste
    variable fenster

    # Prüfen, ob ein Kaliber ausgewählt ist (nicht "Keine")
    if {$munition eq "Keine" || $munition eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Keine Munition" \
            -message "Bitte wählen Sie zuerst ein Kaliber aus."
        return
    }

    # Anzahl validieren
    set anzahl_numerisch [string map {"," "."} $anzahl]
    if {[catch {expr {$anzahl_numerisch + 0}}] || $anzahl_numerisch eq "" || $anzahl_numerisch <= 0} {
        tk_messageBox -parent $fenster -icon warning -title "Ungültige Anzahl" \
            -message "Bitte geben Sie eine gültige Anzahl (größer als 0) ein."
        return
    }

    # Gesamtpreis für diesen Eintrag berechnen
    set einzelpreis_numerisch [string map {"," "."} $munitions_einzelpreis]
    set eintrag_gesamtpreis [expr {$anzahl_numerisch * $einzelpreis_numerisch}]
    set eintrag_gesamtpreis_str [format "%.2f" $eintrag_gesamtpreis]
    set eintrag_gesamtpreis_str [string map {"." ","} $eintrag_gesamtpreis_str]

    # Eintrag zur Liste hinzufügen
    set neuer_eintrag [dict create \
        kaliber $munition \
        anzahl $anzahl \
        einzelpreis $munitions_einzelpreis \
        gesamtpreis $eintrag_gesamtpreis_str \
    ]
    lappend munitions_liste $neuer_eintrag

    # Listbox aktualisieren
    aktualisiere_munitions_listbox

    # Gesamtpreis neu berechnen
    berechne_munitionspreis

    # Felder zurücksetzen für nächste Eingabe
    set munition "Keine"
    set anzahl "1"
    set munitions_einzelpreis "0,00"
}

# =============================================================================
# Prozedur: aktualisiere_munitions_listbox
# Aktualisiert die Anzeige der hinzugefügten Munitionskäufe in der Listbox
# =============================================================================
proc ::neuer_eintrag::aktualisiere_munitions_listbox {} {
    variable munitions_liste
    variable fenster

    # Prüfen, ob Listbox existiert
    if {![winfo exists $fenster.munitions_liste_frame.listbox]} {
        return
    }

    set listbox $fenster.munitions_liste_frame.listbox

    # Listbox leeren
    $listbox delete 0 end

    # Alle Einträge hinzufügen
    foreach munitions_eintrag $munitions_liste {
        set kaliber [dict get $munitions_eintrag kaliber]
        set anzahl [dict get $munitions_eintrag anzahl]
        set gesamtpreis [dict get $munitions_eintrag gesamtpreis]

        # Format: "Kaliber (Anzahl Stk.) - Preis €"
        set anzeige_text "$kaliber ($anzahl Stk.) - $gesamtpreis €"
        $listbox insert end $anzeige_text
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
    variable anzahl
    variable munition
    variable munitionspreis
    variable munitions_liste
    variable fenster
    global script_dir

    # Eingaben validieren
    if {![validiere_eingaben]} {
        return
    }

    # Munitions-String aus der Liste erstellen
    # Format: "Kaliber1 (Anzahl1), Kaliber2 (Anzahl2)" oder "Keine"
    set munitions_string "Keine"
    set munitions_anzahl_string "0"

    if {[llength $munitions_liste] > 0} {
        set munitions_teile [list]
        foreach munitions_eintrag $munitions_liste {
            set kal [dict get $munitions_eintrag kaliber]
            set anz [dict get $munitions_eintrag anzahl]
            lappend munitions_teile "$kal ($anz)"
        }
        set munitions_string [join $munitions_teile ", "]
        # Gesamtanzahl für Kompatibilität (wird bei mehreren Kalibern nicht mehr aussagekräftig)
        set munitions_anzahl_string "1"
    }

    # Überschreibe die Variablen für das Speichern
    set munition $munitions_string
    set anzahl $munitions_anzahl_string

    # Jahr aus dem eingegebenen Datum extrahieren (Format: DD.MM.YYYY)
    if {[regexp {^\d{2}\.\d{2}\.(\d{4})$} $datum -> jahr]} {
        # Jahr erfolgreich extrahiert
    } else {
        # Fallback: Aktuelles Jahr verwenden, falls Datum ungültig
        set jahr [clock format [clock seconds] -format "%Y"]
    }

    # Uhrzeit für JSON-Datei ermitteln
    set uhrzeit [clock format [clock seconds] -format "%H:%M:%S"]

    # Pfad zur Jahres-JSON-Datei bestimmen (alle Jahre in daten/ speichern)
    set jahres_json [::pfad::get_jahres_json_path $jahr]

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
        "anzahl" $anzahl \
        "munition" $munition \
        "munitionspreis" $munitionspreis \
        "bemerkungen" $bemerkungen \
    ]

    # Eintrag zur JSON-Datei hinzufügen
    speichere_eintrag_json $jahres_json $eintrag

    # Eintrag im Hauptfenster anzeigen
    zeige_eintrag_im_hauptfenster $eintrag

    # Fenster schließen (ohne Erfolgsmeldung)
    # Traces entfernen und Fenster schließen
    schliesse_fenster
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
            if {[regexp {"anzahl":\s*"([^"]*)"} $line -> anzahl]} {
                dict set eintrag_data anzahl $anzahl
            }
            if {[regexp {"munition":\s*"([^"]*)"} $line -> munition]} {
                dict set eintrag_data munition $munition
            }
            if {[regexp {"munitionspreis":\s*"([^"]*)"} $line -> munitionspreis]} {
                dict set eintrag_data munitionspreis $munitionspreis
            }
            # Bemerkungen-Feld lesen
            if {[regexp {"bemerkungen":\s*"([^"]*)"} $line -> bemerkungen]} {
                dict set eintrag_data bemerkungen $bemerkungen
            }

            # Prüfen ob ein vollständiger Eintrag vorliegt
            # Bei schließender Klammer den Eintrag abschließen
            if {[string match "*\}*" $line] && [dict size $eintrag_data] >= 11} {
                # Für alte Einträge ohne Anzahl: Standardwert 1 setzen
                if {![dict exists $eintrag_data anzahl]} {
                    dict set eintrag_data anzahl "1"
                }
                # Für alte Einträge ohne Bemerkungen: Leeren String setzen
                if {![dict exists $eintrag_data bemerkungen]} {
                    dict set eintrag_data bemerkungen ""
                }
                lappend eintraege $eintrag_data
                set eintrag_data [dict create]
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
        lappend lines "      \"anzahl\": \"[dict get $entry anzahl]\","
        lappend lines "      \"munition\": \"[dict get $entry munition]\","
        lappend lines "      \"munitionspreis\": \"[dict get $entry munitionspreis]\","
        # Bemerkungen-Feld hinzufügen (leer wenn nicht vorhanden)
        set bemerkungen_wert ""
        if {[dict exists $entry bemerkungen]} {
            set bemerkungen_wert [dict get $entry bemerkungen]
        }
        lappend lines "      \"bemerkungen\": \"$bemerkungen_wert\""

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
        if {[string match "*\"anzahl\":*" $line]} {
            if {[regexp {"anzahl":\s*"([^"]*)"} $line -> anzahl]} {
                dict set eintrag_data anzahl $anzahl
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
            }
        }
        # Bemerkungen-Feld lesen
        if {[string match "*\"bemerkungen\":*" $line]} {
            if {[regexp {"bemerkungen":\s*"([^"]*)"} $line -> bemerkungen]} {
                dict set eintrag_data bemerkungen $bemerkungen
            }
        }

        # Prüfen ob ein vollständiger Eintrag vorliegt (schließende Klammer)
        if {[string match "*\}*" $line] && [dict size $eintrag_data] >= 11} {
            # Für alte Einträge ohne Anzahl: Standardwert 1 setzen
            if {![dict exists $eintrag_data anzahl]} {
                dict set eintrag_data anzahl "1"
            }
            # Für alte Einträge ohne Bemerkungen: Leeren String setzen
            if {![dict exists $eintrag_data bemerkungen]} {
                dict set eintrag_data bemerkungen ""
            }
            lappend eintraege $eintrag_data
            # Dictionary für nächsten Eintrag zurücksetzen
            set eintrag_data [dict create]
        }
    }

    return $eintraege
}

# =============================================================================
# Prozedur: lade_existierende_eintraege
# Lädt existierende Einträge aus allen Jahres-JSON-Dateien und zeigt sie an
# Lädt alle JSON-Dateien aus dem daten-Verzeichnis
# Einträge werden nach Datum und Uhrzeit sortiert angezeigt
# =============================================================================
proc lade_existierende_eintraege {} {
    global script_dir

    # Treeview-Widget des Hauptfensters
    set treeview .main.tree

    # Liste für alle Einträge aus allen Dateien
    set alle_eintraege [list]

    # Daten-Verzeichnis vom Pfad-Management abrufen
    set daten_dir [::pfad::get_daten_directory]

    # Alle JSON-Dateien im daten-Verzeichnis finden und laden
    if {[file exists $daten_dir]} {
        foreach datei [glob -nocomplain -directory $daten_dir *.json] {
            # Einträge aus dieser Datei laden und zur Gesamtliste hinzufügen
            set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]
            set alle_eintraege [concat $alle_eintraege $eintraege]
        }
    }

    # Alle Einträge nach Datum und Uhrzeit sortieren
    set alle_eintraege [lsort -command {::neuer_eintrag::vergleiche_eintraege} $alle_eintraege]

    # Sortierte Einträge ins Treeview einfügen
    foreach eintrag $alle_eintraege {
        # Munitionspreis direkt verwenden - ist bereits der Gesamtpreis (Anzahl × Einzelpreis)
        # Der Preis wurde bereits beim Erstellen des Eintrags berechnet und muss nicht nochmals multipliziert werden
        set munitionspreis [dict get $eintrag munitionspreis]

        # Bemerkungen holen (leer wenn nicht vorhanden für Abwärtskompatibilität)
        set bemerkungen ""
        if {[dict exists $eintrag bemerkungen]} {
            set bemerkungen [dict get $eintrag bemerkungen]
        }

        # Reihenfolge der Spalten: datum, uhrzeit, nachname, vorname, kw, lw, typ, kaliber, startgeld, munition, munpreis, bemerkungen
        # Die Uhrzeit wird in der versteckten Spalte gespeichert
        $treeview insert {} end -values [list \
            [dict get $eintrag datum] \
            [dict get $eintrag uhrzeit] \
            [dict get $eintrag nachname] \
            [dict get $eintrag vorname] \
            [dict get $eintrag kurzwaffe] \
            [dict get $eintrag langwaffe] \
            [dict get $eintrag waffentyp] \
            [dict get $eintrag kaliber] \
            [dict get $eintrag startgeld] \
            [dict get $eintrag munition] \
            $munitionspreis \
            $bemerkungen]
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
# Prozedur: entferne_traces
# Entfernt alle Traces von den Variablen des Neuer-Eintrag-Fensters
# =============================================================================
proc ::neuer_eintrag::entferne_traces {} {
    # Alle Traces entfernen (falls vorhanden)
    # trace remove wird keinen Fehler werfen, wenn die Trace nicht existiert
    catch {trace remove variable ::neuer_eintrag::datum write ::neuer_eintrag::pruefe_speichern_button}
    catch {trace remove variable ::neuer_eintrag::nachname write ::neuer_eintrag::nachname_geaendert}
    catch {trace remove variable ::neuer_eintrag::nachname write ::neuer_eintrag::pruefe_speichern_button}
    catch {trace remove variable ::neuer_eintrag::vorname write ::neuer_eintrag::pruefe_speichern_button}
    catch {trace remove variable ::neuer_eintrag::kaliber write ::neuer_eintrag::pruefe_speichern_button}
    catch {trace remove variable ::neuer_eintrag::anzahl write ::neuer_eintrag::berechne_munitionspreis}
}

# =============================================================================
# Prozedur: schliesse_fenster
# Schließt das Neuer-Eintrag-Fenster und räumt auf (Traces entfernen)
# =============================================================================
proc ::neuer_eintrag::schliesse_fenster {} {
    variable fenster

    # Traces entfernen
    entferne_traces

    # Fenster schließen
    if {[winfo exists $fenster]} {
        destroy $fenster
    }
}

# =============================================================================
# Prozedur: open_neuer_eintrag_fenster
# Öffnet das Fenster für einen neuen Eintrag
# =============================================================================
proc open_neuer_eintrag_fenster {} {
    # Alte Traces entfernen (falls vorhanden von vorherigem Fenster)
    ::neuer_eintrag::entferne_traces

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
    set ::neuer_eintrag::anzahl "1"
    set ::neuer_eintrag::munition "Keine"
    set ::neuer_eintrag::munitions_einzelpreis "0,00"
    set ::neuer_eintrag::munitionspreis "0,00"
    set ::neuer_eintrag::munitions_liste [list]
    set ::neuer_eintrag::bemerkungen ""

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
    # Optimale Größe für alle Eingabefelder, Listbox und Buttons
    # Breite auf 780 erhöht, damit Großkaliber-Radiobutton auch auf kleinen Bildschirmen sichtbar ist
    wm geometry $w "780x650"
    # Mindestgröße festlegen, damit alle Elemente sichtbar bleiben
    wm minsize $w 780 650

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

    entry $w.vorname_frame.vorname_entry -textvariable ::neuer_eintrag::vorname -width 40
    pack $w.vorname_frame.vorname_entry -side left -fill x -expand 1

    # Autovervollständigungs-Listbox für Vornamen
    listbox $w.vorname_frame.autocomplete -height 5 -exportselection 0
    set ::neuer_eintrag::vorname_autocomplete_listbox $w.vorname_frame.autocomplete

    # Trace für Vornamen-Autovervollständigung
    trace add variable ::neuer_eintrag::vorname write ::neuer_eintrag::vorname_geaendert

    # Binding für Vorname-Autovervollständigung
    bind $w.vorname_frame.autocomplete <<ListboxSelect>> ::neuer_eintrag::vorname_autocomplete_ausgewaehlt

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

    # Startgeld-Eingabefeld (editierbar für manuelle Anpassungen in Sonderfällen)
    # Mit Validierung: Nur numerische Werte erlauben
    entry $w.startgeld_frame.entry -textvariable ::neuer_eintrag::startgeld -width 40 \
        -validate key -validatecommand {::neuer_eintrag::validiere_preis_eingabe %P}
    pack $w.startgeld_frame.entry -side left -fill x -expand 1

    # Fokus-Verlust-Event: Wert normalisieren (auf 2 Dezimalstellen formatieren)
    bind $w.startgeld_frame.entry <FocusOut> ::neuer_eintrag::startgeld_fokus_verloren

    # =========================================================================
    # Munition und Anzahl in einer Zeile
    # =========================================================================
    frame $w.munition_anzahl_frame
    pack $w.munition_anzahl_frame -in $w.main -fill x -pady 5

    # Munitions-Auswahl (links)
    label $w.munition_anzahl_frame.munition_label -text "Munition:" -width 20 -anchor w
    pack $w.munition_anzahl_frame.munition_label -side left

    # Munitions-Optionen aus Kaliber-Preisen erstellen
    set munitions_optionen [list "Keine"]
    dict for {kaliber preis} $::neuer_eintrag::kaliber_preise_dict {
        lappend munitions_optionen $kaliber
    }

    ttk::combobox $w.munition_anzahl_frame.munition_combo -textvariable ::neuer_eintrag::munition \
        -values $munitions_optionen -state readonly -width 15
    pack $w.munition_anzahl_frame.munition_combo -side left -padx 5

    # Binding für Munitionsänderung
    bind $w.munition_anzahl_frame.munition_combo <<ComboboxSelected>> ::neuer_eintrag::munition_geaendert

    # Anzahl-Eingabefeld (rechts)
    label $w.munition_anzahl_frame.anzahl_label -text "Anzahl:" -width 10 -anchor w
    pack $w.munition_anzahl_frame.anzahl_label -side left -padx "20 0"

    # Anzahl-Eingabefeld für Munition (numerischer Wert)
    # Mit Validierung: Nur numerische Werte erlauben
    entry $w.munition_anzahl_frame.anzahl_entry -textvariable ::neuer_eintrag::anzahl -width 10 \
        -validate key -validatecommand {::neuer_eintrag::validiere_anzahl_eingabe %P}
    pack $w.munition_anzahl_frame.anzahl_entry -side left -padx 5

    # Fokus-Verlust-Event: Wert normalisieren (auf gültige positive Zahl)
    bind $w.munition_anzahl_frame.anzahl_entry <FocusOut> ::neuer_eintrag::anzahl_fokus_verloren

    # Enter-Taste im Anzahl-Feld soll Munition hinzufügen
    bind $w.munition_anzahl_frame.anzahl_entry <Return> ::neuer_eintrag::munition_hinzufuegen

    # Hinzufügen-Button (hellblau, farbig)
    button $w.munition_anzahl_frame.add_button -text "Hinzufügen" -bg "#ADD8E6" -width 12 \
        -command ::neuer_eintrag::munition_hinzufuegen
    pack $w.munition_anzahl_frame.add_button -side left -padx 10

    # =========================================================================
    # Listbox für hinzugefügte Munitionskäufe
    # =========================================================================
    frame $w.munitions_liste_frame
    pack $w.munitions_liste_frame -in $w.main -fill both -expand 1 -pady 5

    label $w.munitions_liste_frame.label -text "Hinzugefügte Munition:" -anchor w
    pack $w.munitions_liste_frame.label -side top -anchor w

    # Listbox mit Scrollbar
    frame $w.munitions_liste_frame.list_container
    pack $w.munitions_liste_frame.list_container -side top -fill both -expand 1

    scrollbar $w.munitions_liste_frame.list_container.scrollbar -command "$w.munitions_liste_frame.listbox yview"
    pack $w.munitions_liste_frame.list_container.scrollbar -side right -fill y

    listbox $w.munitions_liste_frame.listbox -height 4 -yscrollcommand "$w.munitions_liste_frame.list_container.scrollbar set"
    pack $w.munitions_liste_frame.listbox -in $w.munitions_liste_frame.list_container -side left -fill both -expand 1

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
    # Bemerkungen-Eingabefeld
    # =========================================================================
    frame $w.bemerkungen_frame
    pack $w.bemerkungen_frame -in $w.main -fill x -pady 5

    label $w.bemerkungen_frame.label -text "Bemerkungen:" -width 20 -anchor w
    pack $w.bemerkungen_frame.label -side left

    entry $w.bemerkungen_frame.entry -textvariable ::neuer_eintrag::bemerkungen -width 40
    pack $w.bemerkungen_frame.entry -side left -fill x -expand 1

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
        -command ::neuer_eintrag::schliesse_fenster
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
