# =============================================================================
# Namen - Zentrale Bereinigung und Abgleich von Personennamen
# =============================================================================
# Alle Stellen, die Nachname/Vorname speichern oder vergleichen, nutzen diese
# Prozeduren. So werden Namen überall gleich behandelt:
#   - normalisiere      : Leerzeichen am Rand entfernen, Mehrfach-Leerzeichen
#                         zusammenfassen (Schreibweise bleibt erhalten)
#   - schluessel        : Vergleichsschlüssel (normalisiert, kleingeschrieben)
#   - anzeige           : Anzeigename "Nachname, Vorname"
#   - finde_vorschlag   : erkennt vertauschte Vor-/Nachnamen und Tippfehler
#                         gegenüber bekannten Personen
# =============================================================================

namespace eval ::namen {
    # Zwischenspeicher "nachname\0vorname" -> Vergleichsschlüssel (siehe finde_vorschlag)
    variable schluessel_cache
    array set schluessel_cache {}
}

# =============================================================================
# Prozedur: normalisiere
# Bereinigt einen einzelnen Namensbestandteil
# Parameter:
#   name - Nachname oder Vorname wie eingegeben
# Rückgabe: Name ohne Rand-Leerzeichen, innere Leerzeichen-Folgen als ein Leerzeichen
# =============================================================================
proc ::namen::normalisiere {name} {
    # Alle Folgen von Leerraum (auch Tabulatoren) durch ein Leerzeichen ersetzen
    # und anschließend Leerzeichen am Anfang und Ende entfernen
    return [string trim [regsub -all {\s+} $name " "]]
}

# =============================================================================
# Prozedur: schluessel
# Erzeugt einen Vergleichsschlüssel für eine Person
# Parameter:
#   nachname, vorname - Namensbestandteile wie gespeichert
# Rückgabe: "nachname|vorname" normalisiert und in Kleinbuchstaben
# =============================================================================
proc ::namen::schluessel {nachname vorname} {
    # Groß-/Kleinschreibung spielt für den Vergleich keine Rolle
    return [string tolower "[normalisiere $nachname]|[normalisiere $vorname]"]
}

# =============================================================================
# Prozedur: anzeige
# Erzeugt den Anzeigenamen einer Person
# Parameter:
#   nachname, vorname - Namensbestandteile wie gespeichert
# Rückgabe: "Nachname, Vorname" (bereinigt, Schreibweise erhalten)
# =============================================================================
proc ::namen::anzeige {nachname vorname} {
    return "[normalisiere $nachname], [normalisiere $vorname]"
}

# =============================================================================
# Prozedur: levenshtein
# Berechnet die Editierdistanz zweier Zeichenketten (Anzahl der Einfügungen,
# Löschungen oder Ersetzungen einzelner Zeichen, um a in b zu überführen)
# Parameter:
#   a, b - zu vergleichende Zeichenketten
# Rückgabe: Distanz als Ganzzahl
# =============================================================================
proc ::namen::levenshtein {a b} {
    set la [string length $a]
    set lb [string length $b]

    # Sonderfälle: eine Zeichenkette leer → Distanz = Länge der anderen
    if {$la == 0} { return $lb }
    if {$lb == 0} { return $la }

    # Vorherige Zeile der Distanzmatrix (Abstand vom leeren Präfix)
    set vorher [list]
    for {set j 0} {$j <= $lb} {incr j} {
        lappend vorher $j
    }

    # Zeilenweise die Matrix aufbauen (nur zwei Zeilen im Speicher)
    for {set i 1} {$i <= $la} {incr i} {
        set aktuell [list $i]
        set zeichen_a [string index $a [expr {$i - 1}]]
        for {set j 1} {$j <= $lb} {incr j} {
            # Kosten 0 bei gleichem Zeichen, sonst 1 (Ersetzung)
            set kosten [expr {$zeichen_a eq [string index $b [expr {$j - 1}]] ? 0 : 1}]
            # Minimum aus Löschen, Einfügen und Ersetzen
            set loeschen  [expr {[lindex $vorher $j] + 1}]
            set einfuegen [expr {[lindex $aktuell end] + 1}]
            set ersetzen  [expr {[lindex $vorher [expr {$j - 1}]] + $kosten}]
            lappend aktuell [expr {min($loeschen, $einfuegen, $ersetzen)}]
        }
        set vorher $aktuell
    }

    # Letzter Wert der letzten Zeile ist die Distanz
    return [lindex $vorher end]
}

