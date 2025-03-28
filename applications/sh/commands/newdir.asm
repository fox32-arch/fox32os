; newdir command

shell_newdir_command_string: data.strz "newdir"

shell_newdir_command:
    call shell_parse_arguments
    push r0
    call get_current_disk_id
    mov r1, r0
    pop r0
    mov r2, shell_dir_command_temp_file_struct
    call create_dir
    cmp r0, 0
    ifz jmp shell_newdir_command_fail
    ret

shell_newdir_command_fail:
    mov r0, shell_newdir_command_fail_str
    call print_str_to_terminal
    ret

shell_newdir_command_fail_str: data.str "failed to create directory" data.8 10 data.8 0
