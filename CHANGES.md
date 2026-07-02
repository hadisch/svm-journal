# Änderungshistorie - SVM-Journal

## Version 1.7.2 (2026-07-02)

### Geändert
- **Moderneres Erscheinungsbild (keine funktionalen Änderungen)**
  - Flache Ränder statt der grauen 3D-Bevel-Optik bei allen Buttons und Eingabefeldern
  - Moderne Systemschrift für alle Widgets, die die benannten Tk-Schriften verwenden (z.B. Noto Sans unter Linux, Segoe UI unter Windows)
  - Etwas mehr Innenabstand (Padding) an Buttons für ein luftigeres Erscheinungsbild
- **Vereinheitlichte, dezente Button-Farben ("hell & neutral")**
  - Positive Aktionen (Speichern, Hinzufügen, Exportieren, Neu) jetzt in Vereinsgrün (`#569A40`) mit weißer Schrift statt Pastellgrün
  - Sekundäre Aktionen (Abbrechen, Schließen) in neutralem Grau (`#E0E0E0`) statt Rosa/Cyan
  - Verbliebene 3D-`raised`-Toolbar-Buttons (Gäste-/Blacklist-Fenster) auf flache Darstellung umgestellt
  - Bedeutungstragende Farben (Kategorie-/Warnfarben in Statistik, HTML-Export) bleiben unverändert

### Technische Details
- Datei: `inc/erscheinungsbild.tcl` (neu, Namespaces `::erscheinungsbild` und `::palette`)
  - `::erscheinungsbild::anwenden` setzt vor der Widget-Erzeugung die Optik-Vorgaben über die Tk-Option-Datenbank und die benannten Schriften
  - `::palette` als zentrale, dokumentierte Quelle der Wahrheit für die Button-Farben
- Datei: `svm-journal.tcl`
  - Neue `source`-Anweisung für `inc/erscheinungsbild.tcl` samt Aufruf von `::erscheinungsbild::anwenden` vor der Widget-Erzeugung
- Button-Farbwerte in 16 Dialog-/Fenster-Modulen unter `inc/` an das neue Schema angepasst
- Datei: `CLAUDE.md`
  - Coding-Regel für Button-Farben auf das bedeutungsbasierte Schema aktualisiert
  - Neues Modul in der Namespace-Tabelle ergänzt

---

## Version 1.7.1 (2026-06-24)

### Geändert
- **Teilnahme am Training: Spaltenüberschrift "Gesamt" umbenannt**
  - Die Spalte heißt jetzt "Summe Kurz+Lang" (im Ergebnisfenster und im HTML-Export)
  - Klarstellung, dass dieser Wert die Summe der getrennt gezählten Kurz- und Langwaffen-Trainingstage ist und sich dadurch von der Eintragszählung im Statistik-Fenster unterscheidet

### Technische Details
- Datei: `inc/teilnahme_dialog.tcl`
  - Treeview-Überschrift `gesamt` von "Gesamt" auf "Summe Kurz+Lang" geändert
  - HTML-Export-Tabellenkopf entsprechend angepasst

---

## Version 1.7.0 (2026-06-24)

### Neue Features
- **Menü Werkzeuge: Teilnahme am Training (Bedürfnisnachweis)**
  - Neuer Menüeintrag "Teilnahme am Training" unter Werkzeuge (direkt nach "Statistik")
  - Vorgeschalteter Zeitraum-Dialog (Standard: 01.01. des laufenden Jahres bis heute)
  - Ergebnisfenster mit Tabelle: Name, Kurzwaffe, Langwaffe, Gesamt (jeweils "x mal")
  - Zählweise: pro Trainingstag (mehrere Einträge am selben Tag mit derselben Waffengattung zählen als eine Teilnahme); Gesamt = Kurzwaffe + Langwaffe
  - Ausgewertet werden ausschließlich Vereinsmitglieder (aus `mitglieder.json`); Mitglieder ohne Teilnahme erscheinen mit 0
  - Farbliche Hervorhebung: Grün (mind. 6 Teilnahmen bei beiden Waffengattungen), Rot (noch keine Teilnahme), Schwarz (übrige)
  - HTML-Export der Auswertung
  - Fenstergröße wie die Mitgliederverwaltung (1600x800), zentriert über dem Hauptfenster

### Entfernt
- **Markdown-Export**
  - Der Export nach Markdown wird nicht genutzt und wurde vollständig entfernt
  - Das Untermenü "Datei → Exportieren" (Markdown/HTML) ist jetzt ein direkter Befehl "Datei → Exportieren…", der den HTML-Export öffnet

### Technische Details
- Datei: `inc/teilnahme_dialog.tcl` (neu, Namespace `::teilnahme`)
  - Prozeduren u.a.: `open_zeitraum_dialog`, `berechne_teilnahme`, `zeige_ergebnis_fenster`, `bestimme_farbtag`, `erstelle_html_dokument`, `exportiere_html`
  - Nutzt die Datums-Hilfsfunktionen aus `::statistik` wieder
- Datei: `svm-journal.tcl`
  - Neue `source`-Anweisung für `inc/teilnahme_dialog.tcl`
  - Menüeintrag "Teilnahme am Training" im Werkzeuge-Menü ergänzt
  - Export-Untermenü durch direkten Befehl "Exportieren…" ersetzt
- Datei: `inc/export_dialog.tcl`
  - Prozedur `erstelle_markdown_tabelle` und alle Markdown-Verzweigungen entfernt
  - Namespace-Variable `export_format` entfernt; `open_export_dialog` ohne Format-Parameter

---

## Version 1.6.1 (2026-05-22)

### Neue Features
- **Menü Werkzeuge: Mitgliederliste und Gästeliste**
  - Neuer Menüeintrag "Mitgliederliste" unter Werkzeuge → öffnet das bestehende Mitgliederverwaltungsfenster
  - Neuer Menüeintrag "Gästeliste" unter Werkzeuge → öffnet das neue Gästeverwaltungsfenster
  - Beide Einträge stehen am Anfang des Werkzeuge-Menüs (vor Waffenregister)

- **Neue Datei: `inc/gaeste_fenster.tcl` (Namespace `::gaeste_fenster`)**
  - Fenster zur manuellen Verwaltung der Gästeliste (`gaeste.json`)
  - Toolbar mit Buttons: Hinzufügen, Bearbeiten, Löschen, Schließen
  - Treeview mit zwei Spalten: Nachname und Vorname
  - Statuszeile zeigt aktuelle Anzahl der eingetragenen Gastschützen
  - **Hinzufügen**: Sub-Dialog mit Pflichtfeld-Validierung und Duplikatprüfung (case-insensitiv)
  - **Bearbeiten**: Sub-Dialog mit vorausgefüllten Feldern; Duplikatprüfung gegen andere Einträge
  - **Löschen**: Bestätigungsdialog vor dem Entfernen
  - Doppelklick und Enter-Taste öffnen den Bearbeiten-Dialog
  - ESC schließt das Fenster
  - Manuell hinzugefügte Gäste werden beim nächsten Besuch im "Neuer Eintrag"-Dialog sofort als bekannte Gäste erkannt
  - Alphabetische Sortierung nach Nachname, dann Vorname
  - Liest Daten über `::gaeste::lade_gaeste` aus `gaeste_verwaltung.tcl`

### Technische Details
- Datei: `svm-journal.tcl`
  - Neue `source`-Anweisung für `inc/gaeste_fenster.tcl`
  - Menüeinträge "Mitgliederliste" und "Gästeliste" im Werkzeuge-Menü ergänzt
- Datei: `inc/gaeste_fenster.tcl` (neu)
  - Prozeduren: `lade_gaeste_fuer_fenster`, `speichere_gaeste_fenster`, `aktualisiere_anzeige`
  - Prozeduren: `oeffne_hinzufuegen_dialog`, `pruefe_hinzufuegen_button`, `speichere_neuen_gast`
  - Prozeduren: `oeffne_bearbeiten_dialog`, `pruefe_bearbeiten_button`, `speichere_geaenderten_gast`
  - Prozeduren: `loesche_gast`, `open_gaeste_fenster` (global)

---

## Version 1.6.0 (2026-05-01)

### Neue Features
- **Gastschützen-Verwaltung mit automatischer Gästeliste**
  - Neue Datei: `inc/gaeste_verwaltung.tcl` (Namespace `::gaeste`)
  - Neue Datenbankdatei `daten/gaeste.json` wird beim ersten Gastschützen-Besuch automatisch angelegt
  - Beim Erfassen eines Schützen wird automatisch geprüft, ob es sich um ein Vereinsmitglied
    oder einen Gastschützen handelt

