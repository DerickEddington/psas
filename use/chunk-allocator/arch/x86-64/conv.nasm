%define CHUNK_SIZE 128  ; Sized to be at least 1 cache-line, maybe 2.

; Linked-list of all the chunk-segments that the thread owns.
%define chunk_segment_list  [abs save_area_location + save_area.user0]

; Pointers to the procedures.
%define chunk_alloc  [abs save_area_location + save_area.user1]
%define chunk_free   [abs save_area_location + save_area.user2]
