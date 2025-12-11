# =============================================================================
# Behörden-Dialog
# Ermöglicht die Verwaltung der Behördendaten (zuständige Waffenbehörde)
# Es kann nur ein Behördeneintrag verwaltet werden
# =============================================================================

# Namespace für Behördendaten-Verwaltung
namespace eval ::behoerde {
    # Dialog-Variablen
    variable fenster ""
    variable name ""
    variable plz ""
    variable ort ""
    variable telefon ""
    variable fax ""
    variable email ""
}

# =============================================================================
# Prozedur: lade_behoerde_daten
# Lädt die Behördendaten aus der JSON-Datei
# Füllt die Namespace-Variablen mit den gespeicherten Werten
# =============================================================================
proc ::behoerde::lade_behoerde_daten {} {
    global behoerde_json

    # Variablen initialisieren
    variable name
    variable plz
    variable ort
    variable telefon
    variable fax
    variable email

    # Alle Felder zurücksetzen
    set name ""
    set plz ""
    set ort ""
    set telefon ""
    set fax ""
    set email ""

    # Prüfen, ob Datei existiert
    if {![file exists $behoerde_json]} {
        return
    }

    # Datei öffnen und parsen
    set fp [open $behoerde_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Behördendaten extrahieren
    set lines [split $json_content "\n"]

    foreach line $lines {
        # Name extrahieren
        if {[regexp {"name":\s*"([^"]*)"} $line -> wert]} {
            set name [string trim $wert]
        }
        # PLZ extrahieren
        if {[regexp {"plz":\s*"([^"]*)"} $line -> wert]} {
            set plz [string trim $wert]
        }
        # Ort extrahieren
        if {[regexp {"ort":\s*"([^"]*)"} $line -> wert]} {
            set ort [string trim $wert]
        }
        # Telefon extrahieren
        if {[regexp {"telefon":\s*"([^"]*)"} $line -> wert]} {
            set telefon [string trim $wert]
        }
        # Fax extrahieren
        if {[regexp {"fax":\s*"([^"]*)"} $line -> wert]} {
            set fax [string trim $wert]
        }
        # Email extrahieren
        if {[regexp {"email":\s*"([^"]*)"} $line -> wert]} {
            set email [string trim $wert]
        }
    }
}

# =============================================================================
# Prozedur: speichere_behoerde_daten
# Speichert die Behördendaten in die JSON-Datei
# Validiert, dass alle Felder ausgefüllt sind (alle sind Pflichtfelder)
# =============================================================================
proc ::behoerde::speichere_behoerde_daten {} {
    global behoerde_json

    # Variablen holen
    variable fenster
    variable name
    variable plz
    variable ort
    variable telefon
    variable fax
    variable email

    # Alle Felder trimmen
    set name [string trim $name]
    set plz [string trim $plz]
    set ort [string trim $ort]
    set telefon [string trim $telefon]
    set fax [string trim $fax]
    set email [string trim $email]

    # Alle Pflichtfelder einzeln validieren
    if {$name eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie den Namen der Behörde ein."
        return
    }
    if {$plz eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie die PLZ ein."
        return
    }
    if {$ort eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie den Ort ein."
        return
    }
    if {$telefon eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie die Telefonnummer ein."
        return
    }
    # Fax ist optional - keine Validierung
    if {$email eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie die E-Mail-Adresse ein."
        return
    }

    # JSON-Datei aufbauen
    set lines [list]
    lappend lines "\{"
    lappend lines "  \"name\": \"$name\","
    lappend lines "  \"plz\": \"$plz\","
    lappend lines "  \"ort\": \"$ort\","
    lappend lines "  \"telefon\": \"$telefon\","
    lappend lines "  \"fax\": \"$fax\","
    lappend lines "  \"email\": \"$email\""
    lappend lines "\}"

    set json_content [join $lines "\n"]

    # Datei schreiben
    set fp [open $behoerde_json w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp

    # Erfolgsmeldung anzeigen
    tk_messageBox -parent $fenster -icon info -title "Erfolgreich" \
        -message "Die Behördendaten wurden erfolgreich gespeichert."

    # Fenster schließen
    destroy $fenster
}

# =============================================================================
# Prozedur: open_behoerde_dialog
# Öffnet den Behördendaten-Dialog
# Lädt existierende Daten oder zeigt leeres Formular
# =============================================================================
proc open_behoerde_dialog {} {
    # Dialog-Fenster definieren
    set w .behoerde
    set ::behoerde::fenster $w

    # Prüfen, ob Dialog bereits offen ist
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    # Daten laden
    ::behoerde::lade_behoerde_daten

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Behördendaten"
    wm geometry $w "550x420"
    wm resizable $w 0 0

    # Hauptframe erstellen
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # === Eingabefelder im Grid-Layout ===

    # Zeile 0: Name der Behörde (Pflichtfeld)
    label $w.main.name_label -text "Name der Behörde:*" -anchor w
    entry $w.main.name_entry -textvariable ::behoerde::name -font {Arial 11}
    grid $w.main.name_label -row 0 -column 0 -sticky w -pady 5
    grid $w.main.name_entry -row 0 -column 1 -sticky ew -pady 5

    # Zeile 1: PLZ (Pflichtfeld)
    label $w.main.plz_label -text "PLZ:*" -anchor w
    entry $w.main.plz_entry -textvariable ::behoerde::plz -font {Arial 11}
    grid $w.main.plz_label -row 1 -column 0 -sticky w -pady 5
    grid $w.main.plz_entry -row 1 -column 1 -sticky ew -pady 5

    # Zeile 2: Ort (Pflichtfeld)
    label $w.main.ort_label -text "Ort:*" -anchor w
    entry $w.main.ort_entry -textvariable ::behoerde::ort -font {Arial 11}
    grid $w.main.ort_label -row 2 -column 0 -sticky w -pady 5
    grid $w.main.ort_entry -row 2 -column 1 -sticky ew -pady 5

    # Zeile 3: Telefon (Pflichtfeld)
    label $w.main.tel_label -text "Tel.:*" -anchor w
    entry $w.main.tel_entry -textvariable ::behoerde::telefon -font {Arial 11}
    grid $w.main.tel_label -row 3 -column 0 -sticky w -pady 5
    grid $w.main.tel_entry -row 3 -column 1 -sticky ew -pady 5

    # Zeile 4: Fax (optional)
    label $w.main.fax_label -text "Fax:" -anchor w
    entry $w.main.fax_entry -textvariable ::behoerde::fax -font {Arial 11}
    grid $w.main.fax_label -row 4 -column 0 -sticky w -pady 5
    grid $w.main.fax_entry -row 4 -column 1 -sticky ew -pady 5

    # Zeile 5: E-Mail (Pflichtfeld)
    label $w.main.mail_label -text "Mail:*" -anchor w
    entry $w.main.mail_entry -textvariable ::behoerde::email -font {Arial 11}
    grid $w.main.mail_label -row 5 -column 0 -sticky w -pady 5
    grid $w.main.mail_entry -row 5 -column 1 -sticky ew -pady 5

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure $w.main 1 -weight 1

    # Zeile 6: Hinweis für Pflichtfelder
    label $w.main.hinweis -text "* Pflichtfelder" -fg "#666666" -font {Arial 9 italic}
    grid $w.main.hinweis -row 6 -column 0 -columnspan 2 -sticky w -pady 10

    # === Button-Frame am unteren Rand ===
    frame $w.button_frame -pady 10
    pack $w.button_frame -side bottom -fill x -padx 20

    # Speichern-Button (grün, links)
    button $w.button_frame.speichern -text "Speichern" -bg "#90EE90" -width 12 \
        -command ::behoerde::speichere_behoerde_daten
    pack $w.button_frame.speichern -side left -padx 5

    # Abbrechen-Button (rot, rechts)
    button $w.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 12 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Fokus auf das Fenster setzen
    focus $w
}
