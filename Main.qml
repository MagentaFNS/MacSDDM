import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#000000"

    // 1. ФОН (Статичное размытие, чтобы не крашить видеокарту)
    Image {
        id: bgImage
        source: config.background || ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    FastBlur {
        anchors.fill: parent
        source: bgImage
        radius: 64 // Фиксированное размытие
    }

    // Затемнение фона
    Rectangle {
        anchors.fill: parent
        color: "#25000000"
    }

    // Переменные для каскадной анимации
    property bool showClock: false
    property bool showPlayer: false
    property bool showInput: false

    // Таймеры, запускающие анимации
    Component.onCompleted: startAnimations.start()
    Timer {
        id: startAnimations
        interval: 100
        onTriggered: {
            root.showClock = true
            timerPlayer.start()
        }
    }
    Timer { id: timerPlayer; interval: 200; onTriggered: { root.showPlayer = true; timerInput.start() } }
    Timer { id: timerInput; interval: 200; onTriggered: { root.showInput = true } }

    // 2. ЧАСЫ
    Column {
        anchors.top: parent.top
        anchors.topMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 0
        
        opacity: root.showClock ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: root.showClock ? 0 : -30
            Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: "white"
            font.family: "Inter"
            font.pixelSize: 24
            font.weight: Font.Medium
            opacity: 0.9
        }

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.family: "Inter"
            font.pixelSize: 110
            font.weight: Font.Light
            text: Qt.formatTime(new Date(), "hh:mm")
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }

    // 3. ЦЕНТРАЛЬНЫЙ БЛОК
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 40

        // --- КАРТОЧКА ПЛЕЕРА ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 280
            height: 280
            
            opacity: root.showPlayer ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: root.showPlayer ? 0 : 30
                Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            }

            Image {
                source: config.background || ""
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: 280; height: 280; radius: 16 }
                }
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 80
                color: Qt.rgba(0.1, 0.1, 0.1, 0.6)
                radius: 16
                
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "I Don't Know - Radio Mix"; color: "white"; font.family: "Inter"; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Erika"; color: "#aaaaaa"; font.family: "Inter"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }

        // --- БЛОК АВАТАРА И ПАРОЛЯ ---
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            opacity: root.showInput ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: root.showInput ? 0 : 30
                Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }
            }

            // Аватарка (Убрал DropShadow, чтобы не было краша)
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 88
                height: 88
                
                Image {
                    id: avatarImg
                    source: config.avatar || ""
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: 88; height: 88; radius: 44 }
                    }
                }
            }

            // Имя
            Text {
                text: userModel.lastUser
                color: "white"
                font.family: "Inter"
                font.pixelSize: 18
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter
            }

            // Поле пароля
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 260
                height: 42

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(1, 1, 1, 0.15)
                    radius: 21
                    border.color: Qt.rgba(1, 1, 1, 0.3)
                    border.width: 1
                }

                TextField {
                    id: passwordInput
                    anchors.fill: parent
                    placeholderText: "Enter Password"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.6)
                    echoMode: TextInput.Password
                    color: "white"
                    font.family: "Inter"
                    font.pixelSize: 15
                    horizontalAlignment: TextInput.AlignHCenter
                    background: Item {}
                    focus: true

                    onAccepted: {
                        sddm.login(userModel.lastUser, passwordInput.text, sessionCombo.currentIndex)
                    }
                }
            }

            // Подсказка
            Text {
                text: "Enter your password to unlock"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: "Inter"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }

            // Ошибка
            Text {
                id: errorMsg
                text: ""
                color: "#ff453a"
                font.family: "Inter"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // 4. ПЕРЕКЛЮЧАТЕЛЬ СЕССИЙ
    ComboBox {
        id: sessionCombo
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 40
        width: 180
        height: 36
        model: sessionModel
        currentIndex: sessionModel.lastIndex
        
        opacity: root.showInput ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

        background: Rectangle {
            color: Qt.rgba(1, 1, 1, 0.1)
            radius: 10
            border.color: Qt.rgba(1, 1, 1, 0.2)
            border.width: 1
        }

        contentItem: Text {
            leftPadding: 12
            text: sessionCombo.displayText || ""
            font.family: "Inter"
            font.pixelSize: 12
            color: "white"
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: sessionCombo.width - width - 12
            y: (sessionCombo.height - height) / 2
            text: "⌄"
            color: "white"
            font.pixelSize: 16
        }

        delegate: ItemDelegate {
            width: sessionCombo.width
            height: 32
            contentItem: Text {
                text: model.name || model.display || ""
                color: "white"
                font.family: "Inter"
                font.pixelSize: 12
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
        
        opacity: root.showInput ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.OutCubic } }

        Button {
            text: "⏻"
            font.pixelSize: 22
            onClicked: sddm.powerOff()
            background: Item {}
            contentItem: Text { text: parent.text; color: "white"; opacity: parent.hovered ? 1 : 0.5; font: parent.font }
        }
        Button {
            text: "↻"
            font.pixelSize: 22
            onClicked: sddm.reboot()
            background: Item {}
            contentItem: Text { text: parent.text; color: "white"; opacity: parent.hovered ? 1 : 0.5; font: parent.font }
        }
    }
}