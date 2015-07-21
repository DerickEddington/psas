#!/bin/bash

set -e
set -u


topdir=$(readlink -f $(dirname $0))
psas_dir=$(readlink -f $topdir/../..)

source $psas_dir/build-defs.bash

pushd $topdir
echo "Building..."

pushd arch/$arch
case $arch in
    x86-64)
        asm_opts+=( -I $topdir/arch/$arch/ -I $psas_dir/arch/$arch/ )
        do-show $asm ${asm_opts[@]} -f bin \
                     -o chunk-allocator.bin chunk-allocator.nasm
        do-show disasm chunk-allocator.bin

        function offset_of_sym {
            local X=$(egrep "[[:space:]]*[[:xdigit:]]+[[:space:]]+[[:xdigit:]]+[[:space:]]+${1}\$" chunk_allocator.map)
            [[ "$X" =~ [[:space:]]*([[:xdigit:]]+) ]]
            echo "${BASH_REMATCH[1]}"
        }
        offset_of_sym _chunk_alloc > chunk_alloc.offset
        offset_of_sym _chunk_free > chunk_free.offset
    ;;
esac
popd

# Build tests by delegating to each.
for T in test/* ; do
    if [ -d $T -a -f $T/build.sh ]; then
        ( pushd $T
          PATH=$topdir/util:"$PATH"
          source ./build.sh )
    fi
done


echo "Done."
