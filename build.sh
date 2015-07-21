#!/bin/bash

set -e
set -u


topdir=$(readlink -f $(dirname $0))

source $topdir/build-defs.bash

gcc_opts+=( -I $topdir )

pushd $topdir
echo "Building..."


# The start program should be built static to avoid having dynamic loading which
# might take address space that should be available to the user.
do-show gcc ${gcc_opts[@]} -static -o start start.c


pushd arch/$arch
case $arch in
    x86-64)
        asm_opts+=( -I $topdir/arch/$arch/ )
        # The bootstrap entry-point must be output as raw flat binary so that it
        # can be mmap'ed and used directly.
        do-show $asm ${asm_opts[@]} -f bin -o boot.bin boot.nasm
        do-show disasm boot.bin
    ;;
esac
popd


# Build utils before tests because the tests needs the utils.
pushd util
for F in *.c ; do
    # These are built static for consistency with the nature of the primary
    # system.
    do-show gcc ${gcc_opts[@]} -static -o ${F%.c} $F
done
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
