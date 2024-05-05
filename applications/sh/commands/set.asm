; set commands

shell_setfrom_command_string: data.strz "setfrom"
shell_setreg_command_string: data.strz "setreg"
shell_getreg_command_string: data.strz "getreg"

shell_setfrom_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int

    mov r1, shell_batch_regs
    mul r0, 4
    add r0, r1
    mov [r0], [shell_command_return_value]

    ret

shell_setreg_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_setreg_command_reg], r0
    pop r0
    mov r1, 16
    call string_to_int
    mov [shell_setreg_command_value], r0

    movz.8 r0, [shell_setreg_command_reg]
    mul r0, 4
    add r0, shell_batch_regs
    mov [r0], [shell_setreg_command_value]

    ret

shell_getreg_command:
    call shell_parse_arguments
    mov r1, 10
    call string_to_int
    mul r0, 4
    add r0, shell_batch_regs
    mov [shell_command_return_value], [r0]

    ret

shell_setreg_command_reg: data.8 0
shell_setreg_command_value: data.32 0
