# =============================================================================
# Mitglieder-Fenster
# Erstellt ein neues Fenster zur Verwaltung von Vereinsmitgliedern
# =============================================================================

# Globale Variable zum Speichern der Mitgliederdaten
# Array mit allen Mitgliedern für Suchfunktionen
set ::mitglieder_liste {}

# Globale Variable zum Speichern des aktuell markierten Mitglieds
# Enthält den Index in der mitglieder_liste oder -1 wenn nichts markiert
set ::markiertes_mitglied -1

# Globale Variable für Index-Zuordnung bei gefilterten Ansichten
# Speichert für jede angezeigte Zeile den ursprünglichen Index in mitglieder_liste
set ::angezeigte_indices {}

# Prozedur zum Anzeigen aller Mitglieder im Treeview
# Liest die globale Mitgliederliste und zeigt sie tabellarisch an
proc zeige_alle_mitglieder {} {
    # Markierung zurücksetzen
    set ::markiertes_mitglied -1

    # Alle vorhandenen Items im Treeview löschen
    .mitglieder.main.tree delete [.mitglieder.main.tree children {}]

    # Index-Liste zurücksetzen
    set ::angezeigte_indices {}

    # Alle Mitglieder durchlaufen und ins Treeview einfügen
    set original_index 0
    foreach mitglied $::mitglieder_liste {
        # Einzelne Felder aus der Liste extrahieren
        lassign $mitglied nachname vorname strasse plz ort festnetz mobilfunk email geburtsdatum eintrittsdatum funktion

        # Zeile ins Treeview einfügen
        .mitglieder.main.tree insert {} end -values [list $nachname $vorname $strasse $plz $ort $festnetz $mobilfunk $email $geburtsdatum $eintrittsdatum]

        # Original-Index zur Zuordnungsliste hinzufügen
        lappend ::angezeigte_indices $original_index

        # Zähler erhöhen
        incr original_index
    }
}

# Prozedur zum Filtern der Mitglieder nach Suchbegriff
# Zeigt nur Mitglieder an, die den Suchbegriff enthalten
proc filtere_mitglieder {suchbegriff} {
    # Markierung zurücksetzen (Löschen ist nur bei vollständiger Liste erlaubt)
    set ::markiertes_mitglied -1

    # Alle vorhandenen Items im Treeview löschen
    .mitglieder.main.tree delete [.mitglieder.main.tree children {}]

    # Index-Liste zurücksetzen
    set ::angezeigte_indices {}

    # Zähler für gefundene Mitglieder
    set gefunden_count 0

    # Suchbegriff in Kleinbuchstaben für case-insensitive Suche
    set suchbegriff_lower [string tolower $suchbegriff]

    # Alle Mitglieder durchlaufen und filtern
    set original_index 0
    foreach mitglied $::mitglieder_liste {
        # Einzelne Felder aus der Liste extrahieren
        lassign $mitglied nachname vorname strasse plz ort festnetz mobilfunk email geburtsdatum eintrittsdatum funktion

        # Alle Felder zu einem String zusammenfügen für die Suche
        set volltext "$nachname $vorname $strasse $plz $ort $festnetz $mobilfunk $email $geburtsdatum $eintrittsdatum"
        set volltext_lower [string tolower $volltext]

        # Prüfen, ob Suchbegriff im Volltext enthalten ist
        if {[string first $suchbegriff_lower $volltext_lower] != -1} {
            # Zeile ins Treeview einfügen
            .mitglieder.main.tree insert {} end -values [list $nachname $vorname $strasse $plz $ort $festnetz $mobilfunk $email $geburtsdatum $eintrittsdatum]

            # Original-Index zur Zuordnungsliste hinzufügen
            lappend ::angezeigte_indices $original_index

            # Zähler erhöhen
            incr gefunden_count
        }

        # Original-Index immer erhöhen (für alle Mitglieder in der Hauptliste)
        incr original_index
    }

    # Rückgabewert: Anzahl der gefundenen Mitglieder
    return $gefunden_count
}

# Prozedur zum Prüfen ob Speichern-Button aktiviert werden soll
# Wird bei jeder Eingabe in Nachname oder Vorname aufgerufen
proc pruefe_speichern_button {} {
    # Werte aus Eingabefeldern holen
    set nachname [string trim [.mitglieder.hinzufuegen.content.nachname_entry get]]
    set vorname [string trim [.mitglieder.hinzufuegen.content.vorname_entry get]]

    # Button aktivieren wenn beide Felder ausgefüllt sind
    if {$nachname ne "" && $vorname ne ""} {
        .mitglieder.hinzufuegen.buttons.speichern configure -state normal
    } else {
        .mitglieder.hinzufuegen.buttons.speichern configure -state disabled
    }
}

