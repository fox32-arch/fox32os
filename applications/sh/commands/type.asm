; type command

shell_type_command_string: data.strz "type"

; FIXME: check string length before blindly copying
shell_type_command:
    call shell_parse_arguments

    ; r0: file name
    ; r1: file extension

    ; copy empty file name
    push r1
    push r0
    mov r0, shell_type_command_file_empty
    mov r1, shell_type_command_file
    mov r2, 11
    call copy_memory_bytes

    ; copy file name
    pop r0
    mov r1, shell_type_command_file
    call custom_copy_string

    ; copy file extension
    pop r0
    mov r1, shell_type_command_file
    add r1, 8
    call custom_copy_string
    add r1, 3
    mov.8 [r1], 0

    ; open the file
    mov r0, shell_type_command_file
    movz.8 r1, [shell_current_disk]
    mov r2, shell_type_command_file_struct
    call open
    cmp r0, 0
    ifz jmp shell_type_command_file_not_found

    mov r0, shell_type_command_file_struct
    call ryfs_get_size
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
    mov r0, shell_type_command_file
    call print_str_to_terminal
    mov r0, 10
    call print_character_to_terminal

    ret

custom_copy_string:
    push r0
    push r1
    push r2
custom_copy_string_loop:
    mov.8 r2, [r0]
    mov.8 [r1], r2
    inc r0
    inc r1
    cmp.8 [r0], 0
    ifnz jmp custom_copy_string_loop

    pop r2
    pop r1
    pop r0
    ret

shell_type_command_file: data.fill 0, 12
shell_type_command_file_empty: data.str "           "
shell_type_command_file_struct: data.32 0 data.32 0
shell_type_command_file_character_buffer: data.8 0
shell_type_command_file_not_found_string: data.strz "file not found: "
