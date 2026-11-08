# =============================================================================
# hauptansicht.tcl - Optik der Hauptansicht (Journal-Treeview .main.tree)
# =============================================================================
# Bündelt alle Darstellungs-Einstellungen der Hauptansicht an einer Stelle:
#   - zentrale Farben und Maße im Array ::hauptansicht::stil
#   - Einrichtung der Treeview-Tags (::hauptansicht::init)
#   - zentraler Hook ::hauptansicht::ansicht_aktualisiert, der nach JEDEM
#     Neubefüllen des Treeviews aufgerufen wird (Laden, Filtern, Hinzufügen,
#     Bearbeiten, Löschen) und die Darstellung (z.B. Zebra-Streifen) neu setzt.
#
# WICHTIG: Dieses Modul ändert ausschließlich die ANZEIGE. Die Werte (-values)
# der Treeview-Zeilen bleiben unverändert, da Bearbeiten, Löschen und die Suche
# sie als Datenquelle verwenden.
# =============================================================================

namespace eval ::hauptansicht {
    # -------------------------------------------------------------------------
    # Zentrale Farben und Maße - hier anpassen
    # -------------------------------------------------------------------------
    variable stil
    array set stil {
        zebra_gerade        "#ffffff"
        zebra_ungerade      "#f3f5f3"
        kopf_hintergrund    "#e6efe2"
        kopf_text           "#2e3b2c"
        kopf_linie          "#9fbf92"
        kopf_spaltentrenner "#c9d8c1"
        kopf_padding        {6 4}
        schrift             {TkDefaultFont 11}
        zeilen_luft         5
        zeilenhoehe_min     24
        zelle_padding       {8 0}
        anzeige_ohne_wert   "–"
    }
    # zebra_gerade        - Hintergrund der 1., 3., 5. ... Zeile
    # zebra_ungerade      - Hintergrund der 2., 4., 6. ... Zeile (sehr dezentes Grün-Grau)
    # kopf_hintergrund    - Hintergrund der Kopfzeile (sehr helles Vereinsgrün)
    # kopf_text           - Schriftfarbe der Kopfzeile (dunkles Grün-Grau)
    # kopf_linie          - feine Trennlinie unter der Kopfzeile (1 px)
    # kopf_spaltentrenner - feine senkrechte Linie zwischen den Spaltenköpfen (1 px)
    # kopf_padding        - Innenabstand der Spaltenköpfe {horizontal vertikal} in px
    # schrift             - Schrift der Tabellenzeilen in allen Listen
    # zeilen_luft         - zusätzlicher Platz (px) zur Schrift-Zeilenhöhe (oben + unten)
    # zeilenhoehe_min     - Mindest-Zeilenhöhe in px (Richtwert)
    # zelle_padding       - Innenabstand jeder Zelle der Hauptansicht {horizontal vertikal}
    #                       in px; der sichtbare Abstand zwischen zwei Spalten ist
    #                       2 x horizontal (z.B. Startgeld rechtsbündig | Munition linksbündig)
    # anzeige_ohne_wert   - Anzeigetext statt "Keine" (Munition) bzw. "0,00" (Mun.Preis);
    #                       "–" = Gedankenstrich (Standard), "" = leere Zelle.
    #                       Hinweis: ttk färbt nur ganze Zeilen, ein grauer Strich
    #                       in einer einzelnen Zelle ist daher nicht möglich.

    # -------------------------------------------------------------------------
    # Spaltenbreiten der Hauptansicht - hier anpassen
    # -------------------------------------------------------------------------
    # Angegeben ist die reine INHALTSBREITE in px (Platz für den Text). Die
    # tatsächliche Spaltenbreite wird in ::hauptansicht::spalten_einrichten
    # berechnet: Inhalt + 2 x Zellen-Padding, mindestens aber so breit, dass
    # die Spaltenüberschrift vollständig lesbar ist.
    # Richtwerte aus den vorhandenen Daten (Schrift Noto Sans 11):
    #   Nachname max. 115 px, Vorname max. 125 px, KW/LW "Nein" 32 px,
    #   Kaliber 98 % <= 148 px, Munition 98 % <= 102 px (max. 427 px),
    #   Bemerkungen max. 208 px
    variable spalten_inhalt
    array set spalten_inhalt {
        datum              77
        nachname          120
        vorname           125
        kw                 32
        lw                 32
        typ                37
        kaliber           150
        startgeld          57
        mun_anzeige       200
        munpreis_anzeige   62
        status             22
        bemerkungen       160
    }

    # Spalten, die bei breiterem Fenster den zusätzlichen Platz erhalten
    # (Tk verteilt ihn gleichmäßig auf diese Spalten). Alle anderen Spalten
    # behalten ihre berechnete Breite. Lange Texte, die trotzdem nicht
    # passen, zeigt der Zellen-Tooltip vollständig an.
    variable spalten_dehnbar {kaliber mun_anzeige bemerkungen}

    # Interner Innenabstand, den Tk zusätzlich zum Zellen-Padding für den Text
    # reserviert (4 px je Seite; gemessen mit Tk 8.6 in den Themes "default"
    # und "clam"). Keine Einstellung, sondern eine Korrekturgröße für die
    # Breitenberechnung - nur ändern, falls Texte trotzdem abgeschnitten werden.
    variable tk_text_reserve 8

