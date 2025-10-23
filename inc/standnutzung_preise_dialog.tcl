# =============================================================================
# Standnutzungs-Preise-Dialog
# Ermöglicht die Verwaltung der Standnutzungskategorien und deren Preise
# =============================================================================

# Namespace für Standnutzungspreise-Verwaltung
namespace eval ::standpreise {
    # Dialog-Variablen
    variable fenster ""
    variable kategorie_liste [list]
    variable ausgewaehlter_index -1
}

# =============================================================================
# Prozedur: lade_standnutzung_preise
# Lädt alle Kategorien und Preise aus der JSON-Datei
# Rückgabe: Liste von {kategorie preis} Paaren
# =============================================================================
proc ::standpreise::lade_standnutzung_preise {} {
    global stand_nutzung_json

    set kategorie_liste [list]

    # Prüfen, ob Datei existiert
    if {![file exists $stand_nutzung_json]} {
        return $kategorie_liste
    }

    # Datei öffnen und parsen
    set fp [open $stand_nutzung_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Kategorien und Preise extrahieren
    set lines [split $json_content "\n"]

    foreach line $lines {
        # Jede Kategorie-Preis-Zeile extrahieren (Format: "Kategorie": "Preis")
        if {[regexp {"([^"]+)":\s*"([^"]*)"} $line -> kategorie preis]} {
            set kategorie [string trim $kategorie]
            set preis [string trim $preis]

            # Zur Liste hinzufügen
            lappend kategorie_liste [list $kategorie $preis]
        }
    }

    return $kategorie_liste
}

# =============================================================================
# Prozedur: speichere_standnutzung_preise
# Speichert die Standnutzungs-Preise in die JSON-Datei
# Parameter:
#   kategorie_liste - Liste von {kategorie preis} Paaren
# =============================================================================
proc ::standpreise::speichere_standnutzung_preise {kategorie_liste} {
    global stand_nutzung_json

    # JSON-Datei schreiben
    set lines [list]
    lappend lines "\{"
    lappend lines "\t\"stand-nutzung\": \["
    lappend lines "    \{"

    set anzahl [llength $kategorie_liste]
    set counter 0

    # Kategorien in der ursprünglichen Reihenfolge beibehalten
    foreach kategorie_preis $kategorie_liste {
        lassign $kategorie_preis kategorie preis

        incr counter
        if {$counter < $anzahl} {
            lappend lines "\t  \"$kategorie\": \"$preis\","
        } else {
            lappend lines "      \"$kategorie\": \"$preis\""
        }
    }

    lappend lines "    \}"
    lappend lines "\t\]"
    lappend lines "\}"

    set json_content [join $lines "\n"]

    # Datei schreiben
    set fp [open $stand_nutzung_json w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp
}

# =============================================================================
# Prozedur: aktualisiere_kategorie_anzeige
# Aktualisiert die Listbox mit allen Kategorien und Preisen
# =============================================================================
proc ::standpreise::aktualisiere_kategorie_anzeige {} {
    variable fenster
    variable kategorie_liste

    # Listbox leeren
    $fenster.main.listbox delete 0 end

    # Kategorien zur Listbox hinzufügen
    foreach kategorie_preis $kategorie_liste {
        lassign $kategorie_preis kategorie preis
        # Formatierte Zeile: Kategorie (linksbündig, 30 Zeichen) | Preis (rechtsbündig)
        set line [format "%-30s  %s €" $kategorie $preis]
        $fenster.main.listbox insert end $line
    }
}

# =============================================================================
# Prozedur: listbox_auswahl_geaendert
# Wird aufgerufen, wenn eine Auswahl in der Listbox geändert wird
# =============================================================================
proc ::standpreise::listbox_auswahl_geaendert {} {
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
# Öffnet einen Dialog zum Bearbeiten des Preises einer Kategorie
# =============================================================================
proc ::standpreise::oeffne_bearbeiten_dialog {} {
    variable fenster
    variable kategorie_liste
    variable ausgewaehlter_index

    # Prüfen ob eine Kategorie ausgewählt ist
    if {$ausgewaehlter_index < 0} {
        return
    }

    # Ausgewählte Kategorie holen
    set kategorie_preis [lindex $kategorie_liste $ausgewaehlter_index]
    lassign $kategorie_preis alt_kategorie alt_preis

    # Dialog-Fenster erstellen
    set w .standpreise_bearbeiten

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

    # Kategorie-Anzeige (nicht bearbeitbar)
    label $w.main.kategorie_label -text "Kategorie:" -anchor w
    label $w.main.kategorie_wert -text $alt_kategorie -anchor w -font {Arial 11 bold}
    grid $w.main.kategorie_label -row 0 -column 0 -sticky w -pady 5
    grid $w.main.kategorie_wert -row 0 -column 1 -sticky w -pady 5

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
        -command [list ::standpreise::speichere_bearbeiteten_preis $w $alt_kategorie]
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
# Speichert den bearbeiteten Preis einer Kategorie
# Parameter:
#   dialog_fenster - Fenster des Bearbeiten-Dialogs
#   kategorie - Name der Kategorie
# =============================================================================
proc ::standpreise::speichere_bearbeiteten_preis {dialog_fenster kategorie} {
    variable kategorie_liste

    # Neuen Preis aus Eingabefeld holen
    set neuer_preis [string trim [$dialog_fenster.main.preis_entry get]]

    # Validierung
    if {$neuer_preis eq ""} {
        tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie einen Preis ein."
        return
    }

    # Kategorie in der Liste finden und Preis aktualisieren
    set neue_liste [list]
    foreach kategorie_preis $kategorie_liste {
        lassign $kategorie_preis k p
        if {$k eq $kategorie} {
            # Preis aktualisieren
            lappend neue_liste [list $k $neuer_preis]
        } else {
            # Unverändert übernehmen
            lappend neue_liste [list $k $p]
        }
    }

    # Liste aktualisieren
    set kategorie_liste $neue_liste

    # In JSON-Datei speichern
    speichere_standnutzung_preise $kategorie_liste

    # Anzeige aktualisieren
    aktualisiere_kategorie_anzeige

    # Dialog schließen
    destroy $dialog_fenster

    # Erfolgs-Meldung
    tk_messageBox -parent $::standpreise::fenster -icon info -title "Erfolgreich" \
        -message "Der Preis für \"$kategorie\" wurde erfolgreich geändert."
}

# =============================================================================
# Prozedur: oeffne_neue_kategorie_dialog
# Öffnet einen Dialog zum Hinzufügen einer neuen Kategorie
# =============================================================================
proc ::standpreise::oeffne_neue_kategorie_dialog {} {
    variable fenster

    # Dialog-Fenster erstellen
    set w .standpreise_neu

    if {[winfo exists $w]} {
        destroy $w
    }

    toplevel $w
    wm title $w "Neue Kategorie hinzufügen"
    wm geometry $w "400x210"
    wm transient $w $fenster

    # Hauptframe
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # Kategorie-Eingabefeld
    label $w.main.kategorie_label -text "Kategorie:*" -anchor w
    entry $w.main.kategorie_entry -font {Arial 11}
    grid $w.main.kategorie_label -row 0 -column 0 -sticky w -pady 5
    grid $w.main.kategorie_entry -row 0 -column 1 -sticky ew -pady 5

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
        -command [list ::standpreise::speichere_neue_kategorie $w]
    pack $w.button_frame.speichern -side left -padx 5

    # Abbrechen-Button
    button $w.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 12 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Focus auf Kategorie-Eingabefeld
    focus $w.main.kategorie_entry
}

# =============================================================================
# Prozedur: speichere_neue_kategorie
# Speichert eine neue Kategorie mit Preis
# Parameter:
#   dialog_fenster - Fenster des Neu-Dialogs
# =============================================================================
proc ::standpreise::speichere_neue_kategorie {dialog_fenster} {
    variable kategorie_liste

    # Werte aus Eingabefeldern holen
    set neue_kategorie [string trim [$dialog_fenster.main.kategorie_entry get]]
    set neuer_preis [string trim [$dialog_fenster.main.preis_entry get]]

    # Validierung
    if {$neue_kategorie eq ""} {
        tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie eine Kategorie ein."
        return
    }

    if {$neuer_preis eq ""} {
        tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie einen Preis ein."
        return
    }

    # Prüfen ob Kategorie bereits existiert
    foreach kategorie_preis $kategorie_liste {
        lassign $kategorie_preis k p
        if {[string equal -nocase $k $neue_kategorie]} {
            tk_messageBox -parent $dialog_fenster -icon warning -title "Fehler" \
                -message "Die Kategorie \"$k\" existiert bereits.\n\nBitte verwenden Sie den Bearbeiten-Button, um den Preis zu ändern."
            return
        }
    }

    # Neue Kategorie zur Liste hinzufügen
    lappend kategorie_liste [list $neue_kategorie $neuer_preis]

    # In JSON-Datei speichern
    speichere_standnutzung_preise $kategorie_liste

    # Anzeige aktualisieren
    aktualisiere_kategorie_anzeige

    # Dialog schließen
    destroy $dialog_fenster

    # Erfolgs-Meldung
    tk_messageBox -parent $::standpreise::fenster -icon info -title "Erfolgreich" \
        -message "Die Kategorie \"$neue_kategorie\" wurde erfolgreich hinzugefügt."
}

# =============================================================================
# Prozedur: open_standnutzung_preise_dialog
# Öffnet das Hauptfenster für die Standnutzungspreise-Verwaltung
# =============================================================================
proc open_standnutzung_preise_dialog {} {
    # Standnutzungs-Preise laden
    set ::standpreise::kategorie_liste [::standpreise::lade_standnutzung_preise]

    # Toplevel-Fenster erstellen
    set w .standpreise
    set ::standpreise::fenster $w

    # Falls Fenster bereits existiert, in den Vordergrund bringen
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    toplevel $w
    wm title $w "Standnutzungspreise verwalten"
    wm geometry $w "600x500"

    # Hauptframe
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # Header-Label
    label $w.main.header -text "Kategorien und Preise" -font {Arial 12 bold}
    pack $w.main.header -anchor w -pady 5

    # Frame für Listbox mit Scrollbar
    frame $w.main.list_frame
    pack $w.main.list_frame -fill both -expand 1 -pady 10

    # Scrollbar
    scrollbar $w.main.list_frame.scroll -command {.standpreise.main.listbox yview}
    pack $w.main.list_frame.scroll -side right -fill y

    # Listbox für Kategorien und Preise
    listbox $w.main.listbox -yscrollcommand {.standpreise.main.list_frame.scroll set} \
        -font {Courier 11} -height 15
    pack $w.main.listbox -in $w.main.list_frame -fill both -expand 1

    # Binding für Auswahl-Änderung
    bind $w.main.listbox <<ListboxSelect>> {::standpreise::listbox_auswahl_geaendert}

    # Doppelklick zum Bearbeiten
    bind $w.main.listbox <Double-Button-1> {::standpreise::oeffne_bearbeiten_dialog}

    # Button-Frame
    frame $w.button_frame -pady 10
    pack $w.button_frame -side bottom -fill x -padx 20

    # Button "Bearbeiten" - initial deaktiviert
    button $w.button_frame.bearbeiten -text "Preis ändern" -bg "#FDF1AF" -width 15 \
        -command ::standpreise::oeffne_bearbeiten_dialog -state disabled
    pack $w.button_frame.bearbeiten -side left -padx 5

    # Button "Neu"
    button $w.button_frame.neu -text "Neue Kategorie" -bg "#90EE90" -width 15 \
        -command ::standpreise::oeffne_neue_kategorie_dialog
    pack $w.button_frame.neu -side left -padx 5

    # Button "Schließen"
    button $w.button_frame.schliessen -text "Schließen" -bg "#4ACEFA" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.schliessen -side right -padx 5

    # Kategorie-Anzeige aktualisieren
    ::standpreise::aktualisiere_kategorie_anzeige

    # Focus auf Fenster
    focus $w
}
