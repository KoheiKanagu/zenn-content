#!/bin/bash -euxo pipefail
WORKDIR=$(pwd)
cd "$(dirname "$0")"

textlint --fix articles/*.md
