# =============================================================================
# Daten-Prüfungs-Dialog für das svm-journal Projekt
# Prüft und repariert JSON-Datenbank-Dateien
# =============================================================================

# Namespace für Daten-Prüfung
namespace eval ::daten_pruefen {
    # Fenster-Referenz
    variable fenster ""

    # Textfeld für Ausgaben
    variable ausgabe_text ""

    # Statistik-Variablen
    variable dateien_geprueft 0
    variable eintraege_geprueft 0
    variable eintraege_korrigiert 0
    variable fehler_gefunden 0
    variable backups_erstellt 0

    # Flag ob Prüfung läuft
    variable pruefung_laeuft 0
}

# =============================================================================
# Prozedur: log_ausgabe
# Fügt eine Zeile zur Ausgabe hinzu
# Parameter:
#   nachricht - Die auszugebende Nachricht
# =============================================================================
proc ::daten_pruefen::log_ausgabe {nachricht} {
    variable ausgabe_text

    if {$ausgabe_text ne "" && [winfo exists $ausgabe_text]} {
        $ausgabe_text insert end "$nachricht\n"
        $ausgabe_text see end
        update idletasks
    }
}

# =============================================================================
# Prozedur: log_fehler
# Fügt eine Fehler-Zeile zur Ausgabe hinzu (farbig markiert)
# Parameter:
#   nachricht - Die Fehler-Nachricht
# =============================================================================
proc ::daten_pruefen::log_fehler {nachricht} {
    variable ausgabe_text

    if {$ausgabe_text ne "" && [winfo exists $ausgabe_text]} {
        set startindex [$ausgabe_text index end-1c]
        $ausgabe_text insert end "FEHLER: $nachricht\n"
        set endindex [$ausgabe_text index end-1c]
        $ausgabe_text tag add fehler $startindex $endindex
        $ausgabe_text tag configure fehler -foreground red
        $ausgabe_text see end
        update idletasks
    }
}

# =============================================================================
# Prozedur: log_erfolg
# Fügt eine Erfolgs-Zeile zur Ausgabe hinzu (farbig markiert)
# Parameter:
#   nachricht - Die Erfolgs-Nachricht
# =============================================================================
proc ::daten_pruefen::log_erfolg {nachricht} {
    variable ausgabe_text

    if {$ausgabe_text ne "" && [winfo exists $ausgabe_text]} {
        set startindex [$ausgabe_text index end-1c]
        $ausgabe_text insert end "OK: $nachricht\n"
        set endindex [$ausgabe_text index end-1c]
        $ausgabe_text tag add erfolg $startindex $endindex
        $ausgabe_text tag configure erfolg -foreground green
        $ausgabe_text see end
        update idletasks
    }
}

