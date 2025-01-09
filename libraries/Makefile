FOX32ASM := ../../fox32asm/target/release/fox32asm

FILES = \
	../base_image/streamio.lbr

all: $(FILES)

../base_image/%.lbr: %/main.asm
	$(FOX32ASM) $< $@

clean:
	rm -f $(FILES)
