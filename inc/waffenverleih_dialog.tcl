# =============================================================================
# Waffenverleih-Dialog
# Dokumentation von Waffenausleihen mit HTML-Export
# =============================================================================

# Namespace für Waffenverleih-Verwaltung
namespace eval ::waffenverleih {
    # Dialog-Variablen
    variable fenster ""

    # Geladene Waffenliste für Referenz
    variable waffen_liste [list]

    # Verleihtyp-Checkboxen
    variable typ_leihe 0
    variable typ_verwahrung 0
    variable typ_transport 0
    variable typ_vereinsbeauftragter 0

    # Vorübergehender Besitzer (alle Pflicht)
    variable besitzer_name ""
    variable besitzer_vorname ""
    variable besitzer_geburtsdatum ""
    variable besitzer_geburtsort ""
    variable besitzer_strasse ""
    variable besitzer_hausnummer ""
    variable besitzer_plz ""
    variable besitzer_ort ""
    variable besitzer_wbk_nummer ""
    variable besitzer_wbk_behoerde ""

    # Überlasser (aus verein.json vorausgefüllt)
    variable ueberlasser_name ""
    variable ueberlasser_strasse ""
    variable ueberlasser_plz ""
    variable ueberlasser_ort ""
    variable ueberlasser_tel ""
    variable ueberlasser_email ""
    variable ueberlasser_register ""
}

