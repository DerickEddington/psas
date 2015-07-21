# If DEBUG is set to anything non-null, debugging aspects will be built.
[ -v DEBUG ] && debug="$DEBUG" || debug=yes  # TODO: Change default to off.

gcc_opts=( -std=gnu99 -O1 -Wall ${debug:+ -DDEBUG} )

# TODO: Discover the arch of the host.
arch=${ARCH:-x86-64}

case $arch in
    x86-64)
        asm=${ASSEMBLER:-yasm}  # nasm or yasm
        asm_opts=( ${debug:+ -DDEBUG} )
        SEGFILE_RE='(([0-9A-F]{4})_([0-9A-F]{4})_([0-9A-F]{4})_([0-9A-F]{4}))_([RWX_]{3})'
        ndisasm_opts=( -b 64 )
    ;;
esac

function do-show {
    echo "-----------------------------------------------------------------"
    echo -- "$@"
    "$@"
    echo
}

function disasm {
    ndisasm "${ndisasm_opts[@]}" "$1" > "${1%.bin}".disasm
}

function hexprint {
    hexdump -C "$1" > "$1".hexdump
}

function pushd {
    builtin pushd "$1" > /dev/null
    pwd
}

function popd {
    builtin popd > /dev/null
}
