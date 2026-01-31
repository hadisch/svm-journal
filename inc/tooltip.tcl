# =============================================================================
# tooltip.tcl - Wiederverwendbares Tooltip-System für Tcl/Tk Widgets
# =============================================================================
# Dieses Modul stellt ein einfaches Tooltip-System bereit, das Hilfstexte
# anzeigt, wenn der Mauszeiger über einem Widget verweilt.
# =============================================================================

# Namespace für das Tooltip-System
namespace eval ::tooltip {
    # Variable für das Tooltip-Fenster-Widget
    variable tooltip_window ""

    # Timer-ID für die Verzögerung vor dem Anzeigen
    variable after_id ""

    # Verzögerung in Millisekunden (Standard: 500ms)
    variable delay 500
}

# =============================================================================
# ::tooltip::register - Bindet einen Tooltip an ein Widget
# =============================================================================
# Parameter:
#   widget - Das Widget, an das der Tooltip gebunden werden soll
#   text   - Der anzuzeigende Hilfstext
# =============================================================================
proc ::tooltip::register {widget text} {
    # Event-Binding für Maus-Eintritt: Startet den Timer für die Anzeige
    bind $widget <Enter> [list ::tooltip::schedule $widget $text]

    # Event-Binding für Maus-Austritt: Bricht Timer ab und versteckt Tooltip
    bind $widget <Leave> [list ::tooltip::hide]

    # Event-Binding für Maus-Klick: Versteckt Tooltip sofort bei Interaktion
    bind $widget <Button> [list ::tooltip::hide]
}

# =============================================================================
# ::tooltip::schedule - Plant die Anzeige des Tooltips mit Verzögerung
# =============================================================================
# Parameter:
#   widget - Das Widget, über dem der Tooltip erscheinen soll
#   text   - Der anzuzeigende Hilfstext
# =============================================================================
proc ::tooltip::schedule {widget text} {
    variable after_id
    variable delay

    # Falls ein Timer bereits läuft, zuerst abbrechen
    hide

    # Neuen Timer starten - zeigt Tooltip nach Verzögerung an
    set after_id [after $delay [list ::tooltip::show $widget $text]]
}

# =============================================================================
# ::tooltip::show - Zeigt den Tooltip unterhalb des Widgets an
# =============================================================================
# Parameter:
#   widget - Das Widget, relativ zu dem der Tooltip positioniert wird
#   text   - Der anzuzeigende Hilfstext
# =============================================================================
proc ::tooltip::show {widget text} {
    variable tooltip_window
    variable after_id

    # Timer-ID zurücksetzen, da Tooltip jetzt angezeigt wird
    set after_id ""

    # Prüfen, ob das Widget noch existiert (könnte inzwischen zerstört sein)
    if {![winfo exists $widget]} {
        return
    }

    # Falls bereits ein Tooltip-Fenster existiert, zuerst zerstören
    if {[winfo exists .tooltip]} {
        destroy .tooltip
    }

    # Neues Toplevel-Fenster für den Tooltip erstellen
    set tooltip_window [toplevel .tooltip]

    # Fensterdekorationen entfernen (kein Rahmen, keine Titelleiste)
    wm overrideredirect $tooltip_window 1

    # Tooltip-Fenster immer im Vordergrund halten
    wm attributes $tooltip_window -topmost 1

    # Label mit dem Hilfstext erstellen
    # - Gelber Hintergrund (#FFFFE0) ist Standard für Tooltips
    # - Schwarzer Text für gute Lesbarkeit
    # - Kleiner Innenabstand für angenehmes Erscheinungsbild
    label $tooltip_window.label -text $text \
        -background "#FFFFE0" \
        -foreground "black" \
        -relief solid \
        -borderwidth 1 \
        -padx 5 \
        -pady 2 \
        -font {TkDefaultFont 9}
    pack $tooltip_window.label

    # Position berechnen: unterhalb des Widgets, horizontal zentriert
    # Widget-Position und -Größe ermitteln
    set widget_x [winfo rootx $widget]
    set widget_y [winfo rooty $widget]
    set widget_height [winfo height $widget]
    set widget_width [winfo width $widget]

    # Tooltip-Position: 5 Pixel unterhalb des Widgets
    set tooltip_x $widget_x
    set tooltip_y [expr {$widget_y + $widget_height + 5}]

    # Tooltip an berechneter Position anzeigen
    wm geometry $tooltip_window "+${tooltip_x}+${tooltip_y}"

    # Sicherstellen, dass der Tooltip sichtbar ist
    raise $tooltip_window
}

# =============================================================================
# ::tooltip::hide - Versteckt den aktuellen Tooltip
# =============================================================================
proc ::tooltip::hide {} {
    variable tooltip_window
    variable after_id

    # Falls ein Timer läuft, abbrechen
    if {$after_id ne ""} {
        after cancel $after_id
        set after_id ""
    }

    # Falls ein Tooltip-Fenster existiert, zerstören
    if {[winfo exists .tooltip]} {
        destroy .tooltip
        set tooltip_window ""
    }
}
