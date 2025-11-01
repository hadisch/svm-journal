# =============================================================================
# Pfad-Management-System für SVM-Journal
# =============================================================================
# Verwaltet plattformübergreifend die Verzeichnisstruktur und JSON-Dateipfade
# - Programm-Verzeichnis: enthält ausführbare Skripte
# - User-Daten-Verzeichnis: enthält JSON-Dateien und Benutzerdaten
#   * Linux/Mac: ~/.config/svm/
#   * Windows: %APPDATA%\SVM
# - Unterverzeichnisse: daten/, preferences/, backups/
# =============================================================================

# Namespace für Pfad-Management-Funktionen
namespace eval ::pfad {
    # Globale Variablen für Pfade
    variable script_dir ""     ;# Verzeichnis des Hauptskripts
    variable user_data_dir ""  ;# User-Daten-Verzeichnis (plattformabhängig)
    variable daten_dir ""      ;# Unterverzeichnis für Daten
    variable preferences_dir "" ;# Unterverzeichnis für Einstellungen
    variable backups_dir ""    ;# Unterverzeichnis für Backups
    variable archiv_dir ""     ;# Unterverzeichnis für Archiv (unter daten/)
    variable resources_dir ""  ;# Verzeichnis für Ressourcen (im Programm-Verzeichnis)
    variable log_file ""       ;# Logdatei für Fehlersuche
}

# =============================================================================
# Funktion: get_platform
# Ermittelt die aktuelle Plattform (windows, unix, macosx)
# =============================================================================
proc ::pfad::get_platform {} {
    global tcl_platform
    return $tcl_platform(platform)
}

# =============================================================================
# Funktion: expand_path
# Erweitert Pfade mit Tilde (~) und Umgebungsvariablen
# Parameter:
#   path - Pfad mit evtl. Tilde oder Umgebungsvariablen
# Rückgabe:
#   Vollständig expandierter absoluter Pfad
# =============================================================================
proc ::pfad::expand_path {path} {
    # Tilde am Anfang durch Home-Verzeichnis ersetzen
    if {[string match "~*" $path]} {
        # Home-Verzeichnis ermitteln
        set home ""
        if {[info exists ::env(HOME)]} {
            set home $::env(HOME)
        } elseif {[info exists ::env(USERPROFILE)]} {
            # Windows: USERPROFILE verwenden
            set home $::env(USERPROFILE)
        }

        # Tilde durch Home-Verzeichnis ersetzen
        if {$home ne ""} {
            set path [string map [list "~" $home] $path]
        }
    }

    # Umgebungsvariablen expandieren
    # Windows: %APPDATA% etc.
    if {[::pfad::get_platform] eq "windows"} {
        # Alle %VAR% Muster durch Umgebungsvariablen ersetzen
        set pattern {%([^%]+)%}
        while {[regexp $pattern $path match varname]} {
            if {[info exists ::env($varname)]} {
                set value $::env($varname)
                set path [string map [list "%${varname}%" $value] $path]
            } else {
                # Umgebungsvariable existiert nicht - belassen
                break
            }
        }
    }

    # Pfad normalisieren (/ und \ vereinheitlichen, .. auflösen etc.)
    return [file normalize $path]
}

# =============================================================================
# Funktion: get_user_data_directory
# Ermittelt das User-Daten-Verzeichnis abhängig von der Plattform
# Rückgabe:
#   Absoluter Pfad zum User-Daten-Verzeichnis
# =============================================================================
proc ::pfad::get_user_data_directory {} {
    set platform [::pfad::get_platform]

    # Plattformabhängiges Verzeichnis ermitteln
    if {$platform eq "windows"} {
        # Windows: %APPDATA%\SVM
        if {[info exists ::env(APPDATA)]} {
            # Primärer Pfad: %APPDATA%\SVM
            set base_dir $::env(APPDATA)
        } elseif {[info exists ::env(USERPROFILE)]} {
            # Fallback: USERPROFILE\AppData\Roaming
            set base_dir [file join $::env(USERPROFILE) "AppData" "Roaming"]
        } else {
            # Letzter Fallback: aktuelles Verzeichnis
            set base_dir [pwd]
        }
        return [file join $base_dir "SVM"]
    } else {
        # Linux/Mac: ~/.config/svm/
        set home ""
        if {[info exists ::env(HOME)]} {
            set home $::env(HOME)
        } else {
            # Fallback: aktuelles Verzeichnis
            set home [pwd]
        }
        return [file join $home ".config" "svm"]
    }
}

