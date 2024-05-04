; command parser

shell_parse_command:
    cmp.8 [shell_redirect_next], 0
    ifnz mov [shell_stream_struct_ptr], shell_redirect_stream_struct

    mov r0, shell_text_buf_bottom

    ; clear
    mov r1, shell_clear_command_string
    call compare_string
    ifz jmp shell_clear_command

    ; del
    mov r1, shell_del_command_string
    call compare_string
    ifz jmp shell_del_command

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

    ; echo
    mov r1, shell_echo_command_string
    call compare_string
    ifz jmp shell_echo_command

    ; exit
    mov r1, shell_exit_command_string
    call compare_string
    ifz jmp shell_exit_command

    ; help
    mov r1, shell_help_command_string
    call compare_string
    ifz jmp shell_help_command

    ; rdall
    mov r1, shell_rdall_command_string
    call compare_string
    ifz jmp shell_rdall_command

    ; rdnext
    mov r1, shell_rdnext_command_string
    call compare_string
    ifz jmp shell_rdnext_command

    ; shutdown
    mov r1, shell_shutdown_command_string
    call compare_string
    ifz jmp shell_shutdown_command

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
    #include "commands/clear.asm"
    #include "commands/del.asm"
    #include "commands/dir.asm"
    #include "commands/disk.asm"
    #include "commands/diskrm.asm"
    #include "commands/echo.asm"
    #include "commands/exit.asm"
    #include "commands/help.asm"
    #include "commands/rdall.asm"
    #include "commands/rdnext.asm"
    #include "commands/shutdown.asm"
    #include "commands/type.asm"
