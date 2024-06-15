; del command

shell_del_command_string: data.strz "del"

shell_del_command:
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
    call delete

    ret
