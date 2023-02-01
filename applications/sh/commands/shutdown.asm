; shutdown command

shell_shutdown_command_string: data.strz "shutdown"

shell_shutdown_command:
    call poweroff
    ret
