#!/bin/bash
set -euxo pipefail

textlint --fix articles/*.md
