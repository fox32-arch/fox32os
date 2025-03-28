; help command

shell_help_command_string: data.strz "help"

shell_help_command:
    mov r0, shell_help_text
    call print_str_to_terminal

    ret

shell_help_text:
    data.8 SET_COLOR data.8 0x20 data.8 1 ; set the color to green
    data.str "fox32os shell" data.8 10
    data.8 SET_COLOR data.8 0x70 data.8 1 ; set the color to white
    data.str "internal commands:" data.8 10
    data.str "chgdir   | enter directory $0" data.8 10
    data.str "clear    | clear the terminal contents" data.8 10
    data.str "copy     | copy file $0 to file $1" data.8 10
    data.str "del      | delete file $0" data.8 10
    data.str "dir      | list files in directory $0" data.8 10
    data.str "disk     | select disk $0" data.8 10
    data.str "diskrm   | remove disk $0" data.8 10
    data.str "echo     | print the specified text" data.8 10
    data.str "exit     | exit the shell" data.8 10
    data.str "help     | show this help text" data.8 10
    data.str "newdir   | create directory $0" data.8 10
    data.str "rdall    | redirect all IO to $0" data.8 10
    data.str "rdnext   | redirect next command's IO" data.8 10
    data.str "shutdown | turn the computer off" data.8 10
    data.str "type     | show contents of file $0" data.8 10
    data.str "task prefixes:" data.8 10
    data.str "* | return to shell on first yield" data.8 10
    data.str "% | invoke monitor on task launch" data.8 10
    data.8 0
