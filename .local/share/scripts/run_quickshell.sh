#!/usr/bin/env bash

set -euo pipefail

pkill qs || true
sleep 0.1
qs &
