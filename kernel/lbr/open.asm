; LBR open/close routines

; open an LBR-format library from a file on disk
; inputs:
; r0: pointer to LBR binary path
; r1: disk ID
; outputs:
; r0: address of library jump table, or 0 on error
; r1: size of library jump table in bytes (i.e. 4 bytes per table entry)
open_library:
    push r2
    push r3
    push r4
    push r5
    push r6

    ; check if this library is already open
    push r0
    call search_for_library_list_entry_by_name
    cmp r0, 0xFFFFFFFF
    ifz rjmp.16 open_library_from_disk

    ; if we reach this point then the library is already open
    ; r0 contains the list offset, ignore the pushed value
    inc rsp, 4
    mul r0, LIBRARY_SIZE
    add r0, open_library_list
    inc [r0+4] ; increment ref_count
    mov r1, [r0+12] ; return the jump table size
    mov r0, [r0+8] ; and jump table pointer
    rjmp.16 open_library_from_disk_ret
open_library_from_disk:
    pop r0

    ; open the file
    mov r2, open_library_struct
    call open
    push r0
    cmp r0, 0
    ifz jmp open_library_from_disk_file_error

    ; allocate memory for the binary
    mov r0, open_library_struct
    call get_size
    push r0
    call allocate_memory
    cmp r0, 0
    ifz jmp open_library_from_disk_allocate_error
    mov [open_library_binary_ptr], r0

    ; read the file into memory
    pop r0
    mov r1, open_library_struct
    mov r2, [open_library_binary_ptr]
    call read

    ; relocate the binary
    mov r0, [open_library_binary_ptr]
    call parse_lbr_binary
    cmp r0, 0
    ifz jmp open_library_from_disk_reloc_error

    ; add it to the list of open libraries
    mov [open_library_jump_ptr], r0
    mov [open_library_jump_size], r1
    call search_for_empty_library_list_entry
    mov r1, r0
    add r1, open_library_list
    pop r0
    mov [r1], r0 ; set file_sector
    mov [r1+4], 1 ; initialize ref_count
    mov [r1+8], [open_library_jump_ptr] ; set table_ptr
    mov [r1+12], [open_library_jump_size] ; set table_size
    mov r0, [open_library_jump_ptr] ; return jump table pointer
    mov r1, r0
    dec r1, 4
    mov [r1], [open_library_binary_ptr] ; save the binary pointer
    mov r1, [open_library_jump_size] ; return jump table size
open_library_from_disk_ret:
    pop r6
    pop r5
    pop r4
    pop r3
    pop r2
    ; r0 and r1 already contain return values
    ret
open_library_from_disk_file_error:
open_library_from_disk_allocate_error:
    pop r0
    rjmp.16 open_library_from_disk_error
open_library_from_disk_reloc_error:
    mov r0, [open_library_binary_ptr]
    call free_memory
    ; fall-through
open_library_from_disk_error:
    mov r0, 0
    mov r1, 0
    rjmp.16 open_library_from_disk_ret
open_library_struct_ptr: data.32 0
open_library_struct: data.fill 0, 32
open_library_binary_ptr: data.32 0
open_library_jump_ptr: data.32 0
open_library_jump_size: data.32 0

; close an LBR-format library that was previously opened by `open_library`
; inputs:
; r0: address of library jump table
; outputs:
; none
close_library:
    push r0

    call search_for_library_list_entry_by_jump_table
    cmp r0, 0xFFFFFFFF
    ifz rjmp.16 close_library_ret
    mul r0, LIBRARY_SIZE
    add r0, open_library_list

    dec [r0+4] ; decrement ref_count
    cmp [r0+4], 0
    ifnz rjmp.16 close_library_ret

    ; free the block of memory if ref_count is now zero
    push r0
    mov r0, [r0+8] ; r0 = table_ptr
    dec r0, 4      ; r0 = table_ptr - 4 (contains ptr to free)
    mov r0, [r0]   ; r0 = pointer to block to free
    call free_memory
    pop r0

    ; clear the entry in the library list
    mov [r0], 0
    mov [r0+4], 0
    mov [r0+8], 0
    mov [r0+12], 0
close_library_ret:
    pop r0
    ret

; FIXME: the routines below can be condensed into a single routine that
;        takes a different path depending on the type of search needed

; search for an entry in the open library list by name
; inputs:
; r0: pointer to null-terminated file path
; r1: disk ID
; outputs:
; r0: list offset, or 0xFFFFFFFF if not found
search_for_library_list_entry_by_name:
    push r1
    push r2
    push r31

    mov r2, open_library_struct
    call open
    cmp r0, 0
    ifz rjmp search_for_library_list_entry_by_name_fail

    mov r1, open_library_list
    mov r2, 0
    mov r31, MAX_OPEN_LIBRARIES
search_for_library_list_entry_by_name_loop:
    cmp [r1], r0
    ifz rjmp.16 search_for_library_list_entry_by_name_found
    add r2, LIBRARY_SIZE
    add r1, LIBRARY_SIZE
    rloop.16 search_for_library_list_entry_by_name_loop
search_for_library_list_entry_by_name_fail:
    ; not found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF
search_for_library_list_entry_by_name_ret:
    pop r31
    pop r2
    pop r1
    ret
search_for_library_list_entry_by_name_found:
    ; found the entry, return its offset
    mov r0, r2
    rjmp.16 search_for_library_list_entry_by_name_ret

; search for an entry in the open library list by jump table address
; inputs:
; r0: address of library jump table
; outputs:
; r0: list offset, or 0xFFFFFFFF if not found
search_for_library_list_entry_by_jump_table:
    push r1
    push r2
    push r31

    mov r1, open_library_list
    mov r2, 0
    mov r31, MAX_OPEN_LIBRARIES
search_for_library_list_entry_by_jump_table_loop:
    cmp [r1+8], r0
    ifz rjmp.16 search_for_library_list_entry_by_jump_table_found
    add r2, LIBRARY_SIZE
    add r1, LIBRARY_SIZE
    rloop.16 search_for_library_list_entry_by_jump_table_loop
    ; not found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF
search_for_library_list_entry_by_jump_table_ret:
    pop r31
    pop r2
    pop r1
    ret
search_for_library_list_entry_by_jump_table_found:
    ; found the entry, return its offset
    mov r0, r2
    rjmp.16 search_for_library_list_entry_by_jump_table_ret

; search for an empty entry in the open library list
; inputs:
; none
; outputs:
; r0: list offset, or 0xFFFFFFFF if not found
search_for_empty_library_list_entry:
    push r1
    push r2
    push r31

    mov r1, open_library_list
    mov r2, 0
    mov r31, MAX_OPEN_LIBRARIES
search_for_empty_library_list_entry_loop:
    cmp.8 [r1], 0
    ifz rjmp.16 search_for_empty_library_list_entry_found
    add r2, LIBRARY_SIZE
    add r1, LIBRARY_SIZE
    rloop.16 search_for_empty_library_list_entry_loop
    ; not found, return 0xFFFFFFFF
    mov r0, 0xFFFFFFFF
search_for_empty_library_list_entry_ret:
    pop r31
    pop r2
    pop r1
    ret
search_for_empty_library_list_entry_found:
    ; found the entry, return its offset
    mov r0, r2
    rjmp.16 search_for_empty_library_list_entry_ret

const LIBRARY_SIZE: 16
const MAX_OPEN_LIBRARIES: 32
; library struct:
; data.32 file_sector - first file sector of this library as returned by `open`
; data.32 ref_count   - number of times this library has been opened; will free memory when this reaches zero
; data.32 table_ptr   - pointer to this library's jump table
; data.32 table_size  - size of this library's jump table in bytes
open_library_list: data.fill 0, 512 ; MAX_OPEN_LIBRARIES library structs * LIBRARY_SIZE bytes = 512
