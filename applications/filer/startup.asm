// GUI application header and support routines

.section text

    .ds "APP" .db 0
    .dp _gui_entry
    .dp app_name
    .dp app_desc
    .dp app_author
    .dp app_version
    .dl 0 // no icon

_gui_entry:
    call [0x00000820] // get_boot_disk_id
    mov r1, r0
    mov r0, _winmgr_lbr_path
    call [0x00000824] // open_library
    cmp r0, 0
    ifz mov r0, _winmgr_lbr_missing_str
    ifz call [0xF0040018] // panic
    mov [_winmgr_lbr], r0
    mov r31, r1
    srl r31, 2 // 4 bytes per jump table entry
    mov r2, _winmgr_lbr_table
_gui_entry_copy_table_loop:
    mov [r2], [r0]
    inc r0, 4
    inc r2, 4
    rloop _gui_entry_copy_table_loop
    call start_event_manager_task

    call app_entry // should be defined by the application
app_exit:
.global app_exit
    call end_event_manager_task
    mov r0, [_winmgr_lbr]
    call [0x00000828] // close_library
    call [0x00000A18] // end_current_task

_winmgr_lbr_path: .ds "/system/library/winmgr.lbr" .db 0
_winmgr_lbr_missing_str: .ds "/system/library/winmgr.lbr is missing!!" .db 10 .db 0
_winmgr_lbr: .dl 0

_winmgr_lbr_table:
_winmgr_lbr_fn_new_window: .dl 0
_winmgr_lbr_fn_destroy_window: .dl 0
_winmgr_lbr_fn_new_window_event: .dl 0
_winmgr_lbr_fn_get_next_window_event: .dl 0
_winmgr_lbr_fn_draw_title_bar_to_window: .dl 0
_winmgr_lbr_fn_move_window: .dl 0
_winmgr_lbr_fn_fill_window: .dl 0
_winmgr_lbr_fn_get_window_overlay_number: .dl 0
_winmgr_lbr_fn_start_dragging_window: .dl 0
_winmgr_lbr_fn_new_messagebox: .dl 0
_winmgr_lbr_fn_get_active_window_struct: .dl 0
_winmgr_lbr_fn_set_window_flags: .dl 0
_winmgr_lbr_fn_new_window_from_resource: .dl 0
_winmgr_lbr_fn_start_event_manager_task: .dl 0
_winmgr_lbr_fn_end_event_manager_task: .dl 0
_winmgr_lbr_fn_draw_widgets_to_window: .dl 0
_winmgr_lbr_fn_handle_widget_click: .dl 0
_winmgr_lbr_fn_handle_widget_key_down: .dl 0
_winmgr_lbr_fn_handle_widget_key_up: .dl 0

new_window: jmp [_winmgr_lbr_fn_new_window]
.global new_window
destroy_window: jmp [_winmgr_lbr_fn_destroy_window]
.global destroy_window
new_window_event: jmp [_winmgr_lbr_fn_new_window_event]
.global new_window_event
get_next_window_event: jmp [_winmgr_lbr_fn_get_next_window_event]
.global get_next_window_event
draw_title_bar_to_window: jmp [_winmgr_lbr_fn_draw_title_bar_to_window]
.global draw_title_bar_to_window
move_window: jmp [_winmgr_lbr_fn_move_window]
.global move_window
fill_window: jmp [_winmgr_lbr_fn_fill_window]
.global fill_window
get_window_overlay_number: jmp [_winmgr_lbr_fn_get_window_overlay_number]
.global get_window_overlay_number
start_dragging_window: jmp [_winmgr_lbr_fn_start_dragging_window]
.global start_dragging_window
new_messagebox: jmp [_winmgr_lbr_fn_new_messagebox]
.global new_messagebox
get_active_window_struct: jmp [_winmgr_lbr_fn_get_active_window_struct]
.global get_active_window_struct
set_window_flags: jmp [_winmgr_lbr_fn_set_window_flags]
.global set_window_flags
new_window_from_resource: jmp [_winmgr_lbr_fn_new_window_from_resource]
.global new_window_from_resource
start_event_manager_task: jmp [_winmgr_lbr_fn_start_event_manager_task]
.global start_event_manager_task
end_event_manager_task: jmp [_winmgr_lbr_fn_end_event_manager_task]
.global end_event_manager_task
draw_widgets_to_window: jmp [_winmgr_lbr_fn_draw_widgets_to_window]
.global draw_widgets_to_window
handle_widget_click: jmp [_winmgr_lbr_fn_handle_widget_click]
.global handle_widget_click
handle_widget_key_down: jmp [_winmgr_lbr_fn_handle_widget_key_down]
.global handle_widget_key_down
handle_widget_key_up: jmp [_winmgr_lbr_fn_handle_widget_key_up]
.global handle_widget_key_up
