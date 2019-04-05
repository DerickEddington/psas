Old experiment of making a system for persistent address spaces for machine-code
programs to automatically resume execution immediately after wherever they
previously exited, to enable having programs whose persistent storage is
in-memory (as opposed to files or DBs).  This has its own unconventional linking
and ABI design that `mmap`s backing files to achieve persistent memory segments.

The test programs that exercise it can be run like:
```
./build.sh

HELLO=test/hello/arch/x86-64
./start $HELLO/segments entry_point
./start $HELLO/segments entry_point  # Resumes

./start test/c-entry/segments entry_point

use/chunk-allocator/build.sh
BASIC_ALLOC=use/chunk-allocator/test/basic/arch/x86-64
./start $BASIC_ALLOC/segments entry_point
./start $BASIC_ALLOC/segments entry_point  # Resumes
./start $BASIC_ALLOC/segments entry_point  # Resumes
./start $BASIC_ALLOC/segments entry_point  # Resumes
```
