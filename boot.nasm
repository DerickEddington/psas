%include "conv.nasm"

default abs

section .text

proc entry_point:
  ; This is called by C.  Upon entry, it is considered that no stack is
  ; available (the C stack is ignored except to return to C), and that the only
  ; memory available is the save area.

  ; If instruction-pointer is null, then abort.
  mov rax, [save_area_location + save_area.rip]
  test rax, rax
  jz .abort
  ; If stack-pointer is null, then abort.
  mov rax, [save_area_location + save_area.rsp]
  test rax, rax
  jz .abort

  ; Save the C stack pointer.  Ensure it's 32-byte aligned for future calls to C
  ; procedures.  Adjust down if needed.
  and rsp, -32
  mov [save_area_location + save_area.c_rsp], rsp

  ; Copy current C system interface values to fixed-address save-area where
  ; everything knows where to find it.
  mov rax, [carg1_rdi + system_interface.alloc_segment]
  mov [save_area_location + save_area.sysif + system_interface.alloc_segment], rax
  mov rax, [carg1_rdi + system_interface.free_segment]
  mov [save_area_location + save_area.sysif + system_interface.free_segment], rax
  mov rax, [carg1_rdi + system_interface.console_read]
  mov [save_area_location + save_area.sysif + system_interface.console_read], rax
  mov rax, [carg1_rdi + system_interface.console_write]
  mov [save_area_location + save_area.sysif + system_interface.console_write], rax
  mov rax, [carg1_rdi + system_interface.exit]
  mov [save_area_location + save_area.sysif + system_interface.exit], rax
  ; Copy current other system interface values to fixed-address save-area where
  ; everything knows where to find it.
  lea rax, [rel exit_save]
  mov [save_area_location + save_area.exit_save], rax

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
  ; TODO: Whatever other registers that should be saved.
  lea rsp, [save_area_location + save_area.rflags]
  popfq
  mov rsp, [save_area_location + save_area.rsp]
  ; Jump to saved rip.
  jmp [save_area_location + save_area.rip]

.abort:
  ret  ; Return to C so it can complain.


proc exit_save:
  ; This procedure expects to be call'ed so that the pushed return instruction
  ; pointer is what the caller wants saved.  This is popped before doing pushfq
  ; so that the same stack space can be reused for the pushfq, to avoid using
  ; any more of the stack than the caller knew is OK.
  pop qword [save_area_location + save_area.rip]
  ; rflags
  pushfq
  pop qword [save_area_location + save_area.rflags]
  ; This procedure expects an argument, the exit code, to be on the stack below
  ; the return pointer.  The register we'll use to pass it to the exit procedure
  ; must be saved first.
  mov [save_area_location + save_area.rdi], rdi
  pop carg1_rdi
  ; Now the stack pointer is what the caller wants saved.
  mov [save_area_location + save_area.rsp], rsp
  ; The rest.
  mov [save_area_location + save_area.rax], rax
  mov [save_area_location + save_area.rbx], rbx
  mov [save_area_location + save_area.rcx], rcx
  mov [save_area_location + save_area.rdx], rdx
  mov [save_area_location + save_area.rbp], rbp
  mov [save_area_location + save_area.rsi], rsi
  mov [save_area_location + save_area.r8],  r8
  mov [save_area_location + save_area.r9],  r9
  mov [save_area_location + save_area.r10], r10
  mov [save_area_location + save_area.r11], r11
  mov [save_area_location + save_area.r12], r12
  mov [save_area_location + save_area.r13], r13
  mov [save_area_location + save_area.r14], r14
  mov [save_area_location + save_area.r15], r15
  ; TODO: Whatever other registers that should be saved.
  ; Call C procedure to exit the process.
  call_sysintf exit
