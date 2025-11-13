# =============================================================================
# fenster_einstellungen.tcl
# =============================================================================
# Verwaltet die Fenstergröße, Position und Vollbildstatus des Hauptfensters
# - Speichert Einstellungen beim Beenden
# - Lädt Einstellungen beim Start
# - Speichert in preferences/fenster.json
# =============================================================================

# =============================================================================
# Funktion: speichere_fenster_einstellungen
# Speichert die aktuellen Fenstereinstellungen in eine JSON-Datei
# - Fenstergröße (Breite x Höhe)
# - Fensterposition (X, Y)
# - Vollbildstatus (true/false)
# =============================================================================
proc speichere_fenster_einstellungen {} {
    # Pfad zur JSON-Datei ermitteln
    set fenster_json [::pfad::get_json_path "preferences" "fenster.json"]

    # Aktuellen Vollbildstatus ermitteln
    # wm attributes . -fullscreen gibt 1 oder 0 zurück
    set is_fullscreen [wm attributes . -fullscreen]

    # Wenn Fenster im Vollbildmodus ist, Vollbildmodus verlassen um die
    # normale Geometrie zu ermitteln (diese soll gespeichert werden)
    if {$is_fullscreen} {
        wm attributes . -fullscreen 0
        # Kurz warten, damit Geometrie aktualisiert wird
        update idletasks
    }

    # Aktuelle Fenstergeometrie ermitteln (Format: WIDTHxHEIGHT+X+Y)
    set geometry [wm geometry .]

    # Vollbildstatus wieder herstellen, falls er aktiv war
    if {$is_fullscreen} {
        wm attributes . -fullscreen 1
    }

    # JSON-Struktur erstellen mit Einstellungen
    set json_content "{\n"
    append json_content "  \"geometry\": \"$geometry\",\n"
    append json_content "  \"fullscreen\": [expr {$is_fullscreen ? "true" : "false"}]\n"
    append json_content "}"

    # JSON-Datei schreiben
    if {[catch {
        set fh [open $fenster_json w]
        fconfigure $fh -encoding utf-8
        puts $fh $json_content
        close $fh
        ::pfad::log "Fenstereinstellungen gespeichert: $geometry (Vollbild: $is_fullscreen)"
    } err]} {
        ::pfad::log "FEHLER beim Speichern der Fenstereinstellungen: $err"
    }
}

# =============================================================================
# Funktion: lade_fenster_einstellungen
# Lädt die gespeicherten Fenstereinstellungen und wendet sie an
# Falls keine Einstellungen vorhanden sind, werden die Standard-Einstellungen
# beibehalten
# =============================================================================
proc lade_fenster_einstellungen {} {
    # Pfad zur JSON-Datei ermitteln
    set fenster_json [::pfad::get_json_path "preferences" "fenster.json"]

    # Prüfen, ob Datei existiert
    if {![file exists $fenster_json]} {
        ::pfad::log "Keine gespeicherten Fenstereinstellungen gefunden, verwende Standardwerte"
        return
    }

    # JSON-Datei lesen
    if {[catch {
        set fh [open $fenster_json r]
        fconfigure $fh -encoding utf-8
        set json_content [read $fh]
        close $fh
    } err]} {
        ::pfad::log "FEHLER beim Lesen der Fenstereinstellungen: $err"
        return
    }

    # JSON parsen - einfaches Regex-basiertes Parsing für diese simple Struktur
    # Geometry-String extrahieren (Format: "geometry": "1600x900+100+50")
    set geometry ""
    if {[regexp {"geometry"\s*:\s*"([^"]+)"} $json_content match geometry]} {
        # Geometry auf das Hauptfenster anwenden
        wm geometry . $geometry
        ::pfad::log "Fenstergeometrie wiederhergestellt: $geometry"
    }

    # Vollbildstatus extrahieren (Format: "fullscreen": true/false)
    set fullscreen 0
    if {[regexp {"fullscreen"\s*:\s*(true|false)} $json_content match fullscreen_str]} {
        if {$fullscreen_str eq "true"} {
            set fullscreen 1
        }
    }

    # GUI-Update durchführen, damit Geometrie wirksam wird
    update idletasks

    # Vollbildstatus anwenden (falls aktiviert)
    if {$fullscreen} {
        wm attributes . -fullscreen 1
        ::pfad::log "Vollbildmodus wiederhergestellt"
    }
}
