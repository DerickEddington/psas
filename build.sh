#!/bin/bash

set -e
set -u


topdir=$(readlink -f $(dirname $0))

arch=${ARCH:-x86-64}
gcc_opts=( -std=gnu99 -O1 -Wall -I $topdir )

source $topdir/helpers.bash

pushd $topdir
echo "Building..."


# The start program should be built static to avoid having dynamic loading which
# might take address space that should be available to the user.
do-show gcc ${gcc_opts[@]} -static -o start start.c


pushd arch/$arch
case $arch in
    x86-64)
        asm=${ASSEMBLER:-yasm}  # nasm or yasm
        asm_opts=( -I $topdir/arch/$arch/ )  # For other scripts.
        # The bootstrap entry-point must be output as raw flat binary so that it
        # can be mmap'ed and used directly.
        do-show $asm -f bin -o boot.bin boot.nasm
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
