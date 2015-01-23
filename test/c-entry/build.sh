# This file is sourced by the main build.sh, in its own sub-shell.

do-show cc-raw.sh ${gcc_opts[@]} echo.c

do-show disasm echo.bin

do-show ln -s ../echo.bin segments/$(mmap-something)_R_X
