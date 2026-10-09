# =============================================================================
# warteliste_fenster.tcl - Verwaltung der Warteliste für neue Mitglieder
# =============================================================================
# Die Mitgliederzahl des Vereins ist begrenzt. Interessenten werden deshalb
# auf eine Warteliste gesetzt und rücken in der Reihenfolge ihrer Eintragung
# nach. Die Liste wird NICHT sortiert: wer zuerst eingetragen wurde, steht
# oben (Platz 1), zuletzt Eingetragene stehen am Ende.
#
# Gespeichert wird in daten/warteliste.json. Die Felder entsprechen denen der
# Mitgliederliste ohne Eintrittsdatum und Funktion. Die Feldnamen dürfen sich
# nicht mit Journal-Feldern (datum, uhrzeit, bemerkungen ...) überschneiden,
# da alle *.json im Datenverzeichnis vom Journal-Parser gelesen werden.
#
# Funktionen:
#   - Hinzufügen, Bearbeiten, Löschen von Anwärtern
#   - Übernahme in die Mitgliederliste (über den Dialog "Mitglied hinzufügen")
#   - Namensabfrage für den Dialog "Neuer Eintrag" (::warteliste::lade_namen)
# =============================================================================

namespace eval ::warteliste {
    # Reihenfolge der Felder in jedem Listeneintrag (= Reihenfolge in der JSON-Datei)
    variable felder {nachname vorname geburtsdatum geburtsort strasse plz ort festnetz mobilfunk email}

    # Beschriftungen der Eingabefelder im Dialog (Unicode-Escapes für Windows)
    variable beschriftungen [dict create \
        nachname     "Nachname:*"    \
        vorname      "Vorname:*"     \
        geburtsdatum "Geburtsdatum:" \
        geburtsort   "Geburtsort:"   \
        strasse      "Straße:"  \
        plz          "PLZ:"          \
        ort          "Ort:"          \
        festnetz     "Festnetz:"     \
        mobilfunk    "Mobilfunk:"    \
        email        "E-Mail:"       \
    ]

    # Interne Liste aller Anwärter; jeder Eintrag ist ein Dictionary mit den Feldern oben
    variable liste [list]

    # Index des markierten Eintrags in der Liste (-1 = nichts markiert)
    variable markiert -1

    # Index des Eintrags, der im Dialog bearbeitet wird (-1 = neuer Eintrag)
    variable dialog_index -1

    # Eingabewerte des Dialogs (Array: Feldname -> Wert)
    variable eingabe
    array set eingabe {}
}

# =============================================================================
# ::warteliste::lade
# Liest warteliste.json in die interne Liste ein (Reihenfolge bleibt erhalten).
# Fehlt die Datei, bleibt die Liste leer.
# =============================================================================
proc ::warteliste::lade {} {
    variable liste
    variable felder

    # Liste zurücksetzen
    set liste [list]

    # Datei existiert noch nicht (erster Start) → leere Warteliste
    if {![file exists $::warteliste_json]} {
        return
    }

    # Datei UTF-8-kodiert einlesen
    set fp [open $::warteliste_json r]
    fconfigure $fp -encoding utf-8
    set inhalt [read $fp]
    close $fp

    # Zeilenweises Parsing: Jedes Feld steht in einer eigenen Zeile,
    # eine Zeile mit schließender Klammer beendet den Eintrag
    set eintrag [dict create]
    foreach zeile [split $inhalt "\n"] {
        # Feld "schluessel": "wert" erkennen (Wert darf escapte Zeichen enthalten)
        if {[regexp {^\s*"([a-z]+)":\s*"((?:[^"\\]|\\.)*)"} $zeile -> schluessel wert]} {
            # Nur bekannte Felder übernehmen
            if {$schluessel in $felder} {
                # JSON-Escapes für Anführungszeichen und Backslash zurückwandeln
                dict set eintrag $schluessel [string map {\\\" \" \\\\ \\} $wert]
            }
        } elseif {[regexp {^\s*\}} $zeile] && [dict size $eintrag] > 0} {
            # Eintrag abgeschlossen: fehlende Felder mit Leerstring ergänzen
            foreach feld $felder {
                if {![dict exists $eintrag $feld]} {
                    dict set eintrag $feld ""
                }
            }
            lappend liste $eintrag
            set eintrag [dict create]
        }
    }
}

