#include <stdio.h>
#include "system_interface.h"

#define offsetof(TYPE, MEMBER)  __builtin_offsetof (TYPE, MEMBER)

#define print_offset(X) \
  printf("system_interface." #X ":\t%li\n", \
         offsetof(struct system_interface, X))

int main (void) {
  print_offset(alloc_segment);
  print_offset(free_segment);
  print_offset(console_read);
  print_offset(console_write);
  return 0;
}
