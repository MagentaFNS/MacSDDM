// GlassPill.qml
import QtQuick

Item {
    id: root

    // Свойства, которые можно будет настраивать снаружи
    property real cornerR: 22          // Радиус скругления
    property real thickness: 24        // Толщина искажения
    property real strength: 1.0        // Общая интенсивность
    property real tint: 0.32           // Оттенок
    property real rim: 0.5             // Блик по краю
    property real shadowAmt: 0.5       // Тень
    property bool dark: true           // Тёмное стекло
    property var source: null          // Ссылка на размытый фон (ShaderEffectSource или Image)

    // Внутренние отступы для шейдера (чтобы не обрезать искажения по краям)
    readonly property real pad: 10

    // Сам шейдер
    ShaderEffect {
        id: fx
        // Шейдер рисуется с отступами, чтобы компенсировать pad
        x: -root.pad
        y: -root.pad
        width: root.width + 2 * root.pad
        height: root.height + 2 * root.pad
        fragmentShader: "shaders/liquidglass.frag.qsb"

        // Передаём источник (размытый фон)
        property variant src: root.source

        // Размеры
        property vector2d itemSize: Qt.vector2d(width, height)
        property vector2d glassSize: Qt.vector2d(root.width, root.height)
        property vector2d srcSize: Qt.vector2d(root.source ? root.source.width : 1, root.source ? root.source.height : 1)
        // Смещение источника (координаты root на экране)
        property vector2d srcOffset: Qt.vector2d(root.mapToItem(null, 0, 0).x - root.pad, root.mapToItem(null, 0, 0).y - root.pad)

        // Параметры, адаптированные из Glass.qml
        property real pad: root.pad
        property real radius: root.cornerR
        property real bezel: Math.min(root.height * 0.36, 26)
        property real thickness: root.thickness * root.strength * 1.6
        property real dispersion: 0.06 * root.strength * 1.3
        property real magnify: 0.05 * root.strength * 1.6
        property real rim: root.rim
        property real grain: 0.006
        property real blurPx: 1.5
        property real tintMix: root.tint * 0.55
        property real saturation: 1.25
        property real dark: root.dark ? 1 : 0
        property real debug: 0
        property real shadowAmt: root.shadowAmt
    }
}