    mov r0, 0
loop:
    inc r0
    mov r1, 16
    mov r2, 16
    mov r3, 0xFFFFFFFF
    mov r4, 0xFF000000
    call [0xF004200C] ; fox32rom: draw_decimal_to_background

    push r0
    mov r0, 1 ; fox32os: YieldProcess
    int 0x80
    pop r0

    jmp loop
