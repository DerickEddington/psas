# This file is source'd, in its own sub-shell, in its directory, by the main
# clean.sh.

for D in arch/*/segments ; do
    for X in $D/{save_area,stack} ; do
        L=$(readlink $X)
        rm -v -f -r $D/$L
    done
done
