; heap command

shell_heap_command_string: data.strz "heap"

shell_heap_command:
    call heap_usage
    push r0
    call print_decimal_to_terminal
    mov r0, shell_heap_command_bytes_string
    call print_str_to_terminal

    pop r0
    div r0, 1024
    call print_decimal_to_terminal
    mov r0, shell_heap_command_kib_string
    call print_str_to_terminal

    ret

shell_heap_command_bytes_string: data.str " bytes" data.8 10 data.8 0
shell_heap_command_kib_string: data.str " KiB" data.8 10 data.8 0
