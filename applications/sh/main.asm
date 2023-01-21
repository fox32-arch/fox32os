; fox32os shell

const CURSOR: 0x8A
const REDRAW_LINE: 0xFE

    pop [shell_terminal_stream_struct_ptr]
shell_task_return:
    call shell_clear_buffer
    call shell_print_prompt
shell_task_loop:
    mov r1, [shell_terminal_stream_struct_ptr]
    mov r2, shell_char_buffer
    call read

    movz.8 r0, [shell_char_buffer]
    cmp.8 r0, 0
    ifnz call shell_task_parse_key

    call yield_task
    rjmp shell_task_loop

shell_task_parse_key:
    ; first, check if enter, delete, or backspace was pressed
    cmp.8 r0, 0x1C ; enter
    ifz jmp shell_key_down_enter
    cmp.8 r0, 0x6F ; delete
    ifz jmp shell_key_down_backspace
    cmp.8 r0, 0x0E ; backspace
    ifz jmp shell_key_down_backspace

    ; then, overwrite the cursor
    mov r1, r0
    mov r0, 8 ; backspace character
    call print_character_to_terminal
    mov r0, r1

    ; then, add it to the text buffer and print it to the screen
    call scancode_to_ascii
    call print_character_to_terminal
    call shell_push_character

    ; then, print the cursor
    mov r0, CURSOR
    call print_character_to_terminal

    ; finally, redraw the line
    ; print character 3 times in order to execute the control character once (see terminal's text.asm for details)
    mov r0, REDRAW_LINE
    call print_character_to_terminal
    call print_character_to_terminal
    call print_character_to_terminal
    ret
shell_key_down_enter:
    ; clear the cursor from the screen
    mov r0, 8 ; backspace character
    call print_character_to_terminal
    mov r0, ' ' ; space character
    call print_character_to_terminal
    mov r0, 8 ; backspace character
    call print_character_to_terminal

    mov r0, 10 ; line feed
    call print_character_to_terminal

    mov r0, 0
    call shell_push_character

    call shell_parse_line
    call shell_clear_buffer

    call shell_print_prompt
    ret
shell_key_down_backspace:
    ; check if we are already at the start of the prompt
    mov r1, [shell_text_buf_ptr]
    cmp r1, shell_text_buf_bottom
    iflteq ret
    ; delete the last character from the screen, draw the cursor, and pop the last character from the buffer
    mov r0, 8 ; backspace character
    call print_character_to_terminal
    mov r0, ' ' ; space character
    call print_character_to_terminal
    mov r0, 8 ; backspace character
    call print_character_to_terminal
    call print_character_to_terminal
    mov r0, CURSOR ; cursor
    call print_character_to_terminal
    call shell_delete_character
    mov r0, REDRAW_LINE
    call print_character_to_terminal
    call print_character_to_terminal
    call print_character_to_terminal
    ret

shell_print_prompt:
    movz.8 r0, [shell_current_disk]
    add r0, '0'
    call print_character_to_terminal
    mov r0, shell_prompt
    call print_str_to_terminal
    mov r0, REDRAW_LINE
    call print_character_to_terminal
    call print_character_to_terminal
    call print_character_to_terminal
    ret

shell_parse_line:
    ; if the line is empty, just return
    cmp.8 [shell_text_buf_bottom], 0
    ifz ret

    ; separate the command from the arguments
    ; store the pointer to the arguments
    mov r0, shell_text_buf_bottom
    mov r1, ' '
    call shell_tokenize
    mov [shell_args_ptr], r0

    call shell_parse_command

    ret

; return tokens separated by the specified character
; returns the next token in the list
; inputs:
; r0: pointer to null-terminated string
; r1: separator character
; outputs:
; r0: pointer to next token or zero if none
shell_tokenize:
    cmp.8 [r0], r1
    ifz jmp shell_tokenize_found_token

    cmp.8 [r0], 0
    ifz mov r0, 0
    ifz ret

    inc r0
    jmp shell_tokenize
shell_tokenize_found_token:
    mov.8 [r0], 0
    inc r0
    ret

; parse up to 4 arguments into individual strings
; for example, "this is a test" will be converted to
;              r0: pointer to "this" data.8 0
;              r1: pointer to "is"   data.8 0
;              r2: pointer to "a"    data.8 0
;              r3: pointer to "test" data.8 0
; inputs:
; none
; outputs:
; r0: pointer to 1st null-terminated argument, or zero if none
; r1: pointer to 2nd null-terminated argument, or zero if none
; r2: pointer to 3rd null-terminated argument, or zero if none
; r3: pointer to 4th null-terminated argument, or zero if none
shell_parse_arguments:
    push r31

    mov r0, [shell_args_ptr]
    mov r1, ' '
    mov r31, 3
    push r0
shell_parse_arguments_loop:
    call shell_tokenize
    push r0
    loop shell_parse_arguments_loop
    pop r3
    pop r2
    pop r1
    pop r0

    pop r31
    ret

; push a character to the text buffer
; inputs:
; r0: character
; outputs:
; none
shell_push_character:
    push r1

    mov r1, [shell_text_buf_ptr]
    cmp r1, shell_text_buf_top
    ifgteq jmp shell_push_character_end
    mov.8 [r1], r0
    inc [shell_text_buf_ptr]
shell_push_character_end:
    pop r1
    ret

; pop a character from the text buffer and zero it
; inputs:
; none
; outputs:
; r0: character
shell_delete_character:
    push r1

    mov r1, [shell_text_buf_ptr]
    cmp r1, shell_text_buf_bottom
    iflteq jmp shell_delete_character_end
    dec [shell_text_buf_ptr]
    movz.8 r0, [r1]
    mov.8 [r1], 0
shell_delete_character_end:
    pop r1
    ret

; mark the text buffer as empty
; inputs:
; none
; outputs:
; none
shell_clear_buffer:
    push r0

    ; set the text buffer poinrer to the start of the text buffer
    mov [shell_text_buf_ptr], shell_text_buf_bottom

    ; set the first character as null
    mov r0, [shell_text_buf_ptr]
    mov.8 [r0], 0

    pop r0
    ret

; print a character to the terminal
; inputs:
; r0: ASCII character
; outputs:
; none
print_character_to_terminal:
    push r1
    push r2

    mov.8 [shell_char_buffer], r0
    mov r1, [shell_terminal_stream_struct_ptr]
    mov r2, shell_char_buffer
    call write

    pop r2
    pop r1
    ret

; print a string to the terminal
; inputs:
; r0: pointer to null-terminated string
; outputs:
; none
print_str_to_terminal:
    push r0
    push r2

    mov r1, [shell_terminal_stream_struct_ptr]
    mov r2, r0
print_str_to_terminal_loop:
    call write
    inc r2
    cmp.8 [r2], 0x00
    ifnz jmp print_str_to_terminal_loop

    pop r2
    pop r0
    ret

shell_text_buf_bottom: data.fill 0, 512
shell_text_buf_top:
shell_text_buf_ptr:    data.32 0 ; pointer to the current input character
shell_args_ptr:        data.32 0 ; pointer to the beginning of the command arguments

shell_current_disk: data.8 0

shell_prompt: data.str "> " data.8 CURSOR data.8 0

shell_terminal_stream_struct_ptr: data.32 0
shell_char_buffer: data.32 0

    #include "commands/commands.asm"
    #include "launch.asm"

    ; include system defs
    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
