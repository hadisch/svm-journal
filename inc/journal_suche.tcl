# =============================================================================
# Journal-Suche - Suchfunktion für das Hauptfenster
# Ermöglicht die Suche nach Nachname und Vorname in der Eintragsliste
# mit Live-Filterung und modalem Such-Dialog
# =============================================================================

# Globale Variable zum Zwischenspeichern aller Einträge während der Suche
# Wird beim Öffnen des Such-Dialogs befüllt, damit die Filterung ohne
# erneutes Laden der JSON-Dateien funktioniert
set ::journal_such_cache {}

# =============================================================================
# Prozedur: cache_journal_eintraege
# Liest alle aktuellen Einträge aus dem Hauptfenster-Treeview in einen Cache
# Wird einmalig beim Öffnen des Such-Dialogs aufgerufen
# =============================================================================
proc cache_journal_eintraege {} {
    # Cache leeren
    set ::journal_such_cache {}

    # Zuerst die vollständige Liste von der Festplatte laden. Sonst würde bei einer
    # noch gefilterten Ansicht (frühere Suche) nur in den alten Treffern gesucht.
    aktualisiere_treeview

    # Alle Kinder-Items des Treeview durchlaufen
    foreach item [.main.tree children {}] {
        # Werte des Items holen (datum, uhrzeit, nachname, vorname, kw, lw, typ, kaliber, startgeld, munition, munpreis, bemerkungen, gratis)
        set values [.main.tree item $item -values]

        # Werte zur Cache-Liste hinzufügen
        lappend ::journal_such_cache $values
    }
}

# =============================================================================
# Prozedur: filtere_journal_eintraege
# Filtert die Journal-Einträge im Hauptfenster-Treeview nach Suchbegriff
# Sucht nur in Nachname und Vorname (nicht in allen Feldern)
# Parameter:
#   suchbegriff - Der zu suchende Text
# Rückgabe: Anzahl der gefundenen Einträge
# =============================================================================
proc filtere_journal_eintraege {suchbegriff} {
    # Alle vorhandenen Items im Treeview löschen
    .main.tree delete [.main.tree children {}]

    # Zähler für gefundene Einträge
    set gefunden_count 0

    # Suchbegriff in Kleinbuchstaben in einzelne Wörter zerlegen
    # (Mehrfach-Leerzeichen werden dabei ignoriert)
    set suchwoerter [regexp -all -inline {\S+} [string tolower $suchbegriff]]

    # Alle gecachten Einträge durchlaufen und filtern
    foreach eintrag $::journal_such_cache {
        # Nachname und Vorname aus den Werten extrahieren
        # Reihenfolge: datum(0), uhrzeit(1), nachname(2), vorname(3), kw(4), lw(5), typ(6), kaliber(7), startgeld(8), munition(9), munpreis(10), bemerkungen(11), gratis(12)
        set nachname [lindex $eintrag 2]
        set vorname [lindex $eintrag 3]

        # Suchtext nur aus Nachname und Vorname zusammensetzen
        set suchtext "$nachname $vorname"
        set suchtext_lower [string tolower $suchtext]

        # Jedes Suchwort muss in Nachname oder Vorname vorkommen - die Reihenfolge
        # ist egal, damit "Vorname Nachname" ebenso funktioniert wie "Nachname Vorname"
        set treffer 1
        foreach wort $suchwoerter {
            if {[string first $wort $suchtext_lower] == -1} {
                set treffer 0
                break
            }
        }

        # Treffer übernehmen
        if {$treffer} {
            # Treffer - Zeile ins Treeview einfügen (mit allen Originalwerten)
            .main.tree insert {} end -values $eintrag

            # Zähler erhöhen
            incr gefunden_count
        }
    }

    # Darstellung (Zebra-Streifen usw.) für die gefilterten Zeilen neu setzen
    ::hauptansicht::ansicht_aktualisiert

    # Filterhinweis in der Statusleiste anzeigen, damit klar ist, dass nicht
    # alle Einträge sichtbar sind (wird beim Neuladen der Liste entfernt)
    zeige_journal_filter_hinweis $suchbegriff $gefunden_count

    # Rückgabewert: Anzahl der gefundenen Einträge
    return $gefunden_count
}

# =============================================================================
# Prozedur: zeige_journal_filter_hinweis
# Blendet in der Statusleiste einen Hinweis auf die gefilterte Ansicht ein
# Parameter:
#   suchbegriff - Der aktive Suchbegriff
#   anzahl      - Anzahl der angezeigten Treffer
# =============================================================================
proc zeige_journal_filter_hinweis {suchbegriff anzahl} {
    # Statusleiste existiert erst nach dem Aufbau des Hauptfensters
    if {![winfo exists .statusbar.filter]} {
        return
    }
    # Trefferzahl mit korrekter Einzahl/Mehrzahl ("1 Eintrag" / "2 Einträge")
    if {$anzahl == 1} {
        set anzahl_text "1 Eintrag"
    } else {
        set anzahl_text "$anzahl Eintr\u00e4ge"
    }

    # Hinweistext mit Suchbegriff, Trefferzahl und Rückweg setzen
    .statusbar.filter configure \
        -text "Gefiltert nach \u201e[string trim $suchbegriff]\u201c: $anzahl_text \u2013 ESC zeigt alle Eintr\u00e4ge"
}

# =============================================================================
# Prozedur: entferne_journal_filter_hinweis
# Entfernt den Filterhinweis aus der Statusleiste (vollständige Liste sichtbar)
# =============================================================================
proc entferne_journal_filter_hinweis {} {
    # Nur zurücksetzen, wenn die Statusleiste bereits aufgebaut ist
    if {[winfo exists .statusbar.filter]} {
        .statusbar.filter configure -text ""
    }
}

