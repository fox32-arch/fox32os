; virtual filesystem routines

const TEMP_SECTOR_BUF: 0x0000003C ; fox32rom buffer

; file struct for file:
;   file_disk:         1 byte
;   file_first_sector: 2 bytes
;   file_seek_offset:  4 bytes
;   file_system_type:  1 byte (0x00 for RYFS)
;   file_dir_sector:   2 bytes
;   file_reserved_1:   2 bytes
;   file_reserved_2:   4 bytes
;   file_reserved_3:   4 bytes
;   file_reserved_4:   4 bytes
;   file_reserved_5:   4 bytes
;   file_reserved_6:   4 bytes

; file struct for stream:
;   file_reserved_1:  1 byte
;   file_reserved_2:  2 bytes
;   file_seek_offset: 4 bytes
;   file_system_type: 1 byte (0x01 for stream)
;   file_read_call:   4 bytes
;   file_write_call:  4 bytes
;   file_size:        4 bytes
;   file_reserved_3:  4 bytes
;   file_reserved_4:  4 bytes
;   file_reserved_5:  4 bytes

; open a file from a RYFS-formatted disk, or a named stream
; inputs:
; r0: pointer to file or directory path string
;     i.e. 0:/stuff/test1.txt (will override specified disk) or
;          /stuff/test1.txt (will use specified disk) or
;          test2.txt (will use current directory and specified disk) or
;          /stuff (will return sector of directory) or
;          / (will return sector of root directory)
; r1: disk ID (ignored if stream, or if path specifies disk)
; r2: file struct: pointer to a blank 32 byte file struct
; outputs:
; r0: if file: first file sector, or zero if file wasn't found
;     if stream: non-zero if stream opened, or zero if not
open:
    cmp.8 [r0], ':'
    ifz jmp open_stream

    push r2
    mov r2, r1
    mov r1, 0
open_iterate_loop:
    call iterate_dir_path
    ; r0: pointer to null-terminated path string, incremented past the first directory
    ;     if zero, then r1 points to the sector of the file itself
    ; r1: directory sector containing file, or sector of file, or zero if failure
    ; r2: disk ID
    ; r3: zero if r0 or r1 points to the final file and not another directory; non-zero otherwise
    cmp r3, 0
    ifnz rjmp open_iterate_loop
    mov r3, r1 ; ryfs_open expects the directory sector in r3
    mov r1, r2 ; ryfs_open expects the disk ID in r1
    pop r2
    cmp r0, 0
    ifz rjmp open_root

    call convert_filename
    cmp r0, 0
    ifz ret
    jmp ryfs_open
open_stream:
    push r1

    inc r0

    ; disk0
    mov r1, disk0_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk0

    ; disk1
    mov r1, disk1_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk1

    ; disk2
    mov r1, disk2_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk2

    ; disk3
    mov r1, disk3_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_disk3

    ; fb
    mov r1, framebuffer_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_fb

    ; ofb0 - ofb31
    push r2
    mov r1, overlay_vfs_stream_name
    mov r2, 3
    call compare_memory_bytes
    pop r2
    ifz pop r1
    ifz jmp open_stream_ofb

    ; ramdisk
    mov r1, ramdisk_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_ramdisk

    ; romdisk
    mov r1, romdisk_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_romdisk

    ; serial
    mov r1, serial_vfs_stream_name
    call compare_string
    ifz pop r1
    ifz jmp open_stream_serial

    pop r1
    mov r0, 0
    ret
open_root:
    mov r0, r3 ; return the directory sector directly
    ; now, fill out the file struct like `ryfs_open` usually would
    mov.8 [r2], r1 ; file_disk
    mov.16 [r2+1], r0 ; file_first_sector
    mov [r2+3], 0 ; file_seek_offset
    mov [r2+7], 0 ; file_system_type (0x00 for RYFS)
    mov.16 [r2+8], 0 ; file_dir_sector FIXME: should this be zero if `file_first_sector` points to the root dir???
    ret

