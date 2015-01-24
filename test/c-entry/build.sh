# This file is sourced by the main build.sh, in its own sub-shell.

do-show cc-raw.sh ${gcc_opts[@]} echo.c

do-show disasm echo.bin

seg_fn=$(mmap-something)_R_X
do-show ln -s ../echo.bin segments/$seg_fn
do-show ln -s $seg_fn segments/entry_point
