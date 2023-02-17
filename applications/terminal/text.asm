; text rendering routines

const TERMINAL_X_SIZE: 40
const TERMINAL_Y_SIZE: 25

const FILL_TERM:   0xF0
const MOVE_CURSOR: 0xF1
const SET_COLOR:   0xF2
const REDRAW_LINE: 0xFE
const REDRAW:      0xFF

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
    push r3

    cmp.8 r0, 0     ; null
    ifz jmp print_character_to_terminal_end
    cmp.8 r0, 8     ; backspace
    ifz jmp print_character_to_terminal_bs
    cmp.8 r0, 10    ; line feed
    ifz jmp print_character_to_terminal_lf
    cmp.8 r0, 13    ; carriage return
    ifz jmp print_character_to_terminal_cr
    cmp.8 r0, 127   ; delete
    ifz jmp print_character_to_terminal_bs

    ; check if we are at the end of this line
    cmp.8 [terminal_x], TERMINAL_X_SIZE
    ; if so, increment to the next line
    ifgteq mov.8 [terminal_x], 0
    ifgteq inc.8 [terminal_y]

    ; check if we need to scroll the display
    cmp.8 [terminal_y], TERMINAL_Y_SIZE
    ifgteq call scroll_terminal

    ; calculate coords for character
    movz.8 r1, [terminal_x]
    movz.8 r2, [terminal_y]
    mul r2, TERMINAL_X_SIZE
    add r1, r2
    add r1, terminal_text_buf

    ; calculate coords for color
    movz.8 r2, [terminal_x]
    movz.8 r3, [terminal_y]
    mul r3, TERMINAL_X_SIZE
    add r2, r3
    add r2, terminal_color_buf

    ; and print!!
    mov.8 [r1], r0
    mov.8 [r2], [terminal_current_color_attribute]
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
    pop r3
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

    ; set color
    cmp.8 [terminal_control_char], SET_COLOR
    ifz jmp handle_control_character_set_color

    ret
handle_control_character_fill_term:
    push r0
    push r1
    push r31
    mov r0, terminal_text_buf
    mov r1, terminal_color_buf
    mov r31, 1000
handle_control_character_fill_term_loop:
    mov.8 [r0], [terminal_control_parameter_1]
    mov.8 [r1], [terminal_current_color_attribute]
    inc r0
    inc r1
    loop handle_control_character_fill_term_loop
    call redraw_terminal
    pop r31
    pop r1
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
handle_control_character_set_color:
    mov.8 [terminal_current_color_attribute], [terminal_control_parameter_1]
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

    ; copy text buffer

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

    ; copy color buffer

    ; source
    mov r0, terminal_color_buf
    add r0, TERMINAL_X_SIZE

    ; destination
    mov r1, terminal_color_buf

    ; size
    mov r2, TERMINAL_X_SIZE
    mul r2, 24
    div r2, 4

    call copy_memory_words

    mov.8 [terminal_x], 0
    mov.8 [terminal_y], 24

    ; clear the last line
    mov r0, terminal_text_buf
    mov r1, terminal_color_buf
    add r0, 960 ; 40 * 24
    add r1, 960 ; 40 * 24
    mov r31, TERMINAL_X_SIZE
scroll_terminal_clear_loop:
    mov.8 [r0], 0
    mov.8 [r1], [terminal_current_color_attribute]
    inc r0
    inc r1
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
    mov r2, 16
    mov r31, TERMINAL_Y_SIZE
redraw_terminal_loop_y:
    push r31
    mov r1, 0
    mov r31, TERMINAL_X_SIZE
redraw_terminal_loop_x:
    call get_color
    push r0
    movz.8 r0, [r0]
    call draw_font_tile_to_overlay
    add r1, 8
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
    mov r31, TERMINAL_X_SIZE
redraw_terminal_line_loop_x:
    call get_color
    push r0
    movz.8 r0, [r0]
    call draw_font_tile_to_overlay
    add r1, 8
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

; get the text color at the specified position
; inputs:
; r1: X coordinate
; r2: Y coordinate
; outputs:
; r3: foreground color
; r4: background color
get_color:
    push r1
    push r2

    ; get the character buffer coords from the actual coords
    sub r2, 16
    div r1, 8
    div r2, 16

    ; get the color attribute at the specified position
    mul r2, TERMINAL_X_SIZE
    add r2, r1
    add r2, terminal_color_buf
    movz.8 r2, [r2]

    ; get the foreground color
    mov r3, r2
    srl r3, 4
    mul r3, 4
    add r3, colors
    mov r3, [r3]

    ; get the background color
    mov r4, r2
    and r4, 0x0F
    mul r4, 4
    add r4, colors
    mov r4, [r4]

    pop r2
    pop r1
    ret

colors:
    data.32 0xff2e1e1e ; black
    data.32 0xffa88bf3 ; red
    data.32 0xffa1e3a6 ; green
    data.32 0xffafe2f9 ; yellow
    data.32 0xfffab489 ; blue
    data.32 0xffaca0eb ; magenta
    data.32 0xffd5e294 ; cyan
    data.32 0xfff4d6cd ; white
    data.32 0x00000000 ; transparent

terminal_x: data.8 0
terminal_y: data.8 0
terminal_text_buf: data.fill 0, 1000 ; 40x25 = 1000 bytes
terminal_color_buf: data.fill 0x70, 1000 ; 40x25 = 1000 bytes
terminal_current_color_attribute: data.8 0x70
terminal_state: data.8 0 ; 0: normal, 1: awaiting first control parameter, 2: awaiting second control parameter
terminal_control_char: data.8 0
terminal_control_parameter_1: data.8 0
terminal_control_parameter_2: data.8 0
