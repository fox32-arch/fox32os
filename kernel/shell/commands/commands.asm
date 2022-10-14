; command parser

shell_parse_command:
    mov r0, shell_text_buf_bottom

    ; dir
    mov r1, shell_dir_command_string
    call compare_string
    ifz jmp shell_dir_command

    ; disk
    mov r1, shell_disk_command_string
    call compare_string
    ifz jmp shell_disk_command

    ; diskrm
    mov r1, shell_diskrm_command_string
    call compare_string
    ifz jmp shell_diskrm_command

    ; exit
    mov r1, shell_exit_command_string
    call compare_string
    ifz jmp shell_exit_command

    ; help
    mov r1, shell_help_command_string
    call compare_string
    ifz jmp shell_help_command

    ; type
    mov r1, shell_type_command_string
    call compare_string
    ifz jmp shell_type_command

    ; attempt to run a FXF binary
    call launch_fxf

    ; invalid command
    mov r0, shell_invalid_command_string
    call print_str_to_terminal

    ret

shell_invalid_command_string: data.str "invalid command or FXF binary" data.8 10 data.8 0

    ; all commands
    #include "shell/commands/dir.asm"
    #include "shell/commands/disk.asm"
    #include "shell/commands/diskrm.asm"
    #include "shell/commands/exit.asm"
    #include "shell/commands/help.asm"
    #include "shell/commands/type.asm"
