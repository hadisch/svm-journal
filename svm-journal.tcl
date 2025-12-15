#!/usr/bin/env wish

# Hauptprogramm für svm-journal
# Erstellt ein Fenster mit minimaler Größe von 1600x900 Pixeln

# System-Encoding auf UTF-8 setzen (wichtig für Windows-Kompatibilität)
# Verhindert Probleme mit Umlauten und Sonderzeichen
encoding system utf-8

# Tcl/Tk-Paket laden
package require Tk

# =============================================================================
# Pfad-Management-System laden (MUSS als erstes geladen werden)
# =============================================================================
# Verwaltet plattformübergreifend die Verzeichnisstruktur und initialisiert
# beim ersten Start automatisch die User-Daten-Verzeichnisse
source [file join [file dirname [info script]] inc pfad_management.tcl]

# =============================================================================
# Lock-Mechanismus - Verhindert mehrere Programminstanzen
source [file join [file dirname [info script]] inc programm_lock.tcl]

# =============================================================================
# JSON-Dateipfade - Zentrale Deklaration aller JSON-Dateien im Projekt
# =============================================================================
# Dateien werden jetzt im User-Daten-Verzeichnis gespeichert:
# - Linux/Mac: ~/.config/svm/
# - Windows: %APPDATA%\SVM\

# Mitgliederdaten: Informationen über alle Vereinsmitglieder
set mitglieder_json [::pfad::get_json_path "daten" "mitglieder.json"]

# Kaliber-Definitionen: Liste aller verfügbaren Kaliber
set kaliber_json [::pfad::get_json_path "preferences" "kaliber.json"]

# Kaliber-Preise: Preisliste für verschiedene Kaliber
set kaliber_preise_json [::pfad::get_json_path "preferences" "kaliber-preise.json"]

# Stand-Nutzung: Protokollierung der Standnutzung
set stand_nutzung_json [::pfad::get_json_path "preferences" "stand-nutzung.json"]

# Vereinsdaten: Informationen über den Verein
set verein_json [::pfad::get_json_path "preferences" "verein.json"]

# Behördendaten: Informationen über die zuständige Waffenbehörde
set behoerde_json [::pfad::get_json_path "preferences" "behoerde.json"]

# Waffenregister: Liste aller Vereinswaffen
set waffenregister_json [::pfad::get_json_path "daten" "waffenregister.json"]

# =============================================================================

# Bestätigungsdialog für Programmbeendigung laden
source [file join [file dirname [info script]] inc exit_confirm.tcl]

# Fenster-Einstellungen - Speichern und Laden von Fenstergröße, Position und Vollbildstatus
source [file join [file dirname [info script]] inc fenster_einstellungen.tcl]

# JSON-Writer-Funktionen - Schreiben von JSON-Dateien
source [file join [file dirname [info script]] inc json_writer.tcl]

# JSON-Reader-Funktionen - Lesen von JSON-Dateien
source [file join [file dirname [info script]] inc json_reader.tcl]

# Mitglieder-Fenster - Fenster zur Verwaltung von Vereinsmitgliedern
source [file join [file dirname [info script]] inc mitglieder_fenster.tcl]

# Neuer-Eintrag-Fenster - Fenster zur Erfassung neuer Schießstand-Einträge
source [file join [file dirname [info script]] inc neuer_eintrag.tcl]

# Export-Dialog - Dialog für Markdown und HTML Export
source [file join [file dirname [info script]] inc export_dialog.tcl]

# Eintrag-Löschen - Funktionalität zum Löschen von Einträgen
source [file join [file dirname [info script]] inc eintrag_loeschen.tcl]

# Eintrag-Bearbeiten - Funktionalität zum Bearbeiten von Einträgen
source [file join [file dirname [info script]] inc eintrag_bearbeiten.tcl]

# Munitions-Preise-Dialog - Dialog zur Verwaltung von Kalibern und Preisen
source [file join [file dirname [info script]] inc munitions_preise_dialog.tcl]

# Standnutzungs-Preise-Dialog - Dialog zur Verwaltung von Standnutzungskategorien und Preisen
source [file join [file dirname [info script]] inc standnutzung_preise_dialog.tcl]

# Über-Dialog - Zeigt Informationen über das Programm
source [file join [file dirname [info script]] inc ueber_dialog.tcl]

# Verein-Dialog - Verwaltung von Vereinsdaten
source [file join [file dirname [info script]] inc verein_dialog.tcl]

