# =============================================================================
# schuetzenstatus.tcl - Status eines Schützen im Journal (Mitglied/Anwärter/Gast)
# =============================================================================
# Jeder Journal-Eintrag trägt seit Version 1.12.0 das Feld "status":
#   "M" = Mitglied, "A" = Anwärter (Warteliste), "G" = Gastschütze,
#   ""  = unbekannt (nur bei alten Einträgen, die nicht zuzuordnen waren)
#
# Der Status wird beim Erfassen gespeichert und ist damit historisch richtig:
# Wer später Mitglied wird, bleibt bei seinen früheren Gast-Besuchen "G".
#
# Früher wurde der Status als Bemerkung ("Gastschütze", "Auf der Warteliste")
# gespeichert. ::schuetzenstatus::migration_pruefen stellt alte Journal-Dateien
# beim Programmstart einmalig um (mit Backup) und entfernt diese Texte aus den
# Bemerkungen.
# =============================================================================

namespace eval ::schuetzenstatus {
    # Langtexte der Status-Kürzel (Umlaute als Unicode-Escapes)
    variable texte [dict create \
        M "Mitglied" \
        A "Anwärter" \
        G "Gastschütze"]

    # Bemerkungstexte, die früher automatisch für Gäste eingetragen wurden.
    # Treffer, wenn die Bemerkung damit beginnt und danach nichts oder ein
    # Trennzeichen folgt (z.B. "Gastschütze-Warteliste" -> Rest "Warteliste").
    variable gast_woerter [list "Gastschütze" "Gastschützin" "Gast"]

    # Bemerkungstext, der früher automatisch für Anwärter eingetragen wurde
    variable anwaerter_text "Auf der Warteliste"
}

# =============================================================================
# Prozedur: ::schuetzenstatus::text
# Liefert den Langtext zu einem Status-Kürzel ("" bei unbekanntem Status).
# =============================================================================
proc ::schuetzenstatus::text {kuerzel} {
    variable texte
    if {[dict exists $texte $kuerzel]} {
        return [dict get $texte $kuerzel]
    }
    return ""
}

# =============================================================================
# Prozedur: ::schuetzenstatus::lade_listen
# Lädt Mitglieder, Anwärter und bekannte Gäste und liefert ein Dictionary
#   Vergleichsschlüssel (::namen::schluessel) -> "M" / "A" / "G"
# Reihenfolge der Priorität: Mitglied vor Anwärter vor Gast.
# =============================================================================
proc ::schuetzenstatus::lade_listen {} {
    set listen [dict create]

    # Bekannte Gäste (niedrigste Priorität, wird ggf. überschrieben)
    if {[llength [info commands ::gaeste::lade_gaeste]]} {
        foreach gast [::gaeste::lade_gaeste] {
            dict set listen [::namen::schluessel \
                [dict get $gast nachname] [dict get $gast vorname]] G
        }
    }

    # Anwärter von der Warteliste
    if {[llength [info commands ::warteliste::lade_namen]]} {
        foreach paar [::warteliste::lade_namen] {
            lassign $paar nn vn
            dict set listen [::namen::schluessel $nn $vn] A
        }
    }

    # Mitglieder (höchste Priorität) - zeilenweise wie im übrigen Programm
    if {[info exists ::mitglieder_json] && [file exists $::mitglieder_json]} {
        set fp [open $::mitglieder_json r]
        fconfigure $fp -encoding utf-8
        set inhalt [read $fp]
        close $fp
        set nachname ""
        foreach zeile [split $inhalt "\n"] {
            # Nachname merken, beim folgenden Vornamen das Paar übernehmen
            if {[regexp {"nachname":\s*"([^"]*)"} $zeile -> nn]} {
                set nachname $nn
            }
            if {[regexp {"vorname":\s*"([^"]*)"} $zeile -> vn] && $nachname ne ""} {
                dict set listen [::namen::schluessel $nachname $vn] M
                set nachname ""
            }
        }
    }

    return $listen
}

# =============================================================================
# Prozedur: ::schuetzenstatus::ermitteln
# Status für einen NEUEN Eintrag: Mitglied -> "M", Anwärter -> "A",
# alle anderen -> "G" (wer weder Mitglied noch Anwärter ist, ist Gast).
# Parameter:
#   nachname, vorname - Name des Schützen
#   listen            - optional: Ergebnis von lade_listen (sonst neu geladen)
# =============================================================================
proc ::schuetzenstatus::ermitteln {nachname vorname {listen ""}} {
    if {$listen eq ""} {
        set listen [lade_listen]
    }
    set schluessel [::namen::schluessel $nachname $vorname]
    if {[dict exists $listen $schluessel]} {
        set status [dict get $listen $schluessel]
        # Bekannte Gäste und Unbekannte sind beide Gäste
        if {$status in {M A}} {
            return $status
        }
    }
    return G
}

