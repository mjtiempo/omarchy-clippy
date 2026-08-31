import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Clipboard history popup, anchored to the bar button. Reads the same
// history file the omarchy.clipboard overlay plugin writes (its wl-paste
// watchers do the capturing); this panel is read-only UI.
Panel {
  id: root
  moduleName: "mark.clippy"
  ipcTarget: "mark.clippy"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var history: []
  // Row the mouse is over — drives the hover indicator. Mouse leaves don't
  // clear it (same convention as the network list: cursor stays where the
  // mouse last was).
  property int hoverIndex: -1

  function parseHistory(raw) {
    try {
      var parsed = JSON.parse(String(raw || "[]"))
      return Array.isArray(parsed) ? parsed : []
    } catch (e) { return [] }
  }

  FileView {
    id: historyFile
    path: Quickshell.env("HOME") + "/.local/state/omarchy/clipboard-history.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.history = root.parseHistory(text())
    onLoadFailed: root.history = []
    onFileChanged: reload()
  }

  function open() {
    root.controller.show()
  }

  function close() {
    root.controller.hide()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  // Copy the entry back to the clipboard (same tools the overlay uses) and
  // close the panel, ready to paste.
  function copyIndex(i) {
    var entry = root.history[i]
    if (!entry) return
    if (entry.type === "image")
      Quickshell.execDetached([root.omarchyPath + "/bin/omarchy-clipboard-paste-file", "--copy-only", String(entry.mime || "image/png"), String(entry.path)])
    else
      Quickshell.execDetached([root.omarchyPath + "/bin/omarchy-clipboard-paste-text", "--copy-only", "--history-index", String(i)])
    root.close()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(Math.min(Style.space(520), root.history.length * Style.space(48) + panel.padding * 2))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }

    ListView {
      id: list
      anchors.fill: parent
      clip: true
      model: root.history
      spacing: 2

      // Empty state
      Rectangle {
        visible: list.count === 0
        anchors.fill: parent
        color: "transparent"
        Text {
          anchors.centerIn: parent
          text: "No clipboard history"
          color: Color.menu.text
          opacity: 0.6
          font.pixelSize: Style.font.body
        }
      }

      delegate: CursorSurface {
        id: row
        required property var modelData
        required property int index

        width: list.width
        height: Style.space(48)
        radius: Style.space(6)

        hasCursor: root.hoverIndex === index
        current: false
        foreground: root.bar ? root.bar.foreground : Color.foreground
        accent: Color.accent

        RowLayout {
          anchors.fill: parent
          anchors.margins: Style.spacing.rowPaddingX
          spacing: Style.space(10)

          Image {
            visible: modelData && modelData.type === "image"
            Layout.preferredWidth: Style.space(40)
            Layout.preferredHeight: Style.space(40)
            source: (modelData && modelData.type === "image") ? "file://" + modelData.path : ""
            fillMode: Image.PreserveAspectFit
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
              Layout.fillWidth: true
              text: modelData && modelData.type === "image"
                ? "Image"
                : (modelData ? String(modelData.text || "").trim().split("\n")[0] : "")
              // Clipboard content is arbitrary text from any app — never let
              // AutoText sniff it into rich text.
              textFormat: Text.PlainText
              elide: Text.ElideRight
              maximumLineCount: 1
              color: Color.menu.text
              font.pixelSize: Style.font.body
            }

            Text {
              Layout.fillWidth: true
              visible: modelData && (modelData.capturedAt || modelData.type === "image")
              text: modelData ? String(modelData.capturedAt || (modelData.type === "image" ? "Image" : "")) : ""
              textFormat: Text.PlainText
              elide: Text.ElideRight
              maximumLineCount: 1
              color: Color.menu.text
              opacity: 0.6
              font.pixelSize: Style.font.caption
            }
          }
        }

        MouseArea {
          id: rowHover
          anchors.fill: parent
          hoverEnabled: true
          onContainsMouseChanged: if (containsMouse) root.hoverIndex = index
          onClicked: root.copyIndex(index)
        }
      }
    }
  }
}