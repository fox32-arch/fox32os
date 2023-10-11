; task switching routines

; add a new task to the queue and jump to it immediately
; inputs:
; r0: task ID
; r1: initial instruction pointer
; r2: initial stack pointer (remember that the stack grows down!)
; r3: pointer to code block to free when task ends, or zero for none
; r4: pointer to stack block to free when task ends, or zero for none
; outputs:
; none
new_task:
    ; mark this task ID as used
    bse [task_id_bitmap], r0

    mov r6, r4 ; stack block pointer
    mov r5, r3 ; code block pointer
    mov r4, r2 ; stack pointer
    mov r3, r1 ; instruction pointer
    mov r2, r0 ; task ID

    ; add to the queue
    mov r0, [task_queue_ptr]
    call task_store
    mov [task_queue_ptr], r0

    jmp save_state_and_yield_task

; switch to the next task in the queue
; no registers are saved upon task yield
; if a register must be saved across a yield, push it before the yield and pop it after the yield
; inputs:
; none
; outputs:
; none
yield_task:
    ; add the current task back into the queue
    mov r0, current_task ; get the current task struct
    call task_load
    pop r3 ; pop the return address off of the stack
    mov r4, rsp
    mov r0, [task_queue_ptr]
    call task_store
    mov [task_queue_ptr], r0

    jmp yield_task_0

; push all registers and switch to the next task in the queue
; inputs:
; none
; outputs:
; none
save_state_and_yield_task:
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

    call yield_task

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

; yield for at least the specified number of ms
; inputs:
; r0: minimum ms to yield for
; outputs:
; none
sleep_task:
    push r0
    push r1

    in r1, 0x80000706
    add r0, r1
sleep_task_loop:
    call save_state_and_yield_task
    in r1, 0x80000706
    cmp r1, r0
    iflt jmp sleep_task_loop

    pop r1
    pop r0
    ret

; switch to the next task without adding the current task back into the queue
; this will automatically free the task's code and stack blocks
; inputs:
; none
; outputs:
; none
end_current_task:
    mov r0, current_task ; get the current task struct
    call task_load
    bcl [task_id_bitmap], r2 ; mark this task ID as unused
    mov r0, r5 ; code block pointer
    cmp r0, 0
    ifnz call free_memory
    mov r0, r6 ; stack block pointer
    cmp r0, 0
    ifnz call free_memory
end_current_task_no_mark_no_free:
    pop r0 ; pop the return address off of the stack

    cmp [task_queue_ptr], task_queue_bottom
    ifz jmp task_empty
yield_task_0:
    mov r0, task_queue_bottom
    call task_load
    mov r0, current_task
    call task_store

    mov r1, task_queue_bottom
yield_task_1:
    add r1, TASK_SIZE

    cmp [task_queue_ptr], r1
    ifz jmp yield_task_2

    mov r0, r1
    call task_load

    mov r0, r1
    sub r0, TASK_SIZE
    call task_store

    jmp yield_task_1
yield_task_2:
    mov r0, current_task
    call task_load
    sub [task_queue_ptr], TASK_SIZE

    mov rsp, r4
    jmp r3

; get the next unused task ID, starting at 1
; inputs:
; none
; outputs:
; r0: task ID, or zero if all IDs are used
get_unused_task_id:
    mov r0, 1
get_unused_task_id_loop:
    bts [task_id_bitmap], r0
    ifz ret
    inc r0
    cmp r0, 32
    iflt jmp get_unused_task_id_loop
    ; if we reach this point, then all task IDs are used
    mov r0, 0
    ret

; get the task ID of the currently running task
; inputs:
; none
; outputs:
; r0: task ID
get_current_task_id:
    push r2
    push r3
    push r4
    push r5
    push r6

    mov r0, current_task
    call task_load
    mov r0, r2

    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    ret

; check if a task ID is used
; inputs:
; r0: task ID
; outputs:
; Z flag: set if unused, reset if used
is_task_id_used:
    bts [task_id_bitmap], r0
    ret

task_load:
    mov r2, [r0] ; task ID
    add r0, 4
    mov r3, [r0] ; instruction pointer
    add r0, 4
    mov r4, [r0] ; stack pointer
    add r0, 4
    mov r5, [r0] ; code block pointer
    add r0, 4
    mov r6, [r0] ; stack block pointer
    add r0, 4
    ret

task_store:
    mov [r0], r2 ; task ID
    add r0, 4
    mov [r0], r3 ; instruction pointer
    add r0, 4
    mov [r0], r4 ; stack pointer
    add r0, 4
    mov [r0], r5 ; code block pointer
    add r0, 4
    mov [r0], r6 ; stack block pointer
    add r0, 4
    ret

task_empty:
    mov r0, task_panic_str
    mov r1, task_queue_bottom ; show the address of the task queue in the panic brk output
    mov r2, [task_queue_ptr] ; show the the task queue pointer in the panic brk output
    call panic

task_panic_str: data.str "Scheduler starved, task queue empty!" data.8 10 data.8 0

const TASK_SIZE: 20
task_id_bitmap: data.32 0
current_task:
    data.32 0 ; task ID
    data.32 0 ; instruction pointer
    data.32 0 ; stack pointer
    data.32 0 ; code block pointer
    data.32 0 ; stack block pointer
task_queue_ptr: data.32 task_queue_bottom
task_queue_bottom: data.fill 0, 640 ; 32 tasks * 5 entries per task * 4 bytes per word = 640
