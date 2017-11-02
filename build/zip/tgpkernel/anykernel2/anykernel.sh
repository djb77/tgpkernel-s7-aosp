# -------------------------------
# TGPKERNEL AROMA INSTALLER v2.20
# anykernel2 portion
#
# Anykernel2 created by #osm0sis
# S8Port/NFE mods by @kylothow
# Kernel paths from @Morogoku
# Everything else done by @djb77
#
# DO NOT USE ANY PORTION OF THIS
# CODE WITHOUT MY PERMISSION!!
# -------------------------------

## AnyKernel setup
# Begin Properties
properties() {
kernel.string=
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=1
device.name1=herolte
device.name2=hero2lte
device.name3=
device.name4=
device.name5=
} # end properties

# Shell Variables
block=/dev/block/platform/155a0000.ufs/by-name/BOOT;
is_slot_device=0;
bb="$BB"

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel install
ui_print "- Extracing Boot Image";
dump_boot;

# Ramdisk changes - Modded / New Files
ui_print "- Adding TGPKernel Mods";
replace_file sbin/resetprop 755 mods/sbin/resetprop;
replace_file sbin/initd.sh 755 mods/sbin/initd.sh;
replace_file sbin/kernelinit.sh 755 mods/sbin/kernelinit.sh;
replace_file sbin/wakelock.sh 755 mods/sbin/wakelock.sh;
replace_file init 755 mods/init;
replace_file init.services.rc 755 mods/init.services.rc;

# Ramdisk changes - default.prop
replace_string default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";
replace_string default.prop "ro.debuggable=0" "ro.debuggable=1" "ro.debuggable=0";
replace_string default.prop "persist.sys.usb.config=mtp,adb" "persist.sys.usb.config=mtp" "persist.sys.usb.config=mtp,adb";
insert_line default.prop "persist.service.adb.enable=1" after "persist.sys.usb.config=mtp,adb" "persist.service.adb.enable=1";
insert_line default.prop "persist.adb.notify=0" after "persist.service.adb.enable=1" "persist.adb.notify=0";
insert_line default.prop "ro.securestorage.support=false" after "debug.atrace.tags.enableflags=0" "ro.securestorage.support=false";

# Ramdisk changes - fstab.samsungexynos8890
patch_fstab fstab.samsungexynos8890 /system ext4 flags "wait,verify" "wait"
patch_fstab fstab.samsungexynos8890 /data ext4 flags "wait,check,forceencrypt=footer" "wait,check,encryptable=footer"

# Ramdisk changes - fstab.samsungexynos8890.fwup
patch_fstab fstab.samsungexynos8890.fwup /system ext4 flags "wait,verify" "wait"

# Ramdisk changes - fstab.goldfish
replace_string fstab.goldfish "/dev/block/mtdblock0                                    /system             ext4      ro,noatime,barrier=1                                 wait" "/dev/block/mtdblock0                                    /system             ext4      ro,barrier=1                                         wait" "/dev/block/mtdblock0                                    /system             ext4      ro,noatime,barrier=1                                 wait";

# Ramdisk changes - fstab.ranchu
replace_string fstab.ranchu "/dev/block/vda                                          /system             ext4      ro,noatime                                           wait" "/dev/block/vda                                          /system             ext4      ro                                                   wait" "/dev/block/vda                                          /system             ext4      ro,noatime                                           wait";

# Ramdisk changes - init.rc
insert_line init.rc "import /init.services.rc" after "import /init.fac.rc" "import /init.services.rc";

# Ramdisk changes - SELinux (Fake) Enforcing Mode
if egrep -q "install=1" "/tmp/aroma/selinux.prop"; then
	ui_print "- Enabling SELinux Enforcing Mode";
	replace_string sbin/kernelinit.sh "\$BB echo \"1\" > /sys/fs/selinux/enforce" "\$BB echo \"0\" > /sys/fs/selinux/enforce" "\$BB echo \"1\" > /sys/fs/selinux/enforce";
fi;

# Ramdisk changes - Insecure ADB
if egrep -q "install=1" "/tmp/aroma/insecureadb.prop"; then
	ui_print "- Enabling Insecure ADB";
	replace_file sbin/adbd 755 adbd/adbd;
	replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
fi;

