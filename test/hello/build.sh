# This file is sourced by the main build.sh, in its own sub-shell.

pushd arch/$arch

case $arch in
    x86-64)
        hello_addr=0x00007F6085773000
        stack_addr=0x00007FE117EC7000
        stack_size=128
        stack_ptr=$(printf '0x%016lX' $(( $stack_addr + (stack_size * 1024) )) )

        do-show $asm ${asm_opts[@]} -f bin -o hello.bin hello.nasm
        do-show disasm hello.bin

        do-show truncate -s ${stack_size}K segments/stack

        do-show $asm ${asm_opts[@]} -f bin \
                     -D save_area_rip=$hello_addr \
                     -D save_area_rsp=$stack_ptr \
                     -o segments/save_area \
                     $topdir/arch/$arch/save_area.nasm
        do-show hexprint segments/save_area
    ;;
esac

#popd  # Not necessary.
