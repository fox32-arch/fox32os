; chgdir command

shell_chgdir_command_string: data.strz "chgdir"

shell_chgdir_command:
    call shell_parse_arguments
    push r0
    call get_current_disk_id
    mov r1, r0
    pop r0
    mov r2, shell_dir_command_temp_file_struct
    call open
    cmp r0, 0
    ifz jmp shell_chgdir_command_fail
    call set_current_directory
    ret

shell_chgdir_command_fail:
    mov r0, shell_chgdir_command_fail_str
    call print_str_to_terminal
    ret

shell_chgdir_command_fail_str: data.str "failed to set directory" data.8 10 data.8 0
