# =============================================================================
# statistik_dialog.tcl - Statistik-Funktion für den Schießbetrieb
# =============================================================================
# Dieses Modul bietet statistische Auswertungen über den Schießbetrieb:
# - Gesamtzahl der Schützen
# - Anzahl der Vereinsmitglieder
# - Häufigste Teilnehmer nach Waffentyp (LD/KK/GK)
# - Kreisdiagramm der Verteilung
# - HTML-Export
# =============================================================================

# Namespace für Statistik-Funktionalität
namespace eval ::statistik {
    # Dialog-Variablen
    variable fenster ""
    variable ergebnis_fenster ""

    # Zeitraum-Auswahl (vorausgefüllt mit 01.01.aktuelles Jahr bis heute)
    variable von_datum ""
    variable bis_datum ""

    # Statistik-Ergebnisse
    variable gesamt_schuetzen 0
    variable vereinsmitglieder 0
    variable haeufigster_ld [dict create name "Keine" anzahl 0]
    variable haeufigster_kk [dict create name "Keine" anzahl 0]
    variable haeufigster_gk [dict create name "Keine" anzahl 0]
    variable haeufigster_gesamt [dict create name "Keine" anzahl 0]

    # Prozentuale Verteilung für Kreisdiagramm
    variable anteil_ld 0.0
    variable anteil_kk 0.0
    variable anteil_gk 0.0

    # Absolute Zahlen für Verteilung
    variable anzahl_ld 0
    variable anzahl_kk 0
    variable anzahl_gk 0

    # Rohdaten für Berechnung
    variable eintraege_liste [list]
    variable mitglieder_liste [list]
}

# =============================================================================
# Prozedur: open_zeitraum_dialog
# Öffnet den Dialog zur Auswahl des Zeitraums für die Statistik
# =============================================================================
proc ::statistik::open_zeitraum_dialog {} {
    variable fenster
    variable von_datum
    variable bis_datum

    # Fenster-Widget-Name
    set w .statistik_zeitraum
    set fenster $w

    # Prüfen ob Dialog bereits geöffnet ist
    if {[winfo exists $w]} {
        # Falls ja, in den Vordergrund bringen
        raise $w
        focus $w
        return
    }

    # Standardwerte für Datumsfelder setzen
    # Von: 01.01. des aktuellen Jahres
    set aktuelles_jahr [clock format [clock seconds] -format "%Y"]
    set von_datum "01.01.$aktuelles_jahr"
    # Bis: Heutiges Datum
    set bis_datum [clock format [clock seconds] -format "%d.%m.%Y"]

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Statistik - Zeitraum w\u00e4hlen"
    wm geometry $w "450x250"
    wm resizable $w 0 0

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 15
    pack $w.main -fill both -expand 1

    # Labelframe für Zeitraum-Eingabe
    labelframe $w.main.zeitraum -text "Zeitraum" -padx 15 -pady 10
    pack $w.main.zeitraum -fill x -pady 10

    # Frame für "Von"-Datum
    frame $w.main.zeitraum.von_frame
    pack $w.main.zeitraum.von_frame -fill x -pady 5

    # Label "Von:"
    label $w.main.zeitraum.von_frame.label -text "Von:" -width 8 -anchor w
    pack $w.main.zeitraum.von_frame.label -side left

    # Entry für "Von"-Datum
    entry $w.main.zeitraum.von_frame.entry -textvariable ::statistik::von_datum -width 20
    pack $w.main.zeitraum.von_frame.entry -side left -padx 5

    # Hinweis-Label für Datumsformat
    label $w.main.zeitraum.von_frame.hint -text "(TT.MM.JJJJ)" -fg gray
    pack $w.main.zeitraum.von_frame.hint -side left

    # Frame für "Bis"-Datum
    frame $w.main.zeitraum.bis_frame
    pack $w.main.zeitraum.bis_frame -fill x -pady 5

    # Label "Bis:"
    label $w.main.zeitraum.bis_frame.label -text "Bis:" -width 8 -anchor w
    pack $w.main.zeitraum.bis_frame.label -side left

    # Entry für "Bis"-Datum
    entry $w.main.zeitraum.bis_frame.entry -textvariable ::statistik::bis_datum -width 20
    pack $w.main.zeitraum.bis_frame.entry -side left -padx 5

    # Hinweis-Label für Datumsformat
    label $w.main.zeitraum.bis_frame.hint -text "(TT.MM.JJJJ)" -fg gray
    pack $w.main.zeitraum.bis_frame.hint -side left

    # Button-Frame
    frame $w.main.buttons
    pack $w.main.buttons -fill x -pady 15

    # Button "Berechnen" (grün) - mit Padding für angemessene Button-Höhe
    button $w.main.buttons.berechnen -text "Berechnen" -bg "#90EE90" -width 15 \
        -command {::statistik::berechne_statistik}
    pack $w.main.buttons.berechnen -side left -padx 10 -ipady 8

    # Button "Abbrechen" (rosa) - mit Padding für angemessene Button-Höhe
    button $w.main.buttons.abbrechen -text "Abbrechen" -bg "#FFB6C1" -width 15 \
        -command {::statistik::schliesse_zeitraum_dialog}
    pack $w.main.buttons.abbrechen -side right -padx 10 -ipady 8

    # Traces für Datumseingaben hinzufügen (zur Validierung)
    trace add variable ::statistik::von_datum write ::statistik::pruefe_datum_button
    trace add variable ::statistik::bis_datum write ::statistik::pruefe_datum_button

    # Enter-Taste zum Berechnen binden
    bind $w <Return> {::statistik::berechne_statistik}
    # Escape-Taste zum Schließen binden
    bind $w <Escape> {::statistik::schliesse_zeitraum_dialog}

    # Fokus auf das Fenster setzen
    focus $w
}