# =============================================================================
# Prozedur: ::schuetzenstatus::aus_bemerkung
# Erkennt die früher automatisch eingetragenen Status-Bemerkungen.
# Rückgabe: Liste {status rest}
#   status - "G", "A" oder "" (keine Status-Bemerkung)
#   rest   - Bemerkung ohne den Status-Text (echte Bemerkung)
# =============================================================================
proc ::schuetzenstatus::aus_bemerkung {bemerkung} {
    variable gast_woerter
    variable anwaerter_text

    set text [string trim $bemerkung]

    # Anwärter-Text: nur als vollständige Bemerkung
    if {[string equal -nocase $text $anwaerter_text]} {
        return [list A ""]
    }

    # Gast-Wörter am Anfang; längste zuerst, damit "Gastschütze" vor "Gast" greift
    set woerter [lsort -command {apply {{a b} {
        expr {[string length $b] - [string length $a]}
    }}} $gast_woerter]
    foreach wort $woerter {
        set laenge [string length $wort]
        if {![string equal -nocase -length $laenge $text $wort]} {
            continue
        }
        set rest [string range $text $laenge end]
        # Nur ganzes Wort (sonst wäre z.B. "Gastgeber" ein Treffer)
        if {$rest eq "" || [regexp {^[\s,;:/\-–]} $rest]} {
            regsub {^[\s,;:/\-–]+} $rest "" rest
            return [list G $rest]
        }
    }

    # Keine Status-Bemerkung: unverändert zurückgeben
    return [list "" $bemerkung]
}

# =============================================================================
# Prozedur: ::schuetzenstatus::eintrag_umstellen
# Ergänzt einen alten Eintrag (ohne Feld "status") um den Status und
# entfernt die automatische Status-Bemerkung.
# Vorrang hat die Bemerkung (historisch richtig), sonst die heutigen Listen;
# ist die Person nirgends bekannt, bleibt der Status leer.
# Parameter:
#   eintrag - Eintrags-Dictionary
#   listen  - Ergebnis von lade_listen
# Rückgabe: umgestelltes Eintrags-Dictionary
# =============================================================================
proc ::schuetzenstatus::eintrag_umstellen {eintrag listen} {
    # Bereits umgestellt: nichts tun
    if {[dict exists $eintrag status]} {
        return $eintrag
    }

    set bemerkung ""
    if {[dict exists $eintrag bemerkungen]} {
        set bemerkung [dict get $eintrag bemerkungen]
    }
    lassign [aus_bemerkung $bemerkung] status rest

    # Ohne Status-Bemerkung: heutige Listen befragen
    if {$status eq ""} {
        set schluessel [::namen::schluessel \
            [dict get $eintrag nachname] [dict get $eintrag vorname]]
        if {[dict exists $listen $schluessel]} {
            set status [dict get $listen $schluessel]
        }
    }

    dict set eintrag status $status
    dict set eintrag bemerkungen $rest
    return $eintrag
}

# =============================================================================
# Prozedur: ::schuetzenstatus::migration_pruefen
# Stellt beim Programmstart alle Journal-Dateien um, die noch Einträge ohne
# Feld "status" enthalten. Vor dem Umschreiben wird jede betroffene Datei in
# das Backup-Verzeichnis kopiert. Läuft nur einmal: danach haben alle
# Einträge das Feld und es ist nichts mehr zu tun.
# Rückgabe: Anzahl umgestellter Einträge
# =============================================================================
proc ::schuetzenstatus::migration_pruefen {} {
    set daten_dir [::pfad::get_daten_directory]
    set umgestellt 0
    set listen ""

    # Nur Jahresdateien (z.B. 2026.json)
    foreach datei [lsort [glob -nocomplain -directory $daten_dir {[0-9][0-9][0-9][0-9].json}]] {
        set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]

        # Gibt es Einträge ohne Status?
        set offen 0
        foreach eintrag $eintraege {
            if {![dict exists $eintrag status]} {
                incr offen
            }
        }
        if {$offen == 0} {
            continue
        }

        # Listen nur einmal und nur bei Bedarf laden
        if {$listen eq ""} {
            set listen [lade_listen]
        }

        # Backup der Originaldatei anlegen
        set zeitstempel [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
        set backup [file join [::pfad::get_backups_directory] \
            "[file tail $datei].$zeitstempel.vor_status.backup"]
        file copy -force $datei $backup
        ::pfad::log "Status-Umstellung: Backup $backup"

        # Einträge umstellen und Datei neu schreiben
        set neu [lmap eintrag $eintraege {eintrag_umstellen $eintrag $listen}]
        schreibe_eintraege_json $datei $neu
        ::pfad::log "Status-Umstellung: $offen Einträge in [file tail $datei]"
        incr umgestellt $offen
    }

    return $umgestellt
}
