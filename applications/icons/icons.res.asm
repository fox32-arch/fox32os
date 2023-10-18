const ICON_SIZE: 4096

    ; format: "RES" magic bytes, version, number of resource IDs
    data.str "RES" data.8 0 data.8 4

    ; format: 3 character null-terminated ID, pointer to data, size
    data.strz "abt" data.32 abt data.32 20
    data.strz "dsk" data.32 dsk data.32 ICON_SIZE
    data.strz "fxf" data.32 fxf data.32 ICON_SIZE
    data.strz "msc" data.32 msc data.32 ICON_SIZE

abt:
    data.strz "icons by horsesnoot"
dsk:
    #include "dsk.inc"
fxf:
    #include "fxf.inc"
msc:
    #include "msc.inc"
