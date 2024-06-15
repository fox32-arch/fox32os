; rdnext command

shell_rdnext_command_string: data.strz "rdnext"

shell_rdnext_command:
    cmp.8 [shell_redirect_next], 0
    ifnz ret

    call shell_parse_arguments
    push r0
    call get_current_disk_id
    mov r1, r0
    pop r0
    mov r2, shell_redirect_stream_struct
    mov r3, 0
    call create
    cmp r0, 0
    ifz jmp shell_rdnext_command_failed_to_open

    mov.8 [shell_redirect_next], 2
    mov [shell_old_stream_struct_ptr], [shell_stream_struct_ptr]

    ret

shell_rdnext_command_failed_to_open:
    mov r0, shell_rdnext_command_failed_to_open_string
    call print_str_to_terminal
    ret

shell_rdnext_command_failed_to_open_string: data.str "failed to open file/stream for redirect" data.8 10 data.8 0
