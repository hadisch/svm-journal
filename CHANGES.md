# Änderungshistorie - SVM-Journal

## Version 1.2.6 (2026-01-27)

### Neue Features
- **Suchfunktion im Hauptfenster (Nachname/Vorname)**
  - Neuer Such-Dialog mit Live-Filterung der Eintragsliste
  - Suche beschränkt sich auf Nachname und Vorname (case-insensitive)
  - Neues Menü "Bearbeiten" in der Menüleiste (zwischen Datei und Einstellungen)
  - Menüpunkt "Suchen" mit Tastenkürzel Strg+S
  - Neuer Button "Suchen" in der Toolbar (zwischen "Eintrag bearbeiten" und "Mitglieder")
  - Live-Vorschau: Treeview wird bei jeder Tasteneingabe gefiltert
  - Escape-Taste setzt die Anzeige auf alle Einträge zurück
  - Treeview-Cache verhindert Disk-I/O während der Live-Suche
  - Neue Datei: `inc/journal_suche.tcl`
    - Prozedur `cache_journal_eintraege`: Cached Treeview-Einträge beim Dialog-Öffnen
    - Prozedur `filtere_journal_eintraege`: Filtert nach Nachname (Index 2) und Vorname (Index 3)
    - Prozedur `oeffne_journal_such_dialog`: Modaler Dialog mit Entry-Feld und Suchen-Button
  - Datei: `svm-journal.tcl`
    - Source-Anweisung für `journal_suche.tcl` (Zeile 108-109)
    - Menü "Bearbeiten" mit "Suchen"-Eintrag (Zeile 187-192)
    - Toolbar-Button "Suchen" (Zeile 233-235)
    - Tastatur-Shortcuts Strg+S (Zeile 255-257)

- **Waffenverleih: Neuer Verleihtyp "Wettkampf"**
  - Neue Checkbox "Wettkampf" im Waffenverleih-Dialog
  - Wird bei der Validierung als gültiger Verleihtyp erkannt
  - Erscheint im HTML-Export als eigenständiger Verleihtyp
  - Datei: `inc/waffenverleih_dialog.tcl`
    - Variable `typ_wettkampf` hinzugefügt (Zeile 19)
    - Validierung um Wettkampf erweitert (Zeile 544)
    - Export-Daten um Wettkampf erweitert (Zeile 631)
    - Checkbox im Dialog eingefügt (Zeile 791-796)
  - Datei: `inc/waffenverleih_html_export.tcl`
    - Wettkampf-Typ aus Export-Daten gelesen (Zeile 37-38)
    - "Wettkampf" zur Verleihtyp-Liste hinzugefügt (Zeile 66)

### Bugfixes
- **Startgeld-Berechnung: Mitgliedschaft wird jetzt anhand von Nachname UND Vorname geprüft**
  - Problem: Nur der Nachname wurde geprüft, was zu falscher Mitglied-Erkennung führen konnte
  - Beispiel: "Anna Müller" wurde als Mitglied erkannt, nur weil "Karl Müller" Mitglied ist
  - Lösung: Beide Felder müssen übereinstimmen (case-insensitive)
  - Datei: `inc/neuer_eintrag.tcl`
    - Prozedur `berechne_startgeld`: Erweiterte Mitgliedschaftsprüfung (Zeile 353-383)

- **Datenprüfung: Keine Fehlmeldungen mehr bei bekannten Dateien**
  - Problem: `verein.json`, `behoerde.json`, `fenster.json` wurden als "unbekannte Datei" gemeldet
  - Problem: `waffenregister.json` wurde fälschlich als Journal-Datei geprüft
  - Lösung: Nur Jahres-Dateien (z.B. `2025.json`) werden als Journal-Dateien behandelt
  - Lösung: Bekannte Konfigurationsdateien werden erkannt und übersprungen
  - Verweis auf nicht mehr existierendes `archiv/`-Verzeichnis aus Beschreibung entfernt
  - Beschreibungstext mit Unicode-Escapes für Windows-Kompatibilität
  - Datei: `inc/daten_pruefen_dialog.tcl`
    - Jahres-Regex-Filter für Daten-Verzeichnis (Zeile 729-740)
    - Bekannte Konfigurationsdateien erkannt (Zeile 777-783)
    - Beschreibungstext aktualisiert (Zeile 875)