# =============================================================================
# Prozedur: pruefe_datum_button
# Validiert die Datumseingaben und aktiviert/deaktiviert den Berechnen-Button
# =============================================================================
proc ::statistik::pruefe_datum_button {args} {
    variable fenster
    variable von_datum
    variable bis_datum

    # Prüfen ob Fenster existiert
    if {$fenster eq "" || ![winfo exists $fenster]} {
        return
    }

    # Prüfen ob Button existiert
    if {![winfo exists $fenster.main.buttons.berechnen]} {
        return
    }

    # Beide Datumsfelder müssen ausgefüllt sein
    if {[string trim $von_datum] ne "" && [string trim $bis_datum] ne ""} {
        # Button aktivieren
        $fenster.main.buttons.berechnen configure -state normal
    } else {
        # Button deaktivieren
        $fenster.main.buttons.berechnen configure -state disabled
    }
}

# =============================================================================
# Prozedur: schliesse_zeitraum_dialog
# Schließt den Zeitraum-Dialog und entfernt alle Traces
# =============================================================================
proc ::statistik::schliesse_zeitraum_dialog {} {
    variable fenster

    # Traces entfernen (wichtig um Memory Leaks zu vermeiden)
    catch {trace remove variable ::statistik::von_datum write ::statistik::pruefe_datum_button}
    catch {trace remove variable ::statistik::bis_datum write ::statistik::pruefe_datum_button}

    # Fenster zerstören
    if {[winfo exists $fenster]} {
        destroy $fenster
    }

    # Variable zurücksetzen
    set fenster ""
}

# =============================================================================
# Prozedur: validiere_datum
# Prüft ob ein Datum im Format TT.MM.JJJJ gültig ist
# Parameter: datum_str - Datum als String
# Rückgabe: 1 wenn gültig, 0 wenn ungültig
# =============================================================================
proc ::statistik::validiere_datum {datum_str} {
    # Leerzeichen am Anfang und Ende entfernen
    set datum_str [string trim $datum_str]

    # Prüfen ob Format TT.MM.JJJJ (mit optionaler führender Null)
    if {![regexp {^(\d{1,2})\.(\d{1,2})\.(\d{4})$} $datum_str -> tag monat jahr]} {
        return 0
    }

    # Datum mit clock scan validieren - prüft Format UND kalendarische Gültigkeit
    # Vermeidet Probleme mit Oktal-Interpretation von führenden Nullen (z.B. "08")
    if {[catch {clock scan "$tag.$monat.$jahr" -format "%d.%m.%Y"}]} {
        return 0
    }

    return 1
}

# =============================================================================
# Prozedur: datum_zu_vergleichswert
# Konvertiert ein Datum von TT.MM.JJJJ zu JJJJMMTT für Vergleiche
# Parameter: datum_str - Datum im Format TT.MM.JJJJ
# Rückgabe: Datum im Format JJJJMMTT
# =============================================================================
proc ::statistik::datum_zu_vergleichswert {datum_str} {
    # Regex um Tag, Monat, Jahr zu extrahieren
    if {[regexp {^(\d{1,2})\.(\d{1,2})\.(\d{4})$} $datum_str -> tag monat jahr]} {
        # Führende Nullen hinzufügen
        set tag [format "%02d" [scan $tag %d]]
        set monat [format "%02d" [scan $monat %d]]
        # Format JJJJMMTT für String-Vergleich
        return "${jahr}${monat}${tag}"
    }
    # Fallback: Aktuelles Datum
    return [clock format [clock seconds] -format "%Y%m%d"]
}

# =============================================================================
# Prozedur: datum_im_zeitraum
# Prüft ob ein Datum innerhalb des angegebenen Zeitraums liegt
# Parameter: datum - Zu prüfendes Datum (TT.MM.JJJJ)
#            von - Startdatum (TT.MM.JJJJ)
#            bis - Enddatum (TT.MM.JJJJ)
# Rückgabe: 1 wenn im Zeitraum, 0 wenn nicht
# =============================================================================
proc ::statistik::datum_im_zeitraum {datum von bis} {
    # Alle Daten zu Vergleichswerten konvertieren
    set datum_vgl [datum_zu_vergleichswert $datum]
    set von_vgl [datum_zu_vergleichswert $von]
    set bis_vgl [datum_zu_vergleichswert $bis]

    # String-Vergleich funktioniert wegen JJJJMMTT Format
    if {$datum_vgl >= $von_vgl && $datum_vgl <= $bis_vgl} {
        return 1
    }
    return 0
}

# =============================================================================
# Prozedur: lade_eintraege_im_zeitraum
# Lädt alle Schießbetrieb-Einträge die im gewählten Zeitraum liegen
# Rückgabe: Liste von Eintrags-Dictionaries
# =============================================================================
proc ::statistik::lade_eintraege_im_zeitraum {} {
    variable von_datum
    variable bis_datum

    # Daten-Verzeichnis ermitteln
    set daten_dir [::pfad::get_daten_directory]

    # Liste für alle Einträge
    set alle_eintraege [list]

    # Alle JSON-Dateien im Daten-Verzeichnis durchsuchen
    foreach datei [glob -nocomplain -directory $daten_dir *.json] {
        # mitglieder.json überspringen (enthält keine Schießbetrieb-Einträge)
        if {[file tail $datei] eq "mitglieder.json"} {
            continue
        }

        # Einträge aus dieser Datei laden
        set eintraege [::neuer_eintrag::lade_eintraege_aus_datei $datei]

        # Zur Gesamtliste hinzufügen
        set alle_eintraege [concat $alle_eintraege $eintraege]
    }

    # Nach Zeitraum filtern
    set gefilterte_eintraege [list]

    foreach eintrag $alle_eintraege {
        # Datum des Eintrags holen
        set datum [dict get $eintrag datum]

        # Prüfen ob im Zeitraum
        if {[datum_im_zeitraum $datum $von_datum $bis_datum]} {
            lappend gefilterte_eintraege $eintrag
        }
    }

    return $gefilterte_eintraege
}

