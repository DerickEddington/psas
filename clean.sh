#!/bin/bash

shopt -s globstar

to_delete=(
    start
    **/*.{o,bin}
    util/{mmap-something,system_interface_offsets}
    **/*.{disasm,hexdump}
)

echo "Cleaning..."

for F in ${to_delete[@]} ; do
    rm -v -f -r $F
done

# Clean tests by delegating to each.
for T in test/* ; do
    if [ -d $T -a -f $T/clean.sh ]; then
        ( pushd $T && source ./clean.sh)
    fi
done

echo "Done."
