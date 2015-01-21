#include "system_interface.h"

void foo (const struct system_interface* sys_iface)
{
  const char prompt[] = "Enter char: ";
  const char show[] = "Got: ";
  const char nl = '\n';
  int flag = 0;
  char c[2];
  do {
    if (flag) {
      sys_iface->console_write(show, sizeof(show) - 1);
      sys_iface->console_write(&c, 1);
      sys_iface->console_write(&nl, 1);
    } else flag = 1;
    sys_iface->console_write(prompt, sizeof(prompt) - 1);
  } while (sys_iface->console_read(&c, 2));  // Must read newline too.
}
