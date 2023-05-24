; PROCEDURE YieldProcess();
YieldProcess:
    ; switch context to processes[0], which is the scheduler's context
    mov r0, processes

    ; fall-through

; PROCEDURE SwitchProcess(
;    newProcess: POINTER TO Process;
; );
SwitchProcess:
    push rfp
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

    ; get the current process
    mov r1, [currentProcess]
    mov r1, [r1]

    ; point to currentProcess.instructionPtr and store return address
    add r1, 4
    mov [r1], SwitchProcess_ret

    ; point to currentProcess.stackPtr and store rsp
    add r1, 4
    mov [r1], rsp

    ; get the target instruction pointer
    add r0, 4
    mov r1, [r0]

    ; get the target stack pointer
    add r0, 4
    mov rsp, [r0]

    ; jump to the target
    ; in most cases, this will just jump to SwitchProcess_ret
    ; however, if the target process's instruction pointer was set elsewhere,
    ; then it will jump there instead
    ; FIXME: in that case, 132 bytes of the old process's stack will be wasted
    ;        due to the regs pushed above not being popped
    jmp r1

SwitchProcess_ret:
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
    pop rfp
    ret
