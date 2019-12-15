#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TEMP_DIR=$(mktemp -d -t spin)

export PATH=$TEMP_DIR:$PATH
export SPIN_CACHE_DIR=$TEMP_DIR/cache

cp "$DIR/../_build/default/executable/SpinApp.exe" "$TEMP_DIR/spin"
cd "$TEMP_DIR"

termtosvg -c "$DIR/demo.sh" "$DIR/../docs/demo.svg" -t window_frame
