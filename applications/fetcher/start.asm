    pop [terminalStreamPtr]
    pop [arg0Ptr]
    pop [arg1Ptr]
    pop [arg2Ptr]
    pop [arg3Ptr]

    call Main
    call end_current_task

GetNextWindowEvent:
    push r8
    call get_next_window_event
    mov r8, eventArgs
    mov [r8], r0
    add r8, 4
    mov [r8], r1
    add r8, 4
    mov [r8], r2
    add r8, 4
    mov [r8], r3
    add r8, 4
    mov [r8], r4
    add r8, 4
    mov [r8], r5
    add r8, 4
    mov [r8], r6
    add r8, 4
    mov [r8], r7
    pop r8
    ret

brk:
    brk
    ret

PortIn:
    in r0, r0
    ret

eventArgs: data.fill 0, 32
terminalStreamPtr: data.32 0
arg0Ptr: data.32 0
arg1Ptr: data.32 0
arg2Ptr: data.32 0
arg3Ptr: data.32 0

diskIcon:
    #include "icons/disk.inc"

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
