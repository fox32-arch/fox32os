FOX32ASM := ../../fox32asm/target/release/fox32asm

FILES = \
	../base_image/system/library/streamio.lbr \
	../base_image/system/library/winmgr.lbr \
	../base_image/system/library/qoi.lbr \
	../base_image/system/library/bmp.lbr

all: $(FILES)

../base_image/system/library/%.lbr: %/main.asm
	mkdir -p ../base_image/system/library
	$(FOX32ASM) $< $@

clean:
	rm -f $(FILES)
