; head movement commands (ff, rw, etc.)

shell_ff_command_string: data.strz "ff"
shell_rw_command_string: data.strz "rw"
shell_callff_command_string: data.strz "callff"
shell_callrw_command_string: data.strz "callrw"
shell_ret_command_string: data.strz "ret"
shell_label_command_string: data.strz "label"

shell_ff_command:
    call shell_parse_arguments
    mov r1, shell_batch_label_to_look_for
    call copy_string
    mov.8 [shell_batch_head_mode], 1

    ret

shell_rw_command:
    call shell_parse_arguments
    mov r1, shell_batch_label_to_look_for
    call copy_string
    mov.8 [shell_batch_head_mode], 2

    ret

shell_callff_command:
    call shell_parse_arguments
    mov r1, shell_batch_label_to_look_for
    call copy_string
    mov.8 [shell_batch_head_mode], 1

    mov r0, shell_batch_file_struct
    call tell
    mov r1, shell_batch_ret_stack
    dec [shell_batch_ret_stack_offset]
    mov r2, [shell_batch_ret_stack_offset]
    mul r2, 4
    add r1, r2
    mov [r1], r0

    ret

shell_callrw_command:
    call shell_parse_arguments
    mov r1, shell_batch_label_to_look_for
    call copy_string
    mov.8 [shell_batch_head_mode], 2

    mov r0, shell_batch_file_struct
    call tell
    mov r1, shell_batch_ret_stack
    dec [shell_batch_ret_stack_offset]
    mov r2, [shell_batch_ret_stack_offset]
    mul r2, 4
    add r1, r2
    mov [r1], r0

    ret

shell_ret_command:
    mov r0, shell_batch_ret_stack
    mov r1, [shell_batch_ret_stack_offset]
    mul r1, 4
    add r0, r1
    mov r0, [r0]
    mov r1, shell_batch_file_struct
    call seek
    inc [shell_batch_ret_stack_offset]

    ret

shell_label_command:
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

    call shell_parse_arguments
    call add_label

    ret

; inputs:
; r0: pointer to label name
; r10: pointer to destination in label list
add_label:
    push r0
    call string_length
    inc r0
    call allocate_memory
    mov r1, r0
    pop r0
    push r1
    call copy_string
    pop r0
    mov [r10], r0
    mov r0, shell_batch_file_struct
    call tell
    mov [r10+4], r0

    ret
