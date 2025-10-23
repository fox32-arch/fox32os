OUTPUT = system/fetcher.fxf

include ../application.mk

all: ../../base_image/$(OUTPUT)

../../base_image/$(OUTPUT): Fetcher.okm $(wildcard *.okm)
	lua $(OKAMERON) -arch=fox32 -startup=start.asm $< \
		About.okm \
		Browser.okm \
		BrowserOpen.okm \
		Desktop.okm \
		OS.okm \
		> fetcher.asm
	$(FOX32ASM) fetcher.asm $@
	rm fetcher.asm