---

## Version 1.2.5 (2026-01-14)

### Neue Features
- **Export-Dialog: Feldauswahl für Markdown- und HTML-Export**
  - Neue Checkbox-Auswahl ermöglicht individuelle Feldauswahl beim Export
  - 10 auswählbare Felder: Datum, Nachname, Vorname, KW, LW, Typ, Kaliber, Startgeld, Munition, Mun.Preis
  - Standard-Vorauswahl: 7 Felder (Datum bis Kaliber) aktiviert, 3 Felder (Startgeld, Munition, Mun.Preis) deaktiviert
  - Buttons "Alle auswählen" / "Alle abwählen" für schnelle Massenauswahl
  - Verwendungszweck: Export für Behördennachweise ohne Preisfelder möglich
  - 2-Spalten-Layout für übersichtliche Darstellung der Checkboxen
  - Datei: `inc/export_dialog.tcl`
    - 10 neue Namespace-Variablen für Feldauswahl (Zeile 29-39)
    - Neue Prozedur `get_feld_definitionen`: Zentrale Feld-Definition (Zeile 42-61)
    - Neue Prozedur `get_ausgewaehlte_felder`: Filtert ausgewählte Felder (Zeile 63-83)
    - Neue Prozedur `pruefe_feldauswahl`: Validiert Mindestauswahl (Zeile 85-112)
    - Neue Prozedur `waehle_alle_felder`: Aktiviert alle Felder (Zeile 114-141)
    - Neue Prozedur `waehle_keine_felder`: Deaktiviert alle Felder (Zeile 143-170)
    - `erstelle_markdown_tabelle`: Dynamische Spaltenauswahl (Zeile 520-559)
    - `erstelle_html_tabelle`: Dynamische Spaltenauswahl (Zeile 569-630)
    - `exportiere_daten`: Validierung für Mindestauswahl (Zeile 653-659)
    - LabelFrame "Felder für Export" mit Checkboxen hinzugefügt (Zeile 815-885)
    - Feldauswahl-Variablen werden beim Dialog-Öffnen zurückgesetzt (Zeile 715-725)
    - 10 Traces für Feldauswahl-Validierung (Zeile 925-935)
    - Trace-Cleanup beim Dialog-Schließen (Zeile 317-327)
    - Fenstergröße von 600x450 auf 600x700 erhöht (Zeile 769)

## Version 1.2.4 (2025-12-15)

### Bugfixes
- **Eintrag-Bearbeitung: Einträge werden jetzt korrekt übernommen**
  - Problem: Bearbeitete Einträge wurden nicht im Hauptfenster aktualisiert
  - Ursache: Uhrzeit ging bei der Auswahl verloren (wurde auf "00:00:00" gesetzt)
  - Lösung: Versteckte Spalte "uhrzeit" im Treeview hinzugefügt
  - Die Spalte wird über `-displaycolumns` ausgeblendet, speichert aber die Daten
  - Bearbeitete Einträge werden nun korrekt identifiziert und aktualisiert
  - Datei: `svm-journal.tcl`
    - Treeview um Spalte "uhrzeit" erweitert (Zeile 259, 264, 268, 281)
    - TreeviewSelect-Event liest jetzt korrekte Uhrzeit (Zeile 317-318, 324)
  - Datei: `inc/neuer_eintrag.tcl`
    - Uhrzeit wird beim Laden in versteckte Spalte eingefügt (Zeile 1329)
  - Datei: `inc/eintrag_loeschen.tcl`
    - Feld "anzahl" wird nun korrekt beim Speichern berücksichtigt (Zeile 196)

