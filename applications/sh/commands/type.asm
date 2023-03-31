; type command

shell_type_command_string: data.strz "type"

shell_type_command:
    call shell_parse_arguments

    mov r3, r0

    call get_current_disk_id
    mov r1, r0
    mov r0, r3
    mov r2, shell_type_command_file_struct
    call open
    cmp r0, 0
    ifz jmp shell_type_command_file_not_found

    mov r0, shell_type_command_file_struct
    call get_size
    mov r31, r0
shell_type_command_loop:
    mov r0, 1
    mov r1, shell_type_command_file_struct
    mov r2, shell_type_command_file_character_buffer
    call read

    movz.8 r0, [shell_type_command_file_character_buffer]
    call print_character_to_terminal
    loop shell_type_command_loop

    mov r0, 10
    call print_character_to_terminal

    ret

shell_type_command_file_not_found:
    mov r0, shell_type_command_file_not_found_string
    call print_str_to_terminal
    mov r0, r3
    call print_str_to_terminal
    mov r0, 10
    call print_character_to_terminal

    ret

shell_type_command_file_struct: data.fill 0, 32
shell_type_command_file_character_buffer: data.8 0
shell_type_command_file_not_found_string: data.strz "file not found: "
