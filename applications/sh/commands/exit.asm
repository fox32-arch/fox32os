; exit command

shell_exit_command_string: data.strz "exit"

shell_exit_command:
    mov r0, [shell_batch_label_list_ptr]
    cmp r0, 0
    ifz call end_current_task

    mov r31, [shell_batch_lines_processed]
    dec r31
shell_exit_command_loop:
    mov r0, [shell_batch_label_list_ptr]
    mov r1, r31
    mul r1, 8
    add r0, r1
    cmp [r0], 0
    ifnz mov r0, [r0]
    ifnz call free_memory
    loop shell_exit_command_loop

    mov r0, [shell_batch_label_list_ptr]
    cmp r0, 0
    ifnz call free_memory
    call end_current_task