; create a file on a RYFS-formatted disk, or open a named stream
; if target file already exists, it will be deleted and then re-created as a blank file
; inputs:
; r0: pointer to file path string
;     i.e. 0:/stuff/test1.txt (will override specified disk) or
;          /stuff/test1.txt (will use specified disk) or
;          test2.txt (will use current directory and specified disk)
;     do not use this for directories directly
; r1: disk ID (ignored if stream, or if path specifies disk)
; r2: file struct: pointer to a blank 32 byte file struct
; r3: target file size
; outputs:
; r0: if file: first file sector, or zero if file couldn't be created
;     if stream: non-zero if stream opened, or zero if not
create:
    cmp.8 [r0], ':'
    ifz jmp open_stream

    push r2
    push r3
    mov r2, r1
    mov r1, 0
create_iterate_loop:
    call iterate_dir_path
    ; r0: pointer to null-terminated path string, incremented past the first directory
    ;     if zero, then r1 points to the sector of the file itself
    ; r1: directory sector containing file, or sector of file, or zero if failure
    ; r2: disk ID
    ; r3: zero if r0 or r1 points to the final file and not another directory; non-zero otherwise
    cmp r3, 0
    ifnz rjmp create_iterate_loop
    mov r4, r1 ; ryfs_create expects the directory sector in r4
    mov r1, r2 ; ryfs_create expects the disk ID in r1
    pop r3
    pop r2
    cmp r0, 0
    ifz ret

    call convert_filename
    cmp r0, 0
    ifz ret
    jmp ryfs_create

; create a directory on a RYFS-formatted disk, or open a named stream
; if target directory already exists, it will be opened as-is
; inputs:
; r0: pointer to directory path string
;     i.e. 0:/stuff/test1 (will override specified disk) or
;          /stuff/test1 (will use specified disk) or
;          test2 (will use current directory and specified disk)
; r1: disk ID (ignored if stream, or if path specifies disk)
; r2: file struct: pointer to a blank 32 byte file struct
; outputs:
; r0: if directory: directory sector, or zero if directory couldn't be created
;     if stream: non-zero if stream opened, or zero if not
create_dir:
    cmp.8 [r0], ':'
    ifz jmp open_stream

    push r2
    mov r2, r1
    mov r1, 0
create_dir_iterate_loop:
    call iterate_dir_path
    ; r0: pointer to null-terminated path string, incremented past the first directory
    ;     if zero, then r1 points to the sector of the file itself
    ; r1: directory sector containing file, or sector of file, or zero if failure
    ; r2: disk ID
    ; r3: zero if r0 or r1 points to the final file and not another directory; non-zero otherwise
    cmp r3, 0
    ifnz rjmp create_dir_iterate_loop
    mov r3, r1 ; ryfs_create_dir expects the directory sector in r3
    mov r1, r2 ; ryfs_create_dir expects the disk ID in r1
    pop r2
    cmp r0, 0
    ifz ret

    call convert_filename
    cmp r0, 0
    ifz ret
    jmp ryfs_create_dir

; delete a file on a RYFS-formatted disk
; inputs:
; r0: file struct: pointer to a filled file struct
; outputs:
; none
delete:
    cmp r0, 0
    ifz ret
    jmp ryfs_delete

; copy a file's contents
; inputs:
; r0: source file struct: pointer to a filled file struct
; r1: destination file struct: pointer to a filled file struct
; outputs:
; none
copy:
    mov [copy_source_struct_ptr], r0
    mov [copy_dest_struct_ptr], r1
    call get_size
    mov [copy_buffer_size], r0
    call allocate_memory
    mov [copy_buffer_ptr], r0

    mov r0, [copy_buffer_size]
    mov r1, [copy_source_struct_ptr]
    mov r2, [copy_buffer_ptr]
    call read
    mov r0, [copy_buffer_size]
    mov r1, [copy_dest_struct_ptr]
    mov r2, [copy_buffer_ptr]
    call write

    mov r0, [copy_buffer_ptr]
    call free_memory

    ret
copy_source_struct_ptr: data.32 0
copy_dest_struct_ptr: data.32 0
copy_buffer_ptr: data.32 0
copy_buffer_size: data.32 0

; seek specified file to the specified offset
; inputs:
; r0: byte offset
; r1: pointer to file struct
; outputs:
; none
seek:
    jmp ryfs_seek

; get the seek offset of the specified file
; inputs:
; r0: pointer to file struct
; outputs:
; r0: byte offset
tell:
    jmp ryfs_tell

