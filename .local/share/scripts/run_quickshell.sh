#!/usr/bin/env bash

set -euo pipefail

pkill quickshell
sleep 0.1
quickshell &
