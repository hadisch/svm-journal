# SVM-Journal

Journal für kleinere bis mittlere Schießsportvereine, um die regelmäßigen Aktivitäten auf dem Schießstand zu dokumentieren.

## Installation und Start

Das Programm startet man mit:
```bash
./svm-journal.tcl
```
oder
```bash
wish svm-journal.tcl
```

Beim ersten Start werden automatisch alle benötigten Verzeichnisse im User-Daten-Bereich erstellt:
- **Linux/Mac:** `~/.config/svm/`
- **Windows:** `%APPDATA%\SVM\`

Alle JSON-Dateien und Benutzerdaten werden dort gespeichert, das Programm-Verzeichnis bleibt unverändert.

## Features

### Mitgliederverwaltung
- Vollständige Verwaltung von Vereinsmitgliedern mit Kontaktdaten
- Hinzufügen, Bearbeiten und Löschen von Mitgliedern
- Suchfunktion mit Live-Filterung
- Automatische Backup-Erstellung beim Löschen von Mitgliedern

### Journal-Einträge
- Erfassung von Schießstand-Aktivitäten mit Datum, Person, Waffentyp und Kaliber
- Automatische Berechnung des Startgeldes basierend auf Mitgliedschaft und Waffentyp (Luftdruck, Kleinkaliber, Großkaliber)
- Unterscheidung zwischen Mitgliedern und Gästen mit unterschiedlichen Preisen
- Autovervollständigung für Mitgliedernamen
- Munitionsauswahl mit automatischer Preisberechnung

### Export-Funktionen
- Export nach Markdown (.md) und HTML (.html)
- Zeitraum-Filter für den Export (Alle oder spezifischer Zeitraum)
- Personen-Filter für individuelle Auswertungen

### Munitionspreise
- Verwaltung von Kalibern und zugehörigen Preisen
- Einfache Anpassung der Munitionspreise über einen Dialog

### Datenverwaltung
- JSON-basierte Datenspeicherung für einfache Portabilität
- Automatische Archivierung von Vorjahres-Einträgen
- Sortierte Anzeige aller Einträge nach Datum und Uhrzeit
- Löschen von Einträgen per Rechtsklick-Kontextmenü

### Benutzeroberfläche
- Übersichtliche Tabellen-Darstellung aller Einträge

- Intuitive Bedienung

- Statusleiste mit Datum- und Uhrzeitanzeige

  





