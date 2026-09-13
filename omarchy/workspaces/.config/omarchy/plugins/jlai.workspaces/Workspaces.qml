import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function isNumbered(name) {
    return /^[0-9]+$/.test(String(name))
  }

  // Material Design "boxed" glyphs (Supplementary PUA, so encoded as surrogate
  // pairs): a filled rounded square with the digit/letter knocked out, so the
  // active slot shows the character *inside* the highlight. Digits 0-9 + 10;
  // letters a-z are contiguous from 0xF0B08.
  readonly property var digitBox: ({
    0: 0xF03A1, 1: 0xF03A4, 2: 0xF03A7, 3: 0xF03AA, 4: 0xF03AD,
    5: 0xF03B1, 6: 0xF03B3, 7: 0xF03B6, 8: 0xF03B9, 9: 0xF03BC,
    10: 0xF0F7D
  })

  function glyph(cp) {
    if (cp <= 0xFFFF) return String.fromCharCode(cp)
    cp -= 0x10000
    return String.fromCharCode(0xD800 + (cp >> 10), 0xDC00 + (cp & 0x3FF))
  }

  function boxedGlyph(ws) {
    if (isNumbered(ws.name)) {
      var cp = digitBox[ws.id]
      return cp ? glyph(cp) : String(ws.id)
    }
    var index = String(ws.name).toLowerCase().charCodeAt(0) - 97
    return index >= 0 && index < 26 ? glyph(0xF0B08 + index) : ws.name
  }

  // Numbered workspaces that currently hold windows, ascending, plus the
  // focused workspace so the active slot is always visible. Named (lettered)
  // workspaces only appear while focused — they carry no fixed number to pin.
  readonly property var shownWorkspaces: {
    var list = []
    var seen = ({})
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var ws = values[i]
      if (!isNumbered(ws.name) || ws.toplevels.values.length === 0) continue
      list.push(ws)
      seen[ws.name] = true
    }

    var focusedWs = Hyprland.focusedWorkspace
    if (focusedWs && !seen[focusedWs.name]) list.push(focusedWs)

    list.sort(function(left, right) {
      var leftNumbered = isNumbered(left.name)
      var rightNumbered = isNumbered(right.name)
      if (leftNumbered && rightNumbered) return left.id - right.id
      if (leftNumbered) return -1
      if (rightNumbered) return 1
      return 0
    })

    return list
  }

  function focusWorkspace(ws) {
    if (!root.bar || !ws) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + ws.name + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : Math.max(1, root.shownWorkspaces.length)
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.shownWorkspaces

      WidgetButton {
        required property var modelData

        readonly property var workspace: modelData
        readonly property bool numbered: root.isNumbered(workspace.name)

        bar: root.bar
        text: workspace.focused
          ? root.boxedGlyph(workspace)
          : (numbered ? (workspace.id === 10 ? "0" : String(workspace.id)) : workspace.name)
        opacity: workspace.focused || workspace.toplevels.values.length > 0 ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(workspace) }
      }
    }
  }
}
