# =============================================================================
# Über-Dialog
# Zeigt Informationen über das Programm, Autoren und Lizenz
# =============================================================================

# =============================================================================
# Prozedur: open_ueber_dialog
# Öffnet das "Über..."-Fenster mit Logo, Autoren und Lizenzinformationen
# =============================================================================
proc open_ueber_dialog {} {
    global script_dir

    # Toplevel-Fenster erstellen
    set w .ueber

    # Falls Fenster bereits existiert, in den Vordergrund bringen
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    toplevel $w
    wm title $w "\u00dcber SVM Journal"
    wm geometry $w "500x650"
    wm resizable $w 0 0

    # Hauptframe
    frame $w.main -padx 20 -pady 15 -bg white
    pack $w.main -fill both -expand 1

    # ==========================================================================
    # Logo-Anzeige (oben, mittig)
    # ==========================================================================

    # Pfad zum Logo vom Pfad-Management abrufen
    set logo_pfad [::pfad::get_resources_path "Logo.gif"]

    # Frame für Logo-Bereich
    frame $w.main.logo_frame -bg white
    pack $w.main.logo_frame -pady 10

    # Versuchen, das Logo zu laden
    if {[file exists $logo_pfad]} {
        # GIF-Bild laden und anzeigen
        if {[catch {
            image create photo logo_image -file $logo_pfad
            label $w.main.logo_frame.img -image logo_image -bg white
            pack $w.main.logo_frame.img
        } err]} {
            # Falls Laden fehlschlägt, Platzhalter anzeigen
            label $w.main.logo_frame.text -text "SVM" -font {Arial 36 bold} \
                -bg white -fg "#4ACEFA"
            pack $w.main.logo_frame.text
        }
    } else {
        # Falls Datei nicht existiert, Platzhalter anzeigen
        label $w.main.logo_frame.text -text "SVM" -font {Arial 36 bold} \
            -bg white -fg "#4ACEFA"
        pack $w.main.logo_frame.text
    }

    # ==========================================================================
    # Programmname
    # ==========================================================================
    label $w.main.appname -text "SVM Journal" -font {Arial 20 bold} -bg white
    pack $w.main.appname -pady 5

    # Version
    label $w.main.version -text "Version 1.2.5" -font {Arial 10} -fg "#666666" -bg white
    pack $w.main.version -pady 3

    # Separator
    frame $w.main.sep1 -height 2 -bg "#E0E0E0"
    pack $w.main.sep1 -fill x -pady 10

    # ==========================================================================
    # Autoren
    # ==========================================================================
    label $w.main.autoren_label -text "Autoren:" -font {Arial 11 bold} -bg white
    pack $w.main.autoren_label -pady 3

    label $w.main.autor1 -text "Hans-Dieter Schlabritz" -font {Arial 10} -bg white
    pack $w.main.autor1 -pady 1

    label $w.main.autor1_email -text "<hadisch@zavb.de>" -font {Arial 9} -fg "#4ACEFA" -bg white
    pack $w.main.autor1_email -pady 0

    label $w.main.autor2 -text "Claude (Anthropic)" -font {Arial 10} -bg white
    pack $w.main.autor2 -pady 3

    # Separator
    frame $w.main.sep2 -height 2 -bg "#E0E0E0"
    pack $w.main.sep2 -fill x -pady 10

    # ==========================================================================
    # Copyright
    # ==========================================================================
    set jahr [clock format [clock seconds] -format "%Y"]
    label $w.main.copyright -text "Copyright © $jahr Hans-Dieter Schlabritz" -font {Arial 10} -bg white
    pack $w.main.copyright -pady 3

    # Separator vor Lizenz
    frame $w.main.sep3 -height 2 -bg "#E0E0E0"
    pack $w.main.sep3 -fill x -pady 10

    # ==========================================================================
    # Lizenz
    # ==========================================================================
    label $w.main.lizenz_label -text "Lizenz:" -font {Arial 11 bold} -bg white
    pack $w.main.lizenz_label -pady 5

    label $w.main.lizenz_text -text "GNU GENERAL PUBLIC LICENSE" -font {Arial 10 bold} -bg white
    pack $w.main.lizenz_text -pady 2

    label $w.main.lizenz_version -text "Version 2, June 1991" -font {Arial 9} -fg "#666666" -bg white
    pack $w.main.lizenz_version -pady 5

    # ==========================================================================
    # Schließen-Button
    # ==========================================================================
    button $w.main.close -text "Schlie\u00dfen" -bg "#4ACEFA" -width 15 \
        -command "destroy $w"
    pack $w.main.close -pady 15

    # Focus auf Fenster
    focus $w
}
