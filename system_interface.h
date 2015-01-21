#include <unistd.h>

// TODO: All the aligned attributes exist to ensure non-C code can assume fixed
// offsets for the fields. Is this the right way?

// The procedure pointer fields are aligned at 16-byte for x86_84.
// TODO: About alignment of other architectures.

struct system_interface
{
  void*  (*alloc_segment) (size_t, int)          __attribute__((aligned));
  int    (*free_segment)  (const void*)          __attribute__((aligned));
  size_t (*console_read)  (void*, size_t)        __attribute__((aligned));
  size_t (*console_write) (const void*, size_t)  __attribute__((aligned));
}
__attribute__((aligned));
