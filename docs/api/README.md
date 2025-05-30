# fox32os Application Structure

**Note**: These documents are still a work-in-progress and might contain missing
          information. The goal is to eventually have all fox32{rom,os} APIs
          documented with examples. See the other documents in this directory
          for the current progress on that.

In general, fox32os applications are expected to follow certain conventions in
order to ensure they play nicely with the rest of the system. There are a few
things to keep in mind:

- Applications have full control over their windows, including the responsibility
  of responding to the user attempting to move and close them.
- Applications are responsible for cleaning up after themselves. The OS will not
  free any memory that is still left allocated when your application ends.
- Since the fox32os kernel offers no memory protection, applications must be
  respectful towards other things living in memory.
- When an application's task (aka process) is actively running, it essentially
  has full control over the system. It is up to the application to yield to the
  next task in the queue. Failing to do this means the system is effectively
  locked up *and the application will stop receiving window events*.

## Event Loop

Graphical applications generally all follow a similar structure: Initialize any
data needed and create the window, poll for events in a loop and act upon them
(making sure to yield after each iteration!), then finally clean up any
allocated memory and exit.

A simplified example of this is shown below:

```avrasm
entry:
    mov r0, window_struct ; addr of block of memory to hold the window data
    mov r1, window_title  ; addr of null-terminated window title string
    mov r2, 256           ; window width (in pixels)
    mov r3, 256           ; window height (in pixels, excluding the title bar)
    mov r4, 64            ; initial X coordinate (top left corner of title bar)
    mov r5, 64            ; initial Y coordinate (top left corner of title bar)
    mov r6, menu_items    ; pointer to menu bar structure, or zero for none
    mov r7, widgets       ; pointer to widget structure, or zero for none
    call new_window

event_loop:
    mov r0, window_struct
    call get_next_window_event
    ; r0:    event type
    ; r1-r7: event parameters

    ; handle needed events here
    ; e.g.: did the user click somewhere in the window?
    cmp r0, EVENT_TYPE_MOUSE_CLICK
    ifz jmp mouse_click_event

    ; yield to the next task
    ; this also gets events ready for the `get_next_window_event` call above
    call yield_task
    rjmp event_loop

mouse_click_event:
    ; check if the user is attempting to drag or close the window
    cmp r2, 16
    iflteq jmp drag_or_close_window

    ; handle your mouse click logic here

    rjmp event_loop

drag_or_close_window:
    ; clicked X position <= 8, user clicked close box
    cmp r1, 8
    iflteq rjmp close_window
    ; otherwise start dragging the window
    mov r0, window_struct
    call start_dragging_window
    rjmp event_loop
close_window:
    mov r0, window_struct
    call destroy_window
    ; our window is closed and there no other allocations to free here. exit!
    call end_current_task
```
