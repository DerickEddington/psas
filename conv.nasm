; x86_64 Linux

bits 64

%define PAGESIZE 4096

%define carg1 rdi
%define carg2 rsi
%define carg3 rdx
%define carg4 rcx
%define carg5 r8
%define carg6 r9

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
endstruc

; Save area.

%define save_area_location 0x7FFFF000

struc save_area
  .sysif:   resb system_interface_size
  alignb 8
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
endstruc

%if save_area_location + save_area_size > 0x7FFFFFFF
  %error "save_area_size, " save_area_size ", too big."
%endif

%macro call_sysintf 1
  call [abs save_area_location + save_area.sysif + system_interface.%1]
%endmacro