# Prozedur zum Öffnen des Hinzufügen-Dialogs
# Erstellt ein Fenster mit Eingabefeldern für alle Mitgliedsdaten
proc oeffne_hinzufuegen_dialog {} {
    # Prüfen, ob Dialog bereits existiert
    if {[winfo exists .mitglieder.hinzufuegen]} {
        # Dialog existiert bereits - in den Vordergrund bringen
        raise .mitglieder.hinzufuegen
        focus .mitglieder.hinzufuegen
        return
    }

    # Neues Toplevel-Fenster für Hinzufügen-Dialog erstellen
    toplevel .mitglieder.hinzufuegen

    # Fenstertitel setzen
    wm title .mitglieder.hinzufuegen "Neues Mitglied hinzufügen"

    # Fenstergröße festlegen
    wm geometry .mitglieder.hinzufuegen 600x515

    # Fenster modal machen (im Vordergrund bleiben)
    wm transient .mitglieder.hinzufuegen .mitglieder

    # Frame für Buttons ZUERST erstellen und packen (damit sie sichtbar bleiben)
    frame .mitglieder.hinzufuegen.buttons -pady 10
    pack .mitglieder.hinzufuegen.buttons -side bottom -fill x

    # Frame für Inhalt mit Scrollbar
    frame .mitglieder.hinzufuegen.content -padx 20 -pady 20
    pack .mitglieder.hinzufuegen.content -fill both -expand 1

    # Grid-Layout für Labels und Eingabefelder
    set row 0

    # Nachname (Pflichtfeld)
    label .mitglieder.hinzufuegen.content.nachname_label -text "Nachname:*" -anchor w
    entry .mitglieder.hinzufuegen.content.nachname_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.nachname_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.nachname_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Vorname (Pflichtfeld)
    label .mitglieder.hinzufuegen.content.vorname_label -text "Vorname:*" -anchor w
    entry .mitglieder.hinzufuegen.content.vorname_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.vorname_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.vorname_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Geburtsdatum
    label .mitglieder.hinzufuegen.content.geburtsdatum_label -text "Geburtsdatum:" -anchor w
    entry .mitglieder.hinzufuegen.content.geburtsdatum_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.geburtsdatum_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.geburtsdatum_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Straße
    label .mitglieder.hinzufuegen.content.strasse_label -text "Straße:" -anchor w
    entry .mitglieder.hinzufuegen.content.strasse_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.strasse_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.strasse_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # PLZ
    label .mitglieder.hinzufuegen.content.plz_label -text "PLZ:" -anchor w
    entry .mitglieder.hinzufuegen.content.plz_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.plz_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.plz_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Ort
    label .mitglieder.hinzufuegen.content.ort_label -text "Ort:" -anchor w
    entry .mitglieder.hinzufuegen.content.ort_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.ort_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.ort_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Festnetz
    label .mitglieder.hinzufuegen.content.festnetz_label -text "Festnetz:" -anchor w
    entry .mitglieder.hinzufuegen.content.festnetz_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.festnetz_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.festnetz_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Mobilfunk
    label .mitglieder.hinzufuegen.content.mobilfunk_label -text "Mobilfunk:" -anchor w
    entry .mitglieder.hinzufuegen.content.mobilfunk_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.mobilfunk_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.mobilfunk_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Email
    label .mitglieder.hinzufuegen.content.email_label -text "Email:" -anchor w
    entry .mitglieder.hinzufuegen.content.email_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.email_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.email_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Eintrittsdatum
    label .mitglieder.hinzufuegen.content.eintrittsdatum_label -text "Eintrittsdatum:" -anchor w
    entry .mitglieder.hinzufuegen.content.eintrittsdatum_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.eintrittsdatum_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.eintrittsdatum_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Funktion
    label .mitglieder.hinzufuegen.content.funktion_label -text "Funktion:" -anchor w
    entry .mitglieder.hinzufuegen.content.funktion_entry -font {TkDefaultFont 11}
    grid .mitglieder.hinzufuegen.content.funktion_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.hinzufuegen.content.funktion_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Hinweis für Pflichtfelder
    label .mitglieder.hinzufuegen.content.hinweis -text "* Pflichtfelder" -fg "#666666" -font {Arial 9 italic}
    grid .mitglieder.hinzufuegen.content.hinweis -row $row -column 0 -columnspan 2 -sticky w -pady 10
    incr row

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure .mitglieder.hinzufuegen.content 1 -weight 1

    # Button "Abbrechen" - schließt Dialog ohne Änderungen
    button .mitglieder.hinzufuegen.buttons.abbrechen -text "Abbrechen" -bg "#FFB6C1" -command {
        destroy .mitglieder.hinzufuegen
    }
    pack .mitglieder.hinzufuegen.buttons.abbrechen -side right -padx 5

    # Button "Speichern" - speichert neues Mitglied
    button .mitglieder.hinzufuegen.buttons.speichern -text "Speichern" -state disabled -bg "#90EE90" -command {
        # Error-Handling für gesamten Speichervorgang
        if {[catch {
            # Werte aus Eingabefeldern holen
            set nachname [string trim [.mitglieder.hinzufuegen.content.nachname_entry get]]
            set vorname [string trim [.mitglieder.hinzufuegen.content.vorname_entry get]]
            set geburtsdatum [string trim [.mitglieder.hinzufuegen.content.geburtsdatum_entry get]]
            set strasse [string trim [.mitglieder.hinzufuegen.content.strasse_entry get]]
            set plz [string trim [.mitglieder.hinzufuegen.content.plz_entry get]]
            set ort [string trim [.mitglieder.hinzufuegen.content.ort_entry get]]
            set festnetz [string trim [.mitglieder.hinzufuegen.content.festnetz_entry get]]
            set mobilfunk [string trim [.mitglieder.hinzufuegen.content.mobilfunk_entry get]]
            set email [string trim [.mitglieder.hinzufuegen.content.email_entry get]]
            set eintrittsdatum [string trim [.mitglieder.hinzufuegen.content.eintrittsdatum_entry get]]
            set funktion [string trim [.mitglieder.hinzufuegen.content.funktion_entry get]]

            # Neues Mitglied zur Liste hinzufügen
            lappend ::mitglieder_liste [list $nachname $vorname $strasse $plz $ort $festnetz $mobilfunk $email $geburtsdatum $eintrittsdatum $funktion]

            # JSON-Datei neu schreiben
            schreibe_mitglieder_json

            # Anzeige aktualisieren
            zeige_alle_mitglieder

            # Dialog schließen
            destroy .mitglieder.hinzufuegen

            # Erfolgs-Meldung
            tk_messageBox -parent .mitglieder \
                          -icon info \
                          -type ok \
                          -title "Hinzufügen erfolgreich" \
                          -message "Das Mitglied $vorname $nachname wurde erfolgreich hinzugefügt."
        } error_msg]} {
            # Fehler anzeigen falls etwas schief geht
            tk_messageBox -parent .mitglieder.hinzufuegen \
                          -icon error \
                          -type ok \
                          -title "Fehler beim Speichern" \
                          -message "Es ist ein Fehler aufgetreten:\n\n$error_msg\n\n$::errorInfo"
        }
    }
    pack .mitglieder.hinzufuegen.buttons.speichern -side right -padx 5

    # KeyRelease-Events für Validierung binden
    bind .mitglieder.hinzufuegen.content.nachname_entry <KeyRelease> {pruefe_speichern_button}
    bind .mitglieder.hinzufuegen.content.vorname_entry <KeyRelease> {pruefe_speichern_button}

    # Fokus auf erstes Eingabefeld setzen
    focus .mitglieder.hinzufuegen.content.nachname_entry
}

