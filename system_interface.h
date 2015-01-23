#include <unistd.h>

// TODO: The attributes exist to ensure non-C code can assume fixed offsets for
// the fields. Is this the best way?

struct
__attribute__((packed))
system_interface
{
  void*  (*alloc_segment) (size_t, int)
    __attribute__((aligned(sizeof(void*))));
  int    (*free_segment)  (const void*)
    __attribute__((aligned(sizeof(void*))));
  size_t (*console_read)  (void*, size_t)
    __attribute__((aligned(sizeof(void*))));
  size_t (*console_write) (const void*, size_t)
    __attribute__((aligned(sizeof(void*))));
  void   (*exit) (int)
    __attribute__((aligned(sizeof(void*))));
};
