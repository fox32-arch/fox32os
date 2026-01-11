ifeq (, $(shell which fox32asm 2>/dev/null))
FOX32ASM ?= ../../fox32asm/target/release/fox32asm
else
FOX32ASM ?= fox32asm
endif

all: ../base_image/system/kernel.fxf

../base_image/system/kernel.fxf: main.asm $(wildcard *.asm */*.asm)
	$(FOX32ASM) $< $@
