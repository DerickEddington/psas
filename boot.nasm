%include "conv.nasm"

default abs

section .text

proc entry_point:
  ; This is called by C.  Upon entry, it is considered that no stack is
  ; available (the C stack is ignored except to return to C), and the only
  ; memory available is the save area.

  ; If instruction-pointer is null, then abort.
  mov rax, [save_area_location + save_area.rip]
  test rax, rax
  jz .abort

  ; If stack-pointer is null, then abort.
  mov rax, [save_area_location + save_area.rsp]
  test rax, rax
  jz .abort

  ; Copy current system interface values to fixed-address save-area where
  ; everything knows where to find it.
  mov rax, [carg1 + system_interface.alloc_segment]
  mov [save_area_location + save_area.sysif + system_interface.alloc_segment], rax
  mov rax, [carg1 + system_interface.free_segment]
  mov [save_area_location + save_area.sysif + system_interface.free_segment], rax
  mov rax, [carg1 + system_interface.console_read]
  mov [save_area_location + save_area.sysif + system_interface.console_read], rax
  mov rax, [carg1 + system_interface.console_write]
  mov [save_area_location + save_area.sysif + system_interface.console_write], rax

  ; Restore registers.
  mov rax, [save_area_location + save_area.rax]
  mov rbx, [save_area_location + save_area.rbx]
  mov rcx, [save_area_location + save_area.rcx]
  mov rdx, [save_area_location + save_area.rdx]
  mov rbp, [save_area_location + save_area.rbp]
  mov rsi, [save_area_location + save_area.rsi]
  mov rdi, [save_area_location + save_area.rdi]
  mov r8,  [save_area_location + save_area.r8]
  mov r9,  [save_area_location + save_area.r9]
  mov r10, [save_area_location + save_area.r10]
  mov r11, [save_area_location + save_area.r11]
  mov r12, [save_area_location + save_area.r12]
  mov r13, [save_area_location + save_area.r13]
  mov r14, [save_area_location + save_area.r14]
  mov r15, [save_area_location + save_area.r15]
  lea rsp, [save_area_location + save_area.rflags]
  popfq
  mov rsp, [save_area_location + save_area.rsp]
  ; Jump to saved rip.
  jmp [save_area_location + save_area.rip]

.abort:
  ret  ; Return to C so it can complain.