- **Automatische Prüfung beim Ausfüllen von Vor- und Nachname**
  - Ist die Person kein Mitglied, wird `gaeste.json` abgefragt:
    - **Unbekannter Gast**: Warnhinweis "Bitte unbedingt die Personalien aufnehmen und den
      Personalausweis oder Reisepass kopieren" → Person wird nach OK automatisch in `gaeste.json` eingetragen
    - **Bekannter Gast**: Info-Hinweis "Bereits in der Gäste Liste vorhanden. Weitere Daten
      müssen nicht erhoben werden."
  - Prüfung erfolgt beim Verlassen der Namensfelder (FocusOut) sowie nach Autocomplete-Auswahl
  - Ein Flag verhindert das doppelte Anzeigen des Dialogs für dieselbe Namenskombination

- **Automatisches Vorausfüllen von "Gastschütze" im Bemerkungsfeld**
  - Wird bei erkannten Gastschützen automatisch gesetzt (nur wenn Bemerkungsfeld noch leer)

### Technische Details
- Neue Datei: `inc/gaeste_verwaltung.tcl`
  - Prozedur `::gaeste::lade_gaeste`: Liest alle bekannten Gäste aus `gaeste.json`
  - Prozedur `::gaeste::ist_gast {vorname nachname}`: Case-insensitive Prüfung ob Person bekannt
  - Prozedur `::gaeste::trage_gast_ein {vorname nachname}`: Schreibt neuen Gast in `gaeste.json`
- Datei: `svm-journal.tcl`
  - Neuer Pfad `gaeste_json` → `daten/gaeste.json`
  - Source-Anweisung für `gaeste_verwaltung.tcl`
- Datei: `inc/neuer_eintrag.tcl`
  - Neue Namespace-Variablen: `gaeste_dialog_angezeigt`, `letzter_gepruefter_name`
  - Neue Prozedur `::neuer_eintrag::pruefe_gastschuetze`
  - FocusOut-Bindings auf beide Namensfelder
  - Flag-Reset in `nachname_geaendert` und `vorname_geaendert`
  - Aufruf nach Autocomplete-Auswahl in `autocomplete_ausgewaehlt` und `vorname_autocomplete_ausgewaehlt`

---

## Version 1.5.1 (2026-04-11)

### Neue Features
- **Gratis-Berechtigung für Schützen (Startgeld = 0,00 € intentional)**
  - Löst das Problem, dass legitime 0,00€-Startgeld-Einträge (z.B. bei Ausnahmeregelungen) nicht mehr
    fälschlich als Datenfehler behandelt werden können
  - Neues Feld `gratis` ("Ja"/"Nein") in jedem Journal-Eintrag
  - Vollständige Abwärtskompatibilität: Bestehende Einträge erhalten automatisch `gratis = "Nein"`

- **Gratis-Checkbox im "Neuer Eintrag"-Dialog**
  - Gelb hinterlegte Checkbox "Gratis-Berechtigung (Startgeld entfällt)" direkt unter dem Startgeld-Feld
  - Bei Aktivierung: Startgeld wird auf 0,00 € gesetzt und das Eingabefeld gesperrt
  - Bei Deaktivierung: Startgeld-Feld wird freigegeben und der reguläre Preis neu berechnet
  - Automatische Preissperre: `berechne_startgeld` überschreibt bei aktivierter Gratis-Berechtigung
    den Wert nicht (auch nicht bei Namens- oder Waffentyp-Änderungen)
  - Datei: `inc/neuer_eintrag.tcl`
    - Neue Namespace-Variable `gratis`
    - Neue Prozedur `gratis_geaendert`: steuert Sperren/Freigeben des Startgeld-Felds
    - `berechne_startgeld`: Guard bei aktivem Gratis-Flag
    - `speichern_und_anzeigen`, `speichere_eintrag_json`, `lade_eintraege_aus_datei`,
      `lade_existierende_eintraege`: alle um `gratis` erweitert
    - Fensterhöhe auf 680px erhöht

- **Gratis-Checkbox im "Eintrag bearbeiten"-Dialog**
  - Identisches Verhalten wie im "Neuer Eintrag"-Dialog
  - Bestehende Gratis-Einträge werden beim Öffnen korrekt vorbelegt (Feld gesperrt)
  - Datei: `inc/eintrag_bearbeiten.tcl`
    - `gratis` aus `::markierter_eintrag` lesen (Abwärtskompatibilität)
    - Checkbox in der UI, gespeichertes Dict enthält `gratis`
    - Fensterhöhe auf 640px erhöht

- **Gratis-Flag als versteckte Treeview-Spalte**
  - `gratis` wird als versteckte Spalte im Hauptfenster-Treeview geführt (analog zu `uhrzeit`)
  - Dadurch steht der Wert beim Öffnen des Bearbeiten-Dialogs stets zur Verfügung
  - Datei: `svm-journal.tcl`
    - Spalte `gratis` zu `-columns` hinzugefügt (nicht in `-displaycolumns`)
    - `::markierter_eintrag` enthält jetzt das `gratis`-Feld

### Verbesserungen
- **Datenprüfung: gratis-Feld bei alten Einträgen ergänzen**
  - Beim Prüfen älterer JSON-Dateien ohne `gratis`-Feld wird `"Nein"` automatisch ergänzt und gespeichert
  - Dateien: `inc/daten_pruefen_dialog.tcl`, `inc/eintrag_loeschen.tcl`, `inc/neuer_eintrag.tcl`

### Technische Details
- JSON-Format aller Journal-Einträge um Feld `"gratis": "Ja"|"Nein"` erweitert
- Alle JSON-Schreib-/Leseprozeduren angepasst (neuer_eintrag, eintrag_loeschen, daten_pruefen)
- Kommentare in `inc/journal_suche.tcl` aktualisiert (Spaltenindex-Dokumentation)

---

## Version 1.4.0 (2026-03-14)

### Neue Features
- **Blacklist-Verwaltung: Sperrung von Personen vom Schießbetrieb**
  - Neue Datei: `inc/blacklist_dialog.tcl`
  - Gesperrte Personen werden in `daten/blacklist.json` gespeichert (wird beim ersten Aufruf automatisch angelegt)
  - Verwaltungsfenster mit Treeview (Nachname/Vorname), Toolbar (Hinzufügen, Löschen, Schließen) und Statuszeile
  - Hinzufügen-Sub-Dialog mit Duplikatprüfung und Pflichtfeld-Validierung
  - Liste wird alphabetisch nach Nachname/Vorname sortiert
  - Doppelklick auf Eintrag öffnet Löschen-Dialog
  - ESC-Taste schließt beide Fenster
  - Neues Icon: `resources/Blacklist.png`
  - Datei: `inc/toolbar_icons.tcl`
    - Variable `icon_blacklist` und `"Blacklist.png"` zur Icon-Liste hinzugefügt
    - Switch-Case für "blacklist" in `get`-Prozedur ergänzt

- **Blacklist-Prüfung beim Erfassen neuer Einträge**
  - Datei: `inc/neuer_eintrag.tcl`
  - Neue Variable `blacklist_gesperrt` im Namespace `::neuer_eintrag`
  - Neue Prozedur `::neuer_eintrag::pruefe_blacklist`: Prüft bei Namenseingabe ob die Person gesperrt ist
  - Roter Warnhinweis und Deaktivierung des Speichern-Buttons bei gesperrter Person
  - Prüfung erfolgt case-insensitiv beim Eingeben von Nach- und Vorname

- **Mitglied-Detailfenster in der Mitgliederverwaltung**
  - Enter-Taste und Doppelklick öffnen das Detailfenster des ausgewählten Mitglieds
  - Rechtsklick-Kontextmenü mit Optionen: Öffnen, Bearbeiten, Löschen
  - Datei: `inc/mitglieder_fenster.tcl`

- **Schnellzugriff im Hauptfenster**
  - Doppelklick und Enter auf einem Journaleintrag öffnen direkt den "Eintrag bearbeiten"-Dialog
  - Datei: `svm-journal.tcl`

### Verbesserungen
- **Neues Feld "Geburtsort" in der Mitgliederverwaltung**
  - Geburtsort wird in `mitglieder.json` gespeichert und in allen Dialogen (Hinzufügen/Bearbeiten) angezeigt
  - Rückwärtskompatibilität: Ältere `mitglieder.json`-Dateien ohne Geburtsort-Feld werden korrekt geladen
  - Bestehende Mitglieder-Einträge um das `geburtsort`-Feld ergänzt
  - Geburtsort wird im Waffenverleih-Dialog automatisch mit befüllt (Autofill)
  - Dateien: `inc/mitglieder_fenster.tcl`, `inc/waffenverleih_dialog.tcl`, `inc/json_writer.tcl`

