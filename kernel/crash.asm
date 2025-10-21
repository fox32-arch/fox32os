; task crash handler

task_crash_handler:
    icl
    inc rsp, 4 ; discard exception operand
    mov [task_crash_handler_return_address], [rsp+1]
    mov [task_crash_handler_old_rsp], rsp
    mov rsp, task_crash_handler_stack

    ; save all regs
    push rfp
    push resp
    push r31
    push r30
    push r29
    push r28
    push r27
    push r26
    push r25
    push r24
    push r23
    push r22
    push r21
    push r20
    push r19
    push r18
    push r17
    push r16
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push r7
    push r6
    push r5
    push r4
    push r3
    push r2
    push r1
    push r0

    mov r0, BACKGROUND_COLOR
    mov r1, 30
    call fill_overlay

    mov r0, current_task
    mov [crashed_task_name_low], [r0+24]
    mov [crashed_task_name_high], [r0+28]

    mov r0, crashed_task_name
    mov r1, 8
    mov r2, 0
    mov r3, TEXT_COLOR
    mov r4, BACKGROUND_COLOR
    mov r5, 30
    call draw_str_to_overlay
    mov r0, crash_str
    mov r10, [current_task]
    mov r11, [task_crash_handler_return_address]
    call draw_format_str_to_overlay

task_crash_handler_loop:
    ; pop a key from the keyboard queue
    in r0, 0x80000500
    cmp r0, 0
    ifz rjmp task_crash_handler_loop

    cmp r0, 0x12 ; E
    ifz rjmp task_crash_handler_end_task
    cmp r0, 0x13 ; R
    ifz rjmp task_crash_handler_recover
    cmp r0, 0x32 ; M
    ifz rjmp task_crash_handler_monitor

    rjmp task_crash_handler_loop

task_crash_handler_end_task:
    mov r0, 0xFF3F3F3F
    mov r1, 30
    call fill_overlay
    mov rsp, [task_crash_handler_old_rsp]
    mov [rsp+1], end_current_task
    reti

task_crash_handler_recover:
    mov r0, 0xFF3F3F3F
    mov r1, 30
    call fill_overlay
    mov rsp, [task_crash_handler_old_rsp]
    mov [rsp+1], task_crash_handler_recover_2
    reti
task_crash_handler_recover_2:
    ; once we're here, the flags have been restored
    mov r0, current_task
    mov rsp, [r0+8] ; stack pointer at last yield
    mov r0, [r0+4] ; instruction pointer at last yield
    jmp r0

task_crash_handler_monitor:
    pop r0
    pop r1
    pop r2
    pop r3
    pop r4
    pop r5
    pop r6
    pop r7
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15
    pop r16
    pop r17
    pop r18
    pop r19
    pop r20
    pop r21
    pop r22
    pop r23
    pop r24
    pop r25
    pop r26
    pop r27
    pop r28
    pop r29
    pop r30
    pop r31
    pop resp
    pop rfp

    mov rsp, [task_crash_handler_old_rsp]
    brk
    reti

crash_str: data.strz " (task %u) crashed at 0x%x // E = end, R = recover, M = monitor"
crashed_task_name: data.8 '"'
crashed_task_name_low: data.fill 0, 4
crashed_task_name_high: data.fill 0, 4 data.8 '"' data.8 0
task_crash_handler_return_address: data.32 0
task_crash_handler_old_rsp: data.32 0
    data.fill 0, 512
task_crash_handler_stack:
