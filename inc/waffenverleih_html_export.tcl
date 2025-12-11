# =============================================================================
# Waffenverleih-HTML-Export
# Generiert HTML-Dokumente für Waffenverleih-Formulare
# =============================================================================

# Namespace für HTML-Export
namespace eval ::waffenverleih::export {
    # Keine persistenten Variablen
}

# =============================================================================
# Prozedur: html_escape
# Escaped HTML-Sonderzeichen für sichere Ausgabe
# Parameter:
#   text - Der zu escapende Text
# Rückgabe: Escaped Text
# =============================================================================
proc ::waffenverleih::export::html_escape {text} {
    set text [string map {& &amp; < &lt; > &gt; \" &quot; ' &#39;} $text]
    return $text
}

# =============================================================================
# Prozedur: erstelle_html_dokument
# Erstellt das HTML-Dokument aus den Formulardaten
# Parameter:
#   data_dict - Dict mit allen Formulardaten
# Rückgabe: HTML-String
# =============================================================================
proc ::waffenverleih::export::erstelle_html_dokument {data_dict} {
    # Daten aus Dict extrahieren
    set waffen [dict get $data_dict waffen]
    set typ_leihe [dict get $data_dict typ_leihe]
    set typ_verwahrung [dict get $data_dict typ_verwahrung]
    set typ_transport [dict get $data_dict typ_transport]
    set typ_vereinsbeauftragter [dict get $data_dict typ_vereinsbeauftragter]
    set wbk_erforderlich [dict get $data_dict wbk_erforderlich]

    set besitzer_name [dict get $data_dict besitzer_name]
    set besitzer_vorname [dict get $data_dict besitzer_vorname]
    set besitzer_geburtsdatum [dict get $data_dict besitzer_geburtsdatum]
    set besitzer_geburtsort [dict get $data_dict besitzer_geburtsort]
    set besitzer_strasse [dict get $data_dict besitzer_strasse]
    set besitzer_hausnummer [dict get $data_dict besitzer_hausnummer]
    set besitzer_plz [dict get $data_dict besitzer_plz]
    set besitzer_ort [dict get $data_dict besitzer_ort]
    set besitzer_wbk_nummer [dict get $data_dict besitzer_wbk_nummer]
    set besitzer_wbk_behoerde [dict get $data_dict besitzer_wbk_behoerde]

    set ueberlasser_name [dict get $data_dict ueberlasser_name]
    set ueberlasser_strasse [dict get $data_dict ueberlasser_strasse]
    set ueberlasser_plz [dict get $data_dict ueberlasser_plz]
    set ueberlasser_ort [dict get $data_dict ueberlasser_ort]
    set ueberlasser_tel [dict get $data_dict ueberlasser_tel]
    set ueberlasser_email [dict get $data_dict ueberlasser_email]
    set ueberlasser_register [dict get $data_dict ueberlasser_register]

    # Verleihtypen-Text erstellen
    set loan_types_list [list]
    if {$typ_leihe} { lappend loan_types_list "Leihe" }
    if {$typ_verwahrung} { lappend loan_types_list "Verwahrung" }
    if {$typ_transport} { lappend loan_types_list "Gewerblicher Transport" }
    if {$typ_vereinsbeauftragter} { lappend loan_types_list "Vereinsbeauftragter" }
    set loan_types_text [join $loan_types_list ", "]

    # WBK-Status-Text
    if {$wbk_erforderlich} {
        set wbk_status_text "WBK für vorübergehenden Besitzer erforderlich"
    } else {
        set wbk_status_text "WBK für vorübergehenden Besitzer nicht erforderlich"
    }

    # Aktuelles Datum
    set heute [clock format [clock seconds] -format "%d.%m.%Y"]

    # HTML-String aufbauen
    set html "<!DOCTYPE html>\n"
    append html "<html lang=\"de\">\n"
    append html "<head>\n"
    append html "  <meta charset=\"UTF-8\">\n"
    append html "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
    append html "  <title>Waffenverleihformular</title>\n"
    append html "  <style>\n"

    # CSS für amtliches Aussehen und A4-Druck
    append html "    body {\n"
    append html "      font-family: Arial, sans-serif;\n"
    append html "      font-size: 11pt;\n"
    append html "      line-height: 1.4;\n"
    append html "      max-width: 800px;\n"
    append html "      margin: 0 auto;\n"
    append html "      padding: 20px;\n"
    append html "    }\n"
    append html "    @media print {\n"
    append html "      body {\n"
    append html "        width: 210mm;\n"
    append html "        height: 297mm;\n"
    append html "        margin: 0;\n"
    append html "        padding: 20mm;\n"
    append html "      }\n"
    append html "    }\n"
    append html "    h1 {\n"
    append html "      text-align: center;\n"
    append html "      font-size: 16pt;\n"
    append html "      margin-bottom: 30px;\n"
    append html "      border-bottom: 2px solid #333;\n"
    append html "      padding-bottom: 10px;\n"
    append html "    }\n"
    append html "    .section {\n"
    append html "      margin-bottom: 25px;\n"
    append html "    }\n"
    append html "    .section-title {\n"
    append html "      font-size: 13pt;\n"
    append html "      font-weight: bold;\n"
    append html "      margin-bottom: 10px;\n"
    append html "      border-bottom: 1px solid #666;\n"
    append html "      padding-bottom: 5px;\n"
    append html "    }\n"
    append html "    table {\n"
    append html "      width: 100%;\n"
    append html "      border-collapse: collapse;\n"
    append html "      margin-bottom: 15px;\n"
    append html "    }\n"
    append html "    td {\n"
    append html "      padding: 5px;\n"
    append html "      vertical-align: top;\n"
    append html "    }\n"
    append html "    .label {\n"
    append html "      font-weight: bold;\n"
    append html "      width: 180px;\n"
    append html "    }\n"
    append html "    .weapon-list {\n"
    append html "      margin-left: 20px;\n"
    append html "      margin-bottom: 10px;\n"
    append html "    }\n"
    append html "    .signature-line {\n"
    append html "      margin-top: 50px;\n"
    append html "      border-top: 1px solid #000;\n"
    append html "      width: 300px;\n"
    append html "      padding-top: 5px;\n"
    append html "      text-align: center;\n"
    append html "    }\n"
    append html "  </style>\n"
    append html "</head>\n"
    append html "<body>\n"

    # Überschrift
    append html "  <h1>Waffenverleihformular</h1>\n"

    # SEKTION 1: Vereins-Kopf
    append html "  <div class=\"section\">\n"
    append html "    <table>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Verein:</td>\n"
    append html "        <td>[html_escape $ueberlasser_name]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Adresse:</td>\n"
    append html "        <td>[html_escape $ueberlasser_strasse], [html_escape $ueberlasser_plz] [html_escape $ueberlasser_ort]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Kontakt:</td>\n"
    append html "        <td>Tel: [html_escape $ueberlasser_tel], E-Mail: [html_escape $ueberlasser_email]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Registereintrag:</td>\n"
    append html "        <td>[html_escape $ueberlasser_register]</td>\n"
    append html "      </tr>\n"
    append html "    </table>\n"
    append html "  </div>\n"

    # SEKTION 2: Verleihgrund und WBK-Status
    append html "  <div class=\"section\">\n"
    append html "    <div class=\"section-title\">Art des Verleihs</div>\n"
    append html "    <div>$loan_types_text</div>\n"
    append html "    <div><strong>$wbk_status_text</strong></div>\n"
    append html "  </div>\n"

    # SEKTION 3: Waffen
    append html "  <div class=\"section\">\n"
    append html "    <div class=\"section-title\">Verliehene Waffen</div>\n"
    append html "    <div class=\"weapon-list\">\n"

    foreach waffe $waffen {
        set art [html_escape [dict get $waffe art]]
        set kaliber [html_escape [dict get $waffe kaliber]]
        set seriennr [html_escape [dict get $waffe seriennummer]]
        set wbk_nr [html_escape [dict get $waffe wbk_nummer]]

        append html "      <div>\u2022 $art - $kaliber (Ser: $seriennr, WBK: $wbk_nr)</div>\n"
    }

    append html "    </div>\n"
    append html "  </div>\n"

    # SEKTION 4: Vorübergehender Besitzer
    append html "  <div class=\"section\">\n"
    append html "    <div class=\"section-title\">Vorübergehender Besitzer</div>\n"
    append html "    <table>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Name:</td>\n"
    append html "        <td>[html_escape $besitzer_name] [html_escape $besitzer_vorname]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Geboren:</td>\n"
    append html "        <td>[html_escape $besitzer_geburtsdatum] in [html_escape $besitzer_geburtsort]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Adresse:</td>\n"
    append html "        <td>[html_escape $besitzer_strasse] [html_escape $besitzer_hausnummer], [html_escape $besitzer_plz] [html_escape $besitzer_ort]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">WBK-Nummer:</td>\n"
    append html "        <td>[html_escape $besitzer_wbk_nummer]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Ausstellende Behörde:</td>\n"
    append html "        <td>[html_escape $besitzer_wbk_behoerde]</td>\n"
    append html "      </tr>\n"
    append html "    </table>\n"
    append html "  </div>\n"

    # SEKTION 4a: Empfangsbestätigung
    append html "  <div class=\"section\">\n"
    append html "    <p><strong>Waffe erhalten:</strong></p>\n"
    append html "    <table style=\"margin-top: 10px;\">\n"
    append html "      <tr>\n"
    append html "        <td style=\"width: 50%; padding-right: 20px;\">\n"
    append html "          Datum: _______________________\n"
    append html "        </td>\n"
    append html "        <td style=\"width: 50%;\">\n"
    append html "          Unterschrift: _______________________\n"
    append html "        </td>\n"
    append html "      </tr>\n"
    append html "    </table>\n"
    append html "  </div>\n"

    # SEKTION 5: Überlasser (Details)
    append html "  <div class=\"section\">\n"
    append html "    <div class=\"section-title\">Überlasser</div>\n"
    append html "    <table>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Verein:</td>\n"
    append html "        <td>[html_escape $ueberlasser_name]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Adresse:</td>\n"
    append html "        <td>[html_escape $ueberlasser_strasse], [html_escape $ueberlasser_plz] [html_escape $ueberlasser_ort]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Kontakt:</td>\n"
    append html "        <td>Tel: [html_escape $ueberlasser_tel], E-Mail: [html_escape $ueberlasser_email]</td>\n"
    append html "      </tr>\n"
    append html "      <tr>\n"
    append html "        <td class=\"label\">Registereintrag:</td>\n"
    append html "        <td>[html_escape $ueberlasser_register]</td>\n"
    append html "      </tr>\n"
    append html "    </table>\n"
    append html "  </div>\n"

    # SEKTION 6: Unterschrift
    append html "  <div class=\"section\">\n"
    append html "    <p>Datum: $heute</p>\n"
    append html "    <div class=\"signature-line\">\n"
    append html "      Unterschrift und Stempel\n"
    append html "    </div>\n"
    append html "  </div>\n"

    append html "</body>\n"
    append html "</html>\n"

    return $html
}

# =============================================================================
# Prozedur: exportiere_html
# Hauptprozedur für HTML-Export
# Öffnet Datei-Auswahl-Dialog und speichert HTML-Datei
# Parameter:
#   parent_window - Parent-Fenster für den Dialog
#   data_dict - Dict mit allen Formulardaten
# =============================================================================
proc ::waffenverleih::export::exportiere_html {parent_window data_dict} {
    # Datei-Auswahl-Dialog öffnen
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d"]

    set filename [tk_getSaveFile \
        -parent $parent_window \
        -title "HTML-Formular speichern" \
        -defaultextension ".html" \
        -filetypes {{"HTML-Dateien" {.html}} {"Alle Dateien" {*}}} \
        -initialfile "Waffenverleih-${timestamp}.html"]

    # Prüfen ob Benutzer abgebrochen hat
    if {$filename eq ""} {
        return
    }

    # HTML-Dokument erstellen
    set html [erstelle_html_dokument $data_dict]

    # Datei schreiben
    if {[catch {
        set fh [open $filename w]
        fconfigure $fh -encoding utf-8
        puts $fh $html
        close $fh
    } err]} {
        tk_messageBox -parent $parent_window -icon error -title "Fehler" \
            -message "Fehler beim Speichern der HTML-Datei:\n$err"
        return
    }

    # Erfolgs-Nachricht
    tk_messageBox -parent $parent_window -icon info -title "Erfolg" \
        -message "Das Waffenverleihformular wurde erfolgreich als HTML exportiert:\n\n$filename"
}
