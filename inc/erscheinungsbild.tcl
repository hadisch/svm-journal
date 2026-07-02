# =============================================================================
# erscheinungsbild.tcl - Zentrale Optik-Einstellungen (Schritt 1)
# =============================================================================
# Modernisiert das Erscheinungsbild der klassischen Tk-Widgets, OHNE die
# Funktionalität oder einzelne Dialoge anzufassen. Der gesamte Effekt entsteht
# über die Tk-Option-Datenbank und die benannten Schriften und wirkt dadurch
# global auf alle Fenster.
#
# Wirkung (Schritt 1):
#   - flache Ränder statt der grauen 3D-Bevel-Optik (Hauptursache des "90er-Looks")
#   - moderne Schriftfamilie für alle Widgets, die TkDefaultFont & Co. verwenden
#   - etwas mehr Innenabstand (Padding), damit die Oberfläche "luftiger" wirkt
#
# WICHTIG: Dieses Modul muss geladen und ::erscheinungsbild::anwenden aufgerufen
# werden, BEVOR die ersten Widgets erzeugt werden - sonst greifen die Optionen
# aus der Option-Datenbank nicht mehr für die bereits erstellten Widgets.
#
# ABSCHALTEN: In svm-journal.tcl die source-Zeile und den anwenden-Aufruf
# auskommentieren - dann ist wieder exakt der alte Zustand hergestellt.
# =============================================================================

namespace eval ::erscheinungsbild {
}

# =============================================================================
# Zentrale Farbpalette (Schritt 2) - "hell & neutral"
# =============================================================================
# Einzige Referenzstelle für das Farbschema der Buttons. Die Werte sind aktuell
# direkt in den Dialogen hinterlegt (gewachsener Code-Stil); dieses Namespace
# dient als dokumentierte Quelle der Wahrheit und kann von neuen Buttons per
# $::palette::<name> verwendet werden, damit das Schema konsistent bleibt.
#
# Bedeutung der Button-Farben:
#   positiv          Vereinsgrün, weiße Schrift - bestätigende Aktionen
#                    (Speichern, Hinzufügen, Exportieren, Neu ...)
#   neutral          helles Grau, dunkle Schrift - Abbrechen/Schließen/sekundär
#   akzent           Vereinsgrün als Akzentfarbe (z.B. Treeview-Kopf)
# =============================================================================
namespace eval ::palette {
    variable positiv        "#569A40" ;# Vereinsgrün - bestätigende Aktionen
    variable positiv_aktiv  "#4a8735" ;# Vereinsgrün (gedrückt/aktiv)
    variable positiv_text   "white"   ;# Schriftfarbe auf positiv-Buttons
    variable neutral        "#E0E0E0" ;# helles Grau - Abbrechen/Schließen
    variable neutral_aktiv  "#C8C8C8" ;# helles Grau (gedrückt/aktiv)
    variable akzent         "#569A40" ;# Akzentfarbe (identisch Vereinsgrün)
}

# -----------------------------------------------------------------------------
# Liefert die erste auf diesem System tatsächlich vorhandene Schriftfamilie aus
# einer Vorschlagsliste. So können wir plattformabhängig moderne Systemschriften
# bevorzugen, fallen aber sauber zurück, wenn keine davon installiert ist.
# -----------------------------------------------------------------------------
proc ::erscheinungsbild::_erste_verfuegbare_schrift {kandidaten} {
    # Alle auf dem System installierten Schriftfamilien einmalig abfragen
    set vorhanden [font families]
    # Kandidaten in Reihenfolge prüfen und erste vorhandene zurückgeben
    foreach fam $kandidaten {
        if {[lsearch -exact -nocase $vorhanden $fam] >= 0} {
            return $fam
        }
    }
    # Keine der Wunschschriften vorhanden -> leerer String signalisiert "nichts ändern"
    return ""
}

# -----------------------------------------------------------------------------
# Wendet alle Optik-Einstellungen an. Muss vor der Widget-Erzeugung laufen.
# -----------------------------------------------------------------------------
proc ::erscheinungsbild::anwenden {} {
    global tcl_platform

    # -------------------------------------------------------------------------
    # 1. Moderne Schriftfamilie wählen
    # -------------------------------------------------------------------------
    # Pro Plattform eine Reihenfolge bevorzugter, moderner Systemschriften.
    if {$tcl_platform(platform) eq "windows"} {
        # Windows: Segoe UI ist die Standard-UI-Schrift ab Windows Vista
        set kandidaten [list "Segoe UI" "Tahoma"]
    } elseif {$tcl_platform(os) eq "Darwin"} {
        # macOS: systemtypische UI-Schriften
        set kandidaten [list "Helvetica Neue" "Lucida Grande"]
    } else {
        # Linux/Unix: verbreitete moderne Sans-Serif-Schriften
        set kandidaten [list "Noto Sans" "Cantarell" "DejaVu Sans" "Ubuntu"]
    }

    # Erste vorhandene Wunschschrift ermitteln
    set fam [::erscheinungsbild::_erste_verfuegbare_schrift $kandidaten]

    # Nur wenn eine passende Schrift gefunden wurde, die benannten Fonts umstellen.
    # Bewusst NUR die Familie ändern (nicht die Größe) - so bleibt das Layout der
    # bestehenden Dialoge unverändert und das Risiko minimal.
    if {$fam ne ""} {
        foreach f {TkDefaultFont TkTextFont TkMenuFont TkHeadingFont \
                   TkTooltipFont TkCaptionFont TkSmallCaptionFont} {
            # catch, falls eine benannte Schrift auf einer Plattform nicht existiert
            catch {font configure $f -family $fam}
        }
    }

    # -------------------------------------------------------------------------
    # 2. Flache Ränder statt 3D-Bevel
    # -------------------------------------------------------------------------
    # Priorität "widgetDefault" (40): überschreibt die eingebauten Standardwerte
    # der Widgets, wird aber von explizit im Code gesetzten Optionen (z.B. ein
    # ausdrückliches -relief an einem einzelnen Widget) NICHT überstimmt.

    # Buttons: flach dargestellt, beim Überfahren mit der Maus dezent erhaben
    # (overRelief) - so bleibt die Klickbarkeit erkennbar, ohne dauerhaften Rahmen.
    option add *Button.relief          flat   widgetDefault
    option add *Button.overRelief      raised widgetDefault
    option add *Button.borderWidth     1      widgetDefault
    option add *Button.highlightThickness 0   widgetDefault
    option add *Button.padX            10     widgetDefault
    option add *Button.padY            5      widgetDefault

    # Eingabefelder: dünner durchgehender Rahmen statt versenkter 3D-Optik
    option add *Entry.relief           solid  widgetDefault
    option add *Entry.borderWidth      1      widgetDefault
    option add *Entry.highlightThickness 1    widgetDefault

    # Check-/Radiobuttons: störenden Fokus-Kasten entfernen
    option add *Checkbutton.highlightThickness 0 widgetDefault
    option add *Radiobutton.highlightThickness 0 widgetDefault

    # Listboxen: ebenfalls flacher, dünner Rahmen
    option add *Listbox.relief         solid  widgetDefault
    option add *Listbox.borderWidth    1      widgetDefault
    option add *Listbox.highlightThickness 0  widgetDefault

    # Spinboxen analog zu den Eingabefeldern
    option add *Spinbox.relief         solid  widgetDefault
    option add *Spinbox.borderWidth    1      widgetDefault
    option add *Spinbox.highlightThickness 1  widgetDefault
}
