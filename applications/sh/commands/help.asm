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
    data.8 10
    data.str "(in descriptions, $n is argument n)" data.8 10
    data.str "command | description" data.8 10
    data.str "------- | -----------" data.8 10
    data.str "clear   | clear the terminal contents" data.8 10
    data.str "copy    | copy file $0 to file $1" data.8 10
    data.str "del     | delete file $0" data.8 10
    data.str "dir     | show contents of selected disk" data.8 10
    data.str "disk    | select disk $0" data.8 10
    data.str "diskrm  | remove disk $0" data.8 10
    data.str "echo    | print the specified text" data.8 10
    data.str "exit    | exit the shell" data.8 10
    data.str "help    | show this help text" data.8 10
    data.str "rdall   | redirect all IO to $0" data.8 10
    data.str "rdnext  | redirect the next command's IO" data.8 10
    data.str "shutdown| turn the computer off" data.8 10
    data.str "type    | print contents of file $0" data.8 10
    data.8 10
    data.str "type the name of an FXF binary to launch" data.8 10
    data.str "it as a new task; the shell will suspend" data.8 10
    data.str "until the launched task ends." data.8 10
    data.str "prefix the name of an FXF binary with *" data.8 10
    data.str "to launch it without suspending." data.8 10
    data.8 0
