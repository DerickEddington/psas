#include "system_interface.h"

void foo (const struct system_interface* sys_iface)
{
  const char msg[] = "Hello.\n";
  sys_iface->console_write(msg, sizeof(msg) - 1);
}
