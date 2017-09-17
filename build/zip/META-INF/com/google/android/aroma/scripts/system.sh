#!/sbin/sh
#
# MoRoKernel System script 1.0
# Originally written by @Morogoku
# Modified by @djb77
#

cd /tmp/tgptemp

# Copy system
cp -rf system/. /system

# Patch fingerprint
rm -f /system/app/mcRegistry/ffffffffd0000000000000000000000a.tlbin

# Clean Apex data
rm -rf /data/data/com.sec.android.app.apex

# Remove init.d Placeholder
rm -f /system/etc/init.d/placeholder

