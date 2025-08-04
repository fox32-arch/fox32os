; command parser

shell_parse_command:
    cmp.8 [shell_redirect_next], 0
    ifnz mov [shell_stream_struct_ptr], shell_redirect_stream_struct

    mov r0, shell_text_buf_bottom

    ; addr
    mov r1, shell_addr_command_string
    call compare_string
    ifz jmp shell_addr_command

    ; addi
    mov r1, shell_addi_command_string
    call compare_string
    ifz jmp shell_addi_command

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

    ; chgdir
    mov r1, shell_chgdir_command_string
    call compare_string
    ifz jmp shell_chgdir_command

    ; clear
    mov r1, shell_clear_command_string
    call compare_string
    ifz jmp shell_clear_command

    ; cmpi
    mov r1, shell_cmpi_command_string
    call compare_string
    ifz jmp shell_cmpi_command

    ; cmpr
    mov r1, shell_cmpr_command_string
    call compare_string
    ifz jmp shell_cmpr_command

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

    ; echord
    mov r1, shell_echord_command_string
    call compare_string
    ifz jmp shell_echord_command

    ; echorh
    mov r1, shell_echorh_command_string
    call compare_string
    ifz jmp shell_echorh_command

    ; echors
    mov r1, shell_echors_command_string
    call compare_string
    ifz jmp shell_echors_command

    ; echov
    mov r1, shell_echov_command_string
    call compare_string
    ifz jmp shell_echov_command

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

    ; newdir
    mov r1, shell_newdir_command_string
    call compare_string
    ifz jmp shell_newdir_command

    ; peek
    mov r1, shell_peek_command_string
    call compare_string
    ifz jmp shell_peek_command

    ; poke
    mov r1, shell_poke_command_string
    call compare_string
    ifz jmp shell_poke_command

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

    ; movi
    mov r1, shell_movi_command_string
    call compare_string
    ifz jmp shell_movi_command

    ; movr
    mov r1, shell_movr_command_string
    call compare_string
    ifz jmp shell_movr_command

    ; shutdown
    mov r1, shell_shutdown_command_string
    call compare_string
    ifz jmp shell_shutdown_command

    ; subr
    mov r1, shell_subr_command_string
    call compare_string
    ifz jmp shell_subr_command

    ; subi
    mov r1, shell_subi_command_string
    call compare_string
    ifz jmp shell_subi_command

    ; type
    mov r1, shell_type_command_string
    call compare_string
    ifz jmp shell_type_command

    ; attempt to run a FXF binary
    call launch_fxf

    ; invalid command
    mov r0, shell_invalid_command_string
    call print_str_to_terminal
    mov [shell_command_return_value], 255 ; return 255 to indicate invalid command

    ret

shell_rem_command_string: data.strz "rem"
shell_invalid_command_string: data.str "invalid command or FXF binary" data.8 10 data.8 0

    ; all commands
    #include "commands/call.asm"
    #include "commands/chgdir.asm"
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
    #include "commands/memory.asm"
    #include "commands/newdir.asm"
    #include "commands/rdall.asm"
    #include "commands/rdnext.asm"
    #include "commands/set.asm"
    #include "commands/shutdown.asm"
    #include "commands/type.asm"
