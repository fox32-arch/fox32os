; fox32os shell

    opton

const CURSOR:      0x8A
const FILL_TERM:   0xF0
const MOVE_CURSOR: 0xF1
const SET_COLOR:   0xF2
const REDRAW_LINE: 0xFE

    pop [shell_stream_struct_ptr]
    pop [shell_batch_filename_ptr]
    cmp [shell_stream_struct_ptr], 0
    ifz call end_current_task

    ; before dropping to an interactive prompt,
    ; check if an argument was passed
    cmp [shell_batch_filename_ptr], 0
    ifnz jmp shell_run_batch

shell_task_return:
    cmp [shell_batch_filename_ptr], 0
    ifnz jmp shell_run_batch_next

    cmp.8 [shell_redirect_next], 0
    ifnz mov [shell_stream_struct_ptr], [shell_old_stream_struct_ptr]
    ifnz dec.8 [shell_redirect_next]

    call shell_clear_buffer
    call shell_print_prompt
shell_task_loop:
    mov r0, 1
    mov r1, [shell_stream_struct_ptr]
    mov r2, shell_char_buffer
    call read

    movz.8 r0, [shell_char_buffer]
    cmp.8 r0, 0
    ifnz jmp shell_task_parse_key

    rjmp shell_task_loop

shell_task_parse_key:
    ; first, check if enter, delete, or backspace was pressed
    cmp.8 r0, 0x0a ; enter
    ifz jmp shell_key_down_enter
    cmp.8 r0, 0x7f ; delete
    ifz jmp shell_key_down_backspace
    cmp.8 r0, 0x08 ; backspace
    ifz jmp shell_key_down_backspace

    ; then, overwrite the cursor
    mov r1, r0
    mov r0, 8 ; backspace character
    call print_character_to_terminal
    mov r0, r1

    ; then, add it to the text buffer and print it to the screen
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
    jmp shell_task_loop
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

    jmp shell_task_return
shell_key_down_backspace:
    ; check if we are already at the start of the prompt
    mov r1, [shell_text_buf_ptr]
    cmp r1, shell_text_buf_bottom
    iflteq jmp shell_task_loop
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
    jmp shell_task_loop

shell_print_prompt:
    ; make a "fake" file struct to get the current dir name
    call get_current_directory
    mov r1, r0
    call get_current_disk_id
    mov r2, r0
    mov r0, shell_prompt_dir_temp_struct
    mov.8 [r0], r2
    mov.16 [r0+1], r1
    mov.8 [r0+7], 0
    mov r1, shell_prompt_dir_temp_struct
    ; get_dir_name will overwrite the temp struct with the name
    call get_dir_name
    mov r0, shell_prompt_dir_temp_struct
    call print_str_to_terminal
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
    ;cmp.8 [r0], '"'
    ;ifz jmp shell_tokenize_found_token_quote

    cmp.8 [r0], 0
    ifz mov r0, 0
    ifz ret

    inc r0
    jmp shell_tokenize
shell_tokenize_found_token:
    mov.8 [r0], 0
    inc r0
    cmp.8 r1, '"'
    ifz inc r0
    ret
;shell_tokenize_found_token_quote:
;    mov.8 [r0], 0
;    inc r0, 2
;    ret

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
    mov r31, 3
    rcall.16 shell_parse_arguments_post_tokenize
    push r0
    rcall.16 shell_parse_arguments_post_push
shell_parse_arguments_loop:
    call shell_tokenize
    rcall.16 shell_parse_arguments_post_tokenize
    push r0
    rcall.16 shell_parse_arguments_post_push
    loop shell_parse_arguments_loop
    pop r3
    pop r2
    pop r1
    pop r0

    pop r31
    ret
shell_parse_arguments_post_tokenize:
    mov r1, ' '
    mov [shell_parse_arguments_post_push_saved], 0
    cmp.8 [r0], '$'
    ifz rjmp.16 shell_parse_arguments_post_1
    cmp.8 [r0], '"'
    ifz mov r1, '"'
    ifz inc r0
    ret
shell_parse_arguments_post_1:
    mov [shell_parse_arguments_post_push_saved], r0
    cmp.8 [r0+1], 'r'
    ifz rjmp.16 shell_parse_arguments_post_1_register
    ; if we give a number without the 'r', interpret it as "register as value"
    inc r0
    rjmp.16 shell_parse_arguments_post_1_register_as_value
    ret
