OUTPUT = system/ted.fxf

include ../application.mk

all: ../../base_image/$(OUTPUT)

../../base_image/$(OUTPUT): TEd.okm $(wildcard *.okm)
	lua $(OKAMERON) -arch=fox32 -startup=start.asm $< OS.okm > ted.asm
	$(FOX32ASM) ted.asm $@
	rm ted.asm
