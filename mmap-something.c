#include <sys/mman.h>
#include <stdint.h>
#include <stdio.h>

int main (int argc, char** argv) {
  void* addr = mmap(NULL, 4096 * argc, PROT_READ, MAP_PRIVATE|MAP_ANONYMOUS,
                    -1, 0);
  printf("%016lX\n", (uintptr_t) addr);
  return 0;
}
