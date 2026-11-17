import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import JeridiEngine

Canvas {
    id: brandArt
    property bool compact: false
    onCompactChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        const w = width
        const h = height
        const edge = brandArt.compact ? w * 0.36 : w * 0.48
        const upper = edge + (brandArt.compact ? 42 : 82)
        const lower = edge - (brandArt.compact ? 22 : 53)
        ctx.clearRect(0, 0, w, h)

        const base = ctx.createLinearGradient(0, 0, edge, h)
        base.addColorStop(0, "#7725cb")
        base.addColorStop(0.4, "#4d43d8")
        base.addColorStop(1, "#183bba")
        ctx.fillStyle = base
        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.lineTo(upper, 0)
        ctx.lineTo(lower, h)
        ctx.lineTo(0, h)
        ctx.closePath()
        ctx.fill()

        const wave = ctx.createLinearGradient(0, h * 0.12, edge, h)
        wave.addColorStop(0, "#ff518b")
        wave.addColorStop(0.5, "#fc4171")
        wave.addColorStop(1, "#8124ce")
        ctx.fillStyle = wave
        ctx.beginPath()
        ctx.moveTo(-w * 0.12, h * 0.28)
        ctx.bezierCurveTo(edge * 0.26, h * 0.14, edge * 0.86, h * 0.39,
                          edge * 0.78, h * 0.61)
        ctx.bezierCurveTo(edge * 0.68, h * 0.88, edge * 0.32, h * 0.94,
                          edge * 0.16, h * 1.10)
        ctx.lineTo(-w * 0.12, h * 1.08)
        ctx.closePath()
        ctx.fill()

        const sun = ctx.createLinearGradient(0, h * 0.5, edge, h * 0.88)
        sun.addColorStop(0, "#ffc067")
        sun.addColorStop(0.38, "#ff8d4f")
        sun.addColorStop(1, "#ed366d")
        ctx.fillStyle = sun
        ctx.beginPath()
        ctx.moveTo(-w * 0.12, h * 0.63)
        ctx.bezierCurveTo(edge * 0.20, h * 0.41, edge * 0.73, h * 0.52,
                          edge * 0.48, h * 0.81)
        ctx.bezierCurveTo(edge * 0.27, h * 1.02, edge * 0.06, h * 1.02,
                          -w * 0.12, h * 1.1)
        ctx.closePath()
        ctx.fill()

        const curtain = ctx.createLinearGradient(edge * 0.4, 0, edge, h)
        curtain.addColorStop(0, "#9c55ef")
        curtain.addColorStop(0.6, "#6752e8")
        curtain.addColorStop(1, "#3745ac")
        ctx.fillStyle = curtain
        ctx.beginPath()
        ctx.moveTo(edge * 0.65, 0)
        ctx.lineTo(upper, 0)
        ctx.lineTo(lower, h)
        ctx.lineTo(edge * 0.8, h)
        ctx.bezierCurveTo(edge * 1.03, h * 0.53, edge * 0.79, h * 0.2,
                          edge * 0.65, 0)
        ctx.closePath()
        ctx.fill()

        ctx.strokeStyle = "rgba(255,255,255,0.24)"
        ctx.lineWidth = 1.2
        ctx.beginPath()
        ctx.moveTo(edge * 0.10, 0)
        ctx.lineTo(edge * 0.95, h)
        ctx.moveTo(edge * 0.7, 0)
        ctx.lineTo(edge * 0.24, h)
        ctx.stroke()
    }
}