### Neue Features
- **Bearbeiten-Option im Kontextmenü**
  - Rechtsklick auf Eintrag zeigt nun "Bearbeiten" und "Löschen"
  - Menü-Einträge durch Trennlinie getrennt
  - "Bearbeiten" öffnet den Bearbeitungsdialog für den ausgewählten Eintrag
  - Datei: `inc/eintrag_loeschen.tcl`
    - Kontextmenü um Bearbeiten-Befehl erweitert (Zeile 37-40)

### Verbesserungen
- **Waffenregister: Strukturierte Tabellenansicht**
  - Listbox durch Treeview-Widget ersetzt für bessere Übersicht
  - Alle 7 Felder in klaren Spalten dargestellt:
    - Art der Waffe, Kaliber, Seriennummer, WBK-Nummer
    - Hersteller, Ausstellende Behörde, Bemerkungen
  - Horizontale und vertikale Scrollbars für einfache Navigation
  - Fenstergröße erhöht auf 1200x600 (statt 900x600)
  - Einheitliche Schriftgröße (11pt) wie im Hauptfenster
  - Datei: `inc/waffenregister_dialog.tcl`
    - Prozedur `aktualisiere_waffen_anzeige` auf Treeview umgestellt (Zeile 192-223)
    - Prozedur `listbox_auswahl_geaendert` in `treeview_auswahl_geaendert` umbenannt (Zeile 229-251)
    - Dialog-Layout mit Treeview statt Listbox (Zeile 504-556)

- **Waffenverleihformular: Verbessertes Layout**
  - "nach § 12 Abs. 1 WaffG" nun direkt unter der Überschrift
  - Mittig platziert, vor der Trennlinie
  - Kursiv und grau formatiert für bessere Lesbarkeit
  - Doppelte Zeile in Sektion "Art des Verleihs" entfernt
  - Datei: `inc/waffenverleih_html_export.tcl`
    - CSS-Klasse "subtitle" für Untertitel hinzugefügt (Zeile 107-113)
    - CSS-Klasse "title-separator" für Trennlinie hinzugefügt (Zeile 114-118)
    - Untertitel und Trennlinie unter Überschrift eingefügt (Zeile 159-160)
    - Doppelte Zeile aus Sektion 2 entfernt (Zeile 187)

### Technische Details
- **Archivierungs-Funktionalität überprüft und bestätigt**
  - Laden: Funktioniert aus beiden Verzeichnissen (daten/ und archiv/)
  - Speichern: Neue Einträge landen automatisch im richtigen Verzeichnis
  - Bearbeiten: Archivierte Einträge können problemlos bearbeitet werden
  - Löschen: Archivierte Einträge können problemlos gelöscht werden
  - Jahreswechsel-Sicherheit: Alle Funktionen arbeiten korrekt mit archivierten Daten

---

## Version 1.2.3 (2025-12-13)

### Neue Features
- **Eintrag-Bearbeiten-Funktionalität für Hauptfenster**
  - Neue Datei: `inc/eintrag_bearbeiten.tcl`
  - Neuer Button "Eintrag bearbeiten" zwischen "Neuer Eintrag" und "Mitglieder"
  - Bearbeitungsdialog mit vorausgefüllten Feldern (analog zum Mitgliederverzeichnis)
  - TreeviewSelect-Event zum Speichern des markierten Eintrags
  - Automatische Aktualisierung der Ansicht nach Bearbeitung
  - Datei: `svm-journal.tcl`
    - Source-Anweisung für `eintrag_bearbeiten.tcl` (Zeile 78-79)
    - Button "Eintrag bearbeiten" (Zeile 212-214)
    - TreeviewSelect-Event-Binding (Zeile 294-329)

- **Waffenbehörden-Name im Waffenverleihformular**
  - Behörden-Name wird automatisch aus `behoerde.json` geladen
  - Anzeige direkt hinter der WBK-Nummer im HTML-Export
  - Format: "Pistole - 9mm Luger (Ser: ABC123, WBK: 12345, Jagd- und Waffenbehörde Kreis Plön)"
  - Datei: `inc/waffenverleih_dialog.tcl`
    - Erweiterte Prozedur `lade_waffen_fuer_checkboxen` (Zeile 58-75, 116-119)
    - Behörden-Name als `ausstellende_behoerde` zu jeder Waffe hinzugefügt
  - Datei: `inc/waffenverleih_html_export.tcl`
    - Behörde wird direkt hinter WBK Nr. eingefügt (Zeile 205-215)

