; rdall command

shell_rdall_command_string: data.strz "rdall"

shell_rdall_command:
    call shell_parse_arguments
    push r0
    call get_current_disk_id
    mov r1, r0
    pop r0
    mov r2, shell_redirect_stream_struct
    call open
    cmp r0, 0
    ifz jmp shell_rdall_command_failed_to_open

    mov.8 [shell_redirect_next], 0
    mov [shell_stream_struct_ptr], shell_redirect_stream_struct

    ret

shell_rdall_command_failed_to_open:
    mov r0, shell_rdnext_command_failed_to_open_string
    call print_str_to_terminal
    ret

shell_rdall_command_failed_to_open_string: data.str "failed to open file/stream for redirect" data.8 10 data.8 0
