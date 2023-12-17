; batch file routines

; run a batch file whose name is pointed to by [shell_batch_filename_ptr]
; the batch file must end with `exit;`
; inputs:
; none
; outputs:
; none (does not return)
shell_run_batch:
    ; open the batch file
    call get_current_disk_id
    mov r1, r0
    mov r0, [shell_batch_filename_ptr]
    mov r2, shell_batch_file_struct
    call open
    cmp r0, 0
    ifz jmp shell_run_batch_failed_to_open

shell_run_batch_next:
    cmp.8 [shell_redirect_next], 0
    ifnz mov [shell_stream_struct_ptr], [shell_old_stream_struct_ptr]
    ifnz dec.8 [shell_redirect_next]
    call shell_clear_buffer
shell_run_batch_loop:
    ; read a character from the file
    mov r0, 1
    mov r1, shell_batch_file_struct
    mov r2, shell_batch_file_char_buffer
    call read

    ; if it isn't a semicolon or linefeed, push it to the command buffer
    ; if it is a semicolon, run the command
    movz.8 r0, [shell_batch_file_char_buffer]
    cmp.8 r0, ';'
    ifz jmp shell_run_batch_end_of_line
    cmp.8 r0, 10
    ifnz call shell_push_character

    call yield_task
    rjmp shell_run_batch_loop
shell_run_batch_end_of_line:
    mov r0, 0
    call shell_push_character
    call shell_parse_line
    rjmp shell_run_batch_next

shell_run_batch_failed_to_open:
    mov r0, shell_run_batch_failed_to_open_string
    call print_str_to_terminal
    call end_current_task

shell_batch_file_struct: data.fill 0, 32
shell_batch_file_char_buffer: data.8 0
shell_run_batch_failed_to_open_string: data.str "failed to open batch file" data.8 10 data.8 0
