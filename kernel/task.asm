; task switching routines

; add a new task to the queue and jump to it immediately
; inputs:
; r0: task ID
; r1: task instruction pointer
; r2: task stack pointer
; outputs:
; none
new_task:
    bse [task_id_bitmap], r0 ; mark this task ID as used

    mov r4, r2
    mov r3, r1
    mov r2, r0

    mov r0, [task_queue_ptr]
    call task_store
    mov [task_queue_ptr], r0

    ; fall-through

; switch to the next task in the queue
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

; switch to the next task without adding the current task back into the queue
; inputs:
; none
; outputs:
; none
end_current_task:
    cmp [task_queue_ptr], task_queue_bottom
    ifz jmp task_empty

    mov r0, current_task ; get the current task struct
    call task_load
    bcl [task_id_bitmap], r2 ; mark this task ID as unused
    pop r0 ; pop the return address off of the stack
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
    ; if we reach this point, then add task IDs are used
    mov r0, 0
    ret

task_load:
    mov r2, [r0] ; task ID
    add r0, 4
    mov r3, [r0] ; instruction pointer
    add r0, 4
    mov r4, [r0] ; stack pointer
    add r0, 4
    ret

task_store:
    mov [r0], r2 ; task ID
    add r0, 4
    mov [r0], r3 ; instruction pointer
    add r0, 4
    mov [r0], r4 ; stack pointer
    add r0, 4
    ret

task_empty:
    mov r0, task_panic_str
    mov r1, task_queue_bottom ; show the address of the task queue in the panic brk output
    mov r2, [task_queue_ptr] ; show the the task queue pointer in the panic brk output
    call panic

task_panic_str: data.str "Task queue empty! Hanging here" data.8 10 data.8 0

const TASK_SIZE: 12
task_id_bitmap: data.32 0
current_task:
    data.32 0 ; task ID
    data.32 0 ; instruction pointer
    data.32 0 ; stack pointer
task_queue_ptr: data.32 task_queue_bottom
task_queue_bottom:
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
    data.32 0 data.32 0 data.32 0
