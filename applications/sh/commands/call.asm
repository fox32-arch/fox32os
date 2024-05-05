; call commands

shell_call_command_string: data.strz "call"
shell_callref_command_string: data.strz "callref"

shell_call_command:
    call shell_parse_arguments
    mov r1, 16
    call string_to_int
    mov [shell_call_address], r0

    mov r8, shell_batch_regs
    mov r0, [r8]
    mov r1, [r8+4]
    mov r2, [r8+8]
    mov r3, [r8+12]
    mov r4, [r8+16]
    mov r5, [r8+20]
    mov r6, [r8+24]
    mov r7, [r8+28]
    call [shell_call_address]
    mov r8, shell_batch_regs
    mov [r8], r0
    mov [r8+4], r1
    mov [r8+8], r2
    mov [r8+12], r3
    mov [r8+16], r4
    mov [r8+20], r5
    mov [r8+24], r6
    mov [r8+28], r7

    ret

shell_callref_command:
    call shell_parse_arguments
    mov r1, 16
    call string_to_int
    mov [shell_call_address], [r0]

    mov r8, shell_batch_regs
    mov r0, [r8]
    mov r1, [r8+4]
    mov r2, [r8+8]
    mov r3, [r8+12]
    mov r4, [r8+16]
    mov r5, [r8+20]
    mov r6, [r8+24]
    mov r7, [r8+28]
    call [shell_call_address]
    mov r8, shell_batch_regs
    mov [r8], r0
    mov [r8+4], r1
    mov [r8+8], r2
    mov [r8+12], r3
    mov [r8+16], r4
    mov [r8+20], r5
    mov [r8+24], r6
    mov [r8+28], r7

    ret

shell_call_address: data.32 0
