; memory allocator routines

; block header fields:
; data.32 size - size of block
; data.32 prev - pointer to previous free block, or zero
; data.32 next - pointer to next free block, or zero
; data.32 flag - zero if free, non-zero if used
; data.32 size - size of block (redundancy check)

const HEADER_SIZE: 20

initialize_allocator:
    push r0
    push r1

    mov [free_list_head], 0x00001000

    ; set the free block size to [memory_top] - [free_list_head]
    mov r0, [free_list_head]
    mov r1, [memory_top]
    sub r1, r0
    mov [r0], r1
    mov [r0+16], r1

    mov [total_heap_size], 0

    ; mark this as the only free block
    mov [r0+4], 0
    mov [r0+8], 0
    mov [r0+12], 0

    pop r1
    pop r0
    ret

; allocate a block of memory
; inputs:
; r0: size in bytes
; outputs:
; r0: pointer to allocated block (or zero if no blocks free of requested size)
allocate_memory:
    push r1
    push r10
    push r11
    push r31

    mov [block], [free_list_head]
    cmp [block], 0
    ifz jmp allocate_memory_bad

    ; r10: real_size = requested size + header size
    mov r10, r0
    add r10, HEADER_SIZE
allocate_memory_while_block:
    mov r0, [block]
    call block_get_size
    cmp r0, r10
    ifgteq jmp allocate_memory_good_block

    ; block = block->next
    mov r0, [block]
    call block_get_next
    mov [block], r0

    cmp [block], 0
    ifnz jmp allocate_memory_while_block
allocate_memory_bad:
    ; if we reach this point, no good blocks were found
    mov r0, 0

    pop r11
    pop r10
    pop r1
    ret
allocate_memory_good_block:
    mov r11, r10
    add r11, HEADER_SIZE
    add r11, 16
    mov r0, [block]
    call block_get_size
    cmp r0, r11
    ifgt jmp allocate_memory_good_block_carve

    ; next = block->next
    ; prev = block->prev
    mov r0, [block]
    call block_get_next
    mov [next], r0
    mov r0, [block]
    call block_get_prev
    mov [prev], r0

    cmp [next], 0
    ifnz call allocate_memory_good_block_set_nextprev

    cmp [prev], 0
    ifnz jmp allocate_memory_good_block_set_prevnext
    mov [free_list_head], [next]
allocate_memory_good_block_ret:
    mov r0, [block]
    call block_set_used
    mov r0, [block]
    add r0, HEADER_SIZE
    mov r31, r10
    sub r31, HEADER_SIZE
    push r0
allocate_memory_clear_loop:
    mov.8 [r0], 0
    inc r0
    loop allocate_memory_clear_loop
    pop r0

    add [total_heap_size], r10

    pop r31
    pop r11
    pop r10
    pop r1
    ret
allocate_memory_good_block_carve:
    ; block->size -= real_size
    mov r0, [block]
    call block_get_size
    sub r0, r10
    mov r1, r0
    mov r0, [block]
    call block_set_size

    ; block += block->size
    mov r0, [block]
    call block_get_size
    add [block], r0

    ; block->size = real_size
    mov r0, [block]
    mov r1, r10
    call block_set_size

    jmp allocate_memory_good_block_ret
allocate_memory_good_block_set_nextprev:
    ; next->prev = prev
    mov r0, [next]
    mov r1, [prev]
    call block_set_prev
    ret
allocate_memory_good_block_set_prevnext:
    ; prev->next = next
    mov r0, [prev]
    mov r1, [next]
    call block_set_next
    jmp allocate_memory_good_block_ret
block: data.32 0
next:  data.32 0
prev:  data.32 0
block_get_size:
    mov r0, [r0]
    ret
block_set_size:
    mov [r0], r1
    mov [r0+16], r1
    ret
block_get_prev:
    add r0, 4
    mov r0, [r0]
    ret
block_set_prev:
    add r0, 4
    mov [r0], r1
    ret
block_get_next:
    add r0, 8
    mov r0, [r0]
    ret
block_set_next:
    add r0, 8
    mov [r0], r1
    ret
block_set_used:
    add r0, 12
    mov [r0], 0xFFFFFFFF
    ret
block_set_free:
    add r0, 12
    mov [r0], 0x00000000
    ret

; free a block of memory
; inputs:
; r0: pointer to allocated block
; outputs:
; none
free_memory:
    push r0
    push r1
    push r2

    ; point to the header
    sub r0, HEADER_SIZE
    mov r2, r0

    cmp [r0], [r0+16] ; size redundancy check
    ifnz jmp free_memory_bad_size

    cmp [r0+12], 0
    ifz jmp free_memory_already_freed
    push r0
    call block_set_free
    pop r0

    ; subtract from the total heap size used for debugging
    sub [total_heap_size], [r0] ; r0 points to header.size

    ; add it to the free list
    mov r1, 0
    call block_set_prev
    mov r0, r2
    mov r1, [free_list_head]
    call block_set_next

    cmp [free_list_head], 0
    ifnz mov r1, r2
    ifnz mov r0, [free_list_head]
    ifnz call block_set_prev

    mov [free_list_head], r2
free_memory_ret:
    pop r2
    pop r1
    pop r0
    ret
free_memory_already_freed:
    mov r0, free_memory_already_freed_str
    call panic
    jmp free_memory_ret
free_memory_already_freed_str: data.str "attempted double free" data.8 10 data.8 0
free_memory_bad_size:
    mov r0, free_memory_bad_size_str
    call panic
    jmp free_memory_ret
free_memory_bad_size_str: data.str "bad size in block header" data.8 10 data.8 0

; get the current size of the heap
; inputs:
; none
; outputs:
; r0: size of heap in bytes
heap_usage:
    mov r0, [total_heap_size]
    ret

free_list_head: data.32 0
total_heap_size: data.32 0
memory_top: data.32 0