# =============================================================================
# Funktion: create_directory_if_needed
# Erstellt ein Verzeichnis, falls es nicht existiert
# Parameter:
#   dir - Verzeichnispfad
# Rückgabe:
#   1 bei Erfolg, 0 bei Fehler
# =============================================================================
proc ::pfad::create_directory_if_needed {dir} {
    # Prüfen, ob Verzeichnis bereits existiert
    if {[file exists $dir]} {
        if {[file isdirectory $dir]} {
            # Verzeichnis existiert bereits
            ::pfad::log "Verzeichnis existiert bereits: $dir"
            return 1
        } else {
            # Pfad existiert, ist aber kein Verzeichnis
            ::pfad::log "FEHLER: Pfad existiert, ist aber kein Verzeichnis: $dir"
            return 0
        }
    }

    # Verzeichnis erstellen (mit allen Parent-Verzeichnissen)
    if {[catch {file mkdir $dir} err]} {
        # Fehler beim Erstellen
        ::pfad::log "FEHLER beim Erstellen von $dir: $err"
        return 0
    }

    ::pfad::log "Verzeichnis erfolgreich erstellt: $dir"
    return 1
}

# =============================================================================
# Funktion: is_directory_writable
# Prüft, ob ein Verzeichnis beschreibbar ist
# Parameter:
#   dir - Verzeichnispfad
# Rückgabe:
#   1 wenn beschreibbar, 0 wenn nicht
# =============================================================================
proc ::pfad::is_directory_writable {dir} {
    # Prüfen, ob Verzeichnis existiert
    if {![file exists $dir]} {
        return 0
    }

    # Prüfen, ob es ein Verzeichnis ist
    if {![file isdirectory $dir]} {
        return 0
    }

    # Prüfen, ob Verzeichnis beschreibbar ist
    return [file writable $dir]
}

# =============================================================================
# Funktion: copy_file_if_exists
# Kopiert eine Datei, falls sie existiert
# Parameter:
#   source - Quellpfad
#   dest - Zielpfad
# Rückgabe:
#   1 bei Erfolg, 0 bei Fehler oder wenn Quelle nicht existiert
# =============================================================================
proc ::pfad::copy_file_if_exists {source dest} {
    # Prüfen, ob Quelldatei existiert
    if {![file exists $source]} {
        ::pfad::log "Quelldatei existiert nicht: $source"
        return 0
    }

    # Prüfen, ob Zieldatei bereits existiert
    if {[file exists $dest]} {
        ::pfad::log "Zieldatei existiert bereits, überspringe Kopieren: $dest"
        return 1
    }

    # Datei kopieren
    if {[catch {file copy $source $dest} err]} {
        ::pfad::log "FEHLER beim Kopieren von $source nach $dest: $err"
        return 0
    }

    ::pfad::log "Datei erfolgreich kopiert: $source -> $dest"
    return 1
}

# =============================================================================
# Funktion: rotate_log_file
# Rotiert Logdatei wenn sie größer als 1 MB ist
# Behält maximal 3 alte Logdateien (.1, .2, .3)
# Parameter:
#   log_path - Pfad zur Logdatei
# =============================================================================
proc ::pfad::rotate_log_file {log_path} {
    # Prüfen ob Logdatei existiert
    if {![file exists $log_path]} {
        return
    }

    # Dateigröße prüfen (1 MB = 1048576 Bytes)
    set file_size [file size $log_path]
    if {$file_size < 1048576} {
        # Datei ist kleiner als 1 MB - keine Rotation nötig
        return
    }

    # Log-Rotation durchführen
    # Zuerst alte Logs verschieben: .2 -> .3, .1 -> .2
    # Dann aktuelles Log -> .1

    # .3 löschen falls vorhanden (ältestes Log)
    set log_3 "${log_path}.3"
    if {[file exists $log_3]} {
        catch {file delete $log_3}
    }

    # .2 -> .3
    set log_2 "${log_path}.2"
    if {[file exists $log_2]} {
        catch {file rename -force $log_2 $log_3}
    }

    # .1 -> .2
    set log_1 "${log_path}.1"
    if {[file exists $log_1]} {
        catch {file rename -force $log_1 $log_2}
    }

    # Aktuelles Log -> .1
    catch {file rename -force $log_path $log_1}

    # Neue leere Logdatei wird beim nächsten Log-Eintrag automatisch erstellt
}

