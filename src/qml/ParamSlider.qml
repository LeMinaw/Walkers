import QtQuick 2.0
import QtQuick.Controls 1.0
import org.julialang 1.0

Column {
  property string name: "Slider"
  property int min: 0
  property int max: 10
  property int step: 1
  property int value: 0
  property string helpText
  
  Text {
    text: {
      name + ": " + slider.value.toString();
    }
  }

  Slider {
    id: slider
    minimumValue: min
    maximumValue: max
    stepSize: step
    value: value

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      hoverEnabled: true
      onEntered: {
        if (helpText) {
          statusMsg = helpText;
        }
      }
    }
  }
}
