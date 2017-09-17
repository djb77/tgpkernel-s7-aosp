#!/sbin/sh
#
# TGPKernel Unpack Script
# Originally written by @Morogoku
# Modified by @djb77
#

cd /tmp/tgptemp

# Extract System Files
tar -Jxf system.tar.xz

# Extract Kernels
tar -Jxf kernels.tar.xz

