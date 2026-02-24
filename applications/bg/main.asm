; background image utility

const FRAMEBUFFER: 0x02000000

    opton
start:
    push r0
    push r1
    ; QOI Library
    call get_boot_disk_id
    mov r1, r0
    mov r0, _qoi_lbr_path
    call open_library
    cmp r0, 0
    ifz mov r0, _qoi_lbr_fail
    ifz call panic
    mov [_qoi_lbr], r0
    pop r1
    pop r0
    push r0
    push r1
    ; BMP Library
    call get_boot_disk_id
    mov r1, r0
    mov r0, _bmp_lbr_path
    call open_library
    cmp r0, 0
    ifz mov r0, _bmp_lbr_fail
    ifz call panic
    mov [_bmp_lbr], r0
    pop r1
    pop r0
    mov r19, start
    pop r20
    pop r2
    cmp r2, 0
    ifz jmp usage_error
    call get_boot_disk_id
    mov r1, r0
    mov r31, 3
arg_loop:
    pop r1
    cmp r1, 0
    ifnz jmp usage_error
    loop arg_loop

    ; open the specified file and read the header
    call get_current_disk_id
    mov r1, r0
    mov r0, r2
    mov r2, bg_file
    call open
    cmp r0, 0
    ifz jmp file_not_found_error
    ; get the file size
    mov r0, r2
    call get_size
    push r0
    call allocate_memory
    ifz mov r1, parse_error_alloc
    ifz jmp parse_error
    mov [file_input], r0
    pop r0
    mov r1, bg_file
    mov r2, [file_input]
    call read
    ; Yield before parsing
    call save_state_and_yield_task
    ; Parse the file
    call parse_image
    ; exit
    mov r0, [file_input]
    cmp r0, 0
    ifnz call free_memory
    mov r0, [_qoi_lbr]
    call close_library
    call end_current_task

parse_image:
    ; Attempt QOI
    mov r0, [file_input]
    mov r1, FRAMEBUFFER
    mov r2, [_qoi_lbr]
    call [r2]
    cmp r0, 0
    ifnz ret
    ifz call should_error_out
    ; Attempt BMP
    mov r0, [file_input]
    mov r1, FRAMEBUFFER
    mov r2, [_bmp_lbr]
    call [r2]
    cmp r0, 0
    ifnz ret
    jmp interpret_error

should_error_out:
    cmp r1, 1
    ifnz jmp interpret_error
    ret

interpret_error:
    cmp r1, 1
    ifz mov r1, parse_error_bad_magic
    ifz jmp parse_error
    cmp r1, 2
    ifz mov r1, parse_error_alloc
    ifz jmp parse_error
    cmp r1, 3
    ifz mov r1, parse_error_bpp
    ifz jmp parse_error
    cmp r1, 4
    ifz mov r1, parse_error_neg
    ifz jmp parse_error
    cmp r1, 5
    ifz mov r1, parse_error_compress
    ifz jmp parse_error
    mov r1, parse_error_unknown
    jmp parse_error

usage_error:
    mov r0, usage_str
    call print
    jmp tail

file_not_found_error:
    mov r0, file_not_found_error_str
    call print
    jmp tail

parse_error:
    mov r0, parse_error_str
    call print
    mov r0, r1
    call print
    jmp tail

; print a null terminated string to the stream
; inputs:
; r0: pointer to string
print:
    push r0
    push r1
    push r0
    call strlen
    pop r2
    mov r1, r20
    call write
    pop r1
    pop r0
    ret

; find the length of a null terminated string
; inputs:
; r0: pointer to string
; outputs:
; r0: length of string
strlen:
    push r1
    mov r1, r0
strlen_loop:
    cmp.8 [r1], 0
    ifz jmp strlen_end
    inc r1
    jmp strlen_loop
strlen_end:
    sub r1, r0
    mov r0, r1
    pop r1
    ret

tail:
    mov r0, [file_input]
    cmp r0, 0
    ifnz call free_memory
    mov r0, [_qoi_lbr]
    cmp r0, 0
    ifnz call close_library
    mov r0, [_bmp_lbr]
    cmp r0, 0
    ifnz call close_library
    call end_current_task

bg_file: data.fill 42, 32
file_input: data.32 0

usage_str: data.str "usage: bg <image>" data.8 10 data.8 0
file_not_found_error_str: data.str "error: file not found" data.8 10 data.8 0
parse_error_str: data.str "image parse error: " data.8 0
parse_error_unknown: data.str "unknown internal error" data.8 10 data.8 0
parse_error_bad_magic: data.str "bad magic number" data.8 10 data.8 0
parse_error_alloc: data.str "memory allocation failure" data.8 10 data.8 0
parse_error_bpp: data.str "bpp unsupported (only 24-bit and 32-bit may be used)" data.8 10 data.8 0
parse_error_neg: data.str "negative heights are unsupported" data.8 10 data.8 0
parse_error_compress: data.str "compression method not supported" data.8 10 data.8 0
_qoi_lbr_path: data.str "/system/library/qoi.lbr" data.8 0
_qoi_lbr: data.32 0
_qoi_lbr_fail: data.str "/system/library/qoi.lbr is absent!" data.8 10 data.8 0
_bmp_lbr_path: data.str "/system/library/bmp.lbr" data.8 0
_bmp_lbr: data.32 0
_bmp_lbr_fail: data.str "/system/library/bmp.lbr is absent!" data.8 10 data.8 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
