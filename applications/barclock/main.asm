; menu bar clock

loop:
    ; if no time has passed, don't bother redrawing the clock
    in r0, 0x80000705
    cmp.8 r0, [second_counter]
    ifz jmp loop_end
    mov.8 [second_counter], r0

    ; hour
    in r0, 0x80000703
    mov r1, 584
    cmp r0, 12
    ifgt call afternoon
    mov r2, 0
    mov r3, 0xFFFFFFFF
    mov r4, 0xFF3F3F3F
    mov r5, 30
    call draw_decimal_to_overlay

    ; separator
    movz.8 r0, [second_counter]
    rem.8 r0, 2
    cmp r0, 0
    ifz mov r0, ':'
    ifnz mov r0, ' '
    call draw_font_tile_to_overlay
    add r1, 8

    ; minute
    in r0, 0x80000704
    cmp r0, 10
    iflt call minute_less_than_10
    call draw_decimal_to_overlay

loop_end:
    call yield_task
    rjmp loop

afternoon:
    sub r0, 12
    add r1, 8
    ret

minute_less_than_10:
    mov r0, 0
    call draw_decimal_to_overlay
    in r0, 0x80000704
    ret

second_counter: data.8 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