; get the exact size of the specified file
; inputs:
; r0: pointer to file struct
; outputs:
; r0: size in bytes
get_size:
    push r1
    push r0
    add r0, 7
    movz.8 r1, [r0]
    pop r0
    cmp.8 r1, 0x00
    ifz pop r1
    ifz jmp ryfs_get_size
    cmp.8 r1, 0x01
    ifz pop r1
    ifz jmp stream_get_size
    pop r1
    ret
stream_get_size:
    add r0, 16
    mov r0, [r0]

    ret

; get the name of a directory previously opened with `open`
; inputs:
; r0: pointer to 13 byte buffer (max 8 chars + '.' + max 3 chars + null)
; r1: pointer to file struct
; outputs:
; none
get_dir_name:
    cmp.8 [r1+7], 0x00 ; must be RYFS
    ifnz ret
    push r0
    push r1

    push r0
    mov r0, get_dir_name_temp_str
    call ryfs_get_dir_name
    pop r1
    call copy_string

    pop r1
    pop r0
    ret
get_dir_name_temp_str: data.fill 0, 11

; get the sector of the parent of a directory previously opened with `open`
; inputs:
; r0: pointer to file struct
; outputs:
; r0: sector of the parent directory
get_parent_dir:
    cmp.8 [r0+7], 0x00 ; must be RYFS
    ifz jmp ryfs_get_parent_dir
    ret

; read specified number of bytes into the specified buffer
; inputs:
; r0: number of bytes to read
; r1: pointer to file struct
; r2: pointer to destination buffer
; outputs:
; none
read:
    cmp r0, 0
    ifz ret
    cmp r1, 0
    ifz ret
    cmp r2, 0
    ifz ret
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp ryfs_read
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_read
    pop r3
    ret
stream_read:
    push r0
    push r1
    push r2
stream_read_loop:
    call stream_read_char

    call save_state_and_yield_task

    inc r2
    dec r0
    ifnz jmp stream_read_loop

    pop r2
    pop r1
    pop r0
    ret
stream_read_char:
    push r0
    push r1
    push r2

    ; call [file_read_call] with seek offset in r0
    add r1, 3
    mov r0, [r1]
    add r1, 5
    call [r1]

    ; put the result into [r2]
    pop r2
    mov.8 [r2], r0

    ; increment the seek offset
    sub r1, 5
    inc [r1]

    pop r1
    pop r0
    ret

; write specified number of bytes into the specified file
; inputs:
; r0: number of bytes to write
; r1: pointer to file struct
; r2: pointer to source buffer
; outputs:
; none
write:
    cmp r0, 0
    ifz ret
    cmp r1, 0
    ifz ret
    push r3
    push r1
    add r1, 7
    movz.8 r3, [r1]
    pop r1
    cmp.8 r3, 0x00
    ifz pop r3
    ifz jmp call_ryfs_write
    cmp.8 r3, 0x01
    ifz pop r3
    ifz jmp stream_write
    pop r3
    ret
call_ryfs_write:
    ; `ryfs_write`, despite being written in okameron, clobbers r2 for some reason?
    push r2
    call ryfs_write
    pop r2
    ret
stream_write:
    push r31
    push r2

    mov r31, r0 ; number of bytes to write = loop count
stream_write_loop:
    call stream_write_char
    inc r2
    loop stream_write_loop

    pop r2
    pop r31
    ret
stream_write_char:
    push r0
    push r1
    push r3

    ; call [file_write_call] with pointer to src buf in r0 and seek offset in r1
    mov r3, r1
    add r3, 3
    mov r0, r2
    mov r1, [r3]
    add r3, 9
    call [r3]

    ; increment the seek offset
    sub r3, 9
    inc [r3]

    pop r3
    pop r1
    pop r0
    ret

; convert a user-friendly filename (test.txt) to the internal representation (test    txt)
; filenames without an extension (i.e. test) are assumed to be directories (test    dir)
; inputs:
; r0: pointer to null-terminated input string
; outputs:
; r0: pointer to null-terminated output string, or zero if failure
convert_filename:
    push r1
    push r2
    push r3
    push r31

    ; check the length of the filename to ensure it isn't too long
    mov r1, r0
    call vfs_string_length
    cmp r0, 12
    ifgt jmp convert_filename_fail
    cmp r0, 0
    ifz jmp convert_filename_fail

    ; fill the output string buffer with spaces and a null-terminator
    mov r2, convert_filename_output_string
    mov r31, 11
convert_filename_space_loop:
    mov.8 [r2], ' '
    inc r2
    loop convert_filename_space_loop
    mov.8 [r2], 0

    mov r2, convert_filename_output_string
    mov r3, 0

    ; r0: input filename length
    ; r1: pointer to input filename
    ; r2: pointer to output filename
    ; r3: number of characters processed
convert_filename_copy_loop:
    cmp.8 [r1], '.'
    ifz jmp convert_filename_found_ext
    mov.8 [r2], [r1]
    inc r1
    inc r2
    inc r3
    cmp r3, r0
    ifz jmp convert_filename_dir
    iflt jmp convert_filename_copy_loop
convert_filename_found_ext:
    cmp r3, 0
    ifz jmp convert_filename_fail
    cmp r3, 8
    ifgt jmp convert_filename_fail

    mov r2, convert_filename_output_string
    add r2, 8
    inc r1
    cmp.8 [r1], 0
    ifz jmp convert_filename_fail
    mov.8 [r2], [r1]
    inc r1
    inc r2
    cmp.8 [r1], 0
    ifz jmp convert_filename_done
    cmp.8 [r1], '/'
    ifz jmp convert_filename_done
    mov.8 [r2], [r1]
    inc r1
    inc r2
    cmp.8 [r1], 0
    ifz jmp convert_filename_done
    cmp.8 [r1], '/'
    ifz jmp convert_filename_done
    mov.8 [r2], [r1]
convert_filename_done:
    mov r0, convert_filename_output_string
    rjmp convert_filename_ret
convert_filename_dir:
    mov r2, convert_filename_output_string
    mov.8 [r2+8], 'd'
    mov.8 [r2+9], 'i'
    mov.8 [r2+10], 'r'
    rjmp convert_filename_done
convert_filename_fail:
    mov r0, 0
convert_filename_ret:
    pop r31
    pop r3
    pop r2
    pop r1
    ret
convert_filename_output_string: data.fill 0, 12
convert_filename_temp_file_struct: data.fill 0, 32

; iterate on a user-friendly directory path into its directory sector, and increment the path to the next '/'
; e.g. 2:/stuff.dir/test.txt will return r0 = "test.txt", r1 = sector of stuff.dir, r2 = 2, r3 = 0
;      /stuff.dir/another.dir/test.txt will return r0 = "another.dir/test.txt", r1 = sector of stuff.dir, r2 = <input disk ID>, r3 = <non-zero>
; the .dir extension of directory names may be omitted as needed; /stuff.dir/test.txt and /stuff/test.txt are treated the same
; trailing slashes in directory names are allowed (e.g. /stuff/ is treated the same as /stuff which is treated the same as /stuff.dir)
; inputs:
; r0: pointer to null-terminated path string
; r1: directory sector of previous iteration, or zero if no previous iteration
; r2: disk ID
; outputs:
; r0: pointer to null-terminated path string, incremented past the first directory
;     if zero, then r1 points to the sector of the file itself
; r1: directory sector containing file, or sector of file, or zero if failure
; r2: disk ID
; r3: zero if r0 or r1 points to the final file and not another directory; non-zero otherwise
iterate_dir_path:
    push r27
    push r28
    push r29
    push r30

    cmp.8 [r0], 0
    ifz mov r3, 0
    ifz rjmp iterate_dir_path_ret

    mov r27, r0
    mov r28, r2

    cmp r1, 0
    ifnz mov r29, r1 ; this isn't the first iteration
    ifnz rjmp iterate_dir_path_continue

    ; this is the first iteration
    ; is there a disk ID?
    cmp.8 [r27+1], ':'
    ifnz rjmp iterate_dir_path_check_root
    movz.8 r28, [r27]
    sub r28, '0'
    inc r27, 2
    ; force start from the root dir, since the disk id was overridden
    mov r29, 1
    rjmp iterate_dir_path_continue
iterate_dir_path_check_root:
    ; should we start from the root or the task's current dir?
    cmp.8 [r27], '/'
    ifz mov r29, 1 ; root dir
    ifnz movz.16 r29, [current_directory]