# =============================================================================
# Prozedur: lade_mitglieder
# Lädt die Liste aller Vereinsmitglieder aus mitglieder.json
# Rückgabe: Liste von Mitglieder-Dictionaries
# =============================================================================
proc ::statistik::lade_mitglieder {} {
    # Pfad zur Mitglieder-JSON-Datei
    set mitglieder_datei [::pfad::get_json_path "daten" "mitglieder.json"]

    # Prüfen ob Datei existiert
    if {![file exists $mitglieder_datei]} {
        return [list]
    }

    # JSON-Datei lesen
    if {[catch {
        set fh [open $mitglieder_datei r]
        fconfigure $fh -encoding utf-8
        set json_inhalt [read $fh]
        close $fh
    } err]} {
        puts stderr "Fehler beim Lesen der Mitglieder-Datei: $err"
        return [list]
    }

    # JSON parsen (einfacher Parser für unser Format)
    set mitglieder [list]

    # Nach "mitglieder" Array suchen
    if {[regexp {"mitglieder"\s*:\s*\[(.*?)\]} $json_inhalt -> mitglieder_json]} {
        # Einzelne Mitglieder-Objekte extrahieren
        set objekt_pattern {\{[^{}]+\}}
        set matches [regexp -all -inline $objekt_pattern $mitglieder_json]

        foreach match $matches {
            # Einzelnes Mitglied parsen
            set mitglied [dict create]

            # Nachname extrahieren
            if {[regexp {"nachname"\s*:\s*"([^"]*)"} $match -> nachname]} {
                dict set mitglied nachname $nachname
            }
            # Vorname extrahieren
            if {[regexp {"vorname"\s*:\s*"([^"]*)"} $match -> vorname]} {
                dict set mitglied vorname $vorname
            }

            # Nur hinzufügen wenn beide Felder vorhanden
            if {[dict exists $mitglied nachname] && [dict exists $mitglied vorname]} {
                lappend mitglieder $mitglied
            }
        }
    }

    return $mitglieder
}

# =============================================================================
# Prozedur: zaehle_unique_schuetzen
# Zählt die Anzahl eindeutiger Schützen in der Eintrags-Liste
# Rückgabe: Integer - Anzahl eindeutiger Personen
# =============================================================================
proc ::statistik::zaehle_unique_schuetzen {} {
    variable eintraege_liste

    # Dictionary für eindeutige Personen (Nachname|Vorname als Key)
    set personen [dict create]

    foreach eintrag $eintraege_liste {
        # Nachname und Vorname holen
        set nachname [dict get $eintrag nachname]
        set vorname [dict get $eintrag vorname]
        # Kombination als eindeutiger Schlüssel
        set key "$nachname|$vorname"
        # Im Dictionary speichern (Duplikate werden automatisch überschrieben)
        dict set personen $key 1
    }

    # Anzahl der eindeutigen Schlüssel zurückgeben
    return [dict size $personen]
}

# =============================================================================
# Prozedur: zaehle_vereinsmitglieder
# Zählt wie viele der Schützen auch Vereinsmitglieder sind
# Rückgabe: Integer - Anzahl der Schützen die Mitglieder sind
# =============================================================================
proc ::statistik::zaehle_vereinsmitglieder {} {
    variable eintraege_liste
    variable mitglieder_liste

    # Set der Mitglieder erstellen (Nachname|Vorname als Key)
    set mitglieder_set [dict create]
    foreach mitglied $mitglieder_liste {
        set key "[dict get $mitglied nachname]|[dict get $mitglied vorname]"
        dict set mitglieder_set $key 1
    }

    # Eindeutige Schützen die auch Mitglieder sind
    set mitglied_schuetzen [dict create]

    foreach eintrag $eintraege_liste {
        set key "[dict get $eintrag nachname]|[dict get $eintrag vorname]"
        # Prüfen ob diese Person Mitglied ist
        if {[dict exists $mitglieder_set $key]} {
            dict set mitglied_schuetzen $key 1
        }
    }

    # Anzahl zurückgeben
    return [dict size $mitglied_schuetzen]
}

# =============================================================================
# Prozedur: finde_haeufigsten_teilnehmer
# Ermittelt den Teilnehmer mit den meisten Einträgen für einen Waffentyp
# Parameter: typ - "LD", "KK", "GK" oder "gesamt"
# Rückgabe: Dictionary mit "name" und "anzahl"
# =============================================================================
proc ::statistik::finde_haeufigsten_teilnehmer {typ} {
    variable eintraege_liste
    variable mitglieder_liste

    # Set der Mitglieder erstellen
    set mitglieder_set [dict create]
    foreach mitglied $mitglieder_liste {
        set key "[dict get $mitglied nachname]|[dict get $mitglied vorname]"
        dict set mitglieder_set $key 1
    }

    # Zähler pro Person
    set zaehler [dict create]

    foreach eintrag $eintraege_liste {
        # Waffentyp des Eintrags
        set waffentyp [dict get $eintrag waffentyp]

        # Prüfen ob dieser Eintrag zählt (passender Typ oder "gesamt")
        if {$typ eq "gesamt" || $waffentyp eq $typ} {
            set nachname [dict get $eintrag nachname]
            set vorname [dict get $eintrag vorname]
            set key "$nachname|$vorname"

            # Nur Mitglieder zählen (außer bei "gesamt")
            if {$typ eq "gesamt" || [dict exists $mitglieder_set $key]} {
                # Zähler erhöhen
                if {[dict exists $zaehler $key]} {
                    dict incr zaehler $key
                } else {
                    dict set zaehler $key 1
                }
            }
        }
    }

    # Maximum finden
    set max_key ""
    set max_count 0

    dict for {key count} $zaehler {
        if {$count > $max_count} {
            set max_count $count
            set max_key $key
        }
    }

    # Ergebnis formatieren
    if {$max_key ne ""} {
        lassign [split $max_key "|"] nachname vorname
        return [dict create name "$nachname, $vorname" anzahl $max_count]
    }

    # Fallback wenn keine Einträge gefunden
    return [dict create name "Keine" anzahl 0]
}

