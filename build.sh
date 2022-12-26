#!/usr/bin/env bash

set -e

mkdir -p base_image

# if fox32os.img doesn't exist, then create it
if [ ! -f fox32os.img ]; then
    echo "fox32os.img not found, creating it"

    echo "assembling bootloader"
    ../fox32asm/target/release/fox32asm bootloader/main.asm bootloader/bootloader.bin

    meta/ryfs/ryfs.py -s 16777216 -l fox32os -b bootloader/bootloader.bin create fox32os.img

    rm bootloader/bootloader.bin
fi

echo "assembling kernel"
../fox32asm/target/release/fox32asm kernel/main.asm base_image/kernel.fxf

echo "assembling launcher"
../fox32asm/target/release/fox32asm launcher/main.asm base_image/launcher.fxf

echo "assembling barclock"
../fox32asm/target/release/fox32asm barclock/main.asm base_image/barclock.fxf

echo "assembling terminal"
../fox32asm/target/release/fox32asm terminal/main.asm base_image/terminal.fxf

echo "assembling bg"
../fox32asm/target/release/fox32asm bg/main.asm base_image/bg.fxf

echo "creating bg.raw"
../tools/gfx2inc/target/release/gfx2inc 640 480 bg/bg.png bg/bg.inc
../fox32asm/target/release/fox32asm bg/bg.inc base_image/bg.raw

echo "adding files to fox32os.img"
cd base_image
for file in ./*; do
    ../meta/ryfs/ryfs.py add ../fox32os.img $file
done