# =============================================================================
# Funktion: cleanup_old_backups
# Bereinigt alte Backup-Dateien im Backup-Verzeichnis
# Behält maximal die letzten 10 Backups pro Datei-Typ
# Parameter:
#   backup_dir - Pfad zum Backup-Verzeichnis
#   file_pattern - Datei-Pattern (z.B. "2025.json.*.bak")
#   max_backups - Maximale Anzahl zu behaltender Backups (Standard: 10)
# =============================================================================
proc ::pfad::cleanup_old_backups {backup_dir file_pattern {max_backups 10}} {
    # Prüfen ob Backup-Verzeichnis existiert
    if {![file exists $backup_dir]} {
        return
    }

    # Alle Backup-Dateien finden, die dem Pattern entsprechen
    set backup_files [lsort [glob -nocomplain -directory $backup_dir $file_pattern]]

    # Anzahl der gefundenen Backups
    set backup_count [llength $backup_files]

    # Wenn weniger oder gleich max_backups vorhanden, nichts tun
    if {$backup_count <= $max_backups} {
        return
    }

    # Backup-Dateien nach Änderungsdatum sortieren (älteste zuerst)
    # Hilfsprozedur zum Vergleichen der Datei-Änderungszeiten
    set sorted_backups [lsort -command [list apply {{a b} {
        # Änderungszeit der Dateien vergleichen
        set mtime_a [file mtime $a]
        set mtime_b [file mtime $b]
        return [expr {$mtime_a - $mtime_b}]
    }}] $backup_files]

    # Anzahl zu löschender Dateien berechnen
    set delete_count [expr {$backup_count - $max_backups}]

    # Älteste Dateien löschen
    for {set i 0} {$i < $delete_count} {incr i} {
        set file_to_delete [lindex $sorted_backups $i]
        if {[catch {
            file delete $file_to_delete
            puts "Altes Backup gelöscht: [file tail $file_to_delete]"
        } err]} {
            puts "FEHLER beim Löschen von Backup $file_to_delete: $err"
        }
    }
}

# =============================================================================
# Funktion: log
# Schreibt eine Log-Nachricht in die Logdatei und gibt sie auf stdout aus
# Prüft vor dem Schreiben, ob Log-Rotation nötig ist
# Parameter:
#   message - Log-Nachricht
# =============================================================================
proc ::pfad::log {message} {
    variable log_file

    # Zeitstempel erstellen
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set log_entry "$timestamp - $message"

    # Auf stdout ausgeben
    puts $log_entry

    # In Logdatei schreiben (wenn initialisiert)
    if {$log_file ne ""} {
        # Log-Rotation durchführen falls nötig (vor dem Schreiben)
        ::pfad::rotate_log_file $log_file

        if {[catch {
            set fh [open $log_file a]
            puts $fh $log_entry
            close $fh
        } err]} {
            puts "FEHLER beim Schreiben in Logdatei: $err"
        }
    }
}