    # -------------------------------------------------------------------------
    # Zellen-Tooltip - hier anpassen
    # -------------------------------------------------------------------------
    # Zeigt beim Überfahren einer Zelle deren vollständigen Text, wenn er in
    # der Spalte abgeschnitten ist. Optik wie die übrigen Tooltips im Programm.
    array set stil {
        tooltip_hintergrund  "#FFFFE0"
        tooltip_text         "black"
        tooltip_verzoegerung 400
        tooltip_max_breite   600
    }
    # tooltip_hintergrund  - Hintergrundfarbe des Tooltips
    # tooltip_text         - Schriftfarbe des Tooltips
    # tooltip_verzoegerung - Wartezeit in ms, bis der Tooltip erscheint
    # tooltip_max_breite   - ab dieser Breite (px) wird der Text umgebrochen

    # Zustand des Zellen-Tooltips: zuletzt geprüfte Zelle und Timer
    variable tooltip_zelle ""
    variable tooltip_after ""

    # -------------------------------------------------------------------------
    # Tagestrennung - hier anpassen
    # -------------------------------------------------------------------------
    array set stil {
        tag_trenner_farbe  "#8fb380"
        tag_trenner_dicke  2
    }
    # tag_trenner_farbe - Farbe der Trennlinie beim Wechsel des Datums
    # tag_trenner_dicke - Dicke der Trennlinie in px (0 = Tagestrennung aus)

    # -------------------------------------------------------------------------
    # Statusleiste - hier anpassen
    # -------------------------------------------------------------------------
    array set stil {
        status_hintergrund "#E0E0E0"
        status_text        "#333333"
        status_trenner     " · "
    }
    # status_hintergrund - Hintergrund der Statusleiste im Hauptfenster
    # status_text        - Schriftfarbe der Summenanzeige
    # status_trenner     - Trennzeichen zwischen den Angaben (Mittelpunkt)

    # Pfad des Summen-Labels in der Statusleiste
    variable status_label .statusbar.summen

    # -------------------------------------------------------------------------
    # Toolbar - hier anpassen
    # -------------------------------------------------------------------------
    array set stil {
        toolbar_hintergrund "#E0E0E0"
        toolbar_trenner     "#A8A8A8"
    }
    # toolbar_hintergrund - Hintergrund der Button-Leiste im Hauptfenster
    # toolbar_trenner     - Farbe der senkrechten Trennlinie zwischen Button-Gruppen

    # -------------------------------------------------------------------------
    # Status-Spalte (M/A/G) - hier anpassen
    # -------------------------------------------------------------------------
    # Jedes Kürzel wird als kleines, farbig hinterlegtes Feld in der Zelle
    # angezeigt. Dezente Töne passend zu Zebra-Streifen und Kopfzeile.
    array set stil {
        status_M_hintergrund "#dcebd5"
        status_M_text        "#2f5f22"
        status_A_hintergrund "#dce6f2"
        status_A_text        "#2c4a6b"
        status_G_hintergrund "#f3e5c3"
        status_G_text        "#6e5212"
        status_schrift       {TkDefaultFont 9 bold}
        status_feld_breite   22
        status_feld_abstand  3
    }
    # status_X_hintergrund - Hintergrund des Kürzels X (M=Mitglied, A=Anwärter, G=Gast)
    # status_X_text        - Schriftfarbe des Kürzels X
    # status_schrift       - Schrift der Kürzel
    # status_feld_breite   - Breite des farbigen Feldes in px
    # status_feld_abstand  - Abstand des Feldes zum oberen/unteren Zeilenrand in px

    # Angelegte Status-Felder (Label-Widgets, werden wiederverwendet)
    variable status_felder {}

    # Zeilen (Item-IDs), über denen eine Trennlinie liegt, und die dafür
    # angelegten Linien-Widgets (werden wiederverwendet)
    variable trenner_items {}
    variable trenner_linien {}
    # Merker, damit das Neuzeichnen beim Scrollen nur einmal je Leerlauf läuft
    variable trenner_geplant 0

    # Eigener, vom Standard abgeleiteter Style für die Hauptansicht.
    # Erbt Schrift, Zeilenhöhe und Kopfzeile von "Treeview" bzw.
    # "Treeview.Heading" und ergänzt nur Eigenes der Hauptansicht
    # (Zellen-Innenabstand über "Journal.Treeview.Cell").
    variable style Journal.Treeview

    # Pfad des Haupt-Treeviews (eine Stelle, falls er einmal umbenannt wird)
    variable tree .main.tree
}

