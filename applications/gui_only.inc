; GUI application header

    opton

_gui_entry:
    call get_boot_disk_id
    mov r1, r0
    mov r0, _winmgr_lbr_path
    call open_library
    cmp r0, 0
    ifz mov r0, _winmgr_lbr_missing_str
    ifz call panic
    mov [_winmgr_lbr], r0
    mov r31, r1
    srl r31, 2 ; 4 bytes per jump table entry
    mov r2, _winmgr_lbr_table
_gui_entry_copy_table_loop:
    mov [r2], [r0]
    inc r0, 4
    inc r2, 4
    rloop _gui_entry_copy_table_loop
    call start_event_manager_task

    rcall app_entry ; should be defined by the application
app_exit:
    call end_event_manager_task
    mov r0, [_winmgr_lbr]
    call close_library
    call end_current_task

_winmgr_lbr_path: data.strz "/system/library/winmgr.lbr"
_winmgr_lbr_missing_str: data.str "/system/library/winmgr.lbr is missing!!" data.8 10 data.8 0
_winmgr_lbr: data.32 0

_winmgr_lbr_table:
_winmgr_lbr_fn_new_window: data.32 0
_winmgr_lbr_fn_destroy_window: data.32 0
_winmgr_lbr_fn_new_window_event: data.32 0
_winmgr_lbr_fn_get_next_window_event: data.32 0
_winmgr_lbr_fn_draw_title_bar_to_window: data.32 0
_winmgr_lbr_fn_move_window: data.32 0
_winmgr_lbr_fn_fill_window: data.32 0
_winmgr_lbr_fn_get_window_overlay_number: data.32 0
_winmgr_lbr_fn_start_dragging_window: data.32 0
_winmgr_lbr_fn_new_messagebox: data.32 0
_winmgr_lbr_fn_get_active_window_struct: data.32 0
_winmgr_lbr_fn_set_window_flags: data.32 0
_winmgr_lbr_fn_new_window_from_resource: data.32 0
_winmgr_lbr_fn_start_event_manager_task: data.32 0
_winmgr_lbr_fn_end_event_manager_task: data.32 0
_winmgr_lbr_fn_draw_widgets_to_window: data.32 0
_winmgr_lbr_fn_handle_widget_click: data.32 0
_winmgr_lbr_fn_handle_widget_key_down: data.32 0
_winmgr_lbr_fn_handle_widget_key_up: data.32 0

new_window: jmp [_winmgr_lbr_fn_new_window]
destroy_window: jmp [_winmgr_lbr_fn_destroy_window]
new_window_event: jmp [_winmgr_lbr_fn_new_window_event]
get_next_window_event: jmp [_winmgr_lbr_fn_get_next_window_event]
draw_title_bar_to_window: jmp [_winmgr_lbr_fn_draw_title_bar_to_window]
move_window: jmp [_winmgr_lbr_fn_move_window]
fill_window: jmp [_winmgr_lbr_fn_fill_window]
get_window_overlay_number: jmp [_winmgr_lbr_fn_get_window_overlay_number]
start_dragging_window: jmp [_winmgr_lbr_fn_start_dragging_window]
new_messagebox: jmp [_winmgr_lbr_fn_new_messagebox]
get_active_window_struct: jmp [_winmgr_lbr_fn_get_active_window_struct]
set_window_flags: jmp [_winmgr_lbr_fn_set_window_flags]
new_window_from_resource: jmp [_winmgr_lbr_fn_new_window_from_resource]
start_event_manager_task: jmp [_winmgr_lbr_fn_start_event_manager_task]
end_event_manager_task: jmp [_winmgr_lbr_fn_end_event_manager_task]
draw_widgets_to_window: jmp [_winmgr_lbr_fn_draw_widgets_to_window]
handle_widget_click: jmp [_winmgr_lbr_fn_handle_widget_click]
handle_widget_key_down: jmp [_winmgr_lbr_fn_handle_widget_key_down]
handle_widget_key_up: jmp [_winmgr_lbr_fn_handle_widget_key_up]
