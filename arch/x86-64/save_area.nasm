%include "conv.nasm"

section .data

%macro zifnd 1
  %ifndef save_area_%1
    %define save_area_%1 0
  %endif
%endmacro

zifnd rax
zifnd rbx
zifnd rcx
zifnd rdx
zifnd rbp
zifnd rsi
zifnd rdi
zifnd r8
zifnd r9
zifnd r10
zifnd r11
zifnd r12
zifnd r13
zifnd r14
zifnd r15
zifnd rflags
zifnd rsp
zifnd rip

istruc save_area
  at save_area.rax,     dq save_area_rax
  at save_area.rbx,     dq save_area_rbx
  at save_area.rcx,     dq save_area_rcx
  at save_area.rdx,     dq save_area_rdx
  at save_area.rbp,     dq save_area_rbp
  at save_area.rsi,     dq save_area_rsi
  at save_area.rdi,     dq save_area_rdi
  at save_area.r8,      dq save_area_r8
  at save_area.r9,      dq save_area_r9
  at save_area.r10,     dq save_area_r10
  at save_area.r11,     dq save_area_r11
  at save_area.r12,     dq save_area_r12
  at save_area.r13,     dq save_area_r13
  at save_area.r14,     dq save_area_r14
  at save_area.r15,     dq save_area_r15
  at save_area.rflags,  dq save_area_rflags
  at save_area.rsp,     dq save_area_rsp
  at save_area.rip,     dq save_area_rip
  ; TODO: Whatever other registers that should be saved.
iend
