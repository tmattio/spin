#!/bin/bash

set -e

function type() {
  green=$(tput setaf 2)
  normal=$(tput sgr0)
  printf "%s" "${green}➜  ${normal}"
  echo "$*" | pv -qL $((10 + (-2 + RANDOM % 5)))
}

type 'spin ls'
spin ls

sleep 1.5
echo ""

clear

export SPIN_CREATE_SWITCH=false

type 'spin new cli my-cli'
SPIN_PROJECT_NAME=Demo spin new cli my-cli --default

sleep 1.5
echo ""

clear
