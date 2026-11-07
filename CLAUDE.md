# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt-Überblick

SVM-Journal ist eine Tcl/Tk-Desktopanwendung zur Verwaltung von Schießsportvereinen (Schießstand-Protokoll, Mitglieder, Waffenregister, Gäste, Blacklist, Export). Das Hauptprogramm heißt `svm-journal.tcl` und bindet alle Module per `source` ein.

## Programm starten

```bash
wish svm-journal.tcl
# oder direkt (Shebang: #!/usr/bin/env wish)
./svm-journal.tcl
```

## Architektur

### Modulstruktur

`svm-journal.tcl` ist das Einstiegspunkt-Skript. Es lädt per `source` alle Module aus `inc/`. Jede `source`-Anweisung muss einen erklärenden Kommentar haben. Neue logisch zusammenhängende Codeblöcke gehören in eigene Dateien unter `inc/`, nicht direkt in `svm-journal.tcl`.

### Namespaces

Jedes Modul unter `inc/` kapselt seinen Code in einem eigenen Namespace:

| Namespace                          | Datei                            | Funktion                                                                      |
| ---------------------------------- | -------------------------------- | ----------------------------------------------------------------------------- |
| `::pfad`                           | `pfad_management.tcl`            | Plattformübergreifende Pfadverwaltung (MUSS zuerst geladen werden)            |
| `::programm_lock`                  | `programm_lock.tcl`              | Verhindert mehrere Programminstanzen                                          |
| `::neuer_eintrag`                  | `neuer_eintrag.tcl`              | Dialog zum Erfassen neuer Schießstand-Einträge                                |
| `::gaeste`                         | `gaeste_verwaltung.tcl`          | Gästeliste lesen/schreiben                                                    |
| `::blacklist`                      | `blacklist_dialog.tcl`           | Gesperrte Personen verwalten                                                  |
| `::export`                         | `export_dialog.tcl`              | Markdown- und HTML-Export                                                     |
| `::statistik`                      | `statistik_dialog.tcl`           | Statistiken und Kreisdiagramm                                                 |
| `::waffenregister`                 | `waffenregister_dialog.tcl`      | Vereinswaffen verwalten                                                       |
| `::waffenverleih`                  | `waffenverleih_dialog.tcl`       | Waffenausleihe dokumentieren                                                  |
| `::waffenverleih::export`          | `waffenverleih_html_export.tcl`  | HTML-Export für Waffenverleih                                                 |
| `::daten_pruefen`                  | `daten_pruefen_dialog.tcl`       | JSON-Datenbank überprüfen und reparieren                                      |
| `::toolbar_icons`                  | `toolbar_icons.tcl`              | Icons für die Toolbar laden                                                   |
| `::tooltip`                        | `tooltip.tcl`                    | Tooltip-System                                                                |
| `::namen`                          | `namen.tcl`                      | Zentrale Namensbereinigung, Vergleichsschlüssel, Erkennung von Vertauschungen/Tippfehlern |
| `::namensbericht`                  | `namensbericht.tcl`              | Prüfbericht über verdächtige Namen (aus "Daten überprüfen", ändert keine Daten) |
| `::munpreise`                      | `munitions_preise_dialog.tcl`    | Munitionspreise verwalten                                                     |
| `::standpreise`                    | `standnutzung_preise_dialog.tcl` | Standnutzungspreise verwalten                                                 |
| `::verein`                         | `verein_dialog.tcl`              | Vereinsdaten verwalten                                                        |
| `::behoerde`                       | `behoerde_dialog.tcl`            | Behördendaten verwalten                                                       |
| `::erscheinungsbild` / `::palette` | `erscheinungsbild.tcl`           | Zentrale Optik-Einstellungen (flache Ränder, moderne Schrift) und Farbpalette |

Module ohne eigenen Namespace (`json_reader.tcl`, `json_writer.tcl`, `mitglieder_fenster.tcl`, `eintrag_bearbeiten.tcl`, `eintrag_loeschen.tcl`, `exit_confirm.tcl`, `fenster_einstellungen.tcl`, `journal_suche.tcl`) definieren globale Prozeduren.

### Datenspeicherung

Benutzerdaten werden **nicht** im Programmverzeichnis gespeichert, sondern über `::pfad::get_json_path` im plattformabhängigen User-Daten-Verzeichnis:

- Linux/Mac: `~/.config/svm/`
- Windows: `%APPDATA%\SVM\`

Unterverzeichnisse: `daten/` (Journal-Einträge, Mitglieder, Waffenregister, Gäste, Blacklist), `preferences/` (Kaliber, Preise, Verein, Behörde), `backups/`.

Journal-Einträge werden jahresweise in JSON-Dateien gespeichert (z.B. `daten/2026.json`). Jeder Eintrag enthält die Felder: `datum`, `uhrzeit`, `nachname`, `vorname`, `kurzwaffe`, `langwaffe`, `waffentyp`, `kaliber`, `startgeld`, `munition`, `munitionspreis`, `bemerkungen`, `gratis`.

### Hauptfenster-Treeview

Das zentrale Widget `.main.tree` zeigt alle Journal-Einträge. Die Spalten `uhrzeit` und `gratis` sind versteckt (nicht in `-displaycolumns`) und werden nur intern für Bearbeiten-Dialoge verwendet. Die globale Variable `::markierter_eintrag` (Dictionary) hält den aktuell ausgewählten Eintrag.

### Icons und Ressourcen

Icons liegen im Verzeichnis `resources/` als PNG-Dateien und werden über `::toolbar_icons::load_all` geladen. Neue Icons dort ablegen und in `toolbar_icons.tcl` (Variable + Switch-Case) registrieren.

## Coding-Regeln

- Inline-Kommentare für jede nicht-triviale Zeile; Block-Kommentare für jeden logischen Abschnitt.
- Umlaute in Menüeinträgen als Unicode-Escapes schreiben (z.B. `ü` für ü, `ö` für ö, `ä` für ä, `Ü` für Ü), damit sie unter Windows korrekt dargestellt werden.
- Aktions-Buttons farblich nach Bedeutung darstellen: positive/bestätigende Aktionen (Speichern, Hinzufügen, Exportieren, Neu) in Vereinsgrün mit weißer Schrift, sekundäre Aktionen (Abbrechen, Schließen) in neutralem Grau. Farbwerte siehe Namespace `::palette` in `inc/erscheinungsbild.tcl`. Bedeutungstragende Farben (z.B. Kategorie-/Warnfarben, Statistik) davon ausnehmen.
- Neue logisch zusammenhängende Module unter `inc/` auslagern, nicht in `svm-journal.tcl` schreiben.
- Personennamen (Nachname/Vorname) vor dem Speichern immer mit `::namen::normalisiere` bereinigen und für Vergleiche `::namen::schluessel` verwenden, nie exakte String-Vergleiche.

## Versionierung

Versionierungsschema: x.x.x - Die erste Stelle zeigt grundlegende Änderungen an, die zweite Stelle wird bei neu hinzugefügten Features erhöht und die dritte Stelle bei kleineren Anpassungen und Bugfixes.

Beim Erhöhen der Versionsnummer:

1. `inc/ueber_dialog.tcl` — Label `Version X.Y.Z` anpassen
2. `CHANGES.md` — Eintrag mit allen Änderungen ergänzen
3. Commit auf beide Remotes pushen:

   ```bash
   git push origin main   # Gitea (192.168.178.218)
   git push github main   # GitHub
   ```