# =============================================================================
# Prozedur: lade_waffen_fuer_checkboxen
# Lädt alle Waffen aus waffenregister.json
# Rückgabe: Liste von Waffendicts
# =============================================================================
proc ::waffenverleih::lade_waffen_fuer_checkboxen {} {
    global waffenregister_json
    global behoerde_json

    set waffen_liste [list]

    # Prüfen, ob Datei existiert
    if {![file exists $waffenregister_json]} {
        return $waffen_liste
    }

    # Behörden-Name laden
    set behoerden_name ""
    if {[file exists $behoerde_json]} {
        # Behörden-JSON öffnen und parsen
        set fp_beh [open $behoerde_json r]
        fconfigure $fp_beh -encoding utf-8
        set json_beh_content [read $fp_beh]
        close $fp_beh

        # Name extrahieren
        set beh_lines [split $json_beh_content "\n"]
        foreach beh_line $beh_lines {
            if {[regexp {"name":\s*"([^"]*)"} $beh_line -> wert]} {
                set behoerden_name [string trim $wert]
                break
            }
        }
    }

    # Datei öffnen und parsen (gleiche Logik wie Waffenregister)
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
            if {[regexp {"art":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon art [string trim $wert]
            }
            if {[regexp {"kaliber":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon kaliber [string trim $wert]
            }
            if {[regexp {"seriennummer":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon seriennummer [string trim $wert]
            }
            if {[regexp {"wbk_nummer":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon wbk_nummer [string trim $wert]
            }
            if {[regexp {"hersteller":\s*"([^"]*)"} $line -> wert]} {
                dict set current_weapon hersteller [string trim $wert]
            }

            # Ende eines Waffen-Objekts erkennen
            if {[regexp {\}\s*,?\s*$} $line]} {
                if {[dict size $current_weapon] > 0} {
                    # Behörden-Name zur Waffe hinzufügen (ausstellende Behörde der WBK)
                    if {$behoerden_name ne ""} {
                        dict set current_weapon ausstellende_behoerde $behoerden_name
                    }
                    lappend waffen_liste $current_weapon
                    set current_weapon [dict create]
                }
            }
        }
    }

    return $waffen_liste
}

# =============================================================================
# Prozedur: lade_verein_daten_fuer_ueberlasser
# Lädt Vereinsdaten aus verein.json
# Füllt die ueberlasser_* Variablen
# =============================================================================
proc ::waffenverleih::lade_verein_daten_fuer_ueberlasser {} {
    global verein_json

    # Variablen initialisieren
    variable ueberlasser_name
    variable ueberlasser_strasse
    variable ueberlasser_plz
    variable ueberlasser_ort
    variable ueberlasser_tel
    variable ueberlasser_email
    variable ueberlasser_register

    # Alle Felder zurücksetzen
    set ueberlasser_name ""
    set ueberlasser_strasse ""
    set ueberlasser_plz ""
    set ueberlasser_ort ""
    set ueberlasser_tel ""
    set ueberlasser_email ""
    set ueberlasser_register ""

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
        if {[regexp {"vereinsname":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_name [string trim $wert]
        }
        if {[regexp {"strasse":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_strasse [string trim $wert]
        }
        if {[regexp {"plz":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_plz [string trim $wert]
        }
        if {[regexp {"ort":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_ort [string trim $wert]
        }
        if {[regexp {"telefon":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_tel [string trim $wert]
        }
        if {[regexp {"email":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_email [string trim $wert]
        }
        if {[regexp {"registereintrag":\s*"([^"]*)"} $line -> wert]} {
            set ueberlasser_register [string trim $wert]
        }
    }
}

# =============================================================================
# Prozedur: suche_mitglied_nach_nachname
# Sucht Mitglieder in mitglieder.json nach Nachnamen
# Parameter:
#   nachname - Der zu suchende Nachname
# Rückgabe: Liste von Mitglieds-Dictionaries
# =============================================================================
proc ::waffenverleih::suche_mitglied_nach_nachname {nachname} {
    global mitglieder_json

    # Nachname trimmen und für Vergleich vorbereiten
    set nachname [string trim $nachname]

    # Leerer Nachname - keine Suche
    if {$nachname eq ""} {
        return [list]
    }

    # Prüfen, ob Datei existiert
    if {![file exists $mitglieder_json]} {
        return [list]
    }

    # Datei öffnen und parsen
    set fp [open $mitglieder_json r]
    fconfigure $fp -encoding utf-8
    set json_content [read $fp]
    close $fp

    # Mitglieder aus JSON extrahieren
    set lines [split $json_content "\n"]
    set mitglieder [list]
    set current_member [dict create]

    foreach line $lines {
        # Felder extrahieren
        if {[regexp {"nachname":\s*"([^"]*)"} $line -> wert]} {
            dict set current_member nachname [string trim $wert]
        }
        if {[regexp {"vorname":\s*"([^"]*)"} $line -> wert]} {
            dict set current_member vorname [string trim $wert]
        }
        if {[regexp {"geburtsdatum":\s*"([^"]*)"} $line -> wert]} {
            dict set current_member geburtsdatum [string trim $wert]
        }
        if {[regexp {"strasse":\s*"([^"]*)"} $line -> wert]} {
            dict set current_member strasse [string trim $wert]
        }
        if {[regexp {"plz":\s*"([^"]*)"} $line -> wert]} {
            dict set current_member plz [string trim $wert]
        }
        if {[regexp {"ort":\s*"([^"]*)"} $line -> wert]} {
            dict set current_member ort [string trim $wert]
        }

        # Ende eines Mitglieds-Objekts
        if {[regexp {\}\s*,?\s*$} $line] && [dict size $current_member] > 0} {
            lappend mitglieder $current_member
            set current_member [dict create]
        }
    }

    # Nach Nachnamen filtern (case-insensitive)
    set gefundene_mitglieder [list]
    foreach mitglied $mitglieder {
        if {[dict exists $mitglied nachname]} {
            set mitglied_nachname [dict get $mitglied nachname]
            # Case-insensitive Vergleich
            if {[string equal -nocase $mitglied_nachname $nachname]} {
                lappend gefundene_mitglieder $mitglied
            }
        }
    }

    return $gefundene_mitglieder
}

# =============================================================================
# Prozedur: trenne_strasse_hausnummer
# Trennt Straße und Hausnummer
# Parameter:
#   strasse_komplett - Straße mit Hausnummer (z.B. "Musterstraße 1" oder "Hauptstr. 42a")
# Rückgabe: Dictionary mit {strasse "..." hausnummer "..."}
# =============================================================================
proc ::waffenverleih::trenne_strasse_hausnummer {strasse_komplett} {
    set strasse_komplett [string trim $strasse_komplett]

    # Versuche, die Hausnummer am Ende zu finden
    # Pattern: Straßenname gefolgt von Leerzeichen und Hausnummer (Ziffern + optionale Buchstaben)
    if {[regexp {^(.+)\s+(\d+\w*)$} $strasse_komplett -> strasse hausnummer]} {
        return [dict create strasse [string trim $strasse] hausnummer [string trim $hausnummer]]
    }

    # Falls kein Match, gesamten String als Straße zurückgeben
    return [dict create strasse $strasse_komplett hausnummer ""]
}

# =============================================================================
# Prozedur: fulle_felder_aus_mitglied
# Füllt die Eingabefelder mit Mitgliedsdaten
# Parameter:
#   mitglied - Dictionary mit Mitgliedsdaten
# =============================================================================
proc ::waffenverleih::fulle_felder_aus_mitglied {mitglied} {
    variable besitzer_vorname
    variable besitzer_geburtsdatum
    variable besitzer_strasse
    variable besitzer_hausnummer
    variable besitzer_plz
    variable besitzer_ort

    # Vorname
    if {[dict exists $mitglied vorname]} {
        set besitzer_vorname [dict get $mitglied vorname]
    }

    # Geburtsdatum
    if {[dict exists $mitglied geburtsdatum]} {
        set besitzer_geburtsdatum [dict get $mitglied geburtsdatum]
    }

    # Straße und Hausnummer trennen
    if {[dict exists $mitglied strasse]} {
        set strasse_komplett [dict get $mitglied strasse]
        set trennung [trenne_strasse_hausnummer $strasse_komplett]
        set besitzer_strasse [dict get $trennung strasse]
        set besitzer_hausnummer [dict get $trennung hausnummer]
    }

    # PLZ
    if {[dict exists $mitglied plz]} {
        set besitzer_plz [dict get $mitglied plz]
    }

    # Ort
    if {[dict exists $mitglied ort]} {
        set besitzer_ort [dict get $mitglied ort]
    }
}

# =============================================================================
# Prozedur: pruefe_und_fulle_mitglied
# Prüft, ob ein Mitglied mit dem eingegebenen Nachnamen existiert und füllt Felder aus
# =============================================================================
proc ::waffenverleih::pruefe_und_fulle_mitglied {} {
    variable besitzer_name
    variable fenster

    # Nachname holen und trimmen
    set nachname [string trim $besitzer_name]

    # Wenn leer, nichts tun
    if {$nachname eq ""} {
        return
    }

    # Nach Mitglied suchen
    set gefundene_mitglieder [suche_mitglied_nach_nachname $nachname]

    # Anzahl gefundener Mitglieder
    set anzahl [llength $gefundene_mitglieder]

    if {$anzahl == 0} {
        # Kein Mitglied gefunden - Felder leer lassen
        return
    } elseif {$anzahl == 1} {
        # Genau ein Mitglied gefunden - Felder automatisch ausfüllen
        set mitglied [lindex $gefundene_mitglieder 0]
        fulle_felder_aus_mitglied $mitglied

        # Kurze Bestätigung (optional)
        if {[winfo exists $fenster]} {
            set vorname [dict get $mitglied vorname]
            # Temporäres Label mit Bestätigung (nach 2 Sekunden ausblenden)
            if {![winfo exists $fenster.canvas.main.besitzer_frame.bestaetigung]} {
                label $fenster.canvas.main.besitzer_frame.bestaetigung \
                    -text "✓ Mitglied gefunden: $vorname $nachname" \
                    -fg "green" -font {Arial 9 bold}
                pack $fenster.canvas.main.besitzer_frame.bestaetigung -anchor w -pady 2 -before $fenster.canvas.main.besitzer_frame.hinweis
            } else {
                $fenster.canvas.main.besitzer_frame.bestaetigung configure \
                    -text "✓ Mitglied gefunden: $vorname $nachname"
            }
            after 3000 [list catch {destroy $fenster.canvas.main.besitzer_frame.bestaetigung}]
        }
    } else {
        # Mehrere Mitglieder gefunden - Auswahl anbieten
        zeige_mitglieder_auswahl $gefundene_mitglieder
    }
}

# =============================================================================
# Prozedur: zeige_mitglieder_auswahl
# Zeigt Dialog zur Auswahl eines Mitglieds, wenn mehrere gefunden wurden
# Parameter:
#   mitglieder - Liste von Mitglieds-Dictionaries
# =============================================================================
proc ::waffenverleih::zeige_mitglieder_auswahl {mitglieder} {
    variable fenster

    # Auswahl-Dialog erstellen
    set dialog $fenster.mitglied_auswahl

    # Falls Dialog bereits existiert, entfernen
    if {[winfo exists $dialog]} {
        destroy $dialog
    }

    # Toplevel für Auswahl
    toplevel $dialog
    wm title $dialog "Mitglied auswählen"
    wm transient $dialog $fenster
    wm geometry $dialog "400x300"

    # Beschreibung
    label $dialog.label -text "Mehrere Mitglieder mit diesem Nachnamen gefunden.\nBitte wählen Sie das gewünschte Mitglied:" \
        -justify left -anchor w
    pack $dialog.label -padx 10 -pady 10 -fill x

    # Listbox mit Scrollbar
    frame $dialog.list_frame
    pack $dialog.list_frame -padx 10 -pady 10 -fill both -expand 1

    listbox $dialog.list_frame.listbox -height 10 -font {Arial 10}
    scrollbar $dialog.list_frame.scroll -command "$dialog.list_frame.listbox yview"
    $dialog.list_frame.listbox configure -yscrollcommand "$dialog.list_frame.scroll set"

    pack $dialog.list_frame.scroll -side right -fill y
    pack $dialog.list_frame.listbox -side left -fill both -expand 1

    # Mitglieder in Listbox einfügen
    set index 0
    foreach mitglied $mitglieder {
        set nachname [dict get $mitglied nachname]
        set vorname [dict get $mitglied vorname]
        set geburtsdatum ""
        if {[dict exists $mitglied geburtsdatum]} {
            set geburtsdatum [dict get $mitglied geburtsdatum]
        }
        set text "$vorname $nachname"
        if {$geburtsdatum ne ""} {
            append text " (*$geburtsdatum)"
        }
        $dialog.list_frame.listbox insert end $text
        incr index
    }

    # Button-Frame
    frame $dialog.buttons
    pack $dialog.buttons -pady 10

    # Auswählen-Button
    button $dialog.buttons.select -text "Auswählen" -bg "#90EE90" -width 15 -command [list ::waffenverleih::mitglied_ausgewaehlt $dialog $mitglieder]
    pack $dialog.buttons.select -side left -padx 5

    # Abbrechen-Button
    button $dialog.buttons.cancel -text "Abbrechen" -bg "#FFB6C1" -width 15 -command "destroy $dialog"
    pack $dialog.buttons.cancel -side left -padx 5

    # Erstes Element vorauswählen
    $dialog.list_frame.listbox selection set 0

    # Doppelklick zum Auswählen
    bind $dialog.list_frame.listbox <Double-Button-1> [list ::waffenverleih::mitglied_ausgewaehlt $dialog $mitglieder]
}

# =============================================================================
# Prozedur: mitglied_ausgewaehlt
# Wird aufgerufen, wenn ein Mitglied aus der Auswahl gewählt wurde
# Parameter:
#   dialog - Dialog-Fenster
#   mitglieder - Liste aller Mitglieder
# =============================================================================
proc ::waffenverleih::mitglied_ausgewaehlt {dialog mitglieder} {
    # Ausgewählten Index holen
    set listbox $dialog.list_frame.listbox
    set selection [$listbox curselection]

    if {$selection eq ""} {
        tk_messageBox -parent $dialog -icon warning -title "Fehler" \
            -message "Bitte wählen Sie ein Mitglied aus."
        return
    }

    # Mitglied aus Liste holen
    set mitglied [lindex $mitglieder $selection]

    # Felder ausfüllen
    fulle_felder_aus_mitglied $mitglied

    # Dialog schließen
    destroy $dialog
}

# =============================================================================
# Prozedur: validiere_und_exportiere
# Validiert alle Eingaben und ruft HTML-Export auf
# =============================================================================
proc ::waffenverleih::validiere_und_exportiere {} {
    variable fenster
    variable waffen_liste
    variable typ_leihe
    variable typ_verwahrung
    variable typ_transport
    variable typ_vereinsbeauftragter
    variable besitzer_name
    variable besitzer_vorname
    variable besitzer_geburtsdatum
    variable besitzer_geburtsort
    variable besitzer_strasse
    variable besitzer_hausnummer
    variable besitzer_plz
    variable besitzer_ort
    variable besitzer_wbk_nummer
    variable besitzer_wbk_behoerde
    variable ueberlasser_name
    variable ueberlasser_strasse
    variable ueberlasser_plz
    variable ueberlasser_ort
    variable ueberlasser_tel
    variable ueberlasser_email
    variable ueberlasser_register

    # SCHRITT 1: Mindestens eine Waffe ausgewählt
    set anzahl_waffen 0
    set ausgewaehlte_waffen [list]

    # Durch alle Waffen iterieren und Checkboxen prüfen
    for {set i 0} {$i < [llength $waffen_liste]} {incr i} {
        # Prüfen ob Checkbox-Variable existiert und gesetzt ist
        set varname "::waffenverleih::waffen_check_${i}"
        if {[info exists $varname]} {
            set wert [set $varname]
            if {$wert} {
                incr anzahl_waffen
                lappend ausgewaehlte_waffen [lindex $waffen_liste $i]
            }
        }
    }

    if {$anzahl_waffen == 0} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte wählen Sie mindestens eine Waffe aus."
        return
    }

    # SCHRITT 2: Mindestens ein Verleihtyp ausgewählt
    if {!$typ_leihe && !$typ_verwahrung && !$typ_transport && !$typ_vereinsbeauftragter} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte wählen Sie mindestens eine Art des Verleihs aus."
        return
    }

    # SCHRITT 3: WBK-Logik
    set wbk_erforderlich [expr {$typ_leihe || $typ_verwahrung}]

    # SCHRITT 4: Alle Besitzer-Felder validieren
    set besitzer_name [string trim $besitzer_name]
    set besitzer_vorname [string trim $besitzer_vorname]
    set besitzer_geburtsdatum [string trim $besitzer_geburtsdatum]
    set besitzer_geburtsort [string trim $besitzer_geburtsort]
    set besitzer_strasse [string trim $besitzer_strasse]
    set besitzer_hausnummer [string trim $besitzer_hausnummer]
    set besitzer_plz [string trim $besitzer_plz]
    set besitzer_ort [string trim $besitzer_ort]
    set besitzer_wbk_nummer [string trim $besitzer_wbk_nummer]
    set besitzer_wbk_behoerde [string trim $besitzer_wbk_behoerde]

    # Jedes Feld einzeln prüfen
    if {$besitzer_name eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie den Namen des vorübergehenden Besitzers ein."
        return
    }
    if {$besitzer_vorname eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie den Vornamen des vorübergehenden Besitzers ein."
        return
    }
    if {$besitzer_geburtsdatum eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie das Geburtsdatum ein."
        return
    }
    if {$besitzer_geburtsort eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie den Geburtsort ein."
        return
    }
    if {$besitzer_strasse eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie die Straße ein."
        return
    }
    if {$besitzer_hausnummer eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie die Hausnummer ein."
        return
    }
    if {$besitzer_plz eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie die PLZ ein."
        return
    }
    if {$besitzer_ort eq ""} {
        tk_messageBox -parent $fenster -icon warning -title "Fehler" \
            -message "Bitte geben Sie den Ort ein."
        return
    }
    # WBK-Felder nur validieren, wenn WBK erforderlich ist (Leihe oder Verwahrung)
    if {$wbk_erforderlich} {
        if {$besitzer_wbk_nummer eq ""} {
            tk_messageBox -parent $fenster -icon warning -title "Fehler" \
                -message "Bei Leihe und Verwahrung ist die WBK-Nummer erforderlich."
            return
        }
        if {$besitzer_wbk_behoerde eq ""} {
            tk_messageBox -parent $fenster -icon warning -title "Fehler" \
                -message "Bei Leihe und Verwahrung ist die ausstellende Behörde erforderlich."
            return
        }
    }

    # SCHRITT 5: Daten-Dict aufbauen
    set export_data [dict create]

    # Ausgewählte Waffen
    dict set export_data waffen $ausgewaehlte_waffen

    # Verleihtypen
    dict set export_data typ_leihe $typ_leihe
    dict set export_data typ_verwahrung $typ_verwahrung
    dict set export_data typ_transport $typ_transport
    dict set export_data typ_vereinsbeauftragter $typ_vereinsbeauftragter
    dict set export_data wbk_erforderlich $wbk_erforderlich

    # Besitzer-Daten
    dict set export_data besitzer_name $besitzer_name
    dict set export_data besitzer_vorname $besitzer_vorname
    dict set export_data besitzer_geburtsdatum $besitzer_geburtsdatum
    dict set export_data besitzer_geburtsort $besitzer_geburtsort
    dict set export_data besitzer_strasse $besitzer_strasse
    dict set export_data besitzer_hausnummer $besitzer_hausnummer
    dict set export_data besitzer_plz $besitzer_plz
    dict set export_data besitzer_ort $besitzer_ort
    dict set export_data besitzer_wbk_nummer $besitzer_wbk_nummer
    dict set export_data besitzer_wbk_behoerde $besitzer_wbk_behoerde

    # Überlasser-Daten
    dict set export_data ueberlasser_name $ueberlasser_name
    dict set export_data ueberlasser_strasse $ueberlasser_strasse
    dict set export_data ueberlasser_plz $ueberlasser_plz
    dict set export_data ueberlasser_ort $ueberlasser_ort
    dict set export_data ueberlasser_tel $ueberlasser_tel
    dict set export_data ueberlasser_email $ueberlasser_email
    dict set export_data ueberlasser_register $ueberlasser_register

    # HTML-Export aufrufen (mit Parent-Fenster für korrektes Dialog-Verhalten)
    ::waffenverleih::export::exportiere_html $fenster $export_data
}

# =============================================================================
# Prozedur: open_waffenverleih_dialog
# Öffnet den Waffenverleih-Dialog
# =============================================================================
proc open_waffenverleih_dialog {} {
    # Dialog-Fenster definieren
    set w .waffenverleih
    set ::waffenverleih::fenster $w

    # Prüfen, ob Dialog bereits offen ist
    if {[winfo exists $w]} {
        raise $w
        focus $w
        return
    }

    # Waffenliste laden
    set ::waffenverleih::waffen_liste [::waffenverleih::lade_waffen_fuer_checkboxen]

    # Vereinsdaten laden
    ::waffenverleih::lade_verein_daten_fuer_ueberlasser

    # Prüfen ob Waffen vorhanden sind
    if {[llength $::waffenverleih::waffen_liste] == 0} {
        tk_messageBox -icon warning -title "Keine Waffen" \
            -message "Es sind keine Waffen im Waffenregister vorhanden.\nBitte fügen Sie zuerst Waffen hinzu."
        return
    }

    # Prüfen ob Vereinsdaten vorhanden sind
    if {$::waffenverleih::ueberlasser_name eq ""} {
        tk_messageBox -icon warning -title "Keine Vereinsdaten" \
            -message "Es sind keine Vereinsdaten vorhanden.\nBitte tragen Sie zuerst die Vereinsdaten unter Einstellungen ein."
        return
    }

    # Alle Verleihtyp-Checkboxen zurücksetzen
    set ::waffenverleih::typ_leihe 0
    set ::waffenverleih::typ_verwahrung 0
    set ::waffenverleih::typ_transport 0
    set ::waffenverleih::typ_vereinsbeauftragter 0

    # Alle Besitzer-Felder zurücksetzen
    set ::waffenverleih::besitzer_name ""
    set ::waffenverleih::besitzer_vorname ""
    set ::waffenverleih::besitzer_geburtsdatum ""
    set ::waffenverleih::besitzer_geburtsort ""
    set ::waffenverleih::besitzer_strasse ""
    set ::waffenverleih::besitzer_hausnummer ""
    set ::waffenverleih::besitzer_plz ""
    set ::waffenverleih::besitzer_ort ""
    set ::waffenverleih::besitzer_wbk_nummer ""
    set ::waffenverleih::besitzer_wbk_behoerde ""

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Waffenverleih"
    wm geometry $w "900x800"
    wm resizable $w 1 1

    # === Scrollbares Canvas ===
    canvas $w.canvas -yscrollcommand "$w.scroll set"
    scrollbar $w.scroll -command "$w.canvas yview" -orient vertical

    pack $w.scroll -side right -fill y
    pack $w.canvas -fill both -expand 1

    # Hauptframe im Canvas
    frame $w.canvas.main -padx 20 -pady 20
    $w.canvas create window 0 0 -anchor nw -window $w.canvas.main

    # Scrollregion nach Aufbau aktualisieren
    bind $w.canvas.main <Configure> {
        .waffenverleih.canvas configure -scrollregion [.waffenverleih.canvas bbox all]
    }

    # === SEKTION 1: Waffenauswahl ===
    labelframe $w.canvas.main.waffen_frame -text "Waffen auswählen" -padx 10 -pady 10 -font {Arial 11 bold}
    pack $w.canvas.main.waffen_frame -fill x -pady 10

    # Dynamische Checkboxen für jede Waffe erstellen
    set weapon_id 0
    foreach waffe $::waffenverleih::waffen_liste {
        set art [dict get $waffe art]
        set kaliber [dict get $waffe kaliber]
        set seriennr [dict get $waffe seriennummer]

        # Checkbox-Variable im Namespace erstellen
        set varname "::waffenverleih::waffen_check_${weapon_id}"
        set $varname 0

        # Text: "Pistole - 9mm Luger (Ser: ABC123456)"
        set text "$art - $kaliber (Ser: $seriennr)"

        checkbutton $w.canvas.main.waffen_frame.cb_${weapon_id} \
            -text $text \
            -variable $varname \
            -anchor w
        pack $w.canvas.main.waffen_frame.cb_${weapon_id} -anchor w -pady 2

        incr weapon_id
    }

    # === SEKTION 2: Verleihtyp ===
    labelframe $w.canvas.main.typ_frame -text "Art des Verleihs" -padx 10 -pady 10 -font {Arial 11 bold}
    pack $w.canvas.main.typ_frame -fill x -pady 10

    checkbutton $w.canvas.main.typ_frame.leihe \
        -text "Leihe" \
        -variable ::waffenverleih::typ_leihe \
        -anchor w
    pack $w.canvas.main.typ_frame.leihe -anchor w -pady 2

    checkbutton $w.canvas.main.typ_frame.verwahrung \
        -text "Verwahrung" \
        -variable ::waffenverleih::typ_verwahrung \
        -anchor w
    pack $w.canvas.main.typ_frame.verwahrung -anchor w -pady 2

    checkbutton $w.canvas.main.typ_frame.transport \
        -text "Gewerblicher Transport" \
        -variable ::waffenverleih::typ_transport \
        -anchor w
    pack $w.canvas.main.typ_frame.transport -anchor w -pady 2

    checkbutton $w.canvas.main.typ_frame.vereinsbeauftragter \
        -text "Vereinsbeauftragter" \
        -variable ::waffenverleih::typ_vereinsbeauftragter \
        -anchor w
    pack $w.canvas.main.typ_frame.vereinsbeauftragter -anchor w -pady 2

    # === SEKTION 3: Vorübergehender Besitzer ===
    labelframe $w.canvas.main.besitzer_frame \
        -text "Angaben zum vorübergehenden Besitzer der Waffen" \
        -padx 10 -pady 10 -font {Arial 11 bold}
    pack $w.canvas.main.besitzer_frame -fill x -pady 10

    # Grid-Layout für Eingabefelder
    frame $w.canvas.main.besitzer_frame.fields
    pack $w.canvas.main.besitzer_frame.fields -fill x

    # Zeile 0: Name
    label $w.canvas.main.besitzer_frame.fields.name_label -text "Name:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.name_entry \
        -textvariable ::waffenverleih::besitzer_name -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.name_label -row 0 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.name_entry -row 0 -column 1 -sticky ew -pady 3

    # Binding: Bei Verlassen des Namensfelds Mitglied suchen
    bind $w.canvas.main.besitzer_frame.fields.name_entry <FocusOut> {
        ::waffenverleih::pruefe_und_fulle_mitglied
    }
    # Binding: Bei Enter-Taste Mitglied suchen
    bind $w.canvas.main.besitzer_frame.fields.name_entry <Return> {
        ::waffenverleih::pruefe_und_fulle_mitglied
    }

    # Zeile 1: Vorname
    label $w.canvas.main.besitzer_frame.fields.vorname_label -text "Vorname:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.vorname_entry \
        -textvariable ::waffenverleih::besitzer_vorname -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.vorname_label -row 1 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.vorname_entry -row 1 -column 1 -sticky ew -pady 3

    # Zeile 2: Geburtsdatum
    label $w.canvas.main.besitzer_frame.fields.gebdatum_label -text "Geburtsdatum:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.gebdatum_entry \
        -textvariable ::waffenverleih::besitzer_geburtsdatum -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.gebdatum_label -row 2 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.gebdatum_entry -row 2 -column 1 -sticky ew -pady 3

    # Zeile 3: Geburtsort
    label $w.canvas.main.besitzer_frame.fields.gebort_label -text "Geburtsort:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.gebort_entry \
        -textvariable ::waffenverleih::besitzer_geburtsort -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.gebort_label -row 3 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.gebort_entry -row 3 -column 1 -sticky ew -pady 3

    # Zeile 4: Straße
    label $w.canvas.main.besitzer_frame.fields.strasse_label -text "Straße:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.strasse_entry \
        -textvariable ::waffenverleih::besitzer_strasse -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.strasse_label -row 4 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.strasse_entry -row 4 -column 1 -sticky ew -pady 3

    # Zeile 5: Hausnummer
    label $w.canvas.main.besitzer_frame.fields.hausnr_label -text "Hausnummer:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.hausnr_entry \
        -textvariable ::waffenverleih::besitzer_hausnummer -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.hausnr_label -row 5 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.hausnr_entry -row 5 -column 1 -sticky ew -pady 3

    # Zeile 6: PLZ
    label $w.canvas.main.besitzer_frame.fields.plz_label -text "PLZ:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.plz_entry \
        -textvariable ::waffenverleih::besitzer_plz -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.plz_label -row 6 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.plz_entry -row 6 -column 1 -sticky ew -pady 3

    # Zeile 7: Ort
    label $w.canvas.main.besitzer_frame.fields.ort_label -text "Ort:*" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.ort_entry \
        -textvariable ::waffenverleih::besitzer_ort -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.ort_label -row 7 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.ort_entry -row 7 -column 1 -sticky ew -pady 3

    # Zeile 8: WBK-Nummer
    label $w.canvas.main.besitzer_frame.fields.wbk_label -text "WBK-Nummer:" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.wbk_entry \
        -textvariable ::waffenverleih::besitzer_wbk_nummer -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.wbk_label -row 8 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.wbk_entry -row 8 -column 1 -sticky ew -pady 3

    # Zeile 9: Ausstellende Behörde
    label $w.canvas.main.besitzer_frame.fields.behoerde_label -text "Ausstellende Behörde:" -anchor w
    entry $w.canvas.main.besitzer_frame.fields.behoerde_entry \
        -textvariable ::waffenverleih::besitzer_wbk_behoerde -font {Arial 11}
    grid $w.canvas.main.besitzer_frame.fields.behoerde_label -row 9 -column 0 -sticky w -pady 3
    grid $w.canvas.main.besitzer_frame.fields.behoerde_entry -row 9 -column 1 -sticky ew -pady 3

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure $w.canvas.main.besitzer_frame.fields 1 -weight 1

    # Hinweis
    label $w.canvas.main.besitzer_frame.hinweis -text "* Pflichtfelder\n(WBK nur bei Leihe/Verwahrung erforderlich)" -fg "#666666" -font {Arial 9 italic} -justify left
    pack $w.canvas.main.besitzer_frame.hinweis -anchor w -pady 5

    # === SEKTION 4: Überlasser (Read-only) ===
    labelframe $w.canvas.main.ueberlasser_frame \
        -text "Angaben zum Überlasser" \
        -padx 10 -pady 10 -font {Arial 11 bold}
    pack $w.canvas.main.ueberlasser_frame -fill x -pady 10

    # Grid-Layout für Anzeige
    frame $w.canvas.main.ueberlasser_frame.fields
    pack $w.canvas.main.ueberlasser_frame.fields -fill x

    # Zeile 0: Vereinsname
    label $w.canvas.main.ueberlasser_frame.fields.name_label -text "Vereinsname:" -anchor w
    label $w.canvas.main.ueberlasser_frame.fields.name_wert \
        -text $::waffenverleih::ueberlasser_name \
        -anchor w -font {Arial 10 bold}
    grid $w.canvas.main.ueberlasser_frame.fields.name_label -row 0 -column 0 -sticky w -pady 3
    grid $w.canvas.main.ueberlasser_frame.fields.name_wert -row 0 -column 1 -sticky w -pady 3

    # Zeile 1: Straße
    label $w.canvas.main.ueberlasser_frame.fields.strasse_label -text "Straße:" -anchor w
    label $w.canvas.main.ueberlasser_frame.fields.strasse_wert \
        -text $::waffenverleih::ueberlasser_strasse \
        -anchor w -font {Arial 10 bold}
    grid $w.canvas.main.ueberlasser_frame.fields.strasse_label -row 1 -column 0 -sticky w -pady 3
    grid $w.canvas.main.ueberlasser_frame.fields.strasse_wert -row 1 -column 1 -sticky w -pady 3

    # Zeile 2: PLZ/Ort
    label $w.canvas.main.ueberlasser_frame.fields.ort_label -text "PLZ/Ort:" -anchor w
    label $w.canvas.main.ueberlasser_frame.fields.ort_wert \
        -text "$::waffenverleih::ueberlasser_plz $::waffenverleih::ueberlasser_ort" \
        -anchor w -font {Arial 10 bold}
    grid $w.canvas.main.ueberlasser_frame.fields.ort_label -row 2 -column 0 -sticky w -pady 3
    grid $w.canvas.main.ueberlasser_frame.fields.ort_wert -row 2 -column 1 -sticky w -pady 3

    # Zeile 3: Telefon
    label $w.canvas.main.ueberlasser_frame.fields.tel_label -text "Telefon:" -anchor w
    label $w.canvas.main.ueberlasser_frame.fields.tel_wert \
        -text $::waffenverleih::ueberlasser_tel \
        -anchor w -font {Arial 10 bold}
    grid $w.canvas.main.ueberlasser_frame.fields.tel_label -row 3 -column 0 -sticky w -pady 3
    grid $w.canvas.main.ueberlasser_frame.fields.tel_wert -row 3 -column 1 -sticky w -pady 3

    # Zeile 4: E-Mail
    label $w.canvas.main.ueberlasser_frame.fields.email_label -text "E-Mail:" -anchor w
    label $w.canvas.main.ueberlasser_frame.fields.email_wert \
        -text $::waffenverleih::ueberlasser_email \
        -anchor w -font {Arial 10 bold}
    grid $w.canvas.main.ueberlasser_frame.fields.email_label -row 4 -column 0 -sticky w -pady 3
    grid $w.canvas.main.ueberlasser_frame.fields.email_wert -row 4 -column 1 -sticky w -pady 3

    # Zeile 5: Registereintrag
    label $w.canvas.main.ueberlasser_frame.fields.register_label -text "Registereintrag:" -anchor w
    label $w.canvas.main.ueberlasser_frame.fields.register_wert \
        -text $::waffenverleih::ueberlasser_register \
        -anchor w -font {Arial 10 bold}
    grid $w.canvas.main.ueberlasser_frame.fields.register_label -row 5 -column 0 -sticky w -pady 3
    grid $w.canvas.main.ueberlasser_frame.fields.register_wert -row 5 -column 1 -sticky w -pady 3

    # Spalte 1 soll sich ausdehnen
    grid columnconfigure $w.canvas.main.ueberlasser_frame.fields 1 -weight 1

    # === Button-Frame (fixiert am unteren Rand, außerhalb Canvas) ===
    frame $w.button_frame -pady 10
    pack $w.button_frame -side bottom -fill x -padx 20 -before $w.scroll

    # Formular exportieren-Button (grün, links)
    button $w.button_frame.exportieren -text "Formular exportieren" -bg "#90EE90" -width 20 \
        -command ::waffenverleih::validiere_und_exportiere
    pack $w.button_frame.exportieren -side left -padx 5

    # Abbrechen-Button (rot, rechts)
    button $w.button_frame.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 15 \
        -command "destroy $w"
    pack $w.button_frame.abbrechen -side right -padx 5

    # Fokus auf das Fenster setzen
    focus $w
}
