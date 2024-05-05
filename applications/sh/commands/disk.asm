; disk command

shell_disk_command_string: data.strz "disk"

shell_disk_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    ; r0: disk ID

    ; check if it's in range
    cmp r0, 5
    ifgt jmp shell_disk_command_out_of_range

    cmp r0, 4
    ifz jmp shell_disk_command_is_romdisk

    cmp r0, 5
    ifz jmp shell_disk_command_is_ramdisk
shell_disk_command_is_disk:
    ; OR it with the IO port to get the current insert state of a disk
    or r0, 0x80001000
    in r1, r0
    cmp r1, 0
    ifz ret
    call set_current_disk_id
    ret
shell_disk_command_is_romdisk:
    call is_romdisk_available
    ifz call set_current_disk_id
    ret
shell_disk_command_is_ramdisk:
    call is_ramdisk_formatted
    ifz call set_current_disk_id
    ret

shell_disk_command_out_of_range:
    mov r0, shell_disk_command_out_of_range_string
    call print_str_to_terminal

    ret

shell_disk_command_out_of_range_string: data.str "invalid disk ID" data.8 10 data.8 0
