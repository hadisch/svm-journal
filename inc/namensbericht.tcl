# =============================================================================
# Namensbericht - Prüfbericht über fehlerhafte oder verdächtige Personennamen
# =============================================================================
# Der Bericht ändert keine Daten, er listet nur auf:
#   1. Journal-Einträge, deren Name vermutlich falsch erfasst wurde
#      (vertauschte Vor-/Nachnamen oder Tippfehler gegenüber Mitgliedern,
#      Anwärtern und Gästen - gleiche Logik wie im Dialog "Neuer Eintrag")
#   2. Doppelte Personen in Mitgliederliste, Gästeliste und Warteliste
#   3. Sehr ähnliche Namen in den Stammdaten (mögliche Tippfehler oder
#      zwei Einträge derselben Person)
#   4. Namen mit überflüssigen Leerzeichen in Mitglieder- und Warteliste
# Ob tatsächlich ein Fehler vorliegt, entscheidet der Nutzer.
# =============================================================================

namespace eval ::namensbericht {}

# =============================================================================
# Prozedur: sammle_stammdaten
# Liest alle bekannten Personen aus Mitgliederliste, Warteliste und Gästeliste
# Rückgabe: Liste von Listen {nachname vorname kategorie} (Namen wie gespeichert)
# =============================================================================
proc ::namensbericht::sammle_stammdaten {} {
    set personen [list]

    # Mitglieder (Rohdaten aus mitglieder.json, nicht bereinigt)
    foreach mitglied [::statistik::lade_mitglieder] {
        lappend personen [list [dict get $mitglied nachname] [dict get $mitglied vorname] "Mitglied"]
    }

    # Anwärter auf der Warteliste
    foreach paar [::warteliste::lade_namen] {
        lassign $paar nn vn
        lappend personen [list $nn $vn "Anwärter"]
    }

    # Bekannte Gäste
    foreach gast [::gaeste::lade_gaeste] {
        lappend personen [list [dict get $gast nachname] [dict get $gast vorname] "Gast"]
    }

    return $personen
}

# =============================================================================
# Prozedur: sammle_journal_namen
# Fasst alle Journal-Einträge (alle Jahresdateien) nach Person zusammen
# Rückgabe: Dict Schlüssel -> Dict mit nachname, vorname, anzahl, daten
# =============================================================================
proc ::namensbericht::sammle_journal_namen {} {
    set namen [dict create]

    # Nur Jahresdateien (z.B. 2026.json) enthalten Journal-Einträge
    foreach datei [lsort [glob -nocomplain -directory [::pfad::get_daten_directory] *.json]] {
        if {![regexp {^\d{4}\.json$} [file tail $datei]]} {
            continue
        }
        foreach eintrag [::neuer_eintrag::lade_eintraege_aus_datei $datei] {
            set nn [dict get $eintrag nachname]
            set vn [dict get $eintrag vorname]
            set key [::namen::schluessel $nn $vn]

            # Erste Schreibweise der Person merken, danach nur zählen
            if {![dict exists $namen $key]} {
                dict set namen $key [dict create nachname [::namen::normalisiere $nn] \
                    vorname [::namen::normalisiere $vn] anzahl 0 daten [list]]
            }
            dict with namen $key {
                incr anzahl
                lappend daten [dict get $eintrag datum]
            }
        }
    }

    return $namen
}

# =============================================================================
# Prozedur: erlaubte_distanz
# Erlaubte Tippfehler-Distanz für einen einzelnen Namensbestandteil
# Parameter:
#   a, b - die beiden verglichenen Namensteile
# Rückgabe: 1 bei kurzen Namen, 2 ab 8 Zeichen (bezogen auf den längeren Namen)
# =============================================================================
proc ::namensbericht::erlaubte_distanz {a b} {
    return [expr {max([string length $a], [string length $b]) >= 8 ? 2 : 1}]
}

