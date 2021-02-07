import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.julialang 1.0

ApplicationWindow {
  id: root
  title: "Walkers Alpha"
  visible: true
  width: 900
  height: 600
  onClosing: Qt.quit()

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
      id: paramsColumn
      Layout.margins: 10
      Layout.fillHeight: true

      ParamSlider {
        variable: "count"
        name: "Walkers count"
        min: 2
        max: 40
        step: 1
        helpText: "Number of interacting walkers"
      }

      ParamSlider {
        variable: "spread"
        name: "Walkers spread"
        max: 100
        helpText: "Average distance from origin walkers have at start"
      }

      ParamSlider {
        variable: "rel_avg"
        name: "Average attraction"
        min: -.1
        max: .1
        helpText: "Average values that binds walkers together. Negative value means repulsion, zero means no relation, positive is attraction"
      }

      ParamSlider {
        variable: "rel_var"
        name: "Attraction variance"
        helpText: "How random attraction values are. Zero means no random"
      }

      ParamSlider {
        variable: "iters"
        name: "Iterations"
        min: 1
        max: 1000
        step: 1
        helpText: "Number of iterations to compute"
      }

      ParamSlider {
        variable: "rotspeed"
        name: "Rotation speed"
        helpText: "Viewport rotation speed"
      }
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
