# Helper-Prozedur zum Schreiben der mitglieder.json
proc schreibe_mitglieder_json {} {
    global mitglieder_json

    set anzahl [llength $::mitglieder_liste]
    set counter 0
    set lines [list]

    lappend lines "\{"
    lappend lines "  \"mitglieder\": \["

    foreach mitglied $::mitglieder_liste {
        lassign $mitglied nachname vorname strasse plz ort festnetz mobilfunk email geburtsdatum eintrittsdatum funktion

        lappend lines "    \{"
        lappend lines "      \"nachname\": \"$nachname\","
        lappend lines "      \"vorname\": \"$vorname\","
        lappend lines "      \"geburtsdatum\": \"$geburtsdatum\","
        lappend lines "      \"strasse\": \"$strasse\","
        lappend lines "      \"plz\": \"$plz\","
        lappend lines "      \"ort\": \"$ort\","
        lappend lines "      \"festnetz\": \"$festnetz\","
        lappend lines "      \"mobilfunk\": \"$mobilfunk\","
        lappend lines "      \"email\": \"$email\","
        lappend lines "      \"eintrittsdatum\": \"$eintrittsdatum\","
        lappend lines "      \"funktion\": \"$funktion\""

        incr counter
        if {$counter < $anzahl} {
            lappend lines "    \},"
        } else {
            lappend lines "    \}"
        }
    }

    lappend lines "  \],"

    set timestamp [clock format [clock seconds] -format "%d.%m.%Y, %H:%M:%S"]
    lappend lines "  \"erstellt_am\": \"$timestamp\","
    lappend lines "  \"anzahl\": $anzahl"
    lappend lines "\}"

    set json_content [join $lines "\n"]

    set fp [open $mitglieder_json w]
    fconfigure $fp -encoding utf-8
    puts $fp $json_content
    close $fp
}
