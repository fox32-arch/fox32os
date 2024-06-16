; RES resource routines

; extract a RES binary from an FXF binary, handling relocations as needed
; inputs:
; r0: pointer to memory buffer containing an FXF binary
; outputs:
; r0: relocation address or 0 on error
get_res_in_fxf:
    jmp parse_fxf_binary

; extract resource data from a RES binary loaded in memory
; inputs:
; r0: pointer to memory buffer containing a RES binary
; r1: pointer to 3 character null-terminated resource ID string
; r2: size of resource data to be extracted
; outputs:
; r0: pointer to newly-allocated memory buffer containing the requested resource data
;     this buffer must be freed by the caller!
;     returns zero if resource ID not found, not enough memory, or invalid magic bytes
get_resource:
    cmp [r0], [res_magic]
    ifz jmp get_resource_is_res
    cmp [r0], [rsf_magic]
    ifz jmp get_resource_is_rsf
    mov r0, 0
    ret
get_resource_is_res:
    push r3
    push r4
    push r31
    mov r4, 0
    jmp get_resource_go
get_resource_is_rsf:
    push r3
    push r4
    push r31
    mov r4, 1
get_resource_go:
    mov r3, r0
    movz.8 r31, [r0+4]
    add r0, 5
get_resource_find_loop:
    cmp [r0], [r1]
    ifz jmp get_resource_found
    add r0, 12
    loop get_resource_find_loop
    mov r0, 0
    jmp get_resource_end
get_resource_found:
    cmp r2, [r0+8]
    ifgt mov r2, [r0+8]
    mov r31, [r0+4]
    cmp.8 r4, 0
    ifz add r31, r3
    mov r0, r2
    call allocate_memory
    cmp r0, 0
    ifz jmp get_resource_end
    mov r1, r0
    mov r0, r31
    call copy_memory_bytes
    mov r0, r1
get_resource_end:
    pop r31
    pop r4
    pop r3
    ret

res_magic: data.strz "RES"
rsf_magic: data.strz "RSF"