# Behörden-Dialog - Verwaltung von Behördendaten
source [file join [file dirname [info script]] inc behoerde_dialog.tcl]

# Waffenregister-Dialog - Verwaltung der Vereinswaffen
source [file join [file dirname [info script]] inc waffenregister_dialog.tcl]

# Waffenverleih-Dialog - Dokumentation von Waffenausleihen
source [file join [file dirname [info script]] inc waffenverleih_dialog.tcl]

# Waffenverleih-HTML-Export - HTML-Dokumentengenerierung für Waffenverleih
source [file join [file dirname [info script]] inc waffenverleih_html_export.tcl]

# Daten-Prüfungs-Dialog - Werkzeug zur Überprüfung und Reparatur der JSON-Datenbank
source [file join [file dirname [info script]] inc daten_pruefen_dialog.tcl]

# =============================================================================
# Lock-Mechanismus: Prüfen ob bereits eine Instanz läuft
# =============================================================================
if {![::programm_lock::acquire_lock]} {
    # Eine andere Instanz läuft bereits - Warnung anzeigen und beenden
    # Hauptfenster verstecken, damit nur die MessageBox sichtbar ist
    wm withdraw .

    # Update erzwingen, damit das Fenster wirklich versteckt ist
    update

    # MessageBox ohne Parent anzeigen (erscheint im Vordergrund)
    tk_messageBox -icon warning -type ok -title "SVM-Journal - Warnung" \
        -message "Es läuft bereits eine Instanz des SVM-Journal.\n\nDas Programm wird beendet."
    exit
}

# Fenstertitel setzen
wm title . "SVM Journal"

# Minimale Fenstergröße festlegen (1600x900 Pixel)
wm minsize . 1600 900

# Anfangsgröße des Fensters setzen
wm geometry . 1600x900

# GUI-Update erzwingen, damit Fenster existiert
update idletasks

# Fenster zentrieren auf dem Bildschirm
# Bildschirmbreite und -höhe ermitteln
set screen_width [winfo screenwidth .]
set screen_height [winfo screenheight .]

# Position berechnen für zentriertes Fenster
# Berücksichtigt Taskbar/Panel (ca. 40-50 Pixel Offset nach oben)
set x_pos [expr {($screen_width - 1600) / 2}]
set y_pos [expr {($screen_height - 900) / 2 - 30}]

# Sicherstellen, dass y_pos nicht negativ wird
if {$y_pos < 0} {
    set y_pos 0
}

# Fensterposition setzen (zentriert)
wm geometry . +${x_pos}+${y_pos}

# Gespeicherte Fenstereinstellungen laden und anwenden
# Falls vorhanden, überschreibt dies die obigen Standard-Einstellungen
# Stellt Größe, Position und Vollbildstatus vom letzten Programmstart wieder her
lade_fenster_einstellungen

# Fenster-Schließen-Ereignis abfangen (X-Button)
# Bei Klick auf X wird Lock freigegeben und dann confirm_exit aufgerufen
wm protocol . WM_DELETE_WINDOW {
    ::programm_lock::release_lock
    confirm_exit
}

# Menüleiste erstellen
# Hauptmenü als Menüleiste definieren
menu .menubar

# Menü "Datei" erstellen
menu .menubar.file -tearoff 0

# Untermenü "Exportieren" erstellen
menu .menubar.file.export -tearoff 0
.menubar.file.export add command -label "Markdown" -command {open_export_dialog markdown}
.menubar.file.export add command -label "HTML" -command {open_export_dialog html}

# Exportieren als Untermenü hinzufügen
.menubar.file add cascade -label "Exportieren" -menu .menubar.file.export
.menubar.file add command -label "Beenden" -command {confirm_exit} -accelerator "Strg+Q"
.menubar add cascade -label "Datei" -menu .menubar.file

# Menü "Einstellungen" erstellen
menu .menubar.settings -tearoff 0
.menubar.settings add command -label "Preise Munition..." -command {open_munitions_preise_dialog}
.menubar.settings add command -label "Preise Standnutzung..." -command {open_standnutzung_preise_dialog}
.menubar.settings add separator
.menubar.settings add command -label "Verein" -command {open_verein_dialog}
.menubar.settings add command -label "Beh\u00f6rde" -command {open_behoerde_dialog}
.menubar add cascade -label "Einstellungen" -menu .menubar.settings

