#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    GREETER="sddm-greeter-qt6"
elif command -v sddm-greeter >/dev/null 2>&1; then
    GREETER="sddm-greeter"
else
    echo "SDDM greeter not found."
    exit 1
fi

echo "Testing MacSDDM..."
echo "Theme path: $ROOT"

exec "$GREETER" --test-mode --theme "$ROOT"
