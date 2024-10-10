; background image utility

; global registers
; r30: pointer into `buffer`
; r29: file offset of topmost bitmap line
; r27, r28: width, height of image
; r26: line stride of file (width * bytes_per_pixel rounded up to align to 4 bytes)
; r25: pointer into background framebuffer
; r24: bytes per pixel
; r23: min(width, 640)
; r20: stream pointer (for terminal io)

; BMP features not yet supported
; - Negative height (implies image data is flipped vertically)
; - Bits per pixel besides 24
; - Compression
; - Any sort of YUV?

const BMP_HEADER_SIZE: 34
const BUFFER_SIZE: 1920 ; 640 pixels * 3 bytes per pixel
const FRAMEBUFFER: 0x02000000

    opton
start: mov r19, start
    pop r20
    pop r2
    cmp r2, 0
    ifz jmp usage_error
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
    ; read the header of the file to our buffer
    mov r0, BMP_HEADER_SIZE
    mov r1, bg_file
    mov r2, buffer
    call read
    mov r30, buffer

    ; parse the header and info header
    ; magic number "BM"
    mov r1, parse_error_bad_header_str
    mov r0, 0x4d42
    call bmp_assert_16
    ; file size in bytes (we choose to ignore it instead of verifying it)
    add r30, 4
    ; reserved: must be 0
    mov r0, 0
    call bmp_assert_32
    ; bitmap data offset, info header size (ignored for now since we don't support color tables), image width, image height
    mov r29, [r30]
    mov r27, [r30 + 8]
    cmp r27, 640
    ifgt mov r23, 640
    iflteq mov r23, r27
    mov r28, [r30 + 12]
    add r30, 16
    ; number of planes
    mov r1, parse_error_bad_info_header_str
    mov r0, 1
    call bmp_assert_16
    ; bits per pixel (we currently only support 24 and 32 bit RGB)
    movz.16 r0, [r30]
    cmp r0, 24
    ifz mov r24, 3
    ifz jmp bpp_end
    cmp r0, 32
    ifz mov r24, 4
    ifz jmp bpp_end
    mov r1, unsupported_bpp_str
    jmp parse_error
bpp_end:
    add r30, 2
    ; TODO: properly handle compression type
    mov r1, unsupported_compression_str
    mov r0, 0
    ; call bmp_assert_32
    add r30, 4

    ; draw 24 or 32 bpp image
    ; calculate line stride
    mov r26, r27
    mul r26, r24
    mov r0, r26
    and r0, 3
    cmp r0, 0 ; TODO: align to 4 bytes
    ifnz jmp parse_error
    ; find top-most bitmap line
    mov r0, r26
    mov r1, r28
    dec r1
    mul r0, r1
    add r29, r0
    ; cap to framebuffer height
    cmp r28, 480
    ifgt mov r28, 480
    mov r25, FRAMEBUFFER
    mov r11, 480
draw_background_line:
    mov r10, r29
    mov r12, r28
draw_bitmap_line:
    call save_state_and_yield_task
    mov r0, r10
    mov r1, bg_file
    call seek
    ; find number of pixels to draw
    mov r0, r23
    mul r0, r24
    mov r2, buffer
    call read
    mov r0, 640
draw_background_line_loop:
    mov r30, buffer
    cmp r0, r23
    ifgt mov r31, r23
    iflteq mov r31, r0
draw_bitmap_line_loop:
    mov.8 [r25], [r30 + 2]
    mov.8 [r25 + 1], [r30 + 1]
    mov.8 [r25 + 2], [r30]
    add r30, r24
    add r25, 4
    loop draw_bitmap_line_loop

    sub r0, r23
    ifgt jmp draw_background_line_loop

    dec r11
    ifz call end_current_task
    dec r12
    ifnz sub r10, r26
    ifnz jmp draw_bitmap_line
    jmp draw_background_line

usage_error:
    mov r0, usage_str
    call print 
    call end_current_task

file_not_found_error:
    mov r0, file_not_found_error_str
    call print
    call end_current_task

parse_error:
    mov r0, parse_error_str
    call print
    mov r0, r1
    call print
    call end_current_task

; inputs:
; r0: expected value (lower 2 bytes)
; r1: error string
bmp_assert_16:
    cmp.16 r0, [r30]
    ifnz jmp parse_error
    add r30, 2
    ret
    
; inputs:
; r0: expected value
; r1: error string
bmp_assert_32:
    cmp r0, [r30]
    ifnz brk
    ifnz jmp parse_error
    add r30, 4
    ret

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

bg_file: data.fill 42, 32
buffer: data.fill 65, BUFFER_SIZE

usage_str: data.str "usage: bg <image>" data.8 10 data.8 0
file_not_found_error_str: data.str "error: file not found" data.8 10 data.8 0
parse_error_str: data.str "image parse error: " data.8 0
parse_error_bad_header_str: data.str "bad header" data.8 10 data.8 0
parse_error_bad_info_header_str: data.str "bad info header" data.8 10 data.8 0
unsupported_bpp_str: data.str "only support 24bpp and 32bpp" data.8 10 data.8 0
unsupported_compression_str: data.str "compression not supported" data.8 10 data.8 0

    #include "../../../fox32rom/fox32rom.def"
    #include "../../fox32os.def"
