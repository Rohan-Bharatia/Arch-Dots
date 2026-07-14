#!/usr/bin/env bash

set -euo pipefail

pkill qs
sleep 0.1
qs &
