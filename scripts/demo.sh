#!/bin/bash

set -e

function type() {
  blue=$(tput setaf 2)
  normal=$(tput sgr0)
  printf "%s" "${blue}➜  ${normal}"
  echo "$*" | pv -qL $((10 + (-2 + RANDOM % 5)))
}

type 'spin ls'
spin ls

sleep 2
echo ""

clear

type 'spin new cli my-cli --default'
printf 'My CLI\n' | spin new cli my-cli --default

sleep 5
echo ""
