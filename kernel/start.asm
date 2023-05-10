const SYSTEM_STACK: 0x01FFF800

    call EntryCheck
    ifz rjmp 0

    mov rsp, SYSTEM_STACK
    call Main

    ; Main() should never return, but just in case it does, hang
    rjmp 0

EntryCheck:
    ; TODO: implement this
    mov r0, 1
    ret
