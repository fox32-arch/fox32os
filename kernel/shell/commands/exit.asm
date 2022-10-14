; exit command

shell_exit_command_string: data.str "exit" data.8 0

shell_exit_command:
    call end_current_task
