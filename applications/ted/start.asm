    opton

    pop [terminalStreamPtr]
    pop [arg0Ptr]
    pop [arg1Ptr]
    pop [arg2Ptr]
    pop [arg3Ptr]

    call Main
    call end_current_task

brk:
    brk
    ret

terminalStreamPtr: data.32 0
arg0Ptr: data.32 0
arg1Ptr: data.32 0
arg2Ptr: data.32 0
arg3Ptr: data.32 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