# =============================================================================
# Prozedur: ::hauptansicht::kopfzeile_einrichten
# Richtet den Kopfzeilen-Style ALLER Listen (Treeviews) im Programm ein:
# gedeckter Hintergrund, dunkle Schrift, feine Linie unten und feine
# Spaltentrenner. Gilt global über "Treeview.Heading", die Hauptansicht erbt
# ihn über "Journal.Treeview.Heading".
# Muss NACH der Theme-Auswahl (unter Windows "clam") und VOR dem Erzeugen der
# ersten Treeviews aufgerufen werden, da ttk-Elemente je Theme angelegt werden.
#
# Technik: Die Standard-Kopfzeile kann keine Linie nur an der Unterkante
# zeichnen. Daher wird ein kleines 3x3-Pixel-Bild als ttk-Element verwendet,
# dessen rechte Spalte (Spaltentrenner) und untere Zeile (Trennlinie) als
# Rand fest bleiben, während die Mitte auf die Kopfgröße gestreckt wird.
# =============================================================================
proc ::hauptansicht::kopfzeile_einrichten {} {
    variable stil

    # Hintergrundbild der Kopfzelle (einmalig) anlegen
    if {"::hauptansicht::kopf_bild" ni [image names]} {
        image create photo ::hauptansicht::kopf_bild -width 3 -height 3
    }
    set bild ::hauptansicht::kopf_bild
    # Ganze Fläche mit der Hintergrundfarbe füllen
    $bild put $stil(kopf_hintergrund)    -to 0 0 3 3
    # Rechte Pixelspalte (ohne unterste Zeile) als Spaltentrenner
    $bild put $stil(kopf_spaltentrenner) -to 2 0 3 2
    # Unterste Pixelzeile als Trennlinie zum Tabelleninhalt
    $bild put $stil(kopf_linie)          -to 0 2 3 3

    # Bild-Element im aktuellen Theme anlegen (nur falls noch nicht vorhanden)
    # -border {links oben rechts unten}: rechts und unten 1 px nicht strecken
    if {"Journal.Heading.flaeche" ni [ttk::style element names]} {
        ttk::style element create Journal.Heading.flaeche image $bild \
            -border {0 0 1 1} -sticky nsew
    }

    # Layout der Kopfzelle: Standard-Layout, nur Hintergrund und 3D-Rahmen
    # (Treeheading.cell/.border) durch das Bild-Element ersetzt
    ttk::style layout Treeview.Heading {
        Journal.Heading.flaeche -sticky nswe -children {
            Treeheading.padding -sticky nswe -children {
                Treeheading.image -side right -sticky {}
                Treeheading.text -sticky we
            }
        }
    }

    # Schriftfarbe und Innenabstand der Kopfzeile
    ttk::style configure Treeview.Heading \
        -foreground $stil(kopf_text) \
        -padding    $stil(kopf_padding)
}

# =============================================================================
# Prozedur: ::hauptansicht::zeilen_einrichten
# Setzt Schrift und Zeilenhöhe ALLER Listen (globaler Style "Treeview") sowie
# den Zellen-Innenabstand der Hauptansicht. Die Zeilenhöhe wird aus den
# Schriftmetriken berechnet (Zeilenabstand der Schrift + Luft), damit Texte
# auch bei anderen Schriften oder Bildschirmskalierungen nicht abgeschnitten
# werden. Ergebnis ist mindestens stil(zeilenhoehe_min).
# Einmal beim Programmstart aufrufen; die einzelnen Fenster setzen diese
# Werte nicht mehr selbst.
# =============================================================================
proc ::hauptansicht::zeilen_einrichten {} {
    variable stil
    variable style

    # Tatsächliche Pixelhöhe einer Textzeile (Ober- + Unterlänge) der Schrift
    set zeilenabstand [font metrics $stil(schrift) -linespace]

    # Gewünschte Höhe: Textzeile plus Luft, aber nie unter dem Mindestwert
    set hoehe [expr {max($stil(zeilenhoehe_min), $zeilenabstand + $stil(zeilen_luft))}]

    # Schrift und Zeilenhöhe global für alle Listen setzen (Hauptansicht erbt)
    ttk::style configure Treeview -font $stil(schrift) -rowheight $hoehe

    # Zellen-Innenabstand nur in der Hauptansicht: sorgt für sichtbaren Abstand
    # zwischen rechtsbündigen (Startgeld) und linksbündigen (Munition) Spalten.
    # Tk 8.6 kennt kein Padding je Spalte, daher gilt der Wert für alle Zellen.
    ttk::style configure $style.Cell -padding $stil(zelle_padding)
}

# =============================================================================
# Prozedur: ::hauptansicht::spalten_einrichten
# Setzt die Breiten der sichtbaren Spalten der Hauptansicht aus
# spalten_inhalt. Muss nach dem Setzen der Spaltenüberschriften aufgerufen
# werden, da deren Textbreite als Untergrenze dient.
# =============================================================================
proc ::hauptansicht::spalten_einrichten {} {
    variable stil
    variable spalten_inhalt
    variable spalten_dehnbar
    variable tk_text_reserve
    variable tree

    # Horizontaler Innenabstand der Zellen und der Spaltenköpfe
    set zelle_pad [lindex $stil(zelle_padding) 0]
    set kopf_pad  [lindex $stil(kopf_padding) 0]

    # Schrift der Kopfzeile ermitteln (Fallback: Standard-Überschriftenschrift)
    set kopf_schrift [ttk::style lookup Treeview.Heading -font]
    if {$kopf_schrift eq ""} {
        set kopf_schrift TkHeadingFont
    }

    foreach spalte [array names spalten_inhalt] {
        # Breite aus Inhalt plus Padding links und rechts plus Tk-interner Reserve
        set breite [expr {$spalten_inhalt($spalte) + 2 * $zelle_pad + $tk_text_reserve}]

        # Mindestbreite: Überschrift + Kopf-Padding + 2 px (Spaltentrenner)
        set ueberschrift [$tree heading $spalte -text]
        set min_breite [expr {[font measure $kopf_schrift $ueberschrift] + 2 * $kopf_pad + 2}]

        # Nur die in spalten_dehnbar genannten Spalten erhalten zusätzlichen Platz
        set dehnbar [expr {$spalte in $spalten_dehnbar}]

        # Größeren der beiden Werte als Spaltenbreite setzen; -minwidth
        # verhindert, dass Tk feste Spalten beim Verkleinern zusammendrückt
        set endbreite [expr {max($breite, $min_breite)}]
        $tree column $spalte -width $endbreite -stretch $dehnbar
        if {!$dehnbar} {
            $tree column $spalte -minwidth $endbreite
        }
    }
}

