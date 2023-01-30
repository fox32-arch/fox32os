; shutdown command

shell_shutdown_command_string: data.str "shutdown" data.8 0

shell_shutdown_command:
    call poweroff
    ret