# =============================================================================
# Prozedur: finde_aehnliche_paare
# Sucht in den Stammdaten Paare sehr ähnlicher Namen. Geprüft wird:
#   - gleicher Vorname, ähnlicher Nachname (oder umgekehrt)
#   - vertauschte Vor-/Nachnamen
# Gleiche Namen (identischer Schlüssel) gelten als Duplikat, nicht als ähnlich.
# Parameter:
#   personen - Liste von {nachname vorname kategorie}
# Rückgabe: Liste von Listen {person_a person_b art}
# =============================================================================
proc ::namensbericht::finde_aehnliche_paare {personen} {
    # Jede Person nur einmal betrachten: Steht jemand z.B. als Mitglied und als
    # Gast in den Listen, wird er zu einer Person "(Mitglied, Gast)" zusammengefasst
    set eindeutig [dict create]
    foreach p $personen {
        lassign $p nn vn kat
        set key [::namen::schluessel $nn $vn]
        if {![dict exists $eindeutig $key]} {
            # Erste Schreibweise übernehmen
            dict set eindeutig $key [list [::namen::normalisiere $nn] [::namen::normalisiere $vn] [list $kat]]
        } elseif {$kat ni [lindex [dict get $eindeutig $key] 2]} {
            # Weitere Kategorie derselben Person ergänzen
            set eintrag [dict get $eindeutig $key]
            lset eintrag 2 end+1 $kat
            dict set eindeutig $key $eintrag
        }
    }
    # Kategorien als Text zusammenfügen ("Mitglied, Gast")
    set liste [list]
    foreach eintrag [dict values $eindeutig] {
        lassign $eintrag nn vn kats
        lappend liste [list $nn $vn [join $kats ", "]]
    }

    # Gruppen nach Vorname und nach Nachname bilden, damit nur Personen mit
    # einem gemeinsamen Namensteil verglichen werden müssen (schnell)
    set nach_vorname [dict create]
    set nach_nachname [dict create]
    set nach_schluessel [dict create]
    set index 0
    foreach p $liste {
        lassign $p nn vn kat
        dict lappend nach_vorname [string tolower $vn] $index
        dict lappend nach_nachname [string tolower $nn] $index
        dict lappend nach_schluessel [::namen::schluessel $nn $vn] $index
        incr index
    }

    set paare [list]
    set gesehen [dict create]

    # Hilfsfunktion: Paar einmalig aufnehmen (Reihenfolge der Indizes egal)
    set aufnehmen {
        set paar_id [expr {$i < $j ? "$i,$j" : "$j,$i"}]
        if {![dict exists $gesehen $paar_id]} {
            dict set gesehen $paar_id 1
            lappend paare [list [lindex $liste $i] [lindex $liste $j] $art]
        }
    }

    # Gleicher Vorname → Nachnamen vergleichen, gleicher Nachname → Vornamen vergleichen
    foreach {gruppen teil} [list $nach_vorname 0 $nach_nachname 1] {
        dict for {gemeinsam indizes} $gruppen {
            set n [llength $indizes]
            for {set a 0} {$a < $n} {incr a} {
                for {set b [expr {$a + 1}]} {$b < $n} {incr b} {
                    set i [lindex $indizes $a]
                    set j [lindex $indizes $b]
                    # Unterschiedlicher Namensteil (teil 0 = Nachname, 1 = Vorname)
                    set x [string tolower [lindex $liste $i $teil]]
                    set y [string tolower [lindex $liste $j $teil]]
                    # Identische Namen sind Duplikate und werden separat gemeldet
                    if {$x eq $y} {
                        continue
                    }
                    set max [erlaubte_distanz $x $y]
                    if {[::namen::levenshtein_max $x $y $max] <= $max} {
                        set art "ähnlich"
                        eval $aufnehmen
                    }
                }
            }
        }
    }

    # Vertauschte Namen: Schlüssel "vorname|nachname" existiert als andere Person
    set index 0
    foreach p $liste {
        lassign $p nn vn kat
        set getauscht [::namen::schluessel $vn $nn]
        if {$getauscht ne [::namen::schluessel $nn $vn] && [dict exists $nach_schluessel $getauscht]} {
            foreach j [dict get $nach_schluessel $getauscht] {
                set i $index
                set art "vertauscht"
                eval $aufnehmen
            }
        }
        incr index
    }

    # Alphabetisch nach der ersten Person sortieren
    return [lsort -dictionary -index {0 0} $paare]
}

