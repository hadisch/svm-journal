# =============================================================================
# toolbar_icons.tcl - Zentrales Management für Toolbar-Icons
# =============================================================================
# Dieses Modul lädt und verwaltet alle Icons für die Toolbar-Buttons.
# Die Icons werden beim Laden von 64x64 auf 32x32 Pixel skaliert.
# =============================================================================

# Namespace für das Icon-Management
namespace eval ::toolbar_icons {
    # Flag: Wurden die Icons bereits geladen?
    variable icons_loaded 0

    # Variablen für die geladenen Tk-Images
    variable icon_neuer_eintrag ""
    variable icon_bearbeiten ""
    variable icon_suchen ""
    variable icon_mitglieder ""
    variable icon_beenden ""
    variable icon_loeschen ""
    variable icon_schliessen ""
    variable icon_statistik ""
}

# =============================================================================
# ::toolbar_icons::load_all - Lädt alle Toolbar-Icons aus dem resources-Ordner
# =============================================================================
# Die Icons werden von 64x64 auf 32x32 Pixel skaliert für eine
# angemessene Toolbar-Größe.
# =============================================================================
proc ::toolbar_icons::load_all {} {
    variable icons_loaded
    variable icon_neuer_eintrag
    variable icon_bearbeiten
    variable icon_suchen
    variable icon_mitglieder
    variable icon_beenden
    variable icon_loeschen
    variable icon_schliessen
    variable icon_statistik

    # Falls Icons bereits geladen, nichts tun
    if {$icons_loaded} {
        return
    }

    # Liste der zu ladenden Icons: {Variablenname Dateiname}
    set icon_list {
        icon_neuer_eintrag "Neuer_Eintrag.png"
        icon_bearbeiten "Bearbeiten.png"
        icon_suchen "Suchen.png"
        icon_mitglieder "Mitglieder.png"
        icon_beenden "Beenden.png"
        icon_loeschen "Loeschen.png"
        icon_schliessen "Schliessen.png"
        icon_statistik "Statistik.png"
    }

    # Jedes Icon laden und skalieren
    foreach {var_name filename} $icon_list {
        # Vollständigen Pfad zum Icon ermitteln
        set icon_path [::pfad::get_resources_path $filename]

        # Prüfen, ob die Datei existiert
        if {![file exists $icon_path]} {
            # Warnung ausgeben, falls Icon nicht gefunden
            puts stderr "Warnung: Icon nicht gefunden: $icon_path"
            continue
        }

        # Icon laden und skalieren
        if {[catch {
            # Temporäres Bild im Originalformat (64x64) laden
            set temp_img [image create photo -file $icon_path]

            # Skaliertes Bild erstellen (32x32)
            # -subsample 2 2 reduziert die Größe um Faktor 2 in beiden Dimensionen
            set scaled_img [image create photo]
            $scaled_img copy $temp_img -subsample 2 2

            # Temporäres Original-Bild löschen um Speicher freizugeben
            image delete $temp_img

            # Skaliertes Bild in die entsprechende Variable speichern
            set $var_name $scaled_img

        } err]} {
            # Fehlerbehandlung: Warnung ausgeben falls Laden fehlschlägt
            puts stderr "Fehler beim Laden von $filename: $err"
        }
    }

    # Flag setzen: Icons wurden geladen
    set icons_loaded 1
}

# =============================================================================
# ::toolbar_icons::get - Gibt den Image-Namen für ein bestimmtes Icon zurück
# =============================================================================
# Parameter:
#   icon_name - Name des Icons (ohne "icon_" Präfix)
#               Gültige Werte: neuer_eintrag, bearbeiten, suchen, mitglieder,
#                              beenden, loeschen, schliessen
# Rückgabe:
#   Der Tk-Image-Name, der mit dem -image Parameter von Buttons verwendet
#   werden kann, oder leerer String falls Icon nicht gefunden.
# =============================================================================
proc ::toolbar_icons::get {icon_name} {
    variable icons_loaded
    variable icon_neuer_eintrag
    variable icon_bearbeiten
    variable icon_suchen
    variable icon_mitglieder
    variable icon_beenden
    variable icon_loeschen
    variable icon_schliessen
    variable icon_statistik

    # Falls Icons noch nicht geladen, jetzt laden
    if {!$icons_loaded} {
        load_all
    }

    # Entsprechendes Icon zurückgeben basierend auf dem Namen
    switch -- $icon_name {
        "neuer_eintrag" { return $icon_neuer_eintrag }
        "bearbeiten"    { return $icon_bearbeiten }
        "suchen"        { return $icon_suchen }
        "mitglieder"    { return $icon_mitglieder }
        "beenden"       { return $icon_beenden }
        "loeschen"      { return $icon_loeschen }
        "schliessen"    { return $icon_schliessen }
        "statistik"     { return $icon_statistik }
        default {
            # Unbekannter Icon-Name: Warnung ausgeben
            puts stderr "Warnung: Unbekanntes Icon angefordert: $icon_name"
            return ""
        }
    }
}
