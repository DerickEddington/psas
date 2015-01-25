%include "psas/conv.nasm"

section .text

proc foo:
  ; Push something to see in the stack segment file.
  push 0x11223344
  ; Print 1st hello.
  lea carg1_rdi, [rel msg1]
  mov carg2_rsi, msg1_end - msg1
  call_sysintf console_write
  ; Push something else, after call_sysintf, to see in the stack segment file.
  push -0x778899AB  ; 0xFFFFFFFF88776655

  ; Set registers to something to see in the save-area segment file.
  xor eax, eax
  sub rax, 1  ; Cause the rflags register to be something to see.
  mov eax, 1
  mov ebx, 2
  mov ecx, 3
  mov edx, 4
  mov ebp, 5
  mov esi, 6
  mov edi, 7
  mov r8d, 8
  mov r9d, 9
  mov r10d, 10
  mov r11d, 11
  mov r12d, 12
  mov r13d, 13
  mov r14d, 14
  mov r15d, 15

  ; Save the program state and exit with code 7.
  push 7
  call [abs save_area_location + save_area.exit_save]

  ; The saved program will resume here.

  ; Pop the -0x778899AB into a register, which will be saved below.
  pop rbx
  ; Print 2nd hello.
  lea carg1_rdi, [rel msg2]
  mov carg2_rsi, msg2_end - msg2
  call_sysintf console_write
  ; Pop the 0x11223344 into a register, which will be saved below.
  pop r15
  ; Save the program state and exit with code 17.
  push 17
  call [abs save_area_location + save_area.exit_save]
  ; In case it's resumed again
  ud2


msg1:
db 'Hello 1.',0xA,0
msg1_end:
msg2:
db 'Hello 2.',0xA,0
msg2_end:
