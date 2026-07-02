# =============================================================================
# gaeste_fenster.tcl - Manuelle Verwaltung der Gästeliste
# =============================================================================
# Dieses Modul stellt ein Fenster zur Verwaltung bekannter Gastschützen bereit.
# Die Gästeliste wird in gaeste.json gespeichert und enthält pro Eintrag
# nur Nachname und Vorname. Sie wird automatisch befüllt, wenn im "Neuer
# Eintrag"-Dialog ein unbekannter Gast erfasst wird. Dieses Fenster erlaubt
# zusätzlich die manuelle Pflege: Hinzufügen, Bearbeiten und Löschen.
# =============================================================================

# Namespace für die Gästefenster-Verwaltung
namespace eval ::gaeste_fenster {
    # Interne Liste: jeder Eintrag ist eine Liste {nachname vorname}
    variable gaeste_liste [list]

    # Index des aktuell markierten Eintrags im Treeview (-1 = nichts markiert)
    variable ausgewaehlter_index -1
}

# =============================================================================
# ::gaeste_fenster::lade_gaeste_fuer_fenster
# Lädt gaeste.json über ::gaeste::lade_gaeste und konvertiert die
# Dictionary-Liste in das interne {nachname vorname}-Listenformat.
# =============================================================================
proc ::gaeste_fenster::lade_gaeste_fuer_fenster {} {
    variable gaeste_liste

    # Liste zurücksetzen
    set gaeste_liste [list]

    # Bestehende ::gaeste::lade_gaeste-Prozedur aus gaeste_verwaltung.tcl nutzen
    set dicts [::gaeste::lade_gaeste]

    # Dictionary-Format in einfache {nachname vorname}-Paare umwandeln
    foreach gast $dicts {
        set nachname [dict get $gast nachname]
        set vorname  [dict get $gast vorname]
        lappend gaeste_liste [list $nachname $vorname]
    }

    # Alphabetisch sortieren: zuerst nach Nachname, dann nach Vorname
    set gaeste_liste [lsort -index 0 [lsort -index 1 $gaeste_liste]]
}

