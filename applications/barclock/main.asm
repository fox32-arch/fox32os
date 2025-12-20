; menu bar clock

    opton

    ; get the background color of the menu bar by pulling the first pixel of overlay 30
    in r0, 0x8000021E
    mov r0, [r0+24] ; 6 pixels to the right to skip any menu bar corners
    mov [bg_color], r0
    not r0
    or r0, 0xFF000000
    mov [fg_color], r0

loop:
    ; redraw the window title if the active window has changed
    call get_active_window_struct
    cmp r0, [active_window_struct_ptr]
    ifnz mov.8 [second_counter], 0xFF ; force clock redraw
    ifnz call draw_window_title

    ; if no time has passed, don't bother redrawing the clock
    in r0, 0x80000705
    cmp.8 r0, [second_counter]
    ifz jmp loop_end
    mov.8 [second_counter], r0

    ; hour
    in r0, 0x80000703
    cmp r0, 0
    ifz mov r0, 12
    mov r1, 584
    cmp r0, 12
    ifgt call afternoon
    mov r2, 0
    mov r3, [fg_color]
    mov r4, [bg_color]
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

draw_window_title:
    mov [active_window_struct_ptr], r0

    ; if there is no active window, clear the menu bar and return
    cmp r0, 0
    ifz call clear_menu_bar
    cmp r0, 0
    ifz ret

    ; get the title string pointer
    add r0, 12
    mov r0, [r0]

    ; get the length of the string
    mov r1, r0
    call string_length

    ; calculate the position of the text
    mov r2, 574
    mul r0, 8
    sub r2, r0
    mov r0, r1
    mov r1, r2

    ; draw the text
    mov r2, 0
    mov r3, [fg_color]
    mov r4, [bg_color]
    mov r5, 30
    call draw_str_to_overlay

    ret

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
active_window_struct_ptr: data.32 0

bg_color: data.32 0
fg_color: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
