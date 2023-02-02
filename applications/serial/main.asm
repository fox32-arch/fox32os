; serial terminal - spawn sh.fxf on the serial port

    ; start an instance of sh.fxf
    call get_unused_task_id
    mov.8 [shell_task_id], r0
    mov r1, stream_struct
    call new_shell_task

event_loop:
    movz.8 r0, [shell_task_id]
    call is_task_id_used
    ifz call end_current_task
    call yield_task
    rjmp event_loop

print_str_to_terminal:
    push r0
    push r1
print_str_to_terminal_loop:
    mov r1, [r0]
    cmp r1, 0
    ifz jmp print_str_to_terminal_out
    out 0, r1
    inc r0
    jmp print_str_to_terminal_loop
print_str_to_terminal_out:
    pop r1
    pop r0

stream_struct:
    data.8  0x00
    data.16 0x00
    data.32 0x00
    data.8  0x01
    data.32 stream_read
    data.32 stream_write

shell_task_id: data.8 0

stream_read:
    in r0, 0
    ret

stream_write:
    push r0
    movz.8 r0, [r0]
    bts r0, 7
    ifnz jmp stream_write_special
    out 0, r0
    pop r0
    ret
stream_write_special:
    cmp r0, 0x8a
    ifz out 0, ' '
    pop r0
    ret


#include "../terminal/task.asm"
#include "../../../fox32rom/fox32rom.def"
#include "../../fox32os.def"
