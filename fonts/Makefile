FOX32ASM ?= ../../fox32asm/target/release/fox32asm
GFX2INC ?= ../../tools/gfx2inc/target/release/gfx2inc

FILES = \
	casual-b.fnt \
	casual-t.fnt

all: $(FILES)

%.fnt: %.asm
	mkdir -p ../base_image/system/font
	$(GFX2INC) 8 16 $(patsubst %.asm,%.png,$<) $(patsubst %.fnt,%.inc,$@)
	$(FOX32ASM) $< $@
	cp $@ ../base_image/system/font/

clean:
	$(RM) -f $(FILES) ../base_image/system/font/*.fnt
