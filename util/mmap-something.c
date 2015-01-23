#include <sys/mman.h>
#include <stdint.h>
#include <stdio.h>

// TODO: Other architectures will need something a little different.

int main (int argc, char** argv) {
  void* addr = mmap(NULL, 4096 * argc, PROT_READ, MAP_PRIVATE|MAP_ANONYMOUS,
                    -1, 0);
  //printf("%016lX\n", (uintptr_t) addr);
  printf("%04lX_",    ((uintptr_t)addr) >> 48);
  printf("%04lX_",   (((uintptr_t)addr) >> 32) & 0xFFFF);
  printf("%04lX_",   (((uintptr_t)addr) >> 16) & 0xFFFF);
  printf("%04lX\n",   ((uintptr_t)addr)        & 0xFFFF);
  return 0;
}