# =============================================================================
# Prozedur: berechne_prozentuale_verteilung
# Berechnet die prozentuale Verteilung der Waffentypen
# Setzt die Variablen anteil_ld, anteil_kk, anteil_gk
# =============================================================================
proc ::statistik::berechne_prozentuale_verteilung {} {
    variable eintraege_liste
    variable anteil_ld
    variable anteil_kk
    variable anteil_gk
    variable anzahl_ld
    variable anzahl_kk
    variable anzahl_gk

    # Zähler initialisieren
    set anzahl_ld 0
    set anzahl_kk 0
    set anzahl_gk 0

    # Einträge nach Waffentyp zählen
    foreach eintrag $eintraege_liste {
        set waffentyp [dict get $eintrag waffentyp]
        switch $waffentyp {
            "LD" { incr anzahl_ld }
            "KK" { incr anzahl_kk }
            "GK" { incr anzahl_gk }
        }
    }

    # Gesamtzahl berechnen
    set gesamt [expr {$anzahl_ld + $anzahl_kk + $anzahl_gk}]

    # Prozentuale Anteile berechnen
    if {$gesamt > 0} {
        set anteil_ld [expr {double($anzahl_ld) / $gesamt * 100}]
        set anteil_kk [expr {double($anzahl_kk) / $gesamt * 100}]
        set anteil_gk [expr {double($anzahl_gk) / $gesamt * 100}]
    } else {
        # Fallback wenn keine Einträge
        set anteil_ld 0.0
        set anteil_kk 0.0
        set anteil_gk 0.0
    }
}

# =============================================================================
# Prozedur: berechne_statistik
# Hauptprozedur: Lädt Daten, führt alle Berechnungen durch und zeigt Ergebnis
# =============================================================================
proc ::statistik::berechne_statistik {} {
    variable fenster
    variable von_datum
    variable bis_datum
    variable eintraege_liste
    variable mitglieder_liste
    variable gesamt_schuetzen
    variable vereinsmitglieder
    variable haeufigster_ld
    variable haeufigster_kk
    variable haeufigster_gk
    variable haeufigster_gesamt

    # Datumsvalidierung
    if {![validiere_datum $von_datum]} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" \
            -message "Das Von-Datum ist ung\u00fcltig.\nBitte im Format TT.MM.JJJJ eingeben."
        return
    }

    if {![validiere_datum $bis_datum]} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" \
            -message "Das Bis-Datum ist ung\u00fcltig.\nBitte im Format TT.MM.JJJJ eingeben."
        return
    }

    # Prüfen ob Von-Datum vor Bis-Datum liegt
    set von_vgl [datum_zu_vergleichswert $von_datum]
    set bis_vgl [datum_zu_vergleichswert $bis_datum]

    if {$von_vgl > $bis_vgl} {
        tk_messageBox -parent $fenster -icon error -title "Fehler" \
            -message "Das Von-Datum muss vor dem Bis-Datum liegen."
        return
    }

    # Einträge im Zeitraum laden
    set eintraege_liste [lade_eintraege_im_zeitraum]

    # Mitgliederliste laden
    set mitglieder_liste [lade_mitglieder]

    # Prüfen ob Einträge vorhanden sind
    if {[llength $eintraege_liste] == 0} {
        tk_messageBox -parent $fenster -icon warning -title "Keine Daten" \
            -message "Im gew\u00e4hlten Zeitraum wurden keine Eintr\u00e4ge gefunden."
        return
    }

    # Statistiken berechnen
    set gesamt_schuetzen [zaehle_unique_schuetzen]
    set vereinsmitglieder [zaehle_vereinsmitglieder]

    # Häufigste Teilnehmer ermitteln
    set haeufigster_ld [finde_haeufigsten_teilnehmer "LD"]
    set haeufigster_kk [finde_haeufigsten_teilnehmer "KK"]
    set haeufigster_gk [finde_haeufigsten_teilnehmer "GK"]
    set haeufigster_gesamt [finde_haeufigsten_teilnehmer "gesamt"]

    # Prozentuale Verteilung berechnen
    berechne_prozentuale_verteilung

    # Zeitraum-Dialog schließen
    schliesse_zeitraum_dialog

    # Ergebnis-Dialog anzeigen
    zeige_ergebnis_dialog
}

