; command parser

shell_parse_command:
    cmp.8 [shell_redirect_next], 0
    ifnz mov [shell_stream_struct_ptr], shell_redirect_stream_struct

    mov r0, shell_text_buf_bottom

    ; addreg
    mov r1, shell_addreg_command_string
    call compare_string
    ifz jmp shell_addreg_command

    ; addimm
    mov r1, shell_addimm_command_string
    call compare_string
    ifz jmp shell_addimm_command

    ; call
    mov r1, shell_call_command_string
    call compare_string
    ifz jmp shell_call_command

    ; callff
    mov r1, shell_callff_command_string
    call compare_string
    ifz jmp shell_callff_command

    ; callref
    mov r1, shell_callref_command_string
    call compare_string
    ifz jmp shell_callref_command

    ; callrw
    mov r1, shell_callrw_command_string
    call compare_string
    ifz jmp shell_callrw_command

    ; clear
    mov r1, shell_clear_command_string
    call compare_string
    ifz jmp shell_clear_command

    ; cmpimm
    mov r1, shell_cmpimm_command_string
    call compare_string
    ifz jmp shell_cmpimm_command

    ; cmpreg
    mov r1, shell_cmpreg_command_string
    call compare_string
    ifz jmp shell_cmpreg_command

    ; copy
    mov r1, shell_copy_command_string
    call compare_string
    ifz jmp shell_copy_command

    ; del
    mov r1, shell_del_command_string
    call compare_string
    ifz jmp shell_del_command

    ; dir
    mov r1, shell_dir_command_string
    call compare_string
    ifz jmp shell_dir_command

    ; disk
    mov r1, shell_disk_command_string
    call compare_string
    ifz jmp shell_disk_command

    ; diskrm
    mov r1, shell_diskrm_command_string
    call compare_string
    ifz jmp shell_diskrm_command

    ; echo
    mov r1, shell_echo_command_string
    call compare_string
    ifz jmp shell_echo_command

    ; echoregd
    mov r1, shell_echoregd_command_string
    call compare_string
    ifz jmp shell_echoregd_command

    ; echoregh
    mov r1, shell_echoregh_command_string
    call compare_string
    ifz jmp shell_echoregh_command

    ; echoregs
    mov r1, shell_echoregs_command_string
    call compare_string
    ifz jmp shell_echoregs_command

    ; exit
    mov r1, shell_exit_command_string
    call compare_string
    ifz jmp shell_exit_command

    ; ff
    mov r1, shell_ff_command_string
    call compare_string
    ifz jmp shell_ff_command

    ; getreg
    mov r1, shell_getreg_command_string
    call compare_string
    ifz jmp shell_getreg_command

    ; heap
    mov r1, shell_heap_command_string
    call compare_string
    ifz jmp shell_heap_command

    ; help
    mov r1, shell_help_command_string
    call compare_string
    ifz jmp shell_help_command

    ; ifnz
    mov r1, shell_ifnz_command_string
    call compare_string
    ifz jmp shell_ifnz_command

    ; ifz
    mov r1, shell_ifz_command_string
    call compare_string
    ifz jmp shell_ifz_command

    ; label
    mov r1, shell_label_command_string
    call compare_string
    ifz jmp shell_label_command

    ; rdall
    mov r1, shell_rdall_command_string
    call compare_string
    ifz jmp shell_rdall_command

    ; rdnext
    mov r1, shell_rdnext_command_string
    call compare_string
    ifz jmp shell_rdnext_command

    ; rem
    mov r1, shell_rem_command_string
    call compare_string
    ifz ret

    ; ret
    mov r1, shell_ret_command_string
    call compare_string
    ifz jmp shell_ret_command

    ; rw
    mov r1, shell_rw_command_string
    call compare_string
    ifz jmp shell_rw_command

    ; setfrom
    mov r1, shell_setfrom_command_string
    call compare_string
    ifz jmp shell_setfrom_command

    ; setreg
    mov r1, shell_setreg_command_string
    call compare_string
    ifz jmp shell_setreg_command

    ; shutdown
    mov r1, shell_shutdown_command_string
    call compare_string
    ifz jmp shell_shutdown_command

    ; subreg
    mov r1, shell_subreg_command_string
    call compare_string
    ifz jmp shell_subreg_command

    ; subimm
    mov r1, shell_subimm_command_string
    call compare_string
    ifz jmp shell_subimm_command

    ; type
    mov r1, shell_type_command_string
    call compare_string
    ifz jmp shell_type_command

    ; attempt to run a FXF binary
    call launch_fxf

    ; invalid command
    mov r0, shell_invalid_command_string
    call print_str_to_terminal

    ret

shell_rem_command_string: data.strz "rem"
shell_invalid_command_string: data.str "invalid command or FXF binary" data.8 10 data.8 0

    ; all commands
    #include "commands/call.asm"
    #include "commands/clear.asm"
    #include "commands/cmp.asm"
    #include "commands/copy.asm"
    #include "commands/del.asm"
    #include "commands/dir.asm"
    #include "commands/disk.asm"
    #include "commands/diskrm.asm"
    #include "commands/echo.asm"
    #include "commands/exit.asm"
    #include "commands/head.asm"
    #include "commands/heap.asm"
    #include "commands/help.asm"
    #include "commands/if.asm"
    #include "commands/math.asm"
    #include "commands/rdall.asm"
    #include "commands/rdnext.asm"
    #include "commands/set.asm"
    #include "commands/shutdown.asm"
    #include "commands/type.asm"
