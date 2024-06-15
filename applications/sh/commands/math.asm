; math commands

shell_addreg_command_string: data.strz "addreg"
shell_addimm_command_string: data.strz "addimm"
shell_subreg_command_string: data.strz "subreg"
shell_subimm_command_string: data.strz "subimm"

shell_addreg_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg1], r0
    pop r0
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg2], r0

    ; get
    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r1, [r0]
    movz.8 r0, [shell_cmpreg_command_reg2]
    mul r0, 4
    add r0, shell_batch_regs
    mov r2, [r0]

    ; add
    add r1, r2
    ifz mov [shell_command_return_value], 0
    ifnz mov [shell_command_return_value], 1

    ; write back
    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r0, [r0]
    mov [r0], r1

    ret

shell_addimm_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg1], r0
    pop r0
    mov r1, 16
    call string_to_int
    mov [shell_cmpreg_command_imm], r0

    ; get
    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r1, [r0]
    mov r2, [shell_cmpreg_command_imm]

    ; add
    add r1, r2
    ifz mov [shell_command_return_value], 0
    ifnz mov [shell_command_return_value], 1

    ; write back
    mov [r0], r1

    ret

shell_subreg_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg1], r0
    pop r0
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg2], r0

    ; get
    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r1, [r0]
    movz.8 r0, [shell_cmpreg_command_reg2]
    mul r0, 4
    add r0, shell_batch_regs
    mov r2, [r0]

    ; sub
    sub r1, r2
    ifz mov [shell_command_return_value], 0
    ifnz mov [shell_command_return_value], 1

    ; write back
    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r0, [r0]
    mov [r0], r1

    ret

shell_subimm_command:
    call shell_parse_arguments
    push r1
    mov r1, 10
    call string_to_int
    mov.8 [shell_cmpreg_command_reg1], r0
    pop r0
    mov r1, 16
    call string_to_int
    mov [shell_cmpreg_command_imm], r0

    ; get
    movz.8 r0, [shell_cmpreg_command_reg1]
    mul r0, 4
    add r0, shell_batch_regs
    mov r1, [r0]
    mov r2, [shell_cmpreg_command_imm]

    ; sub
    sub r1, r2
    ifz mov [shell_command_return_value], 0
    ifnz mov [shell_command_return_value], 1

    ; write back
    mov [r0], r1

    ret