# =============================================================================
# Prozedur: zeige_ergebnis_dialog
# Zeigt das Ergebnis-Fenster mit allen berechneten Statistiken
# =============================================================================
proc ::statistik::zeige_ergebnis_dialog {} {
    variable ergebnis_fenster
    variable von_datum
    variable bis_datum
    variable gesamt_schuetzen
    variable vereinsmitglieder
    variable haeufigster_ld
    variable haeufigster_kk
    variable haeufigster_gk
    variable haeufigster_gesamt
    variable anteil_ld
    variable anteil_kk
    variable anteil_gk
    variable anzahl_ld
    variable anzahl_kk
    variable anzahl_gk

    # Fenster-Widget-Name
    set w .statistik_ergebnis
    set ergebnis_fenster $w

    # Prüfen ob Dialog bereits geöffnet ist
    if {[winfo exists $w]} {
        destroy $w
    }

    # Toplevel-Fenster erstellen
    toplevel $w
    wm title $w "Statistik vom $von_datum bis $bis_datum"
    wm geometry $w "750x620"
    wm resizable $w 0 0

    # Hauptframe mit Padding
    frame $w.main -padx 20 -pady 15
    pack $w.main -fill both -expand 1

    # Titel
    label $w.main.titel -text "Statistik vom $von_datum bis $bis_datum" \
        -font {Helvetica 14 bold} -fg "#333333"
    pack $w.main.titel -pady 10

    # Horizontaler Container für linke und rechte Seite
    frame $w.main.content
    pack $w.main.content -fill both -expand 1 -pady 10

    # Linke Seite (Statistik-Daten)
    frame $w.main.content.links
    pack $w.main.content.links -side left -fill both -expand 1 -padx 10

    # Übersicht-Labelframe
    labelframe $w.main.content.links.uebersicht -text "\u00dcbersicht" -padx 15 -pady 10
    pack $w.main.content.links.uebersicht -fill x -pady 5

    # Gesamtzahl Schützen
    frame $w.main.content.links.uebersicht.gesamt
    pack $w.main.content.links.uebersicht.gesamt -fill x -pady 3
    label $w.main.content.links.uebersicht.gesamt.label -text "Sch\u00fctzen gesamt:" -anchor w -width 25
    pack $w.main.content.links.uebersicht.gesamt.label -side left
    label $w.main.content.links.uebersicht.gesamt.wert -text "$gesamt_schuetzen" -font {Helvetica 10 bold}
    pack $w.main.content.links.uebersicht.gesamt.wert -side left

    # Davon Mitglieder
    frame $w.main.content.links.uebersicht.mitglieder
    pack $w.main.content.links.uebersicht.mitglieder -fill x -pady 3
    label $w.main.content.links.uebersicht.mitglieder.label -text "davon Vereinsmitglieder:" -anchor w -width 25
    pack $w.main.content.links.uebersicht.mitglieder.label -side left
    label $w.main.content.links.uebersicht.mitglieder.wert -text "$vereinsmitglieder" -font {Helvetica 10 bold}
    pack $w.main.content.links.uebersicht.mitglieder.wert -side left

    # Anzahl Einträge (Gesamtschüsse)
    set gesamt_eintraege [llength $::statistik::eintraege_liste]
    frame $w.main.content.links.uebersicht.eintraege
    pack $w.main.content.links.uebersicht.eintraege -fill x -pady 3
    label $w.main.content.links.uebersicht.eintraege.label -text "Anzahl Eintr\u00e4ge:" -anchor w -width 25
    pack $w.main.content.links.uebersicht.eintraege.label -side left
    label $w.main.content.links.uebersicht.eintraege.wert -text "$gesamt_eintraege" -font {Helvetica 10 bold}
    pack $w.main.content.links.uebersicht.eintraege.wert -side left

    # Häufigste Teilnehmer-Labelframe
    labelframe $w.main.content.links.haeufig -text "H\u00e4ufigste Teilnehmer (Mitglieder)" -padx 15 -pady 10
    pack $w.main.content.links.haeufig -fill x -pady 10

    # LD (Luftdruck)
    frame $w.main.content.links.haeufig.ld
    pack $w.main.content.links.haeufig.ld -fill x -pady 3
    label $w.main.content.links.haeufig.ld.label -text "Luftdruck (LD):" -anchor w -width 18 -fg "#4ACEFA"
    pack $w.main.content.links.haeufig.ld.label -side left
    set ld_name [dict get $haeufigster_ld name]
    set ld_anzahl [dict get $haeufigster_ld anzahl]
    label $w.main.content.links.haeufig.ld.wert -text "$ld_name (${ld_anzahl}x)" -font {Helvetica 10 bold}
    pack $w.main.content.links.haeufig.ld.wert -side left

    # KK (Kleinkaliber)
    frame $w.main.content.links.haeufig.kk
    pack $w.main.content.links.haeufig.kk -fill x -pady 3
    label $w.main.content.links.haeufig.kk.label -text "Kleinkaliber (KK):" -anchor w -width 18 -fg "#DAA520"
    pack $w.main.content.links.haeufig.kk.label -side left
    set kk_name [dict get $haeufigster_kk name]
    set kk_anzahl [dict get $haeufigster_kk anzahl]
    label $w.main.content.links.haeufig.kk.wert -text "$kk_name (${kk_anzahl}x)" -font {Helvetica 10 bold}
    pack $w.main.content.links.haeufig.kk.wert -side left

    # GK (Großkaliber)
    frame $w.main.content.links.haeufig.gk
    pack $w.main.content.links.haeufig.gk -fill x -pady 3
    label $w.main.content.links.haeufig.gk.label -text "Gro\u00dfkaliber (GK):" -anchor w -width 18 -fg "#FF6B6B"
    pack $w.main.content.links.haeufig.gk.label -side left
    set gk_name [dict get $haeufigster_gk name]
    set gk_anzahl [dict get $haeufigster_gk anzahl]
    label $w.main.content.links.haeufig.gk.wert -text "$gk_name (${gk_anzahl}x)" -font {Helvetica 10 bold}
    pack $w.main.content.links.haeufig.gk.wert -side left

    # Gesamt (alle Waffentypen)
    frame $w.main.content.links.haeufig.gesamt
    pack $w.main.content.links.haeufig.gesamt -fill x -pady 3
    label $w.main.content.links.haeufig.gesamt.label -text "Gesamt:" -anchor w -width 18
    pack $w.main.content.links.haeufig.gesamt.label -side left
    set gesamt_name [dict get $haeufigster_gesamt name]
    set gesamt_anzahl [dict get $haeufigster_gesamt anzahl]
    label $w.main.content.links.haeufig.gesamt.wert -text "$gesamt_name (${gesamt_anzahl}x)" -font {Helvetica 10 bold}
    pack $w.main.content.links.haeufig.gesamt.wert -side left

    # Rechte Seite (Kreisdiagramm)
    frame $w.main.content.rechts
    pack $w.main.content.rechts -side right -fill both -padx 10

    # Kreisdiagramm-Labelframe
    labelframe $w.main.content.rechts.diagramm -text "Verteilung nach Waffentyp" -padx 15 -pady 10
    pack $w.main.content.rechts.diagramm -fill both -expand 1

    # Canvas für Kreisdiagramm
    canvas $w.main.content.rechts.diagramm.canvas -width 250 -height 250 -bg white -highlightthickness 0
    pack $w.main.content.rechts.diagramm.canvas -pady 5

    # Kreisdiagramm zeichnen
    zeichne_kreisdiagramm $w.main.content.rechts.diagramm.canvas

    # Legende
    frame $w.main.content.rechts.diagramm.legende
    pack $w.main.content.rechts.diagramm.legende -pady 10

    # LD Legende
    frame $w.main.content.rechts.diagramm.legende.ld
    pack $w.main.content.rechts.diagramm.legende.ld -fill x -pady 2
    label $w.main.content.rechts.diagramm.legende.ld.farbe -bg "#4ACEFA" -width 3 -relief solid -bd 1
    pack $w.main.content.rechts.diagramm.legende.ld.farbe -side left -padx 5
    label $w.main.content.rechts.diagramm.legende.ld.text -text [format "LD - Luftdruck (%.1f%% / %d)" $anteil_ld $anzahl_ld]
    pack $w.main.content.rechts.diagramm.legende.ld.text -side left

    # KK Legende
    frame $w.main.content.rechts.diagramm.legende.kk
    pack $w.main.content.rechts.diagramm.legende.kk -fill x -pady 2
    label $w.main.content.rechts.diagramm.legende.kk.farbe -bg "#FFD700" -width 3 -relief solid -bd 1
    pack $w.main.content.rechts.diagramm.legende.kk.farbe -side left -padx 5
    label $w.main.content.rechts.diagramm.legende.kk.text -text [format "KK - Kleinkaliber (%.1f%% / %d)" $anteil_kk $anzahl_kk]
    pack $w.main.content.rechts.diagramm.legende.kk.text -side left

    # GK Legende
    frame $w.main.content.rechts.diagramm.legende.gk
    pack $w.main.content.rechts.diagramm.legende.gk -fill x -pady 2
    label $w.main.content.rechts.diagramm.legende.gk.farbe -bg "#FF6B6B" -width 3 -relief solid -bd 1
    pack $w.main.content.rechts.diagramm.legende.gk.farbe -side left -padx 5
    label $w.main.content.rechts.diagramm.legende.gk.text -text [format "GK - Gro\u00dfkaliber (%.1f%% / %d)" $anteil_gk $anzahl_gk]
    pack $w.main.content.rechts.diagramm.legende.gk.text -side left

    # Button-Frame
    frame $w.main.buttons
    pack $w.main.buttons -fill x -pady 15

    # Button "HTML Export" (hellblau) - mit Padding für angemessene Button-Höhe
    button $w.main.buttons.export -text "HTML Export" -bg "#ADD8E6" -width 15 \
        -command {::statistik::exportiere_html}
    pack $w.main.buttons.export -side left -padx 10 -ipady 8

    # Button "Schließen" (rosa) - mit Padding für angemessene Button-Höhe
    button $w.main.buttons.schliessen -text "Schlie\u00dfen" -bg "#FFB6C1" -width 15 \
        -command {::statistik::schliesse_ergebnis_dialog}
    pack $w.main.buttons.schliessen -side right -padx 10 -ipady 8

    # Escape-Taste zum Schließen binden
    bind $w <Escape> {::statistik::schliesse_ergebnis_dialog}

    # Fokus auf das Fenster setzen
    focus $w
}

# =============================================================================
# Prozedur: zeichne_kreisdiagramm
# Zeichnet ein Kreisdiagramm auf dem angegebenen Canvas
# Parameter: canvas - Das Canvas-Widget
# =============================================================================
proc ::statistik::zeichne_kreisdiagramm {canvas} {
    variable anteil_ld
    variable anteil_kk
    variable anteil_gk

    # Canvas-Dimensionen
    set width 250
    set height 250
    set center_x [expr {$width / 2}]
    set center_y [expr {$height / 2}]
    set radius 100

    # Bounding Box für Arc-Items
    set x1 [expr {$center_x - $radius}]
    set y1 [expr {$center_y - $radius}]
    set x2 [expr {$center_x + $radius}]
    set y2 [expr {$center_y + $radius}]

    # Canvas leeren (falls bereits gezeichnet)
    $canvas delete all

    # Farben definieren
    set farbe_ld "#4ACEFA"  ;# Türkis für Luftdruck
    set farbe_kk "#FFD700"  ;# Gold für Kleinkaliber
    set farbe_gk "#FF6B6B"  ;# Rot für Großkaliber

    # Startwinkel (Tk Canvas: 0 Grad = 3 Uhr, positive Winkel = gegen Uhrzeigersinn)
    # Wir beginnen bei 90 Grad (12 Uhr) und gehen gegen Uhrzeigersinn
    set start_angle 90

    # Prüfen ob überhaupt Daten vorhanden sind
    set gesamt [expr {$anteil_ld + $anteil_kk + $anteil_gk}]

    if {$gesamt < 0.1} {
        # Keine Daten: Grauen Kreis zeichnen
        $canvas create oval $x1 $y1 $x2 $y2 -fill "#CCCCCC" -outline "#333333" -width 2
        $canvas create text $center_x $center_y -text "Keine Daten" -font {Helvetica 10}
        return
    }

    # LD-Segment zeichnen (Türkis)
    if {$anteil_ld > 0} {
        set extent_ld [expr {$anteil_ld * 3.6}]  ;# 3.6 Grad pro Prozent
        $canvas create arc $x1 $y1 $x2 $y2 \
            -start $start_angle -extent [expr {-$extent_ld}] \
            -fill $farbe_ld -outline "#333333" -width 2 -style pieslice
        set start_angle [expr {$start_angle - $extent_ld}]
    }

    # KK-Segment zeichnen (Gold)
    if {$anteil_kk > 0} {
        set extent_kk [expr {$anteil_kk * 3.6}]
        $canvas create arc $x1 $y1 $x2 $y2 \
            -start $start_angle -extent [expr {-$extent_kk}] \
            -fill $farbe_kk -outline "#333333" -width 2 -style pieslice
        set start_angle [expr {$start_angle - $extent_kk}]
    }

    # GK-Segment zeichnen (Rot)
    if {$anteil_gk > 0} {
        set extent_gk [expr {$anteil_gk * 3.6}]
        $canvas create arc $x1 $y1 $x2 $y2 \
            -start $start_angle -extent [expr {-$extent_gk}] \
            -fill $farbe_gk -outline "#333333" -width 2 -style pieslice
    }
}

# =============================================================================
# Prozedur: schliesse_ergebnis_dialog
# Schließt das Ergebnis-Fenster
# =============================================================================
proc ::statistik::schliesse_ergebnis_dialog {} {
    variable ergebnis_fenster

    # Fenster zerstören
    if {[winfo exists $ergebnis_fenster]} {
        destroy $ergebnis_fenster
    }

    # Variable zurücksetzen
    set ergebnis_fenster ""
}

