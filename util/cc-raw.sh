#!/bin/bash

set -u
set -e

file="${@: -1}"

gcc -nostdlib "${@:1: $# - 1}" -c "$file"

objcopy -j .text -O binary "${file%.c}".o "${file%.c}".bin
