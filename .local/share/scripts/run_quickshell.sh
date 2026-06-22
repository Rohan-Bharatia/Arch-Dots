#!/usr/bin/env bash

set -euo pipefail

qs kill || true
sleep 0.1
qs &
