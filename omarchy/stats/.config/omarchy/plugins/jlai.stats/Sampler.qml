import QtQuick
import Quickshell.Io

// Owns the polling lifecycle and history for the stats widget. The bash
// sampler does the /proc math and persists to its own cache; this object
// primes an in-memory ring buffer from that cache once, then appends each new
// sample so graphs never wait on a disk read.
Item {
  id: sampler
  visible: false

  property string script: "~/.local/bin/omarchy-bar-stats"
  property int intervalMs: 2000
  property int historyLimit: 300

  property var history: []
  property var latest: ({})
  property var topProcs: ({})

  signal sampleReady()

  // Extract one metric series from history for a graph. `limit` keeps only the
  // newest N points (the bar sparklines want a short, readable window).
  function series(name, limit) {
    var out = []
    for (var i = 0; i < history.length; i++) {
      var s = history[i]
      var v
      if (name === "cpu") v = s.cpu
      else if (name === "ram") v = s.ram ? s.ram.pct : undefined
      else if (name === "disk") v = s.disk ? s.disk.pct : undefined
      else if (name === "temp") v = s.temp
      else if (name === "io") v = s.disk ? (s.disk.read + s.disk.write) : undefined
      else if (name === "read") v = s.disk ? s.disk.read : undefined
      else if (name === "write") v = s.disk ? s.disk.write : undefined
      if (v !== undefined && v !== null) out.push(v)
    }
    if (limit && out.length > limit) return out.slice(out.length - limit)
    return out
  }

  function refreshTop() {
    if (!topProc.running) topProc.running = true
  }

  Process {
    id: historyProc
    command: ["bash", "-lc", sampler.script + " --history " + sampler.historyLimit]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var arr = JSON.parse(text)
          if (Array.isArray(arr)) {
            sampler.history = arr
            if (arr.length > 0) sampler.latest = arr[arr.length - 1]
          }
        } catch (e) {}
        sampleTimer.running = true
      }
    }
  }

  Process {
    id: sampleProc
    command: ["bash", "-lc", sampler.script]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var line = String(text).trim()
        var nl = line.lastIndexOf("\n")
        if (nl >= 0) line = line.substring(nl + 1)
        var s = null
        try { s = JSON.parse(line) } catch (e) { return }
        if (!s || typeof s !== "object") return
        sampler.latest = s
        var h = sampler.history.slice()
        h.push(s)
        if (h.length > sampler.historyLimit) h = h.slice(h.length - sampler.historyLimit)
        sampler.history = h
        sampler.sampleReady()
      }
    }
  }

  Process {
    id: topProc
    command: ["bash", "-lc", sampler.script + " --top"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var t = JSON.parse(text)
          if (t && typeof t === "object") sampler.topProcs = t
        } catch (e) {}
      }
    }
  }

  Timer {
    id: sampleTimer
    interval: sampler.intervalMs
    repeat: true
    running: false
    onTriggered: if (!sampleProc.running) sampleProc.running = true
  }

  Component.onCompleted: if (!historyProc.running) historyProc.running = true
}
