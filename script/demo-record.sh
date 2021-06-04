#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TEMP_DIR=$(mktemp -d -t spin)

export PATH=$TEMP_DIR:$PATH
export SPIN_CACHE_DIR=$TEMP_DIR/cache

cp "$(dune exec which spin)" "$TEMP_DIR/spin"
cd "$TEMP_DIR"

asciinema rec -c "$DIR/demo-emulate.sh" 

# cat /var/folders/1k/w8wtfpk909s_mvn_72q6d2p40000gn/T/tmp8dhvupt4-ascii.cast | svg-term --out "doc/demo.svg" --window --no-cursor --width 80 --height 24