# =============================================================================
# Zellen-Tooltip: vollständiger Text abgeschnittener Zellen
# =============================================================================
# Prozedur: ::hauptansicht::tooltip_einrichten
# Bindet die Maus-Ereignisse an den Haupt-Treeview. Einmal nach dem Erzeugen
# von .main.tree aufrufen.
# =============================================================================
proc ::hauptansicht::tooltip_einrichten {} {
    variable tree

    # Mausbewegung: prüfen, ob unter dem Zeiger eine abgeschnittene Zelle liegt
    bind $tree <Motion> {+::hauptansicht::tooltip_pruefen %W %x %y}
    # Verlassen, Klicken und Scrollen blenden den Tooltip sofort aus
    bind $tree <Leave>       {+::hauptansicht::tooltip_verbergen}
    bind $tree <ButtonPress> {+::hauptansicht::tooltip_verbergen}
    bind $tree <MouseWheel>  {+::hauptansicht::tooltip_verbergen}
    bind $tree <KeyPress>    {+::hauptansicht::tooltip_verbergen}
}

# =============================================================================
# Prozedur: ::hauptansicht::tooltip_pruefen
# Ermittelt die Zelle unter dem Mauszeiger. Ist deren Text breiter als die
# Spalte, wird der Tooltip mit Verzögerung angezeigt.
# Parameter:
#   w    - Treeview-Widget
#   x, y - Mausposition relativ zum Widget
# =============================================================================
proc ::hauptansicht::tooltip_pruefen {w x y} {
    variable stil
    variable tooltip_zelle
    variable tooltip_after
    variable tk_text_reserve

    # Nur Datenzellen berücksichtigen (nicht Kopfzeile oder leere Fläche)
    if {[$w identify region $x $y] ne "cell"} {
        tooltip_verbergen
        return
    }

    # Zeile und Spalte unter dem Zeiger bestimmen; "#3" -> Spalten-ID
    set item   [$w identify item $x $y]
    set spalte [$w column [$w identify column $x $y] -id]

    # Gleiche Zelle wie zuvor: nichts zu tun (Tooltip steht oder Timer läuft)
    if {"$item|$spalte" eq $tooltip_zelle} {
        return
    }

    # Neue Zelle: alten Tooltip/Timer entfernen und Zelle merken
    tooltip_verbergen
    set tooltip_zelle "$item|$spalte"

    # Text der Zelle und benötigte Breite (Text + Zellen-Padding links/rechts
    # + Tk-interne Reserve)
    set text [$w set $item $spalte]
    set schrift [ttk::style lookup [$w cget -style] -font]
    if {$schrift eq ""} {
        set schrift $stil(schrift)
    }
    set benoetigt [expr {[font measure $schrift $text] \
        + 2 * [lindex $stil(zelle_padding) 0] + $tk_text_reserve}]

    # Text passt vollständig in die Spalte: kein Tooltip nötig
    if {$benoetigt <= [$w column $spalte -width]} {
        return
    }

    # Tooltip nach kurzer Verzögerung anzeigen
    set tooltip_after [after $stil(tooltip_verzoegerung) \
        [list ::hauptansicht::tooltip_zeigen $w $text $schrift]]
}

# =============================================================================
# Prozedur: ::hauptansicht::tooltip_zeigen
# Zeigt den Tooltip mit dem vollständigen Zellentext neben dem Mauszeiger.
# Parameter:
#   w       - Treeview-Widget (für Existenzprüfung)
#   text    - vollständiger Zellentext
#   schrift - Schrift des Tooltips (gleich der Tabellenschrift)
# =============================================================================
proc ::hauptansicht::tooltip_zeigen {w text schrift} {
    variable stil
    variable tooltip_after

    # Timer ist abgelaufen
    set tooltip_after ""

    # Treeview könnte inzwischen zerstört sein
    if {![winfo exists $w]} {
        return
    }

    # Eigenes, randloses Fenster für den Tooltip
    set tip .zellen_tooltip
    catch {destroy $tip}
    toplevel $tip
    wm overrideredirect $tip 1

    # Inhalt: Text mit Rahmen, Optik wie die übrigen Tooltips
    label $tip.text -text $text -font $schrift \
        -background $stil(tooltip_hintergrund) \
        -foreground $stil(tooltip_text) \
        -relief solid -borderwidth 1 -padx 5 -pady 2 \
        -justify left -wraplength $stil(tooltip_max_breite)
    pack $tip.text

    # Position: rechts unterhalb des Mauszeigers
    lassign [winfo pointerxy $w] px py
    set tx [expr {$px + 12}]
    set ty [expr {$py + 18}]

    # Am rechten/unteren Bildschirmrand nach innen verschieben
    update idletasks
    set breite [winfo reqwidth $tip]
    set hoehe  [winfo reqheight $tip]
    if {$tx + $breite > [winfo screenwidth $w]} {
        set tx [expr {[winfo screenwidth $w] - $breite - 4}]
    }
    if {$ty + $hoehe > [winfo screenheight $w]} {
        set ty [expr {$py - $hoehe - 8}]
    }
    wm geometry $tip "+$tx+$ty"
    raise $tip
}

# =============================================================================
# Prozedur: ::hauptansicht::tooltip_verbergen
# Bricht einen wartenden Tooltip ab und schließt einen sichtbaren.
# =============================================================================
proc ::hauptansicht::tooltip_verbergen {} {
    variable tooltip_zelle
    variable tooltip_after

    # Wartenden Timer abbrechen
    if {$tooltip_after ne ""} {
        after cancel $tooltip_after
        set tooltip_after ""
    }

    # Sichtbaren Tooltip schließen und Zelle vergessen
    catch {destroy .zellen_tooltip}
    set tooltip_zelle ""
}

