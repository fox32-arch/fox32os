; disk command

shell_disk_command_string: data.strz "disk"

shell_disk_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    ; r0: disk ID

    ; check if it's in range
    cmp r0, 3
    ifgt jmp shell_disk_command_out_of_range

    ; OR it with the IO port to get the current insert state of a disk
    or r0, 0x80001000
    in r1, r0
    cmp r1, 0
    ifz ret

    ; set the current disk ID
    mov.8 [shell_current_disk], r0

    ret

shell_disk_command_out_of_range:
    mov r0, shell_disk_command_out_of_range_string
    call print_str_to_terminal

    ret

shell_disk_command_out_of_range_string: data.str "invalid disk ID" data.8 10 data.8 0