# Prozedur zum Öffnen des Bearbeiten-Dialogs
# Erstellt ein Fenster mit vorausgefüllten Eingabefeldern für das markierte Mitglied
proc oeffne_mitglied_bearbeiten_dialog {} {
    # Prüfen ob ein Mitglied markiert ist
    if {$::markiertes_mitglied < 0} {
        tk_messageBox -parent .mitglieder \
                      -icon warning \
                      -type ok \
                      -title "Bearbeiten" \
                      -message "Bitte wählen Sie zunächst ein Mitglied aus der Liste aus."
        return
    }

    # Prüfen, ob Dialog bereits existiert
    if {[winfo exists .mitglieder.bearbeiten]} {
        raise .mitglieder.bearbeiten
        focus .mitglieder.bearbeiten
        return
    }

    # Markiertes Mitglied aus Liste holen
    set mitglied [lindex $::mitglieder_liste $::markiertes_mitglied]
    lassign $mitglied alt_nachname alt_vorname alt_strasse alt_plz alt_ort alt_festnetz alt_mobilfunk alt_email alt_geburtsdatum alt_eintrittsdatum alt_funktion

    # Neues Toplevel-Fenster für Bearbeiten-Dialog erstellen
    toplevel .mitglieder.bearbeiten

    # Fenstertitel setzen
    wm title .mitglieder.bearbeiten "Mitglied bearbeiten"

    # Fenstergröße festlegen
    wm geometry .mitglieder.bearbeiten 600x515

    # Fenster modal machen
    wm transient .mitglieder.bearbeiten .mitglieder

    # Frame für Buttons ZUERST erstellen und packen (damit sie sichtbar bleiben)
    frame .mitglieder.bearbeiten.buttons -pady 10
    pack .mitglieder.bearbeiten.buttons -side bottom -fill x

    # Frame für Inhalt
    frame .mitglieder.bearbeiten.content -padx 20 -pady 20
    pack .mitglieder.bearbeiten.content -fill both -expand 1

    # Grid-Layout für Labels und Eingabefelder
    set row 0

    # Nachname (Pflichtfeld)
    label .mitglieder.bearbeiten.content.nachname_label -text "Nachname:*" -anchor w
    entry .mitglieder.bearbeiten.content.nachname_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.nachname_entry insert 0 $alt_nachname
    grid .mitglieder.bearbeiten.content.nachname_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.nachname_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Vorname (Pflichtfeld)
    label .mitglieder.bearbeiten.content.vorname_label -text "Vorname:*" -anchor w
    entry .mitglieder.bearbeiten.content.vorname_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.vorname_entry insert 0 $alt_vorname
    grid .mitglieder.bearbeiten.content.vorname_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.vorname_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Geburtsdatum
    label .mitglieder.bearbeiten.content.geburtsdatum_label -text "Geburtsdatum:" -anchor w
    entry .mitglieder.bearbeiten.content.geburtsdatum_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.geburtsdatum_entry insert 0 $alt_geburtsdatum
    grid .mitglieder.bearbeiten.content.geburtsdatum_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.geburtsdatum_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Straße
    label .mitglieder.bearbeiten.content.strasse_label -text "Straße:" -anchor w
    entry .mitglieder.bearbeiten.content.strasse_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.strasse_entry insert 0 $alt_strasse
    grid .mitglieder.bearbeiten.content.strasse_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.strasse_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # PLZ
    label .mitglieder.bearbeiten.content.plz_label -text "PLZ:" -anchor w
    entry .mitglieder.bearbeiten.content.plz_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.plz_entry insert 0 $alt_plz
    grid .mitglieder.bearbeiten.content.plz_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.plz_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Ort
    label .mitglieder.bearbeiten.content.ort_label -text "Ort:" -anchor w
    entry .mitglieder.bearbeiten.content.ort_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.ort_entry insert 0 $alt_ort
    grid .mitglieder.bearbeiten.content.ort_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.ort_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Festnetz
    label .mitglieder.bearbeiten.content.festnetz_label -text "Festnetz:" -anchor w
    entry .mitglieder.bearbeiten.content.festnetz_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.festnetz_entry insert 0 $alt_festnetz
    grid .mitglieder.bearbeiten.content.festnetz_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.festnetz_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Mobilfunk
    label .mitglieder.bearbeiten.content.mobilfunk_label -text "Mobilfunk:" -anchor w
    entry .mitglieder.bearbeiten.content.mobilfunk_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.mobilfunk_entry insert 0 $alt_mobilfunk
    grid .mitglieder.bearbeiten.content.mobilfunk_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.mobilfunk_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Email
    label .mitglieder.bearbeiten.content.email_label -text "Email:" -anchor w
    entry .mitglieder.bearbeiten.content.email_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.email_entry insert 0 $alt_email
    grid .mitglieder.bearbeiten.content.email_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.email_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Eintrittsdatum
    label .mitglieder.bearbeiten.content.eintrittsdatum_label -text "Eintrittsdatum:" -anchor w
    entry .mitglieder.bearbeiten.content.eintrittsdatum_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.eintrittsdatum_entry insert 0 $alt_eintrittsdatum
    grid .mitglieder.bearbeiten.content.eintrittsdatum_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.eintrittsdatum_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Funktion
    label .mitglieder.bearbeiten.content.funktion_label -text "Funktion:" -anchor w
    entry .mitglieder.bearbeiten.content.funktion_entry -font {TkDefaultFont 11}
    .mitglieder.bearbeiten.content.funktion_entry insert 0 $alt_funktion
    grid .mitglieder.bearbeiten.content.funktion_label -row $row -column 0 -sticky w -pady 5
    grid .mitglieder.bearbeiten.content.funktion_entry -row $row -column 1 -sticky ew -pady 5
    incr row

    # Hinweis für Pflichtfelder
    label .mitglieder.bearbeiten.content.hinweis -text "* Pflichtfelder" -fg "#666666" -font {Arial 9 italic}
    grid .mitglieder.bearbeiten.content.hinweis -row $row -column 0 -columnspan 2 -sticky w -pady 10
    incr row

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure .mitglieder.bearbeiten.content 1 -weight 1

    # Button "Abbrechen"
    button .mitglieder.bearbeiten.buttons.abbrechen -text "Abbrechen" -bg "#FFB6C1" -command {
        destroy .mitglieder.bearbeiten
    }
    pack .mitglieder.bearbeiten.buttons.abbrechen -side right -padx 5

    # Button "Speichern"
    button .mitglieder.bearbeiten.buttons.speichern -text "Speichern" -bg "#90EE90" -command {
        # Error-Handling für gesamten Speichervorgang
        if {[catch {
            # Werte aus Eingabefeldern holen
            set nachname [string trim [.mitglieder.bearbeiten.content.nachname_entry get]]
            set vorname [string trim [.mitglieder.bearbeiten.content.vorname_entry get]]
            set geburtsdatum [string trim [.mitglieder.bearbeiten.content.geburtsdatum_entry get]]
            set strasse [string trim [.mitglieder.bearbeiten.content.strasse_entry get]]
            set plz [string trim [.mitglieder.bearbeiten.content.plz_entry get]]
            set ort [string trim [.mitglieder.bearbeiten.content.ort_entry get]]
            set festnetz [string trim [.mitglieder.bearbeiten.content.festnetz_entry get]]
            set mobilfunk [string trim [.mitglieder.bearbeiten.content.mobilfunk_entry get]]
            set email [string trim [.mitglieder.bearbeiten.content.email_entry get]]
            set eintrittsdatum [string trim [.mitglieder.bearbeiten.content.eintrittsdatum_entry get]]
            set funktion [string trim [.mitglieder.bearbeiten.content.funktion_entry get]]

            # Prüfen ob Pflichtfelder ausgefüllt sind
            if {$nachname eq "" || $vorname eq ""} {
                tk_messageBox -parent .mitglieder.bearbeiten \
                              -icon warning \
                              -type ok \
                              -title "Fehlende Eingaben" \
                              -message "Bitte füllen Sie mindestens Nachname und Vorname aus."
                return
            }

            # Mitglied in der Liste aktualisieren
            set ::mitglieder_liste [lreplace $::mitglieder_liste $::markiertes_mitglied $::markiertes_mitglied \
                [list $nachname $vorname $strasse $plz $ort $festnetz $mobilfunk $email $geburtsdatum $eintrittsdatum $funktion]]

            # Markierung zurücksetzen
            set ::markiertes_mitglied -1

            # JSON-Datei neu schreiben
            schreibe_mitglieder_json

            # Anzeige aktualisieren
            zeige_alle_mitglieder

            # Dialog schließen
            destroy .mitglieder.bearbeiten

            # Erfolgs-Meldung
            tk_messageBox -parent .mitglieder \
                          -icon info \
                          -type ok \
                          -title "Bearbeiten erfolgreich" \
                          -message "Das Mitglied $vorname $nachname wurde erfolgreich aktualisiert."
        } error_msg]} {
            # Fehler anzeigen falls etwas schief geht
            tk_messageBox -parent .mitglieder.bearbeiten \
                          -icon error \
                          -type ok \
                          -title "Fehler beim Speichern" \
                          -message "Es ist ein Fehler aufgetreten:\n\n$error_msg\n\n$::errorInfo"
        }
    }
    pack .mitglieder.bearbeiten.buttons.speichern -side right -padx 5

    # Fokus auf erstes Eingabefeld setzen
    focus .mitglieder.bearbeiten.content.nachname_entry
}

