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

    ; are we in fast-forward mode?
    cmp.8 [shell_batch_head_mode], 1
    ifz jmp shell_run_batch_ff

    ; are we in rewind mode?
    cmp.8 [shell_batch_head_mode], 2
    ifz jmp shell_run_batch_rw

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
    inc [shell_batch_lines_processed]
    call shell_parse_line
    rjmp shell_run_batch_next

shell_run_batch_ff_next:
    call shell_clear_buffer
shell_run_batch_ff:
    ; read a character from the file
    mov r0, 1
    mov r1, shell_batch_file_struct
    mov r2, shell_batch_file_char_buffer
    call read

    ; if it isn't a semicolon or linefeed, push it to the command buffer
    ; if it is a semicolon, check for a label
    movz.8 r0, [shell_batch_file_char_buffer]
    cmp.8 r0, ';'
    ifz jmp shell_run_batch_ff_check_label
    cmp.8 r0, 10
    ifnz call shell_push_character
    jmp shell_run_batch_ff ; TODO: timeout? error handling?
shell_run_batch_ff_check_label:
    inc [shell_batch_lines_processed]

    mov r0, 0
    call shell_push_character
    mov r0, shell_text_buf_bottom
    mov r1, ' '
    call shell_tokenize
    mov [shell_args_ptr], r0

    mov r0, shell_text_buf_bottom
    mov r1, shell_label_command_string
    call compare_string
    ifnz jmp shell_run_batch_ff_next

    ; we're at a label, now compare the actual label
    mov r0, [shell_args_ptr]
    mov r1, shell_batch_label_to_look_for
    call compare_string
    ifnz jmp shell_run_batch_ff_next

    ; add the label we just reached
    mov r0, [shell_batch_label_list_ptr]
    mov r1, [shell_batch_lines_processed]
    mul r1, 8
    call shell_reallocate

    mov [shell_batch_label_list_ptr], r0
    mov r1, [shell_batch_lines_processed]
    dec r1
    mul r1, 8
    add r0, r1
    mov r10, r0
    mov r0, shell_batch_label_to_look_for
    call add_label

    ; if we reach this point then we're at the requested label, resume execution
    mov.8 [shell_batch_head_mode], 0
    jmp shell_run_batch_next

shell_run_batch_rw:
    mov r0, [shell_batch_label_list_ptr]
    mov r1, [shell_batch_lines_processed]
    mul r1, 8
    call shell_reallocate
    mov [shell_batch_label_list_ptr], r0

    mov r31, [shell_batch_lines_processed]
    dec r31
shell_run_batch_rw_loop:
    mov r0, [shell_batch_label_list_ptr]
    cmp r0, 0
    ifz jmp shell_run_batch_rw_fail
    mov r1, r31
    mul r1, 8
    add r0, r1
    cmp [r0], 0
    ifnz call shell_run_batch_rw_check_label
    loop shell_run_batch_rw_loop
shell_run_batch_rw_fail:
    mov r0, shell_run_batch_failed_to_find_rw_label
    call print_str_to_terminal
    jmp shell_exit_command
shell_run_batch_rw_check_label:
    mov r0, [r0]
    mov r1, shell_batch_label_to_look_for
    call compare_string
    ifnz ret

    ; if we reach this point then we're at the requested label, resume execution
    sub [shell_batch_lines_processed], r31
    mov r0, [shell_batch_label_list_ptr]
    mov r1, r31
    mul r1, 8
    add r0, r1
    mov r0, [r0+4]
    mov r1, shell_batch_file_struct
    call seek
    mov.8 [shell_batch_head_mode], 0
    pop r0 ; pop return address
    jmp shell_run_batch_next

shell_run_batch_failed_to_open:
    mov r0, shell_run_batch_failed_to_open_string
    call print_str_to_terminal
    call end_current_task

; inputs:
; r0: pointer to old block
; r1: new size
; outputs:
; r0: pointer to new block
shell_reallocate:
    cmp r1, 0
    ifz ret
    cmp r0, 0
    ifz jmp shell_reallocate_all_new
    cmp r1, [shell_reallocate_old_size]
    ifz ret
    push r31
    push r2
    push r0
    mov r0, r1
    call allocate_memory
    mov r2, [shell_reallocate_old_size]
    mov [shell_reallocate_old_size], r1
    mov r31, r1
    push r0
shell_reallocate_clear_loop:
    mov.8 [r0], 0
    inc r0
    loop shell_reallocate_clear_loop
    pop r1
    pop r0
    cmp r2, 0
    ifnz call copy_memory_bytes
    call free_memory
    pop r2
    pop r31
    mov r0, r1
    ret
shell_reallocate_all_new:
    mov r0, r1
    call allocate_memory
    mov [shell_reallocate_old_size], r1
    mov r31, r1
    push r0
shell_reallocate_clear_loop2:
    mov.8 [r0], 0
    inc r0
    loop shell_reallocate_clear_loop2
    pop r0
    ret
shell_reallocate_old_size: data.32 0

shell_batch_file_struct: data.fill 0, 32
shell_batch_file_char_buffer: data.8 0
shell_run_batch_failed_to_open_string: data.str "failed to open batch file" data.8 10 data.8 0
shell_run_batch_failed_to_find_rw_label: data.str "failed to find label for rw" data.8 10 data.8 0
shell_batch_head_mode: data.8 0
shell_batch_label_to_look_for: data.fill 0, 128
shell_batch_ret_stack: data.fill 0, 128
shell_batch_ret_stack_offset: data.32 32
shell_batch_label_list_ptr: data.32 0
shell_batch_lines_processed: data.32 0