# =============================================================================
# ::warteliste::speichere
# Schreibt die interne Liste vollständig nach warteliste.json.
# =============================================================================
proc ::warteliste::speichere {} {
    variable liste
    variable felder

    # JSON zeilenweise aufbauen (ein Feld pro Zeile, passend zum Parser in ::warteliste::lade)
    set zeilen [list]
    lappend zeilen "\{"
    lappend zeilen "  \"warteliste\": \["

    set anzahl [llength $liste]
    set nr 0
    foreach eintrag $liste {
        incr nr
        lappend zeilen "    \{"
        set feld_nr 0
        foreach feld $felder {
            incr feld_nr
            # Backslash und Anführungszeichen für JSON escapen
            set wert [string map {\\ \\\\ \" \\\"} [dict get $eintrag $feld]]
            # Komma nach jedem Feld außer dem letzten (valides JSON)
            set komma [expr {$feld_nr < [llength $felder] ? "," : ""}]
            lappend zeilen "      \"$feld\": \"$wert\"$komma"
        }
        # Komma nach jedem Eintrag außer dem letzten
        lappend zeilen [expr {$nr < $anzahl ? "    \}," : "    \}"}]
    }

    lappend zeilen "  \],"
    # Zeitstempel und Anzahl wie in mitglieder.json
    set zeitstempel [clock format [clock seconds] -format "%d.%m.%Y, %H:%M:%S"]
    lappend zeilen "  \"erstellt_am\": \"$zeitstempel\","
    lappend zeilen "  \"anzahl\": $anzahl"
    lappend zeilen "\}"

    # Verzeichnis sicherstellen
    set verzeichnis [file dirname $::warteliste_json]
    if {![file exists $verzeichnis]} {
        file mkdir $verzeichnis
    }

    # UTF-8-kodiert schreiben
    set fp [open $::warteliste_json w]
    fconfigure $fp -encoding utf-8
    puts $fp [join $zeilen "\n"]
    close $fp
}

# =============================================================================
# ::warteliste::lade_namen
# Liefert alle Anwärter als Liste von {nachname vorname}-Paaren.
# Wird vom Dialog "Neuer Eintrag" für Prüfung und Autovervollständigung genutzt.
# Liest direkt aus der Datei, damit auch ohne geöffnetes Fenster aktuelle Daten vorliegen.
# =============================================================================
proc ::warteliste::lade_namen {} {
    variable liste

    # Aktuellen Stand aus der Datei laden
    lade

    # Nur Nachname und Vorname zurückgeben
    set namen [list]
    foreach eintrag $liste {
        lappend namen [list [dict get $eintrag nachname] [dict get $eintrag vorname]]
    }
    return $namen
}

# =============================================================================
# ::warteliste::ist_mitglied
# Prüft, ob eine Person bereits in mitglieder.json steht (case-insensitiv).
# Parameter:
#   nachname, vorname - zu prüfender Name
# Rückgabe: 1 wenn Mitglied, sonst 0
# =============================================================================
proc ::warteliste::ist_mitglied {nachname vorname} {
    # Ohne Mitgliederdatei gibt es keine Mitglieder
    if {![file exists $::mitglieder_json]} {
        return 0
    }

    # Datei einlesen
    set fp [open $::mitglieder_json r]
    fconfigure $fp -encoding utf-8
    set inhalt [read $fp]
    close $fp

    # Zeilenweise Nachname/Vorname-Paare suchen (wie in ::gaeste::lade_gaeste)
    set aktueller_nachname ""
    foreach zeile [split $inhalt "\n"] {
        if {[regexp {"nachname":\s*"([^"]*)"} $zeile -> nn]} {
            set aktueller_nachname [string trim $nn]
        }
        if {[regexp {"vorname":\s*"([^"]*)"} $zeile -> vn]} {
            # Paar vollständig - mit gesuchtem Namen vergleichen
            if {[string equal -nocase $aktueller_nachname $nachname] &&
                [string equal -nocase [string trim $vn] $vorname]} {
                return 1
            }
            set aktueller_nachname ""
        }
    }
    return 0
}

# =============================================================================
# ::warteliste::aktualisiere_anzeige
# Füllt den Treeview neu aus der internen Liste und aktualisiert die Statuszeile.
# =============================================================================
proc ::warteliste::aktualisiere_anzeige {} {
    variable liste
    variable markiert

    # Fenster nicht offen → nichts zu tun
    if {![winfo exists .warteliste.main.tree]} {
        return
    }

    # Markierung zurücksetzen, da die Zeilen neu aufgebaut werden
    set markiert -1

    # Alle Zeilen entfernen
    .warteliste.main.tree delete [.warteliste.main.tree children {}]

    # Zeilen in Listenreihenfolge einfügen; Item-ID = Listenindex für einfache Zuordnung
    set index 0
    foreach eintrag $liste {
        set platz [expr {$index + 1}]
        .warteliste.main.tree insert {} end -id $index -values [list \
            $platz \
            [dict get $eintrag nachname] \
            [dict get $eintrag vorname] \
            [dict get $eintrag strasse] \
            [dict get $eintrag plz] \
            [dict get $eintrag ort] \
            [dict get $eintrag festnetz] \
            [dict get $eintrag mobilfunk] \
            [dict get $eintrag email] \
            [dict get $eintrag geburtsdatum]]
        incr index
    }

    # Anzahl in der Statuszeile anzeigen
    set anzahl [llength $liste]
    if {$anzahl == 1} {
        .warteliste.status configure -text "1 Person auf der Warteliste."
    } else {
        .warteliste.status configure -text "$anzahl Personen auf der Warteliste."
    }
}

# =============================================================================
# ::warteliste::pruefe_auswahl
# Prüft, ob ein Eintrag markiert ist, und zeigt sonst einen Hinweis.
# Rückgabe: 1 wenn ein Eintrag markiert ist, sonst 0
# =============================================================================
proc ::warteliste::pruefe_auswahl {} {
    variable markiert

    if {$markiert < 0} {
        tk_messageBox -parent .warteliste -icon info -type ok \
            -title "Kein Eintrag ausgewählt" \
            -message "Bitte wählen Sie zuerst einen Eintrag aus der Liste aus."
        return 0
    }
    return 1
}

# =============================================================================
# ::warteliste::pruefe_speichern_button
# Trace-Callback: Speichern nur aktiv, wenn Nachname und Vorname ausgefüllt sind.
# =============================================================================
proc ::warteliste::pruefe_speichern_button {args} {
    variable eingabe

    # Dialog bereits geschlossen → nichts tun
    if {![winfo exists .warteliste.dialog.buttons.speichern]} {
        return
    }

    if {[string trim $eingabe(nachname)] ne "" && [string trim $eingabe(vorname)] ne ""} {
        .warteliste.dialog.buttons.speichern configure -state normal
    } else {
        .warteliste.dialog.buttons.speichern configure -state disabled
    }
}

# =============================================================================
# ::warteliste::oeffne_dialog
# Öffnet den Dialog zum Hinzufügen (index = -1) oder Bearbeiten eines Anwärters.
# =============================================================================
proc ::warteliste::oeffne_dialog {index} {
    variable liste
    variable felder
    variable beschriftungen
    variable eingabe
    variable dialog_index

    # Nur ein Dialog gleichzeitig
    if {[winfo exists .warteliste.dialog]} {
        raise .warteliste.dialog
        focus .warteliste.dialog
        return
    }

    # Index merken, damit beim Speichern klar ist, ob neu oder geändert
    set dialog_index $index

    # Eingabefelder vorbelegen: leer bei neuem Eintrag, sonst vorhandene Werte
    foreach feld $felder {
        if {$index < 0} {
            set eingabe($feld) ""
        } else {
            set eingabe($feld) [dict get [lindex $liste $index] $feld]
        }
    }

    # Dialogfenster erstellen
    set d .warteliste.dialog
    toplevel $d
    if {$index < 0} {
        wm title $d "Anwärter hinzufügen"
    } else {
        wm title $d "Anwärter bearbeiten"
    }
    wm geometry $d 600x470
    wm transient $d .warteliste

    # Button-Leiste zuerst packen, damit sie immer sichtbar bleibt
    frame $d.buttons -pady 10
    pack $d.buttons -side bottom -fill x

    # Inhaltsbereich
    frame $d.content -padx 20 -pady 20
    pack $d.content -fill both -expand 1

    # Für jedes Feld ein Label und ein Eingabefeld im Grid anlegen
    set row 0
    foreach feld $felder {
        label $d.content.${feld}_label -text [dict get $beschriftungen $feld] -anchor w
        entry $d.content.${feld}_entry -font {TkDefaultFont 11} \
            -textvariable ::warteliste::eingabe($feld)
        grid $d.content.${feld}_label -row $row -column 0 -sticky w -pady 5
        grid $d.content.${feld}_entry -row $row -column 1 -sticky ew -pady 5
        incr row
    }

    # Hinweis für Pflichtfelder
    label $d.content.hinweis -text "* Pflichtfelder" -fg "#666666" -font {Arial 9 italic}
    grid $d.content.hinweis -row $row -column 0 -columnspan 2 -sticky w -pady 10

    # Eingabespalte dehnt sich mit dem Fenster
    grid columnconfigure $d.content 1 -weight 1

    # Abbrechen (neutral grau)
    button $d.buttons.abbrechen -text "Abbrechen" \
        -bg $::palette::neutral -activebackground $::palette::neutral_aktiv \
        -command [list destroy $d]
    pack $d.buttons.abbrechen -side right -padx 5

    # Speichern (Vereinsgrün, weiße Schrift auch im deaktivierten Zustand)
    button $d.buttons.speichern -text "Speichern" \
        -bg $::palette::positiv -fg $::palette::positiv_text \
        -activebackground $::palette::positiv_aktiv -disabledforeground $::palette::positiv_text \
        -command ::warteliste::speichere_dialog
    pack $d.buttons.speichern -side right -padx 5

    # Pflichtfeld-Prüfung bei jeder Eingabe in Nachname/Vorname
    trace add variable ::warteliste::eingabe(nachname) write ::warteliste::pruefe_speichern_button
    trace add variable ::warteliste::eingabe(vorname)  write ::warteliste::pruefe_speichern_button
    # Traces beim Schließen wieder entfernen (nur für das Toplevel selbst, nicht für Kinder)
    bind $d <Destroy> {
        if {"%W" eq ".warteliste.dialog"} {
            catch {trace remove variable ::warteliste::eingabe(nachname) write ::warteliste::pruefe_speichern_button}
            catch {trace remove variable ::warteliste::eingabe(vorname)  write ::warteliste::pruefe_speichern_button}
        }
    }

    # Anfangszustand des Speichern-Buttons setzen
    pruefe_speichern_button

    # ESC schließt den Dialog
    bind $d <Escape> [list destroy $d]

    # Fokus ins erste Feld
    focus $d.content.nachname_entry
}

# =============================================================================
# ::warteliste::speichere_dialog
# Übernimmt die Dialogeingaben in die Liste (neu am Ende oder an alter Stelle),
# nach Duplikatprüfung gegen Mitglieder und Warteliste.
# =============================================================================
proc ::warteliste::speichere_dialog {} {
    variable liste
    variable felder
    variable eingabe
    variable dialog_index

    # Eingaben getrimmt in ein Dictionary übernehmen
    set neu [dict create]
    foreach feld $felder {
        dict set neu $feld [string trim $eingabe($feld)]
    }
    set nachname [dict get $neu nachname]
    set vorname  [dict get $neu vorname]

    # Pflichtfelder prüfen (Button ist zwar gesperrt, Enter o.ä. aber sicherheitshalber)
    if {$nachname eq "" || $vorname eq ""} {
        return
    }

    # Hinweis, wenn die Person bereits Mitglied ist (Namensgleichheit ist möglich → nachfragen)
    if {[ist_mitglied $nachname $vorname]} {
        set antwort [tk_messageBox -parent .warteliste.dialog -icon warning -type yesno \
            -title "Bereits Mitglied" \
            -message "$vorname $nachname ist bereits in der Mitgliederliste eingetragen.\n\nTrotzdem auf die Warteliste setzen?"]
        if {$antwort ne "yes"} {
            return
        }
    }

    # Hinweis, wenn derselbe Name schon auf der Warteliste steht (eigener Eintrag ausgenommen)
    set index 0
    foreach eintrag $liste {
        if {$index != $dialog_index &&
            [string equal -nocase [dict get $eintrag nachname] $nachname] &&
            [string equal -nocase [dict get $eintrag vorname] $vorname]} {
            set antwort [tk_messageBox -parent .warteliste.dialog -icon warning -type yesno \
                -title "Bereits auf der Warteliste" \
                -message "$vorname $nachname steht bereits auf der Warteliste (Platz [expr {$index + 1}]).\n\nTrotzdem speichern?"]
            if {$antwort ne "yes"} {
                return
            }
            break
        }
        incr index
    }

    # Neuer Eintrag ans Ende, geänderter Eintrag bleibt auf seinem Platz
    if {$dialog_index < 0} {
        lappend liste $neu
    } else {
        set liste [lreplace $liste $dialog_index $dialog_index $neu]
    }

    # Speichern, Anzeige aktualisieren, Dialog schließen
    if {[catch {speichere} err]} {
        tk_messageBox -parent .warteliste.dialog -icon error -type ok \
            -title "Fehler beim Speichern" \
            -message "Die Warteliste konnte nicht gespeichert werden:\n\n$err"
        return
    }
    aktualisiere_anzeige
    destroy .warteliste.dialog
}

# =============================================================================
# ::warteliste::loesche_markierten
# Löscht den markierten Anwärter nach Bestätigung (mit Backup der Datei).
# =============================================================================
proc ::warteliste::loesche_markierten {} {
    variable liste
    variable markiert

    # Ohne Auswahl nichts löschen
    if {![pruefe_auswahl]} {
        return
    }

    # Sicherheitsabfrage mit Name und Platz
    set eintrag [lindex $liste $markiert]
    set antwort [tk_messageBox -parent .warteliste -icon question -type yesno \
        -title "Löschen bestätigen" \
        -message "Diesen Eintrag wirklich von der Warteliste löschen?\n\nPlatz [expr {$markiert + 1}]: [dict get $eintrag nachname], [dict get $eintrag vorname]"]
    if {$antwort ne "yes"} {
        return
    }

    # Backup der aktuellen Datei anlegen (wie beim Löschen von Mitgliedern)
    if {[file exists $::warteliste_json]} {
        set backup_dir [::pfad::get_backups_directory]
        if {![file exists $backup_dir]} {
            file mkdir $backup_dir
        }
        file copy -force $::warteliste_json [file join $backup_dir "warteliste.json.bak"]
    }

    # Eintrag entfernen, speichern und Anzeige aktualisieren
    set liste [lreplace $liste $markiert $markiert]
    speichere
    aktualisiere_anzeige
}

# =============================================================================
# ::warteliste::in_mitgliederliste_uebernehmen
# Öffnet den Dialog "Mitglied hinzufügen", vorbelegt mit den Daten des
# markierten Anwärters und dem heutigen Datum als Eintrittsdatum.
# Erst nach "Speichern" im Mitglieder-Dialog wird der Anwärter von der
# Warteliste entfernt (Callback ::warteliste::nach_uebernahme).
# =============================================================================
proc ::warteliste::in_mitgliederliste_uebernehmen {} {
    variable liste
    variable markiert

    # Ohne Auswahl keine Übernahme
    if {![pruefe_auswahl]} {
        return
    }

    # Ein bereits offener Hinzufügen-Dialog würde sonst ohne Vorbelegung nur nach vorne geholt
    if {[winfo exists .mitglieder.hinzufuegen]} {
        tk_messageBox -parent .warteliste -icon info -type ok \
            -title "Dialog bereits geöffnet" \
            -message "In der Mitgliederverwaltung ist bereits der Dialog \"Neues Mitglied hinzufügen\" geöffnet.\n\nBitte schließen Sie ihn zuerst."
        return
    }

    # Datensatz des Anwärters merken (für das spätere Löschen nach dem Speichern)
    set eintrag [lindex $liste $markiert]

    # Vorbelegung für den Mitglieder-Dialog: alle Felder + heutiges Eintrittsdatum
    set vorbelegung $eintrag
    dict set vorbelegung eintrittsdatum [clock format [clock seconds] -format "%d.%m.%Y"]

    # Mitgliederverwaltung öffnen (lädt die Mitgliederliste) und Dialog vorbelegt anzeigen
    open_mitglieder_fenster
    oeffne_hinzufuegen_dialog $vorbelegung [list ::warteliste::nach_uebernahme $eintrag]
}

# =============================================================================
# ::warteliste::nach_uebernahme
# Callback nach erfolgreichem Speichern im Mitglieder-Dialog:
# entfernt den übernommenen Anwärter von der Warteliste.
# Parameter:
#   eintrag - der ursprüngliche Datensatz (Dictionary) des Anwärters
# =============================================================================
proc ::warteliste::nach_uebernahme {eintrag} {
    variable liste

    # Aktuellen Stand laden (Fenster könnte inzwischen geschlossen worden sein)
    lade

    # Eintrag anhand des vollständigen Datensatzes suchen, nicht über den Index,
    # da sich die Liste zwischenzeitlich geändert haben kann
    set index [lsearch -exact $liste $eintrag]
    if {$index < 0} {
        return
    }

    # Entfernen, speichern und - falls das Fenster offen ist - Anzeige aktualisieren
    set liste [lreplace $liste $index $index]
    speichere
    aktualisiere_anzeige
}

# =============================================================================
# ::warteliste::zeige_kontext_menu
# Rechtsklick-Menü: Bearbeiten, In die Mitgliederliste übernehmen, Löschen.
# Parameter:
#   x y - Position im Treeview (Zeilenermittlung)
#   X Y - Bildschirmposition (Menüplatzierung)
# =============================================================================
proc ::warteliste::zeige_kontext_menu {x y X Y} {
    # Zeile unter dem Mauszeiger markieren; Klick ins Leere öffnet kein Menü
    set item [.warteliste.main.tree identify row $x $y]
    if {$item eq ""} {
        return
    }
    .warteliste.main.tree selection set $item
    # Auswahl-Event sofort verarbeiten, damit ::warteliste::markiert stimmt
    set ::warteliste::markiert $item

    # Altes Menü entfernen
    if {[winfo exists .warteliste_kontext_menu]} {
        destroy .warteliste_kontext_menu
    }

    # Menü aufbauen (Unicode-Escapes für Windows)
    menu .warteliste_kontext_menu -tearoff 0
    .warteliste_kontext_menu add command -label "Bearbeiten" \
        -command {::warteliste::oeffne_dialog $::warteliste::markiert}
    .warteliste_kontext_menu add command -label "In die Mitgliederliste übernehmen" \
        -command ::warteliste::in_mitgliederliste_uebernehmen
    # Trennlinie vor der destruktiven Aktion
    .warteliste_kontext_menu add separator
    .warteliste_kontext_menu add command -label "Löschen" \
        -command ::warteliste::loesche_markierten

    # Menü an der Mausposition anzeigen
    tk_popup .warteliste_kontext_menu $X $Y
}

# =============================================================================
# open_warteliste_fenster
# Öffnet das Fenster "Warteliste" (Menü Werkzeuge → Warteliste).
# =============================================================================
proc open_warteliste_fenster {} {
    # Fenster existiert bereits → nach vorne holen
    if {[winfo exists .warteliste]} {
        raise .warteliste
        focus .warteliste
        return
    }

    # Fenster anlegen
    toplevel .warteliste
    wm title .warteliste "Warteliste"
    wm minsize .warteliste 1000 400
    wm geometry .warteliste 1400x600

    # Über dem Hauptfenster zentrieren
    update idletasks
    set x_pos [expr {[winfo x .] + ([winfo width .] - 1400) / 2}]
    set y_pos [expr {[winfo y .] + ([winfo height .] - 600) / 2}]
    if {$x_pos < 0} { set x_pos 0 }
    if {$y_pos < 0} { set y_pos 0 }
    wm geometry .warteliste +${x_pos}+${y_pos}

    # -------------------------------------------------------------------------
    # Toolbar (gleiche Icons wie in der Mitgliederverwaltung)
    # -------------------------------------------------------------------------
    frame .warteliste.toolbar -bg #E0E0E0 -relief raised -bd 1
    pack .warteliste.toolbar -fill x -pady 2

    # Hinzufügen - neuer Anwärter am Ende der Liste
    button .warteliste.toolbar.add -image [::toolbar_icons::get neuer_eintrag] \
        -command {::warteliste::oeffne_dialog -1}
    pack .warteliste.toolbar.add -side left -padx 5 -pady 3
    ::tooltip::register .warteliste.toolbar.add "Anwärter hinzufügen - Strg+N"

    # Bearbeiten - markierten Anwärter ändern
    button .warteliste.toolbar.edit -image [::toolbar_icons::get bearbeiten] \
        -command {if {[::warteliste::pruefe_auswahl]} {::warteliste::oeffne_dialog $::warteliste::markiert}}
    pack .warteliste.toolbar.edit -side left -padx 5 -pady 3
    ::tooltip::register .warteliste.toolbar.edit "Ausgewählten Eintrag bearbeiten"

    # Löschen - markierten Anwärter entfernen
    button .warteliste.toolbar.delete -image [::toolbar_icons::get loeschen] \
        -command ::warteliste::loesche_markierten
    pack .warteliste.toolbar.delete -side left -padx 5 -pady 3
    ::tooltip::register .warteliste.toolbar.delete "Ausgewählten Eintrag löschen"

    # Schließen (rechts)
    button .warteliste.toolbar.close -image [::toolbar_icons::get schliessen] \
        -command {destroy .warteliste}
    pack .warteliste.toolbar.close -side right -padx 5 -pady 3
    ::tooltip::register .warteliste.toolbar.close "Fenster schließen"

    # Statuszeile mit Anzahl (unten, vor dem Hauptbereich packen)
    label .warteliste.status -anchor w -padx 10 -pady 4
    pack .warteliste.status -side bottom -fill x

    # -------------------------------------------------------------------------
    # Treeview mit Scrollbars
    # -------------------------------------------------------------------------
    frame .warteliste.main -bg white
    pack .warteliste.main -fill both -expand 1

    scrollbar .warteliste.main.yscroll -command {.warteliste.main.tree yview} -orient vertical
    scrollbar .warteliste.main.xscroll -command {.warteliste.main.tree xview} -orient horizontal

    # Gleiche Treeview-Optik wie in der Mitgliederverwaltung
    ttk::style configure Treeview -font {TkDefaultFont 11} -rowheight 22
    ttk::style configure Treeview.Heading -background $::palette::akzent -foreground white
    ttk::style map Treeview.Heading \
        -background [list active $::palette::akzent pressed $::palette::positiv_aktiv] \
        -relief     [list active flat pressed sunken]

    # Spalten wie Mitgliederliste, ohne Eintrittsdatum, mit "Platz" vorne
    ttk::treeview .warteliste.main.tree \
        -columns {platz nachname vorname strasse plz ort festnetz mobilfunk email geburtsdatum} \
        -show headings \
        -selectmode browse \
        -yscrollcommand {.warteliste.main.yscroll set} \
        -xscrollcommand {.warteliste.main.xscroll set}

    # Überschriften und Breiten (Spalte, Text, Breite)
    foreach {spalte text breite} [list \
        platz        "Platz"         60  \
        nachname     "Nachname"      150 \
        vorname      "Vorname"       150 \
        strasse      "Straße"   200 \
        plz          "PLZ"           60  \
        ort          "Ort"           150 \
        festnetz     "Festnetz"      120 \
        mobilfunk    "Mobilfunk"     120 \
        email        "E-Mail"        200 \
        geburtsdatum "Geburtsdatum"  110 \
    ] {
        .warteliste.main.tree heading $spalte -text $text
        .warteliste.main.tree column $spalte -width $breite -anchor w
    }
    # Platz-Nummer zentriert
    .warteliste.main.tree column platz -anchor center

    # Layout per Grid
    grid .warteliste.main.tree    -row 0 -column 0 -sticky nsew
    grid .warteliste.main.yscroll -row 0 -column 1 -sticky ns
    grid .warteliste.main.xscroll -row 1 -column 0 -sticky ew
    grid rowconfigure    .warteliste.main 0 -weight 1
    grid columnconfigure .warteliste.main 0 -weight 1

    # Auswahl merken: Item-ID entspricht dem Listenindex
    bind .warteliste.main.tree <<TreeviewSelect>> {
        set auswahl [.warteliste.main.tree selection]
        if {[llength $auswahl] > 0} {
            set ::warteliste::markiert [lindex $auswahl 0]
        } else {
            set ::warteliste::markiert -1
        }
    }

    # Doppelklick und Enter öffnen den Bearbeiten-Dialog
    bind .warteliste.main.tree <Double-Button-1> {
        if {$::warteliste::markiert >= 0} {::warteliste::oeffne_dialog $::warteliste::markiert}
    }
    bind .warteliste.main.tree <Return> {
        if {$::warteliste::markiert >= 0} {::warteliste::oeffne_dialog $::warteliste::markiert}
    }

    # Rechtsklick öffnet das Kontextmenü
    bind .warteliste.main.tree <Button-3> {::warteliste::zeige_kontext_menu %x %y %X %Y}

    # Strg+N fügt einen Anwärter hinzu
    bind .warteliste <Control-n> {.warteliste.toolbar.add invoke}
    bind .warteliste <Control-N> {.warteliste.toolbar.add invoke}

    # Daten laden und anzeigen
    ::warteliste::lade
    ::warteliste::aktualisiere_anzeige
}
