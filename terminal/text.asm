; text rendering routines

const TERMINAL_X_SIZE: 40
const TERMINAL_Y_SIZE: 25

const TEXT_COLOR:       0xFFFFFFFF
const BACKGROUND_COLOR: 0xFF000000

; print a single character to the terminal
; inputs:
; r0: ASCII character
; outputs:
; none
print_character_to_terminal:
    push r0
    push r1
    push r2

    cmp.8 r0, 0     ; null
    ifz jmp print_character_to_terminal_end
    cmp.8 r0, 8     ; backspace
    ifz jmp print_character_to_terminal_bs
    cmp.8 r0, 10    ; line feed
    ifz jmp print_character_to_terminal_lf
    cmp.8 r0, 13    ; carriage return
    ifz jmp print_character_to_terminal_cr

    ; check if we are at the end of this line
    cmp.8 [terminal_x], TERMINAL_X_SIZE
    ; if so, increment to the next line
    ifgteq mov.8 [terminal_x], 0
    ifgteq inc.8 [terminal_y]

    ; check if we need to scroll the display
    cmp.8 [terminal_y], TERMINAL_Y_SIZE
    ifgteq call scroll_terminal

    ; calculate coords for character...
    movz.8 r1, [terminal_x]
    movz.8 r2, [terminal_y]
    mul r2, TERMINAL_X_SIZE
    add r1, r2
    add r1, terminal_text_buf

    ; ...and print!!
    mov.8 [r1], r0
    inc.8 [terminal_x]
    jmp print_character_to_terminal_end
print_character_to_terminal_cr:
    ; return to the beginning of the line
    mov.8 [terminal_x], 0
    jmp print_character_to_terminal_end
print_character_to_terminal_lf:
    ; return to the beginning of the line and increment the line
    mov.8 [terminal_x], 0
    inc.8 [terminal_y]
    ; scroll the display if needed
    cmp.8 [terminal_y], TERMINAL_Y_SIZE
    ifgteq call scroll_terminal
    jmp print_character_to_terminal_end
print_character_to_terminal_bs:
    ; go back one character
    cmp.8 [terminal_x], 0
    ifnz dec.8 [terminal_x]
print_character_to_terminal_end:
    call redraw_terminal_line
    pop r2
    pop r1
    pop r0
    ret

; scroll the terminal
; inputs:
; none
; outputs:
; none
scroll_terminal:
    push r0
    push r1
    push r2
    push r31

    ; source
    mov r0, terminal_text_buf
    add r0, TERMINAL_X_SIZE

    ; destination
    mov r1, terminal_text_buf

    ; size
    mov r2, TERMINAL_X_SIZE
    mul r2, 24
    div r2, 4

    call copy_memory_words

    mov.8 [terminal_x], 0
    mov.8 [terminal_y], 24

    ; clear the last line
    mov r0, terminal_text_buf
    add r0, 960 ; 40 * 24
    mov r31, TERMINAL_X_SIZE
scroll_terminal_clear_loop:
    mov.8 [r0], 0
    inc r0
    loop scroll_terminal_clear_loop

    ; redraw the screen
    call redraw_terminal

    pop r31
    pop r2
    pop r1
    pop r0
    ret

; redraw the whole terminal
; inputs:
; none
; outputs:
; none
redraw_terminal:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r31

    mov r0, window_struct
    call get_window_overlay_number
    mov r5, r0

    mov r0, terminal_text_buf
    mov r1, 0
    mov r2, 16
    mov r3, TEXT_COLOR
    mov r4, BACKGROUND_COLOR
    mov r31, TERMINAL_Y_SIZE
redraw_terminal_loop_y:
    push r31
    mov r1, 0
    mov r31, TERMINAL_X_SIZE
redraw_terminal_loop_x:
    push r0
    movz.8 r0, [r0]
    call draw_font_tile_to_overlay
    movz.8 r0, 8
    add r1, r0
    pop r0
    inc r0
    loop redraw_terminal_loop_x
    pop r31
    movz.8 r6, 16
    add r2, r6
    loop redraw_terminal_loop_y

    pop r31
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

; redraw only the current line
; inputs:
; none
; outputs:
; none
redraw_terminal_line:
    push r0
    push r1
    push r2
    push r3
    push r4
    push r5
    push r6
    push r31

    mov r0, window_struct
    call get_window_overlay_number
    mov r5, r0

    movz.8 r0, [terminal_y]
    mul r0, TERMINAL_X_SIZE
    add r0, terminal_text_buf

    movz.8 r1, [terminal_y]
    mov r2, 16
    mul r2, r1
    add r2, 16

    mov r1, 0
    mov r3, TEXT_COLOR
    mov r4, BACKGROUND_COLOR

    mov r1, 0
    mov r31, TERMINAL_X_SIZE
redraw_terminal_line_loop_x:
    push r0
    movz.8 r0, [r0]
    call draw_font_tile_to_overlay
    movz.8 r0, 8
    add r1, r0
    pop r0
    inc r0
    loop redraw_terminal_line_loop_x

    pop r31
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    pop r0
    ret

terminal_x: data.8 0
terminal_y: data.8 0
terminal_text_buf: data.fill 0, 1000 ; 40x25 = 1000 bytes
