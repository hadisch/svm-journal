# =============================================================================
# Eintrag-Bearbeiten-Funktionalität
# Ermöglicht das Bearbeiten von Journal-Einträgen aus dem Hauptfenster
# =============================================================================

# Globale Variable für den markierten Eintrag
# Speichert ein Dictionary mit allen Daten des ausgewählten Eintrags
set ::markierter_eintrag [dict create]

# =============================================================================
# Prozedur: oeffne_bearbeiten_dialog
# Öffnet den Dialog zum Bearbeiten eines Eintrags
# =============================================================================
proc oeffne_bearbeiten_dialog {} {
    # Prüfen ob ein Eintrag markiert ist
    if {[dict size $::markierter_eintrag] == 0} {
        tk_messageBox -icon warning \
                      -type ok \
                      -title "Bearbeiten" \
                      -message "Bitte wählen Sie zunächst einen Eintrag aus der Liste aus."
        return
    }

    # Prüfen, ob Dialog bereits existiert
    if {[winfo exists .eintrag_bearbeiten]} {
        raise .eintrag_bearbeiten
        focus .eintrag_bearbeiten
        return
    }

    # Daten aus dem markierten Eintrag extrahieren
    set alt_datum [dict get $::markierter_eintrag datum]
    set alt_uhrzeit [dict get $::markierter_eintrag uhrzeit]
    set alt_nachname [dict get $::markierter_eintrag nachname]
    set alt_vorname [dict get $::markierter_eintrag vorname]
    set alt_kurzwaffe [dict get $::markierter_eintrag kurzwaffe]
    set alt_langwaffe [dict get $::markierter_eintrag langwaffe]
    set alt_waffentyp [dict get $::markierter_eintrag waffentyp]
    set alt_kaliber [dict get $::markierter_eintrag kaliber]
    set alt_startgeld [dict get $::markierter_eintrag startgeld]
    set alt_munition [dict get $::markierter_eintrag munition]
    set alt_munitionspreis [dict get $::markierter_eintrag munitionspreis]

    # Kurzwaffe und Langwaffe in Boolesche Werte konvertieren
    set kurzwaffe_bool [expr {$alt_kurzwaffe eq "Ja" ? 1 : 0}]
    set langwaffe_bool [expr {$alt_langwaffe eq "Ja" ? 1 : 0}]

    # Neues Toplevel-Fenster erstellen
    toplevel .eintrag_bearbeiten

    # Fenstertitel setzen
    wm title .eintrag_bearbeiten "Eintrag bearbeiten"

    # Fenstergröße festlegen
    wm geometry .eintrag_bearbeiten 720x550

    # Hauptframe mit Padding
    frame .eintrag_bearbeiten.main -padx 20 -pady 20
    pack .eintrag_bearbeiten.main -fill both -expand 1

    # =========================================================================
    # Datum-Eingabefeld
    # =========================================================================
    frame .eintrag_bearbeiten.main.datum_frame
    pack .eintrag_bearbeiten.main.datum_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.datum_frame.label -text "Datum:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.datum_frame.label -side left

    entry .eintrag_bearbeiten.main.datum_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.datum_frame.entry insert 0 $alt_datum
    pack .eintrag_bearbeiten.main.datum_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Name-Eingabefeld
    # =========================================================================
    frame .eintrag_bearbeiten.main.name_frame
    pack .eintrag_bearbeiten.main.name_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.name_frame.label -text "Nachname:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.name_frame.label -side left

    entry .eintrag_bearbeiten.main.name_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.name_frame.entry insert 0 $alt_nachname
    pack .eintrag_bearbeiten.main.name_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Vorname-Eingabefeld
    # =========================================================================
    frame .eintrag_bearbeiten.main.vorname_frame
    pack .eintrag_bearbeiten.main.vorname_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.vorname_frame.label -text "Vorname:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.vorname_frame.label -side left

    entry .eintrag_bearbeiten.main.vorname_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.vorname_frame.entry insert 0 $alt_vorname
    pack .eintrag_bearbeiten.main.vorname_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Waffen-Checkboxen (KW/LW)
    # =========================================================================
    frame .eintrag_bearbeiten.main.waffen_frame
    pack .eintrag_bearbeiten.main.waffen_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.waffen_frame.label -text "Waffe:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.waffen_frame.label -side left

    # Variable für Kurzwaffe
    set ::eintrag_bearbeiten_kurzwaffe $kurzwaffe_bool
    checkbutton .eintrag_bearbeiten.main.waffen_frame.kw -text "Kurzwaffe (KW)" \
        -variable ::eintrag_bearbeiten_kurzwaffe
    pack .eintrag_bearbeiten.main.waffen_frame.kw -side left -padx 5

    # Variable für Langwaffe
    set ::eintrag_bearbeiten_langwaffe $langwaffe_bool
    checkbutton .eintrag_bearbeiten.main.waffen_frame.lw -text "Langwaffe (LW)" \
        -variable ::eintrag_bearbeiten_langwaffe
    pack .eintrag_bearbeiten.main.waffen_frame.lw -side left -padx 5

    # =========================================================================
    # Waffentyp-Auswahl (LD/KK/GK)
    # =========================================================================
    frame .eintrag_bearbeiten.main.typ_frame
    pack .eintrag_bearbeiten.main.typ_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.typ_frame.label -text "Waffentyp:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.typ_frame.label -side left

    # Variable für Waffentyp
    set ::eintrag_bearbeiten_waffentyp $alt_waffentyp

    radiobutton .eintrag_bearbeiten.main.typ_frame.ld -text "Luftdruck (LD)" \
        -variable ::eintrag_bearbeiten_waffentyp -value "LD"
    pack .eintrag_bearbeiten.main.typ_frame.ld -side left -padx 5

    radiobutton .eintrag_bearbeiten.main.typ_frame.kk -text "Kleinkaliber (KK)" \
        -variable ::eintrag_bearbeiten_waffentyp -value "KK"
    pack .eintrag_bearbeiten.main.typ_frame.kk -side left -padx 5

    radiobutton .eintrag_bearbeiten.main.typ_frame.gk -text "Großkaliber (GK)" \
        -variable ::eintrag_bearbeiten_waffentyp -value "GK"
    pack .eintrag_bearbeiten.main.typ_frame.gk -side left -padx 5

    # =========================================================================
    # Kaliber-Eingabefeld
    # =========================================================================
    frame .eintrag_bearbeiten.main.kaliber_frame
    pack .eintrag_bearbeiten.main.kaliber_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.kaliber_frame.label -text "Kaliber:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.kaliber_frame.label -side left

    entry .eintrag_bearbeiten.main.kaliber_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.kaliber_frame.entry insert 0 $alt_kaliber
    pack .eintrag_bearbeiten.main.kaliber_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Startgeld-Eingabefeld
    # =========================================================================
    frame .eintrag_bearbeiten.main.startgeld_frame
    pack .eintrag_bearbeiten.main.startgeld_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.startgeld_frame.label -text "Startgeld (€):" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.startgeld_frame.label -side left

    entry .eintrag_bearbeiten.main.startgeld_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.startgeld_frame.entry insert 0 $alt_startgeld
    pack .eintrag_bearbeiten.main.startgeld_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Munition-Eingabefeld (Textfeld, da mehrere Kaliber möglich)
    # =========================================================================
    frame .eintrag_bearbeiten.main.munition_frame
    pack .eintrag_bearbeiten.main.munition_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.munition_frame.label -text "Munition:" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.munition_frame.label -side left

    entry .eintrag_bearbeiten.main.munition_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.munition_frame.entry insert 0 $alt_munition
    pack .eintrag_bearbeiten.main.munition_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Munitionspreis-Eingabefeld
    # =========================================================================
    frame .eintrag_bearbeiten.main.munitionspreis_frame
    pack .eintrag_bearbeiten.main.munitionspreis_frame -fill x -pady 5

    label .eintrag_bearbeiten.main.munitionspreis_frame.label -text "Munitionspreis (€):" -width 20 -anchor w
    pack .eintrag_bearbeiten.main.munitionspreis_frame.label -side left

    entry .eintrag_bearbeiten.main.munitionspreis_frame.entry -font {TkDefaultFont 11}
    .eintrag_bearbeiten.main.munitionspreis_frame.entry insert 0 $alt_munitionspreis
    pack .eintrag_bearbeiten.main.munitionspreis_frame.entry -side left -fill x -expand 1

    # =========================================================================
    # Hinweis-Label
    # =========================================================================
    label .eintrag_bearbeiten.main.hinweis -text "Hinweis: Datum und Uhrzeit können nicht geändert werden." \
        -fg "#666666" -font {Arial 9 italic} -anchor w
    pack .eintrag_bearbeiten.main.hinweis -pady 10

    # =========================================================================
    # Button-Frame
    # =========================================================================
    frame .eintrag_bearbeiten.main.button_frame
    pack .eintrag_bearbeiten.main.button_frame -fill x -pady 20

    # Button "Abbrechen"
    button .eintrag_bearbeiten.main.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 15 \
        -command {destroy .eintrag_bearbeiten}
    pack .eintrag_bearbeiten.main.button_frame.abbrechen -side right -padx 5

    # Button "Speichern"
    button .eintrag_bearbeiten.main.button_frame.speichern -text "Speichern" -bg "#90EE90" -width 15 \
        -command {
        # Error-Handling für gesamten Speichervorgang
        if {[catch {
            # Werte aus Eingabefeldern holen
            set datum [string trim [.eintrag_bearbeiten.main.datum_frame.entry get]]
            set nachname [string trim [.eintrag_bearbeiten.main.name_frame.entry get]]
            set vorname [string trim [.eintrag_bearbeiten.main.vorname_frame.entry get]]
            set kurzwaffe [expr {$::eintrag_bearbeiten_kurzwaffe ? "Ja" : "Nein"}]
            set langwaffe [expr {$::eintrag_bearbeiten_langwaffe ? "Ja" : "Nein"}]
            set waffentyp $::eintrag_bearbeiten_waffentyp
            set kaliber [string trim [.eintrag_bearbeiten.main.kaliber_frame.entry get]]
            set startgeld [string trim [.eintrag_bearbeiten.main.startgeld_frame.entry get]]
            set munition [string trim [.eintrag_bearbeiten.main.munition_frame.entry get]]
            set munitionspreis [string trim [.eintrag_bearbeiten.main.munitionspreis_frame.entry get]]

            # Alte Uhrzeit beibehalten
            set uhrzeit [dict get $::markierter_eintrag uhrzeit]

            # Prüfen ob Pflichtfelder ausgefüllt sind
            if {$datum eq "" || $nachname eq "" || $vorname eq "" || $kaliber eq ""} {
                tk_messageBox -parent .eintrag_bearbeiten \
                              -icon warning \
                              -type ok \
                              -title "Fehlende Eingaben" \
                              -message "Bitte füllen Sie alle Pflichtfelder aus:\nDatum, Nachname, Vorname, Kaliber"
                return
            }

            # Mindestens eine Waffe muss ausgewählt sein
            if {!$::eintrag_bearbeiten_kurzwaffe && !$::eintrag_bearbeiten_langwaffe} {
                tk_messageBox -parent .eintrag_bearbeiten \
                              -icon warning \
                              -type ok \
                              -title "Fehlende Auswahl" \
                              -message "Bitte wählen Sie mindestens eine Waffe aus (Kurzwaffe oder Langwaffe)."
                return
            }

            # Waffentyp muss ausgewählt sein
            if {$waffentyp eq ""} {
                tk_messageBox -parent .eintrag_bearbeiten \
                              -icon warning \
                              -type ok \
                              -title "Fehlende Auswahl" \
                              -message "Bitte wählen Sie einen Waffentyp aus (LD, KK oder GK)."
                return
            }

            # Alten Eintrag aus JSON-Datei löschen
            # Jahr aus dem Datum extrahieren
            regexp {^\d{2}\.\d{2}\.(\d{4})$} $datum -> jahr
            set aktuelles_jahr [clock format [clock seconds] -format "%Y"]

            # Pfad zur Jahres-JSON-Datei bestimmen
            if {$jahr < $aktuelles_jahr} {
                set archiv_dir [::pfad::get_archiv_directory]
                set jahres_json [file join $archiv_dir "${jahr}.json"]
            } else {
                set jahres_json [::pfad::get_jahres_json_path $jahr]
            }

            # Alle Einträge aus der Datei laden
            set alle_eintraege [::neuer_eintrag::lade_eintraege_aus_datei $jahres_json]

            # Zu aktualisierenden Eintrag finden und entfernen
            set neue_eintraege [list]
            set eintrag_gefunden 0

            # Alte Werte aus markiertem Eintrag holen
            set alt_datum [dict get $::markierter_eintrag datum]
            set alt_uhrzeit [dict get $::markierter_eintrag uhrzeit]
            set alt_nachname [dict get $::markierter_eintrag nachname]
            set alt_vorname [dict get $::markierter_eintrag vorname]
            set alt_kaliber [dict get $::markierter_eintrag kaliber]

            foreach eintrag $alle_eintraege {
                # Prüfen ob dies der zu aktualisierende Eintrag ist
                set e_datum [dict get $eintrag datum]
                set e_uhrzeit [dict get $eintrag uhrzeit]
                set e_nachname [dict get $eintrag nachname]
                set e_vorname [dict get $eintrag vorname]
                set e_kaliber [dict get $eintrag kaliber]

                if {$e_datum eq $alt_datum && $e_uhrzeit eq $alt_uhrzeit &&
                    $e_nachname eq $alt_nachname && $e_vorname eq $alt_vorname &&
                    $e_kaliber eq $alt_kaliber} {
                    # Dies ist der zu aktualisierende Eintrag - nicht zur neuen Liste hinzufügen
                    set eintrag_gefunden 1
                } else {
                    # Eintrag behalten
                    lappend neue_eintraege $eintrag
                }
            }

            # Neuen (aktualisierten) Eintrag hinzufügen
            set neuer_eintrag [dict create \
                "datum" $datum \
                "uhrzeit" $uhrzeit \
                "nachname" $nachname \
                "vorname" $vorname \
                "kurzwaffe" $kurzwaffe \
                "langwaffe" $langwaffe \
                "waffentyp" $waffentyp \
                "kaliber" $kaliber \
                "startgeld" $startgeld \
                "anzahl" "1" \
                "munition" $munition \
                "munitionspreis" $munitionspreis \
            ]
            lappend neue_eintraege $neuer_eintrag

            # JSON-Datei neu schreiben
            schreibe_eintraege_json $jahres_json $neue_eintraege

            # Treeview aktualisieren
            aktualisiere_treeview

            # Markierung zurücksetzen
            set ::markierter_eintrag [dict create]

            # Dialog schließen
            destroy .eintrag_bearbeiten

            # Erfolgs-Meldung
            tk_messageBox -icon info \
                          -type ok \
                          -title "Bearbeiten erfolgreich" \
                          -message "Der Eintrag wurde erfolgreich aktualisiert."
        } error_msg]} {
            # Fehler anzeigen falls etwas schief geht
            tk_messageBox -parent .eintrag_bearbeiten \
                          -icon error \
                          -type ok \
                          -title "Fehler beim Speichern" \
                          -message "Es ist ein Fehler aufgetreten:\n\n$error_msg"
        }
    }
    pack .eintrag_bearbeiten.main.button_frame.speichern -side right -padx 5

    # Fokus auf erstes Eingabefeld setzen
    focus .eintrag_bearbeiten.main.datum_frame.entry
}
