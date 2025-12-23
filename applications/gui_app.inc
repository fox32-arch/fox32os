; GUI application header and support routines

    opton

    data.strz "APP"
    data.32 _gui_entry
    data.32 app_name
    data.32 app_desc
    data.32 app_author
    data.32 app_version
    data.32 app_icon

_gui_entry:
    call get_boot_disk_id
    mov r1, r0
    mov r0, winmgr_lbr_path
    call open_library
    cmp r0, 0
    ifz mov r0, winmgr_lbr_missing_str
    ifz call panic
    mov [winmgr_lbr], r0
    call start_event_manager_task

    rcall app_entry ; should be defined by the application
app_exit:
    call end_event_manager_task
    mov r0, [winmgr_lbr]
    call close_library
    call end_current_task

winmgr_lbr_path: data.strz "/system/library/winmgr.lbr"
winmgr_lbr_missing_str: data.str "/system/library/winmgr.lbr is missing!!" data.8 10 data.8 0
winmgr_lbr: data.32 0

; FIXME: find a better way to do this??
new_window:
    mov resp, [winmgr_lbr]
    jmp [resp+0]
destroy_window:
    mov resp, [winmgr_lbr]
    jmp [resp+4]
new_window_event:
    mov resp, [winmgr_lbr]
    jmp [resp+8]
get_next_window_event:
    mov resp, [winmgr_lbr]
    jmp [resp+12]
draw_title_bar_to_window:
    mov resp, [winmgr_lbr]
    jmp [resp+16]
move_window:
    mov resp, [winmgr_lbr]
    jmp [resp+20]
fill_window:
    mov resp, [winmgr_lbr]
    jmp [resp+24]
get_window_overlay_number:
    mov resp, [winmgr_lbr]
    jmp [resp+28]
start_dragging_window:
    mov resp, [winmgr_lbr]
    jmp [resp+32]
new_messagebox:
    mov resp, [winmgr_lbr]
    jmp [resp+36]
get_active_window_struct:
    mov resp, [winmgr_lbr]
    jmp [resp+40]
set_window_flags:
    mov resp, [winmgr_lbr]
    jmp [resp+44]
new_window_from_resource:
    mov resp, [winmgr_lbr]
    jmp [resp+48]
start_event_manager_task:
    mov resp, [winmgr_lbr]
    jmp [resp+52]
end_event_manager_task:
    mov resp, [winmgr_lbr]
    jmp [resp+56]

draw_widgets_to_window:
    mov resp, [winmgr_lbr]
    jmp [resp+60]
handle_widget_click:
    mov resp, [winmgr_lbr]
    jmp [resp+64]
handle_widget_key_down:
    mov resp, [winmgr_lbr]
    jmp [resp+68]
handle_widget_key_up:
    mov resp, [winmgr_lbr]
    jmp [resp+72]
