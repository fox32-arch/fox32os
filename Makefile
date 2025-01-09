RYFS := $(CURDIR)/meta/ryfs/ryfs.py
FOX32ASM := ../fox32asm/target/release/fox32asm
OKAMERON := $(CURDIR)/meta/okameron/okameron.lua
GFX2INC := ../tools/gfx2inc/target/release/gfx2inc

IMAGE_SIZE := 16777216
ROM_IMAGE_SIZE := 196608
BOOTLOADER := bootloader/bootloader.bin

all: base_image/streamio.lbr fox32os.img romdisk.img

base_image:
	mkdir -p base_image

base_image/kernel.fxf: kernel/main.asm $(wildcard kernel/*.asm kernel/*/*.asm)
	$(FOX32ASM) $< $@

base_image/sh.fxf: applications/sh/main.asm $(wildcard applications/sh/*.asm applications/sh/*/*.asm)
	$(FOX32ASM) $< $@

base_image/barclock.fxf: applications/barclock/main.asm
	$(FOX32ASM) $< $@

base_image/terminal.fxf: applications/terminal/main.asm $(wildcard applications/terminal/*.asm)
	$(FOX32ASM) $< $@

base_image/fetcher.fxf: applications/fetcher/Fetcher.okm $(wildcard applications/fetcher/*.okm)
	lua $(OKAMERON) -arch=fox32 -startup=applications/fetcher/start.asm $< \
		applications/fetcher/About.okm \
		applications/fetcher/Browser.okm \
		applications/fetcher/BrowserOpen.okm \
		applications/fetcher/Desktop.okm \
		applications/fetcher/OS.okm \
		> applications/fetcher/fetcher.asm
	$(FOX32ASM) applications/fetcher/fetcher.asm $@
	rm applications/fetcher/fetcher.asm

base_image/pride.fxf: applications/pride/main.asm
	$(FOX32ASM) $< $@

base_image/loadfont.fxf: applications/loadfont/main.asm
	$(FOX32ASM) $< $@

base_image/tasks.fxf: applications/tasks/main.asm
	$(FOX32ASM) $< $@

base_image/serial.fxf: applications/serial/main.asm $(wildcard applications/terminal/*.asm)
	$(FOX32ASM) $< $@

base_image/foxpaint.fxf: applications/foxpaint/main.asm
	$(FOX32ASM) $< $@

base_image/ted.fxf: applications/ted/TEd.okm $(wildcard applications/ted/*.okm)
	lua $(OKAMERON) -arch=fox32 -startup=applications/ted/start.asm $< \
		applications/ted/OS.okm \
		> applications/ted/ted.asm
	$(FOX32ASM) applications/ted/ted.asm $@
	rm applications/ted/ted.asm

base_image/okmpaint.fxf: applications/okmpaint/OkmPaint.okm $(wildcard applications/okmpaint/*.okm)
	lua $(OKAMERON) -arch=fox32 -startup=applications/okmpaint/start.asm $< > applications/okmpaint/okmpaint.asm
	$(FOX32ASM) applications/okmpaint/okmpaint.asm $@
	rm applications/okmpaint/okmpaint.asm

base_image/bg.fxf: applications/bg/main.asm
	$(FOX32ASM) $< $@

base_image/bg.bmp: applications/bg/bg.bmp
	cp $< $@

base_image/launcher.fxf: applications/launcher/main.asm $(wildcard applications/launcher/*.asm) applications/launcher/icons.inc
	$(FOX32ASM) $< $@

applications/launcher/icons.inc: applications/launcher/icons.png
	$(GFX2INC) 16 16 $< $@

bootloader/bootloader.bin: bootloader/main.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@

base_image/startup.bat: base_image/startup.bat.default
	cp $< $@

ICONS16 := \
	applications/icons/mnu.inc

ICONS32 := \
	applications/icons/dsk.inc \
	applications/icons/fxf.inc \
	applications/icons/msc.inc

applications/icons/%.inc: applications/icons/%.16.png
	$(GFX2INC) 16 16 $< $@
applications/icons/%.inc: applications/icons/%.32.png
	$(GFX2INC) 32 32 $< $@
base_image/icons.res: applications/icons/icons.res.asm $(ICONS16) $(ICONS32)
	$(FOX32ASM) $< $@

FILES = \
	base_image/startup.bat \
	base_image/icons.res \
	base_image/kernel.fxf \
	base_image/sh.fxf \
	base_image/barclock.fxf \
	base_image/terminal.fxf \
	base_image/fetcher.fxf \
	base_image/serial.fxf \
	base_image/pride.fxf \
	base_image/foxpaint.fxf \
	base_image/okmpaint.fxf \
	base_image/bg.fxf \
	base_image/bg.bmp \
	base_image/launcher.fxf \
	base_image/ted.fxf \
	base_image/loadfont.fxf \
	base_image/tasks.fxf

ROM_FILES = \
	base_image/startup.bat \
	base_image/icons.res \
	base_image/kernel.fxf \
	base_image/sh.fxf \
	base_image/barclock.fxf \
	base_image/terminal.fxf \
	base_image/fetcher.fxf \
	base_image/serial.fxf \
	base_image/pride.fxf \
	base_image/bg.fxf \
	base_image/launcher.fxf \
	base_image/ted.fxf \
	base_image/loadfont.fxf \
	base_image/tasks.fxf

base_image/%.lbr: $(wildcard libraries/*/*.asm)
	cd libraries && $(MAKE)

fox32os.img: $(BOOTLOADER) $(FILES) $(wildcard libraries/*/*.asm)
	$(RYFS) -s $(IMAGE_SIZE) -l fox32os -b $(BOOTLOADER) create $@.tmp
	for file in base_image/*.lbr; do $(RYFS) add $@.tmp $$file; done
	for file in $(FILES); do $(RYFS) add $@.tmp $$file; done
	mv $@.tmp $@

romdisk.img: $(BOOTLOADER) $(ROM_FILES) $(wildcard libraries/*/*.asm)
	$(RYFS) -s $(ROM_IMAGE_SIZE) -l romdisk -b $(BOOTLOADER) create $@.tmp
	for file in base_image/*.lbr; do $(RYFS) add $@.tmp $$file; done
	for file in $(ROM_FILES); do $(RYFS) add $@.tmp $$file; done
	mv $@.tmp $@

clean:
	cd libraries && $(MAKE) clean
	rm -f $(FILES)

.PHONY: clean
