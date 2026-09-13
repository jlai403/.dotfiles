import QtQuick

// Tiny history graph for the stats widget. Renders `values` (oldest first)
// as either a filled area or a row of bars. Fixed-range by default
// (valueMin..valueMax); set autoScale for metrics without a natural range.
Canvas {
  id: root

  property var values: []
  property bool autoScale: false
  property real valueMin: 0
  property real valueMax: 100
  property string mode: "area"   // "area" | "bars"
  property color lineColor: "#ffffff"
  property color fillColor: "transparent"
  property real lineWidth: 1.5
  property int barGap: 1

  antialiasing: true

  onValuesChanged: requestPaint()
  onLineColorChanged: requestPaint()
  onFillColorChanged: requestPaint()
  onModeChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  function bounds() {
    var n = values.length
    if (!autoScale || n === 0) return { lo: valueMin, hi: valueMax }
    var lo = values[0]
    var hi = values[0]
    for (var i = 1; i < n; i++) {
      if (values[i] < lo) lo = values[i]
      if (values[i] > hi) hi = values[i]
    }
    if (hi - lo < 1) {
      var mid = (hi + lo) / 2
      lo = mid - 1
      hi = mid + 1
    }
    return { lo: lo, hi: hi }
  }

  function yFor(v, lo, hi, h) {
    var t = (v - lo) / (hi - lo)
    if (t < 0) t = 0
    if (t > 1) t = 1
    return h - t * h
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var n = values.length
    if (n === 0 || width <= 0 || height <= 0) return

    var w = width
    var h = height
    var b = bounds()

    if (mode === "bars") {
      var slot = w / n
      var bw = Math.max(1, slot - barGap)
      ctx.fillStyle = lineColor
      for (var i = 0; i < n; i++) {
        var y = yFor(values[i], b.lo, b.hi, h)
        ctx.fillRect(i * slot, y, bw, h - y)
      }
      return
    }

    var dx = n > 1 ? w / (n - 1) : w
    ctx.beginPath()
    for (var j = 0; j < n; j++) {
      var x = j * dx
      var yy = yFor(values[j], b.lo, b.hi, h)
      if (j === 0) ctx.moveTo(x, yy)
      else ctx.lineTo(x, yy)
    }

    if (fillColor.a > 0) {
      ctx.lineTo(w, h)
      ctx.lineTo(0, h)
      ctx.closePath()
      ctx.fillStyle = fillColor
      ctx.fill()
      ctx.beginPath()
      for (var k = 0; k < n; k++) {
        var x2 = k * dx
        var y2 = yFor(values[k], b.lo, b.hi, h)
        if (k === 0) ctx.moveTo(x2, y2)
        else ctx.lineTo(x2, y2)
      }
    }

    ctx.lineWidth = lineWidth
    ctx.lineJoin = "round"
    ctx.lineCap = "round"
    ctx.strokeStyle = lineColor
    ctx.stroke()
  }
}
