[map symbols chunk_allocator.map]


%include "psas/conv.nasm"
%include "chunk-allocator/conv.nasm"

; TODO: Make benchmark program and see if aligning branch targets to 16 or using
; likely/unlikely prefix hints helps.


%define CHUNK_SEGMENT_SIZE  128 * PAGESIZE  ; 512 KB
%define CHUNK_SEGMENT_MPROT  1 | 2  ; PROT_READ | PROT_WRITE

struc chunk_segment
  ; Linked-list of free chunks in the segment.
  .free_list: resq 1
  ; How many chunks are allocated in the segment.
  .count:     resq 1
  ; Pointer to a next chunk_segment that the thread owns.
  .next:      resq 1
  ; Pointer to a previous chunk_segment that the thread owns.
  .prev:      resq 1
  alignb CHUNK_SIZE
  .chunks:
  alignb PAGESIZE
  .pages:     resb CHUNK_SEGMENT_SIZE - .pages
endstruc

%if chunk_segment_size != CHUNK_SEGMENT_SIZE
  %error
%endif


struc free_chunk
  .next:   resq 1
  .unused: resb CHUNK_SIZE - .unused
endstruc

%macro clear_free_chunk 1
  mov qword [%1 + 8 * 0], 0
  mov qword [%1 + 8 * 1], 0
  mov qword [%1 + 8 * 2], 0
  mov qword [%1 + 8 * 3], 0
  mov qword [%1 + 8 * 4], 0
  mov qword [%1 + 8 * 5], 0
  mov qword [%1 + 8 * 6], 0
  mov qword [%1 + 8 * 7], 0
  mov qword [%1 + 8 * 8], 0
  mov qword [%1 + 8 * 9], 0
  mov qword [%1 + 8 * 10], 0
  mov qword [%1 + 8 * 11], 0
  mov qword [%1 + 8 * 12], 0
  mov qword [%1 + 8 * 13], 0
  mov qword [%1 + 8 * 14], 0
  mov qword [%1 + 8 * 15], 0
%endmacro



section .text

proc _chunk_alloc:
  mov rcx, chunk_segment_list
.find_free:
  ; Try to find a free chunk in a segment
  test rcx, rcx
  jz .no_free
  mov rdx, rcx
  mov rax, [rcx + chunk_segment.free_list]
  mov rcx, [rcx + chunk_segment.next]
  test rax, rax
  jz .find_free
  ; Found a free chunk
  mov rcx, [rax + free_chunk.next]
  mov [rdx + chunk_segment.free_list], rcx
  add qword [rdx + chunk_segment.count], 1
  ret

.no_free:
  ; Map a new segment
  mov carg1_rdi, CHUNK_SEGMENT_SIZE
  mov carg2_rsi, CHUNK_SEGMENT_MPROT
  call_sysintf alloc_segment
  cmp cret1_rax, -1  ; Check if returned value is MAP_FAILED
  je .cant_alloc
  lea rcx, [cret1_rax + chunk_segment.chunks]  ; First chunk of segment
  mov rsi, cret1_rax  ; Saved for later
  add rax, CHUNK_SEGMENT_SIZE - CHUNK_SIZE  ; Last chunk of segment
  xor edx, edx
.link_chunks:
  mov [rax + free_chunk.next], rdx
  mov rdx, rax
  sub rax, CHUNK_SIZE
  cmp rax, rcx
  ja .link_chunks
  mov [rsi + chunk_segment.free_list], rdx  ; 2nd chunk of segment
  mov qword [rsi + chunk_segment.count], 1
  ; Put new segment at head of list
  mov rdi, chunk_segment_list
  mov [rsi + chunk_segment.next], rdi
  test rdi, rdi
  jz .done
  mov [rdi + chunk_segment.prev], rsi
.done:
  mov chunk_segment_list, rsi
  ret  ; rax has 1st chunk of segment

.cant_alloc:
  xor eax, eax
  ret



proc _chunk_free:
  test carg1_rdi, CHUNK_SIZE - 1
  jnz .bug
  ; Find the chunk's segment
  mov rax, chunk_segment_list
.find:
  test rax, rax
  jz .bug
  lea rcx, [rax + chunk_segment.chunks]
  lea rdx, [rax + CHUNK_SEGMENT_SIZE]
  mov rsi, rax
  mov rax, [rax + chunk_segment.next]
  cmp carg1_rdi, rcx
  jb .find
  cmp carg1_rdi, rdx
  jae .find
  ; Found segment
  sub qword [rsi + chunk_segment.count], 1
  jc .bug
  jz .free_segment
  mov rax, [rsi + chunk_segment.free_list]
  mov [rsi + chunk_segment.free_list], carg1_rdi
  clear_free_chunk carg1_rdi
  mov [carg1_rdi + free_chunk.next], rax
  ret

.free_segment:
  mov rcx, [rsi + chunk_segment.next]
  mov rdx, [rsi + chunk_segment.prev]
  ; If head of segment list, must change head to next
  mov rax, chunk_segment_list
  cmp rax, rsi
  jnz .unlink
  mov chunk_segment_list, rcx
.unlink:
  ; Unlink from list
  test rdx, rdx
  jz .prev
  mov [rdx + chunk_segment.next], rcx
.prev:
  test rcx, rcx
  jz .done
  mov [rcx + chunk_segment.prev], rdx
.done:
  ; Unmap the segment
  mov carg1_rdi, rsi
  call_sysintf free_segment
  test cret1_rax, cret1_rax
  jnz .bug
  ret

.bug:
  ud2  ; Cause invalid instruction
