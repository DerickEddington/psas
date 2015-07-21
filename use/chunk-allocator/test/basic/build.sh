# This file is source'd, in its own sub-shell, in its directory, by the main
# build.sh.

pushd arch/$arch

case $arch in
    x86-64)
        function parse {
            [[ "$1" =~ $SEGFILE_RE ]]
            echo 0x"${BASH_REMATCH[2]}${BASH_REMATCH[3]}${BASH_REMATCH[4]}${BASH_REMATCH[5]}"
        }
        save_sf=$(readlink segments/save_area)
        save_addr=$(parse $save_sf)
        prog_sf=$(readlink segments/program)
        prog_addr=$(parse $prog_sf)

        stack_sf=$(readlink segments/stack)
        stack_addr=$(parse $stack_sf)
        stack_size=128
        stack_ptr=$(printf '0x%016lX' $(( $stack_addr + (stack_size * 1024) )) )

        allocator_sf=$(readlink segments/chunk_allocator)
        allocator_addr=$(parse $allocator_sf)
        chunk_alloc_addr=$(< $topdir/arch/$arch/chunk_alloc.offset)
        chunk_alloc_addr=$(printf '0x%016lX' \
                                  $(( $allocator_addr + 0x$chunk_alloc_addr )) )
        chunk_free_addr=$(< $topdir/arch/$arch/chunk_free.offset)
        chunk_free_addr=$(printf '0x%016lX' \
                                 $(( $allocator_addr + 0x$chunk_free_addr )) )


        do-show $asm ${asm_opts[@]} -f bin \
                     -o basic.bin basic.nasm
        do-show disasm basic.bin

        do-show truncate -s ${stack_size}K segments/$stack_sf

        do-show $asm ${asm_opts[@]} -f bin \
                     -D save_area_rip=$prog_addr \
                     -D save_area_rsp=$stack_ptr \
                     -D save_area_user1=$chunk_alloc_addr \
                     -D save_area_user2=$chunk_free_addr \
                     -o segments/$save_sf \
                     $psas_dir/arch/$arch/save_area.nasm
        do-show hexprint segments/save_area

        do-show ln -s $psas_dir/arch/$arch/boot.bin segments/boot.bin
    ;;
esac

#popd  # Not necessary.
