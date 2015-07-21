#!/bin/bash

set -e
set -u

topdir=$(readlink -f $(dirname $0))
psas_dir=$(readlink -f $topdir/../..)

source $psas_dir/build-defs.bash

pushd $topdir
echo "Cleaning..."

shopt -s globstar

to_delete=(
    **/*.{o,bin}
    **/*.{map,offset}
    **/*.{disasm,hexdump}
)

for F in ${to_delete[@]} ; do
    rm -v -f -r $F
done

# Clean tests by delegating to each.
for T in test/* ; do
    if [ -d $T -a -f $T/clean.sh ]; then
        ( pushd $T
          source ./clean.sh )
    fi
done

echo "Done."
