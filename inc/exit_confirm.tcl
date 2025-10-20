# exit_confirm.tcl
# Funktion zur Bestätigung des Programmbeendens
# Zeigt einen Dialog mit Ja/Nein-Buttons an

proc confirm_exit {} {
    # Toplevel-Fenster für den Bestätigungsdialog erstellen
    # -parent . : Dialog ist modal zum Hauptfenster
    toplevel .exit_dialog

    # Dialog-Fenstertitel setzen
    wm title .exit_dialog "Programm beenden?"

    # Dialog modal machen (blockiert Hauptfenster)
    wm transient .exit_dialog .
    grab set .exit_dialog

    # Dialogfenster nicht größenveränderbar machen
    wm resizable .exit_dialog 0 0

    # Frame für die Nachricht erstellen
    frame .exit_dialog.msg -padx 20 -pady 20
    pack .exit_dialog.msg -fill both -expand 1

    # Fragetext anzeigen
    label .exit_dialog.msg.text -text "Bist du sicher, dass du das Programm beenden willst?" \
                                -font {Arial 10}
    pack .exit_dialog.msg.text

    # Frame für die Buttons (Ja/Nein) erstellen
    frame .exit_dialog.buttons -pady 10
    pack .exit_dialog.buttons -fill x

    # "Ja"-Button - beendet das Programm
    button .exit_dialog.buttons.yes -text "Ja" -width 10 -command {
        # Dialog schließen
        destroy .exit_dialog
        # Programm beenden
        exit
    }
    pack .exit_dialog.buttons.yes -side left -padx 20

    # "Nein"-Button - schließt nur den Dialog
    button .exit_dialog.buttons.no -text "Nein" -width 10 -command {
        # Dialog schließen, Hauptprogramm läuft weiter
        destroy .exit_dialog
    }
    pack .exit_dialog.buttons.no -side right -padx 20

    # Dialog auf dem Bildschirm zentrieren
    # Erst mal Update durchführen, damit Geometrie bekannt ist
    update idletasks

    # Breite und Höhe des Dialogs ermitteln
    set dialog_width [winfo reqwidth .exit_dialog]
    set dialog_height [winfo reqheight .exit_dialog]

    # Position relativ zum Hauptfenster berechnen
    set main_x [winfo x .]
    set main_y [winfo y .]
    set main_width [winfo width .]
    set main_height [winfo height .]

    # Dialog zentriert über Hauptfenster positionieren
    set x_pos [expr {$main_x + ($main_width - $dialog_width) / 2}]
    set y_pos [expr {$main_y + ($main_height - $dialog_height) / 2}]

    # Position setzen
    wm geometry .exit_dialog +${x_pos}+${y_pos}

    # Focus auf den "Nein"-Button setzen (sicherer Default)
    focus .exit_dialog.buttons.no

    # Warten, bis der Dialog geschlossen wird
    tkwait window .exit_dialog
}
