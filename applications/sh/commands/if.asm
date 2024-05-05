; if commands

shell_ifz_command_string: data.strz "ifz"
shell_ifnz_command_string: data.strz "ifnz"

shell_ifz_command:
    cmp [shell_command_return_value], 0
    ifnz ret
    jmp shell_if_common

shell_ifnz_command:
    cmp [shell_command_return_value], 0
    ifz ret
    ; fall-through

shell_if_common:
    mov r0, [shell_args_ptr]
    mov r1, shell_text_buf_bottom
    call copy_string
    call shell_parse_line

    ret
