    ; format: "RES" magic bytes, version, number of resource IDs
    data.str "RES" data.8 0 data.8 1

    ; format: 3 character null-terminated ID, pointer to data, size
    data.strz "***" data.32 ANY data.32 18

ANY:
    data.strz "/apps/hjkl.fxf %s"
