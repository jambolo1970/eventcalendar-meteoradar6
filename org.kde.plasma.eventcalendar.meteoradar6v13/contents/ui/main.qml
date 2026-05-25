import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import QtWebEngine

PlasmoidItem {
    id: root
    preferredRepresentation: compactRepresentation
    Plasmoid.title: i18n("Event Calendar MeteoRadar 6 V13")
    toolTipMainText: Qt.formatDateTime(new Date(), Qt.DefaultLocaleLongDate)
    toolTipSubText: nextEventsText()

    property date today: new Date()
    property date selectedDate: new Date()
    property var events: []
    property var forecast: []
    property string lastError: ""
    property string weatherError: ""
    property bool loading: false
    property bool weatherLoading: false
    property int weatherReload: 0
    property int firstDayOfWeek: Qt.locale().firstDayOfWeek

    onForecastChanged: { try { weatherCanvas.requestPaint() } catch(e) {} }

    FontLoader { id: weatherFont; source: "../fonts/weathericons-regular-webfont.ttf" }

    Timer { interval: 60000; running: true; repeat: true; onTriggered: today = new Date() }

    Timer {
        id: refreshTimer
        interval: Math.max(5, plasmoid.configuration.refreshMinutes) * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { loadCalendar(); loadWeather() }
    }

    Connections {
        target: plasmoid.configuration
        function onCalendarUrlChanged() { loadCalendar() }
        function onWeatherWidgetUrlChanged() { root.weatherReload++ }
        function onForecastSiteUrlChanged() { root.weatherReload++ }
        function onRefreshMinutesChanged() { refreshTimer.interval = Math.max(5, plasmoid.configuration.refreshMinutes) * 60000; refreshTimer.restart() }
        function onLatitudeChanged() { loadWeather() }
        function onLongitudeChanged() { loadWeather() }
        function onLatitudeTextChanged() { loadWeather() }
        function onLongitudeTextChanged() { loadWeather() }
        function onForecastHoursChanged() { loadWeather() }
    }

    compactRepresentation: MouseArea {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 3
        Layout.minimumHeight: Kirigami.Units.gridUnit * 2
        onClicked: root.expanded = !root.expanded
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            QQC2.Label { text: Qt.formatTime(root.today, Qt.locale().timeFormat(Locale.ShortFormat)); font.bold: true; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
            QQC2.Label { text: Qt.formatDate(root.today, "ddd d"); opacity: 0.8; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
        }
    }

    fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing
        Layout.minimumWidth: plasmoid.configuration.compactMode ? Kirigami.Units.gridUnit * 22 : Kirigami.Units.gridUnit * 30
        Layout.minimumHeight: plasmoid.configuration.compactMode ? Kirigami.Units.gridUnit * 30 : Kirigami.Units.gridUnit * 38

        RowLayout {
            Layout.fillWidth: true
            QQC2.Label { text: Qt.formatDate(root.today, Qt.DefaultLocaleLongDate); font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2; font.bold: true; Layout.fillWidth: true }
            QQC2.BusyIndicator { running: root.weatherLoading || root.loading; visible: running; implicitWidth: Kirigami.Units.gridUnit; implicitHeight: Kirigami.Units.gridUnit }
        }

        Rectangle {
            id: meteogramCard
            Layout.fillWidth: true
            Layout.preferredHeight: plasmoid.configuration.meteogramHeight > 0 ? plasmoid.configuration.meteogramHeight : 150
            radius: Kirigami.Units.largeSpacing
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.82)
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
            clip: true

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Kirigami.Theme.backgroundColor, 1.28) }
                GradientStop { position: 1.0; color: Qt.darker(Kirigami.Theme.backgroundColor, 1.10) }
            }

            Canvas {
                id: weatherCanvas
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                onPaint: drawMeteogram()

                function drawMeteogram() {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var w = width, h = height
                    var data = root.forecast
                    if (!data || data.length < 2) return
                    var left = 34, right = 8, top = 34, bottom = 24
                    var gw = w - left - right, gh = h - top - bottom
                    var minT = data[0].temp, maxT = data[0].temp
                    for (var i=0; i<data.length; i++) { minT = Math.min(minT, data[i].temp); maxT = Math.max(maxT, data[i].temp) }
                    minT = Math.floor(minT - 1); maxT = Math.ceil(maxT + 1); if (minT === maxT) maxT = minT + 1
                    function px(i) { return left + (data.length === 1 ? 0 : i * gw / (data.length - 1)) }
                    function py(t) { return top + gh - ((t - minT) / (maxT - minT)) * gh }

                    ctx.lineWidth = 1
                    ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                    ctx.fillStyle = Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.65)
                    ctx.font = "10px sans-serif"
                    for (var g=0; g<=3; g++) {
                        var ty = minT + (maxT-minT)*g/3
                        var y = py(ty)
                        ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(w-right, y); ctx.stroke()
                        ctx.fillText(Math.round(ty) + "°", 2, y+3)
                    }

                    var grad = ctx.createLinearGradient(0, top, 0, top+gh)
                    grad.addColorStop(0, Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.34))
                    grad.addColorStop(1, Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.03))
                    ctx.beginPath(); ctx.moveTo(px(0), top+gh)
                    for (var a=0; a<data.length; a++) ctx.lineTo(px(a), py(data[a].temp))
                    ctx.lineTo(px(data.length-1), top+gh); ctx.closePath(); ctx.fillStyle = grad; ctx.fill()

                    ctx.lineWidth = 5
                    ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.23)
                    drawCurve(ctx, data, px, py, 2)
                    ctx.lineWidth = 3
                    ctx.strokeStyle = Kirigami.Theme.highlightColor
                    drawCurve(ctx, data, px, py, 0)

                    ctx.fillStyle = Kirigami.Theme.textColor
                    ctx.font = "10px sans-serif"
                    for (var j=0; j<data.length; j+=Math.max(1, Math.floor(data.length/6))) {
                        ctx.fillText(data[j].label, px(j)-10, h-6)
                    }
                }

                function drawCurve(ctx, data, px, py, yoff) {
                    ctx.beginPath(); ctx.moveTo(px(0), py(data[0].temp)+yoff)
                    for (var i=1; i<data.length-1; i++) {
                        var xc = (px(i) + px(i+1)) / 2
                        var yc = (py(data[i].temp) + py(data[i+1].temp)) / 2 + yoff
                        ctx.quadraticCurveTo(px(i), py(data[i].temp)+yoff, xc, yc)
                    }
                    var n = data.length-1
                    ctx.quadraticCurveTo(px(n-1), py(data[n-1].temp)+yoff, px(n), py(data[n].temp)+yoff)
                    ctx.stroke()
                }
            }

            RowLayout {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label { text: i18n("Andamento temperature"); font.bold: true; Layout.fillWidth: true }
                QQC2.ToolButton { icon.name: "view-refresh"; display: QQC2.AbstractButton.IconOnly; onClicked: loadWeather() }
            }

            RowLayout {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.topMargin: Kirigami.Units.gridUnit * 1.5
                anchors.leftMargin: Kirigami.Units.gridUnit * 2.2
                anchors.rightMargin: Kirigami.Units.smallSpacing
                spacing: 2
                Repeater {
                    model: root.forecast
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.8
                        QQC2.Label { anchors.centerIn: parent; text: weatherIcon(modelData.code, modelData.isNight); font.family: weatherFont.name; font.pixelSize: Kirigami.Units.iconSizes.medium; style: Text.Outline; styleColor: Qt.rgba(0,0,0,0.35) }
                    }
                }
            }

            QQC2.Label { anchors.centerIn: parent; visible: root.forecast.length === 0 && !root.weatherLoading; text: root.weatherError.length ? root.weatherError : i18n("Nessuna previsione disponibile"); opacity: 0.75; wrapMode: Text.WordWrap; width: parent.width - Kirigami.Units.gridUnit }
        }

        Rectangle {
            visible: plasmoid.configuration.showOfficialWidget
            Layout.fillWidth: true
            Layout.preferredHeight: plasmoid.configuration.weatherWidgetHeight > 0 ? plasmoid.configuration.weatherWidgetHeight : 260
            radius: Kirigami.Units.smallSpacing
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.disabledTextColor
            clip: true
            WebEngineView {
                id: meteoRadarView
                anchors.fill: parent
                anchors.margins: 1
                url: weatherWidgetUrlWithReload()
                settings.showScrollBars: false
                zoomFactor: 1.0
            }
            QQC2.ToolButton {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.smallSpacing
                icon.name: "view-refresh"
                display: QQC2.AbstractButton.IconOnly
                onClicked: {
                    root.weatherReload++
                    meteoRadarView.reload()
                }
            }
        }


        QQC2.Button {
            visible: (plasmoid.configuration.forecastSiteUrl || "").trim().length > 0
            Layout.fillWidth: true
            text: i18n("Apri sito previsioni configurato")
            icon.name: "internet-web-browser"
            onClicked: Qt.openUrlExternally(plasmoid.configuration.forecastSiteUrl)
        }

        RowLayout {
            Layout.fillWidth: true
            QQC2.ToolButton {
                text: "‹"
                onClicked: shiftMonth(-1)
            }
            QQC2.Label {
                text: Qt.formatDate(root.selectedDate, "MMMM yyyy")
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                Layout.fillWidth: true
            }
            QQC2.ToolButton {
                text: "›"
                onClicked: shiftMonth(1)
            }
            QQC2.ToolButton {
                icon.name: "view-refresh"
                onClicked: loadCalendar()
            }
        }

        GridLayout {
            columns: 7
            Layout.fillWidth: true
            Repeater {
                model: 7
                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: weekdayName(index)
                    opacity: 0.7
                    font.bold: true
                }
            }
        }

        GridLayout {
            columns: 7
            rowSpacing: 1
            columnSpacing: 1
            Layout.fillWidth: true
            Repeater {
                model: monthCells(root.selectedDate)
                delegate: QQC2.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    text: ""
                    enabled: modelData.day > 0
                    flat: !sameDay(modelData.date, root.today)
                    highlighted: sameDay(modelData.date, root.selectedDate)
                    contentItem: ColumnLayout {
                        spacing: 0
                        QQC2.Label {
                            text: modelData.day > 0 ? modelData.day : ""
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                        QQC2.Label {
                            text: modelData.day > 0 && dayEvents(modelData.date).length > 0 ? "•" : ""
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            font.bold: true
                        }
                    }
                    onClicked: root.selectedDate = modelData.date
                }
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }
        QQC2.Label {
            text: i18n("Events for %1", Qt.formatDate(root.selectedDate, Qt.DefaultLocaleShortDate))
            font.bold: true
            Layout.fillWidth: true
        }
        QQC2.Label {
            visible: !plasmoid.configuration.calendarUrl
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Configura un URL pubblico ICS/iCal. Per Google Calendar usa l'indirizzo segreto in formato iCal.")
        }
        QQC2.Label {
            visible: root.lastError.length > 0
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.negativeTextColor
            text: root.lastError
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: plasmoid.configuration.eventListHeight > 0 ? plasmoid.configuration.eventListHeight : Kirigami.Units.gridUnit * 8
            clip: true
            model: dayEvents(root.selectedDate)
            delegate: QQC2.ItemDelegate {
                width: ListView.view.width
                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    QQC2.Label {
                        text: modelData.allDay ? "" : Qt.formatTime(modelData.start, Qt.locale().timeFormat(Locale.ShortFormat))
                        font.bold: true
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                    }
                    QQC2.Label {
                        text: modelData.summary
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        Layout.fillWidth: true
                    }
                }
                icon.name: modelData.allDay ? "view-calendar-day" : "appointment-new"
            }
            QQC2.Label {
                anchors.centerIn: parent
                visible: parent.count === 0 && plasmoid.configuration.calendarUrl && !root.loading && root.lastError.length === 0
                text: i18n("No events")
                opacity: 0.7
            }
        }
    }

    function shiftMonth(delta) { root.selectedDate = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth() + delta, 1) }
    function weekdayName(i) { var base = new Date(2023, 0, 1 + ((root.firstDayOfWeek + i) % 7)); return Qt.formatDate(base, "ddd") }
    function monthCells(d) { var y=d.getFullYear(), m=d.getMonth(), days=new Date(y,m+1,0).getDate(), offset=(new Date(y,m,1).getDay()-root.firstDayOfWeek+7)%7, arr=[]; for(var i=0;i<offset;i++) arr.push({day:0,date:new Date(y,m,1)}); for(var day=1;day<=days;day++) arr.push({day:day,date:new Date(y,m,day)}); while(arr.length%7!==0) arr.push({day:0,date:new Date(y,m,days)}); return arr }
    function sameDay(a,b) { return a && b && a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate() }
    function dayEvents(day) { var out=[]; for(var i=0;i<root.events.length;i++){ var e=root.events[i]; if(sameDay(e.start,day)) out.push(e) } out.sort(function(a,b){return a.start-b.start}); return out }
    function nextEventsText() { var now=new Date(); var future=root.events.filter(function(e){return e.start>=now}).slice(0,3); if(future.length===0) return i18n("No upcoming online events"); return future.map(function(e){return Qt.formatDate(e.start,Qt.DefaultLocaleShortDate)+" "+e.summary}).join("\n") }

    function loadCalendar() { var url=plasmoid.configuration.calendarUrl; root.lastError=""; if(!url || url.trim().length===0){root.events=[]; return}; root.loading=true; var xhr=new XMLHttpRequest(); xhr.onreadystatechange=function(){ if(xhr.readyState===XMLHttpRequest.DONE){ root.loading=false; if(xhr.status===0 || (xhr.status>=200 && xhr.status<300)){ try{root.events=parseIcs(xhr.responseText)} catch(e){root.lastError=i18n("Calendar parse error: %1", e); root.events=[]} } else {root.lastError=i18n("Calendar download failed: HTTP %1", xhr.status); root.events=[]} } }; try{xhr.open("GET",url); xhr.send()} catch(e){root.loading=false; root.lastError=i18n("Calendar URL error: %1", e); root.events=[]} }
    function unfoldIcs(text) { return text.replace(/\r\n/g,"\n").replace(/\n[ \t]/g,"") }
    function parseIcs(text) { var clean=unfoldIcs(text), blocks=clean.split("BEGIN:VEVENT"), parsed=[]; for(var i=1;i<blocks.length;i++){ var block=blocks[i].split("END:VEVENT")[0], summary=readIcsField(block,"SUMMARY") || i18n("Untitled"), dtstart=readIcsField(block,"DTSTART"), dtend=readIcsField(block,"DTEND"); if(!dtstart) continue; var start=parseIcsDate(dtstart), end=dtend?parseIcsDate(dtend):start; parsed.push({summary:decodeIcsText(summary), start:start, end:end, allDay:dtstart.length===8}) } return parsed }
    function readIcsField(block,name) { var re=new RegExp("^"+name+"(?:;[^:]*)?:(.*)$","m"); var match=block.match(re); return match ? match[1].trim() : "" }
    function decodeIcsText(s) { return s.replace(/\\n/g," ").replace(/\\,/g,",").replace(/\\;/g,";").replace(/\\\\/g,"\\") }
    function parseIcsDate(v) { if(v.length===8) return new Date(parseInt(v.substr(0,4)),parseInt(v.substr(4,2))-1,parseInt(v.substr(6,2))); var y=parseInt(v.substr(0,4)), mo=parseInt(v.substr(4,2))-1, d=parseInt(v.substr(6,2)), h=parseInt(v.substr(9,2)||"0"), mi=parseInt(v.substr(11,2)||"0"), s=parseInt(v.substr(13,2)||"0"); if(v.charAt(v.length-1)==="Z") return new Date(Date.UTC(y,mo,d,h,mi,s)); return new Date(y,mo,d,h,mi,s) }

    function withReloadParameter(u) {
        if (!u || String(u).trim().length === 0) {
            return "about:blank"
        }
        var clean = String(u).trim()
        var sep = clean.indexOf("?") >= 0 ? "&" : "?"
        return clean + sep + "_plasmaReload=" + root.weatherReload
    }

    function weatherWidgetUrlWithReload() {
        var u = plasmoid.configuration.weatherWidgetUrl || "https://api.wo-cloud.com/content/widget/?geoObjectKey=13229380&language=it&region=IT&timeFormat=HH:mm&windUnit=kmh&systemOfMeasurement=metric&temperatureUnit=celsius"
        return withReloadParameter(u)
    }

    function parseCoordinate(textValue, intValue, fallbackInt) {
        var raw = textValue ? String(textValue).trim().replace(',', '.') : ""
        if (raw.length > 0) {
            var parsed = Number(raw)
            if (!isNaN(parsed)) {
                return parsed
            }
        }
        var v = intValue || fallbackInt
        return v / 10000.0
    }

    function weatherApiUrl() {
        var lat = parseCoordinate(plasmoid.configuration.latitudeText, plasmoid.configuration.latitude, 444949)
        var lon = parseCoordinate(plasmoid.configuration.longitudeText, plasmoid.configuration.longitude, 113426)
        return "https://api.open-meteo.com/v1/forecast?latitude=" + encodeURIComponent(lat) + "&longitude=" + encodeURIComponent(lon) + "&hourly=temperature_2m,precipitation_probability,weather_code&forecast_days=2&timezone=auto"
    }
    function loadWeather() { root.weatherError=""; root.weatherLoading=true; var xhr=new XMLHttpRequest(); xhr.onreadystatechange=function(){ if(xhr.readyState===XMLHttpRequest.DONE){ root.weatherLoading=false; if(xhr.status===0 || (xhr.status>=200 && xhr.status<300)){ try{parseWeather(JSON.parse(xhr.responseText))} catch(e){root.weatherError=i18n("Errore meteo: %1", e); root.forecast=[]} } else {root.weatherError=i18n("Download meteo fallito: HTTP %1", xhr.status); root.forecast=[]} } }; try{xhr.open("GET", weatherApiUrl()); xhr.send()} catch(e){root.weatherLoading=false; root.weatherError=i18n("URL meteo non valido: %1", e); root.forecast=[]} }
    function parseWeather(json) { var out=[], times=json.hourly.time, temps=json.hourly.temperature_2m, codes=json.hourly.weather_code; var now=new Date(), max=Math.max(6, Math.min(24, plasmoid.configuration.forecastHours || 12)); for(var i=0;i<times.length && out.length<max;i++){ var t=new Date(times[i]); if(t >= now || out.length>0){ out.push({time:t, label:Qt.formatTime(t,"HH"), temp:temps[i], code:codes[i], isNight:(t.getHours()<7 || t.getHours()>20)}) } } root.forecast=out }
    function weatherIcon(code, night) { if(code===0) return night ? "\uf02e" : "\uf00d"; if(code===1 || code===2) return night ? "\uf086" : "\uf002"; if(code===3) return "\uf013"; if(code===45 || code===48) return "\uf014"; if(code>=51 && code<=57) return "\uf0b5"; if(code>=61 && code<=67) return night ? "\uf028" : "\uf008"; if(code>=71 && code<=77) return "\uf01b"; if(code>=80 && code<=82) return night ? "\uf029" : "\uf009"; if(code>=85 && code<=86) return night ? "\uf038" : "\uf00a"; if(code>=95) return night ? "\uf025" : "\uf010"; return "?" }
}
