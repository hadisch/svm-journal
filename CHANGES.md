# Änderungshistorie - SVM-Journal

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
