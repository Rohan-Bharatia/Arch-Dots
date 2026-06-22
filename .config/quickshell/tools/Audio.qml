pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: audio

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink?.ready ?? false
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string sinkName: sink?.description ?? ""

    PwObjectTracker {
        objects: audio.sink != null
            ? [audio.sink]
            : []
    }

    function setVolume(v) {
        if (audio.ready && audio.sink.audio)
            audio.sink.audio.volume = v
    }

    function toggleMute() {
        if (audio.ready && audio.sink.audio)
            audio.sink.audio.muted = !audio.sink.audio.muted
    }

    function sliderToVolume(s) {
        if (s <= 0) return 0
        return Math.min(1, Math.pow(10, (s * 60 - 60) / 20))
    }

    function volumeToSlider(v) {
        if (v <= 0) return 0
        return Math.max(0, Math.min(1, (Math.log(v) / Math.log(10) * 20 + 60) / 60))
    }
}