# =============================================================================
# ::gaeste_fenster::speichere_gaeste_fenster
# Schreibt gaeste_liste vollständig als JSON in gaeste.json.
# Überschreibt die Datei komplett (wie ::gaeste::trage_gast_ein).
# =============================================================================
proc ::gaeste_fenster::speichere_gaeste_fenster {} {
    variable gaeste_liste

    # Zieldateipfad aus dem zentralen Pfad-Management
    set pfad $::gaeste_json

    # JSON manuell aufbauen (gleiche Struktur wie gaeste_verwaltung.tcl)
    set zeilen [list]
    lappend zeilen "\{"
    lappend zeilen "  \"gaeste\": \["

    set anzahl [llength $gaeste_liste]
    set idx 0

    foreach eintrag $gaeste_liste {
        set nn [lindex $eintrag 0]
        set vn [lindex $eintrag 1]

        # Sonderzeichen für JSON escapen
        set nn [string map {\\ \\\\ \" \\\"} $nn]
        set vn [string map {\\ \\\\ \" \\\"} $vn]

        incr idx
        # Letzter Eintrag ohne abschließendes Komma (valides JSON)
        if {$idx < $anzahl} {
            lappend zeilen "    \{\"nachname\": \"$nn\", \"vorname\": \"$vn\"\},"
        } else {
            lappend zeilen "    \{\"nachname\": \"$nn\", \"vorname\": \"$vn\"\}"
        }
    }

    lappend zeilen "  \],"
    lappend zeilen "  \"anzahl\": $anzahl"
    lappend zeilen "\}"

    # Verzeichnis anlegen falls noch nicht vorhanden
    set verzeichnis [file dirname $pfad]
    if {![file exists $verzeichnis]} {
        file mkdir $verzeichnis
    }

    # UTF-8-kodiert schreiben
    if {[catch {
        set fp [open $pfad w]
        fconfigure $fp -encoding utf-8
        puts $fp [join $zeilen "\n"]
        close $fp
    } err]} {
        tk_messageBox -icon error -type ok \
            -title "Fehler" \
            -parent .gaestefenster \
            -message "Gästeliste konnte nicht gespeichert werden:\n$err"
    }
}

# =============================================================================
# ::gaeste_fenster::aktualisiere_anzeige
# Leert den Treeview und befüllt ihn neu aus gaeste_liste.
# =============================================================================
proc ::gaeste_fenster::aktualisiere_anzeige {} {
    variable gaeste_liste

    # Sicherheitscheck: Treeview muss existieren
    if {![winfo exists .gaestefenster.main.tree]} {
        return
    }

    # Alle vorhandenen Einträge entfernen
    .gaestefenster.main.tree delete [.gaestefenster.main.tree children {}]

    # Neu befüllen aus der internen Liste
    foreach eintrag $gaeste_liste {
        set nachname [lindex $eintrag 0]
        set vorname  [lindex $eintrag 1]
        .gaestefenster.main.tree insert {} end -values [list $nachname $vorname]
    }

    # Eintragsanzahl in der Statuszeile aktualisieren
    set anzahl [llength $gaeste_liste]
    if {[winfo exists .gaestefenster.status.info]} {
        if {$anzahl == 1} {
            .gaestefenster.status.info configure -text "1 Gastschütze eingetragen."
        } else {
            .gaestefenster.status.info configure -text "$anzahl Gastschützen eingetragen."
        }
    }
}

# =============================================================================
# ::gaeste_fenster::pruefe_hinzufuegen_button
# Trace-Callback: Aktiviert/Deaktiviert den Speichern-Button im Hinzufügen-
# Dialog je nachdem ob beide Pflichtfelder ausgefüllt sind.
# =============================================================================
proc ::gaeste_fenster::pruefe_hinzufuegen_button {args} {
    # Sicherheitscheck: Dialog muss noch existieren
    if {![winfo exists .gaestefenster.hinzufuegen.main.buttons.save]} {
        return
    }

    # Beide Felder müssen mindestens ein Zeichen enthalten
    if {[string trim $::gaeste_fenster::neu_nachname] ne "" &&
        [string trim $::gaeste_fenster::neu_vorname] ne ""} {
        .gaestefenster.hinzufuegen.main.buttons.save configure -state normal
    } else {
        .gaestefenster.hinzufuegen.main.buttons.save configure -state disabled
    }
}

# =============================================================================
# ::gaeste_fenster::speichere_neuen_gast
# Fügt einen neuen Gast zur Liste hinzu, sortiert, speichert und schließt Dialog.
# =============================================================================
proc ::gaeste_fenster::speichere_neuen_gast {} {
    variable gaeste_liste

    # Eingaben trimmen
    set nachname [string trim $::gaeste_fenster::neu_nachname]
    set vorname  [string trim $::gaeste_fenster::neu_vorname]

    # Duplikatprüfung (case-insensitiv)
    foreach eintrag $gaeste_liste {
        if {[string equal -nocase [lindex $eintrag 0] $nachname] &&
            [string equal -nocase [lindex $eintrag 1] $vorname]} {
            tk_messageBox -icon info -type ok \
                -title "Bereits vorhanden" \
                -parent .gaestefenster.hinzufuegen \
                -message "$vorname $nachname ist bereits in der Gästeliste eingetragen."
            return
        }
    }

    # Neuen Eintrag hinzufügen und alphabetisch sortieren
    lappend gaeste_liste [list $nachname $vorname]
    set gaeste_liste [lsort -index 0 [lsort -index 1 $gaeste_liste]]

    # Persistieren und Anzeige aktualisieren
    speichere_gaeste_fenster
    aktualisiere_anzeige

    # Dialog schließen
    destroy .gaestefenster.hinzufuegen
}

# =============================================================================
# ::gaeste_fenster::oeffne_hinzufuegen_dialog
# Öffnet einen Sub-Dialog zum manuellen Hinzufügen eines neuen Gastes.
# =============================================================================
proc ::gaeste_fenster::oeffne_hinzufuegen_dialog {} {
    # Verhindert mehrfaches Öffnen
    if {[winfo exists .gaestefenster.hinzufuegen]} {
        raise .gaestefenster.hinzufuegen
        focus .gaestefenster.hinzufuegen
        return
    }

    # Sub-Dialog-Fenster erstellen
    toplevel .gaestefenster.hinzufuegen
    wm title .gaestefenster.hinzufuegen "Gast hinzufügen"
    wm geometry .gaestefenster.hinzufuegen 420x185
    wm transient .gaestefenster.hinzufuegen .gaestefenster
    wm resizable .gaestefenster.hinzufuegen 0 0

    # Dialog auf dem Elternfenster zentrieren
    update idletasks
    set px [winfo x .gaestefenster]
    set py [winfo y .gaestefenster]
    set pw [winfo width .gaestefenster]
    set ph [winfo height .gaestefenster]
    set dw 420
    set dh 185
    set dx [expr {$px + ($pw - $dw) / 2}]
    set dy [expr {$py + ($ph - $dh) / 2}]
    wm geometry .gaestefenster.hinzufuegen +${dx}+${dy}

    # Hauptrahmen
    frame .gaestefenster.hinzufuegen.main -padx 15 -pady 10
    pack .gaestefenster.hinzufuegen.main -fill both -expand 1

    # Nachname-Eingabefeld
    frame .gaestefenster.hinzufuegen.main.nn_frame
    pack .gaestefenster.hinzufuegen.main.nn_frame -fill x -pady 5

    label .gaestefenster.hinzufuegen.main.nn_frame.label \
        -text "Nachname *:" -width 14 -anchor w
    pack .gaestefenster.hinzufuegen.main.nn_frame.label -side left

    entry .gaestefenster.hinzufuegen.main.nn_frame.entry \
        -textvariable ::gaeste_fenster::neu_nachname -width 30
    pack .gaestefenster.hinzufuegen.main.nn_frame.entry -side left -fill x -expand 1

    # Vorname-Eingabefeld
    frame .gaestefenster.hinzufuegen.main.vn_frame
    pack .gaestefenster.hinzufuegen.main.vn_frame -fill x -pady 5

    label .gaestefenster.hinzufuegen.main.vn_frame.label \
        -text "Vorname *:" -width 14 -anchor w
    pack .gaestefenster.hinzufuegen.main.vn_frame.label -side left

    entry .gaestefenster.hinzufuegen.main.vn_frame.entry \
        -textvariable ::gaeste_fenster::neu_vorname -width 30
    pack .gaestefenster.hinzufuegen.main.vn_frame.entry -side left -fill x -expand 1

    # Pflichtfeld-Hinweis
    label .gaestefenster.hinzufuegen.main.hinweis \
        -text "* Pflichtfelder" -fg gray -anchor w
    pack .gaestefenster.hinzufuegen.main.hinweis -fill x

    # Button-Leiste
    frame .gaestefenster.hinzufuegen.main.buttons
    pack .gaestefenster.hinzufuegen.main.buttons -fill x -pady 8

    # Speichern-Button (initial deaktiviert bis beide Felder gefüllt)
    button .gaestefenster.hinzufuegen.main.buttons.save \
        -text "Hinzufügen" -bg #569A40 -fg white -activebackground #4a8735 \
        -state disabled \
        -command ::gaeste_fenster::speichere_neuen_gast
    pack .gaestefenster.hinzufuegen.main.buttons.save -side left -padx 5

    # Abbrechen-Button
    button .gaestefenster.hinzufuegen.main.buttons.cancel \
        -text "Abbrechen" -bg #E0E0E0 -activebackground #C8C8C8 \
        -command {destroy .gaestefenster.hinzufuegen}
    pack .gaestefenster.hinzufuegen.main.buttons.cancel -side left -padx 5

    # Variablen initialisieren
    set ::gaeste_fenster::neu_nachname ""
    set ::gaeste_fenster::neu_vorname  ""

    # Traces für Button-Aktivierung
    trace add variable ::gaeste_fenster::neu_nachname write ::gaeste_fenster::pruefe_hinzufuegen_button
    trace add variable ::gaeste_fenster::neu_vorname  write ::gaeste_fenster::pruefe_hinzufuegen_button

    # Traces beim Schließen aufräumen
    bind .gaestefenster.hinzufuegen <Destroy> {
        catch {trace remove variable ::gaeste_fenster::neu_nachname write ::gaeste_fenster::pruefe_hinzufuegen_button}
        catch {trace remove variable ::gaeste_fenster::neu_vorname  write ::gaeste_fenster::pruefe_hinzufuegen_button}
    }

    # ESC schließt den Dialog
    bind .gaestefenster.hinzufuegen <Escape> {destroy .gaestefenster.hinzufuegen}

    # Enter im Vorname-Feld speichert (wenn Button aktiv)
    bind .gaestefenster.hinzufuegen.main.vn_frame.entry <Return> {
        if {[.gaestefenster.hinzufuegen.main.buttons.save cget -state] eq "normal"} {
            ::gaeste_fenster::speichere_neuen_gast
        }
    }

    # Fokus auf Nachname-Feld
    focus .gaestefenster.hinzufuegen.main.nn_frame.entry
}

# =============================================================================
# ::gaeste_fenster::pruefe_bearbeiten_button
# Trace-Callback: Aktiviert/Deaktiviert den Speichern-Button im Bearbeiten-Dialog.
# =============================================================================
proc ::gaeste_fenster::pruefe_bearbeiten_button {args} {
    # Sicherheitscheck: Dialog muss noch existieren
    if {![winfo exists .gaestefenster.bearbeiten.main.buttons.save]} {
        return
    }

    # Beide Felder müssen ausgefüllt sein
    if {[string trim $::gaeste_fenster::edit_nachname] ne "" &&
        [string trim $::gaeste_fenster::edit_vorname] ne ""} {
        .gaestefenster.bearbeiten.main.buttons.save configure -state normal
    } else {
        .gaestefenster.bearbeiten.main.buttons.save configure -state disabled
    }
}

# =============================================================================
# ::gaeste_fenster::speichere_geaenderten_gast
# Ersetzt den Eintrag an ausgewaehlter_index durch die neuen Werte und speichert.
# =============================================================================
proc ::gaeste_fenster::speichere_geaenderten_gast {} {
    variable gaeste_liste
    variable ausgewaehlter_index

    # Neue Werte aus den Eingabefeldern lesen
    set neuer_nachname [string trim $::gaeste_fenster::edit_nachname]
    set neuer_vorname  [string trim $::gaeste_fenster::edit_vorname]

    # Duplikatprüfung: Anderen Eintrag mit gleichem Namen verhindern
    # (eigener Eintrag beim gleichen Index ist erlaubt)
    set idx 0
    foreach eintrag $gaeste_liste {
        if {$idx != $ausgewaehlter_index} {
            if {[string equal -nocase [lindex $eintrag 0] $neuer_nachname] &&
                [string equal -nocase [lindex $eintrag 1] $neuer_vorname]} {
                tk_messageBox -icon info -type ok \
                    -title "Bereits vorhanden" \
                    -parent .gaestefenster.bearbeiten \
                    -message "$neuer_vorname $neuer_nachname ist bereits in der Gästeliste eingetragen."
                return
            }
        }
        incr idx
    }

    # Eintrag an der gespeicherten Position ersetzen
    set gaeste_liste [lreplace $gaeste_liste $ausgewaehlter_index $ausgewaehlter_index \
        [list $neuer_nachname $neuer_vorname]]

    # Erneut sortieren nach der Änderung
    set gaeste_liste [lsort -index 0 [lsort -index 1 $gaeste_liste]]

    # Auswahl zurücksetzen, da Position sich durch Sortierung verändert haben kann
    set ausgewaehlter_index -1

    # Persistieren und Anzeige aktualisieren
    speichere_gaeste_fenster
    aktualisiere_anzeige

    # Dialog schließen
    destroy .gaestefenster.bearbeiten
}

# =============================================================================
# ::gaeste_fenster::oeffne_bearbeiten_dialog
# Öffnet einen Sub-Dialog zum Bearbeiten des aktuell markierten Gastes.
# Die Felder werden mit den vorhandenen Werten vorausgefüllt.
# =============================================================================
proc ::gaeste_fenster::oeffne_bearbeiten_dialog {} {
    variable gaeste_liste
    variable ausgewaehlter_index

    # Prüfen ob ein Eintrag ausgewählt ist
    if {$ausgewaehlter_index < 0} {
        tk_messageBox -icon info -type ok \
            -title "Kein Eintrag ausgewählt" \
            -parent .gaestefenster \
            -message "Bitte wählen Sie zuerst einen Eintrag aus der Liste aus."
        return
    }

    # Verhindert mehrfaches Öffnen
    if {[winfo exists .gaestefenster.bearbeiten]} {
        raise .gaestefenster.bearbeiten
        focus .gaestefenster.bearbeiten
        return
    }

    # Vorhandene Werte des ausgewählten Eintrags lesen
    set eintrag [lindex $gaeste_liste $ausgewaehlter_index]
    set alter_nachname [lindex $eintrag 0]
    set alter_vorname  [lindex $eintrag 1]

    # Sub-Dialog-Fenster erstellen
    toplevel .gaestefenster.bearbeiten
    wm title .gaestefenster.bearbeiten "Gast bearbeiten"
    wm geometry .gaestefenster.bearbeiten 420x185
    wm transient .gaestefenster.bearbeiten .gaestefenster
    wm resizable .gaestefenster.bearbeiten 0 0

    # Dialog auf dem Elternfenster zentrieren
    update idletasks
    set px [winfo x .gaestefenster]
    set py [winfo y .gaestefenster]
    set pw [winfo width .gaestefenster]
    set ph [winfo height .gaestefenster]
    set dw 420
    set dh 185
    set dx [expr {$px + ($pw - $dw) / 2}]
    set dy [expr {$py + ($ph - $dh) / 2}]
    wm geometry .gaestefenster.bearbeiten +${dx}+${dy}

    # Hauptrahmen
    frame .gaestefenster.bearbeiten.main -padx 15 -pady 10
    pack .gaestefenster.bearbeiten.main -fill both -expand 1

    # Nachname-Eingabefeld
    frame .gaestefenster.bearbeiten.main.nn_frame
    pack .gaestefenster.bearbeiten.main.nn_frame -fill x -pady 5

    label .gaestefenster.bearbeiten.main.nn_frame.label \
        -text "Nachname *:" -width 14 -anchor w
    pack .gaestefenster.bearbeiten.main.nn_frame.label -side left

    entry .gaestefenster.bearbeiten.main.nn_frame.entry \
        -textvariable ::gaeste_fenster::edit_nachname -width 30
    pack .gaestefenster.bearbeiten.main.nn_frame.entry -side left -fill x -expand 1

    # Vorname-Eingabefeld
    frame .gaestefenster.bearbeiten.main.vn_frame
    pack .gaestefenster.bearbeiten.main.vn_frame -fill x -pady 5

    label .gaestefenster.bearbeiten.main.vn_frame.label \
        -text "Vorname *:" -width 14 -anchor w
    pack .gaestefenster.bearbeiten.main.vn_frame.label -side left

    entry .gaestefenster.bearbeiten.main.vn_frame.entry \
        -textvariable ::gaeste_fenster::edit_vorname -width 30
    pack .gaestefenster.bearbeiten.main.vn_frame.entry -side left -fill x -expand 1

    # Pflichtfeld-Hinweis
    label .gaestefenster.bearbeiten.main.hinweis \
        -text "* Pflichtfelder" -fg gray -anchor w
    pack .gaestefenster.bearbeiten.main.hinweis -fill x

    # Button-Leiste
    frame .gaestefenster.bearbeiten.main.buttons
    pack .gaestefenster.bearbeiten.main.buttons -fill x -pady 8

    # Speichern-Button (initial aktiv, da Felder vorausgefüllt)
    button .gaestefenster.bearbeiten.main.buttons.save \
        -text "Speichern" -bg #569A40 -fg white -activebackground #4a8735 \
        -command ::gaeste_fenster::speichere_geaenderten_gast
    pack .gaestefenster.bearbeiten.main.buttons.save -side left -padx 5

    # Abbrechen-Button
    button .gaestefenster.bearbeiten.main.buttons.cancel \
        -text "Abbrechen" -bg #E0E0E0 -activebackground #C8C8C8 \
        -command {destroy .gaestefenster.bearbeiten}
    pack .gaestefenster.bearbeiten.main.buttons.cancel -side left -padx 5

    # Variablen mit vorhandenen Werten vorausfüllen
    set ::gaeste_fenster::edit_nachname $alter_nachname
    set ::gaeste_fenster::edit_vorname  $alter_vorname

    # Traces für Button-Aktivierung (Pflichtfeld-Validierung)
    trace add variable ::gaeste_fenster::edit_nachname write ::gaeste_fenster::pruefe_bearbeiten_button
    trace add variable ::gaeste_fenster::edit_vorname  write ::gaeste_fenster::pruefe_bearbeiten_button

    # Traces beim Schließen aufräumen
    bind .gaestefenster.bearbeiten <Destroy> {
        catch {trace remove variable ::gaeste_fenster::edit_nachname write ::gaeste_fenster::pruefe_bearbeiten_button}
        catch {trace remove variable ::gaeste_fenster::edit_vorname  write ::gaeste_fenster::pruefe_bearbeiten_button}
    }

    # ESC schließt den Dialog
    bind .gaestefenster.bearbeiten <Escape> {destroy .gaestefenster.bearbeiten}

    # Enter im Vorname-Feld speichert (wenn Button aktiv)
    bind .gaestefenster.bearbeiten.main.vn_frame.entry <Return> {
        if {[.gaestefenster.bearbeiten.main.buttons.save cget -state] eq "normal"} {
            ::gaeste_fenster::speichere_geaenderten_gast
        }
    }

    # Fokus auf Nachname-Feld, Cursor ans Ende setzen
    focus .gaestefenster.bearbeiten.main.nn_frame.entry
    .gaestefenster.bearbeiten.main.nn_frame.entry icursor end
}

# =============================================================================
# ::gaeste_fenster::loesche_gast
# Löscht den markierten Eintrag nach Bestätigung.
# =============================================================================
proc ::gaeste_fenster::loesche_gast {} {
    variable gaeste_liste
    variable ausgewaehlter_index

    # Prüfen ob ein Eintrag ausgewählt ist
    if {$ausgewaehlter_index < 0} {
        tk_messageBox -icon info -type ok \
            -title "Kein Eintrag ausgewählt" \
            -parent .gaestefenster \
            -message "Bitte wählen Sie zuerst einen Eintrag aus der Liste aus."
        return
    }

    # Daten des zu löschenden Eintrags ermitteln
    set eintrag [lindex $gaeste_liste $ausgewaehlter_index]
    set nachname [lindex $eintrag 0]
    set vorname  [lindex $eintrag 1]

    # Bestätigung einholen
    set antwort [tk_messageBox -icon question -type yesno \
        -title "Eintrag löschen" \
        -parent .gaestefenster \
        -message "$vorname $nachname aus der Gästeliste entfernen?\n\nBei einem erneuten Besuch werden dann wieder Personalien aufgenommen."]

    if {$antwort ne "yes"} {
        return
    }

    # Eintrag entfernen
    set gaeste_liste [lreplace $gaeste_liste $ausgewaehlter_index $ausgewaehlter_index]

    # Auswahl zurücksetzen
    set ausgewaehlter_index -1

    # Persistieren und Anzeige aktualisieren
    speichere_gaeste_fenster
    aktualisiere_anzeige
}

# =============================================================================
# open_gaeste_fenster
# Öffnet das Gästefenster. Globale Prozedur, wird aus dem Menü aufgerufen.
# Singleton-Muster: Bringt vorhandenes Fenster in den Vordergrund statt
# ein zweites zu öffnen.
# =============================================================================
proc open_gaeste_fenster {} {
    # Verhindert mehrfaches Öffnen
    if {[winfo exists .gaestefenster]} {
        raise .gaestefenster
        focus .gaestefenster
        return
    }

    # Auswahl zurücksetzen
    set ::gaeste_fenster::ausgewaehlter_index -1

    # Hauptfenster erstellen
    toplevel .gaestefenster
    wm title .gaestefenster "Gästeliste"
    wm geometry .gaestefenster 700x500
    wm minsize .gaestefenster 600 400

    # Fenster auf dem Hauptfenster zentrieren
    update idletasks
    set px [winfo x .]
    set py [winfo y .]
    set pw [winfo width .]
    set ph [winfo height .]
    set dw 700
    set dh 500
    set dx [expr {$px + ($pw - $dw) / 2}]
    set dy [expr {$py + ($ph - $dh) / 2}]
    if {$dy < 0} { set dy 0 }
    wm geometry .gaestefenster +${dx}+${dy}

    # =========================================================================
    # Toolbar mit Buttons für CRUD-Operationen
    # =========================================================================
    frame .gaestefenster.toolbar -bg #E0E0E0 -relief raised -bd 1
    pack .gaestefenster.toolbar -fill x

    # Button "Hinzufügen" - fügt manuell einen neuen Gast ein
    button .gaestefenster.toolbar.add \
        -image [::toolbar_icons::get neuer_eintrag] \
        -command ::gaeste_fenster::oeffne_hinzufuegen_dialog \
        -bg #569A40 -fg white -activebackground #4a8735 -relief flat -bd 1
    pack .gaestefenster.toolbar.add -side left -padx 5 -pady 3
    ::tooltip::register .gaestefenster.toolbar.add "Gast manuell hinzufügen"

    # Button "Bearbeiten" - öffnet den Bearbeiten-Dialog für den markierten Gast
    button .gaestefenster.toolbar.edit \
        -image [::toolbar_icons::get bearbeiten] \
        -command ::gaeste_fenster::oeffne_bearbeiten_dialog \
        -bg #E0E0E0 -activebackground #C8C8C8 -relief flat -bd 1
    pack .gaestefenster.toolbar.edit -side left -padx 5 -pady 3
    ::tooltip::register .gaestefenster.toolbar.edit "Ausgewählten Gast bearbeiten"

    # Button "Löschen" - entfernt den markierten Gast nach Bestätigung
    button .gaestefenster.toolbar.delete \
        -image [::toolbar_icons::get loeschen] \
        -command ::gaeste_fenster::loesche_gast \
        -bg #E0E0E0 -activebackground #C8C8C8 -relief flat -bd 1
    pack .gaestefenster.toolbar.delete -side left -padx 5 -pady 3
    ::tooltip::register .gaestefenster.toolbar.delete "Ausgewählten Gast löschen"

    # Button "Schließen" - schließt das Fenster (rechts ausgerichtet)
    button .gaestefenster.toolbar.close \
        -image [::toolbar_icons::get schliessen] \
        -command {destroy .gaestefenster} \
        -bg #E0E0E0 -activebackground #C8C8C8 -relief flat -bd 1
    pack .gaestefenster.toolbar.close -side right -padx 5 -pady 3
    ::tooltip::register .gaestefenster.toolbar.close "Fenster schließen"

    # =========================================================================
    # Hauptbereich: Treeview mit Scrollbars
    # =========================================================================
    frame .gaestefenster.main -bg white
    pack .gaestefenster.main -fill both -expand 1

    # Treeview mit den Spalten Nachname und Vorname
    ttk::treeview .gaestefenster.main.tree \
        -columns {nachname vorname} \
        -show headings \
        -selectmode browse \
        -yscrollcommand {.gaestefenster.main.yscroll set} \
        -xscrollcommand {.gaestefenster.main.xscroll set}

    # Vertikale Scrollbar
    scrollbar .gaestefenster.main.yscroll -orient vertical \
        -command {.gaestefenster.main.tree yview}

    # Horizontale Scrollbar
    scrollbar .gaestefenster.main.xscroll -orient horizontal \
        -command {.gaestefenster.main.tree xview}

    # Spaltenüberschriften und -breiten
    .gaestefenster.main.tree heading nachname -text "Nachname" -anchor w
    .gaestefenster.main.tree heading vorname  -text "Vorname"  -anchor w
    .gaestefenster.main.tree column  nachname -width 300 -anchor w
    .gaestefenster.main.tree column  vorname  -width 300 -anchor w

    # Grid-Layout für Treeview und Scrollbars
    grid .gaestefenster.main.tree    -row 0 -column 0 -sticky nsew
    grid .gaestefenster.main.yscroll -row 0 -column 1 -sticky ns
    grid .gaestefenster.main.xscroll -row 1 -column 0 -sticky ew

    # Grid-Gewichtung: Treeview wächst mit dem Fenster
    grid rowconfigure    .gaestefenster.main 0 -weight 1
    grid columnconfigure .gaestefenster.main 0 -weight 1

    # =========================================================================
    # Statuszeile mit Eintragsanzahl
    # =========================================================================
    frame .gaestefenster.status -bg #F0F0F0 -relief sunken -bd 1
    pack .gaestefenster.status -fill x -side bottom

    label .gaestefenster.status.info \
        -text "" -bg #F0F0F0 -fg #666666 -anchor w -padx 5
    pack .gaestefenster.status.info -side left

    # =========================================================================
    # Event-Bindings
    # =========================================================================

    # Treeview-Selektion: ausgewaehlter_index aktuell halten
    bind .gaestefenster.main.tree <<TreeviewSelect>> {
        set selected_items [.gaestefenster.main.tree selection]
        if {[llength $selected_items] > 0} {
            set item_id [lindex $selected_items 0]
            set all_items [.gaestefenster.main.tree children {}]
            set ::gaeste_fenster::ausgewaehlter_index [lsearch $all_items $item_id]
        } else {
            set ::gaeste_fenster::ausgewaehlter_index -1
        }
    }

    # Doppelklick öffnet den Bearbeiten-Dialog
    bind .gaestefenster.main.tree <Double-Button-1> {::gaeste_fenster::oeffne_bearbeiten_dialog}

    # Enter-Taste öffnet den Bearbeiten-Dialog
    bind .gaestefenster.main.tree <Return> {::gaeste_fenster::oeffne_bearbeiten_dialog}

    # ESC schließt das Fenster
    bind .gaestefenster <Escape> {destroy .gaestefenster}

    # =========================================================================
    # Daten laden und Anzeige aufbauen
    # =========================================================================
    ::gaeste_fenster::lade_gaeste_fuer_fenster
    ::gaeste_fenster::aktualisiere_anzeige

    # Fokus auf den Treeview setzen
    focus .gaestefenster.main.tree
}
