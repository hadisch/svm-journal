# =============================================================================
# Verein-Dialog
# Ermöglicht die Verwaltung der Vereinsdaten
# Es kann nur ein Vereinseintrag verwaltet werden
# =============================================================================

# Namespace für Vereinsdaten-Verwaltung
namespace eval ::verein {
    # Dialog-Variablen
    variable fenster ""
    variable vereinsname ""
    variable strasse ""
    variable plz ""
    variable ort ""
    variable telefon ""
    variable email ""
    variable registereintrag ""
}

# =============================================================================
# Prozedur: lade_verein_daten
# Lädt die Vereinsdaten aus der JSON-Datei
# Füllt die Namespace-Variablen mit den gespeicherten Werten
# =============================================================================
proc ::verein::lade_verein_daten {} {
    global verein_json

    # Variablen initialisieren
    variable vereinsname
    variable strasse
    variable plz
    variable ort
    variable telefon
    variable email
    variable registereintrag

    # Alle Felder zurücksetzen
    set vereinsname ""
    set strasse ""
    set plz ""
    set ort ""
    set telefon ""
    set email ""
    set registereintrag ""

    # Prüfen, ob Datei existiert
    if {![file exists $verein_json]} {
        return
    }

    # Datei öffnen und parsen
    set fp [open $verein_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Vereinsdaten extrahieren
    set lines [split $json_content "\n"]

    foreach line $lines {
        # Vereinsname extrahieren
        if {[regexp {"vereinsname":\s*"([^"]*)"} $line -> wert]} {
            set vereinsname [string trim $wert]
        }
        # Straße extrahieren
        if {[regexp {"strasse":\s*"([^"]*)"} $line -> wert]} {
            set strasse [string trim $wert]
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
        # Email extrahieren
        if {[regexp {"email":\s*"([^"]*)"} $line -> wert]} {
            set email [string trim $wert]
        }
        # Registereintrag extrahieren
        if {[regexp {"registereintrag":\s*"([^"]*)"} $line -> wert]} {
            set registereintrag [string trim $wert]
        }
    }
}

# =============================================================================
# Prozedur: speichere_verein_daten
# Speichert die Vereinsdaten in die JSON-Datei
# Validiert, dass der Vereinsname ausgefüllt ist (Pflichtfeld)
# =============================================================================
proc ::verein::speichere_verein_daten {} {
    global verein_json

    # Variablen holen
    variable fenster
    variable vereinsname
    variable strasse
    variable plz
    variable ort
    variable telefon
    variable email
    variable registereintrag

    # Vereinsname trimmen
    set vereinsname [string trim $vereinsname]

    # Pflichtfeld validieren
    if {$vereinsname eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie einen Vereinsnamen ein."
        return
    }

    # Alle anderen Felder auch trimmen
    set strasse [string trim $strasse]
    set plz [string trim $plz]
    set ort [string trim $ort]
    set telefon [string trim $telefon]
    set email [string trim $email]
    set registereintrag [string trim $registereintrag]

    # JSON-Datei aufbauen
    set lines [list]
    lappend lines "\{"
    lappend lines "  \"vereinsname\": \"$vereinsname\","
    lappend lines "  \"strasse\": \"$strasse\","
    lappend lines "  \"plz\": \"$plz\","
    lappend lines "  \"ort\": \"$ort\","
    lappend lines "  \"telefon\": \"$telefon\","
    lappend lines "  \"email\": \"$email\","
    lappend lines "  \"registereintrag\": \"$registereintrag\""
    lappend lines "\}"

    set json_content [join $lines "\n"]

    # Datei schreiben
    set fp [open $verein_json w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp

    # Erfolgsmeldung anzeigen
    tk_messageBox -parent $fenster -icon info -title "Erfolgreich" \
        -message "Die Vereinsdaten wurden erfolgreich gespeichert."

    # Fenster schließen
    destroy $fenster
}

# =============================================================================
# Prozedur: open_verein_dialog
# Öffnet den Vereinsdaten-Dialog
# Lädt existierende Daten oder zeigt leeres Formular
# =============================================================================
proc open_verein_dialog {} {
    # Dialog-Fenster definieren
    set w .verein
    set ::verein::fenster $w

    # Prüfen, ob Dialog bereits offen ist
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    # Daten laden
    ::verein::lade_verein_daten

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Vereinsdaten"
    wm geometry $w "550x450"
    wm resizable $w 0 0

    # Hauptframe erstellen
    frame $w.main -padx 20 -pady 20
    pack $w.main -fill both -expand 1

    # === Eingabefelder im Grid-Layout ===

    # Zeile 0: Vereinsname (Pflichtfeld)
    label $w.main.vereinsname_label -text "Vereinsname:*" -anchor w
    entry $w.main.vereinsname_entry -textvariable ::verein::vereinsname -font {Arial 11}
    grid $w.main.vereinsname_label -row 0 -column 0 -sticky w -pady 5
    grid $w.main.vereinsname_entry -row 0 -column 1 -sticky ew -pady 5

    # Zeile 1: Straße
    label $w.main.strasse_label -text "Straße:" -anchor w
    entry $w.main.strasse_entry -textvariable ::verein::strasse -font {Arial 11}
    grid $w.main.strasse_label -row 1 -column 0 -sticky w -pady 5
    grid $w.main.strasse_entry -row 1 -column 1 -sticky ew -pady 5

    # Zeile 2: PLZ
    label $w.main.plz_label -text "PLZ:" -anchor w
    entry $w.main.plz_entry -textvariable ::verein::plz -font {Arial 11}
    grid $w.main.plz_label -row 2 -column 0 -sticky w -pady 5
    grid $w.main.plz_entry -row 2 -column 1 -sticky ew -pady 5

    # Zeile 3: Ort
    label $w.main.ort_label -text "Ort:" -anchor w
    entry $w.main.ort_entry -textvariable ::verein::ort -font {Arial 11}
    grid $w.main.ort_label -row 3 -column 0 -sticky w -pady 5
    grid $w.main.ort_entry -row 3 -column 1 -sticky ew -pady 5

    # Zeile 4: Telefon
    label $w.main.tel_label -text "Tel.:" -anchor w
    entry $w.main.tel_entry -textvariable ::verein::telefon -font {Arial 11}
    grid $w.main.tel_label -row 4 -column 0 -sticky w -pady 5
    grid $w.main.tel_entry -row 4 -column 1 -sticky ew -pady 5

    # Zeile 5: E-Mail
    label $w.main.mail_label -text "Mail:" -anchor w
    entry $w.main.mail_entry -textvariable ::verein::email -font {Arial 11}
    grid $w.main.mail_label -row 5 -column 0 -sticky w -pady 5
    grid $w.main.mail_entry -row 5 -column 1 -sticky ew -pady 5

    # Zeile 6: Registereintrag
    label $w.main.register_label -text "Registereintrag:" -anchor w
    entry $w.main.register_entry -textvariable ::verein::registereintrag -font {Arial 11}
    grid $w.main.register_label -row 6 -column 0 -sticky w -pady 5
    grid $w.main.register_entry -row 6 -column 1 -sticky ew -pady 5

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure $w.main 1 -weight 1

    # Zeile 7: Hinweis für Pflichtfelder
    label $w.main.hinweis -text "* Pflichtfeld" -fg "#666666" -font {Arial 9 italic}
    grid $w.main.hinweis -row 7 -column 0 -columnspan 2 -sticky w -pady 10

    # === Button-Frame am unteren Rand ===
    frame $w.button_frame -pady 10
    pack $w.button_frame -side bottom -fill x -padx 20

    # Speichern-Button (grün, links)
    button $w.button_frame.speichern -text "Speichern" -bg "#90EE90" -width 12 \
        -command ::verein::speichere_verein_daten
    pack $w.button_frame.speichern -side left -padx 5

    # Abbrechen-Button (rot, rechts)
    button $w.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 12 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Fokus auf das Fenster setzen
    focus $w
}
