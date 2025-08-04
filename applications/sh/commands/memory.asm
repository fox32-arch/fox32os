; memory commands (peek, poke, etc.)

shell_peek_command_string: data.strz "peek"
shell_poke_command_string: data.strz "poke"

shell_peek_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    movz.8 [shell_command_return_value], [r0]

    ret

shell_poke_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov r2, r0

    pop r0
    mov r1, 10
    call string_to_int

    mov.8 [r2], r0

    ret