# =============================================================================
# Prozedur: erstelle_bericht
# Ermittelt alle Befunde (ohne Ausgabe, daher auch ohne Oberfläche testbar)
# Rückgabe: Dict mit den Listen journal, doppelt, aehnlich, leerzeichen
# =============================================================================
proc ::namensbericht::erstelle_bericht {} {
    set stammdaten [sammle_stammdaten]

    # 1. Journal-Namen, zu denen es einen Vorschlag gibt
    set journal [list]
    dict for {key info} [sammle_journal_namen] {
        set vorschlag [::namen::finde_vorschlag [dict get $info nachname] [dict get $info vorname] $stammdaten]
        if {$vorschlag ne ""} {
            lappend journal [dict merge $info [dict create vorschlag $vorschlag]]
        }
    }
    # Alphabetisch nach Nachname, Vorname sortieren
    set journal [lsort -command {apply {{a b} {
        string compare -nocase "[dict get $a nachname]|[dict get $a vorname]" "[dict get $b nachname]|[dict get $b vorname]"
    }}} $journal]

    # 2. Doppelte Personen je Kategorie (gleicher Schlüssel mehrfach)
    set zaehler [dict create]
    foreach p $stammdaten {
        lassign $p nn vn kat
        set k [list $kat [::namen::schluessel $nn $vn]]
        if {![dict exists $zaehler $k]} {
            dict set zaehler $k [list [::namen::anzeige $nn $vn] 0]
        }
        dict set zaehler $k [list [lindex [dict get $zaehler $k] 0] [expr {[lindex [dict get $zaehler $k] 1] + 1}]]
    }
    set doppelt [list]
    dict for {k wert} $zaehler {
        lassign $wert name anzahl
        if {$anzahl > 1} {
            lappend doppelt [list [lindex $k 0] $name $anzahl]
        }
    }

    # 3. Ähnliche Namen in den Stammdaten
    set aehnlich [finde_aehnliche_paare $stammdaten]

    # 4. Überflüssige Leerzeichen in den Rohdaten der Stammdaten
    set leerzeichen [list]
    foreach p $stammdaten {
        lassign $p nn vn kat
        if {$nn ne [::namen::normalisiere $nn] || $vn ne [::namen::normalisiere $vn]} {
            lappend leerzeichen [list $kat "„$nn“, „$vn“"]
        }
    }

    return [dict create journal $journal doppelt $doppelt aehnlich $aehnlich leerzeichen $leerzeichen]
}

# =============================================================================
# Prozedur: schreibe
# Schreibt eine Zeile in das Ausgabe-Textfeld, optional mit Formatierung
# Parameter:
#   text_widget - Ziel-Textfeld
#   zeile       - Text der Zeile
#   tag         - optionaler Formatierungs-Tag (ueberschrift, hinweis, ok)
# =============================================================================
proc ::namensbericht::schreibe {text_widget zeile {tag ""}} {
    $text_widget insert end "$zeile\n" $tag
}

# =============================================================================
# Prozedur: personen_text
# Formatiert eine Person {nachname vorname kategorie} für die Ausgabe
# =============================================================================
proc ::namensbericht::personen_text {person} {
    lassign $person nn vn kat
    return "$nn, $vn ($kat)"
}

