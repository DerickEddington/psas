case $arch in
    x86-64)
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
