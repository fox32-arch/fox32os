; clear command

shell_echo_command_string: data.strz "echo"

shell_echo_command:
    mov r0, [shell_args_ptr]
    call print_str_to_terminal
    mov r0, 10
    call print_character_to_terminal

    ret
