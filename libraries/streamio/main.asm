    opton

jump_table:
    data.32 print_character
    data.32 print_string
    data.32 print_decimal
    data.32 0x00000000 ; end jump table

const ROM_string_length: 0xF0046018
const OS_write: 0x00000D20

; print a single character to the given stream
; inputs:
; r0: character byte
; r1: stream pointer
; outputs:
; none
print_character:
    push r2

    push r0
    mov r2, rsp
    mov r0, 1
    call [OS_write]
    pop r0

    pop r2
    ret

; print a null-terminated string to the given stream
; inputs:
; r0: pointer to null-terminated string
; r1: stream pointer
; outputs:
; none
print_string:
    push r0
    push r2

    mov r2, r0
    call [ROM_string_length]
    call [OS_write]

    pop r2
    pop r0
    ret

; print a decimal integer to the given stream
; inputs:
; r0: integer
; r1: stream pointer
; outputs:
; none
print_decimal:
    push r0
    push r10
    push r11
    push r12
    push r13
    mov r10, rsp
    mov r12, r0

    push.8 0
print_decimal_loop:
    push r12
    div r12, 10
    pop r13
    rem r13, 10
    mov r11, r13
    add r11, '0'
    push.8 r11
    cmp r12, 0
    ifnz jmp print_decimal_loop

    mov r0, rsp
    call print_string

    mov rsp, r10
    pop r13
    pop r12
    pop r11
    pop r10
    pop r0
    ret
