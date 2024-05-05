; copy command

shell_copy_command_string: data.strz "copy"

shell_copy_command:
    call shell_parse_arguments

    cmp r0, 0
    ifz ret
    cmp r1, 0
    ifz ret

    mov r4, r1

    call copy_get_disk_id
    mov r2, shell_type_command_file_struct
    call open
    cmp r0, 0
    ifz jmp shell_copy_command_file_not_found

    mov r0, shell_type_command_file_struct
    call get_size
    mov r3, r0
    mov r0, r4
    call copy_get_disk_id
    mov r2, shell_copy_command_file_struct
    call create

    mov r0, shell_type_command_file_struct
    call get_size

    mov r0, shell_type_command_file_struct
    mov r1, shell_copy_command_file_struct
    call copy

    ret

copy_get_disk_id:
    cmp.8 [r0+1], ':'
    ifnz jmp copy_get_disk_id_1
    movz.8 r1, [r0]
    sub r1, '0'
    inc r0, 2
    ret
copy_get_disk_id_1:
    push r0
    call get_current_disk_id
    mov r1, r0
    pop r0
    ret

shell_copy_command_file_not_found:
    mov r0, shell_copy_command_file_not_found_string
    call print_str_to_terminal

    ret

shell_copy_command_file_struct: data.fill 0, 32
shell_copy_command_file_not_found_string: data.strz "source file not found"