# =============================================================================
# Funktion: initialize_directories
# Initialisiert die komplette Verzeichnisstruktur beim ersten Start
# - Erstellt User-Daten-Verzeichnis und Unterverzeichnisse
# - Kopiert vorhandene JSON-Dateien aus dem Programm-Verzeichnis
# Rückgabe:
#   1 bei Erfolg, 0 bei Fehler
# =============================================================================
proc ::pfad::initialize_directories {} {
    variable script_dir
    variable user_data_dir
    variable daten_dir
    variable preferences_dir
    variable backups_dir
    variable archiv_dir
    variable resources_dir
    variable log_file

    # Script-Verzeichnis ermitteln
    # Da pfad_management.tcl im inc/-Verzeichnis liegt, gehen wir eine Ebene hoch
    set script_dir [file dirname [file dirname [info script]]]

    # User-Daten-Verzeichnis ermitteln
    set user_data_dir [::pfad::get_user_data_directory]

    # Unterverzeichnisse im User-Daten-Verzeichnis definieren
    set daten_dir [file join $user_data_dir "daten"]
    set preferences_dir [file join $user_data_dir "preferences"]
    set backups_dir [file join $user_data_dir "backups"]
    set archiv_dir [file join $daten_dir "archiv"]

    # Resources-Verzeichnis im Programm-Verzeichnis
    set resources_dir [file join $script_dir "resources"]

    # Logdatei im User-Daten-Verzeichnis
    set log_file [file join $user_data_dir "svm-journal.log"]

    # =============================================================================
    # Logging: Pfade beim Start ausgeben (zur Fehlersuche)
    # =============================================================================
    ::pfad::log "=========================================="
    ::pfad::log "SVM-Journal Pfad-Initialisierung gestartet"
    ::pfad::log "=========================================="
    ::pfad::log "Plattform: [::pfad::get_platform]"
    ::pfad::log "Script-Verzeichnis: $script_dir"
    ::pfad::log "User-Daten-Verzeichnis: $user_data_dir"
    ::pfad::log "Daten-Verzeichnis: $daten_dir"
    ::pfad::log "Preferences-Verzeichnis: $preferences_dir"
    ::pfad::log "Backups-Verzeichnis: $backups_dir"
    ::pfad::log "Archiv-Verzeichnis: $archiv_dir"
    ::pfad::log "Resources-Verzeichnis: $resources_dir"
    ::pfad::log "Logdatei: $log_file"

    # =============================================================================
    # Verzeichnisse erstellen
    # =============================================================================

    # User-Daten-Verzeichnis erstellen
    if {![::pfad::create_directory_if_needed $user_data_dir]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "Konnte User-Daten-Verzeichnis nicht erstellen:\n$user_data_dir"
        return 0
    }

    # Unterverzeichnisse erstellen
    if {![::pfad::create_directory_if_needed $daten_dir]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "Konnte Daten-Verzeichnis nicht erstellen:\n$daten_dir"
        return 0
    }

    if {![::pfad::create_directory_if_needed $preferences_dir]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "Konnte Preferences-Verzeichnis nicht erstellen:\n$preferences_dir"
        return 0
    }

    if {![::pfad::create_directory_if_needed $backups_dir]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "Konnte Backups-Verzeichnis nicht erstellen:\n$backups_dir"
        return 0
    }

    if {![::pfad::create_directory_if_needed $archiv_dir]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "Konnte Archiv-Verzeichnis nicht erstellen:\n$archiv_dir"
        return 0
    }

    # =============================================================================
    # Beschreibbarkeit prüfen
    # =============================================================================

    if {![::pfad::is_directory_writable $user_data_dir]} {
        tk_messageBox -icon error -title "Fehler" \
            -message "User-Daten-Verzeichnis ist nicht beschreibbar:\n$user_data_dir"
        return 0
    }

    ::pfad::log "Alle Verzeichnisse sind beschreibbar"

    # =============================================================================
    # JSON-Dateien aus Programm-Verzeichnis kopieren (nur beim ersten Start)
    # =============================================================================

    ::pfad::log "Kopiere JSON-Dateien aus Programm-Verzeichnis..."

    # Daten-Dateien kopieren
    set source_daten_dir [file join $script_dir "daten"]
    if {[file exists $source_daten_dir]} {
        # Alle JSON-Dateien im daten-Verzeichnis finden
        foreach source_file [glob -nocomplain -directory $source_daten_dir "*.json"] {
            set filename [file tail $source_file]
            set dest_file [file join $daten_dir $filename]
            ::pfad::copy_file_if_exists $source_file $dest_file
        }
    }

    # Preferences-Dateien kopieren
    set source_preferences_dir [file join $script_dir "preferences"]
    if {[file exists $source_preferences_dir]} {
        # Alle JSON-Dateien im preferences-Verzeichnis finden
        foreach source_file [glob -nocomplain -directory $source_preferences_dir "*.json"] {
            set filename [file tail $source_file]
            set dest_file [file join $preferences_dir $filename]
            ::pfad::copy_file_if_exists $source_file $dest_file
        }
    }

    ::pfad::log "=========================================="
    ::pfad::log "Pfad-Initialisierung erfolgreich abgeschlossen"
    ::pfad::log "=========================================="

    return 1
}

