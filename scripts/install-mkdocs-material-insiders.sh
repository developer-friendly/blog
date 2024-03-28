#!/usr/bin/env bash

set -eu

version=${1:-''}

if [ -z "$version" ]; then
  echo "Using latest version of mkdocs-material-insiders"
  version_suffix=""
else
  echo "Using version $version of mkdocs-material-insiders"
  version_suffix="@$version"
fi

pip install "mkdocs-material[imaging] @ git+https://${GH_TOKEN}@github.com/squidfunk/mkdocs-material-insiders.git${version_suffix}"