# =============================================================================
# Prozedur: normalisiere_preis
# Normalisiert einen Preis-Wert zu einem gültigen Format
# Wandelt nicht-numerische Werte in "0,00" um
# Parameter:
#   wert - Der zu normalisierende Wert
# Rückgabe: Normalisierter Preis im Format "0,00"
# =============================================================================
proc ::daten_pruefen::normalisiere_preis {wert} {
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
# Prozedur: validiere_datum
# Validiert und normalisiert ein Datum
# Parameter:
#   datum - Der zu prüfende Datumswert
# Rückgabe: Dictionary mit {gueltig 0/1, datum "DD.MM.YYYY", fehler "beschreibung"}
# =============================================================================
proc ::daten_pruefen::validiere_datum {datum} {
    # Trimmen
    set datum [string trim $datum]

    # Prüfen, ob Datum leer ist
    if {$datum eq ""} {
        return [dict create gueltig 0 datum "" fehler "Datum ist leer"]
    }

    # Prüfen, ob Format DD.MM.YYYY ist
    if {![regexp {^(\d{1,2})\.(\d{1,2})\.(\d{4})$} $datum -> tag monat jahr]} {
        return [dict create gueltig 0 datum $datum fehler "Ungültiges Format (erwartet: TT.MM.JJJJ)"]
    }

    # Führende Nullen entfernen für numerische Vergleiche (Tcl interpretiert sonst als Oktal)
    # Verwende "scan" mit %d um sicherzustellen, dass wir Dezimalzahlen erhalten
    scan $tag %d tag_int
    scan $monat %d monat_int

    # Plausibilitätsprüfung
    if {$monat_int < 1 || $monat_int > 12} {
        return [dict create gueltig 0 datum $datum fehler "Monat ungültig: $monat"]
    }

    if {$tag_int < 1 || $tag_int > 31} {
        return [dict create gueltig 0 datum $datum fehler "Tag ungültig: $tag"]
    }

    # Tag und Monat auf 2 Stellen normalisieren (jetzt mit den bereinigten Integer-Werten)
    set tag_norm [format "%02d" $tag_int]
    set monat_norm [format "%02d" $monat_int]

    # Normalisiertes Datum
    set datum_norm "${tag_norm}.${monat_norm}.${jahr}"

    return [dict create gueltig 1 datum $datum_norm fehler ""]
}

# =============================================================================
# Prozedur: lade_eintraege_aus_datei
# Lädt Einträge aus einer JSON-Datei
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
# Rückgabe: Liste von Eintrags-Dictionaries
# =============================================================================
proc ::daten_pruefen::lade_eintraege_aus_datei {datei_pfad} {
    # Prüfen, ob Datei existiert
    if {![file exists $datei_pfad]} {
        return [list]
    }

    # Datei öffnen und lesen
    set fp [open $datei_pfad r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Einträge aus JSON parsen
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

                # Vollständiger Eintrag gefunden
                set size [dict size $eintrag_data]
                if {$size >= 11} {
                    # Für alte Einträge ohne Anzahl: Standardwert 1 setzen
                    if {![dict exists $eintrag_data anzahl]} {
                        dict set eintrag_data anzahl "1"
                    }
                    lappend eintraege $eintrag_data
                    set eintrag_data [dict create]
                }
            }
        }
    }

    return $eintraege
}

