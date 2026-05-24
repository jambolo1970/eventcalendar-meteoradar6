import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: page
    property alias cfg_calendarUrl: calendarUrl.text
    property alias cfg_calendarName: calendarName.text
    property alias cfg_weatherWidgetUrl: weatherWidgetUrl.text
    property alias cfg_forecastSiteUrl: forecastSiteUrl.text
    property alias cfg_weatherWidgetHeight: weatherWidgetHeight.value
    property alias cfg_showOfficialWidget: showOfficialWidget.checked
    property alias cfg_latitudeText: latitudeText.text
    property alias cfg_longitudeText: longitudeText.text
    property alias cfg_forecastHours: forecastHours.value
    property alias cfg_meteogramHeight: meteogramHeight.value
    property alias cfg_eventListHeight: eventListHeight.value
    property alias cfg_compactMode: compactMode.checked
    property alias cfg_keepPopupOpen: keepPopupOpen.checked
    property alias cfg_refreshMinutes: refreshMinutes.value

    QQC2.ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        Kirigami.FormLayout {
            id: form
            width: Math.max(Kirigami.Units.gridUnit * 32, parent.availableWidth - Kirigami.Units.gridUnit * 2)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Kirigami.Units.largeSpacing

            QQC2.TextField {
                id: calendarName
                Kirigami.FormData.label: i18n("Nome calendario:")
                placeholderText: i18n("Google Calendar")
                Layout.fillWidth: true
            }

            QQC2.TextArea {
                id: calendarUrl
                Kirigami.FormData.label: i18n("URL ICS/iCal:")
                placeholderText: "https://calendar.google.com/calendar/ical/.../basic.ics"
                wrapMode: TextEdit.WrapAnywhere
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
            }

            QQC2.Label {
                text: i18n("Per Google Calendar non usare il link della pagina web: serve il link .ics da Impostazioni calendario → Integra calendario → Indirizzo segreto in formato iCal.")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            QQC2.TextField {
                id: latitudeText
                Kirigami.FormData.label: i18n("Latitudine meteo:")
                placeholderText: "44.4949"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                Layout.fillWidth: true
            }
            QQC2.TextField {
                id: longitudeText
                Kirigami.FormData.label: i18n("Longitudine meteo:")
                placeholderText: "11.3426"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                Layout.fillWidth: true
            }
            QQC2.Label {
                text: i18n("Inserisci coordinate decimali, con punto o virgola. Esempio Bologna: 44.4949 / 11.3426")
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            QQC2.SpinBox { id: forecastHours; Kirigami.FormData.label: i18n("Ore nel grafico:"); from: 6; to: 24; stepSize: 1; editable: true }
            QQC2.SpinBox { id: meteogramHeight; Kirigami.FormData.label: i18n("Altezza grafico:"); from: 90; to: 260; stepSize: 10; editable: true; textFromValue: function(v){ return v + " px" }; valueFromText: function(t){ return parseInt(t) || 140 } }

            QQC2.CheckBox { id: showOfficialWidget; text: i18n("Mostra anche il widget ufficiale Meteo & Radar") }
            QQC2.TextArea {
                id: weatherWidgetUrl
                Kirigami.FormData.label: i18n("Widget Meteo & Radar:")
                placeholderText: "https://api.wo-cloud.com/content/widget/?geoObjectKey=..."
                wrapMode: TextEdit.WrapAnywhere
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
            }
            QQC2.TextArea {
                id: forecastSiteUrl
                Kirigami.FormData.label: i18n("Link sito previsioni:")
                placeholderText: "https://www.meteoeradar.it/meteo/..."
                wrapMode: TextEdit.WrapAnywhere
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
            }
            QQC2.SpinBox { id: weatherWidgetHeight; Kirigami.FormData.label: i18n("Altezza widget ufficiale:"); from: 120; to: 900; stepSize: 10; editable: true; textFromValue: function(v){ return v + " px" }; valueFromText: function(t){ return parseInt(t) || 260 } }
            QQC2.SpinBox { id: eventListHeight; Kirigami.FormData.label: i18n("Altezza lista eventi:"); from: 80; to: 500; stepSize: 10; editable: true; textFromValue: function(v){ return v + " px" }; valueFromText: function(t){ return parseInt(t) || 150 } }
            QQC2.SpinBox { id: refreshMinutes; Kirigami.FormData.label: i18n("Aggiorna ogni:"); from: 5; to: 1440; stepSize: 5; editable: true; textFromValue: function(v){ return v + " min" }; valueFromText: function(t){ return parseInt(t) || 30 } }
            QQC2.CheckBox { id: compactMode; text: i18n("Popup compatto") }
            QQC2.CheckBox { id: keepPopupOpen; text: i18n("Tieni aperto il popup quando perde il focus") }
        }
    }
}
