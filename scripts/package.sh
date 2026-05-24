#!/usr/bin/env bash
set -euo pipefail

PKG_ID="org.kde.plasma.eventcalendar.meteoradar6v13"
OUT_DIR="packages"
OUT_FILE="$OUT_DIR/eventcalendar-meteoradar6-v13.plasmoid"

cd "$(dirname "$0")/.."
mkdir -p "$OUT_DIR"
rm -f "$OUT_FILE"

(
  cd "$PKG_ID"
  zip -r "../$OUT_FILE" . -x '*.git*' -x '*~'
)

echo "Creato: $OUT_FILE"