# =============================================================================
# Prozedur: starte
# Erstellt den Bericht und zeigt ihn im Textfeld des Fensters "Daten überprüfen"
# Parameter:
#   text_widget - Ausgabe-Textfeld
# =============================================================================
proc ::namensbericht::starte {text_widget} {
    # Formatierungen für Überschriften, Hinweise und "keine Befunde"
    $text_widget tag configure ueberschrift -font {Courier 10 bold} -foreground "#2F5F22"
    $text_widget tag configure hinweis -foreground "#666666"
    $text_widget tag configure ok -foreground "#2E7D32"

    # Ausgabe leeren und Fortschritt anzeigen (Berechnung kann einige Sekunden dauern)
    $text_widget delete 1.0 end
    schreibe $text_widget "Namensbericht wird erstellt, bitte warten..."
    . configure -cursor watch
    update

    # Befunde ermitteln - Fehler beim Lesen der Dateien abfangen
    set rc [catch {erstelle_bericht} bericht]
    . configure -cursor ""
    $text_widget delete 1.0 end
    if {$rc} {
        schreibe $text_widget "FEHLER beim Erstellen des Berichts: $bericht"
        return
    }

    # Kopf
    schreibe $text_widget "============================================="
    schreibe $text_widget "Namensbericht für svm-journal"
    schreibe $text_widget "============================================="
    schreibe $text_widget "Erstellt am: [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]"
    schreibe $text_widget "Der Bericht ändert keine Daten. Bitte jeden Befund prüfen - zwei" hinweis
    schreibe $text_widget "verschiedene Personen können sehr ähnlich heißen." hinweis
    schreibe $text_widget ""

    # --- Abschnitt 1: Journal ---
    set journal [dict get $bericht journal]
    schreibe $text_widget "1. Journal: vermutlich falsch erfasste Namen ([llength $journal])" ueberschrift
    if {[llength $journal] == 0} {
        schreibe $text_widget "   Keine Auffälligkeiten." ok
    }
    foreach befund $journal {
        set v [dict get $befund vorschlag]
        set art [expr {[dict get $v art] eq "vertauscht" ? "vertauscht" : "Tippfehler?"}]
        set anzahl [dict get $befund anzahl]
        # Höchstens die ersten fünf Daten anzeigen, damit die Zeile lesbar bleibt
        set daten [lrange [dict get $befund daten] 0 4]
        set mehr [expr {$anzahl > 5 ? ", …" : ""}]
        schreibe $text_widget "   [dict get $befund nachname], [dict get $befund vorname]  →  [dict get $v nachname], [dict get $v vorname] ([dict get $v kategorie], $art)"
        schreibe $text_widget "      $anzahl Eintr[expr {$anzahl == 1 ? "ag" : "äge"}]: [join $daten ", "]$mehr" hinweis
    }
    if {[llength $journal] > 0} {
        schreibe $text_widget "   Korrektur: Im Hauptfenster suchen (Strg+S) und den Eintrag bearbeiten." hinweis
    }
    schreibe $text_widget ""

    # --- Abschnitt 2: Doppelte Personen ---
    set doppelt [dict get $bericht doppelt]
    schreibe $text_widget "2. Doppelt erfasste Personen ([llength $doppelt])" ueberschrift
    if {[llength $doppelt] == 0} {
        schreibe $text_widget "   Keine Auffälligkeiten." ok
    }
    foreach befund $doppelt {
        lassign $befund kat name anzahl
        schreibe $text_widget "   $name – ${anzahl}× als $kat"
    }
    if {[llength $doppelt] > 0} {
        schreibe $text_widget "   Korrektur: Den überzähligen Datensatz in der jeweiligen Liste löschen." hinweis
    }
    schreibe $text_widget ""

    # --- Abschnitt 3: Ähnliche Namen ---
    set aehnlich [dict get $bericht aehnlich]
    schreibe $text_widget "3. Sehr ähnliche Namen in Mitglieder-, Gäste- und Warteliste ([llength $aehnlich])" ueberschrift
    if {[llength $aehnlich] == 0} {
        schreibe $text_widget "   Keine Auffälligkeiten." ok
    }
    foreach befund $aehnlich {
        lassign $befund a b art
        schreibe $text_widget "   [personen_text $a]  ↔  [personen_text $b]   ($art)"
    }
    if {[llength $aehnlich] > 0} {
        schreibe $text_widget "   Korrektur: Falsche Schreibweise in der Liste bearbeiten oder Doppel löschen." hinweis
    }
    schreibe $text_widget ""

    # --- Abschnitt 4: Leerzeichen ---
    set leerzeichen [dict get $bericht leerzeichen]
    schreibe $text_widget "4. Namen mit überflüssigen Leerzeichen ([llength $leerzeichen])" ueberschrift
    if {[llength $leerzeichen] == 0} {
        schreibe $text_widget "   Keine Auffälligkeiten." ok
    }
    foreach befund $leerzeichen {
        lassign $befund kat name
        schreibe $text_widget "   $name ($kat)"
    }
    if {[llength $leerzeichen] > 0} {
        schreibe $text_widget "   Korrektur: Datensatz in der Liste öffnen und speichern - die Leerzeichen werden dabei entfernt." hinweis
    }
    schreibe $text_widget ""

    # Zusammenfassung
    set summe [expr {[llength $journal] + [llength $doppelt] + [llength $aehnlich] + [llength $leerzeichen]}]
    if {$summe == 0} {
        schreibe $text_widget "Alle Namen sind unauffällig." ok
    } else {
        schreibe $text_widget "Befunde insgesamt: $summe" ueberschrift
    }
    $text_widget see 1.0
}