# =============================================================================
# Prozedur: ::hauptansicht::init
# Richtet die Tags des Haupt-Treeviews ein. Muss einmal nach dem Erzeugen von
# .main.tree aufgerufen werden.
# =============================================================================
proc ::hauptansicht::init {} {
    variable stil
    variable tree

    # Zebra-Tags vorab einrichten (zebra setzt sie bei jedem Aufruf erneut)
    $tree tag configure zebra_gerade   -background $stil(zebra_gerade)
    $tree tag configure zebra_ungerade -background $stil(zebra_ungerade)
}

# =============================================================================
# Prozedur: ::hauptansicht::zebra
# Zebra-Streifen für eine BELIEBIGE Liste (Treeview) im Programm.
# Vergibt die Zebra-Tags anhand der AKTUELLEN Reihenfolge der Zeilen. Dadurch
# stimmen die Streifen nach Sortieren, Filtern, Hinzufügen und Löschen.
# Andere Tags einer Zeile (z.B. Textfarben) bleiben erhalten (tag add/remove).
# Aufruf: nach jedem Neubefüllen der Liste, z.B.
#   ::hauptansicht::zebra .mitglieder.main.tree
# Parameter:
#   tree - Pfad des Treeview-Widgets
# =============================================================================
proc ::hauptansicht::zebra {tree} {
    variable stil

    # Liste existiert evtl. nicht (Fenster geschlossen) - dann nichts tun
    if {![winfo exists $tree]} {
        return
    }

    # Zebra-Tags (je Widget) mit den zentralen Farben einrichten. Nur der
    # Hintergrund wird gesetzt; die Auswahlfarbe des Themes (Zustand
    # "selected") hat in Tk >= 8.6.10 Vorrang, die markierte Zeile bleibt
    # also klar erkennbar.
    $tree tag configure zebra_gerade   -background $stil(zebra_gerade)
    $tree tag configure zebra_ungerade -background $stil(zebra_ungerade)

    # Aktuelle Zeilen in Anzeigereihenfolge holen
    set items [$tree children {}]

    # Alte Zebra-Tags von allen Zeilen entfernen (z.B. nach Umsortierung)
    $tree tag remove zebra_gerade   $items
    $tree tag remove zebra_ungerade $items

    # Zeilen abwechselnd taggen; Zählung beginnt bei 0 = "gerade" (weiß)
    set nr 0
    foreach item $items {
        # Index gerade -> erste Farbe, ungerade -> zweite Farbe
        if {$nr % 2 == 0} {
            $tree tag add zebra_gerade [list $item]
        } else {
            $tree tag add zebra_ungerade [list $item]
        }
        incr nr
    }
}

# =============================================================================
# Prozedur: ::hauptansicht::anzeigewerte_setzen
# Befüllt die sichtbaren Anzeige-Spalten "mun_anzeige" und "munpreis_anzeige"
# aus den versteckten Originalspalten "munition" und "munpreis".
# "Keine" bzw. ein Preis von 0 werden durch stil(anzeige_ohne_wert) ersetzt.
# Die Originalwerte bleiben unverändert (Datenquelle für Bearbeiten/Löschen).
# =============================================================================
proc ::hauptansicht::anzeigewerte_setzen {} {
    variable stil
    variable tree

    foreach item [$tree children {}] {
        # Gespeicherte Originalwerte der Zeile lesen
        set munition [string trim [$tree set $item munition]]
        set munpreis [string trim [$tree set $item munpreis]]

        # Munition: "Keine" (beliebige Schreibweise) oder leer -> Platzhalter
        if {$munition eq "" || [string equal -nocase $munition "Keine"]} {
            set munition $stil(anzeige_ohne_wert)
        }

        # Mun.Preis: deutscher Dezimalwert; 0 (z.B. "0,00", "0") -> Platzhalter
        set zahl [string map {, .} $munpreis]
        if {$munpreis eq "" || ([string is double -strict $zahl] && $zahl == 0)} {
            set munpreis $stil(anzeige_ohne_wert)
        }

        # Anzeige-Spalten setzen
        $tree set $item mun_anzeige      $munition
        $tree set $item munpreis_anzeige $munpreis
    }
}

# =============================================================================
# Tagestrennung: Linie zwischen zwei Zeilen mit unterschiedlichem Datum
# =============================================================================
# ttk::treeview kann keine Rahmenlinien an einzelnen Zeilen zeichnen. Daher
# werden schmale Frame-Widgets genau auf die Grenze zwischen den Zeilen gelegt
# (place). Die Zeilen und ihre Werte bleiben unverändert. Die Linien werden
# nach jedem Befüllen, beim Scrollen und bei Größenänderung neu positioniert.
# =============================================================================

# -----------------------------------------------------------------------------
# Hilfsprozedur: Datum "TT.MM.JJJJ" in sortierbaren Schlüssel "JJJJMMTT"
# -----------------------------------------------------------------------------
proc ::hauptansicht::datum_schluessel {datum} {
    # Unbekanntes Format: unverändert zurückgeben (wird dann als Text verglichen)
    if {[regexp {^(\d{2})\.(\d{2})\.(\d{4})$} $datum -> t m j]} {
        return "$j$m$t"
    }
    return $datum
}