# Prozedur zum Löschen eines Mitglieds
# Erstellt Backup und entfernt das markierte Mitglied aus der JSON-Datei
proc loesche_mitglied {} {
    # Prüfen ob ein Mitglied markiert ist
    if {$::markiertes_mitglied < 0} {
        tk_messageBox -parent .mitglieder \
                      -icon warning \
                      -type ok \
                      -title "Löschen" \
                      -message "Bitte wählen Sie zunächst ein Mitglied aus der Liste aus."
        return
    }

    # Markiertes Mitglied aus Liste holen
    set mitglied [lindex $::mitglieder_liste $::markiertes_mitglied]
    lassign $mitglied nachname vorname strasse plz ort festnetz mobilfunk email geburtsdatum eintrittsdatum funktion

    # Sicherheitsabfrage anzeigen
    set antwort [tk_messageBox -parent .mitglieder \
                                -icon question \
                                -type yesno \
                                -title "Löschen bestätigen" \
                                -message "Diesen Eintrag wirklich löschen?\n\n$nachname, $vorname\n$strasse\n$plz $ort"]

    # Wenn "Nein" geklickt wurde, abbrechen
    if {$antwort eq "no"} {
        return
    }

    # Zugriff auf die globale Variable aus svm-journal.tcl
    global mitglieder_json
    global script_dir

    # Backup-Verzeichnis erstellen falls nicht vorhanden
    set backup_dir [::pfad::get_backups_directory]
    if {![file exists $backup_dir]} {
        file mkdir $backup_dir
    }

    # Backup-Datei-Pfad erstellen
    set backup_file [file join $backup_dir "mitglieder.json.bak"]

    # Aktuelle JSON-Datei als Backup kopieren (überschreiben falls vorhanden)
    file copy -force $mitglieder_json $backup_file

    # Mitglied aus der globalen Liste entfernen
    set ::mitglieder_liste [lreplace $::mitglieder_liste $::markiertes_mitglied $::markiertes_mitglied]

    # Markierung zurücksetzen
    set ::markiertes_mitglied -1

    # JSON-Datei neu schreiben
    schreibe_mitglieder_json

    # Anzeige aktualisieren
    zeige_alle_mitglieder

    # Erfolgs-Meldung
    tk_messageBox -parent .mitglieder \
                  -icon info \
                  -type ok \
                  -title "Löschen erfolgreich" \
                  -message "Das Mitglied wurde erfolgreich gelöscht.\n\nEin Backup wurde erstellt unter:\n$backup_file"
}

