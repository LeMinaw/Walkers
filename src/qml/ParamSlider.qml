import QtQuick 2.0
import QtQuick.Controls 1.0
import org.julialang 1.0

Column {
  required property string variable
  property string name: "Slider"
  property variant min: 0
  property variant max: 1
  property variant step: 0
  property variant value
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
    value: params[variable]
    onValueChanged: {
      params[variable] = value;
    }

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
