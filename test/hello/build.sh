# This file is sourced by the main build.sh, in its own sub-shell.

pushd arch/$arch

case $arch in
    x86-64)
        function parse {
            [[ "$1" =~ $SEGFILE_RE ]]
            echo 0x"${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}${BASH_REMATCH[5]}"
        }
        save_sf=$(readlink segments/save_area)
        save_addr=$(parse $save_sf)
        hello_sf=$(readlink segments/program)
        hello_addr=$(parse $hello_sf)
        stack_sf=$(readlink segments/stack)
        stack_addr=$(parse $stack_sf)
        stack_size=128
        stack_ptr=$(printf '0x%016lX' $(( $stack_addr + (stack_size * 1024) )) )

        do-show $asm ${asm_opts[@]} -f bin -o hello.bin hello.nasm
        do-show disasm hello.bin

        do-show truncate -s ${stack_size}K segments/$stack_sf

        do-show $asm ${asm_opts[@]} -f bin \
                     -D save_area_rip=$hello_addr \
                     -D save_area_rsp=$stack_ptr \
                     -o segments/$save_sf \
                     $topdir/arch/$arch/save_area.nasm
        do-show hexprint segments/save_area
    ;;
esac

#popd  # Not necessary.
