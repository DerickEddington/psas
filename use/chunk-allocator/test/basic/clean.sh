# This file is source'd, in its own sub-shell, in its directory, by the main
# clean.sh.

for D in arch/*/segments ; do

    for X in $D/* ; do
        [ -L "$X" ] || rm -v -f "$X"
    done

done
