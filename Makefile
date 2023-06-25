RYFS := $(CURDIR)/meta/ryfs/ryfs.py
FOX32ASM := ../fox32asm/target/release/fox32asm
OKAMERON := $(CURDIR)/meta/okameron/okameron.lua
GFX2INC := ../tools/gfx2inc/target/release/gfx2inc

IMAGE_SIZE := 16777216
ROM_IMAGE_SIZE := 65536
BOOTLOADER := bootloader/bootloader.bin

all: fox32os.img romdisk.img

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

base_image/serial.fxf: applications/serial/main.asm $(wildcard applications/terminal/*.asm)
	$(FOX32ASM) $< $@

base_image/foxpaint.fxf: applications/foxpaint/main.asm
	$(FOX32ASM) $< $@

base_image/okmpaint.fxf: applications/okmpaint/OkmPaint.okm $(wildcard applications/okmpaint/*.okm)
	lua $(OKAMERON) -arch=fox32 -startup=applications/okmpaint/start.asm $< > applications/okmpaint/okmpaint.asm
	$(FOX32ASM) applications/okmpaint/okmpaint.asm $@
	rm applications/okmpaint/okmpaint.asm

base_image/bg.fxf: applications/bg/main.asm
	$(FOX32ASM) $< $@

base_image/bg.raw: applications/bg/bg.inc
	$(FOX32ASM) $< $@

applications/bg/bg.inc: applications/bg/bg.png
	$(GFX2INC) 640 480 $< $@

base_image/launcher.fxf: applications/launcher/main.asm $(wildcard applications/launcher/*.asm) applications/launcher/icons.inc
	$(FOX32ASM) $< $@

applications/launcher/icons.inc: applications/launcher/icons.png
	$(GFX2INC) 16 16 $< $@

bootloader/bootloader.bin: bootloader/main.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@

base_image/startup.cfg: base_image/startup.cfg.default
	cp $< $@

FILES = \
	base_image/startup.cfg \
	base_image/kernel.fxf \
	base_image/sh.fxf \
	base_image/barclock.fxf \
	base_image/terminal.fxf \
	base_image/serial.fxf \
	base_image/foxpaint.fxf \
	base_image/okmpaint.fxf \
	base_image/bg.fxf \
	base_image/bg.raw \
	base_image/launcher.fxf

ROM_FILES = \
	base_image/startup.cfg \
	base_image/kernel.fxf \
	base_image/sh.fxf \
	base_image/barclock.fxf \
	base_image/terminal.fxf \
	base_image/serial.fxf \
	base_image/bg.fxf \
	base_image/launcher.fxf

fox32os.img: $(BOOTLOADER) $(FILES)
	$(RYFS) -s $(IMAGE_SIZE) -l fox32os -b $(BOOTLOADER) create $@.tmp
	for file in $(FILES); do $(RYFS) add $@.tmp $$file; done
	mv $@.tmp $@

romdisk.img: $(BOOTLOADER) $(ROM_FILES)
	$(RYFS) -s $(ROM_IMAGE_SIZE) -l romdisk -b $(BOOTLOADER) create $@.tmp
	for file in $(ROM_FILES); do $(RYFS) add $@.tmp $$file; done
	mv $@.tmp $@

clean:
	rm -f $(FILES)
