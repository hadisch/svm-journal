# =============================================================================
# Waffenregister-Dialog
# Ermöglicht die Verwaltung der Vereinswaffen (CRUD-Funktionalität)
# =============================================================================

# Namespace für Waffenregister-Verwaltung
namespace eval ::waffenregister {
    # Dialog-Variablen
    variable fenster ""
    variable waffen_liste [list]
    variable ausgewaehlter_index -1
}

# =============================================================================
# Prozedur: lade_behoerde_name
# Beschreibung: Lädt den Behördennamen aus behoerde.json
# Rückgabe: Behördenname oder leerer String bei Fehler
# =============================================================================
proc ::waffenregister::lade_behoerde_name {} {
    # Lädt den Behördennamen aus behoerde.json
    set behoerde_json [::pfad::get_json_path "preferences" "behoerde.json"]

    if {![file exists $behoerde_json]} {
        return ""
    }

    if {[catch {
        set fp [open $behoerde_json r]
        fconfigure $fp -encoding utf-8
        set content [read $fp]
        close $fp

        # Behördennamen extrahieren
        if {[regexp {"name":\s*"([^"]*)"} $content -> name]} {
            return $name
        }
    }]} {
        return ""
    }

    return ""
}

# =============================================================================
# Prozedur: lade_waffenregister
# Lädt alle Waffen aus der JSON-Datei
# Rückgabe: Liste von Dicts mit Waffendaten
# =============================================================================
proc ::waffenregister::lade_waffenregister {} {
    global waffenregister_json

    set waffen_liste [list]

    # Prüfen, ob Datei existiert
    if {![file exists $waffenregister_json]} {
        return $waffen_liste
    }

    # Datei öffnen und parsen
    set fp [open $waffenregister_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Waffen aus JSON-Array extrahieren
    set lines [split $json_content "\n"]
    set in_array 0
    set current_weapon [dict create]

    foreach line $lines {
        # Prüfen ob wir im "waffen"-Array sind
        if {[regexp {"waffen"} $line]} {
            set in_array 1
            continue
        }

        # Wenn wir im Array sind, Felder extrahieren
        if {$in_array} {
            # Art der Waffe extrahieren
            if {[regexp {"art":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon art [string trim $wert]
            }
            # Kaliber extrahieren
            if {[regexp {"kaliber":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon kaliber [string trim $wert]
            }
            # Seriennummer extrahieren
            if {[regexp {"seriennummer":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon seriennummer [string trim $wert]
            }
            # WBK-Nummer extrahieren
            if {[regexp {"wbk_nummer":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon wbk_nummer [string trim $wert]
            }
            # Hersteller extrahieren
            if {[regexp {"hersteller":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon hersteller [string trim $wert]
            }
            # Ausstellende Behörde extrahieren
            if {[regexp {"ausstellende_behoerde":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon ausstellende_behoerde [string trim $wert]
            }
            # Bemerkungen extrahieren
            if {[regexp {"bemerkungen":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon bemerkungen [string trim $wert]
            }

            # Ende eines Waffen-Objekts erkennen
            if {[regexp {\}\s*,?\s*$} $line]} {
                # Wenn das Dict nicht leer ist, zur Liste hinzufügen
                if {[dict size $current_weapon] > 0} {
                    lappend waffen_liste $current_weapon
                    set current_weapon [dict create]
                }
            }
        }
    }

    return $waffen_liste
}

# =============================================================================
# Prozedur: speichere_waffenregister
# Speichert die Waffenliste in die JSON-Datei
# Parameter:
#   waffen_liste - Liste von Dicts mit Waffendaten
# =============================================================================
proc ::waffenregister::speichere_waffenregister {waffen_liste} {
    global waffenregister_json

    # JSON-Datei aufbauen
    set lines [list]
    lappend lines "\{"
    lappend lines "  \"waffen\": \["

    set anzahl [llength $waffen_liste]
    set counter 0

    # Jede Waffe als JSON-Objekt schreiben
    foreach waffe $waffen_liste {
        set art [dict get $waffe art]
        set kaliber [dict get $waffe kaliber]
        set seriennummer [dict get $waffe seriennummer]
        set wbk_nummer [dict get $waffe wbk_nummer]
        set hersteller [dict get $waffe hersteller]
        # Neue Felder mit Standardwerten für Abwärtskompatibilität
        if {[dict exists $waffe ausstellende_behoerde]} {
            set ausstellende_behoerde [dict get $waffe ausstellende_behoerde]
        } else {
            set ausstellende_behoerde ""
        }
        if {[dict exists $waffe bemerkungen]} {
            set bemerkungen [dict get $waffe bemerkungen]
        } else {
            set bemerkungen ""
        }

        lappend lines "    \{"
        lappend lines "      \"art\": \"$art\","
        lappend lines "      \"kaliber\": \"$kaliber\","
        lappend lines "      \"seriennummer\": \"$seriennummer\","
        lappend lines "      \"wbk_nummer\": \"$wbk_nummer\","
        lappend lines "      \"hersteller\": \"$hersteller\","
        lappend lines "      \"ausstellende_behoerde\": \"$ausstellende_behoerde\","
        lappend lines "      \"bemerkungen\": \"$bemerkungen\""

        incr counter
        # Komma nur wenn nicht das letzte Element
        if {$counter < $anzahl} {
            lappend lines "    \},"
        } else {
            lappend lines "    \}"
        }
    }

    lappend lines "  \]"
    lappend lines "\}"

    set json_content [join $lines "\n"]

    # Datei schreiben
    set fp [open $waffenregister_json w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp
}

# =============================================================================
# Prozedur: aktualisiere_waffen_anzeige
# Aktualisiert das Treeview mit allen Waffen
# =============================================================================
proc ::waffenregister::aktualisiere_waffen_anzeige {} {
    variable fenster
    variable waffen_liste

    # Treeview leeren
    $fenster.main.tree delete [$fenster.main.tree children {}]

    # Waffen zum Treeview hinzufügen
    foreach waffe $waffen_liste {
        set art [dict get $waffe art]
        set kaliber [dict get $waffe kaliber]
        set seriennummer [dict get $waffe seriennummer]
        set wbk_nummer [dict get $waffe wbk_nummer]
        set hersteller [dict get $waffe hersteller]

        # Neue Felder mit Standardwerten für Abwärtskompatibilität
        if {[dict exists $waffe ausstellende_behoerde]} {
            set ausstellende_behoerde [dict get $waffe ausstellende_behoerde]
        } else {
            set ausstellende_behoerde ""
        }
        if {[dict exists $waffe bemerkungen]} {
            set bemerkungen [dict get $waffe bemerkungen]
        } else {
            set bemerkungen ""
        }

        # Zeile zum Treeview hinzufügen
        $fenster.main.tree insert {} end -values [list \
            $art $kaliber $seriennummer $wbk_nummer $hersteller $ausstellende_behoerde $bemerkungen]
    }
}

# =============================================================================
# Prozedur: treeview_auswahl_geaendert
# Wird aufgerufen, wenn eine Auswahl im Treeview geändert wird
# =============================================================================
proc ::waffenregister::treeview_auswahl_geaendert {} {
    variable fenster
    variable ausgewaehlter_index

    # Aktuell ausgewählte Items holen
    set selection [$fenster.main.tree selection]

    if {$selection ne "" && [llength $selection] > 0} {
        # Item-ID des ersten ausgewählten Items
        set item_id [lindex $selection 0]

        # Index des Items ermitteln (Position in der Treeview-Kinderliste)
        set all_items [$fenster.main.tree children {}]
        set ausgewaehlter_index [lsearch -exact $all_items $item_id]

        # Löschen-Button aktivieren
        $fenster.button_frame.loeschen configure -state normal
    } else {
        set ausgewaehlter_index -1
        # Löschen-Button deaktivieren
        $fenster.button_frame.loeschen configure -state disabled
    }
}

# =============================================================================
# Prozedur: speichere_neue_waffe
# Speichert eine neue Waffe nach Validierung
# Parameter:
#   dialog - Dialog-Fenster
# =============================================================================
proc ::waffenregister::speichere_neue_waffe {dialog} {
    variable fenster
    variable waffen_liste

    # Werte aus Entry-Feldern holen
    set art [string trim [$dialog.main.art_entry get]]
    set kaliber [string trim [$dialog.main.kaliber_entry get]]
    set seriennummer [string trim [$dialog.main.seriennummer_entry get]]
    set wbk_nummer [string trim [$dialog.main.wbk_nummer_entry get]]
    set hersteller [string trim [$dialog.main.hersteller_entry get]]
    set ausstellende_behoerde [string trim [$dialog.main.behoerde_entry get]]
    set bemerkungen [string trim [$dialog.main.bemerkungen_text get 1.0 end]]

    # Pflichtfelder validieren (alle außer Hersteller, Ausstellende Behörde und Bemerkungen)
    if {$art eq ""} {
        tk_messageBox -parent $dialog -icon warning -title "Fehler" \
            -message "Bitte geben Sie die Art der Waffe ein."
        return
    }
    if {$kaliber eq ""} {
        tk_messageBox -parent $dialog -icon warning -title "Fehler" \
            -message "Bitte geben Sie das Kaliber ein."
        return
    }
    if {$seriennummer eq ""} {
        tk_messageBox -parent $dialog -icon warning -title "Fehler" \
            -message "Bitte geben Sie die Seriennummer ein."
        return
    }
    if {$wbk_nummer eq ""} {
        tk_messageBox -parent $dialog -icon warning -title "Fehler" \
            -message "Bitte geben Sie die WBK-Nummer ein."
        return
    }

    # Prüfen ob Seriennummer bereits existiert (case-insensitive)
    foreach waffe $waffen_liste {
        set vorhandene_seriennr [dict get $waffe seriennummer]
        if {[string equal -nocase $vorhandene_seriennr $seriennummer]} {
            tk_messageBox -parent $dialog -icon warning -title "Fehler" \
                -message "Eine Waffe mit der Seriennummer \"$seriennummer\" existiert bereits."
            return
        }
    }

    # Neue Waffe als Dict erstellen
    set neue_waffe [dict create \
        art $art \
        kaliber $kaliber \
        seriennummer $seriennummer \
        wbk_nummer $wbk_nummer \
        hersteller $hersteller \
        ausstellende_behoerde $ausstellende_behoerde \
        bemerkungen $bemerkungen]

    # Zur Liste hinzufügen
    lappend waffen_liste $neue_waffe

    # In JSON-Datei speichern
    speichere_waffenregister $waffen_liste

    # Anzeige aktualisieren
    aktualisiere_waffen_anzeige

    # Erfolgs-Nachricht
    tk_messageBox -parent $fenster -icon info -title "Erfolgreich" \
        -message "Die Waffe wurde erfolgreich hinzugefügt."

    # Dialog schließen
    destroy $dialog
}

# =============================================================================
# Prozedur: oeffne_hinzufuegen_dialog
# Öffnet einen Dialog zum Hinzufügen einer neuen Waffe
# =============================================================================
proc ::waffenregister::oeffne_hinzufuegen_dialog {} {
    variable fenster

    # Dialog-Fenster erstellen
    set dialog .waffenregister_hinzufuegen
    if {[winfo exists $dialog]} {
        raise $dialog
        focus $dialog
        return
    }

    # Nested Toplevel mit Parent-Beziehung
    toplevel $dialog
    wm transient $dialog $fenster
    wm title $dialog "Waffe hinzufügen"
    wm geometry $dialog "550x550"
    wm resizable $dialog 0 0

    # Hauptframe
    frame $dialog.main -padx 20 -pady 20
    pack $dialog.main -fill both -expand 1

    # === Eingabefelder im Grid-Layout ===

    # Zeile 0: Art der Waffe (Pflicht)
    label $dialog.main.art_label -text "Art der Waffe:*" -anchor w
    entry $dialog.main.art_entry -font {Arial 11}
    grid $dialog.main.art_label -row 0 -column 0 -sticky w -pady 5
    grid $dialog.main.art_entry -row 0 -column 1 -sticky ew -pady 5

    # Zeile 1: Kaliber (Pflicht)
    label $dialog.main.kaliber_label -text "Kaliber:*" -anchor w
    entry $dialog.main.kaliber_entry -font {Arial 11}
    grid $dialog.main.kaliber_label -row 1 -column 0 -sticky w -pady 5
    grid $dialog.main.kaliber_entry -row 1 -column 1 -sticky ew -pady 5

    # Zeile 2: Seriennummer (Pflicht)
    label $dialog.main.seriennummer_label -text "Seriennummer:*" -anchor w
    entry $dialog.main.seriennummer_entry -font {Arial 11}
    grid $dialog.main.seriennummer_label -row 2 -column 0 -sticky w -pady 5
    grid $dialog.main.seriennummer_entry -row 2 -column 1 -sticky ew -pady 5

    # Zeile 3: WBK-Nummer (Pflicht)
    label $dialog.main.wbk_nummer_label -text "WBK-Nummer:*" -anchor w
    entry $dialog.main.wbk_nummer_entry -font {Arial 11}
    grid $dialog.main.wbk_nummer_label -row 3 -column 0 -sticky w -pady 5
    grid $dialog.main.wbk_nummer_entry -row 3 -column 1 -sticky ew -pady 5

    # Zeile 4: Hersteller (optional)
    label $dialog.main.hersteller_label -text "Hersteller:" -anchor w
    entry $dialog.main.hersteller_entry -font {Arial 11}
    grid $dialog.main.hersteller_label -row 4 -column 0 -sticky w -pady 5
    grid $dialog.main.hersteller_entry -row 4 -column 1 -sticky ew -pady 5

    # Zeile 5: Ausstellende Behörde (optional, aus behoerde.json vorausgefüllt)
    label $dialog.main.behoerde_label -text "Ausstellende Behörde:" -anchor w
    entry $dialog.main.behoerde_entry -font {Arial 11}
    grid $dialog.main.behoerde_label -row 5 -column 0 -sticky w -pady 5
    grid $dialog.main.behoerde_entry -row 5 -column 1 -sticky ew -pady 5

    # Vorausfüllen mit Behördennamen aus behoerde.json
    set behoerde_name [::waffenregister::lade_behoerde_name]
    $dialog.main.behoerde_entry insert 0 $behoerde_name

    # Zeile 6: Bemerkungen (optional, mehrzeilig)
    label $dialog.main.bemerkungen_label -text "Bemerkungen:" -anchor nw
    text $dialog.main.bemerkungen_text -font {Arial 11} -height 4 -width 30 -wrap word
    scrollbar $dialog.main.bemerkungen_scroll -command "$dialog.main.bemerkungen_text yview"
    $dialog.main.bemerkungen_text configure -yscrollcommand "$dialog.main.bemerkungen_scroll set"
    grid $dialog.main.bemerkungen_label -row 6 -column 0 -sticky nw -pady 5
    grid $dialog.main.bemerkungen_text -row 6 -column 1 -sticky ew -pady 5

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure $dialog.main 1 -weight 1

    # Zeile 7: Hinweis für Pflichtfelder
    label $dialog.main.hinweis -text "* Pflichtfelder" -fg "#666666" -font {Arial 9 italic}
    grid $dialog.main.hinweis -row 7 -column 0 -columnspan 2 -sticky w -pady 10

    # === Button-Frame ===
    frame $dialog.button_frame -pady 10
    pack $dialog.button_frame -side bottom -fill x -padx 20

    # Hinzufügen-Button (grün, links)
    button $dialog.button_frame.hinzufuegen -text "Hinzufügen" -bg "#90EE90" -width 12 \
        -command [list ::waffenregister::speichere_neue_waffe $dialog]
    pack $dialog.button_frame.hinzufuegen -side left -padx 5

    # Abbrechen-Button (rot, rechts)
    button $dialog.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 12 \
        -command "destroy $dialog"
    pack $dialog.button_frame.abbrechen -side right -padx 5

    # Fokus auf erstes Eingabefeld
    focus $dialog.main.art_entry
}

# =============================================================================
# Prozedur: oeffne_loeschen_dialog
# Öffnet einen Bestätigungsdialog zum Löschen einer Waffe
# =============================================================================
proc ::waffenregister::oeffne_loeschen_dialog {} {
    variable fenster
    variable waffen_liste
    variable ausgewaehlter_index

    # Prüfen ob eine Waffe ausgewählt ist
    if {$ausgewaehlter_index < 0 || $ausgewaehlter_index >= [llength $waffen_liste]} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte wählen Sie eine Waffe aus der Liste aus."
        return
    }

    # Ausgewählte Waffe holen
    set waffe [lindex $waffen_liste $ausgewaehlter_index]
    set art [dict get $waffe art]
    set seriennummer [dict get $waffe seriennummer]

    # Bestätigung einholen
    set antwort [tk_messageBox -parent $fenster -icon question -title "Löschen bestätigen" \
        -type yesno \
        -message "Möchten Sie die Waffe \"$art\" (Seriennr.: $seriennummer) wirklich löschen?"]

    if {$antwort eq "no"} {
        return
    }

    # Waffe aus der Liste entfernen
    set waffen_liste [lreplace $waffen_liste $ausgewaehlter_index $ausgewaehlter_index]

    # In JSON-Datei speichern
    speichere_waffenregister $waffen_liste

    # Auswahl zurücksetzen
    set ausgewaehlter_index -1

    # Anzeige aktualisieren
    aktualisiere_waffen_anzeige

    # Löschen-Button deaktivieren
    $fenster.button_frame.loeschen configure -state disabled

    # Erfolgs-Nachricht
    tk_messageBox -parent $fenster -icon info -title "Erfolgreich" \
        -message "Die Waffe wurde erfolgreich gelöscht."
}

# =============================================================================
# Prozedur: open_waffenregister_dialog
# Öffnet den Waffenregister-Dialog
# =============================================================================
proc open_waffenregister_dialog {} {
    # Dialog-Fenster definieren
    set w .waffenregister
    set ::waffenregister::fenster $w

    # Prüfen, ob Dialog bereits offen ist
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    # Waffenliste laden
    set ::waffenregister::waffen_liste [::waffenregister::lade_waffenregister]

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Waffenregister"
    wm geometry $w "1200x600"
    wm resizable $w 1 1

    # Schriftgröße für Treeview-Widget konfigurieren (11 Punkte)
    ttk::style configure Treeview -font {TkDefaultFont 11} -rowheight 22

    # Hauptframe
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # Header
    label $w.main.header -text "Vereinswaffen" -font {Arial 12 bold}
    pack $w.main.header -pady {0 10}

    # === Treeview mit Scrollbars ===
    frame $w.main.tree_frame
    pack $w.main.tree_frame -fill both -expand 1 -pady 10

    # Vertikale Scrollbar
    scrollbar $w.main.tree_frame.yscroll -command {.waffenregister.main.tree yview} -orient vertical
    pack $w.main.tree_frame.yscroll -side right -fill y

    # Horizontale Scrollbar
    scrollbar $w.main.tree_frame.xscroll -command {.waffenregister.main.tree xview} -orient horizontal
    pack $w.main.tree_frame.xscroll -side bottom -fill x

    # Treeview-Widget mit Spalten für Waffendaten
    ttk::treeview $w.main.tree \
        -columns {art kaliber seriennummer wbk_nummer hersteller behoerde bemerkungen} \
        -show headings \
        -selectmode browse \
        -yscrollcommand {.waffenregister.main.tree_frame.yscroll set} \
        -xscrollcommand {.waffenregister.main.tree_frame.xscroll set}

    # Spaltenüberschriften definieren
    $w.main.tree heading art -text "Art der Waffe"
    $w.main.tree heading kaliber -text "Kaliber"
    $w.main.tree heading seriennummer -text "Seriennummer"
    $w.main.tree heading wbk_nummer -text "WBK-Nummer"
    $w.main.tree heading hersteller -text "Hersteller"
    $w.main.tree heading behoerde -text "Ausst. Behörde"
    $w.main.tree heading bemerkungen -text "Bemerkungen"

    # Spaltenbreiten festlegen (in Pixeln)
    $w.main.tree column art -width 150 -anchor w
    $w.main.tree column kaliber -width 100 -anchor w
    $w.main.tree column seriennummer -width 150 -anchor w
    $w.main.tree column wbk_nummer -width 120 -anchor w
    $w.main.tree column hersteller -width 120 -anchor w
    $w.main.tree column behoerde -width 150 -anchor w
    $w.main.tree column bemerkungen -width 200 -anchor w

    pack $w.main.tree -in $w.main.tree_frame -fill both -expand 1

    # Bindings für Treeview
    bind $w.main.tree <<TreeviewSelect>> {::waffenregister::treeview_auswahl_geaendert}

    # === Button-Frame ===
    frame $w.button_frame -pady 10
    pack $w.button_frame -side bottom -fill x -padx 20

    # Hinzufügen-Button (grün, links)
    button $w.button_frame.hinzufuegen -text "Hinzufügen" -bg "#90EE90" -width 15 \
        -command ::waffenregister::oeffne_hinzufuegen_dialog
    pack $w.button_frame.hinzufuegen -side left -padx 5

    # Löschen-Button (rot, mitte, initial disabled)
    button $w.button_frame.loeschen -text "Löschen" -bg "#FFB6C1" -width 15 \
        -state disabled \
        -command ::waffenregister::oeffne_loeschen_dialog
    pack $w.button_frame.loeschen -side left -padx 5

    # Abbrechen-Button (blau, rechts)
    button $w.button_frame.abbrechen -text "Schließen" -bg "#4ACEFA" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Initiale Anzeige aktualisieren
    ::waffenregister::aktualisiere_waffen_anzeige

    # Fokus auf das Fenster setzen
    focus $w
}