# =============================================================================
# Prozedur: html_escape
# Escaped HTML-Sonderzeichen in einem String
# Parameter: text - Der zu escapende Text
# Rückgabe: Der escapte Text
# =============================================================================
proc ::statistik::html_escape {text} {
    # Sonderzeichen durch HTML-Entities ersetzen
    set text [string map {& &amp; < &lt; > &gt; \" &quot; ' &#39;} $text]
    return $text
}

# =============================================================================
# Prozedur: erstelle_svg_kreisdiagramm
# Erstellt ein SVG-Kreisdiagramm für den HTML-Export
# Rückgabe: SVG-Code als String
# =============================================================================
proc ::statistik::erstelle_svg_kreisdiagramm {} {
    variable anteil_ld
    variable anteil_kk
    variable anteil_gk

    # SVG-Header
    set svg "<svg width=\"200\" height=\"200\" viewBox=\"0 0 200 200\" xmlns=\"http://www.w3.org/2000/svg\">\n"

    # Mittelpunkt und Radius
    set cx 100
    set cy 100
    set r 80

    # Prüfen ob Daten vorhanden
    set gesamt [expr {$anteil_ld + $anteil_kk + $anteil_gk}]

    if {$gesamt < 0.1} {
        # Keine Daten: Grauen Kreis
        append svg "  <circle cx=\"$cx\" cy=\"$cy\" r=\"$r\" fill=\"#CCCCCC\" stroke=\"#333\" stroke-width=\"2\"/>\n"
        append svg "  <text x=\"$cx\" y=\"$cy\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-size=\"12\">Keine Daten</text>\n"
        append svg "</svg>\n"
        return $svg
    }

    # Startwinkel (-90 Grad = 12 Uhr Position in SVG)
    set start_angle -90

    # Hilfsprozedur: Punkt auf Kreis berechnen
    proc punkt_auf_kreis {cx cy r winkel_grad} {
        set winkel_rad [expr {$winkel_grad * 3.14159265359 / 180.0}]
        set x [expr {$cx + $r * cos($winkel_rad)}]
        set y [expr {$cy + $r * sin($winkel_rad)}]
        return [list $x $y]
    }

    # LD-Segment (Türkis)
    if {$anteil_ld > 0} {
        set end_angle [expr {$start_angle + $anteil_ld * 3.6}]
        lassign [punkt_auf_kreis $cx $cy $r $start_angle] x1 y1
        lassign [punkt_auf_kreis $cx $cy $r $end_angle] x2 y2
        set large_arc [expr {$anteil_ld > 50 ? 1 : 0}]
        append svg "  <path d=\"M $cx $cy L $x1 $y1 A $r $r 0 $large_arc 1 $x2 $y2 Z\" fill=\"#4ACEFA\" stroke=\"#333\" stroke-width=\"1\"/>\n"
        set start_angle $end_angle
    }

    # KK-Segment (Gold)
    if {$anteil_kk > 0} {
        set end_angle [expr {$start_angle + $anteil_kk * 3.6}]
        lassign [punkt_auf_kreis $cx $cy $r $start_angle] x1 y1
        lassign [punkt_auf_kreis $cx $cy $r $end_angle] x2 y2
        set large_arc [expr {$anteil_kk > 50 ? 1 : 0}]
        append svg "  <path d=\"M $cx $cy L $x1 $y1 A $r $r 0 $large_arc 1 $x2 $y2 Z\" fill=\"#FFD700\" stroke=\"#333\" stroke-width=\"1\"/>\n"
        set start_angle $end_angle
    }

    # GK-Segment (Rot)
    if {$anteil_gk > 0} {
        set end_angle [expr {$start_angle + $anteil_gk * 3.6}]
        lassign [punkt_auf_kreis $cx $cy $r $start_angle] x1 y1
        lassign [punkt_auf_kreis $cx $cy $r $end_angle] x2 y2
        set large_arc [expr {$anteil_gk > 50 ? 1 : 0}]
        append svg "  <path d=\"M $cx $cy L $x1 $y1 A $r $r 0 $large_arc 1 $x2 $y2 Z\" fill=\"#FF6B6B\" stroke=\"#333\" stroke-width=\"1\"/>\n"
    }

    append svg "</svg>\n"

    return $svg
}

# =============================================================================
# Prozedur: erstelle_html_dokument
# Erstellt das komplette HTML-Dokument für den Export
# Rückgabe: HTML-Code als String
# =============================================================================
proc ::statistik::erstelle_html_dokument {} {
    variable von_datum
    variable bis_datum
    variable gesamt_schuetzen
    variable vereinsmitglieder
    variable haeufigster_ld
    variable haeufigster_kk
    variable haeufigster_gk
    variable haeufigster_gesamt
    variable anteil_ld
    variable anteil_kk
    variable anteil_gk
    variable anzahl_ld
    variable anzahl_kk
    variable anzahl_gk
    variable eintraege_liste

    # HTML-Dokument mit eingebettetem CSS
    set html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n"
    append html "<head>\n"
    append html "  <meta charset=\"UTF-8\">\n"
    append html "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
    append html "  <title>SVM Journal - Statistik</title>\n"
    append html "  <style>\n"

    # CSS-Styles
    append html "    * { box-sizing: border-box; }\n"
    append html "    body { font-family: Arial, Helvetica, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; color: #333; }\n"
    append html "    h1 { color: #333; text-align: center; margin-bottom: 5px; }\n"
    append html "    .subtitle { text-align: center; color: #666; margin-bottom: 30px; font-size: 1.1em; }\n"
    append html "    .container { display: flex; gap: 30px; flex-wrap: wrap; justify-content: center; max-width: 1000px; margin: 0 auto; }\n"
    append html "    .section { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); flex: 1; min-width: 280px; max-width: 450px; }\n"
    append html "    .section-title { color: #4ACEFA; font-size: 1.2em; font-weight: bold; margin-bottom: 15px; border-bottom: 2px solid #4ACEFA; padding-bottom: 8px; }\n"
    append html "    .stat-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }\n"
    append html "    .stat-row:last-child { border-bottom: none; }\n"
    append html "    .stat-label { color: #555; }\n"
    append html "    .stat-value { font-weight: bold; color: #333; }\n"
    append html "    .chart-container { text-align: center; }\n"
    append html "    .chart-container svg { margin: 10px auto; display: block; }\n"
    append html "    .legend { margin-top: 20px; text-align: left; }\n"
    append html "    .legend-item { display: flex; align-items: center; margin: 8px 0; }\n"
    append html "    .legend-color { width: 24px; height: 24px; margin-right: 12px; border: 1px solid #333; border-radius: 3px; }\n"
    append html "    .footer { margin-top: 40px; text-align: center; color: #888; font-size: 0.9em; padding-top: 20px; border-top: 1px solid #ddd; }\n"
    append html "    .color-ld { color: #4ACEFA; }\n"
    append html "    .color-kk { color: #DAA520; }\n"
    append html "    .color-gk { color: #FF6B6B; }\n"
    append html "    @media print { body { background: white; } .section { box-shadow: none; border: 1px solid #ddd; } }\n"
    append html "  </style>\n"
    append html "</head>\n"
    append html "<body>\n"

    # Titel
    append html "  <h1>SVM Journal - Statistik</h1>\n"
    append html "  <div class=\"subtitle\">Zeitraum: $von_datum bis $bis_datum</div>\n"

    # Container
    append html "  <div class=\"container\">\n"

    # Übersicht Section
    append html "    <div class=\"section\">\n"
    append html "      <div class=\"section-title\">&Uuml;bersicht</div>\n"
    append html "      <div class=\"stat-row\"><span class=\"stat-label\">Sch&uuml;tzen gesamt:</span><span class=\"stat-value\">$gesamt_schuetzen</span></div>\n"
    append html "      <div class=\"stat-row\"><span class=\"stat-label\">davon Vereinsmitglieder:</span><span class=\"stat-value\">$vereinsmitglieder</span></div>\n"
    append html "      <div class=\"stat-row\"><span class=\"stat-label\">Anzahl Eintr&auml;ge:</span><span class=\"stat-value\">[llength $eintraege_liste]</span></div>\n"
    append html "    </div>\n"

    # Häufigste Teilnehmer Section
    append html "    <div class=\"section\">\n"
    append html "      <div class=\"section-title\">H&auml;ufigste Teilnehmer (Mitglieder)</div>\n"

    # LD
    set ld_name [html_escape [dict get $haeufigster_ld name]]
    set ld_anzahl [dict get $haeufigster_ld anzahl]
    append html "      <div class=\"stat-row\"><span class=\"stat-label color-ld\">Luftdruck (LD):</span><span class=\"stat-value\">$ld_name (${ld_anzahl}x)</span></div>\n"

    # KK
    set kk_name [html_escape [dict get $haeufigster_kk name]]
    set kk_anzahl [dict get $haeufigster_kk anzahl]
    append html "      <div class=\"stat-row\"><span class=\"stat-label color-kk\">Kleinkaliber (KK):</span><span class=\"stat-value\">$kk_name (${kk_anzahl}x)</span></div>\n"

    # GK
    set gk_name [html_escape [dict get $haeufigster_gk name]]
    set gk_anzahl [dict get $haeufigster_gk anzahl]
    append html "      <div class=\"stat-row\"><span class=\"stat-label color-gk\">Gro&szlig;kaliber (GK):</span><span class=\"stat-value\">$gk_name (${gk_anzahl}x)</span></div>\n"

    # Gesamt
    set gesamt_name [html_escape [dict get $haeufigster_gesamt name]]
    set gesamt_anzahl [dict get $haeufigster_gesamt anzahl]
    append html "      <div class=\"stat-row\"><span class=\"stat-label\">Gesamt:</span><span class=\"stat-value\">$gesamt_name (${gesamt_anzahl}x)</span></div>\n"

    append html "    </div>\n"

    # Verteilung Section mit SVG-Kreisdiagramm
    append html "    <div class=\"section chart-container\">\n"
    append html "      <div class=\"section-title\">Verteilung nach Waffentyp</div>\n"
    append html [erstelle_svg_kreisdiagramm]
    append html "      <div class=\"legend\">\n"
    append html "        <div class=\"legend-item\"><div class=\"legend-color\" style=\"background: #4ACEFA;\"></div>LD - Luftdruck ([format "%.1f" $anteil_ld]% / $anzahl_ld Eintr&auml;ge)</div>\n"
    append html "        <div class=\"legend-item\"><div class=\"legend-color\" style=\"background: #FFD700;\"></div>KK - Kleinkaliber ([format "%.1f" $anteil_kk]% / $anzahl_kk Eintr&auml;ge)</div>\n"
    append html "        <div class=\"legend-item\"><div class=\"legend-color\" style=\"background: #FF6B6B;\"></div>GK - Gro&szlig;kaliber ([format "%.1f" $anteil_gk]% / $anzahl_gk Eintr&auml;ge)</div>\n"
    append html "      </div>\n"
    append html "    </div>\n"

    append html "  </div>\n"

    # Footer
    set timestamp [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]
    append html "  <div class=\"footer\">Erstellt am: $timestamp mit SVM Journal</div>\n"

    append html "</body>\n"
    append html "</html>\n"

    return $html
}

# =============================================================================
# Prozedur: exportiere_html
# Exportiert die Statistik als HTML-Datei
# =============================================================================
proc ::statistik::exportiere_html {} {
    variable ergebnis_fenster
    variable von_datum
    variable bis_datum

    # Standarddateiname mit Zeitraum
    set von_kurz [string map {"." ""} $von_datum]
    set bis_kurz [string map {"." ""} $bis_datum]
    set standard_name "Statistik_${von_kurz}_bis_${bis_kurz}.html"

    # Datei-Dialog öffnen
    set dateiname [tk_getSaveFile \
        -parent $ergebnis_fenster \
        -title "Statistik als HTML speichern" \
        -defaultextension ".html" \
        -initialfile $standard_name \
        -filetypes {{"HTML-Dateien" {.html .htm}} {"Alle Dateien" {*}}}]

    # Abbruch wenn kein Dateiname gewählt
    if {$dateiname eq ""} {
        return
    }

    # HTML-Dokument erstellen
    set html [erstelle_html_dokument]

    # Datei schreiben
    if {[catch {
        set fh [open $dateiname w]
        fconfigure $fh -encoding utf-8
        puts $fh $html
        close $fh
    } err]} {
        tk_messageBox -parent $ergebnis_fenster -icon error -title "Fehler" \
            -message "Fehler beim Speichern der Datei:\n$err"
        return
    }

    # Erfolgsmeldung
    tk_messageBox -parent $ergebnis_fenster -icon info -title "Export erfolgreich" \
        -message "Die Statistik wurde erfolgreich exportiert nach:\n$dateiname"
}