# =============================================================================
# Prozedur: speichere_eintraege_in_datei
# Speichert Einträge in eine JSON-Datei
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
#   eintraege - Liste von Eintrags-Dictionaries
# =============================================================================
proc ::daten_pruefen::speichere_eintraege_in_datei {datei_pfad eintraege} {
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
    set fp [open $datei_pfad w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp
}

# =============================================================================
# Prozedur: pruefe_datei
# Prüft eine einzelne JSON-Datei und korrigiert Fehler
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
# Rückgabe: Dictionary mit Statistiken {geprueft X korrigiert Y fehler Z}
# =============================================================================
proc ::daten_pruefen::pruefe_datei {datei_pfad} {
    variable backups_erstellt

    # Statistik für diese Datei
    set stat_geprueft 0
    set stat_korrigiert 0
    set stat_fehler 0

    # Dateiname extrahieren
    set dateiname [file tail $datei_pfad]

    log_ausgabe "=========================================="
    log_ausgabe "Prüfe Datei: $dateiname"
    log_ausgabe "=========================================="

    # Einträge laden
    if {[catch {
        set eintraege [lade_eintraege_aus_datei $datei_pfad]
    } fehler]} {
        log_fehler "Fehler beim Laden der Datei: $fehler"
        return [dict create geprueft 0 korrigiert 0 fehler 1]
    }

    if {[llength $eintraege] == 0} {
        log_ausgabe "  Keine Einträge gefunden oder Datei ist leer"
        return [dict create geprueft 0 korrigiert 0 fehler 0]
    }

    log_ausgabe "  Gefundene Einträge: [llength $eintraege]"

    # Backup erstellen (nur wenn Änderungen erforderlich)
    set backup_erforderlich 0
    set bereinigte_eintraege [list]

    # Jeder Eintrag durchgehen
    foreach eintrag $eintraege {
        incr stat_geprueft
        set eintrag_geaendert 0

        # 1. PRÜFUNG: Pflichtfelder vorhanden
        set pflichtfelder {datum uhrzeit nachname vorname kurzwaffe langwaffe waffentyp kaliber startgeld anzahl munition munitionspreis}
        foreach feld $pflichtfelder {
            if {![dict exists $eintrag $feld]} {
                log_fehler "  Eintrag [dict get $eintrag nachname] ([dict get $eintrag datum]): Feld '$feld' fehlt"
                incr stat_fehler
                # Fehlende Felder mit Standardwerten ergänzen
                switch $feld {
                    "datum" { dict set eintrag $feld "01.01.2000" }
                    "uhrzeit" { dict set eintrag $feld "00:00:00" }
                    "nachname" { dict set eintrag $feld "Unbekannt" }
                    "vorname" { dict set eintrag $feld "Unbekannt" }
                    "kurzwaffe" { dict set eintrag $feld "Nein" }
                    "langwaffe" { dict set eintrag $feld "Nein" }
                    "waffentyp" { dict set eintrag $feld "" }
                    "kaliber" { dict set eintrag $feld "" }
                    "startgeld" { dict set eintrag $feld "0,00" }
                    "anzahl" { dict set eintrag $feld "1" }
                    "munition" { dict set eintrag $feld "Keine" }
                    "munitionspreis" { dict set eintrag $feld "0,00" }
                }
                set eintrag_geaendert 1
            }
        }

        # 2. PRÜFUNG: Datum validieren
        set datum [dict get $eintrag datum]
        set datum_validierung [validiere_datum $datum]

        if {![dict get $datum_validierung gueltig]} {
            log_ausgabe "  Eintrag [dict get $eintrag nachname]: Datum '$datum' - [dict get $datum_validierung fehler]"
            incr stat_fehler
        } else {
            set datum_neu [dict get $datum_validierung datum]
            if {$datum ne $datum_neu} {
                log_ausgabe "  Eintrag [dict get $eintrag nachname]: Datum normalisiert '$datum' -> '$datum_neu'"
                dict set eintrag datum $datum_neu
                incr stat_korrigiert
                set eintrag_geaendert 1
            }
        }

        # 3. PRÜFUNG: Startgeld validieren
        set alt_startgeld [dict get $eintrag startgeld]
        set neu_startgeld [normalisiere_preis $alt_startgeld]

        if {$alt_startgeld ne $neu_startgeld} {
            log_ausgabe "  Eintrag [dict get $eintrag nachname] ([dict get $eintrag datum]): Startgeld '$alt_startgeld' -> '$neu_startgeld'"
            dict set eintrag startgeld $neu_startgeld
            incr stat_korrigiert
            set eintrag_geaendert 1
        }

        # 4. PRÜFUNG: Munitionspreis validieren
        set alt_munitionspreis [dict get $eintrag munitionspreis]
        set neu_munitionspreis [normalisiere_preis $alt_munitionspreis]

        if {$alt_munitionspreis ne $neu_munitionspreis} {
            log_ausgabe "  Eintrag [dict get $eintrag nachname] ([dict get $eintrag datum]): Munitionspreis '$alt_munitionspreis' -> '$neu_munitionspreis'"
            dict set eintrag munitionspreis $neu_munitionspreis
            incr stat_korrigiert
            set eintrag_geaendert 1
        }

        # Wenn Änderungen vorgenommen wurden, Backup markieren
        if {$eintrag_geaendert} {
            set backup_erforderlich 1
        }

        lappend bereinigte_eintraege $eintrag
    }

    # Backup erstellen und Datei speichern (nur wenn Änderungen)
    if {$backup_erforderlich} {
        # Backup im zentralen Backup-Verzeichnis erstellen
        set backup_dir [::pfad::get_backups_directory]
        set dateiname [file tail $datei_pfad]
        set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
        set backup_filename "${dateiname}.${timestamp}.backup"
        set backup_pfad [file join $backup_dir $backup_filename]

        if {[catch {
            file copy -force $datei_pfad $backup_pfad
            log_erfolg "  Backup erstellt: [file tail $backup_pfad]"
            incr backups_erstellt
        } fehler]} {
            log_fehler "  Fehler beim Erstellen des Backups: $fehler"
        }

        # Datei speichern
        if {[catch {
            speichere_eintraege_in_datei $datei_pfad $bereinigte_eintraege
            log_erfolg "  Datei aktualisiert: $stat_korrigiert Korrekturen vorgenommen"
        } fehler]} {
            log_fehler "  Fehler beim Speichern der Datei: $fehler"
            incr stat_fehler
        }
    } else {
        log_erfolg "  Keine Korrekturen erforderlich"
    }

    log_ausgabe ""

    return [dict create geprueft $stat_geprueft korrigiert $stat_korrigiert fehler $stat_fehler]
}

# =============================================================================
# Prozedur: pruefe_kaliber_preise_datei
# Prüft die kaliber-preise.json Datei und korrigiert Preise
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
# Rückgabe: Dictionary mit Statistiken {geprueft X korrigiert Y fehler Z}
# =============================================================================
proc ::daten_pruefen::pruefe_kaliber_preise_datei {datei_pfad} {
    variable backups_erstellt

    # Statistik für diese Datei
    set stat_geprueft 0
    set stat_korrigiert 0
    set stat_fehler 0

    # Dateiname extrahieren
    set dateiname [file tail $datei_pfad]

    log_ausgabe "=========================================="
    log_ausgabe "Prüfe Datei: $dateiname"
    log_ausgabe "=========================================="

    # Datei lesen
    if {[catch {
        set fp [open $datei_pfad r]
        fconfigure $fp -encoding utf-8
        set json_content [read $fp]
        close $fp
    } fehler]} {
        log_fehler "Fehler beim Laden der Datei: $fehler"
        return [dict create geprueft 0 korrigiert 0 fehler 1]
    }

    # JSON parsen - Zeile für Zeile
    set lines [split $json_content "\n"]
    set neue_lines [list]
    set backup_erforderlich 0

    foreach line $lines {
        set neue_line $line

        # Preis-Felder suchen und prüfen
        if {[string match "*\"preis\":*" $line]} {
            if {[regexp {"preis":\s*"([^"]*)"} $line -> preis]} {
                incr stat_geprueft

                # Preis normalisieren
                set neuer_preis [normalisiere_preis $preis]

                if {$preis ne $neuer_preis} {
                    log_ausgabe "  Preis normalisiert: '$preis' -> '$neuer_preis'"
                    incr stat_korrigiert
                    set backup_erforderlich 1

                    # Zeile aktualisieren
                    set neue_line [regsub {"preis":\s*"[^"]*"} $line "\"preis\": \"$neuer_preis\""]
                }
            }
        }

        lappend neue_lines $neue_line
    }

    # Backup erstellen und Datei speichern (nur wenn Änderungen)
    if {$backup_erforderlich} {
        # Backup im zentralen Backup-Verzeichnis erstellen
        set backup_dir [::pfad::get_backups_directory]
        set dateiname [file tail $datei_pfad]
        set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
        set backup_filename "${dateiname}.${timestamp}.backup"
        set backup_pfad [file join $backup_dir $backup_filename]

        if {[catch {
            file copy -force $datei_pfad $backup_pfad
            log_erfolg "  Backup erstellt: [file tail $backup_pfad]"
            incr backups_erstellt
        } fehler]} {
            log_fehler "  Fehler beim Erstellen des Backups: $fehler"
        }

        # Datei speichern
        if {[catch {
            set fp [open $datei_pfad w]
            fconfigure $fp -encoding utf-8
            puts $fp [join $neue_lines "\n"]
            close $fp
            log_erfolg "  Datei aktualisiert: $stat_korrigiert Korrekturen vorgenommen"
        } fehler]} {
            log_fehler "  Fehler beim Speichern der Datei: $fehler"
            incr stat_fehler
        }
    } else {
        log_erfolg "  Keine Korrekturen erforderlich"
    }

    log_ausgabe ""

    return [dict create geprueft $stat_geprueft korrigiert $stat_korrigiert fehler $stat_fehler]
}

# =============================================================================
# Prozedur: pruefe_stand_nutzung_datei
# Prüft die stand-nutzung.json Datei und korrigiert Preise
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
# Rückgabe: Dictionary mit Statistiken {geprueft X korrigiert Y fehler Z}
# =============================================================================
proc ::daten_pruefen::pruefe_stand_nutzung_datei {datei_pfad} {
    variable backups_erstellt

    # Statistik für diese Datei
    set stat_geprueft 0
    set stat_korrigiert 0
    set stat_fehler 0

    # Dateiname extrahieren
    set dateiname [file tail $datei_pfad]

    log_ausgabe "=========================================="
    log_ausgabe "Prüfe Datei: $dateiname"
    log_ausgabe "=========================================="

    # Datei lesen
    if {[catch {
        set fp [open $datei_pfad r]
        fconfigure $fp -encoding utf-8
        set json_content [read $fp]
        close $fp
    } fehler]} {
        log_fehler "Fehler beim Laden der Datei: $fehler"
        return [dict create geprueft 0 korrigiert 0 fehler 1]
    }

    # JSON parsen - Zeile für Zeile
    set lines [split $json_content "\n"]
    set neue_lines [list]
    set backup_erforderlich 0

    # Preis-Felder in stand-nutzung.json:
    # "Mitglied Luftdruck", "Mitglied Kleinkaliber", "Mitglied Grosskaliber", "Gast"
    set preis_felder [list "Mitglied Luftdruck" "Mitglied Kleinkaliber" "Mitglied Grosskaliber" "Gast"]

    foreach line $lines {
        set neue_line $line

        # Jedes Preis-Feld prüfen
        foreach feld $preis_felder {
            if {[string match "*\"$feld\":*" $line]} {
                if {[regexp "\"$feld\":\\s*\"(\[^\"\]*)\"" $line -> preis]} {
                    incr stat_geprueft

                    # Preis normalisieren
                    set neuer_preis [normalisiere_preis $preis]

                    if {$preis ne $neuer_preis} {
                        log_ausgabe "  $feld: '$preis' -> '$neuer_preis'"
                        incr stat_korrigiert
                        set backup_erforderlich 1

                        # Zeile aktualisieren
                        set neue_line [regsub "\"$feld\":\\s*\"(\[^\"\]*)\"" $neue_line "\"$feld\": \"$neuer_preis\""]
                    }
                }
            }
        }

        lappend neue_lines $neue_line
    }

    # Backup erstellen und Datei speichern (nur wenn Änderungen)
    if {$backup_erforderlich} {
        # Backup im zentralen Backup-Verzeichnis erstellen
        set backup_dir [::pfad::get_backups_directory]
        set dateiname [file tail $datei_pfad]
        set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
        set backup_filename "${dateiname}.${timestamp}.backup"
        set backup_pfad [file join $backup_dir $backup_filename]

        if {[catch {
            file copy -force $datei_pfad $backup_pfad
            log_erfolg "  Backup erstellt: [file tail $backup_pfad]"
            incr backups_erstellt
        } fehler]} {
            log_fehler "  Fehler beim Erstellen des Backups: $fehler"
        }

        # Datei speichern
        if {[catch {
            set fp [open $datei_pfad w]
            fconfigure $fp -encoding utf-8
            puts $fp [join $neue_lines "\n"]
            close $fp
            log_erfolg "  Datei aktualisiert: $stat_korrigiert Korrekturen vorgenommen"
        } fehler]} {
            log_fehler "  Fehler beim Speichern der Datei: $fehler"
            incr stat_fehler
        }
    } else {
        log_erfolg "  Keine Korrekturen erforderlich"
    }

    log_ausgabe ""

    return [dict create geprueft $stat_geprueft korrigiert $stat_korrigiert fehler $stat_fehler]
}

# =============================================================================
# Prozedur: starte_pruefung
# Startet die Datenprüfung für alle JSON-Dateien
# =============================================================================
proc ::daten_pruefen::starte_pruefung {} {
    variable fenster
    variable ausgabe_text
    variable dateien_geprueft
    variable eintraege_geprueft
    variable eintraege_korrigiert
    variable fehler_gefunden
    variable backups_erstellt
    variable pruefung_laeuft

    # Prüfen, ob bereits eine Prüfung läuft
    if {$pruefung_laeuft} {
        return
    }

    set pruefung_laeuft 1

    # Button deaktivieren
    if {[winfo exists $fenster.button_frame.start]} {
        $fenster.button_frame.start configure -state disabled
    }

    # Ausgabe leeren
    $ausgabe_text delete 1.0 end

    # Statistik zurücksetzen
    set dateien_geprueft 0
    set eintraege_geprueft 0
    set eintraege_korrigiert 0
    set fehler_gefunden 0
    set backups_erstellt 0

    log_ausgabe "============================================="
    log_ausgabe "Datenprüfung für svm-journal"
    log_ausgabe "============================================="
    log_ausgabe "Gestartet am: [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]"
    log_ausgabe ""

    # Daten-Verzeichnis und Preferences-Verzeichnis
    set daten_dir [::pfad::get_daten_directory]
    set preferences_dir [::pfad::get_preferences_directory]

    # Alle JSON-Dateien sammeln
    # Journal-Dateien (außer mitglieder.json)
    set journal_dateien [list]
    # Preferences-Dateien
    set preferences_dateien [list]

    # Daten-Verzeichnis durchsuchen
    # Nur Jahres-JSON-Dateien (z.B. 2025.json) als Journal-Dateien behandeln
    # mitglieder.json und waffenregister.json haben eine andere Struktur
    if {[file exists $daten_dir]} {
        foreach datei [glob -nocomplain -directory $daten_dir *.json] {
            set dateiname [file tail $datei]
            # Nur Dateien mit Jahreszahl als Name sind Journal-Dateien
            if {[regexp {^\d{4}\.json$} $dateiname]} {
                lappend journal_dateien $datei
            }
        }
    }

    # Preferences-Verzeichnis durchsuchen
    if {[file exists $preferences_dir]} {
        foreach datei [glob -nocomplain -directory $preferences_dir *.json] {
            lappend preferences_dateien $datei
        }
    }

    set gesamt_dateien [expr {[llength $journal_dateien] + [llength $preferences_dateien]}]
    log_ausgabe "Gefundene Dateien: $gesamt_dateien"
    log_ausgabe "  - Journal-Dateien: [llength $journal_dateien]"
    log_ausgabe "  - Preferences-Dateien: [llength $preferences_dateien]"
    log_ausgabe ""

    # Journal-Dateien prüfen
    foreach datei $journal_dateien {
        set ergebnis [pruefe_datei $datei]

        incr dateien_geprueft
        incr eintraege_geprueft [dict get $ergebnis geprueft]
        incr eintraege_korrigiert [dict get $ergebnis korrigiert]
        incr fehler_gefunden [dict get $ergebnis fehler]
    }

    # Preferences-Dateien prüfen (mit speziellen Prüffunktionen)
    foreach datei $preferences_dateien {
        set dateiname [file tail $datei]
        set ergebnis ""

        # Richtige Prüffunktion basierend auf Dateinamen wählen
        if {$dateiname eq "kaliber-preise.json"} {
            # Kaliber-Preise: Preisfelder auf numerisches Format prüfen
            set ergebnis [pruefe_kaliber_preise_datei $datei]
        } elseif {$dateiname eq "stand-nutzung.json"} {
            # Stand-Nutzung: Preisfelder auf numerisches Format prüfen
            set ergebnis [pruefe_stand_nutzung_datei $datei]
        } elseif {$dateiname in {verein.json behoerde.json fenster.json kaliber.json}} {
            # Konfigurations-Dateien ohne spezielle Validierung - überspringen
            log_ausgabe "=========================================="
            log_ausgabe "Überspringe Konfigurationsdatei: $dateiname (keine Validierung nötig)"
            log_ausgabe "=========================================="
            log_ausgabe ""
            continue
        } else {
            # Unbekannte Preferences-Datei - überspringen mit Hinweis
            log_ausgabe "=========================================="
            log_ausgabe "Überspringe unbekannte Datei: $dateiname"
            log_ausgabe "=========================================="
            log_ausgabe ""
            continue
        }

        incr dateien_geprueft
        incr eintraege_geprueft [dict get $ergebnis geprueft]
        incr eintraege_korrigiert [dict get $ergebnis korrigiert]
        incr fehler_gefunden [dict get $ergebnis fehler]
    }

    # Zusammenfassung
    log_ausgabe "============================================="
    log_ausgabe "Prüfung abgeschlossen!"
    log_ausgabe "============================================="
    log_ausgabe "Dateien geprüft:      $dateien_geprueft"
    log_ausgabe "Einträge geprüft:     $eintraege_geprueft"
    log_ausgabe "Einträge korrigiert:  $eintraege_korrigiert"
    log_ausgabe "Fehler gefunden:      $fehler_gefunden"
    log_ausgabe "Backups erstellt:     $backups_erstellt"
    log_ausgabe ""
    log_ausgabe "Backup-Speicherort: [::pfad::get_backups_directory]"
    log_ausgabe ""

    if {$backups_erstellt > 0} {
        log_ausgabe "HINWEIS: Backup-Dateien wurden mit der Endung .backup erstellt."
        log_ausgabe "         Diese können nach erfolgreicher Prüfung gelöscht werden."
    }

    if {$eintraege_korrigiert == 0 && $fehler_gefunden == 0} {
        log_erfolg "Alle Daten sind korrekt!"
    } elseif {$fehler_gefunden > 0} {
        log_fehler "Es wurden $fehler_gefunden Fehler gefunden!"
    } else {
        log_erfolg "$eintraege_korrigiert Einträge wurden erfolgreich korrigiert!"
    }

    log_ausgabe ""

    # Hauptfenster-Tabelle neu laden
    if {[winfo exists .main.tree]} {
        log_ausgabe "Aktualisiere Hauptfenster..."

        # Treeview leeren
        .main.tree delete [.main.tree children {}]

        # Einträge neu laden
        if {[llength [info commands ::lade_existierende_eintraege]] > 0} {
            ::lade_existierende_eintraege
            log_erfolg "Hauptfenster wurde aktualisiert"
        }
    }

    # Button wieder aktivieren
    if {[winfo exists $fenster.button_frame.start]} {
        $fenster.button_frame.start configure -state normal
    }

    set pruefung_laeuft 0
}

# =============================================================================
# Prozedur: open_daten_pruefen_dialog
# Öffnet das Fenster zur Datenprüfung
# =============================================================================
proc open_daten_pruefen_dialog {} {
    set w .daten_pruefen
    set ::daten_pruefen::fenster $w

    # Falls Fenster bereits existiert, in den Vordergrund bringen
    if {[winfo exists $w]} {
        raise $w
        return
    }

    # Neues Toplevel-Fenster
    toplevel $w
    wm title $w "Daten überprüfen"
    wm geometry $w "900x750"

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # =========================================================================
    # Beschreibung
    # =========================================================================
    label $w.main.beschreibung -text "Dieses Werkzeug pr\u00fcft alle JSON-Datenbank-Dateien auf Fehler und korrigiert diese automatisch.\n\nGepr\u00fcfte Verzeichnisse:\n\u2022 daten/ - Schie\u00dfjournal-Eintr\u00e4ge (Jahres-Dateien)\n\u2022 preferences/ - Kaliber-Preise und Stand-Nutzungsgeb\u00fchren\n\nValidierungen:\n\u2022 Preis-Felder auf numerische Werte und korrektes Format\n\u2022 Datumsformate und Plausibilit\u00e4t\n\u2022 Vollst\u00e4ndigkeit der Pflichtfelder\n\nVor jeder \u00c4nderung wird automatisch ein Backup erstellt." \
        -justify left -anchor w
    pack $w.main.beschreibung -fill x -pady "0 20"

    # =========================================================================
    # Ausgabe-Textfeld mit Scrollbar
    # =========================================================================
    frame $w.ausgabe_frame
    pack $w.ausgabe_frame -in $w.main -fill both -expand 1

    # Scrollbar
    scrollbar $w.ausgabe_frame.scrollbar -command "$w.ausgabe_frame.text yview"
    pack $w.ausgabe_frame.scrollbar -side right -fill y

    # Textfeld
    text $w.ausgabe_frame.text -height 25 -width 80 -yscrollcommand "$w.ausgabe_frame.scrollbar set" \
        -font {Courier 9} -wrap word -state normal
    pack $w.ausgabe_frame.text -side left -fill both -expand 1

    set ::daten_pruefen::ausgabe_text $w.ausgabe_frame.text

    # Initial-Text
    $w.ausgabe_frame.text insert end "Bereit zur Datenprüfung.\n\n"
    $w.ausgabe_frame.text insert end "Klicken Sie auf 'Prüfung starten', um die Überprüfung zu beginnen.\n"

    # =========================================================================
    # Buttons
    # =========================================================================
    frame $w.button_frame
    pack $w.button_frame -in $w.main -fill x -pady "20 0"

    # Button "Prüfung starten"
    button $w.button_frame.start -text "Prüfung starten" -bg "#90EE90" -width 20 \
        -command ::daten_pruefen::starte_pruefung
    pack $w.button_frame.start -side left -padx 5

    # Button "Schließen"
    button $w.button_frame.close -text "Schließen" -bg "#FFB6C1" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.close -side right -padx 5
}
