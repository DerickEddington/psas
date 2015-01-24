# This file is source'd, in its own sub-shell, in its directory, by the main
# build.sh.

do-show cc-raw.sh ${gcc_opts[@]} echo.c
do-show disasm echo.bin

seg_fn=$(mmap-something)_R_X
do-show ln -s ../echo.bin segments/$seg_fn
do-show ln -s $seg_fn segments/entry_point
