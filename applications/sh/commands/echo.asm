; echo command

shell_echo_command_string: data.strz "echo"
shell_echov_command_string: data.strz "echov"
shell_echord_command_string: data.strz "echord"
shell_echorh_command_string: data.strz "echorh"
shell_echors_command_string: data.strz "echors"

shell_echo_command:
    call shell_parse_arguments

    cmp r0, 0
    ifnz call print_str_to_terminal
    mov r0, r1
    cmp r0, 0
    ifnz call print_str_to_terminal
    mov r0, r2
    cmp r0, 0
    ifnz call print_str_to_terminal
    mov r0, r3
    cmp r0, 0
    ifnz call print_str_to_terminal

    mov r0, 10
    call print_character_to_terminal

    ret

shell_echov_command:
    call shell_parse_arguments

    cmp r0, 0
    ifnz call print_str_to_terminal
    mov r0, r1
    cmp r0, 0
    ifnz call print_str_to_terminal
    mov r0, r2
    cmp r0, 0
    ifnz call print_str_to_terminal
    mov r0, r3
    cmp r0, 0
    ifnz call print_str_to_terminal

    ret

shell_echord_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    mul r0, 4
    add r0, shell_batch_regs
    mov r12, [r0]

    mov r10, rsp
    push.8 0x00 ; end the string with a terminator
shell_echord_command_decimal_loop:
    push r12
    div r12, 10
    pop r13
    rem r13, 10
    mov r11, r13
    add r11, '0'
    push.8 r11
    cmp r12, 0
    ifnz jmp shell_echord_command_decimal_loop
    mov r0, rsp ; point to start of string in the stack
    call print_str_to_terminal
    mov rsp, r10

    ret

shell_echorh_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    mul r0, 4
    add r0, shell_batch_regs

    mov r10, [r0]
    mov r31, 8
shell_echorh_command_loop:
    rol r10, 4
    movz.16 r11, r10
    and r11, 0x0F
    mov r12, hex_chars
    add r12, r11
    movz.8 r0, [r12]
    call print_character_to_terminal
    add r1, r6
    loop shell_echorh_command_loop

    ret

shell_echors_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    mul r0, 4
    add r0, shell_batch_regs
    mov r0, [r0]
    call print_str_to_terminal

    ret

hex_chars: data.str "0123456789ABCDEF"