# =============================================================================
# Prozedur: ::hauptansicht::trenner_berechnen
# Ermittelt die Zeilen, an denen ein neuer Tag beginnt. Nur wenn die Liste
# nach Datum geordnet ist (aufsteigend ODER absteigend); bei jeder anderen
# Reihenfolge (z.B. künftige Sortierung nach Name) gibt es keine Trennlinien,
# da sich das Datum sonst fast in jeder Zeile ändern würde.
# =============================================================================
proc ::hauptansicht::trenner_berechnen {} {
    variable tree
    variable trenner_items

    set trenner_items {}
    set items [$tree children {}]

    # Datumsschlüssel aller Zeilen in Anzeigereihenfolge
    set schluessel [lmap item $items {datum_schluessel [$tree set $item datum]}]

    # Prüfen, ob die Zeilen nach Datum geordnet sind
    set auf 1
    set ab 1
    set vorher ""
    foreach s $schluessel {
        if {$vorher ne ""} {
            if {$s < $vorher} { set auf 0 }
            if {$s > $vorher} { set ab 0 }
        }
        set vorher $s
    }
    if {!$auf && !$ab} {
        return
    }

    # Jede Zeile, deren Datum sich von der vorherigen unterscheidet, merken
    set vorher ""
    foreach item $items s $schluessel {
        if {$vorher ne "" && $s ne $vorher} {
            lappend trenner_items $item
        }
        set vorher $s
    }
}

# =============================================================================
# Prozedur: ::hauptansicht::trenner_planen
# Plant ein Neuzeichnen der Linien im nächsten Leerlauf (bündelt viele
# Scroll-Ereignisse zu einem einzigen Neuzeichnen).
# =============================================================================
proc ::hauptansicht::trenner_planen {} {
    variable trenner_geplant
    if {!$trenner_geplant} {
        set trenner_geplant 1
        after idle ::hauptansicht::trenner_zeichnen
    }
}

# =============================================================================
# Prozedur: ::hauptansicht::trenner_zeichnen
# Legt für jede SICHTBARE Tagesgrenze eine Linie über die Zeilengrenze.
# =============================================================================
proc ::hauptansicht::trenner_zeichnen {} {
    variable stil
    variable tree
    variable trenner_items
    variable trenner_linien
    variable trenner_geplant

    set trenner_geplant 0
    if {![winfo exists $tree]} {
        return
    }

    # Oberkante des Datenbereichs = Oberkante der ersten sichtbaren Zeile
    # (darüber liegt die Kopfzeile, dort wird keine Linie gezeichnet)
    set items [$tree children {}]
    set oben 0
    if {[llength $items] > 0} {
        set erster [expr {int([lindex [$tree yview] 0] * [llength $items])}]
        foreach item [lrange $items $erster [expr {$erster + 1}]] {
            set bbox [$tree bbox $item]
            if {$bbox ne ""} {
                set oben [lindex $bbox 1]
                break
            }
        }
    }

    # Positionen aller sichtbaren Tagesgrenzen sammeln
    set dicke $stil(tag_trenner_dicke)
    set positionen {}
    if {$dicke > 0} {
        foreach item $trenner_items {
            # bbox ist leer, wenn die Zeile nicht im sichtbaren Bereich liegt
            set bbox [$tree bbox $item]
            if {$bbox eq ""} {
                continue
            }
            set y [lindex $bbox 1]
            # Grenze direkt unter der Kopfzeile auslassen (dort ist schon eine Linie)
            if {$y <= $oben} {
                continue
            }
            # Linie mittig auf die Zeilengrenze legen
            lappend positionen [expr {$y - $dicke / 2}]
        }
    }

    # Fehlende Linien-Widgets anlegen (vorhandene werden wiederverwendet)
    while {[llength $trenner_linien] < [llength $positionen]} {
        set linie $tree.trenner[llength $trenner_linien]
        frame $linie -height $dicke -background $stil(tag_trenner_farbe) \
            -borderwidth 0 -highlightthickness 0
        lappend trenner_linien $linie
    }

    # Linien über die volle Breite platzieren, überzählige ausblenden
    set nr 0
    foreach linie $trenner_linien {
        if {$nr < [llength $positionen]} {
            place $linie -x 0 -y [lindex $positionen $nr] -relwidth 1 -height $dicke
        } else {
            place forget $linie
        }
        incr nr
    }

    # Die farbigen Status-Felder hängen an denselben Ereignissen (Scrollen,
    # Größenänderung, Neubefüllen) und werden daher gleich mit gezeichnet
    status_zeichnen
}

