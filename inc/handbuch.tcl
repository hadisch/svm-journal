# =============================================================================
# handbuch.tcl - Benutzerhandbuch im Standard-Webbrowser öffnen
# =============================================================================
# Das Handbuch liegt als HTML-Fassung im Programmverzeichnis unter
#   doc/html/SVM-Journal-Handbuch.html
# und wird über Menü Hilfe -> Handbuch mit dem Standard-Webbrowser des
# Betriebssystems geöffnet (Windows, macOS und Linux).
# =============================================================================

namespace eval ::handbuch {
    # Pfad der HTML-Datei relativ zum Programmverzeichnis
    variable relativer_pfad [list doc html SVM-Journal-Handbuch.html]
}

# =============================================================================
# Prozedur: ::handbuch::pfad
# Liefert den vollständigen Pfad zur HTML-Fassung des Handbuchs.
# =============================================================================
proc ::handbuch::pfad {} {
    variable relativer_pfad
    return [file normalize [file join [::pfad::get_script_directory] {*}$relativer_pfad]]
}

# =============================================================================
# Prozedur: ::handbuch::oeffnen
# Öffnet das Handbuch im Standard-Webbrowser. Fehlt die Datei oder lässt sich
# kein Browser starten, erscheint ein Hinweis mit dem Dateipfad.
# =============================================================================
proc ::handbuch::oeffnen {} {
    global tcl_platform
    set datei [pfad]

    # Handbuch nicht vorhanden (z.B. Programmordner unvollständig kopiert)
    if {![file exists $datei]} {
        tk_messageBox -icon warning -type ok -title "Handbuch" \
            -message "Das Handbuch wurde nicht gefunden:\n$datei"
        return
    }

    # Je Betriebssystem das Standardprogramm für HTML-Dateien aufrufen.
    # "&" startet den Browser im Hintergrund, damit SVM-Journal nicht wartet.
    if {[catch {
        if {$tcl_platform(platform) eq "windows"} {
            # Windows: Dateizuordnung über "start" (leerer Titel als 1. Argument)
            exec {*}[auto_execok start] "" [file nativename $datei] &
        } elseif {$tcl_platform(os) eq "Darwin"} {
            # macOS: "open" nutzt den Standardbrowser
            exec open $datei &
        } else {
            # Linux/Unix: xdg-open nutzt die Desktop-Einstellung
            exec xdg-open $datei &
        }
    } fehler]} {
        tk_messageBox -icon warning -type ok -title "Handbuch" \
            -message "Der Webbrowser konnte nicht gestartet werden:\n$fehler\n\nDas Handbuch liegt unter:\n$datei"
    }
}
