#!/bin/bash

set -e

mkdir -p base_image

# if fox32os.img doesn't exist, then create it
if [ ! -f fox32os.img ]; then
    echo "fox32os.img not found, creating it"
    meta/ryfs/ryfs.py -s 16777216 -l fox32os create fox32os.img
fi

echo "assembling kernel"
../fox32asm/target/release/fox32asm kernel/main.asm base_image/system.bin

echo "assembling launcher"
../fox32asm/target/release/fox32asm launcher/main.asm base_image/launcher.fxf

echo "creating wallpapr.raw"
../tools/gfx2inc/target/release/gfx2inc 640 480 launcher/wallpaper.png launcher/wallpaper.inc
../fox32asm/target/release/fox32asm launcher/wallpaper.inc base_image/wallpapr.raw

echo "adding files to fox32os.img"
cd base_image
for file in ./*; do
    ../meta/ryfs/ryfs.py add ../fox32os.img $file
done
