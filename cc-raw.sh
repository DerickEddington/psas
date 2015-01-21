#!/bin/bash

set -u
set -e

file="$1"

gcc -Wall -std=gnu99 -nostdlib "${@:2}" -c "$file"

objcopy -j .text -O binary "${file%.c}".o "${file%.c}".bin
