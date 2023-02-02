; exit command

shell_exit_command_string: data.strz "exit"

shell_exit_command:
    call end_current_task
