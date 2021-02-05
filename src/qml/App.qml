import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

ApplicationWindow {
  title: "Walkers Alpha"
  visible: true
  width: 900
  height: 600

  property string statusMsg: "Welcome to Walkers Alpha!"

  menuBar: MenuBar {
    Menu {
      title: "File"

      MenuItem {
        text: "Reset simulation"
        shortcut: "Ctrl+N"
      }

      MenuSeparator {}

      MenuItem {
        text: "Save simulation parameters..."
        shortcut: "Ctrl+S"
      }

      MenuItem {
        text: "Recall simulation parameters..."
        shortcut: "Ctrl+O"
      }

      MenuSeparator {}

      MenuItem {
        text: "Quit"
        shortcut: "Ctrl+Q"
      }
    }

    Menu {
      title: "View"

      MenuItem {
        text: "Export as raster file..."
        shortcut: "Ctrl+E"
      }
    }
  }

  statusBar: StatusBar {
    RowLayout {
      anchors.fill: parent
      Label {
        id: statusbar
        text: statusMsg
      }
    }
  } 

  RowLayout {
    id: content
    anchors.fill: parent

    ColumnLayout {
      id: params
      Layout.margins: 10
      Layout.fillHeight: true
      // Layout.preferredWidth: 400

      ParamSlider {
        name: "Walkers count"
        min: 2
        max: 40
        helpText: "Number of interacting walkers"
      }

      ParamSlider {
        name: "Iterations"
        min: 1
        max: 1000
        helpText: "Number of iterations to compute"
      }

      ParamSlider { }
    }

    // MakieViewport {
    //   id: viewport
    //   Layout.fillWidth: true
    //   Layout.fillHeight: true
    //   renderFunction: render_callback
    // }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "lightsteelblue"
    }
  }
}
