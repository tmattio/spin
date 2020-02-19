#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TEMP_DIR=$(mktemp -d -t spin)

export PATH=$TEMP_DIR:$PATH
export SPIN_CACHE_DIR=$TEMP_DIR/cache

cp "$(esy x which spin)" "$TEMP_DIR/spin"
cd "$TEMP_DIR"

termtosvg -c "$DIR/demo-emulate.sh" "$DIR/../docs/demo.svg" -t window_frame -g 80x24 -m 100 -M 1000 -D 3000