# =============================================================================
# Funktion: get_json_path
# Gibt den vollständigen Pfad zu einer JSON-Datei zurück
# Parameter:
#   category - Kategorie (daten, preferences, backups)
#   filename - Dateiname (z.B. "mitglieder.json")
# Rückgabe:
#   Vollständiger Pfad zur JSON-Datei
# =============================================================================
proc ::pfad::get_json_path {category filename} {
    variable user_data_dir
    variable daten_dir
    variable preferences_dir
    variable backups_dir

    # Je nach Kategorie den richtigen Pfad zurückgeben
    switch -exact -- $category {
        "daten" {
            return [file join $daten_dir $filename]
        }
        "preferences" {
            return [file join $preferences_dir $filename]
        }
        "backups" {
            return [file join $backups_dir $filename]
        }
        default {
            ::pfad::log "FEHLER: Unbekannte Kategorie: $category"
            return ""
        }
    }
}

# =============================================================================
# Funktion: get_script_directory
# Gibt das Programm-Verzeichnis zurück
# Rückgabe:
#   Absoluter Pfad zum Programm-Verzeichnis
# =============================================================================
proc ::pfad::get_script_directory {} {
    variable script_dir
    return $script_dir
}

# =============================================================================
# Funktion: get_user_data_directory_path
# Gibt das User-Daten-Verzeichnis zurück
# Rückgabe:
#   Absoluter Pfad zum User-Daten-Verzeichnis
# =============================================================================
proc ::pfad::get_user_data_directory_path {} {
    variable user_data_dir
    return $user_data_dir
}

# =============================================================================
# Funktion: get_archiv_directory
# Gibt das Archiv-Verzeichnis zurück
# Rückgabe:
#   Absoluter Pfad zum Archiv-Verzeichnis
# =============================================================================
proc ::pfad::get_archiv_directory {} {
    variable archiv_dir
    return $archiv_dir
}

# =============================================================================
# Funktion: get_backups_directory
# Gibt das Backups-Verzeichnis zurück
# Rückgabe:
#   Absoluter Pfad zum Backups-Verzeichnis
# =============================================================================
proc ::pfad::get_backups_directory {} {
    variable backups_dir
    return $backups_dir
}

# =============================================================================
# Funktion: get_resources_path
# Gibt den vollständigen Pfad zu einer Ressourcen-Datei zurück
# Parameter:
#   filename - Dateiname (z.B. "Logo.gif")
# Rückgabe:
#   Vollständiger Pfad zur Ressourcen-Datei
# =============================================================================
proc ::pfad::get_resources_path {filename} {
    variable resources_dir
    return [file join $resources_dir $filename]
}

# =============================================================================
# Funktion: get_jahres_json_path
# Gibt den vollständigen Pfad zu einer Jahres-JSON-Datei zurück
# Parameter:
#   jahr - Jahr (z.B. "2025")
# Rückgabe:
#   Vollständiger Pfad zur Jahres-JSON-Datei
# =============================================================================
proc ::pfad::get_jahres_json_path {jahr} {
    variable daten_dir
    return [file join $daten_dir "${jahr}.json"]
}

# =============================================================================
# Funktion: get_daten_directory
# Gibt das Daten-Verzeichnis zurück
# Rückgabe:
#   Absoluter Pfad zum Daten-Verzeichnis
# =============================================================================
proc ::pfad::get_daten_directory {} {
    variable daten_dir
    return $daten_dir
}

# =============================================================================
# Pfad-Management beim Laden initialisieren
# =============================================================================

# Verzeichnisstruktur initialisieren
if {![::pfad::initialize_directories]} {
    # Fehler bei Initialisierung - Programm beenden
    puts "KRITISCHER FEHLER: Pfad-Initialisierung fehlgeschlagen!"
    exit 1
}
