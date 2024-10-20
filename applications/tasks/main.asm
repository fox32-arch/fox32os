; print task info to the terminal

    pop [stream_ptr]

    mov r0, header
    call print

    call get_task_queue
    mov r10, r0
    mov r31, r1
task_loop:
    ; r10: pointer to this task entry
    ; r2: size of each task entry in bytes

    ; task ID
    cmp [r10], 10
    iflt mov r0, space
    iflt call print
    mov r0, [r10]
    call print_dec
    mov r0, separator
    call print

    ; rip value
    mov r0, [r10+4]
    call print_hex
    mov r0, separator2
    call print

    ; rsp value
    mov r0, [r10+8]
    call print_hex
    mov r0, separator2
    call print

    ; base address
    mov r0, [r10+12]
    call print_hex
    mov r0, nl
    call print

    add r10, r2

    loop task_loop
    call end_current_task

separator2: data.str " "
separator: data.strz " | "
space: data.strz " "
header: data.str "ID | rip value | rsp value | base addr" nl: data.8 10 data.8 0

print:
    push r0
    push r1
    push r2

    mov r2, r0            ; r2: source buffer
    call string_length    ; r0: length
    mov r1, [stream_ptr]  ; r1: stream pointer
    call write

    pop r2
    pop r1
    pop r0
    ret

print_hex:
    push r0
    push r1
    push r2
    push r10
    push r11
    push r12
    push r31

    mov r10, r0
    mov r31, 8
print_hex_loop:
    rol r10, 4
    movz.16 r11, r10
    and r11, 0x0F
    mov r12, hex_chars
    add r12, r11
    movz.8 r0, [r12]
    push.8 r0
    mov r2, rsp
    mov r0, 1
    mov r1, [stream_ptr]
    call write
    inc rsp
    loop print_hex_loop

    pop r31
    pop r12
    pop r11
    pop r10
    pop r2
    pop r1
    pop r0
    ret
hex_chars: data.str "0123456789ABCDEF"

print_dec:
    push r0
    push r10
    push r11
    push r12
    push r13
    mov r10, rsp
    mov r12, r0

    push.8 0
print_dec_loop:
    push r12
    div r12, 10
    pop r13
    rem r13, 10
    mov r11, r13
    add r11, '0'
    push.8 r11
    cmp r12, 0
    ifnz jmp print_dec_loop
    mov r0, rsp
    call print

    mov rsp, r10
    pop r13
    pop r12
    pop r11
    pop r10
    pop r0
    ret

stream_ptr: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../../fox32os/fox32os.def"
