import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root

  moduleName: "jlai.stats"
  ipcTarget: "jlai.stats"

  // ---------------------------------------------------------------- theme
  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color graphColor: Color.accent
  readonly property color graphFill: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16)
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color track: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool vertical: bar ? bar.vertical : false

  // ---------------------------------------------------------------- data
  readonly property var s: sampler.latest
  readonly property bool hasData: !!s && s.cpu !== undefined
  readonly property int cpuPct: hasData ? s.cpu : 0
  readonly property int ramPct: hasData && s.ram ? s.ram.pct : 0
  readonly property int diskPct: hasData && s.disk ? s.disk.pct : 0
  readonly property int tempC: hasData && s.temp !== undefined ? s.temp : -1
  readonly property var cores: hasData && s.cores ? s.cores : []

  readonly property bool cpuDanger: cpuPct > 80
  readonly property bool ramDanger: ramPct > 80
  readonly property bool diskDanger: diskPct > 90
  readonly property bool tempDanger: tempC > 90

  readonly property var tempSeries: sampler.series("temp")
  readonly property int tempMin: tempSeries.length ? Math.min.apply(null, tempSeries) : tempC
  readonly property int tempMax: tempSeries.length ? Math.max.apply(null, tempSeries) : tempC
  readonly property var ioSeries: sampler.series("io")

  function fmtRate(bytes) {
    var b = Number(bytes || 0)
    if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
    if (b >= 1024) return (b / 1024).toFixed(0) + " KB/s"
    return b.toFixed(0) + " B/s"
  }

  function fmtUptime(sec) {
    if (sec === undefined || sec === null) return "—"
    var d = Math.floor(sec / 86400)
    var h = Math.floor((sec % 86400) / 3600)
    var m = Math.floor((sec % 3600) / 60)
    return (d > 0 ? d + "d " : "") + h + "h " + m + "m"
  }

  function fmtLoad() {
    if (!hasData || !s.load) return "—"
    return s.load.map(function(v) { return Number(v).toFixed(2) }).join("  ")
  }

  function barTooltip() {
    if (!hasData) return "System stats loading…"
    return "CPU " + cpuPct + "%   RAM " + ramPct + "%   DISK " + diskPct + "%   TEMP "
      + (tempC >= 0 ? tempC + "°C" : "—") + "\nClick for details"
  }

  function samplerTop(kind) {
    if (!sampler.topProcs || !sampler.topProcs[kind]) return []
    return sampler.topProcs[kind]
  }

  implicitWidth: barRow.implicitWidth + Style.space(12)
  implicitHeight: bar ? bar.barSize : Style.space(26)

  Sampler { id: sampler }

  Timer {
    interval: 3000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: sampler.refreshTop()
  }

  onOpenedChanged: if (opened) Qt.callLater(function() { keyCatcher.forceActiveFocus() })

  // ---------------------------------------------------------------- bar row
  Row {
    id: barRow
    anchors.centerIn: parent
    spacing: Style.space(10)
    visible: !root.vertical

    component Metric: Row {
      id: metric
      property string icon
      property string text
      property bool danger: false
      property var spark: []
      property real low: 0
      property real high: 100

      spacing: Style.space(3)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: metric.icon
        color: metric.danger ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: metric.text
        color: metric.danger ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
      }

      Sparkline {
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(20)
        height: Style.space(11)
        mode: "bars"
        values: metric.spark
        valueMin: metric.low
        valueMax: metric.high
        lineColor: metric.danger ? root.urgent : root.graphColor
      }
    }

    Metric {
      icon: "󰻠"
      text: root.cpuPct + "%"
      danger: root.cpuDanger
      spark: sampler.series("cpu", 40)
    }

    Metric {
      icon: "󰍛"
      text: root.ramPct + "%"
      danger: root.ramDanger
      spark: sampler.series("ram", 40)
    }

    Metric {
      icon: "󰋊"
      text: root.diskPct + "%"
      danger: root.diskDanger
      spark: sampler.series("disk", 40)
    }

    Metric {
      icon: "󰔄"
      text: root.tempC >= 0 ? root.tempC + "°" : "—"
      danger: root.tempDanger
      spark: sampler.series("temp", 40)
      low: 30
      high: 100
    }
  }

  // Vertical bars have no room for sparklines: keep one glyph as the handle.
  Text {
    id: verticalIcon
    anchors.centerIn: parent
    visible: root.vertical
    text: "󰻠"
    color: root.cpuDanger ? root.urgent : root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
  }

  MouseArea {
    id: barMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onClicked: root.toggle()
    onContainsMouseChanged: {
      if (!root.bar) return
      if (containsMouse) root.bar.showTooltip(barRow, root.barTooltip())
      else root.bar.hideTooltip(barRow)
    }
  }

  // ---------------------------------------------------------------- popup
  KeyboardPanel {
    id: panel
    anchorItem: barRow
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(2000))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) {
        if (dy !== 0)
          flick.contentY = Math.max(0, Math.min(
            flick.contentY + dy * Style.space(56),
            Math.max(0, flick.contentHeight - flick.height)))
      }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(14)

          // ------------------------------------------------ CPU
          Section {
            title: "CPU"

            Item {
              width: parent.width
              implicitHeight: heroCpuValue.implicitHeight

              Text {
                id: heroCpuValue
                text: root.cpuPct + "%"
                color: root.cpuDanger ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }

              Text {
                anchors.right: parent.right
                anchors.baseline: heroCpuValue.baseline
                text: "load  " + root.fmtLoad()
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }

            Sparkline {
              width: parent.width
              height: Style.space(56)
              values: sampler.series("cpu")
              valueMin: 0
              valueMax: 100
              lineColor: root.graphColor
              fillColor: root.graphFill
            }

            Grid {
              id: coreGrid
              width: parent.width
              columns: 2
              columnSpacing: Style.space(18)
              rowSpacing: Style.space(4)

              Repeater {
                model: root.cores

                CoreRow {
                  required property var modelData
                  required property int index
                  width: (coreGrid.width - coreGrid.columnSpacing) / 2
                  coreIndex: index
                  pct: modelData
                }
              }
            }

            KV { label: "Uptime"; value: root.fmtUptime(root.s ? root.s.uptime : undefined) }

            ProcList {
              width: parent.width
              heading: "Top CPU"
              rows: root.samplerTop("cpu")
            }
          }

          Separator {}

          // ------------------------------------------------ Memory
          Section {
            title: "Memory"

            Item {
              width: parent.width
              implicitHeight: heroMemValue.implicitHeight

              Text {
                id: heroMemValue
                text: root.ramPct + "%"
                color: root.ramDanger ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }

              Text {
                anchors.right: parent.right
                anchors.baseline: heroMemValue.baseline
                text: root.hasData ? root.s.ram.used + " / " + root.s.ram.total + " GiB" : "—"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }

            Sparkline {
              width: parent.width
              height: Style.space(56)
              values: sampler.series("ram")
              valueMin: 0
              valueMax: 100
              lineColor: root.graphColor
              fillColor: root.graphFill
            }

            KV {
              label: "Swap"
              value: root.hasData ? root.s.ram.swapUsed + " / " + root.s.ram.swapTotal + " GiB" : "—"
            }
            KV {
              label: "Cached"
              value: root.hasData ? root.s.ram.cached + " GiB" : "—"
            }

            ProcList {
              width: parent.width
              heading: "Top Memory"
              rows: root.samplerTop("mem")
            }
          }

          Separator {}

          // ------------------------------------------------ Disk
          Section {
            title: "Disk"

            Item {
              width: parent.width
              implicitHeight: heroDiskValue.implicitHeight

              Text {
                id: heroDiskValue
                text: root.diskPct + "%"
                color: root.diskDanger ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }

              Text {
                anchors.right: parent.right
                anchors.baseline: heroDiskValue.baseline
                text: root.hasData ? root.s.disk.mount : "—"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }

            Meter {
              width: parent.width
              value: root.diskPct / 100
              fillColor: root.diskDanger ? root.urgent : root.graphColor
            }

            KV {
              label: "Used"
              value: root.hasData ? root.s.disk.used + " / " + root.s.disk.total + " GiB" : "—"
            }
            KV {
              label: "Free"
              value: root.hasData ? root.s.disk.free + " GiB" : "—"
            }

            Text {
              textFormat: Text.PlainText
              text: "Activity"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Sparkline {
              width: parent.width
              height: Style.space(44)
              values: root.ioSeries
              autoScale: true
              lineColor: root.graphColor
              fillColor: root.graphFill
            }

            KV {
              label: "Peak I/O"
              value: root.ioSeries.length ? root.fmtRate(Math.max.apply(null, root.ioSeries)) : "—"
            }
          }

          Separator {}

          // ------------------------------------------------ Temperature
          Section {
            title: "Temperature"

            Item {
              width: parent.width
              implicitHeight: heroTempValue.implicitHeight

              Text {
                id: heroTempValue
                text: root.tempC >= 0 ? root.tempC + "°C" : "—"
                color: root.tempDanger ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
                font.bold: true
              }

              Text {
                anchors.right: parent.right
                anchors.baseline: heroTempValue.baseline
                text: root.tempC >= 0 ? "min " + root.tempMin + "°  max " + root.tempMax + "°" : ""
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
              }
            }

            Sparkline {
              width: parent.width
              height: Style.space(56)
              values: root.tempSeries
              autoScale: true
              lineColor: root.graphColor
              fillColor: root.graphFill
            }
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------- parts
  component Section: Column {
    id: section
    property string title
    default property alias body: inner.data
    width: parent ? parent.width : implicitWidth
    spacing: Style.space(8)

    PanelSectionHeader {
      text: section.title
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Column {
      id: inner
      width: parent.width
      spacing: Style.space(8)
    }
  }

  component Separator: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: root.dim
    opacity: 0.3
  }

  component KV: Item {
    id: kv
    property string label
    property string value
    property color valueColor: root.foreground
    width: parent ? parent.width : implicitWidth
    implicitHeight: Math.max(kvLabel.implicitHeight, kvValue.implicitHeight)

    Text {
      id: kvLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: kv.label
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      id: kvValue
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: kv.value
      color: kv.valueColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  component Meter: Item {
    id: meter
    property real value: 0
    property color fillColor: root.foreground
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
    implicitHeight: thickness

    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      height: parent.height
      radius: height / 2
      width: parent.width * Math.max(0, Math.min(1, meter.value))
      color: meter.fillColor
      Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
  }

  component CoreRow: Item {
    id: core
    property int coreIndex: 0
    property int pct: 0
    implicitHeight: Math.max(coreLabel.implicitHeight, Style.space(14))

    Text {
      id: coreLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(48)
      textFormat: Text.PlainText
      text: "Core " + core.coreIndex
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Meter {
      anchors.left: coreLabel.right
      anchors.right: corePct.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      height: Style.space(5)
      value: core.pct / 100
      fillColor: core.pct > 80 ? root.urgent : root.graphColor
    }

    Text {
      id: corePct
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: core.pct + "%"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  component ProcList: Column {
    id: procList
    property string heading
    property var rows: []
    spacing: Style.space(4)

    Text {
      visible: procList.rows.length > 0
      textFormat: Text.PlainText
      text: procList.heading
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Repeater {
      model: procList.rows

      Item {
        id: procRow
        required property var modelData
        width: procList.width
        implicitHeight: Math.max(procName.implicitHeight, procVal.implicitHeight)

        Text {
          id: procName
          anchors.left: parent.left
          anchors.right: procVal.left
          anchors.rightMargin: Style.space(10)
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: procRow.modelData.name
          elide: Text.ElideRight
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          id: procVal
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          text: Number(procRow.modelData.cpu).toFixed(1) + "%   " + Number(procRow.modelData.mem).toFixed(1) + "%"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
