; memory allocator routines
; this is a very basic memory allocator, it doesn't even allow freeing
; TODO: make this better

const MEMORY_TOP: 0x02000000

; allocate a block of memory
; inputs:
; r0: size in bytes
; outputs:
; r0: pointer to allocated block (or zero if no blocks free)
allocate_memory:
    push r1
    push r2

    mov r1, MEMORY_TOP
    mov r2, [free_base]
    sub r1, r2
    cmp r1, r0
    iflteq jmp allocate_memory_full
    mov r1, [free_base]
    add [free_base], r0
    mov r0, r1

    pop r2
    pop r1
    ret
allocate_memory_full:
    mov r0, 0

    pop r2
    pop r1
    ret

free_base: data.32 kernel_bottom
