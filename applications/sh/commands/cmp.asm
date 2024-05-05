; cmp command

shell_cmpreg_command_string: data.strz "cmpreg"
shell_cmpimm_command_string: data.strz "cmpimm"

shell_cmpreg_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg1], r0
    pop r0
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg2], r0

    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r1, [r0]
    movz.8 r0, [shell_cmpreg_command_reg2]
    mul r0, 4
    add r0, shell_batch_regs
    mov r2, [r0]

    cmp r1, r2
    ifz mov [shell_command_return_value], 0
    ifnz mov [shell_command_return_value], 1

    ret

shell_cmpimm_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg1], r0
    pop r0
    mov r1, 16
    call string_to_int
    mov [shell_cmpreg_command_imm], r0

    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r1, [r0]
    mov r2, [shell_cmpreg_command_imm]

    cmp r1, r2
    ifz mov [shell_command_return_value], 0
    ifnz mov [shell_command_return_value], 1

    ret

shell_cmpreg_command_reg1: data.8 0
shell_cmpreg_command_reg2: data.8 0
shell_cmpreg_command_imm: data.32 0