# =============================================================================
# Status-Spalte: farbig hinterlegte Kürzel M/A/G
# =============================================================================
# ttk::treeview kann einzelne Zellen nicht einfärben (nur ganze Zeilen). Daher
# wird - wie bei den Tageslinien - für jede SICHTBARE Zeile ein kleines Label
# über die Zelle der Spalte "status" gelegt. Mausaktionen auf dem Label werden
# an die Tabelle weitergereicht (Auswahl, Doppelklick, Kontextmenü, Scrollrad).
# =============================================================================
proc ::hauptansicht::status_zeichnen {} {
    variable stil
    variable tree
    variable status_felder

    if {![winfo exists $tree]} {
        return
    }

    # Nur die sichtbaren Zeilen betrachten (aus der Scrollposition berechnet)
    set items [$tree children {}]
    set anzahl [llength $items]
    lassign [$tree yview] von bis
    set erster [expr {max(0, int($von * $anzahl) - 1)}]
    set letzter [expr {min($anzahl - 1, int(ceil($bis * $anzahl)) + 1)}]

    # Oberkante des Datenbereichs: erste sichtbare Zeile (darüber liegt die Kopfzeile)
    set oben 0
    foreach item [lrange $items $erster [expr {$erster + 2}]] {
        set bbox [$tree bbox $item]
        if {$bbox ne ""} {
            set oben [lindex $bbox 1]
            break
        }
    }

    # Zu zeichnende Felder sammeln: {item kürzel x y breite höhe}
    set felder {}
    set abstand $stil(status_feld_abstand)
    foreach item [lrange $items $erster $letzter] {
        set kuerzel [$tree set $item status]
        if {$kuerzel ni {M A G}} {
            continue
        }
        # Zellen-Rechteck; leer, wenn Zeile oder Spalte nicht sichtbar ist
        set bbox [$tree bbox $item status]
        if {$bbox eq ""} {
            continue
        }
        lassign $bbox x y b h
        # Zeilen, die teilweise unter der Kopfzeile liegen, auslassen
        if {$y < $oben} {
            continue
        }
        # Feld mittig in die Zelle setzen, nie breiter als die Zelle
        set breite [expr {min($stil(status_feld_breite), $b - 4)}]
        if {$breite < 8} {
            continue
        }
        lappend felder [list $item $kuerzel \
            [expr {$x + ($b - $breite) / 2}] [expr {$y + $abstand}] \
            $breite [expr {$h - 2 * $abstand}]]
    }

    # Fehlende Label-Widgets anlegen (vorhandene werden wiederverwendet)
    while {[llength $status_felder] < [llength $felder]} {
        set feld $tree.status[llength $status_felder]
        label $feld -font $stil(status_schrift) -borderwidth 0 -padx 0 -pady 0
        # Mausaktionen an die Tabelle weiterreichen
        foreach ereignis {<ButtonPress-1> <ButtonRelease-1> <ButtonPress-3> <Button-4> <Button-5>} {
            bind $feld $ereignis [list ::hauptansicht::status_weiterleiten %W $ereignis %x %y]
        }
        bind $feld <MouseWheel> {::hauptansicht::status_weiterleiten %W <MouseWheel> %x %y -delta %D}
        # Doppelklick: wird nicht aus zwei weitergereichten Klicks erkannt, daher eigens
        bind $feld <Double-ButtonPress-1> {::hauptansicht::status_doppelklick %W %x %y}
        lappend status_felder $feld
    }

    # Felder platzieren und einfärben, überzählige ausblenden
    set nr 0
    foreach feld $status_felder {
        if {$nr < [llength $felder]} {
            lassign [lindex $felder $nr] item kuerzel x y breite hoehe
            $feld configure -text $kuerzel \
                -background $stil(status_${kuerzel}_hintergrund) \
                -foreground $stil(status_${kuerzel}_text)
            place $feld -x $x -y $y -width $breite -height $hoehe
            # Langtext als Tooltip (z.B. "Gastschütze")
            ::tooltip::register $feld [::schuetzenstatus::text $kuerzel]
        } else {
            place forget $feld
        }
        incr nr
    }
}

# =============================================================================
# Prozedur: ::hauptansicht::status_weiterleiten
# Reicht ein Maus-Ereignis von einem Status-Feld an die Tabelle weiter, mit
# auf die Tabelle umgerechneten Koordinaten.
# Parameter:
#   feld     - Status-Label, auf dem das Ereignis auftrat
#   ereignis - Tk-Ereignis, z.B. <ButtonPress-1>
#   x, y     - Mausposition relativ zum Label
#   args     - weitere Optionen für event generate (z.B. -delta)
# =============================================================================
proc ::hauptansicht::status_weiterleiten {feld ereignis x y args} {
    variable tree
    # Tooltip des Feldes schließen (er würde sonst stehen bleiben)
    ::tooltip::hide
    event generate $tree $ereignis \
        -x [expr {$x + [winfo x $feld]}] -y [expr {$y + [winfo y $feld]}] \
        -rootx [winfo pointerx $tree] -rooty [winfo pointery $tree] {*}$args
}

# =============================================================================
# Prozedur: ::hauptansicht::status_doppelklick
# Doppelklick auf ein Status-Feld: Zeile auswählen und die Doppelklick-Aktion
# der Tabelle ausführen (öffnet den Bearbeiten-Dialog). Aus zwei
# weitergereichten Einzelklicks erkennt Tk keinen Doppelklick, weil
# erzeugte Ereignisse keinen verlässlichen Zeitstempel tragen.
# =============================================================================
proc ::hauptansicht::status_doppelklick {feld x y} {
    variable tree
    # Zeile unter dem Feld auswählen (wie ein normaler Klick)
    status_weiterleiten $feld <ButtonPress-1> $x $y
    status_weiterleiten $feld <ButtonRelease-1> $x $y
    # Doppelklick-Bindung der Tabelle ausführen (Koordinaten umgerechnet)
    set skript [bind $tree <Double-Button-1>]
    if {$skript ne ""} {
        set tx [expr {$x + [winfo x $feld]}]
        set ty [expr {$y + [winfo y $feld]}]
        uplevel #0 [string map [list %x $tx %y $ty %W $tree] $skript]
    }
}

# =============================================================================
# Prozedur: ::hauptansicht::yscroll
# Ersatz für die -yscrollcommand des Haupt-Treeviews: bedient die Scrollbar
# und lässt die Tageslinien an die neue Scrollposition anpassen.
# Parameter:
#   scrollbar - Pfad der vertikalen Scrollbar
#   args      - Werte von Tk (first last), unverändert an die Scrollbar
# =============================================================================
proc ::hauptansicht::yscroll {scrollbar args} {
    $scrollbar set {*}$args
    trenner_planen
}

