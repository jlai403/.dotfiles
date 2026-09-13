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

      // Every slot is a plain number/letter at Style.font.body (uniform size
      // everywhere); the focused slot adds a filled rounded accent box behind
      // the character, drawn in the bar's contrast foreground.
      Item {
        id: slot
        required property var modelData

        readonly property var workspace: modelData
        readonly property bool numbered: root.isNumbered(workspace.name)
        readonly property bool focused: workspace.focused

        implicitWidth: Style.space(20)
        implicitHeight: root.barSize

        Rectangle {
          anchors.fill: parent
          visible: slot.focused
          color: Color.accent
        }

        Rectangle {
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          height: Style.space(2)
          visible: slot.focused
          color: Color.muted
        }

        WidgetButton {
          anchors.fill: parent
          bar: root.bar
          text: slot.numbered ? (slot.workspace.id === 10 ? "0" : String(slot.workspace.id)) : slot.workspace.name
          foreground: slot.focused
            ? (root.bar ? root.bar.background : Color.background)
            : (root.bar ? root.bar.barForeground : Color.foreground)
          opacity: slot.focused || slot.workspace.toplevels.values.length > 0 ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: Style.space(20)
          fixedHeight: root.barSize
          onPressed: function() { root.focusWorkspace(slot.workspace) }
        }
      }
    }
  }
}