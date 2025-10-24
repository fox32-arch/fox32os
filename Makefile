RYFS := meta/ryfs/ryfs.py
NEWSDK := meta/jackal
JKL := $(NEWSDK)/bin/jkl.exe

ifeq ($(shell uname), Darwin)
REALPATH ?= grealpath
else
REALPATH ?= realpath
endif

IMAGE_SIZE := 16777216
ROM_IMAGE_SIZE := 196608
BOOTLOADER := bootloader/boot1.bin
BOOT_STAGE2 := bootloader/boot2.bin

FILES = \
	base_image/system/boot2.bin \
	base_image/system/startup.bat \
	base_image/system/icons.res \
	base_image/system/kernel.fxf \
	base_image/system/sh.fxf \
	base_image/system/barclock.fxf \
	base_image/system/fetcher.fxf \
	base_image/system/filer.fxf \
	base_image/system/serial.fxf \
	base_image/system/bg.fxf \
	base_image/system/format.fxf \
	base_image/system/sysdisk.fxf \
	base_image/system/ted.fxf \
	base_image/system/loadfont.fxf \
	base_image/system/tasks.fxf \
	base_image/apps/terminal.fxf \
	base_image/apps/pride.fxf \
	base_image/apps/foxpaint.fxf \
	base_image/user/bg.bmp

ROM_FILES = \
	base_image/system/boot2.bin \
	base_image/system/startup.bat \
	base_image/system/icons.res \
	base_image/system/kernel.fxf \
	base_image/system/sh.fxf \
	base_image/system/barclock.fxf \
	base_image/system/fetcher.fxf \
	base_image/system/filer.fxf \
	base_image/system/serial.fxf \
	base_image/system/bg.fxf \
	base_image/system/format.fxf \
	base_image/system/sysdisk.fxf \
	base_image/system/ted.fxf \
	base_image/system/loadfont.fxf \
	base_image/system/tasks.fxf \
	base_image/apps/pride.fxf \
	base_image/apps/terminal.fxf

all: \
	$(JKL) \
	base_image/system/library \
	base_image/system/font \
	base_image/apps \
	base_image/user \
	base_image/system/library/*.lbr \
	base_image/system/font/*.fnt \
	fox32os.img #romdisk.img

$(JKL):
	cd $(NEWSDK) && ./bootstrap.sh
	cd $(NEWSDK) && ./buildall.sh 4

base_image/system/library:
	mkdir -p base_image/system/library
base_image/system/font:
	mkdir -p base_image/system/font
base_image/apps:
	mkdir -p base_image/apps
base_image/user:
	mkdir -p base_image/user

bootloader/boot1.bin: bootloader/boot1.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@
bootloader/boot2.bin: bootloader/boot2.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@
base_image/system/boot2.bin: bootloader/boot2.bin
	cp $< $@
base_image/system/startup.bat: base_image/system/startup.bat.default
	cp $< $@

base_image/system/kernel.fxf:
	$(MAKE) -C kernel
base_image/system/%.fxf: $(wildcard applications/%/**)
	$(MAKE) -C applications/$*
base_image/system/icons.res:
	$(MAKE) -C applications/icons
base_image/system/library/%.lbr: $(wildcard libraries/*/*.asm)
	$(MAKE) -C libraries
base_image/system/font/%.fnt: $(wildcard fonts/*.asm) $(wildcard fonts/*.png)
	$(MAKE) -C fonts
base_image/apps/%.fxf: $(wildcard applications/%/**)
	$(MAKE) -C applications/$*

fox32os.img: $(BOOTLOADER) $(FILES) $(wildcard libraries/*/*.asm)
	$(RYFS) -s $(IMAGE_SIZE) -l boot -b $(BOOTLOADER) create $@.tmp
	$(RYFS) newdir $@.tmp system.dir
	$(RYFS) newdir -d system $@.tmp library.dir
	$(RYFS) newdir -d system $@.tmp font.dir
	$(RYFS) newdir $@.tmp apps.dir
	$(RYFS) newdir $@.tmp user.dir
	for file in base_image/system/library/*.lbr; do $(RYFS) add -d /system/library $@.tmp $$file; done
	for file in base_image/system/font/*.fnt; do $(RYFS) add -d /system/font $@.tmp $$file; done
	$(foreach file, $(FILES), $(RYFS) add -q -d $(patsubst %/,%,$(dir $(shell $(REALPATH) --relative-to base_image/ $(file)))) $@.tmp $(file);)
	mv $@.tmp $@

romdisk.img: $(BOOTLOADER) $(ROM_FILES) $(wildcard libraries/*/*.asm)
	$(RYFS) -s $(ROM_IMAGE_SIZE) -l romdisk -b $(BOOTLOADER) create $@.tmp
	$(RYFS) newdir $@.tmp system.dir
	$(RYFS) newdir -d system $@.tmp library.dir
	$(RYFS) newdir -d system $@.tmp font.dir
	$(RYFS) newdir $@.tmp apps.dir
	$(RYFS) newdir $@.tmp user.dir
	for file in base_image/system/library/*.lbr; do $(RYFS) add -d /system/library $@.tmp $$file; done
	$(foreach file, $(ROM_FILES), $(RYFS) add -q -d $(patsubst %/,%,$(dir $(shell $(REALPATH) --relative-to base_image/ $(file)))) $@.tmp $(file);)
	mv $@.tmp $@

clean:
	cd libraries && $(MAKE) clean
	cd fonts && $(MAKE) clean
	rm -f fox32os.img romdisk.img $(FILES)

.PHONY: clean