### Bugfixes
- **Lock-Mechanismus: MessageBox erschien im Hintergrund**
  - Hauptfenster wird beim Lock-Check jetzt korrekt versteckt
  - MessageBox erscheint garantiert im Vordergrund
  - Kein leeres Fenster mehr bei zweiter Programminstanz
  - Datei: `svm-journal.tcl`
    - Fenster wird beim Lock-Fehler mit `wm withdraw .` versteckt (Zeile 114)
    - `update` erzwingt sofortige Ausführung des Versteckens (Zeile 117)
    - MessageBox ohne Parent für Vordergrund-Anzeige (Zeile 120-121)

### Technische Details
- Globale Variable `::markierter_eintrag` zum Speichern des ausgewählten Eintrags
- Bearbeitungsdialog verwendet vorhandene Funktionen aus `neuer_eintrag.tcl` und `eintrag_loeschen.tcl`
- Vollständige Integration in bestehendes Backup- und JSON-System

---

## Version 1.2.2 (2025-12-12)

### Neue Features
- **Lock-Mechanismus zur Verhinderung mehrerer Programminstanzen**
  - Neue Datei: `inc/programm_lock.tcl`
  - PID-basiertes Lock-System im User-Daten-Verzeichnis
  - Automatische Erkennung und Entfernung von stale Locks
  - Warnung beim Versuch, eine zweite Instanz zu starten
  - Lock wird beim Programmende automatisch freigegeben

- **Autovervollständigung für Vornamen im Hauptfenster**
  - Funktioniert analog zur bestehenden Nachnamen-Autovervollständigung
  - Zeigt nur Vornamen an, die zum eingegebenen Nachnamen passen
  - Unterstützt case-insensitive Matching
  - Datei: `inc/neuer_eintrag.tcl`
    - Neue Prozeduren: `vorname_geaendert`, `vorname_autocomplete_ausgewaehlt`
    - Neue Namespace-Variablen: `vorname_autocomplete_listbox`, `vorname_autocomplete_visible`

- **Waffenregister: Neue Felder "Ausstellende Behörde" und "Bemerkungen"**
  - Ausstellende Behörde wird automatisch aus `behoerde.json` vorausgefüllt
  - Bemerkungen als mehrzeiliges Text-Widget (4 Zeilen)
  - Vollständige Abwärtskompatibilität mit bestehenden Waffen-Daten
  - Datei: `inc/waffenregister_dialog.tcl`
    - Neue Prozedur: `lade_behoerde_name`
    - Erweiterte Datenstruktur in JSON-Speicherung und -Ladung
    - Fenstergröße angepasst: 550x550 (statt 550x450)

### Verbesserungen
- **Waffenverleih: WBK-Nummer und Ausstellende Behörde jetzt optional**
  - Felder sind nur bei "Leihe" und "Verwahrung" verpflichtend
  - Bei "Transport" sind sie optional
  - Aktualisierte Labels (ohne "*") und erweiterter Hinweistext
  - Datei: `inc/waffenverleih_dialog.tcl`

