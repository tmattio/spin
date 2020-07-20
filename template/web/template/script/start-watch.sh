#!/usr/bin/env bash

trap ctrl_c INT

function ctrl_c() {
    kill -9 ${PID}
    exit 1
}

_build/default/bin/server.exe -- "$@" &
PID=$!

fswatch -0 _build/default/bin/server.exe |
while read -d "" _; do
    printf "\nRestarting server.exe due to filesystem change\n"
    kill -9 ${PID}
    _build/default/bin/server.exe -- "$@" &
    PID=$!
done