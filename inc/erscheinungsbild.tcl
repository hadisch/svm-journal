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
# Einzige Referenzstelle für das Farbschema der Buttons. Alle Buttons im
# Programm verwenden einen der beiden fertigen Options-Sätze:
#   button $w ... {*}$::palette::knopf_positiv   (bestätigende Aktion)
#   button $w ... {*}$::palette::knopf_neutral   (Abbrechen/Schließen/sekundär)
#   button $w ... {*}$::palette::knopf_icon      (Icon-Button in einer Toolbar)
# Die Sätze legen ALLE Zustände fest (normal, Maus darüber, deaktiviert), damit
# kein Button auf die uneinheitlichen Tk-Standardfarben zurückfällt.
# Buttons ohne eigenen Satz (z.B. Icon-Buttons) erhalten über die Option-
# Datenbank automatisch das Icon-Aussehen (siehe ::erscheinungsbild::anwenden).
#
# Bedeutung der Button-Farben:
#   positiv          Vereinsgrün, weiße Schrift - bestätigende Aktionen
#                    (Speichern, Hinzufügen, Exportieren, Neu, Suchen, Ja ...)
#   neutral          helles Grau, dunkle Schrift - Abbrechen/Schließen/sekundär
#   akzent           Vereinsgrün als Akzentfarbe (Listen-Kopfzeilen sind hell, siehe inc/hauptansicht.tcl)
# =============================================================================
namespace eval ::palette {
    variable positiv              "#569A40" ;# Vereinsgrün - bestätigende Aktionen
    variable positiv_aktiv        "#4a8735" ;# Vereinsgrün (Maus darüber/gedrückt)
    variable positiv_text         "white"   ;# Schriftfarbe auf positiv-Buttons
    variable positiv_text_inaktiv "#B5D3AA" ;# Schrift deaktivierter positiv-Buttons (blasses Grün)
    variable neutral              "#CFCFCF" ;# Grau - Abbrechen/Schließen (hebt sich vom Fenster ab)
    variable neutral_aktiv        "#BDBDBD" ;# Grau (Maus darüber/gedrückt)
    variable neutral_text         "#2e3b2c" ;# Schriftfarbe auf neutral-Buttons (dunkles Grün-Grau)
    variable neutral_text_inaktiv "#9A9A9A" ;# Schrift deaktivierter neutral-Buttons
    variable akzent               "#569A40" ;# Akzentfarbe (identisch Vereinsgrün)
    variable icon                 "#E0E0E0" ;# Hintergrund von Icon-Buttons (= Toolbar-Hintergrund)
    variable icon_aktiv           "#C8C8C8" ;# Icon-Button (Maus darüber/gedrückt)

    # Fertige Options-Sätze für button-Widgets (Verwendung: {*}$::palette::knopf_positiv)
    variable knopf_positiv [list \
        -background         $positiv \
        -foreground         $positiv_text \
        -activebackground   $positiv_aktiv \
        -activeforeground   $positiv_text \
        -disabledforeground $positiv_text_inaktiv]
    variable knopf_neutral [list \
        -background         $neutral \
        -foreground         $neutral_text \
        -activebackground   $neutral_aktiv \
        -activeforeground   $neutral_text \
        -disabledforeground $neutral_text_inaktiv]
    # Icon-Buttons in Toolbars: Hintergrund wie die Toolbar, damit das Icon
    # nicht auf einem abgesetzten Quadrat sitzt
    variable knopf_icon [list \
        -background         $icon \
        -foreground         $neutral_text \
        -activebackground   $icon_aktiv \
        -activeforeground   $neutral_text \
        -disabledforeground $neutral_text_inaktiv]
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

    # Buttons ohne eigene Farben (das sind nur noch Icon-Buttons in Toolbars):
    # Icon-Aussehen in allen Zuständen, damit keiner auf die Tk-Standardfarben
    # zurückfällt. Text-Buttons verwenden immer knopf_positiv/knopf_neutral.
    option add *Button.background         $::palette::icon                 widgetDefault
    option add *Button.foreground         $::palette::neutral_text         widgetDefault
    option add *Button.activeBackground   $::palette::icon_aktiv           widgetDefault
    option add *Button.activeForeground   $::palette::neutral_text         widgetDefault
    option add *Button.disabledForeground $::palette::neutral_text_inaktiv widgetDefault

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
