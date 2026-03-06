ifeq (, $(shell which fox32asm 2>/dev/null))
FOX32ASM ?= ../../fox32asm/target/release/fox32asm
else
FOX32ASM ?= fox32asm
endif

ifeq (, $(shell which gfx2inc 2>/dev/null))
GFX2INC ?= ../../tools/gfx2inc/target/release/gfx2inc
else
GFX2INC ?= gfx2inc
endif

all: ../base_image/system/kernel.fxf

cursor/busy.inc: cursor/busy.png
	$(GFX2INC) 18 12 $< $@

../base_image/system/kernel.fxf: main.asm cursor/busy.inc $(wildcard *.asm */*.asm)
	$(FOX32ASM) $< $@
