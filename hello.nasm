%include "conv.nasm"

section .text

proc foo:
  lea carg1_rdi, [rel msg]
  mov carg2_rsi, msg_end - msg
  call_sysintf console_write
  mov carg1_rdi, 17
  call_sysintf exit

msg:
db 'Hello.',0xA,0
msg_end:
