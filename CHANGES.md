# Änderungshistorie - SVM-Journal

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
