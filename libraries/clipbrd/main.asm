    opton

jump_table:
    data.32 pull
    data.32 invalidate
    data.32 copy_file
    data.32 0x00000000 ; end jump table

const ROM_copy_string:    0xF0046008
const OS_allocate_memory: 0x00000B10
const OS_free_memory:     0x00000B14

const CLIPBOARD_TYPE_EMPTY: 0
const CLIPBOARD_TYPE_FILE: 1

clipboard_data_ptr: data.32 0
clipboard_data_size: data.32 0
clipboard_data_type: data.32 0
clipboard_data_needs_free: data.8 0
clipboard_file_name: data.fill 0, 13

; pull the contents of the clipboard
; as this returns a pointer to our memory, the caller needs to ensure
; that they copy this data into their own memory before the next yield!
; inputs:
; r0: non-zero if the clipboard should automatically be invalidated after this
; outputs:
; r0: pointer to buffer containing clipboard data
; r1: size of buffer
; r2: type of data (see consts above)
; r3: pointer to file name, if applicable
pull:
    cmp r0, 0
    mov r0, [clipboard_data_ptr]
    mov r1, [clipboard_data_size]
    mov r2, [clipboard_data_type]
    mov r3, clipboard_file_name
    ifnz call invalidate
    ret

; invalidate the current contents of the clipboard, freeing memory as needed
; inputs:
; none
; outputs:
; none
invalidate:
    cmp.8 [clipboard_data_needs_free], 0
    ifz rjmp invalidate_no_free
    push r0
    mov r0, [clipboard_data_ptr]
    cmp r0, 0
    ifnz call [OS_free_memory]
    pop r0
invalidate_no_free:
    mov [clipboard_data_ptr], 0
    mov [clipboard_data_size], 0
    mov [clipboard_data_type], CLIPBOARD_TYPE_EMPTY
    mov.8 [clipboard_data_needs_free], 0
    ret

; copy a pointer to an open file to the clipboard
; inputs:
; r0: pointer to file struct
; r1: pointer to file name (null-terminated, max 12 chars)
; outputs:
; none
copy_file:
    call invalidate

    mov [clipboard_data_ptr], r0
    mov [clipboard_data_size], 0
    mov [clipboard_data_type], CLIPBOARD_TYPE_FILE
    mov.8 [clipboard_data_needs_free], 0
    mov r0, r1
    mov r1, clipboard_file_name
    call [ROM_copy_string]

    ret
