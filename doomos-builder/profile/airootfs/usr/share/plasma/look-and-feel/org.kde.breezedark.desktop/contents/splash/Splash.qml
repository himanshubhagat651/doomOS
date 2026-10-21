/*
    SPDX-FileCopyrightText: 2026 DoomOS Systems Engineering
    Custom Doctor Doom Emerald Boot Splash Screen
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#0e1411"

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            introAnimation.target = busyIndicator;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            readonly property real size: Kirigami.Units.gridUnit * 10
            anchors.centerIn: parent
            asynchronous: true
            source: "images/plasma.png"
            sourceSize.width: size
            sourceSize.height: size
        }

        Image {
            id: busyIndicator
            y: parent.height - (parent.height - logo.y) / 2 - height/2
            anchors.horizontalCenter: parent.horizontalCenter
            asynchronous: true
            source: "images/busywidget.svgz"
            sourceSize.height: Kirigami.Units.gridUnit * 2
            sourceSize.width: Kirigami.Units.gridUnit * 2
            RotationAnimator on rotation {
                id: rotationAnimator
                from: 0
                to: 360
                duration: 2000
                loops: Animation.Infinite
                running: Kirigami.Units.longDuration > 1
            }
        }

        Row {
            spacing: Kirigami.Units.largeSpacing
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                margins: Kirigami.Units.gridUnit * 2
            }
            Text {
                color: "#22c55e"
                font.bold: true
                font.pointSize: 13
                anchors.verticalCenter: parent.verticalCenter
                text: "DoomOS — Next-Gen Linux"
                Accessible.name: text
                Accessible.role: Accessible.StaticText
                textFormat: Text.PlainText
            }
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
