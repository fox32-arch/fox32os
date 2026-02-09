; window event routines

; event types
const EVENT_TYPE_BUTTON_CLICK: 0x80000000

const WINDOW_EVENT_SIZE: 32

; get the next window event and remove it from the event queue
; inputs:
; r0: pointer to window struct
; outputs:
; r0: event type
; r1-r7: event parameters
get_next_window_event:
    push r10
    push r11

    ; r10: event_queue_ptr
    mov r10, r0
    add r10, 4

    ; r11: event_queue_bottom
    mov r11, r0
    add r11, 8

    cmp [r10], [r11]
    ifz pop r11
    ifz pop r10
    ifz jmp window_event_empty

get_next_window_event_0:
    push r8
    push r9

    mov r8, [r11]
    call window_event_load
    mov r8, window_event_temp
    call window_event_store

    mov r9, [r11]

get_next_window_event_1:
    add r9, WINDOW_EVENT_SIZE

    cmp [r10], r9
    ifz jmp get_next_window_event_2

    mov r8, r9
    call window_event_load

    mov r8, r9
    sub r8, WINDOW_EVENT_SIZE
    call window_event_store

    jmp get_next_window_event_1

get_next_window_event_2:
    mov r8, window_event_temp
    call window_event_load

    sub [r10], WINDOW_EVENT_SIZE

    pop r9
    pop r8
    pop r11
    pop r10
    ret

; add an event to a window's event queue
; inputs:
; r0: event type
; r1-r7: event parameters
; r8: pointer to window struct
; outputs:
; none
new_window_event:
    push r8
    push r9

    mov r9, r8
    add r9, 4 ; point to event_queue_ptr in the window struct
    mov r8, [r9]
    call window_event_store
    mov [r9], r8

    pop r9
    pop r8
    ret

window_event_load:
    mov r0, [r8]
    add r8, 4
    mov r1, [r8]
    add r8, 4
    mov r2, [r8]
    add r8, 4
    mov r3, [r8]
    add r8, 4
    mov r4, [r8]
    add r8, 4
    mov r5, [r8]
    add r8, 4
    mov r6, [r8]
    add r8, 4
    mov r7, [r8]
    add r8, 4
    ret

window_event_store:
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
    add r8, 4
    ret

window_event_empty:
    mov r0, EVENT_TYPE_EMPTY
    mov r1, 0
    mov r2, 0
    mov r3, 0
    mov r4, 0
    mov r5, 0
    mov r6, 0
    mov r7, 0
    ret

window_event_temp: data.fill 0, 32 ; 8 entries * 4 bytes per word
