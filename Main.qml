import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

Rectangle {
    id: root

    width: Screen.width
    height: Screen.height

    color: "#0b0b10"

    // ==========================================
    // CONFIGURATION
    // ==========================================

    readonly property real u:
        Math.max(0.70, Math.min(1.15, height / 930))

    readonly property string uiFont:
        regularFont.status === FontLoader.Ready
        ? regularFont.name
        : "Inter"

    readonly property string currentUser:
        userModel.count > 1
        ? userPicker.currentText
        : userModel.count === 1
          ? (userModel.lastUser || userPicker.currentText)
          : usernameField.text.trim()

    readonly property url wallpaperUrl:
        Qt.resolvedUrl(config.background || "assets/wallpaper.jpg")

    readonly property url avatarUrl:
        Qt.resolvedUrl(config.avatar || "assets/avatar.png")

    property date now: new Date()

    property bool shown: false
    property bool engaged: false
    property bool busy: false

    property string errorMessage: ""

    FontLoader {
        id: regularFont
        source: Qt.resolvedUrl("assets/fonts/OpenRunde-Regular.otf")
    }

    FontLoader {
        id: semiboldFont
        source: Qt.resolvedUrl("assets/fonts/OpenRunde-Semibold.otf")
    }

    // ==========================================
    // MACLOCK ACTIVITY / IDLE
    // ==========================================

    function poke() {
        engaged = true
        idleTimer.restart()
    }

    Timer {
        id: idleTimer

        interval: 9000

        onTriggered: {
            if (
                passwordInput.text.length === 0
                && !root.busy
            ) {
                root.engaged = false
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: root.now = new Date()
    }

    Timer {
        id: entranceTimer
        interval: 450

        onTriggered: {
            root.shown = true
            focusTimer.start()
        }
    }

    Timer {
        id: focusTimer
        interval: 500

        onTriggered: {
            if (userModel.count > 0)
                passwordInput.forceActiveFocus()
            else
                usernameField.forceActiveFocus()
        }
    }

    Timer {
        id: errorTimer
        interval: 3500

        onTriggered: root.errorMessage = ""
    }

    Component.onCompleted: entranceTimer.start()

    // ==========================================
    // AUTHENTICATION
    // ==========================================

    function startLogin() {
        if (root.busy)
            return

        if (root.currentUser.length === 0) {
            root.errorMessage = qsTr("Enter username")
            return
        }

        if (passwordInput.text.length === 0) {
            passwordInput.forceActiveFocus()
            return
        }

        root.errorMessage = ""
        root.busy = true
        root.poke()

        var sessionIndex =
            sessionPicker.currentIndex >= 0
            ? sessionPicker.currentIndex
            : 0

        sddm.login(
            root.currentUser,
            passwordInput.text,
            sessionIndex
        )
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.busy = false
            root.errorMessage = qsTr("Incorrect password")

            passwordInput.text = ""
            passwordInput.forceActiveFocus()

            root.poke()
            errorTimer.restart()

            passwordShake.restart()
        }

        function onLoginSucceeded() {
            root.busy = false
        }
    }

    // ==========================================
    // BACKGROUND
    // ==========================================

    Item {
        id: scene

        anchors.fill: parent

        Image {
            id: wallpaper

            anchors.fill: parent

            source: root.wallpaperUrl

            fillMode: Image.PreserveAspectCrop

            asynchronous: true
            cache: true
            smooth: true
            mipmap: true

            sourceSize.width:
                Math.min(root.width * 1.1, 2560)

            scale: root.shown ? 1.0 : 1.055

            Behavior on scale {
                NumberAnimation {
                    duration: 750
                    easing.type: Easing.OutQuint
                }
            }

            onStatusChanged: {
                if (status === Image.Error)
                    console.warn(
                        "[MacSDDM] Wallpaper error:",
                        source
                    )
            }
        }

        // Dynamic wallpaper blur.
        // Sharp while idle, soft while interacting.
        MultiEffect {
            anchors.fill: wallpaper

            source: wallpaper

            scale: wallpaper.scale

            blurEnabled: true
            blurMax: 48

            blur: root.engaged ? 0.55 : 0.0

            opacity: root.engaged ? 1 : 0

            visible: opacity > 0.002

            Behavior on blur {
                NumberAnimation {
                    duration: 650
                    easing.type: Easing.OutQuint
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 650
                    easing.type: Easing.OutQuint
                }
            }
        }

        // Very subtle contrast overlay.
        Rectangle {
            anchors.fill: parent
            color: "#0D000000"
        }

        // Soft vignette.
        Rectangle {
            anchors.fill: parent

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#24000000"
                }

                GradientStop {
                    position: 0.48
                    color: "#00000000"
                }

                GradientStop {
                    position: 1
                    color: "#28000000"
                }
            }
        }
    }

    // Shared backdrop texture for glass.
    ShaderEffectSource {
        id: glassTexture

        sourceItem: scene

        live: true
        mipmap: true

        visible: false
    }

    // ==========================================
    // CLOCK
    // ==========================================

    Column {
        id: clock

        anchors.top: parent.top
        anchors.topMargin: 76 * root.u

        anchors.horizontalCenter: parent.horizontalCenter

        spacing: -5 * root.u

        opacity: root.shown ? 1 : 0

        transform: Translate {
            y: root.shown ? 0 : -22 * root.u

            Behavior on y {
                NumberAnimation {
                    duration: 700
                    easing.type: Easing.OutQuint
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 700 }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: Qt.formatDate(
                root.now,
                config.dateFormat || "dddd, MMMM d"
            )

            color: "#EFFFFFFF"

            font.family: root.uiFont
            font.pixelSize: 17 * root.u
            font.weight: Font.Medium

            opacity: 0.85
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: Qt.formatTime(
                root.now,
                config.timeFormat || "hh:mm"
            )

            color: "#FFFFFF"

            font.family: root.uiFont
            font.pixelSize: 105 * root.u
            font.weight: Font.Normal

            renderType: Text.QtRendering
        }
    }

    // ==========================================
    // LOGIN PROFILE
    // ==========================================

    Column {
        id: loginProfile

        width: Math.min(
            320 * root.u,
            root.width - 40 * root.u
        )

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 72 * root.u

        spacing: 9 * root.u

        opacity: root.shown ? 1 : 0

        transform: Translate {
            y: root.shown ? 0 : 20 * root.u

            Behavior on y {
                NumberAnimation {
                    duration: 750
                    easing.type: Easing.OutQuint
                }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 750 }
        }

        // ======================================
        // AVATAR
        // ======================================

        Item {
            id: avatarFrame

            width: 70 * root.u
            height: width

            anchors.horizontalCenter: parent.horizontalCenter

            scale: root.engaged ? 1.0 : 0.94

            Behavior on scale {
                NumberAnimation {
                    duration: 650
                    easing.type: Easing.OutQuint
                }
            }

            Rectangle {
                anchors.fill: parent

                radius: width / 2

                color: "#28FFFFFF"

                Text {
                    anchors.centerIn: parent

                    visible: avatarImage.status !== Image.Ready

                    text: root.currentUser.length > 0
                          ? root.currentUser.charAt(0).toUpperCase()
                          : "?"

                    color: "white"

                    font.family: root.uiFont
                    font.pixelSize: 30 * root.u
                    font.weight: Font.DemiBold
                }
            }

            // Circle mask.
            Item {
                id: avatarMask

                anchors.fill: parent

                visible: false
                layer.enabled: true
                layer.smooth: true

                Rectangle {
                    anchors.fill: parent

                    radius: width / 2
                    color: "black"
                }
            }

            // Your actual assets/avatar.png.
            Image {
                id: avatarImage

                anchors.fill: parent

                source: root.avatarUrl

                fillMode: Image.PreserveAspectCrop

                asynchronous: true
                smooth: true
                mipmap: true

                sourceSize: Qt.size(256, 256)

                layer.enabled: true
                layer.smooth: true

                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: avatarMask

                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                onStatusChanged: {
                    if (status === Image.Error)
                        console.warn(
                            "[MacSDDM] Avatar error:",
                            source
                        )
                }
            }

            Rectangle {
                anchors.fill: parent

                radius: width / 2

                color: "transparent"

                border.width: 1
                border.color: "#48FFFFFF"
            }
        }

        // ======================================
        // USER NAME
        // ======================================

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            visible: userModel.count <= 1 && userModel.count > 0

            text: root.currentUser

            color: "#FFFFFF"

            font.family: root.uiFont
            font.pixelSize: 15 * root.u
            font.weight: Font.DemiBold
        }

        // User selection.
        ComboBox {
            id: userPicker

            visible: userModel.count > 1

            anchors.horizontalCenter: parent.horizontalCenter

            width: 180 * root.u
            height: 30 * root.u

            model: userModel
            textRole: "name"

            currentIndex:
                userModel.lastIndex >= 0
                ? userModel.lastIndex
                : 0

            font.family: root.uiFont
            font.pixelSize: 14 * root.u

            onActivated: {
                root.errorMessage = ""
                root.poke()
                passwordInput.forceActiveFocus()
            }

            background: Item {}

            contentItem: Text {
                text: userPicker.displayText

                color: "white"

                font: userPicker.font

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            indicator: Text {
                text: "⌄"

                color: "#BFFFFFFF"

                font.pixelSize: 14 * root.u

                x: userPicker.width - width - 8 * root.u
                y: (userPicker.height - height) / 2
            }

            delegate: ItemDelegate {
                width: userPicker.width

                contentItem: Text {
                    text: model.name || ""

                    color: "white"

                    font.family: root.uiFont
                    font.pixelSize: 13 * root.u

                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10 * root.u
                }

                background: Rectangle {
                    radius: 8

                    color: highlighted
                           ? "#40FFFFFF"
                           : "transparent"
                }
            }

            popup: Popup {
                y: userPicker.height + 6 * root.u

                width: userPicker.width

                padding: 6 * root.u

                background: Rectangle {
                    color: "#E51A1B20"

                    radius: 13 * root.u

                    border.width: 1
                    border.color: "#40FFFFFF"
                }

                contentItem: ListView {
                    clip: true

                    implicitHeight: Math.min(
                        contentHeight,
                        180 * root.u
                    )

                    model: userPicker.popup.visible
                           ? userPicker.delegateModel
                           : null

                    currentIndex: userPicker.highlightedIndex
                }
            }
        }

        // Fallback if SDDM has no available user list.
        TextField {
            id: usernameField

            visible: userModel.count === 0

            anchors.horizontalCenter: parent.horizontalCenter

            width: 210 * root.u
            height: 32 * root.u

            placeholderText: qsTr("Username")
            placeholderTextColor: "#AFFFFFFF"

            color: "white"

            font.family: root.uiFont
            font.pixelSize: 13 * root.u

            horizontalAlignment: TextInput.AlignHCenter

            background: Rectangle {
                radius: height / 2
                color: "#20FFFFFF"
                border.width: 1
                border.color: "#40FFFFFF"
            }

            onAccepted: passwordInput.forceActiveFocus()
        }

        // ======================================
        // PASSWORD PILL
        // ======================================

        Item {
            id: passwordBox

            anchors.horizontalCenter: parent.horizontalCenter

            width: (
                passwordInput.text.length > 0 || root.engaged
                ? 236
                : 210
            ) * root.u

            height: 36 * root.u

            Behavior on width {
                NumberAnimation {
                    duration: 450
                    easing.type: Easing.OutQuint
                }
            }

            property bool pressed: passwordTap.pressed

            // Press animation.
            transform: [
                Translate {
                    id: passwordShakeOffset
                    x: 0
                },

                Scale {
                    origin.x: passwordBox.width / 2
                    origin.y: passwordBox.height / 2

                    xScale: passwordBox.pressed ? 1.045 : 1.0
                    yScale: passwordBox.pressed ? 0.86 : 1.0

                    Behavior on xScale {
                        NumberAnimation {
                            duration: passwordBox.pressed ? 140 : 420
                            easing.type: Easing.OutQuint
                        }
                    }

                    Behavior on yScale {
                        NumberAnimation {
                            duration: passwordBox.pressed ? 140 : 420
                            easing.type: Easing.OutQuint
                        }
                    }
                }
            ]

            // Liquid Glass.
            GlassPill {
                anchors.fill: parent

                src: glassTexture
                frame: root

                cornerR: height / 2

                thickness: 18
                strength: 1.0

                tint: 0.50
                rim: 0.55
                shadowAmt: 0.4
            }

            // Hover border glow.
            Rectangle {
                anchors.fill: parent

                radius: height / 2

                color: "transparent"

                border.width: 1.3
                border.color: "#EFFFFFFF"

                opacity:
                    passwordHover.hovered || passwordBox.pressed
                    ? 0.65
                    : 0.12

                Behavior on opacity {
                    NumberAnimation {
                        duration: 320
                        easing.type: Easing.OutQuint
                    }
                }
            }

            HoverHandler {
                id: passwordHover

                onHoveredChanged: {
                    if (hovered)
                        root.poke()
                }
            }

            TapHandler {
                id: passwordTap

                onPressedChanged: {
                    if (pressed)
                        root.poke()
                }
            }

            // Real hidden input.
            TextInput {
                id: passwordInput

                anchors.left: parent.left
                anchors.leftMargin: 16 * root.u

                anchors.right: parent.right
                anchors.rightMargin: 42 * root.u

                anchors.verticalCenter: parent.verticalCenter

                height: parent.height

                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"

                cursorVisible: false

                echoMode: TextInput.NoEcho

                font.family: root.uiFont
                font.pixelSize: 14 * root.u

                verticalAlignment: TextInput.AlignVCenter

                inputMethodHints:
                    Qt.ImhHiddenText | Qt.ImhNoPredictiveText

                activeFocusOnPress: true

                onTextChanged: {
                    root.errorMessage = ""
                    errorTimer.stop()

                    root.poke()
                    passwordBox.syncDots()
                }

                onAccepted: root.startLogin()

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        text = ""
                        event.accepted = true
                    }
                }
            }

            // Password placeholder.
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16 * root.u

                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Enter Password")

                color: "#CFFFFFFF"

                font.family: root.uiFont
                font.pixelSize: 14 * root.u

                opacity:
                    passwordInput.text.length === 0
                    ? 1
                    : 0

                Behavior on opacity {
                    NumberAnimation { duration: 140 }
                }
            }

            // Animated password dots.
            ListModel {
                id: dotModel
            }

            property int dotSequence: 0

            function syncDots() {
                var want = passwordInput.text.length
                var alive = 0

                for (var i = 0; i < dotModel.count; i++) {
                    if (!dotModel.get(i).dying)
                        alive++
                }

                while (alive < want) {
                    dotModel.append({
                        uid: dotSequence++,
                        dying: false
                    })

                    alive++
                }

                for (
                    var j = dotModel.count - 1;
                    j >= 0 && alive > want;
                    j--
                ) {
                    if (!dotModel.get(j).dying) {
                        dotModel.setProperty(j, "dying", true)
                        alive--
                    }
                }
            }

            Item {
                anchors.left: parent.left
                anchors.leftMargin: 16 * root.u

                anchors.right: loginButton.left
                anchors.rightMargin: 8 * root.u

                anchors.verticalCenter: parent.verticalCenter

                height: 12 * root.u

                clip: true

                Row {
                    id: dotRow

                    anchors.verticalCenter: parent.verticalCenter

                    x: Math.min(0, parent.width - width)

                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: dotModel

                        delegate: Item {
                            id: dotCell

                            required property int uid
                            required property bool dying

                            property real grow: 0

                            readonly property real step:
                                12 * root.u

                            width: step * grow
                            height: 12 * root.u

                            Component.onCompleted: grow = 1

                            onDyingChanged: {
                                if (dying) {
                                    grow = 0
                                    removeDot.start()
                                }
                            }

                            Behavior on grow {
                                NumberAnimation {
                                    duration: dotCell.dying ? 200 : 240
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent

                                width: 7 * root.u
                                height: width

                                radius: width / 2

                                color: "white"

                                opacity: dotCell.grow

                                scale: 0.35 + 0.65 * dotCell.grow
                            }

                            Timer {
                                id: removeDot

                                interval: 240

                                onTriggered: {
                                    for (
                                        var i = dotModel.count - 1;
                                        i >= 0;
                                        i--
                                    ) {
                                        if (
                                            dotModel.get(i).uid
                                            === dotCell.uid
                                        ) {
                                            dotModel.remove(i)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Submit button.
            Item {
                id: loginButton

                anchors.right: parent.right
                anchors.rightMargin: 6 * root.u

                anchors.verticalCenter: parent.verticalCenter

                width: 24 * root.u
                height: width

                readonly property bool active:
                    passwordInput.text.length > 0 || root.busy

                opacity: active ? 1 : 0

                scale: active ? 1 : 0.4

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 340
                        easing.type: Easing.OutQuint
                    }
                }

                Rectangle {
                    anchors.fill: parent

                    radius: width / 2

                    color: "#48FFFFFF"

                    visible: !root.busy
                }

                Text {
                    anchors.centerIn: parent

                    visible: !root.busy

                    text: "→"

                    color: "white"

                    font.pixelSize: 17 * root.u
                }

                Canvas {
                    anchors.fill: parent

                    visible: root.busy

                    onPaint: {
                        var c = getContext("2d")
                        c.reset()

                        var w = width

                        c.strokeStyle = "white"
                        c.lineWidth = Math.max(1.6, w * 0.09)
                        c.lineCap = "round"

                        c.beginPath()
                        c.arc(
                            w / 2,
                            w / 2,
                            w * 0.36,
                            0,
                            Math.PI * 1.4
                        )

                        c.stroke()
                    }

                    onWidthChanged: requestPaint()

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: root.busy
                    }
                }

                MouseArea {
                    id: loginMouse

                    anchors.fill: parent

                    cursorShape: Qt.PointingHandCursor

                    enabled: loginButton.active && !root.busy

                    onClicked: root.startLogin()
                }
            }
        }

        // Error / hint.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            width: parent.width

            horizontalAlignment: Text.AlignHCenter

            text:
                root.errorMessage.length > 0
                ? root.errorMessage
                : qsTr("Enter your password to unlock")

            color:
                root.errorMessage.length > 0
                ? "#FFFFB5B0"
                : "#AFFFFFFF"

            font.family: root.uiFont
            font.pixelSize: 12 * root.u

            opacity:
                root.engaged || root.errorMessage.length > 0
                ? 1
                : 0

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }
    }

    // Password failure animation.
    SequentialAnimation {
        id: passwordShake

        NumberAnimation {
            target: passwordShakeOffset
            property: "x"
            to: -16 * root.u
            duration: 55
        }

        NumberAnimation {
            target: passwordShakeOffset
            property: "x"
            to: 14 * root.u
            duration: 80
        }

        NumberAnimation {
            target: passwordShakeOffset
            property: "x"
            to: -10 * root.u
            duration: 75
        }

        NumberAnimation {
            target: passwordShakeOffset
            property: "x"
            to: 7 * root.u
            duration: 70
        }

        NumberAnimation {
            target: passwordShakeOffset
            property: "x"
            to: 0
            duration: 90
        }
    }

    // ==========================================
    // POWER CONTROLS
    // ==========================================

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        anchors.leftMargin: 30 * root.u
        anchors.bottomMargin: 28 * root.u

        spacing: 10 * root.u

        opacity: root.shown ? 1 : 0

        Repeater {
            model: [
                { glyph: "⏻", action: "power" },
                { glyph: "↻", action: "reboot" }
            ]

            delegate: Item {
                id: powerItem

                width: 40 * root.u
                height: width

                visible:
                    modelData.action === "power"
                    ? sddm.canPowerOff
                    : sddm.canReboot

                scale:
                    powerMouse.pressed ? 0.90
                    : powerMouse.containsMouse ? 1.06
                    : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutQuint
                    }
                }

                GlassPill {
                    anchors.fill: parent

                    src: glassTexture
                    frame: root

                    cornerR: width / 2

                    thickness: 12
                    strength: 0.7

                    tint: 0.18
                    rim: 0.5
                    shadowAmt: 0.25
                }

                Text {
                    anchors.centerIn: parent

                    text: modelData.glyph

                    color: "white"

                    font.family: root.uiFont
                    font.pixelSize: 19 * root.u
                }

                MouseArea {
                    id: powerMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape: Qt.PointingHandCursor

                    onEntered: root.poke()

                    onClicked: {
                        root.poke()

                        if (modelData.action === "power")
                            sddm.powerOff()
                        else
                            sddm.reboot()
                    }
                }
            }
        }
    }

    // ==========================================
    // SESSION SELECTOR
    // ==========================================

    ComboBox {
        id: sessionPicker

        visible: sessionModel.count > 1

        anchors.right: parent.right
        anchors.bottom: parent.bottom

        anchors.rightMargin: 30 * root.u
        anchors.bottomMargin: 28 * root.u

        width: 165 * root.u
        height: 40 * root.u

        model: sessionModel
        textRole: "name"

        currentIndex:
            sessionModel.lastIndex >= 0
            ? sessionModel.lastIndex
            : 0

        font.family: root.uiFont
        font.pixelSize: 12 * root.u

        onActivated: root.poke()

        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 700 }
        }

        background: GlassPill {
            anchors.fill: parent

            src: glassTexture
            frame: root

            cornerR: height / 2

            thickness: 12
            strength: 0.8

            tint: 0.20
            rim: 0.5
            shadowAmt: 0.3
        }

        contentItem: Text {
            leftPadding: 14 * root.u
            rightPadding: 25 * root.u

            text: sessionPicker.displayText

            color: "white"

            font: sessionPicker.font

            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            text: "⌄"

            color: "#DFFFFFFF"

            font.pixelSize: 14 * root.u

            x: sessionPicker.width - width - 12 * root.u
            y: (sessionPicker.height - height) / 2
        }

        delegate: ItemDelegate {
            width: sessionPicker.width

            contentItem: Text {
                text: model.name || ""

                color: "white"

                font.family: root.uiFont
                font.pixelSize: 12 * root.u

                verticalAlignment: Text.AlignVCenter
                leftPadding: 10 * root.u
            }

            background: Rectangle {
                radius: 8

                color: highlighted
                       ? "#45FFFFFF"
                       : "transparent"
            }
        }

        popup: Popup {
            y: sessionPicker.height + 5 * root.u

            width: sessionPicker.width

            padding: 6 * root.u

            background: Rectangle {
                color: "#E51B1C22"

                radius: 14 * root.u

                border.width: 1
                border.color: "#40FFFFFF"
            }

            contentItem: ListView {
                clip: true

                implicitHeight: Math.min(
                    contentHeight,
                    200 * root.u
                )

                model: sessionPicker.popup.visible
                       ? sessionPicker.delegateModel
                       : null

                currentIndex: sessionPicker.highlightedIndex
            }
        }
    }

    // ==========================================
    // GLOBAL POINTER TRACKER
    // ==========================================

    MouseArea {
        anchors.fill: parent

        z: -1

        hoverEnabled: true

        property point last:
            Qt.point(-1, -1)

        onPositionChanged: function(mouse) {
            if (
                last.x >= 0
                && (
                    Math.abs(mouse.x - last.x) > 2
                    || Math.abs(mouse.y - last.y) > 2
                )
            ) {
                root.poke()
            }

            last = Qt.point(mouse.x, mouse.y)
        }

        onClicked: root.poke()
    }
}