iterate_dir_path_continue:
    cmp.8 [r27], '/'
    ifz inc r27
    cmp.8 [r27], 0
    ifz rjmp iterate_dir_path_root

    mov r0, r27
    call vfs_string_length
    mov r30, r0

    ; r27: pointer to the directory name (incremented as we go along)
    ; r28: disk ID
    ; r29: currently searched directory sector
    ; r30: length of this directory name
    mov r0, r27

    push r0
    call vfs_string_length
    pop r2
    push r2
    add r2, r0
    pop r0
    cmp.16 [r2], 0x002F ; '/' and a null-terminator
    ifz rjmp iterate_dir_path_final_file ; trailing slash ignored
    cmp.8 [r2], 0
    ifnz rjmp iterate_dir_path_not_final_file
    rjmp iterate_dir_path_final_file
iterate_dir_path_root:
    ; the path we were given was simply "/" (with or without a disk ID)
    ; simply return 1 as the sector of the file, as that is the root dir
    mov r29, 1
    mov r0, 0
iterate_dir_path_final_file:
    ; this is the final file, no need to open it
    mov r1, r29
    mov r3, 0
    rjmp iterate_dir_path_ret
iterate_dir_path_not_final_file:
    call convert_filename
    mov r1, r28
    mov r2, iterate_dir_path_temp_file_struct
    mov r3, r29
    call ryfs_open
    ; it should have returned the sector of this directory
    cmp r0, 0
    ifz rjmp iterate_dir_path_fail

    mov r1, r0
    mov r0, r27
    add r0, r30

    push r0
    call vfs_string_length
    mov r2, r0
    pop r0
    push r0
    add r0, r2
    cmp.8 [r0], '/'
    ifz mov r3, 1
    ifz pop r0
    ifz rjmp iterate_dir_path_ret
    sub r0, 4
    push r1
    mov r1, iterate_dir_path_ending_str
    mov r3, 0
    call vfs_compare_string
    ifz inc r3
    mov r1, iterate_dir_path_ending_slash_str
    call vfs_compare_string
    ifz inc r3
    pop r1
    pop r0

    rjmp iterate_dir_path_ret
iterate_dir_path_fail:
    mov r0, 0
    mov r1, 0
    mov r3, 0
iterate_dir_path_ret:
    mov r2, r28
    pop r30
    pop r29
    pop r28
    pop r27
    ret
iterate_dir_path_temp_file_struct: data.fill 0, 32
iterate_dir_path_ending_str: data.strz ".dir"
iterate_dir_path_ending_slash_str: data.strz ".dir/"

; get the length of a string using 0 and '/' as the terminator
; inputs:
; r0: pointer to null-terminated or '/'-terminated string
; outputs:
; r0: length of the string, not including the terminator
vfs_string_length:
    push r1
    mov r1, 0
vfs_string_length_loop:
    cmp.8 [r0], 0
    ifz jmp vfs_string_length_end
    cmp.8 [r0], '/'
    ifz jmp vfs_string_length_end
    inc r0
    inc r1
    jmp vfs_string_length_loop
vfs_string_length_end:
    mov r0, r1
    pop r1
    ret

; compare string from source pointer with destination pointer using 0 and '/' as the terminator
; inputs:
; r0: pointer to source
; r1: pointer to destination
; outputs:
; Z flag
vfs_compare_string:
    push r0
    push r1
vfs_compare_string_loop:
    ; check if the strings match
    cmp.8 [r0], [r1]
    ifnz jmp vfs_compare_string_not_equal

    ; if this is the end of string 1, then this must also be the end of string 2
    ; the cmp above already ensured that both strings have a terminator here
    cmp.8 [r0], 0
    ifz jmp vfs_compare_string_equal
    cmp.8 [r0], '/'
    ifz jmp vfs_compare_string_equal

    inc r0
    inc r1
    jmp vfs_compare_string_loop
vfs_compare_string_not_equal:
    ; Z flag is already cleared at this point
    pop r1
    pop r0
    ret
vfs_compare_string_equal:
    ; set Z flag
    mov r0, 0
    cmp r0, 0
    pop r1
    pop r0
    ret

    ; named streams
    #include "vfs/disk0.asm"
    #include "vfs/disk1.asm"
    #include "vfs/disk2.asm"
    #include "vfs/disk3.asm"
    #include "vfs/fb.asm"
    #include "vfs/ofb.asm"
    #include "vfs/ramdisk.asm"
    #include "vfs/romdisk.asm"
    #include "vfs/serial.asm"
