#!/bin/bash

function bump_source() {
  search='(let version = ").+(")'
  replace="\1$2\2"
  sed -i ".tmp" -E "s/${search}/${replace}/g" "$1"
  rm "$1.tmp"
}

function bump_all() {
  output=$(npm version "${release}" --no-git-tag-version)
  version=${output:1}
  bump_source "bin/package.re" "$version"
}

version=$(sed -nE 's/^version: "(.*)"$/\1/p' inquire.opam)

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
    bump_all
    git add .
    git commit -m "Bump to ${version}"
    dune-release tag ${version} -y
    dune-release distrib
    dune-release publish -y
    dune-release opam submit --no-auto-open -y
    git tag -a "${output}" -m "${version}"
    git push origin --tags
  fi
else
  bump_all
fi
