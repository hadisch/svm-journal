# =============================================================================
# Datei: programm_lock.tcl
# Beschreibung: Verhindert mehrere Instanzen des SVM-Journal Programms
# =============================================================================

namespace eval ::programm_lock {
    # Lock-Datei Pfad
    variable lock_file ""
    # Status ob Lock erworben wurde
    variable lock_acquired 0
}

# =============================================================================
# Prozedur: get_lock_file_path
# Beschreibung: Gibt den Pfad zur Lock-Datei zurück
# Rückgabe: Vollständiger Pfad zur Lock-Datei
# =============================================================================
proc ::programm_lock::get_lock_file_path {} {
    variable lock_file

    if {$lock_file eq ""} {
        # Lock-Datei im User-Daten-Verzeichnis ablegen
        set user_data_dir [::pfad::get_user_data_directory]
        set lock_file [file join $user_data_dir "svm-journal.lock"]
    }

    return $lock_file
}

# =============================================================================
# Prozedur: process_exists
# Beschreibung: Prüft ob ein Prozess mit der gegebenen PID existiert
# Parameter: pid - Prozess-ID zum Prüfen
# Rückgabe: 1 wenn Prozess existiert, 0 sonst
# =============================================================================
proc ::programm_lock::process_exists {pid} {
    global tcl_platform

    # Plattformabhängige Prozess-Prüfung
    if {$tcl_platform(platform) eq "windows"} {
        # Windows: tasklist verwenden
        if {[catch {exec tasklist /FI "PID eq $pid" /NH} result]} {
            return 0
        }
        # Prüfen ob PID in der Ausgabe enthalten ist
        return [string match "*$pid*" $result]
    } else {
        # Unix/Linux/Mac: ps verwenden
        if {[catch {exec ps -p $pid} result]} {
            return 0
        }
        return 1
    }
}

# =============================================================================
# Prozedur: acquire_lock
# Beschreibung: Versucht den Lock zu erwerben
# Rückgabe: 1 bei Erfolg, 0 wenn bereits eine andere Instanz läuft
# =============================================================================
proc ::programm_lock::acquire_lock {} {
    variable lock_acquired

    set lock_path [get_lock_file_path]

    # Prüfen ob Lock-Datei existiert
    if {[file exists $lock_path]} {
        # Lock-Datei existiert - PID auslesen und prüfen
        if {[catch {
            set fp [open $lock_path r]
            set old_pid [string trim [read $fp]]
            close $fp
        }]} {
            # Fehler beim Lesen - Lock-Datei löschen und neu erstellen
            catch {file delete -force $lock_path}
        } else {
            # Prüfen ob Prozess noch läuft
            if {[process_exists $old_pid]} {
                # Prozess läuft noch - Lock nicht verfügbar
                return 0
            } else {
                # Stale Lock - Prozess existiert nicht mehr, Lock-Datei löschen
                catch {file delete -force $lock_path}
            }
        }
    }

    # Lock-Datei erstellen mit aktueller PID
    if {[catch {
        set fp [open $lock_path w]
        puts $fp [pid]
        close $fp
        set lock_acquired 1
    } fehler]} {
        # Fehler beim Erstellen - trotzdem fortfahren
        # (z.B. keine Schreibrechte)
        return 1
    }

    return 1
}

# =============================================================================
# Prozedur: release_lock
# Beschreibung: Gibt den Lock frei (beim Beenden des Programms)
# =============================================================================
proc ::programm_lock::release_lock {} {
    variable lock_acquired

    # Nur freigeben wenn Lock auch erworben wurde
    if {!$lock_acquired} {
        return
    }

    set lock_path [get_lock_file_path]

    # Lock-Datei löschen
    if {[file exists $lock_path]} {
        catch {file delete -force $lock_path}
    }

    set lock_acquired 0
}
