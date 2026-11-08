#!/bin/sh
# =============================================================================
# erzeuge_icons.sh - Erzeugt die Toolbar-Icons aus den Tabler-SVG-Vorlagen
# =============================================================================
# Wandelt die SVG-Dateien in diesem Verzeichnis (Tabler Icons, MIT-Lizenz,
# siehe ../LICENSE-icons.txt) in 32x32-PNG-Dateien um, färbt sie ein und
# legt sie unter den vom Programm erwarteten Namen in resources/ ab.
#
# Benötigt: rsvg-convert (Paket librsvg2-bin bzw. librsvg)
#
# Aufruf (aus beliebigem Verzeichnis):
#   sh resources/icons-quelle/erzeuge_icons.sh
#
# Farben ändern: die beiden Variablen unten anpassen und Skript erneut
# ausführen. Sie entsprechen ::palette::neutral_text bzw. ::palette::positiv
# in inc/erscheinungsbild.tcl.
# =============================================================================

# Abbruch bei jedem Fehler
set -e

# -----------------------------------------------------------------------------
# Einstellungen
# -----------------------------------------------------------------------------
neutral="#2e3b2c"   # Linienfarbe aller Icons (dunkles Grün-Grau)
gruen="#569A40"     # Linienfarbe für "Neu" (Vereinsgrün)
groesse=32          # Kantenlänge der PNG-Dateien in Pixeln

# Verzeichnis dieses Skripts (SVG-Quellen) und Zielverzeichnis resources/
quelle=$(cd "$(dirname "$0")" && pwd)
ziel=$(dirname "$quelle")

# Prüfen, ob das Umwandlungsprogramm vorhanden ist
if ! command -v rsvg-convert >/dev/null 2>&1; then
    echo "Fehler: rsvg-convert nicht gefunden (Paket librsvg2-bin installieren)." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Zuordnung: SVG-Vorlage -> PNG-Dateiname -> Linienfarbe
# -----------------------------------------------------------------------------
# Die Tabler-SVGs zeichnen mit stroke="currentColor"; dieser Platzhalter wird
# vor dem Umwandeln durch die gewünschte Farbe ersetzt.
while read -r svg png farbe; do
    # Leerzeilen überspringen
    [ -z "$svg" ] && continue
    # Farbe einsetzen und in PNG der gewünschten Größe umwandeln
    sed "s/currentColor/$farbe/g" "$quelle/$svg.svg" \
        | rsvg-convert -w "$groesse" -h "$groesse" -o "$ziel/$png"
    echo "$png  <-  $svg.svg  ($farbe)"
done <<LISTE
file-plus Neuer_Eintrag.png $gruen
pencil    Bearbeiten.png    $neutral
search    Suchen.png        $neutral
users     Mitglieder.png    $neutral
chart-bar Statistik.png     $neutral
user-off  Blacklist.png     $neutral
trash     Loeschen.png      $neutral
logout    Beenden.png       $neutral
x         Schliessen.png    $neutral
LISTE
