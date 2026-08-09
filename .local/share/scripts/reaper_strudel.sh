#!/usr/bin/env sh

pw-jack chromium --app=https://strudel.cc/ &

sleep 1

jack_disconnect "Alder Lake PCH-P High Definition Audio Controller Stereo Microphone:capture_FL" "REAPER:in1"
jack_disconnect "Alder Lake PCH-P High Definition Audio Controller Stereo Microphone:capture_FR" "REAPER:in2"

jack_disconnect "Chromium:output_FL" "JBL TUNE130NC TWS-106:playback_FL"
jack_disconnect "Chromium:output_FR" "JBL TUNE130NC TWS-106:playback_FR"

jack_connect "Chromium:output_FL" "REAPER:in1"
jack_connect "Chromium:output_FR" "REAPER:in2"
