; text rendering routines

const TERMINAL_X_SIZE: 40
const TERMINAL_Y_SIZE: 25

const TEXT_COLOR:       0xFFFFFFFF
const BACKGROUND_COLOR: 0xFF000000

const FILL_TERM: 0xF0
const MOVE_CURSOR: 0xF1
const REDRAW_LINE: 0xFE
const REDRAW: 0xFF

; print a string to the terminal
; inputs:
; r0: pointer to null-terminated string
; outputs:
; none
print_str_to_terminal:
    push r0
    push r1

    mov r1, r0
print_str_to_terminal_loop:
    movz.8 r0, [r1]
    call print_character_to_terminal
    inc r1
    cmp.8 [r1], 0x00
    ifnz jmp print_str_to_terminal_loop

    pop r1
    pop r0
    ret

; print a single character to the terminal
; inputs:
; r0: ASCII character or control character
; outputs:
; none
print_character_to_terminal:
    ; if we're in a control state, or the char has the highest bit set
    ; then handle it as a control character
    ; allow character 0x8A (the block cursor itself) to pass through
    cmp.8 r0, 0x8A
    ifz jmp print_character_to_terminal_allow
    cmp.8 [terminal_state], 0
    ifnz jmp handle_control_character
    bts r0, 7
    ifnz jmp handle_control_character
print_character_to_terminal_allow:
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
    ; draw the line
    call redraw_terminal_line
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
    pop r2
    pop r1
    pop r0
    ret

; control character state machine
; inputs:
; r0: control character or parameter
; outputs:
; none
handle_control_character:
    cmp.8 [terminal_state], 0 ; got control character
    ifz mov.8 [terminal_control_char], r0
    ifz mov.8 [terminal_state], 1
    ifz ret
    cmp.8 [terminal_state], 1 ; got first parameter
    ifz mov.8 [terminal_control_parameter_1], r0
    ifz mov.8 [terminal_state], 2
    ifz ret
    cmp.8 [terminal_state], 2 ; got second parameter, now execute
    ifz mov.8 [terminal_control_parameter_2], r0
    ifz mov.8 [terminal_state], 0

    ; fill terminal
    cmp.8 [terminal_control_char], FILL_TERM
    ifz jmp handle_control_character_fill_term

    ; set cursor position
    cmp.8 [terminal_control_char], MOVE_CURSOR
    ifz jmp handle_control_character_set_cursor_pos

    ; redraw line
    cmp.8 [terminal_control_char], REDRAW_LINE
    ifz jmp handle_control_character_redraw_line

    ; redraw
    cmp.8 [terminal_control_char], REDRAW
    ifz jmp handle_control_character_redraw

    ret
handle_control_character_fill_term:
    push r0
    push r31
    mov r0, terminal_text_buf
    mov r31, 1000
handle_control_character_fill_term_loop:
    mov.8 [r0], [terminal_control_parameter_1]
    inc r0
    loop handle_control_character_fill_term_loop
    call redraw_terminal
    pop r31
    pop r0
    ret
handle_control_character_set_cursor_pos:
    call redraw_terminal_line
    mov.8 [terminal_x], [terminal_control_parameter_1]
    mov.8 [terminal_y], [terminal_control_parameter_2]
    ret
handle_control_character_redraw_line:
    call redraw_terminal_line
    ret
handle_control_character_redraw:
    call redraw_terminal
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
terminal_state: data.8 0 ; 0: normal, 1: awaiting first control parameter, 2: awaiting second control parameter
terminal_control_char: data.8 0
terminal_control_parameter_1: data.8 0
terminal_control_parameter_2: data.8 0