shell_parse_arguments_post_1_register:
    inc r0, 2
    cmp.8 [r0], 'd'
    ifz rjmp.16 shell_parse_arguments_post_1_register_as_decimal_string
    cmp.8 [r0], 'c'
    ifz rjmp.16 shell_parse_arguments_post_1_register_as_character
shell_parse_arguments_post_1_register_as_value:
    push r1
    mov r1, 10
    call string_to_int
    mul r0, 4
    add r0, shell_batch_regs
    mov r0, [r0]
    pop r1
    ret
shell_parse_arguments_post_1_register_as_decimal_string:
    push r1
    inc r0
    mov r1, 10
    call string_to_int
    mul r0, 4
    add r0, shell_batch_regs
    mov r0, [r0]
    pop r1

    push [shell_text_buf_ptr]
    push r10
    push r11
    push r12
    push r13
    mov r10, rsp
    mov r12, r0

    push.8 0
shell_parse_arguments_post_1_register_as_decimal_string_loop:
    push r12
    div r12, 10
    pop r13
    rem r13, 10
    mov r11, r13
    add r11, '0'
    push.8 r11
    cmp r12, 0
    ifnz jmp shell_parse_arguments_post_1_register_as_decimal_string_loop
    mov r11, rsp
shell_parse_arguments_post_1_register_as_decimal_string_push:
    movz.8 r0, [r11]
    call shell_push_character
    inc r11
    cmp r0, 0
    ifnz rjmp.16 shell_parse_arguments_post_1_register_as_decimal_string_push

    mov rsp, r10
    pop r13
    pop r12
    pop r11
    pop r10
    pop r0
    ret
shell_parse_arguments_post_1_register_as_character:
    push r1
    inc r0
    mov r1, 10
    call string_to_int
    mul r0, 4
    add r0, shell_batch_regs
    mov r0, [r0]
    push [shell_text_buf_ptr]
    call shell_push_character
    movz.8 r0, 0
    call shell_push_character
    pop r0
    pop r1
    ret
shell_parse_arguments_post_push:
    cmp [shell_parse_arguments_post_push_saved], 0
    ifnz mov r0, [shell_parse_arguments_post_push_saved]
    mov [shell_parse_arguments_post_push_saved], 0
    ret
shell_parse_arguments_post_push_saved: data.32 0

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

    ; set the text buffer pointer to the start of the text buffer
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
    push r0
    push r1
    push r2

    mov.8 [shell_char_buffer], r0
    mov r0, 1
    mov r1, [shell_stream_struct_ptr]
    mov r2, shell_char_buffer
    call write

    pop r2
    pop r1
    pop r0
    ret

; print a string to the terminal
; inputs:
; r0: pointer to null-terminated string
; outputs:
; none
print_str_to_terminal:
    push r0
    push r1
    push r2

    mov r1, [shell_stream_struct_ptr]
    mov r2, r0
print_str_to_terminal_loop:
    mov r0, 1
    call write
    inc r2
    cmp.8 [r2], 0x00
    ifnz jmp print_str_to_terminal_loop

    pop r2
    pop r1
    pop r0
    ret

print_decimal_to_terminal:
    push r0
    push r10
    push r11
    push r12
    push r13
    mov r10, rsp
    mov r12, r0

    push.8 0
print_decimal_to_terminal_loop:
    push r12
    div r12, 10
    pop r13
    rem r13, 10
    mov r11, r13
    add r11, '0'
    push.8 r11
    cmp r12, 0
    ifnz jmp print_decimal_to_terminal_loop
print_decimal_to_terminal_print:
    mov r0, rsp
    call print_str_to_terminal

    mov rsp, r10
    pop r13
    pop r12
    pop r11
    pop r10
    pop r0
    ret

shell_text_buf_bottom: data.fill 0, 512
shell_text_buf_top:
shell_text_buf_ptr:    data.32 0 ; pointer to the current input character
shell_args_ptr:        data.32 0 ; pointer to the beginning of the command arguments

shell_prompt: data.str "> " data.8 CURSOR data.8 0

shell_stream_struct_ptr: data.32 0
shell_old_stream_struct_ptr: data.32 0
shell_redirect_next: data.8 0
shell_redirect_stream_struct: data.fill 0, 32
shell_prompt_dir_temp_struct: data.fill 0, 32
shell_batch_filename_ptr: data.32 0
shell_char_buffer: data.32 0
shell_command_return_value: data.32 0
shell_batch_regs: data.fill 0, 1024 ; 256 regs x 4 bytes each

    #include "batch.asm"
    #include "commands/commands.asm"
    #include "launch.asm"

    ; include system defs
    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
