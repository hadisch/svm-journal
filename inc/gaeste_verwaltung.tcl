# =============================================================================
# Gäste-Verwaltung für das svm-journal Projekt
# Liest und schreibt die gaeste.json - Datenbank bekannter Gastschützen
#
# Hintergrund: Beim ersten Besuch eines Gastschützen müssen Personalien
# aufgenommen und der Ausweis kopiert werden. Bei Folgebesuchen ist das
# nicht mehr erforderlich, da die Unterlagen bereits vorliegen.
# Diese Datei verwaltet eine Aufzeichnung aller Gastschützen, die bereits
# einmal beim Verein waren, um doppelte Datenerhebung zu vermeiden.
# =============================================================================

namespace eval ::gaeste {
    # Namespace ohne Zustandsvariablen - alle Operationen lesen/schreiben direkt die Datei
}

# =============================================================================
# Prozedur: ::gaeste::lade_gaeste
# Lädt die gaeste.json und gibt eine Liste aller bekannten Gäste zurück.
# Gibt eine leere Liste zurück wenn die Datei noch nicht existiert.
# Rückgabe: Tcl-Liste von Dictionaries mit den Schlüsseln "nachname" und "vorname"
# =============================================================================
proc ::gaeste::lade_gaeste {} {
    global gaeste_json

    # Leere Liste als Standardrückgabe wenn Datei noch nicht vorhanden
    set gaeste_liste [list]

    # Datei existiert noch nicht (z.B. beim ersten Start) → leere Liste zurückgeben
    if {![file exists $gaeste_json]} {
        return $gaeste_liste
    }

    # Datei einlesen (UTF-8 für korrekte Umlaute)
    set fp [open $gaeste_json r]
    fconfigure $fp -encoding utf-8
    set inhalt [read $fp]
    close $fp

    # Zeilenweises Parsing: Suche nach "nachname"/"vorname"-Paaren
    # (analog zum Parsing in neuer_eintrag.tcl und blacklist_dialog.tcl)
    set zeilen [split $inhalt "\n"]
    set aktueller_nachname ""

    foreach zeile $zeilen {
        # Nachname extrahieren
        if {[regexp {"nachname":\s*"([^"]*)"} $zeile -> nn]} {
            set aktueller_nachname [string trim $nn]
        }
        # Vorname extrahieren - zusammen mit gespeichertem Nachnamen als Paar ablegen
        if {[regexp {"vorname":\s*"([^"]*)"} $zeile -> vn]} {
            set vn [string trim $vn]
            if {$aktueller_nachname ne ""} {
                lappend gaeste_liste [dict create nachname $aktueller_nachname vorname $vn]
                # Nachnamen zurücksetzen für nächsten Eintrag
                set aktueller_nachname ""
            }
        }
    }

    return $gaeste_liste
}

# =============================================================================
# Prozedur: ::gaeste::ist_gast
# Prüft ob eine Person bereits in der Gästeliste eingetragen ist.
# Vergleich ist case-insensitiv, damit Schreibvarianten keine Rolle spielen.
# Parameter:
#   vorname  - Vorname der Person
#   nachname - Nachname der Person
# Rückgabe: 1 wenn bekannter Gast, 0 wenn nicht
# =============================================================================
proc ::gaeste::ist_gast {vorname nachname} {
    # Alle bekannten Gäste laden
    set gaeste [lade_gaeste]

    foreach gast $gaeste {
        # Case-insensitiver Vergleich für robuste Erkennung (z.B. "müller" = "Müller")
        if {[string equal -nocase [dict get $gast nachname] $nachname] &&
            [string equal -nocase [dict get $gast vorname]  $vorname]} {
            return 1
        }
    }

    # Person nicht in der Liste gefunden
    return 0
}

# =============================================================================
# Prozedur: ::gaeste::trage_gast_ein
# Fügt eine Person als bekannten Gast in die gaeste.json ein.
# Wird nach dem Bestätigen des Warnhinweises aufgerufen, damit beim nächsten
# Besuch der Info-Dialog erscheint statt erneut zur Datenerhebung aufzufordern.
# Parameter:
#   vorname  - Vorname des neuen Gastes
#   nachname - Nachname des neuen Gastes
# =============================================================================
proc ::gaeste::trage_gast_ein {vorname nachname} {
    global gaeste_json

    # Bestehende Gäste laden (damit vorhandene Einträge nicht überschrieben werden)
    set gaeste [lade_gaeste]

    # Neuen Gast zur Liste hinzufügen
    lappend gaeste [dict create nachname $nachname vorname $vorname]

    # JSON-Datei mit aktualisierter Liste neu schreiben
    set zeilen [list]
    lappend zeilen "\{"
    lappend zeilen "  \"gaeste\": \["

    set anzahl [llength $gaeste]
    set counter 0

    foreach gast $gaeste {
        incr counter
        set nn [dict get $gast nachname]
        set vn [dict get $gast vorname]

        # Komma nach jedem Eintrag außer dem letzten (valides JSON)
        if {$counter < $anzahl} {
            lappend zeilen "    \{\"nachname\": \"$nn\", \"vorname\": \"$vn\"\},"
        } else {
            lappend zeilen "    \{\"nachname\": \"$nn\", \"vorname\": \"$vn\"\}"
        }
    }

    lappend zeilen "  \],"
    lappend zeilen "  \"anzahl\": $anzahl"
    lappend zeilen "\}"

    # Zieldirectory sicherstellen (wird normalerweise von pfad_management angelegt,
    # aber sicherheitshalber nochmals prüfen)
    set verzeichnis [file dirname $gaeste_json]
    if {![file exists $verzeichnis]} {
        file mkdir $verzeichnis
    }

    # Datei UTF-8-kodiert schreiben
    set fp [open $gaeste_json w]
    fconfigure $fp -encoding utf-8
    puts $fp [join $zeilen "\n"]
    close $fp
}
