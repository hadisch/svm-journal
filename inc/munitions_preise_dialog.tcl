# =============================================================================
# Munitions-Preise-Dialog
# Ermöglicht die Verwaltung der Kaliber und deren Preise
# =============================================================================

# Namespace für Munitionspreise-Verwaltung
namespace eval ::munpreise {
    # Dialog-Variablen
    variable fenster ""
    variable kaliber_liste [list]
    variable ausgewaehlter_index -1
}

# =============================================================================
# Prozedur: lade_kaliber_preise
# Lädt alle Kaliber und Preise aus der JSON-Datei
# Rückgabe: Liste von {kaliber preis} Paaren
# =============================================================================
proc ::munpreise::lade_kaliber_preise {} {
    global kaliber_preise_json

    set kaliber_liste [list]

    # Prüfen, ob Datei existiert
    if {![file exists $kaliber_preise_json]} {
        return $kaliber_liste
    }

    # Datei öffnen und parsen
    set fp [open $kaliber_preise_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Kaliber und Preise extrahieren
    set lines [split $json_content "\n"]
    set aktuelles_kaliber ""
    set aktueller_preis ""

    foreach line $lines {
        # Kaliber extrahieren
        if {[regexp {"kaliber":\s*"([^"]*)"} $line -> kaliber]} {
            set aktuelles_kaliber [string trim $kaliber]
        }
        # Preis extrahieren
        if {[regexp {"preis":\s*"([^"]*)"} $line -> preis]} {
            set aktueller_preis [string trim $preis]

            # Wenn beide vorhanden, zur Liste hinzufügen
            if {$aktuelles_kaliber ne "" && $aktueller_preis ne ""} {
                lappend kaliber_liste [list $aktuelles_kaliber $aktueller_preis]
                set aktuelles_kaliber ""
                set aktueller_preis ""
            }
        }
    }

    return $kaliber_liste
}

# =============================================================================
# Prozedur: speichere_kaliber_preise
# Speichert die Kaliber-Preise in die JSON-Datei
# Parameter:
#   kaliber_liste - Liste von {kaliber preis} Paaren
# =============================================================================
proc ::munpreise::speichere_kaliber_preise {kaliber_liste} {
    global kaliber_preise_json

    # JSON-Datei schreiben
    set lines [list]
    lappend lines "\{"
    lappend lines "  \"kaliber-preise\": \["

    set anzahl [llength $kaliber_liste]
    set counter 0

    # Kaliber alphabetisch sortieren
    set kaliber_liste [lsort -dictionary -index 0 $kaliber_liste]

    foreach kaliber_preis $kaliber_liste {
        lassign $kaliber_preis kaliber preis

        lappend lines "    \{"
        lappend lines "      \"kaliber\": \"$kaliber\","
        lappend lines "      \"preis\": \"$preis\""

        incr counter
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
    set fp [open $kaliber_preise_json w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp
}

# =============================================================================
# Prozedur: aktualisiere_kaliber_anzeige
# Aktualisiert die Listbox mit allen Kalibern und Preisen
# =============================================================================
proc ::munpreise::aktualisiere_kaliber_anzeige {} {
    variable fenster
    variable kaliber_liste

    # Listbox leeren
    $fenster.main.listbox delete 0 end

    # Kaliber zur Listbox hinzufügen
    foreach kaliber_preis $kaliber_liste {
        lassign $kaliber_preis kaliber preis
        # Formatierte Zeile: Kaliber (linksbündig, 30 Zeichen) | Preis (rechtsbündig)
        set line [format "%-30s  %s €" $kaliber $preis]
        $fenster.main.listbox insert end $line
    }
}

# =============================================================================
# Prozedur: listbox_auswahl_geaendert
# Wird aufgerufen, wenn eine Auswahl in der Listbox geändert wird
# =============================================================================
proc ::munpreise::listbox_auswahl_geaendert {} {
    variable fenster
    variable ausgewaehlter_index

    # Aktuell ausgewählten Index holen
    set selection [$fenster.main.listbox curselection]

    if {$selection ne "" && [llength $selection] > 0} {
        set ausgewaehlter_index [lindex $selection 0]
        # Bearbeiten-Button aktivieren
        $fenster.button_frame.bearbeiten configure -state normal
    } else {
        set ausgewaehlter_index -1
        # Bearbeiten-Button deaktivieren
        $fenster.button_frame.bearbeiten configure -state disabled
    }
}

# =============================================================================
# Prozedur: oeffne_bearbeiten_dialog
# Öffnet einen Dialog zum Bearbeiten des Preises eines Kalibers
# =============================================================================
proc ::munpreise::oeffne_bearbeiten_dialog {} {
    variable fenster
    variable kaliber_liste
    variable ausgewaehlter_index

    # Prüfen ob ein Kaliber ausgewählt ist
    if {$ausgewaehlter_index < 0} {
        return
    }

    # Ausgewähltes Kaliber holen
    set kaliber_preis [lindex $kaliber_liste $ausgewaehlter_index]
    lassign $kaliber_preis alt_kaliber alt_preis

    # Dialog-Fenster erstellen
    set w .munpreise_bearbeiten

    if {[winfo exists $w]} {
        destroy $w
    }

    toplevel $w
    wm title $w "Preis bearbeiten"
    wm geometry $w "400x150"
    wm transient $w $fenster

    # Hauptframe
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # Kaliber-Anzeige (nicht bearbeitbar)
    label $w.main.kaliber_label -text "Kaliber:" -anchor w
    label $w.main.kaliber_wert -text $alt_kaliber -anchor w -font {Arial 11 bold}
    grid $w.main.kaliber_label -row 0 -column 0 -sticky w -pady 5
    grid $w.main.kaliber_wert -row 0 -column 1 -sticky w -pady 5

    # Preis-Eingabefeld
    label $w.main.preis_label -text "Preis (€):" -anchor w
    entry $w.main.preis_entry -font {Arial 11}
    $w.main.preis_entry insert 0 $alt_preis
    grid $w.main.preis_label -row 1 -column 0 -sticky w -pady 5
    grid $w.main.preis_entry -row 1 -column 1 -sticky ew -pady 5

    grid columnconfigure $w.main 1 -weight 1

    # Button-Frame
    frame $w.button_frame
    pack $w.button_frame -side bottom -fill x -pady 10 -padx 20

    # Speichern-Button
    button $w.button_frame.speichern -text "Speichern" -bg "#90EE90" -width 12 \
        -command [list ::munpreise::speichere_bearbeiteten_preis $w $alt_kaliber]
    pack $w.button_frame.speichern -side left -padx 5

    # Abbrechen-Button
    button $w.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 12 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Focus auf Preis-Eingabefeld
    focus $w.main.preis_entry
    $w.main.preis_entry selection range 0 end
}

# =============================================================================
# Prozedur: speichere_bearbeiteten_preis
# Speichert den bearbeiteten Preis eines Kalibers
# Parameter:
#   dialog_fenster - Fenster des Bearbeiten-Dialogs
#   kaliber - Name des Kalibers
# =============================================================================
proc ::munpreise::speichere_bearbeiteten_preis {dialog_fenster kaliber} {
    variable kaliber_liste

    # Neuen Preis aus Eingabefeld holen
    set neuer_preis [string trim [$dialog_fenster.main.preis_entry get]]

    # Validierung
    if {$neuer_preis eq ""} {
        tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie einen Preis ein."
        return
    }

    # Kaliber in der Liste finden und Preis aktualisieren
    set neue_liste [list]
    foreach kaliber_preis $kaliber_liste {
        lassign $kaliber_preis k p
        if {$k eq $kaliber} {
            # Preis aktualisieren
            lappend neue_liste [list $k $neuer_preis]
        } else {
            # Unverändert übernehmen
            lappend neue_liste [list $k $p]
        }
    }

    # Liste aktualisieren
    set kaliber_liste $neue_liste

    # In JSON-Datei speichern
    speichere_kaliber_preise $kaliber_liste

    # Anzeige aktualisieren
    aktualisiere_kaliber_anzeige

    # Dialog schließen
    destroy $dialog_fenster

    # Erfolgs-Meldung
    tk_messageBox -parent $::munpreise::fenster -icon info -title "Erfolgreich" \
        -message "Der Preis für \"$kaliber\" wurde erfolgreich geändert."
}

# =============================================================================
# Prozedur: oeffne_neues_kaliber_dialog
# Öffnet einen Dialog zum Hinzufügen eines neuen Kalibers
# =============================================================================
proc ::munpreise::oeffne_neues_kaliber_dialog {} {
    variable fenster

    # Dialog-Fenster erstellen
    set w .munpreise_neu

    if {[winfo exists $w]} {
        destroy $w
    }

    toplevel $w
    wm title $w "Neues Kaliber hinzufügen"
    wm geometry $w "400x210"
    wm transient $w $fenster

    # Hauptframe
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # Kaliber-Eingabefeld
    label $w.main.kaliber_label -text "Kaliber:*" -anchor w
    entry $w.main.kaliber_entry -font {Arial 11}
    grid $w.main.kaliber_label -row 0 -column 0 -sticky w -pady 5
    grid $w.main.kaliber_entry -row 0 -column 1 -sticky ew -pady 5

    # Preis-Eingabefeld
    label $w.main.preis_label -text "Preis (€):*" -anchor w
    entry $w.main.preis_entry -font {Arial 11}
    grid $w.main.preis_label -row 1 -column 0 -sticky w -pady 5
    grid $w.main.preis_entry -row 1 -column 1 -sticky ew -pady 5

    # Hinweis
    label $w.main.hinweis -text "* Pflichtfelder" -fg "#666666" -font {Arial 9 italic}
    grid $w.main.hinweis -row 2 -column 0 -columnspan 2 -sticky w -pady 10

    grid columnconfigure $w.main 1 -weight 1

    # Button-Frame
    frame $w.button_frame
    pack $w.button_frame -side bottom -fill x -pady 10 -padx 20

    # Speichern-Button
    button $w.button_frame.speichern -text "Hinzufügen" -bg "#90EE90" -width 12 \
        -command [list ::munpreise::speichere_neues_kaliber $w]
    pack $w.button_frame.speichern -side left -padx 5

    # Abbrechen-Button
    button $w.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 12 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Focus auf Kaliber-Eingabefeld
    focus $w.main.kaliber_entry
}

# =============================================================================
# Prozedur: speichere_neues_kaliber
# Speichert ein neues Kaliber mit Preis
# Parameter:
#   dialog_fenster - Fenster des Neu-Dialogs
# =============================================================================
proc ::munpreise::speichere_neues_kaliber {dialog_fenster} {
    variable kaliber_liste

    # Werte aus Eingabefeldern holen
    set neues_kaliber [string trim [$dialog_fenster.main.kaliber_entry get]]
    set neuer_preis [string trim [$dialog_fenster.main.preis_entry get]]

    # Validierung
    if {$neues_kaliber eq ""} {
        tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie ein Kaliber ein."
        return
    }

    if {$neuer_preis eq ""} {
        tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie einen Preis ein."
        return
    }

    # Prüfen ob Kaliber bereits existiert
    foreach kaliber_preis $kaliber_liste {
        lassign $kaliber_preis k p
        if {[string equal -nocase $k $neues_kaliber]} {
            tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
                -message "Das Kaliber \"$k\" existiert bereits.\n\nBitte verwenden Sie den Bearbeiten-Button, um den Preis zu ändern."
            return
        }
    }

    # Neues Kaliber zur Liste hinzufügen
    lappend kaliber_liste [list $neues_kaliber $neuer_preis]

    # In JSON-Datei speichern
    speichere_kaliber_preise $kaliber_liste

    # Anzeige aktualisieren
    aktualisiere_kaliber_anzeige

    # Dialog schließen
    destroy $dialog_fenster

    # Erfolgs-Meldung
    tk_messageBox -parent $::munpreise::fenster -icon info -title "Erfolgreich" \
        -message "Das Kaliber \"$neues_kaliber\" wurde erfolgreich hinzugefügt."
}

# =============================================================================
# Prozedur: open_munitions_preise_dialog
# Öffnet das Hauptfenster für die Munitionspreise-Verwaltung
# =============================================================================
proc open_munitions_preise_dialog {} {
    # Kaliber-Preise laden
    set ::munpreise::kaliber_liste [::munpreise::lade_kaliber_preise]

    # Toplevel-Fenster erstellen
    set w .munpreise
    set ::munpreise::fenster $w

    # Falls Fenster bereits existiert, in den Vordergrund bringen
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    toplevel $w
    wm title $w "Munitionspreise verwalten"
    wm geometry $w "600x500"

    # Hauptframe
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # Header-Label
    label $w.main.header -text "Kaliber und Preise" -font {Arial 12 bold}
    pack $w.main.header -anchor w -pady 5

    # Frame für Listbox mit Scrollbar
    frame $w.main.list_frame
    pack $w.main.list_frame -fill both -expand 1 -pady 10

    # Scrollbar
    scrollbar $w.main.list_frame.scroll -command {.munpreise.main.listbox yview}
    pack $w.main.list_frame.scroll -side right -fill y

    # Listbox für Kaliber und Preise
    listbox $w.main.listbox -yscrollcommand {.munpreise.main.list_frame.scroll set} \
        -font {Courier 11} -height 15
    pack $w.main.listbox -in $w.main.list_frame -fill both -expand 1

    # Binding für Auswahl-Änderung
    bind $w.main.listbox <<ListboxSelect>> {::munpreise::listbox_auswahl_geaendert}

    # Doppelklick zum Bearbeiten
    bind $w.main.listbox <Double-Button-1> {::munpreise::oeffne_bearbeiten_dialog}

    # Button-Frame
    frame $w.button_frame -pady 10
    pack $w.button_frame -side bottom -fill x -padx 20

    # Button "Bearbeiten" - initial deaktiviert
    button $w.button_frame.bearbeiten -text "Preis ändern" -bg "#FDF1AF" -width 15 \
        -command ::munpreise::oeffne_bearbeiten_dialog -state disabled
    pack $w.button_frame.bearbeiten -side left -padx 5

    # Button "Neu"
    button $w.button_frame.neu -text "Neues Kaliber" -bg "#90EE90" -width 15 \
        -command ::munpreise::oeffne_neues_kaliber_dialog
    pack $w.button_frame.neu -side left -padx 5

    # Button "Schließen"
    button $w.button_frame.schliessen -text "Schließen" -bg "#4ACEFA" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.schliessen -side right -padx 5

    # Kaliber-Anzeige aktualisieren
    ::munpreise::aktualisiere_kaliber_anzeige

    # Focus auf Fenster
    focus $w
}
