OKAMERON := ../okameron/okameron.lua
FOX32ASM := ../fox32asm/target/release/fox32asm
RYFS := $(CURDIR)/meta/ryfs/ryfs.py
GFX2INC := ../tools/gfx2inc/target/release/gfx2inc
FOX32ROMDEF := ../fox32rom/fox32rom.def.okm

IMAGE_SIZE := 16777216
ROM_IMAGE_SIZE := 65536
BOOTLOADER := bootloader/bootloader.bin

all: fox32os.img romdisk.img

KENREL_INPUT_FILES = \
	kernel/Main.okm \
	kernel/Allocator.okm \
	kernel/Process.okm \
	kernel/RYFS.okm \
	kernel/String.okm \
	kernel/VFS.okm

bootloader/bootloader.bin: bootloader/main.asm $(wildcard bootloader/*.asm)
	$(FOX32ASM) $< $@

base_image/kernel.fxf: $(KENREL_INPUT_FILES) $(wildcard kernel/*.okm kernel/*/*.okm)
	lua $(OKAMERON) -arch=fox32 -startup=kernel/start.asm $(KENREL_INPUT_FILES) $(FOX32ROMDEF) > kernel/kernel.asm
	$(FOX32ASM) kernel/kernel.asm $@
	rm kernel/kernel.asm

OUTPUT_FILES = \
	base_image/kernel.fxf

OUTPUT_ROM_FILES = \
	base_image/kernel.fxf

fox32os.img: $(BOOTLOADER) $(OUTPUT_FILES)
	$(RYFS) -s $(IMAGE_SIZE) -l fox32os -b $(BOOTLOADER) create $@.tmp
	for file in $(OUTPUT_FILES); do $(RYFS) add $@.tmp $$file; done
	mv $@.tmp $@

romdisk.img: $(BOOTLOADER) $(OUTPUT_ROM_FILES)
	$(RYFS) -s $(ROM_IMAGE_SIZE) -l romdisk -b $(BOOTLOADER) create $@.tmp
	for file in $(OUTPUT_ROM_FILES); do $(RYFS) add $@.tmp $$file; done
	mv $@.tmp $@

clean:
	rm -f $(OUTPUT_FILES)
