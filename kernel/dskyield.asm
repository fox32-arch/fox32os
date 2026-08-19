disk_yield_callback:
    push r0
disk_yield_callback_loop:
    call get_disk_op_completed
    cmp.8 r0, 0
    ifnz mov.8 r0, 0
    ifnz call set_disk_op_completed
    ifnz rjmp disk_yield_callback_end
    call get_disk_op_in_progress
    cmp.8 r0, 0
    ifz rjmp disk_yield_callback_end ; no operation in progress, bail out

    call save_state_and_yield_task
    rjmp disk_yield_callback_loop
disk_yield_callback_end:
    pop r0
    ret