- **Hover-Effekt auf Spaltenköpfen deaktiviert**
  - Spaltenbezeichnungen im Treeview reagieren nicht mehr auf Maus-Hover (via `ttk::style map`)
  - Verhindert unerwünschte visuelle Hervorhebung beim Überfahren der Spaltenköpfe
  - Datei: `svm-journal.tcl`

---

## Version 1.3.4 (2026-03-05)

### Verbesserungen
- **Mitglieder-Verwaltung: Alphabetische Sortierung nach dem Hinzufügen/Bearbeiten**
  - Problem: Neu hinzugefügte Mitglieder wurden ans Ende der Liste angehängt statt alphabetisch einsortiert
  - Lösung: Neue Prozedur `sortiere_mitglieder_liste` sortiert die Liste nach Nachname (primär) und Vorname (sekundär), case-insensitiv
  - Die Sortierung wird nach dem Hinzufügen und nach dem Bearbeiten eines Mitglieds automatisch aufgerufen
  - Datei: `inc/mitglieder_fenster.tcl`
    - Neue Prozedur `sortiere_mitglieder_liste` mit `lsort -command` und anonymer Vergleichsfunktion
    - Aufruf nach `lappend` im Hinzufügen-Dialog
    - Aufruf nach `lreplace` im Bearbeiten-Dialog

---

## Version 1.3.3 (2026-02-26)

### Bugfixes
- **Mitglieder-Fenster: Absturz beim ersten Start ohne mitglieder.json**
  - Problem: Beim Öffnen des Mitglieder-Fensters ohne vorhandene `mitglieder.json` wurde
    auf das nicht existierende Widget `.mitglieder.main.text` zugegriffen, was zu einem
    Laufzeitfehler führte (`invalid command name ".mitglieder.main.text"`)
  - Lösung: Statt einer Fehlermeldung wird beim ersten Start eine leere, korrekt
    strukturierte `mitglieder.json` automatisch angelegt (inkl. Verzeichnis-Erstellung)
  - Der Anwender sieht ein leeres Treeview und kann sofort Mitglieder hinzufügen
  - Datei: `inc/mitglieder_fenster.tcl`
    - `else`-Zweig in `open_mitglieder_fenster`: Verzeichnis anlegen + `schreibe_mitglieder_json` aufrufen

---

## Version 1.3.2 (2026-02-26)

### Bugfixes
- **Umlaut-Fehler im Tooltip des Löschen-Buttons unter Windows**
  - Problem: Der Tooltip "Ausgewählten Eintrag löschen" verwendete direkte UTF-8-Zeichen
  - Lösung: Umlaute durch Unicode-Escapes ersetzt (`\u00e4` für ä, `\u00f6` für ö)
  - Datei: `svm-journal.tcl`
    - Zeile 281: `"Ausgew\u00e4hlten Eintrag l\u00f6schen"`

### Verbesserungen
- **Automatischer Scroll zum letzten Eintrag beim Programmstart**
  - Das Hauptfenster scrollt nach dem Laden der Einträge automatisch zum jüngsten Eintrag
  - Besonders hilfreich bei vielen Einträgen, da der aktuellste Eintrag sofort sichtbar ist
  - Datei: `svm-journal.tcl`
    - Nach `lade_existierende_eintraege`: Scroll-Code mit `.main.tree see [lindex $items end]`

---

## Version 1.3.1 (2026-02-08)

### Neue Features
- **Bemerkungen-Feld im Hauptfenster**
  - Neue Spalte "Bemerkungen" am Ende der Treeview-Tabelle
  - Eingabefeld im "Neuer Eintrag"-Dialog
  - Eingabefeld im "Eintrag bearbeiten"-Dialog
  - Checkbox im Export-Dialog zur optionalen Einbeziehung
  - Abwärtskompatibilität: Alte Einträge ohne Bemerkungen werden automatisch mit leerem String ergänzt
  - Spaltenbreiten optimiert: Munition (130→100), Mun.Preis (80→70), Bemerkungen (170)

### Technische Details
- Datei: `svm-journal.tcl`
  - Treeview um Spalte "bemerkungen" erweitert
  - Spaltenbreiten angepasst für optimale Platznutzung
  - Dictionary-Erstellung und lassign erweitert
- Datei: `inc/neuer_eintrag.tcl`
  - Variable `bemerkungen` im Namespace
  - Eingabefeld nach Munitionspreis
  - JSON-Reader/Writer mit Abwärtskompatibilität
  - Treeview-Insert um Bemerkungen erweitert
- Datei: `inc/eintrag_bearbeiten.tcl`
  - Eingabefeld für Bemerkungen
  - Fensterhöhe auf 600px erhöht
  - Dictionary beim Speichern erweitert
- Datei: `inc/eintrag_loeschen.tcl`
  - lassign und JSON-Writer angepasst
- Datei: `inc/export_dialog.tcl`
  - Neue Variable `feld_bemerkungen`
  - Checkbox und Traces hinzugefügt
- Datei: `inc/daten_pruefen_dialog.tcl`
  - JSON-Reader/Writer mit Abwärtskompatibilität
  - Automatisches Ergänzen fehlender Bemerkungen-Felder
- Datei: `inc/journal_suche.tcl`
  - Kommentare aktualisiert
- Dateien: `daten/2025.json`, `daten/2026.json`
  - Alle Einträge um `"bemerkungen": ""` ergänzt

---

## Version 1.3.0 (2026-01-31)

### Neue Features
- **Statistik-Funktion für den Schießbetrieb**
  - Neuer Menüeintrag "Werkzeuge → Statistik"
  - Neuer Toolbar-Button "Statistik" (links neben dem Löschen-Icon)
  - Tooltip: "Statistiken über den Schießbetrieb"
  - Zeitraum-Auswahl-Dialog mit vorausgefüllten Datumsfeldern:
    - Von: 01.01. des aktuellen Jahres
    - Bis: Aktuelles Datum
  - Ergebnis-Dialog mit folgenden Statistiken:
    - Gesamtzahl der Schützen im Zeitraum
    - Anzahl der Vereinsmitglieder (Abgleich mit mitglieder.json)
    - Anzahl der Einträge insgesamt
    - Häufigster Teilnehmer bei Luftdruck (LD)
    - Häufigster Teilnehmer bei Kleinkaliber (KK)
    - Häufigster Teilnehmer bei Großkaliber (GK)
    - Häufigster Teilnehmer gesamt (alle Waffentypen)
  - Canvas-basiertes Kreisdiagramm mit prozentualer Verteilung:
    - Türkis (#4ACEFA) für Luftdruck
    - Gold (#FFD700) für Kleinkaliber
    - Rot (#FF6B6B) für Großkaliber
  - Legende mit Prozentangaben und absoluten Zahlen
  - HTML-Export mit eingebettetem SVG-Kreisdiagramm
  - Modernes, responsives CSS-Layout im HTML-Export
  - Neue Datei: `inc/statistik_dialog.tcl` (~800 Zeilen)
    - Namespace `::statistik` mit allen Variablen und Prozeduren
    - Prozedur `open_zeitraum_dialog`: Zeitraum-Auswahl
    - Prozedur `berechne_statistik`: Hauptberechnung
    - Prozedur `lade_eintraege_im_zeitraum`: Datenladung mit Datumsfilter
    - Prozedur `zaehle_unique_schuetzen`: Eindeutige Personen zählen
    - Prozedur `zaehle_vereinsmitglieder`: Mitglieder-Abgleich
    - Prozedur `finde_haeufigsten_teilnehmer`: Top-Teilnehmer ermitteln
    - Prozedur `berechne_prozentuale_verteilung`: Verteilung LD/KK/GK
    - Prozedur `zeige_ergebnis_dialog`: Ergebnisanzeige
    - Prozedur `zeichne_kreisdiagramm`: Canvas Pie-Chart
    - Prozedur `erstelle_svg_kreisdiagramm`: SVG für HTML-Export
    - Prozedur `exportiere_html`: HTML-Datei speichern
  - Datei: `inc/toolbar_icons.tcl`
    - Variable `icon_statistik` hinzugefügt
    - `Statistik.png` zur Icon-Liste hinzugefügt
    - Switch-Case für "statistik" in get-Prozedur
  - Datei: `svm-journal.tcl`
    - Source-Anweisung für `statistik_dialog.tcl`
    - Menüeintrag unter Werkzeuge hinzugefügt
    - Toolbar-Button zwischen Mitglieder und Löschen eingefügt

### Verbesserungen
- **Statistik-Icon optimiert**
  - Von 188x188 auf 64x64 Pixel skaliert (konsistent mit anderen Icons)
  - Transparenter Hintergrund für bessere Integration in die Toolbar

---

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