# =============================================================================
# Prozedur: oeffne_journal_such_dialog
# Öffnet den Such-Dialog für das Hauptfenster
# Ermöglicht Live-Suche nach Nachname und Vorname in der Eintragsliste
# =============================================================================
proc oeffne_journal_such_dialog {} {
    # Prüfen, ob Such-Dialog bereits existiert
    if {[winfo exists .journal_suchdialog]} {
        # Dialog existiert bereits - in den Vordergrund bringen
        raise .journal_suchdialog
        focus .journal_suchdialog.eingabe
        return
    }

    # Aktuelle Einträge in den Cache laden (bevor der Dialog geöffnet wird)
    cache_journal_eintraege

    # ESC auf dem Hauptfenster als universellen Fallback setzen:
    # Egal wie der Such-Dialog verlassen wird (ESC, X, Suchen-Button) –
    # mit ESC kann der Nutzer immer zur vollständigen Ansicht zurückkehren.
    bind . <Escape> {
        aktualisiere_treeview
        bind . <Escape> {}
    }

    # Neues Toplevel-Fenster für Such-Dialog erstellen
    toplevel .journal_suchdialog

    # Fenstertitel setzen
    wm title .journal_suchdialog "Suchen"

    # Fenstergröße festlegen (gleich wie in Mitgliederverwaltung)
    wm geometry .journal_suchdialog 500x130

    # Fenster modal machen (im Vordergrund des Hauptfensters bleiben)
    wm transient .journal_suchdialog .

    # Frame für Inhalt mit Abstand
    frame .journal_suchdialog.frame -padx 10 -pady 10
    pack .journal_suchdialog.frame -fill both -expand 1

    # Label für Eingabefeld
    label .journal_suchdialog.frame.label -text "Suchbegriff (Nachname/Vorname):"
    pack .journal_suchdialog.frame.label -anchor w

    # Eingabefeld für Suchbegriff (gleiche Schrift wie im Hauptfenster)
    entry .journal_suchdialog.eingabe -font {TkDefaultFont 11}
    pack .journal_suchdialog.eingabe -in .journal_suchdialog.frame -fill x -pady 5

    # Frame für Buttons
    frame .journal_suchdialog.buttons
    pack .journal_suchdialog.buttons -in .journal_suchdialog.frame -pady 5

    # Button "Suchen" - fixiert das Suchergebnis und schließt den Dialog
    button .journal_suchdialog.buttons.suchen {*}$::palette::knopf_positiv -text "Suchen" -command {
        # Suchbegriff aus Eingabefeld holen
        set suchtext [.journal_suchdialog.eingabe get]

        # Prüfen, ob Suchbegriff leer ist
        if {[string trim $suchtext] eq ""} {
            # Leerer Suchbegriff - alle Einträge wiederherstellen
            aktualisiere_treeview
            destroy .journal_suchdialog
        } else {
            # Suche durchführen
            set anzahl [filtere_journal_eintraege $suchtext]

            # Wenn keine Ergebnisse gefunden wurden, MessageBox anzeigen
            if {$anzahl == 0} {
                tk_messageBox -parent .journal_suchdialog \
                              -icon warning \
                              -type ok \
                              -title "Suche" \
                              -message "Keinen passenden Eintrag gefunden"
                # Eingabefeld leeren und Fokus setzen
                .journal_suchdialog.eingabe delete 0 end
                focus .journal_suchdialog.eingabe
            } else {
                # Ergebnisse gefunden - Dialog schließen
                # Das ESC-Binding auf dem Hauptfenster wurde bereits beim Öffnen
                # des Dialogs gesetzt und bleibt bis zur Verwendung aktiv.
                destroy .journal_suchdialog
            }
        }
    }
    pack .journal_suchdialog.buttons.suchen -side left -padx 5

    # Live-Suche bei jeder Tasteneingabe (KeyRelease Event)
    bind .journal_suchdialog.eingabe <KeyRelease> {
        # Suchbegriff aus Eingabefeld holen
        set suchtext [.journal_suchdialog.eingabe get]

        # Prüfen, ob Suchbegriff leer ist
        if {[string trim $suchtext] eq ""} {
            # Leerer Suchbegriff - alle Einträge aus Cache wiederherstellen
            .main.tree delete [.main.tree children {}]
            foreach eintrag $::journal_such_cache {
                .main.tree insert {} end -values $eintrag
            }
            # Darstellung (Zebra-Streifen usw.) für die wiederhergestellten Zeilen setzen
            ::hauptansicht::ansicht_aktualisiert
            # Vollständige Liste sichtbar - Filterhinweis entfernen
            entferne_journal_filter_hinweis
        } else {
            # Live-Filterung durchführen
            filtere_journal_eintraege $suchtext
        }
    }

    # Enter-Taste löst Suchen-Button aus
    bind .journal_suchdialog.eingabe <Return> {
        .journal_suchdialog.buttons.suchen invoke
    }

    # ESC-Taste schließt den Dialog und zeigt alle Einträge wieder
    bind .journal_suchdialog <Escape> {
        # Alle Einträge wiederherstellen (von Disk laden)
        aktualisiere_treeview
        destroy .journal_suchdialog
    }

    # Beim Schließen über das X des Fensters ebenfalls alle Einträge wiederherstellen.
    # Ohne diesen Handler bliebe der Treeview leer, wenn der Dialog per X geschlossen wird,
    # ohne dass Suchergebnisse vorhanden waren.
    wm protocol .journal_suchdialog WM_DELETE_WINDOW {
        aktualisiere_treeview
        destroy .journal_suchdialog
    }

    # Fokus auf Eingabefeld setzen
    focus .journal_suchdialog.eingabe
}
