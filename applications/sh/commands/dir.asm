; dir command

shell_dir_command_string: data.str "dir" data.8 0

shell_dir_command:
    mov r0, shell_dir_command_list_buffer
    movz.8 r1, [shell_current_disk]
    call ryfs_get_file_list
    cmp r0, 0
    ifz ret

    mov r31, r0
    mov r3, 0
shell_dir_command_loop:
    ; copy one file name from the list buffer to the file buffer
    mov r0, shell_dir_command_list_buffer
    add r0, r3
    mov r1, shell_dir_command_file_buffer
    mov r2, 11
    call copy_memory_bytes
    add r1, 11
    mov.8 [r1], 0

    ; then print the file name to the terminal
    mov r0, shell_dir_command_file_buffer
    call print_str_to_terminal

    ; new line
    mov r0, 10
    call print_character_to_terminal

    ; point to next file name in the buffer
    add r3, 11
    loop shell_dir_command_loop

    ret

shell_dir_command_list_buffer: data.fill 0, 341
shell_dir_command_file_buffer: data.fill 0, 12