# Menü "Werkzeuge" erstellen
menu .menubar.tools -tearoff 0
.menubar.tools add command -label "Waffenregister" -command {open_waffenregister_dialog}
.menubar.tools add command -label "Waffenverleih" -command {open_waffenverleih_dialog}
.menubar.tools add separator
.menubar.tools add command -label "Daten \u00fcberpr\u00fcfen..." -command {open_daten_pruefen_dialog}
.menubar add cascade -label "Werkzeuge" -menu .menubar.tools

# Menü "Info" erstellen
menu .menubar.info -tearoff 0
.menubar.info add command -label "\u00dcber..." -command {open_ueber_dialog}
.menubar add cascade -label "Info" -menu .menubar.info

# Menüleiste dem Hauptfenster zuweisen
. configure -menu .menubar

# Button-Toolbar unterhalb der Menüleiste erstellen
# Frame für die Button-Leiste mit hellgrauem Hintergrund
frame .toolbar -bg #E0E0E0 -relief raised -bd 1
pack .toolbar -fill x -pady 2

# Linke Button-Gruppe (Neuer Eintrag, Eintrag bearbeiten, Mitglieder) in gelblichem Ton
# Button "Neuer Eintrag" - öffnet Dialog für neuen Journal-Eintrag
button .toolbar.new -text "Neuer Eintrag" -bg "#FDF1AF" -command {open_neuer_eintrag_fenster}
pack .toolbar.new -side left -padx 5 -pady 3

# Button "Eintrag bearbeiten" - öffnet Dialog zum Bearbeiten des ausgewählten Eintrags
button .toolbar.edit -text "Eintrag bearbeiten" -bg "#FDF1AF" -command {oeffne_bearbeiten_dialog}
pack .toolbar.edit -side left -padx 5 -pady 3

# Button "Mitglieder" - zeigt Mitgliederverwaltung
button .toolbar.members -text "Mitglieder" -bg "#FDF1AF" -command {open_mitglieder_fenster}
pack .toolbar.members -side left -padx 5 -pady 3

# Rechter Button (Beenden) in blauem Ton
# Button "Beenden" - zeigt Bestätigungsdialog vor dem Schließen
button .toolbar.quit -text "Beenden" -bg "#4ACEFA" -command {confirm_exit}
pack .toolbar.quit -side right -padx 5 -pady 3

# Tastatur-Shortcuts für das Hauptfenster
# Strg+Q für Beenden (Menü und Button)
bind . <Control-q> {confirm_exit}
bind . <Control-Q> {confirm_exit}

# Strg+N für Neuer Eintrag
bind . <Control-n> {.toolbar.new invoke}
bind . <Control-N> {.toolbar.new invoke}

# Hauptframe erstellen für zukünftige Inhalte
frame .main -bg white
pack .main -fill both -expand 1

# Treeview-Widget für tabellarische Darstellung der Einträge
# Vertikale Scrollbar für das Treeview
scrollbar .main.yscroll -command {.main.tree yview} -orient vertical

# Horizontale Scrollbar für das Treeview
scrollbar .main.xscroll -command {.main.tree xview} -orient horizontal

# Schriftgröße für Treeview-Widget konfigurieren (11 Punkte)
ttk::style configure Treeview -font {TkDefaultFont 11} -rowheight 22

# Treeview-Widget mit Spalten für Einträge
# -selectmode browse: Erlaubt nur Einzelauswahl, keine Mehrfachauswahl mit Strg/Shift
# Spalte "uhrzeit" ist versteckt (nicht in -show headings), wird aber für die Bearbeitung benötigt
ttk::treeview .main.tree \
    -columns {datum uhrzeit nachname vorname kw lw typ kaliber startgeld munition munpreis} \
    -show headings \
    -selectmode browse \
    -yscrollcommand {.main.yscroll set} \
    -xscrollcommand {.main.xscroll set} \
    -displaycolumns {datum nachname vorname kw lw typ kaliber startgeld munition munpreis}

# Spaltenüberschriften und Breiten definieren
.main.tree heading datum -text "Datum"
.main.tree heading uhrzeit -text "Uhrzeit"
.main.tree heading nachname -text "Nachname"
.main.tree heading vorname -text "Vorname"
.main.tree heading kw -text "KW"
.main.tree heading lw -text "LW"
.main.tree heading typ -text "Typ"
.main.tree heading kaliber -text "Kaliber"
.main.tree heading startgeld -text "Startgeld"
.main.tree heading munition -text "Munition"
.main.tree heading munpreis -text "Mun.Preis"

