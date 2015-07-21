; x86_64 Linux

bits 64

%define PAGESIZE 4096

%define carg1_rdi rdi
%define carg2_rsi rsi
%define carg3_rdx rdx
%define carg4_rcx rcx
%define carg5_r8  r8
%define carg6_r9  r9
%define cret1_rax rax

; Align procedure entry-points.
%macro proc 1
  align 16
  %1
%endmacro

; Indirect jump, more efficiently.
%macro jmp_ind 1+
  likely jmp %1  ; NOTE: Intel documents say branch-hints are only for Jcc
                 ; instructions, but the use here seems to improve speed.
  ud2  ; help branch misprediction
%endmacro

; Branch hints.
%macro likely 1+
  db 0x3E
  %1
%endmacro

%macro unlikely 1+
  db 0x2E
  %1
%endmacro

; System interface procedures (that are C).
struc system_interface
  .alloc_segment: resq 1
  .free_segment:  resq 1
  .console_read:  resq 1
  .console_write: resq 1
  .exit:          resq 1
endstruc

; Save area.  It is located at a fixed address so that everything else can be
; hard-coded to expect it to be there.  The location is chosen to be the last
; page that can be addressed with signed 32-bit absolute-address immediate
; operands, which allows single-instruction calls to the procedure pointers that
; it stores.

%define save_area_location 0x80000000 - PAGESIZE

struc save_area
  .sysif: resb system_interface_size
  alignb 8
  .exit_save: resq 1
  .c_rsp: resq 1
  .rax:     resq 1
  .rbx:     resq 1
  .rcx:     resq 1
  .rdx:     resq 1
  .rbp:     resq 1
  .rsi:     resq 1
  .rdi:     resq 1
  .r8:      resq 1
  .r9:      resq 1
  .r10:     resq 1
  .r11:     resq 1
  .r12:     resq 1
  .r13:     resq 1
  .r14:     resq 1
  .r15:     resq 1
  .rflags:  resq 1
  .rsp:     resq 1
  .rip:     resq 1
  ; TODO: Whatever other registers that should be saved.
  alignb 128  ; Align to cache-line to help locality of user data.
  .user:
  ; The rest is available for the user.
  .user0: resq 1
  .user1: resq 1
  .user2: resq 1
  ; More .userN convenience labels could be declared if needed.
  .user_undef:
  alignb PAGESIZE
endstruc

%if save_area_location + save_area_size > 0x80000000
  %assign saz save_area_size
  %error save_area_size saz is too big.
%endif

%macro call_sysintf 1
  ; Ensure that the call to the C procedure is entered according to the C ABI.
  ; TODO: Is this sufficiently and correctly preparing according to the C ABI?

  ; Reinstate the C stack pointer and save the current.  The saved C rsp is
  ; expected to already be 32-byte aligned.
  xchg rsp, [abs save_area_location + save_area.c_rsp]

  ;emms  ; TODO: Is this good, to expect this to already be handled?
  ; TODO: What about other stuff like the MXCSR register and x87 status word?
  ; Maybe better to expect this to already be handled?

  ; Clear DF flag.
  cld

  ; Call the given procedure.
  call [abs save_area_location + save_area.sysif + system_interface.%1]
  ; Restore the stack pointer and re-save the C one.
  xchg rsp, [abs save_area_location + save_area.c_rsp]
%endmacro


%macro debug_write 1+
%ifdef DEBUG
  ; Save the registers that are not preserved across procedure calls according
  ; to the C ABI.
  push rax
  push rcx
  push rdx
  push rsi
  push rdi
  push r8
  push r9
  push r10
  push r11
  ; TODO: Save others that might need it, like the xmm registers?

  lea carg1_rdi, [rel %%msg]
  mov carg2_rsi, %%msg_end - %%msg
  call_sysintf console_write

  pop r11
  pop r10
  pop r9
  pop r8
  pop rdi
  pop rsi
  pop rdx
  pop rcx
  pop rax

  jmp %%msg_end
%%msg: db %1,0
%%msg_end:
%endif
%endmacro
