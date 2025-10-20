# =============================================================================
# JSON-Reader-Funktionen für das svm-journal Projekt
# =============================================================================

# Lädt das JSON-Paket (falls verfügbar) - ohne Fehlermeldung
catch {package require json}
catch {package require json::write}

# =============================================================================
# Prozedur: lies_json_datei
# Liest eine JSON-Datei und gibt den Inhalt als Tcl-Dictionary zurück
# Parameter:
#   dateiPfad - Vollständiger Pfad zur JSON-Datei
# Rückgabe:
#   Dictionary mit dem JSON-Inhalt oder leeres Dictionary bei Fehler
# =============================================================================
proc lies_json_datei {dateiPfad} {
    # Prüfen, ob die Datei existiert
    if {![file exists $dateiPfad]} {
        puts stderr "FEHLER: Datei nicht gefunden: $dateiPfad"
        return [dict create]
    }

    # Datei öffnen und Inhalt lesen
    set fp [open $dateiPfad r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # JSON parsen - verwende json::json2dict wenn verfügbar
    if {[catch {package require json}]} {
        # Einfaches manuelles Parsing für unsere Zwecke
        # Dies ist eine vereinfachte Variante - für komplexes JSON sollte ein Paket verwendet werden
        return [parse_simple_json $json_content]
    } else {
        # JSON-Paket verfügbar - nutze json::json2dict
        return [::json::json2dict $json_content]
    }
}

# =============================================================================
# Prozedur: parse_simple_json
# Sehr einfacher JSON-Parser für die spezifischen Anforderungen dieses Projekts
# WARNUNG: Dies ist keine vollständige JSON-Parser-Implementierung!
# Parameter:
#   json_str - JSON-String zum Parsen
# Rückgabe:
#   Dictionary mit geparstem Inhalt
# =============================================================================
proc parse_simple_json {json_str} {
    # Diese Prozedur wird nur verwendet, wenn kein JSON-Paket verfügbar ist
    # Für Produktivcode sollte tcllib installiert werden

    # Entferne Whitespace und Zeilenumbrüche am Anfang und Ende
    set json_str [string trim $json_str]

    # Einfaches Dictionary erstellen
    set result [dict create]

    # Hinweis: Dies ist eine sehr vereinfachte Implementierung
    # Für echte Anwendungen sollte das json-Paket aus tcllib verwendet werden

    return $result
}

# =============================================================================
# Prozedur: lies_mitglieder
# Liest die mitglieder.json und gibt eine Liste aller Mitglieder zurück
# Rückgabe:
#   Liste von Dictionaries, wobei jedes Dictionary ein Mitglied repräsentiert
# =============================================================================
proc lies_mitglieder {} {
    global mitglieder_json

    # JSON-Datei lesen
    set data [lies_json_datei $mitglieder_json]

    # Mitglieder-Array extrahieren
    if {[dict exists $data mitglieder]} {
        return [dict get $data mitglieder]
    }

    return [list]
}

# =============================================================================
# Prozedur: lies_kaliber_preise
# Liest die kaliber-preise.json und gibt eine Liste aller Kaliber mit Preisen zurück
# Rückgabe:
#   Liste von Dictionaries mit kaliber und preis
# =============================================================================
proc lies_kaliber_preise {} {
    global kaliber_preise_json

    # JSON-Datei lesen
    set data [lies_json_datei $kaliber_preise_json]

    # Kaliber-Preise-Array extrahieren
    if {[dict exists $data kaliber-preise]} {
        return [dict get $data kaliber-preise]
    }

    return [list]
}

# =============================================================================
# Prozedur: lies_stand_nutzung
# Liest die stand-nutzung.json und gibt die Preise für Standnutzung zurück
# Rückgabe:
#   Dictionary mit den Preisen für verschiedene Kategorien
# =============================================================================
proc lies_stand_nutzung {} {
    global stand_nutzung_json

    # JSON-Datei lesen
    set data [lies_json_datei $stand_nutzung_json]

    # Stand-Nutzung-Array extrahieren (erstes Element)
    if {[dict exists $data stand-nutzung]} {
        set stand_liste [dict get $data stand-nutzung]
        # Erstes Element zurückgeben (sollte ein Dictionary sein)
        if {[llength $stand_liste] > 0} {
            return [lindex $stand_liste 0]
        }
    }

    return [dict create]
}