# Prozedur zum Öffnen des Such-Dialogfensters
# Erstellt ein Fenster mit Eingabefeld und Live-Suche
proc oeffne_such_dialog {} {
    # Prüfen, ob Such-Dialog bereits existiert
    if {[winfo exists .mitglieder.suchdialog]} {
        # Dialog existiert bereits - in den Vordergrund bringen
        raise .mitglieder.suchdialog
        focus .mitglieder.suchdialog.eingabe
        return
    }

    # Neues Toplevel-Fenster für Such-Dialog erstellen
    toplevel .mitglieder.suchdialog

    # Fenstertitel setzen
    wm title .mitglieder.suchdialog "Suchen"

    # Fenstergröße festlegen (Höhe erhöht für bessere Darstellung)
    wm geometry .mitglieder.suchdialog 500x130

    # Fenster modal machen (im Vordergrund bleiben)
    wm transient .mitglieder.suchdialog .mitglieder

    # Frame für Inhalt
    frame .mitglieder.suchdialog.frame -padx 10 -pady 10
    pack .mitglieder.suchdialog.frame -fill both -expand 1

    # Label für Eingabefeld
    label .mitglieder.suchdialog.frame.label -text "Suchbegriff:"
    pack .mitglieder.suchdialog.frame.label -anchor w

    # Eingabefeld für Suchbegriff (gleiche Schrift wie im Hauptfenster)
    entry .mitglieder.suchdialog.eingabe -font {TkDefaultFont 11}
    pack .mitglieder.suchdialog.eingabe -in .mitglieder.suchdialog.frame -fill x -pady 5

    # Frame für Buttons
    frame .mitglieder.suchdialog.buttons
    pack .mitglieder.suchdialog.buttons -in .mitglieder.suchdialog.frame -pady 5

    # Button "Suchen" - fixiert das Suchergebnis
    button .mitglieder.suchdialog.buttons.suchen -text "Suchen" -command {
        # Suchbegriff aus Eingabefeld holen
        set suchtext [.mitglieder.suchdialog.eingabe get]

        # Prüfen, ob Suchbegriff leer ist
        if {[string trim $suchtext] eq ""} {
            # Leerer Suchbegriff - alle Mitglieder anzeigen
            zeige_alle_mitglieder
            destroy .mitglieder.suchdialog
        } else {
            # Suche durchführen
            set anzahl [filtere_mitglieder $suchtext]

            # Wenn keine Ergebnisse gefunden wurden, MessageBox anzeigen
            if {$anzahl == 0} {
                tk_messageBox -parent .mitglieder.suchdialog \
                              -icon warning \
                              -type ok \
                              -title "Suche" \
                              -message "Keinen passenden Eintrag gefunden"
                # Eingabefeld leeren und Fokus setzen
                .mitglieder.suchdialog.eingabe delete 0 end
                focus .mitglieder.suchdialog.eingabe
            } else {
                # Ergebnisse gefunden - Dialog schließen
                destroy .mitglieder.suchdialog
            }
        }
    }
    pack .mitglieder.suchdialog.buttons.suchen -side left -padx 5

    # Live-Suche bei jeder Tasteneingabe (KeyRelease Event)
    bind .mitglieder.suchdialog.eingabe <KeyRelease> {
        # Suchbegriff aus Eingabefeld holen
        set suchtext [.mitglieder.suchdialog.eingabe get]

        # Prüfen, ob Suchbegriff leer ist
        if {[string trim $suchtext] eq ""} {
            # Leerer Suchbegriff - alle Mitglieder anzeigen
            zeige_alle_mitglieder
        } else {
            # Live-Filterung durchführen
            filtere_mitglieder $suchtext
        }
    }

    # Enter-Taste löst Suchen-Button aus
    bind .mitglieder.suchdialog.eingabe <Return> {
        .mitglieder.suchdialog.buttons.suchen invoke
    }

    # ESC-Taste schließt den Dialog und zeigt alle Mitglieder
    bind .mitglieder.suchdialog <Escape> {
        zeige_alle_mitglieder
        destroy .mitglieder.suchdialog
    }

    # Fokus auf Eingabefeld setzen
    focus .mitglieder.suchdialog.eingabe
}

