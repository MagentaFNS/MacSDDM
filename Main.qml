import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 1920
    height: 1080
    // Глубокий черный фон в стиле MacLock
    color: "#0b0b10"

    // 1. СЛОЙ ФОНА (Обои + Размытие + Анимация)
    Item {
        id: scene
        anchors.fill: parent

        Image {
            id: wallpaper
            anchors.fill: parent
            source: config.background || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }

        // Имитация эффекта "Liquid Glass" через FastBlur
        FastBlur {
            anchors.fill: parent
            source: wallpaper
            radius: 80
            // Плавное появление при загрузке
            opacity: 0
            NumberAnimation on opacity {
                to: 1
                duration: 1000
                easing.type: Easing.OutQuint
                running: true
            }
        }

        // Градиентная виньетка для контраста текста
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.4) }
                GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.0) }
                GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
            }
        }
    }

    // 2. ЧАСЫ (С эффектом стекла и анимацией)
    Column {
        id: clockBlock
        anchors.top: parent.top
        anchors.topMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        // Плашка под часы (стекло)
        Rectangle {
            id: clockGlass
            width: timeText.width + 60
            height: timeText.height + dateText.height + 40
            anchors.centerIn: parent
            color: Qt.rgba(1, 1, 1, 0.08)
            radius: 24
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            // Анимация появления
            opacity: 0
            scale: 0.9
            NumberAnimation on opacity { to: 1; duration: 800; easing.type: Easing.OutCubic; running: true }
            NumberAnimation on scale { to: 1.0; duration: 800; easing.type: Easing.OutCubic; running: true }
        }

        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: "white"
            font.family: "Open Runde" // Или "sans-serif"
            font.pixelSize: 26
            font.weight: Font.DemiBold
            z: 1 // Поверх стекла
        }

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.family: "Open Runde"
            font.pixelSize: 120
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "hh:mm")
            z: 1

            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }

    // 3. БЛОК ВХОДА (Аватар + Пароль)
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 100
        spacing: 20

        // Аватар с анимацией
        Item {
            width: 96
            height: 96
            Layout.alignment: Qt.AlignHCenter

            Image {
                id: avatarImg
                source: config.avatar || ""
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: 96; height: 96; radius: 48 }
                }
            }

            // Плавное появление
            opacity: 0
            NumberAnimation on opacity {
                to: 1
                duration: 800
                easing.type: Easing.OutCubic
                running: true
            }
        }

        Text {
            text: userModel.lastUser
            color: "white"
            font.family: "Open Runde"
            font.pixelSize: 20
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignHCenter
        }

        // Поле пароля (в виде пилюли)
        TextField {
            id: passwordInput
            Layout.preferredWidth: 280
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignHCenter
            placeholderText: "Enter Password"
            placeholderTextColor: "#99ffffff"
            echoMode: TextInput.Password
            color: "white"
            font.family: "Open Runde"
            font.pixelSize: 16
            horizontalAlignment: TextInput.AlignHCenter
            focus: true

            background: Rectangle {
                color: Qt.rgba(1, 1, 1, 0.12)
                radius: 22
                border.color: passwordInput.activeFocus ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.2)
                border.width: 1
            }

            onAccepted: {
                sddm.login(userModel.lastUser, passwordInput.text, sessionModel.lastIndex)
            }
        }

        // Текст ошибки
        Text {
            id: errorMsg
            text: ""
            color: "#ff453a"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        Connections {
            target: sddm
            function onLoginFailed() {
                errorMsg.text = "Incorrect Password"
                passwordInput.text = ""
                passwordInput.forceActiveFocus()
            }
        }
    }

    // 4. ПЕРЕКЛЮЧАТЕЛЬ СЕССИЙ (Правый нижний угол)
    ComboBox {
        id: sessionCombo
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 40
        width: 200
        height: 38
        model: sessionModel
        currentIndex: sessionModel.lastIndex

        background: Rectangle {
            color: Qt.rgba(1, 1, 1, 0.12)
            radius: 10
            border.color: Qt.rgba(1, 1, 1, 0.2)
            border.width: 1
        }

        contentItem: Text {
            leftPadding: 14
            text: sessionCombo.displayText
            font.family: "Open Runde"
            font.pixelSize: 13
            color: "white"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: sessionCombo.width - width - 12
            y: (sessionCombo.height - height) / 2
            text: "⌄"
            color: "white"
            font.pixelSize: 18
        }

        delegate: ItemDelegate {
            width: sessionCombo.width
            height: 34
            contentItem: Text {
                text: model.display
                color: "white"
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                leftPadding: 10
            }
            background: Rectangle {
                color: sessionCombo.highlightedIndex === index ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
                radius: 6
            }
        }

        popup: Popup {
            y: sessionCombo.height + 4
            width: sessionCombo.width
            padding: 4
            background: Rectangle {
                color: Qt.rgba(0.15, 0.15, 0.15, 0.95)
                radius: 10
                border.color: Qt.rgba(1, 1, 1, 0.15)
            }
            contentItem: ListView {
                implicitHeight: contentHeight
                model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null
            }
        }
    }

    // 5. КНОПКИ ПИТАНИЯ
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 40
        spacing: 24

        Button {
            text: "⏻"
            font.pixelSize: 24
            onClicked: sddm.powerOff()
            background: Item {}
            contentItem: Text { text: parent.text; color: "white"; font: parent.font; opacity: parent.hovered ? 1 : 0.6 }
        }
        Button {
            text: "↻"
            font.pixelSize: 24
            onClicked: sddm.reboot()
            background: Item {}
            contentItem: Text { text: parent.text; color: "white"; font: parent.font; opacity: parent.hovered ? 1 : 0.6 }
        }
    }
}