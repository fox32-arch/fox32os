; dir command

shell_dir_command_string: data.strz "dir"

shell_dir_command:
    mov r0, shell_dir_command_header_string
    call print_str_to_terminal

    call get_current_disk_id
    mov r1, r0
    mov r0, shell_dir_command_list_buffer
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
    mov r2, 8
    call copy_memory_bytes
    add r1, 8
    mov.8 [r1], 0

    ; copy file type from the list buffer to the type buffer
    mov r0, shell_dir_command_list_buffer
    add r0, r3
    add r0, 8
    mov r1, shell_dir_command_type_buffer
    mov r2, 3
    call copy_memory_bytes
    add r1, 3
    mov.8 [r1], 0

    ; print the file name to the terminal
    mov r0, shell_dir_command_file_buffer
    call print_str_to_terminal

    ; space
    mov r0, ' '
    call print_character_to_terminal

    ; print the file type to the terminal
    mov r0, shell_dir_command_type_buffer
    call print_str_to_terminal

    ; two spaces
    mov r0, ' '
    call print_character_to_terminal
    call print_character_to_terminal

    ; get and print the file size
    ; call ryfs_open instead of open because this uses the internal filename style
    call get_current_disk_id
    mov r1, r0
    mov r0, shell_dir_command_list_buffer
    add r0, r3
    mov r2, shell_dir_command_temp_file_struct
    call ryfs_open
    cmp r0, 0
    ifz jmp shell_dir_command_failed_to_open_file
    mov r0, shell_dir_command_temp_file_struct
    call get_size
    call print_decimal_to_terminal
shell_dir_command_failed_to_open_file:
    ; new line
    mov r0, 10
    call print_character_to_terminal

    ; point to next file name in the buffer
    add r3, 11
    loop shell_dir_command_loop

    ret

shell_dir_command_list_buffer: data.fill 0, 341
shell_dir_command_file_buffer: data.fill 0, 9
shell_dir_command_type_buffer: data.fill 0, 4
shell_dir_command_temp_file_struct: data.fill 0, 32
shell_dir_command_header_string:
    data.8 SET_COLOR data.8 0x20 data.8 1 ; set the color to green
    data.str "file     type size" data.8 10
    data.8 SET_COLOR data.8 0x70 data.8 1 ; set the color to white
    data.8 0
