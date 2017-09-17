#!/sbin/sh
# TGPKernel Flashing Script
# Originally written by @Tkkg1994

cd /tmp/tgptemp/kernels

getprop ro.boot.bootloader >> BLmodel

if grep -q G935 BLmodel; then
	cat g935x.img > /dev/block/platform/155a0000.ufs/by-name/BOOT
fi;
if grep -q G930 BLmodel; then
	cat g930x.img > /dev/block/platform/155a0000.ufs/by-name/BOOT
fi;

sync