# Prozedur zum Öffnen des Mitglieder-Fensters
# Erstellt ein Toplevel-Fenster mit Buttonleiste zur Mitgliederverwaltung
proc open_mitglieder_fenster {} {
    # Prüfen, ob das Fenster bereits existiert
    # Falls ja, Fenster in den Vordergrund bringen statt neu zu erstellen
    if {[winfo exists .mitglieder]} {
        # Fenster existiert bereits - in den Vordergrund holen
        raise .mitglieder
        focus .mitglieder
        return
    }

    # Neues Toplevel-Fenster für Mitgliederverwaltung erstellen
    toplevel .mitglieder

    # Fenstertitel setzen
    wm title .mitglieder "Mitgliederverwaltung"

    # Minimale Fenstergröße festlegen (1600x800 Pixel)
    wm minsize .mitglieder 1600 800

    # Anfangsgröße des Fensters setzen
    wm geometry .mitglieder 1600x800

    # GUI-Update erzwingen, damit Fenster existiert
    update idletasks

    # Fenster zentrieren relativ zum Hauptfenster
    # Hauptfenster-Position ermitteln
    set main_x [winfo x .]
    set main_y [winfo y .]
    set main_width [winfo width .]
    set main_height [winfo height .]

    # Neue Position berechnen (zentriert über dem Hauptfenster)
    set x_pos [expr {$main_x + ($main_width - 1600) / 2}]
    set y_pos [expr {$main_y + ($main_height - 800) / 2}]

    # Sicherstellen, dass Position nicht negativ wird
    if {$x_pos < 0} { set x_pos 0 }
    if {$y_pos < 0} { set y_pos 0 }

    # Fensterposition setzen
    wm geometry .mitglieder +${x_pos}+${y_pos}

    # =============================================================================
    # Button-Toolbar am oberen Rand des Fensters
    # =============================================================================

    # Frame für die Button-Leiste mit hellgrauem Hintergrund
    frame .mitglieder.toolbar -bg #E0E0E0 -relief raised -bd 1
    pack .mitglieder.toolbar -fill x -pady 2

    # --- Linke Button-Gruppe mit Icon-Buttons ---

    # Button "Suchen" - Suchfunktion für Mitglieder
    button .mitglieder.toolbar.search -image [::toolbar_icons::get suchen] \
        -command {oeffne_such_dialog}
    pack .mitglieder.toolbar.search -side left -padx 5 -pady 3
    # Tooltip für "Suchen"-Button registrieren
    ::tooltip::register .mitglieder.toolbar.search "Suchen - Strg+S"

    # Button "Hinzufügen" - Neues Mitglied hinzufügen
    button .mitglieder.toolbar.add -image [::toolbar_icons::get neuer_eintrag] \
        -command {oeffne_hinzufuegen_dialog}
    pack .mitglieder.toolbar.add -side left -padx 5 -pady 3
    # Tooltip für "Hinzufügen"-Button registrieren
    ::tooltip::register .mitglieder.toolbar.add "Mitglied hinzufügen - Strg+N"

    # Button "Bearbeiten" - Ausgewähltes Mitglied bearbeiten
    button .mitglieder.toolbar.edit -image [::toolbar_icons::get bearbeiten] \
        -command {oeffne_mitglied_bearbeiten_dialog}
    pack .mitglieder.toolbar.edit -side left -padx 5 -pady 3
    # Tooltip für "Bearbeiten"-Button registrieren
    ::tooltip::register .mitglieder.toolbar.edit "Ausgewählten Eintrag bearbeiten"

    # Button "Löschen" - Ausgewähltes Mitglied löschen
    button .mitglieder.toolbar.delete -image [::toolbar_icons::get loeschen] \
        -command {loesche_mitglied}
    pack .mitglieder.toolbar.delete -side left -padx 5 -pady 3
    # Tooltip für "Löschen"-Button registrieren
    ::tooltip::register .mitglieder.toolbar.delete "Ausgewählten Eintrag löschen"

    # --- Rechter Button (Schließen) ---

    # Button "Schließen" - Fenster schließen
    button .mitglieder.toolbar.close -image [::toolbar_icons::get schliessen] \
        -command {destroy .mitglieder}
    pack .mitglieder.toolbar.close -side right -padx 5 -pady 3
    # Tooltip für "Schließen"-Button registrieren
    ::tooltip::register .mitglieder.toolbar.close "Fenster schließen"

    # =============================================================================
    # Hauptbereich des Fensters - Treeview-Widget mit Scrollbars
    # =============================================================================

    # Hauptframe für Inhalt
    frame .mitglieder.main -bg white
    pack .mitglieder.main -fill both -expand 1

    # Vertikale Scrollbar für das Treeview
    scrollbar .mitglieder.main.yscroll -command {.mitglieder.main.tree yview} -orient vertical

    # Horizontale Scrollbar für das Treeview
    scrollbar .mitglieder.main.xscroll -command {.mitglieder.main.tree xview} -orient horizontal

    # Schriftgröße für Treeview-Widget konfigurieren (11 Punkte, wie im Hauptfenster)
    ttk::style configure Treeview -font {TkDefaultFont 11} -rowheight 22

    # Treeview-Widget mit Spalten für Mitgliederdaten
    # -selectmode browse: Erlaubt nur Einzelauswahl, keine Mehrfachauswahl mit Strg/Shift
    ttk::treeview .mitglieder.main.tree \
        -columns {nachname vorname strasse plz ort festnetz mobilfunk email geburtsdatum eintrittsdatum} \
        -show headings \
        -selectmode browse \
        -yscrollcommand {.mitglieder.main.yscroll set} \
        -xscrollcommand {.mitglieder.main.xscroll set}

    # Spaltenüberschriften und Breiten definieren
    .mitglieder.main.tree heading nachname -text "Nachname"
    .mitglieder.main.tree heading vorname -text "Vorname"
    .mitglieder.main.tree heading strasse -text "Straße"
    .mitglieder.main.tree heading plz -text "PLZ"
    .mitglieder.main.tree heading ort -text "Ort"
    .mitglieder.main.tree heading festnetz -text "Festnetz"
    .mitglieder.main.tree heading mobilfunk -text "Mobilfunk"
    .mitglieder.main.tree heading email -text "Email"
    .mitglieder.main.tree heading geburtsdatum -text "Geburtsdatum"
    .mitglieder.main.tree heading eintrittsdatum -text "Eintrittsdatum"

    # Spaltenbreiten festlegen (in Pixeln)
    .mitglieder.main.tree column nachname -width 150 -anchor w
    .mitglieder.main.tree column vorname -width 150 -anchor w
    .mitglieder.main.tree column strasse -width 200 -anchor w
    .mitglieder.main.tree column plz -width 60 -anchor w
    .mitglieder.main.tree column ort -width 150 -anchor w
    .mitglieder.main.tree column festnetz -width 120 -anchor w
    .mitglieder.main.tree column mobilfunk -width 120 -anchor w
    .mitglieder.main.tree column email -width 200 -anchor w
    .mitglieder.main.tree column geburtsdatum -width 110 -anchor w
    .mitglieder.main.tree column eintrittsdatum -width 120 -anchor w

    # Layout: Grid-Manager für optimale Platzierung
    # Treeview nimmt den gesamten verfügbaren Platz ein
    grid .mitglieder.main.tree    -row 0 -column 0 -sticky nsew
    grid .mitglieder.main.yscroll -row 0 -column 1 -sticky ns
    grid .mitglieder.main.xscroll -row 1 -column 0 -sticky ew

    # Grid-Gewichtung: Treeview soll bei Größenänderung mitwachsen
    grid rowconfigure    .mitglieder.main 0 -weight 1
    grid columnconfigure .mitglieder.main 0 -weight 1

    # Selection-Event für Treeview binden
    # Wird aufgerufen, wenn eine Zeile ausgewählt wird
    bind .mitglieder.main.tree <<TreeviewSelect>> {
        # Ausgewähltes Item ermitteln
        set selected_items [.mitglieder.main.tree selection]
        if {[llength $selected_items] > 0} {
            # Index des ausgewählten Items im angezeigte_indices Array finden
            set item_id [lindex $selected_items 0]
            # Item-Index im Treeview ermitteln
            set all_items [.mitglieder.main.tree children {}]
            set display_index [lsearch $all_items $item_id]
            # Original-Index aus angezeigte_indices holen
            if {$display_index >= 0 && $display_index < [llength $::angezeigte_indices]} {
                set ::markiertes_mitglied [lindex $::angezeigte_indices $display_index]
            }
        } else {
            set ::markiertes_mitglied -1
        }
    }

    # =============================================================================
    # mitglieder.json einlesen und in globale Liste laden
    # =============================================================================

    # Zugriff auf die globale Variable aus svm-journal.tcl
    global mitglieder_json

    # Globale Mitgliederliste leeren (für erneutes Öffnen des Fensters)
    set ::mitglieder_liste {}

    # Prüfen, ob die Datei existiert
    if {[file exists $mitglieder_json]} {
        # Datei öffnen und Inhalt lesen
        set fp [open $mitglieder_json r]
        # Encoding auf UTF-8 setzen für korrekte Darstellung von Umlauten
        fconfigure $fp -encoding utf-8
        # Gesamten Dateiinhalt in Variable einlesen
        set json_content [read $fp]
        # Datei schließen
        close $fp

        # JSON manuell parsen - jeden Mitgliederdatensatz finden
        # Regex: Sucht nach JSON-Objekten zwischen geschweiften Klammern
        set pattern {\{\s*"nachname":\s*"([^"]*)",\s*"vorname":\s*"([^"]*)",\s*"geburtsdatum":\s*"([^"]*)",\s*"strasse":\s*"([^"]*)",\s*"plz":\s*"([^"]*)",\s*"ort":\s*"([^"]*)",\s*"festnetz":\s*"([^"]*)",\s*"mobilfunk":\s*"([^"]*)",\s*"email":\s*"([^"]*)",\s*"eintrittsdatum":\s*"([^"]*)",\s*"funktion":\s*"[^"]*"\s*\}}

        # Alle Übereinstimmungen finden und durchlaufen
        set start 0
        while {[regexp -start $start -indices $pattern $json_content match]} {
            # Position des Matches ermitteln
            set match_start [lindex $match 0]
            set match_end [lindex $match 1]

            # Match-Text extrahieren
            set match_text [string range $json_content $match_start $match_end]

            # Einzelne Felder extrahieren mit individuellen Regex-Patterns
            regexp {"nachname":\s*"([^"]*)"} $match_text -> nachname
            regexp {"vorname":\s*"([^"]*)"} $match_text -> vorname
            regexp {"strasse":\s*"([^"]*)"} $match_text -> strasse
            regexp {"plz":\s*"([^"]*)"} $match_text -> plz
            regexp {"ort":\s*"([^"]*)"} $match_text -> ort
            regexp {"festnetz":\s*"([^"]*)"} $match_text -> festnetz
            regexp {"mobilfunk":\s*"([^"]*)"} $match_text -> mobilfunk
            regexp {"email":\s*"([^"]*)"} $match_text -> email
            regexp {"geburtsdatum":\s*"([^"]*)"} $match_text -> geburtsdatum
            regexp {"eintrittsdatum":\s*"([^"]*)"} $match_text -> eintrittsdatum
            regexp {"funktion":\s*"([^"]*)"} $match_text -> funktion

            # Mitglied als Liste zur globalen Liste hinzufügen (inklusive funktion)
            lappend ::mitglieder_liste [list $nachname $vorname $strasse $plz $ort $festnetz $mobilfunk $email $geburtsdatum $eintrittsdatum $funktion]

            # Nächste Suche nach diesem Match starten
            set start [expr {$match_end + 1}]
        }

        # Alle Mitglieder im Textwidget anzeigen
        zeige_alle_mitglieder

    } else {
        # Datei existiert nicht (z.B. beim ersten Programmstart)
        # Verzeichnis anlegen falls nötig
        set json_dir [file dirname $mitglieder_json]
        if {![file exists $json_dir]} {
            file mkdir $json_dir
        }

        # Leere JSON-Datei mit korrekter Struktur erstellen,
        # damit der Anwender sofort Mitglieder hinzufügen kann.
        # ::mitglieder_liste ist zu diesem Zeitpunkt bereits leer ({}).
        schreibe_mitglieder_json
    }

    # =============================================================================
    # ESC-Taste zum Zurücksetzen der Suche binden
    # =============================================================================

    # ESC-Taste im Mitglieder-Fenster binden
    # Zeigt die komplette Liste wieder an
    bind .mitglieder <Escape> {
        zeige_alle_mitglieder
    }

    # =============================================================================
    # Tastatur-Shortcuts für das Mitglieder-Fenster
    # =============================================================================

    # Strg+S für Suchen
    bind .mitglieder <Control-s> {.mitglieder.toolbar.search invoke}
    bind .mitglieder <Control-S> {.mitglieder.toolbar.search invoke}

    # Strg+N für Hinzufügen
    bind .mitglieder <Control-n> {.mitglieder.toolbar.add invoke}
    bind .mitglieder <Control-N> {.mitglieder.toolbar.add invoke}
}