- **Zentrale Backup-Verwaltung**
  - Alle Backups werden nun im zentralen Backup-Verzeichnis gespeichert
    - Linux/Mac: `~/.config/svm/backups/`
    - Windows: `%APPDATA%\SVM\backups\`
  - Backups mit Zeitstempel zur Vermeidung von Kollisionen
  - Backup-Speicherort wird in der Zusammenfassung angezeigt
  - Datei: `inc/daten_pruefen_dialog.tcl`

- **HTML-Export Waffenverleih: Erweiterte Waffenangaben**
  - Zeigt nun auch Hersteller und Ausstellende Behörde an
  - Format: Art - Kaliber (Ser: ..., WBK: ..., Hersteller: ..., Behörde: ...)
  - Felder werden nur angezeigt, wenn Daten vorhanden sind
  - Datei: `inc/waffenverleih_html_export.tcl`

- **HTML-Formular Waffenverleih: Gesetzesreferenz**
  - Zusätzlicher Text "nach § 12 Abs. 1 WaffG" unter "Art des Verleihs"
  - In kursiv formatiert
  - Datei: `inc/waffenverleih_html_export.tcl`

### Technische Details
- Hauptprogramm: `svm-journal.tcl`
  - Einbindung von `inc/programm_lock.tcl`
  - Lock-Prüfung vor GUI-Aufbau
  - Lock-Freigabe im WM_DELETE_WINDOW-Protokoll

---

## Version 1.2.1 (2025-12-11)

### Neue Features
- **Automatische Mitglieder-Vervollständigung im Waffenverleih-Dialog**
  - Beim Eingeben des Nachnamens werden vorhandene Mitgliedsdaten automatisch aus `mitglieder.json` geladen
  - Automatisches Ausfüllen von: Vorname, Geburtsdatum, Straße, Hausnummer, PLZ und Ort
  - Intelligente Trennung von Straße und Hausnummer
  - Unterstützung für mehrere Mitglieder mit gleichem Nachnamen (Auswahldialog)
  - Visuelle Bestätigung bei erfolgreichem Fund
  - Auslösung per Tab/Enter oder beim Verlassen des Namensfeldes

### Verbesserungen
- **Erweiterte JSON-Datenprüfung**
  - Prüfung umfasst nun auch das `preferences/`-Verzeichnis
  - Spezielle Prüffunktionen für `kaliber-preise.json` und `stand-nutzung.json`
  - Normalisierung von Preis-Feldern in Preferences-Dateien
  - Detaillierte Statistiken über geprüfte Verzeichnisse im Prüfbericht
  - Aktualisierte Dialog-Beschreibung mit vollständiger Verzeichnisübersicht

- **Pfad-Management**
  - Neue Funktion `::pfad::get_preferences_directory` für konsistenten Zugriff auf Preferences-Verzeichnis

### Bugfixes
- **Waffenverleih-Export**: Bestätigungsdialog erschien hinter dem Hauptfenster
  - Fehlende `-parent` Parameter in `tk_messageBox`-Aufrufen ergänzt
  - Dialog erscheint nun korrekt vor dem Waffenverleih-Fenster

### Technische Details
- Datei: `inc/waffenverleih_dialog.tcl`
  - Neue Prozeduren: `suche_mitglied_nach_nachname`, `trenne_strasse_hausnummer`, `fulle_felder_aus_mitglied`, `pruefe_und_fulle_mitglied`, `zeige_mitglieder_auswahl`, `mitglied_ausgewaehlt`
  - Event-Bindings für Namensfeld (<FocusOut>, <Return>)

- Datei: `inc/daten_pruefen_dialog.tcl`
  - Neue Prozeduren: `pruefe_kaliber_preise_datei`, `pruefe_stand_nutzung_datei`
  - Erweiterte Prozedur: `starte_pruefung` (inkl. Preferences-Verzeichnis)

- Datei: `inc/waffenverleih_html_export.tcl`
  - Zeilen 309, 315: `-parent` Parameter ergänzt

- Datei: `inc/pfad_management.tcl`
  - Zeilen 585-593: Neue Funktion `get_preferences_directory`

---

## Version 1.2 (2025-12-10)

### Neue Features
- Eingabevalidierung und Daten-Prüfungs-Werkzeug
- Fenstereinstellungen mit Geometrie-Speicherung
- Tastatur-Shortcuts für wichtige Funktionen
- UI-Verbesserungen

### Verbesserungen
- Automatische Log-Rotation (>1MB)
- Automatische Backup-Bereinigung (max. 10 Backups)
- Benutzerfreundlichere Dialoge

---

*Weitere Versionshistorie siehe Git-Log*
