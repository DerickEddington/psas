%include "psas/conv.nasm"
%include "chunk-allocator/conv.nasm"

proc basic:
  call chunk_alloc
  test cret1_rax, cret1_rax
  jz .fail
  mov qword [rax + 8 * 0], 1
  mov qword [rax + 8 * 1], 2
  mov qword [rax + 8 * 2], 3
  mov qword [rax + 8 * 3], 4
  mov qword [rax + 8 * 4], 5
  mov qword [rax + 8 * 5], 6
  mov qword [rax + 8 * 6], 7
  mov qword [rax + 8 * 7], 8
  mov qword [rax + 8 * 8], 9
  mov qword [rax + 8 * 9], 10
  mov qword [rax + 8 * 10], 11
  mov qword [rax + 8 * 11], 12
  mov qword [rax + 8 * 12], 13
  mov qword [rax + 8 * 13], 14
  mov qword [rax + 8 * 14], 15
  mov qword [rax + 8 * 15], 16
  mov rbx, rax

  ; Save the program state and exit with code 1.
  push 1
  call [abs save_area_location + save_area.exit_save]
  ; The saved program will resume here.

  debug_write "Resumed 1",0xA
  call chunk_alloc
  test cret1_rax, cret1_rax
  jz .fail
  mov qword [rax + 8 * 0], -1
  mov qword [rax + 8 * 1], -2
  mov qword [rax + 8 * 2], -3
  mov qword [rax + 8 * 3], -4
  mov qword [rax + 8 * 4], -5
  mov qword [rax + 8 * 5], -6
  mov qword [rax + 8 * 6], -7
  mov qword [rax + 8 * 7], -8
  mov qword [rax + 8 * 8], -9
  mov qword [rax + 8 * 9], -10
  mov qword [rax + 8 * 10], -11
  mov qword [rax + 8 * 11], -12
  mov qword [rax + 8 * 12], -13
  mov qword [rax + 8 * 13], -14
  mov qword [rax + 8 * 14], -15
  mov qword [rax + 8 * 15], -16
  mov rcx, rax

  ; Save the program state and exit with code 2.
  push 2
  call [abs save_area_location + save_area.exit_save]
  ; The saved program will resume here.

  debug_write "Resumed 2",0xA
  mov carg1_rdi, rbx
  call chunk_free

  ; Save the program state and exit with code 3.
  push 3
  call [abs save_area_location + save_area.exit_save]
  ; The saved program will resume here.

  debug_write "Resumed 3",0xA
  mov carg1_rdi, rcx
  call chunk_free

  ; Save the program state and exit with code 4.
  push 4
  call [abs save_area_location + save_area.exit_save]

.fail:
  ud2
