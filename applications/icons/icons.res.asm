const ICON_SIZE: 4096

    ; format: "RES" magic bytes, version, number of resource IDs
    data.str "RES" data.8 0 data.8 3

    ; format: 3 character null-terminated ID, pointer to data, size
    data.strz "cfg" data.32 cfg_icon data.32 ICON_SIZE
    data.strz "dsk" data.32 dsk_icon data.32 ICON_SIZE
    data.strz "fxf" data.32 fxf_icon data.32 ICON_SIZE

cfg_icon:
    #include "cfg_icon.inc"
dsk_icon:
    #include "dsk_icon.inc"
fxf_icon:
    #include "fxf_icon.inc"