# Spaltenbreiten festlegen (in Pixeln)
.main.tree column datum -width 100 -anchor w
.main.tree column uhrzeit -width 80 -anchor w
.main.tree column nachname -width 150 -anchor w
.main.tree column vorname -width 150 -anchor w
.main.tree column kw -width 50 -anchor center
.main.tree column lw -width 50 -anchor center
.main.tree column typ -width 50 -anchor center
.main.tree column kaliber -width 120 -anchor w
.main.tree column startgeld -width 70 -anchor e
.main.tree column munition -width 150 -anchor w
.main.tree column munpreis -width 90 -anchor e

# Layout: Grid-Manager für optimale Platzierung
# Treeview nimmt den gesamten verfügbaren Platz ein
grid .main.tree    -row 0 -column 0 -sticky nsew
grid .main.yscroll -row 0 -column 1 -sticky ns
grid .main.xscroll -row 1 -column 0 -sticky ew

# Grid-Gewichtung: Treeview soll bei Größenänderung mitwachsen
grid rowconfigure    .main 0 -weight 1
grid columnconfigure .main 0 -weight 1

# Rechtsklick-Binding für Kontextmenü (Eintrag löschen)
bind .main.tree <Button-3> {zeige_kontext_menu %x %y}

# TreeviewSelect-Event zum Speichern des markierten Eintrags
# Wird aufgerufen, wenn eine Zeile im Treeview ausgewählt wird
bind .main.tree <<TreeviewSelect>> {
    # Ausgewähltes Item ermitteln
    set selected_items [.main.tree selection]
    if {[llength $selected_items] > 0} {
        # Item-ID des ersten ausgewählten Items
        set item_id [lindex $selected_items 0]

        # Werte des ausgewählten Eintrags holen
        set values [.main.tree item $item_id -values]

        # Einzelne Felder extrahieren (Reihenfolge: datum, uhrzeit, nachname, vorname, kw, lw, typ, kaliber, startgeld, munition, munpreis)
        lassign $values datum uhrzeit nachname vorname kw lw typ kaliber startgeld munition munpreis

        # Markierten Eintrag als Dictionary speichern
        # Die Uhrzeit wird jetzt korrekt aus der versteckten Spalte gelesen
        set ::markierter_eintrag [dict create \
            "datum" $datum \
            "uhrzeit" $uhrzeit \
            "nachname" $nachname \
            "vorname" $vorname \
            "kurzwaffe" $kw \
            "langwaffe" $lw \
            "waffentyp" $typ \
            "kaliber" $kaliber \
            "startgeld" $startgeld \
            "munition" $munition \
            "munitionspreis" $munpreis \
        ]
    } else {
        # Keine Auswahl - markierter Eintrag zurücksetzen
        set ::markierter_eintrag [dict create]
    }
}

# Statusleiste am unteren Rand für Datum und Uhrzeit
# Frame für Statusleiste mit leicht erhöhtem Rand
frame .statusbar -bg #E0E0E0 -relief sunken -bd 1
pack .statusbar -side bottom -fill x

# Label für Datum und Uhrzeit, rechtsbündig
label .statusbar.datetime -text "" -bg #E0E0E0 -anchor e
pack .statusbar.datetime -side right -padx 10 -pady 2

# Funktion zur Aktualisierung von Datum und Uhrzeit
# Wird jede Sekunde aufgerufen, um die Anzeige zu aktualisieren
proc update_datetime {} {
    # Aktuelles Datum und Uhrzeit im deutschen Format ermitteln
    set current_datetime [clock format [clock seconds] -format "%d.%m.%Y  %H:%M:%S"]

    # Label-Text aktualisieren
    .statusbar.datetime configure -text $current_datetime

    # Funktion nach 1000ms (1 Sekunde) erneut aufrufen
    after 1000 update_datetime
}

# Erste Aktualisierung der Datum/Uhrzeit-Anzeige starten
update_datetime

# Header-Zeile für Einträge im Hauptfenster anzeigen
zeige_eintraege_header

# Existierende Einträge aus der Jahres-JSON-Datei laden und anzeigen
lade_existierende_eintraege

# Ereignisschleife starten (wird automatisch durch wish gestartet)