# =============================================================================
# Prozedur: levenshtein_max
# Wie levenshtein, rechnet aber nur so weit wie nötig: Sobald feststeht, dass
# die Distanz größer als max ist, wird abgebrochen. Dadurch ist der Vergleich
# vieler Namen deutlich schneller.
# Parameter:
#   a, b - zu vergleichende Zeichenketten
#   max  - größte interessierende Distanz
# Rückgabe: Distanz, oder max+1 wenn sie größer als max ist
# =============================================================================
proc ::namen::levenshtein_max {a b max} {
    set la [string length $a]
    set lb [string length $b]
    set zu_gross [expr {$max + 1}]

    # Längenunterschied ist eine untere Schranke der Distanz
    if {abs($la - $lb) > $max} {
        return $zu_gross
    }
    if {$la == 0 || $lb == 0} {
        return [expr {max($la, $lb)}]
    }

    # Erste Zeile der Distanzmatrix
    set vorher [list]
    for {set j 0} {$j <= $lb} {incr j} {
        lappend vorher $j
    }

    for {set i 1} {$i <= $la} {incr i} {
        set aktuell [list $i]
        set zeichen_a [string index $a [expr {$i - 1}]]
        # Kleinster Wert dieser Zeile für den vorzeitigen Abbruch
        set zeilen_min $i
        for {set j 1} {$j <= $lb} {incr j} {
            set kosten [expr {$zeichen_a eq [string index $b [expr {$j - 1}]] ? 0 : 1}]
            set wert [expr {min([lindex $vorher $j] + 1, [lindex $aktuell end] + 1, [lindex $vorher [expr {$j - 1}]] + $kosten)}]
            lappend aktuell $wert
            if {$wert < $zeilen_min} {
                set zeilen_min $wert
            }
        }
        # Jeder Wert der Zeile übersteigt max → Gesamtdistanz kann nicht mehr kleiner werden
        if {$zeilen_min > $max} {
            return $zu_gross
        }
        set vorher $aktuell
    }

    # Ergebnis, auf max+1 begrenzt
    set distanz [lindex $vorher end]
    return [expr {$distanz > $max ? $zu_gross : $distanz}]
}

# =============================================================================
# Prozedur: finde_vorschlag
# Sucht zu einer eingegebenen, unbekannten Person einen passenden bekannten
# Namen. Erkannt werden:
#   - vertauschte Vor- und Nachnamen ("Patryk Omilian" statt "Omilian Patryk")
#   - Tippfehler (höchstens 1 bzw. 2 abweichende Zeichen, je nach Namenslänge)
# Parameter:
#   nachname, vorname - Eingabe
#   bekannte          - Liste von Listen {nachname vorname kategorie}
#                       (kategorie z.B. "Mitglied", "Anwärter", "Gast")
# Rückgabe: Leerer String, wenn die Eingabe bekannt ist oder kein eindeutiger
#           Vorschlag existiert; sonst Dict mit nachname, vorname, kategorie
#           und art ("vertauscht" oder "tippfehler")
# =============================================================================
proc ::namen::finde_vorschlag {nachname vorname bekannte} {
    # Vergleichsschlüssel der Eingabe und der vertauschten Eingabe
    set eingabe   [schluessel $nachname $vorname]
    set getauscht [schluessel $vorname $nachname]

    # Unvollständige Eingabe: nichts vorschlagen
    if {[normalisiere $nachname] eq "" || [normalisiere $vorname] eq ""} {
        return ""
    }

    # Erlaubte Tippfehler-Distanz: bei kurzen Namen nur 1 Zeichen, sonst 2
    # (Schlüssel enthält den Trenner "|", daher zählt er mit zur Länge)
    set max_distanz [expr {[string length $eingabe] >= 11 ? 2 : 1}]

    # Bester Tippfehler-Kandidat (kleinste Distanz) und ob dieser eindeutig ist
    set vertauscht ""
    set bester ""
    set beste_distanz [expr {$max_distanz + 1}]
    set eindeutig 1

    # Zwischenspeicher für Vergleichsschlüssel: Die Liste der bekannten Personen
    # ist bei vielen Aufrufen dieselbe, die Bereinigung muss nur einmal laufen
    variable schluessel_cache

    foreach person $bekannte {
        lassign $person b_nachname b_vorname b_kategorie
        set cache_key "$b_nachname\x00$b_vorname"
        if {![info exists schluessel_cache($cache_key)]} {
            set schluessel_cache($cache_key) [schluessel $b_nachname $b_vorname]
        }
        set b_schluessel $schluessel_cache($cache_key)

        # Eingabe entspricht einer bekannten Person → kein Vorschlag nötig
        if {$b_schluessel eq $eingabe} {
            return ""
        }

        # Vertauschte Eingabe passt genau → Kandidat merken (hat Vorrang)
        if {$vertauscht eq "" && $b_schluessel eq $getauscht} {
            set vertauscht [dict create nachname [normalisiere $b_nachname] \
                vorname [normalisiere $b_vorname] kategorie $b_kategorie art "vertauscht"]
            continue
        }

        # Schneller Vorfilter: Längenunterschied größer als erlaubte Distanz
        if {abs([string length $b_schluessel] - [string length $eingabe]) > $max_distanz} {
            continue
        }

        # Tippfehler-Abstand berechnen (bricht ab, sobald max_distanz überschritten ist)
        set distanz [levenshtein_max $eingabe $b_schluessel $max_distanz]
        if {$distanz < $beste_distanz} {
            # Neuer bester Kandidat
            set beste_distanz $distanz
            set bester [dict create nachname [normalisiere $b_nachname] \
                vorname [normalisiere $b_vorname] kategorie $b_kategorie art "tippfehler"]
            set eindeutig 1
        } elseif {$distanz == $beste_distanz && $bester ne "" &&
                  [schluessel [dict get $bester nachname] [dict get $bester vorname]] ne $b_schluessel} {
            # Gleich guter Kandidat einer anderen Person → nicht eindeutig
            set eindeutig 0
        }
    }

    # Vertauschte Namen haben Vorrang vor Tippfehlern
    if {$vertauscht ne ""} {
        return $vertauscht
    }

    # Tippfehler nur vorschlagen, wenn genau eine Person in Frage kommt
    if {$bester ne "" && $eindeutig} {
        return $bester
    }

    return ""
}
