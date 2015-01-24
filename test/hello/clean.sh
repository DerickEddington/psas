# This file is sourced by the main build.sh, in its own sub-shell.

for D in arch/*/segments ; do
    for X in $D/{save_area,stack} ; do
        L=$(readlink $X)
        rm -v -f -r $D/$L
    done
done