# =============================================================================
# Prozedur: ::hauptansicht::xscroll
# Wie yscroll, für die horizontale Scrollbar: beim seitlichen Scrollen
# verschieben sich die Spalten, die Status-Felder müssen mitwandern.
# =============================================================================
proc ::hauptansicht::xscroll {scrollbar args} {
    $scrollbar set {*}$args
    trenner_planen
}

# =============================================================================
# Prozedur: ::hauptansicht::trenner_einrichten
# Bindet das Neuzeichnen von Tageslinien und Status-Feldern an
# Größenänderungen und an das Ändern von Spaltenbreiten (Ziehen in der
# Kopfzeile). Einmal nach dem Erzeugen von .main.tree aufrufen.
# (Scrollen wird über yscroll/xscroll erfasst.)
# =============================================================================
proc ::hauptansicht::trenner_einrichten {} {
    variable tree
    bind $tree <Configure>       {+::hauptansicht::trenner_planen}
    bind $tree <B1-Motion>       {+::hauptansicht::trenner_planen}
    bind $tree <ButtonRelease-1> {+::hauptansicht::trenner_planen}
}

# =============================================================================
# Statusleiste: Anzahl und Summen der angezeigten Einträge
# =============================================================================

# -----------------------------------------------------------------------------
# Hilfsprozedur: deutschen Betrag ("8,00", "1.234,50") in eine Zahl wandeln.
# Nicht lesbare oder leere Werte zählen als 0.
# -----------------------------------------------------------------------------
proc ::hauptansicht::betrag_lesen {text} {
    set zahl [string trim $text]
    # Mit Komma: deutsches Format -> Tausenderpunkte entfernen, Komma zu Punkt.
    # Ohne Komma: Wert unverändert lassen (z.B. "8.00" bleibt 8.00, nicht 800)
    if {[string first , $zahl] >= 0} {
        set zahl [string map {. "" , .} $zahl]
    }
    if {[string is double -strict $zahl]} {
        return $zahl
    }
    return 0
}

# -----------------------------------------------------------------------------
# Hilfsprozedur: Zahl als deutschen Betrag mit Tausenderpunkt formatieren,
# z.B. 12345.5 -> "12.345,50"
# -----------------------------------------------------------------------------
proc ::hauptansicht::betrag_format {zahl} {
    # Auf zwei Nachkommastellen runden und in Ganzzahl- und Nachkommateil teilen
    lassign [split [format "%.2f" $zahl] .] ganz rest

    # Vorzeichen abtrennen, damit es nicht in die Tausendergruppen gerät
    set vorzeichen ""
    if {[string index $ganz 0] eq "-"} {
        set vorzeichen "-"
        set ganz [string range $ganz 1 end]
    }

    # Von rechts in Dreiergruppen mit Punkt trennen: jeder Durchlauf setzt einen
    # Punkt vor die letzten drei Ziffern der führenden Ziffernfolge
    # (1234567 -> 1234.567 -> 1.234.567), bis keine 4 Ziffern mehr am Anfang stehen
    while {[regsub {^(\d+)(\d{3})} $ganz {\1.\2} ganz]} {}
    return "$vorzeichen$ganz,$rest"
}

# =============================================================================
# Prozedur: ::hauptansicht::status_aktualisieren
# Zeigt für die aktuell angezeigten (ggf. gefilterten) Zeilen Anzahl, Summe
# Startgeld und Summe Munitionspreis in der Statusleiste an, z.B.
#   "35 Einträge · Startgeld 241,00 € · Munition 403,00 €"
# Gerechnet wird mit den gespeicherten Originalwerten (nicht der Anzeige).
# =============================================================================
proc ::hauptansicht::status_aktualisieren {} {
    variable stil
    variable tree
    variable status_label

    # Statusleiste wird erst nach dem Treeview aufgebaut
    if {![winfo exists $status_label]} {
        return
    }

    # Summen über alle angezeigten Zeilen bilden
    set items [$tree children {}]
    set startgeld 0.0
    set munition  0.0
    foreach item $items {
        set startgeld [expr {$startgeld + [betrag_lesen [$tree set $item startgeld]]}]
        set munition  [expr {$munition  + [betrag_lesen [$tree set $item munpreis]]}]
    }

    # Anzahl mit korrekter Einzahl/Mehrzahl (Umlaut als Unicode-Escape)
    set anzahl [llength $items]
    if {$anzahl == 1} {
        set anzahl_text "1 Eintrag"
    } else {
        set anzahl_text "$anzahl Einträge"
    }

    # Text zusammensetzen und anzeigen
    set t $stil(status_trenner)
    $status_label configure -text \
        "$anzahl_text${t}Startgeld [betrag_format $startgeld] €${t}Munition [betrag_format $munition] €"
}

# =============================================================================
# Prozedur: ::hauptansicht::ansicht_aktualisiert
# Zentraler Hook: nach jedem Neubefüllen des Haupt-Treeviews aufrufen.
# Setzt alle zeilenabhängigen Darstellungen neu.
# =============================================================================
proc ::hauptansicht::ansicht_aktualisiert {} {
    variable tree

    # Treeview existiert erst nach dem Aufbau des Hauptfensters
    if {![winfo exists $tree]} {
        return
    }

    # Anzeige-Spalten (Munition / Mun.Preis ohne "Keine"/"0,00") befüllen
    anzeigewerte_setzen

    # Zebra-Streifen passend zur aktuellen Zeilenfolge setzen
    zebra $tree

    # Tagesgrenzen neu bestimmen und Trennlinien neu zeichnen
    trenner_berechnen
    trenner_planen

    # Anzahl und Summen in der Statusleiste aktualisieren
    status_aktualisieren
}
