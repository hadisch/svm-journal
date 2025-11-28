#!/usr/bin/env tclsh
# =============================================================================
# Bereinigungs-Skript für Preis-Felder in JSON-Datenbank
# Wandelt nicht-numerische Werte in Startgeld und Munitionspreis in "0,00" um
# =============================================================================
#
# HINWEIS: Diese Funktionalität ist jetzt auch direkt im Programm verfügbar!
# Im Hauptprogramm: Menü "Werkzeuge" → "Daten überprüfen..."
#
# Dieses Kommandozeilen-Skript kann weiterhin unabhängig verwendet werden.
# =============================================================================

# Encoding auf UTF-8 setzen
encoding system utf-8

# =============================================================================
# Prozedur: normalisiere_preis
# Normalisiert einen Preis-Wert zu einem gültigen Format
# Wandelt nicht-numerische Werte in "0,00" um
# Parameter:
#   wert - Der zu normalisierende Wert
# Rückgabe: Normalisierter Preis im Format "0,00"
# =============================================================================
proc normalisiere_preis {wert} {
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
# Prozedur: bereinige_json_datei
# Bereinigt eine einzelne JSON-Datei
# Parameter:
#   datei_pfad - Pfad zur JSON-Datei
# Rückgabe: Anzahl der geänderten Einträge
# =============================================================================
proc bereinige_json_datei {datei_pfad} {
    # Prüfen, ob Datei existiert
    if {![file exists $datei_pfad]} {
        return 0
    }

    puts "Bearbeite: $datei_pfad"

    # Datei öffnen und lesen
    set fp [open $datei_pfad r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Backup erstellen
    set backup_pfad "${datei_pfad}.backup"
    set fp_backup [open $backup_pfad w]
    fconfigure $fp_backup -encoding utf-8
    puts $fp_backup $json_content
    close $fp_backup
    puts "  Backup erstellt: $backup_pfad"

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

                # Vollständiger Eintrag gefunden - zur Liste hinzufügen
                # Unterstützt sowohl alte Einträge (11 Felder) als auch neue (12 Felder mit Anzahl)
                set size [dict size $eintrag_data]
                if {$size == 11 || $size == 12} {
                    # Für alte Einträge ohne Anzahl: Standardwert 1 setzen
                    if {$size == 11 && ![dict exists $eintrag_data anzahl]} {
                        dict set eintrag_data anzahl "1"
                    }
                    lappend eintraege $eintrag_data
                    set eintrag_data [dict create]
                }
            }
        }
    }

    # Einträge bereinigen und Änderungen zählen
    set geaenderte_eintraege 0
    set bereinigte_eintraege [list]

    foreach eintrag $eintraege {
        set geaendert 0

        # Startgeld normalisieren
        set alt_startgeld [dict get $eintrag startgeld]
        set neu_startgeld [normalisiere_preis $alt_startgeld]

        if {$alt_startgeld ne $neu_startgeld} {
            puts "  Startgeld geändert: '$alt_startgeld' -> '$neu_startgeld' ([dict get $eintrag datum], [dict get $eintrag nachname])"
            dict set eintrag startgeld $neu_startgeld
            set geaendert 1
        }

        # Munitionspreis normalisieren
        set alt_munitionspreis [dict get $eintrag munitionspreis]
        set neu_munitionspreis [normalisiere_preis $alt_munitionspreis]

        if {$alt_munitionspreis ne $neu_munitionspreis} {
            puts "  Munitionspreis geändert: '$alt_munitionspreis' -> '$neu_munitionspreis' ([dict get $eintrag datum], [dict get $eintrag nachname])"
            dict set eintrag munitionspreis $neu_munitionspreis
            set geaendert 1
        }

        if {$geaendert} {
            incr geaenderte_eintraege
        }

        lappend bereinigte_eintraege $eintrag
    }

    # JSON-Datei neu schreiben (nur wenn Änderungen vorgenommen wurden)
    if {$geaenderte_eintraege > 0} {
        set lines [list]
        lappend lines "\{"
        lappend lines "  \"eintraege\": \["

        set anzahl [llength $bereinigte_eintraege]
        set counter 0

        foreach entry $bereinigte_eintraege {
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

        puts "  Datei aktualisiert. $geaenderte_eintraege Einträge wurden bereinigt."
    } else {
        puts "  Keine Änderungen erforderlich."
    }

    return $geaenderte_eintraege
}

# =============================================================================
# Hauptprogramm
# =============================================================================

puts "============================================="
puts "Preis-Bereinigung für svm-journal Datenbank"
puts "============================================="
puts ""

# Daten-Verzeichnis
set script_dir [file dirname [info script]]
set daten_dir [file join $script_dir "daten"]
set archiv_dir [file join $daten_dir "archiv"]

# Statistik
set gesamt_dateien 0
set gesamt_eintraege 0

# Alle JSON-Dateien im daten-Verzeichnis bereinigen
if {[file exists $daten_dir]} {
    puts "Durchsuche daten/ Verzeichnis..."
    foreach datei [glob -nocomplain -directory $daten_dir *.json] {
        set geaendert [bereinige_json_datei $datei]
        incr gesamt_dateien
        incr gesamt_eintraege $geaendert
    }
    puts ""
}

# Alle JSON-Dateien im archiv-Verzeichnis bereinigen
if {[file exists $archiv_dir]} {
    puts "Durchsuche daten/archiv/ Verzeichnis..."
    foreach datei [glob -nocomplain -directory $archiv_dir *.json] {
        set geaendert [bereinige_json_datei $datei]
        incr gesamt_dateien
        incr gesamt_eintraege $geaendert
    }
    puts ""
}

# Zusammenfassung
puts "============================================="
puts "Bereinigung abgeschlossen!"
puts "============================================="
puts "Dateien bearbeitet: $gesamt_dateien"
puts "Einträge bereinigt: $gesamt_eintraege"
puts ""

if {$gesamt_eintraege > 0} {
    puts "HINWEIS: Backup-Dateien wurden mit der Endung .backup erstellt."
    puts "         Diese können nach erfolgreicher Prüfung gelöscht werden."
} else {
    puts "Alle Preis-Felder waren bereits im korrekten Format."
}

puts ""