# Ramdisk changes - Spectrum
if egrep -q "install=1" "/tmp/aroma/spectrum.prop"; then
	ui_print "- Adding Spectrum";
	replace_file sbin/spa 755 spectrum/spa;
	replace_file init.spectrum.rc 644 spectrum/init.spectrum.rc;
	replace_file init.spectrum.sh 644 spectrum/init.spectrum.sh;
	insert_line init.rc "import /init.spectrum.rc" after "import /init.services.rc" "import /init.spectrum.rc";
fi;

# Ramdisk changes - PWMFix
if egrep -q "install=1" "/tmp/aroma/pwm.prop"; then
	ui_print "- Enabling PWMFix by default";
	replace_string sbin/kernelinit.sh "\$BB echo \"1\" > /sys/class/lcd/panel/smart_on" "\$BB echo \"0\" > /sys/class/lcd/panel/smart_on" "\$BB echo \"1\" > /sys/class/lcd/panel/smart_on";
fi;

# Ramdisk Advanced Options
if egrep -q "install=1" "/tmp/aroma/advanced.prop"; then

# Ramdisk changes for CPU Governors (Big)
	sed -i -- "s/governor-big=//g" /tmp/aroma/governor-big.prop
	GOVERNOR_BIG=`cat /tmp/aroma/governor-big.prop`
	if [[ "$GOVERNOR_BIG" != "interactive" ]]; then
		ui_print "- Setting CPU Big Freq Governor to $GOVERNOR_BIG";
		insert_line sbin/kernelinit.sh "\$BB echo $GOVERNOR_BIG > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor" after "# Customisations" "\$BB echo $GOVERNOR_BIG > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor";
	fi

# Ramdisk changes for CPU Governors (Little)
	sed -i -- "s/governor-little=//g" /tmp/aroma/governor-little.prop
	GOVERNOR_LITTLE=`cat /tmp/aroma/governor-little.prop`
	if [[ "$GOVERNOR_LITTLE" != "interactive" ]]; then
		ui_print "- Setting CPU Little Freq Governor to $GOVERNOR_LITTLE";
		insert_line sbin/kernelinit.sh "\$BB echo $GOVERNOR_LITTLE > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" after "# Customisations" "\$BB echo $GOVERNOR_LITTLE > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor";
	fi

# Ramdisk changes for IO Schedulers (Internal)
	sed -i -- "s/scheduler-internal=//g" /tmp/aroma/scheduler-internal.prop
	SCHEDULER_INTERNAL=`cat /tmp/aroma/scheduler-internal.prop`
	if [[ "$SCHEDULER_INTERNAL" != "cfq" ]]; then
		ui_print "- Setting Internal IO Scheduler to $SCHEDULER_INTERNAL";
		insert_line sbin/kernelinit.sh "\$BB echo $SCHEDULER_INTERNAL > /sys/block/sda/queue/scheduler" after "# Customisations" "\$BB echo $SCHEDULER_INTERNAL > /sys/block/sda/queue/scheduler";
	fi

# Ramdisk changes for IO Schedulers (External)
	sed -i -- "s/scheduler-external=//g" /tmp/aroma/scheduler-external.prop
	SCHEDULER_EXTERNAL=`cat /tmp/aroma/scheduler-external.prop`
	if [[ "$SCHEDULER_EXTERNAL" != "cfq" ]]; then
		ui_print "- Setting External IO Scheduler to $SCHEDULER_EXTERNAL";
		insert_line sbin/kernelinit.sh "\$BB echo $SCHEDULER_EXTERNAL > /sys/block/mmcblk0/queue/scheduler" after "# Customisations" "\$BB echo $SCHEDULER_EXTERNAL > /sys/block/mmcblk0/queue/scheduler";
	fi

# Ramdisk changes for TCP Congestion Algorithms
	sed -i -- "s/tcp=//g" /tmp/aroma/tcp.prop
	TCP=`cat /tmp/aroma/tcp.prop`
	if [[ "$TCP" != "bic" ]]; then
		ui_print "- Setting TCP Congestion Algorithm to $TCP";
		insert_line sbin/kernelinit.sh "\$BB echo $TCP > /proc/sys/net/ipv4/tcp_congestion_control" after "# Customisations" "\$BB echo $TCP > /proc/sys/net/ipv4/tcp_congestion_control";
	fi

fi

# End ramdisk changes
ui_print "- Writing Boot Image";
write_boot;

## End install

