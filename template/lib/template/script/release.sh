#!/bin/bash

set -e

if [ -d ".git" ]; then
  changes=$(git status --porcelain)
  branch=$(git rev-parse --abbrev-ref HEAD)

  if [ -n "${changes}" ]; then
    echo "Please commit staged files prior to bumping"
    exit 1
  elif [ "${branch}" != "master" ]; then
    echo "Please run the release script on master"
    exit 1
  else
    {% if package_manager == 'Esy' %}esy x {% endif %}dune-release tag
    {% if package_manager == 'Esy' %}esy x {% endif %}dune-release distrib
    {% if package_manager == 'Esy' %}esy x {% endif %}dune-release publish -y
    {% if package_manager == 'Esy' %}esy x {% endif %}dune-release opam pkg
    {% if package_manager == 'Esy' %}esy x {% endif %}dune-release opam submit --no-auto-open -y
  fi
else
  echo "This project is not a git repository. Run `git init` first to be able to release."
  exit 1
fi
