; eject command

shell_diskrm_command_string: data.strz "diskrm"

shell_diskrm_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    ; r0: disk ID

    ; check if it's in range
    cmp r0, 3
    ifgt jmp shell_diskrm_command_out_of_range

    ; OR it with the IO port to remove a disk
    or r0, 0x80005000

    ; remove disk
    out r0, 0

    ret

shell_diskrm_command_out_of_range:
    mov r0, shell_diskrm_command_out_of_range_string
    call print_str_to_terminal

    ret

shell_diskrm_command_out_of_range_string: data.str "invalid disk ID" data.8 10 data.8 0
