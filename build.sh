#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by djb77 / XDA Developers

# ---------
# VARIABLES
# ---------
BUILD_SCRIPT=3.30
export VERSION_NUMBER=$(<build/version)
export ANDROIDVERSION=$(<build/variant)
ARCH=arm64
BUILD_CROSS_COMPILE=~/android/toolchains/aarch64-cortex_a53-linux-gnueabi/bin/aarch64-cortex_a53-linux-gnueabi-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
RDIR=$(pwd)
WORKDIR=$RDIR/.work
ZIPDIR=$RDIR/.work_zip
OUTDIR=$WORKDIR/arch/$ARCH/boot
DTSDIR=$WORKDIR/arch/$ARCH/boot/dts
DTBDIR=$WORKDIR/arch/$ARCH/boot/dtb
DTCTOOL=$WORKDIR/scripts/dtc/dtc
INCDIR=$WORKDIR/include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELNAME=TGPKernel
export KERNELTITLE=$KERNELNAME.$ANDROIDVERSION.$VERSION_NUMBER
KERNELCONFIG=tgpkernel
OUTPUT=$RDIR/output

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{
echo ""
echo "Deleting old work files ..."
echo ""
[ -d "$WORKDIR" ] && rm -rf $WORKDIR
[ -f "$OUTPUT/build.log" ] && rm -f $OUTPUT/build.log
}

FUNC_BUILD_ZIMAGE()
{
echo "Copying Files ..."
echo ""
mkdir -p $WORKDIR/arch
mkdir -p $WORKDIR/firmware
mkdir -p $WORKDIR/include
mkdir -p $WORKDIR/ramdisk
mkdir -p $WORKDIR/scripts
cp -rf $RDIR/arch/arm/ $WORKDIR/arch/
cp -rf $RDIR/arch/arm64/ $WORKDIR/arch/
cp -rf $RDIR/arch/x86 $WORKDIR/arch/
cp -rf $RDIR/firmware $WORKDIR/
cp -rf $RDIR/include $WORKDIR/
cp -rf $RDIR/build/ramdisk $WORKDIR/
cp -rf $RDIR/build/aik/* $WORKDIR/ramdisk 
cp -rf $RDIR/scripts $WORKDIR/
cd $WORKDIR
find . -name \.placeholder -type f -delete
cd ..
echo "Loading configuration ..."
echo ""
make -C $RDIR O=.work -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	$KERNEL_DEFCONFIG || exit -1
echo ""
echo "Compiling zImage ..."
echo ""
make -C $RDIR O=.work -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
echo ""
}

FUNC_BUILD_DTB()
{
[ -f "$DTCTOOL" ] || {
	echo "You need to run ./build.sh first!"
	exit 1
}
case $MODEL in
herolte)
	DTSFILES="exynos8890-herolte_eur_open_00 exynos8890-herolte_eur_open_01
		exynos8890-herolte_eur_open_02 exynos8890-herolte_eur_open_03
		exynos8890-herolte_eur_open_04 exynos8890-herolte_eur_open_08
		exynos8890-herolte_eur_open_09"
	;;
hero2lte)
	DTSFILES="exynos8890-hero2lte_eur_open_00 exynos8890-hero2lte_eur_open_01
		exynos8890-hero2lte_eur_open_03 exynos8890-hero2lte_eur_open_04
		exynos8890-hero2lte_eur_open_08"
	;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac
mkdir -p $OUTDIR $DTBDIR
cd $DTBDIR || {
	echo "Unable to cd to $DTBDIR!"
	exit 1
}
rm -f ./*
echo ""
echo "Processing DTS files ..."
echo ""
for dts in $DTSFILES; do
	echo "Processing: ${dts}.dts"
	${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
	echo "Generating: ${dts}.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
done
echo ""
echo "Generating dtb.img"
echo ""
$WORKDIR/scripts/dtbTool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
}

FUNC_BUILD_RAMDISK()
{
mkdir $WORKDIR/ramdisk/ramdisk/config
chmod 500 $WORKDIR/ramdisk/ramdisk/config
mv $WORKDIR/arch/$ARCH/boot/Image $WORKDIR/ramdisk/split_img/boot.img-zImage
mv $WORKDIR/arch/$ARCH/boot/dtb.img $WORKDIR/ramdisk/split_img/boot.img-dtb
case $MODEL in
herolte)
	sed -i -- 's/hero2/hero/g' $WORKDIR/ramdisk/ramdisk/property_contexts
	sed -i -- 's/hero2/hero/g' $WORKDIR/ramdisk/ramdisk/service_contexts
	cd $WORKDIR/ramdisk
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
hero2lte)
	cd $WORKDIR/ramdisk
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac
}

FUNC_BUILD_BOOTIMG()
{
	FUNC_CLEAN
	[ ! -d "$OUTPUT" ] && mkdir output
	(
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_DTB
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a $OUTPUT/build.log
}

FUNC_BUILD_ZIP()
{
echo ""

cd $ZIPDIR/tgpkernel/anykernel2
rm -f .git.zip

echo "Building anykernel2.zip File ..."
zip -9gq anykernel2.zip -r * -x "*~"

cd $ZIPDIR/tgpkernel

echo "Building system.tar.xz File ..."
tar -cf - system/ | xz -9 -c - > system.tar.xz 

echo "Building kernels.tar.xz File ..."
tar -cf - kernels/ | xz -9 -c - > kernels.tar.xz 

echo "Moving .tar.xz Files ..."
mv -f $ZIPDIR/tgpkernel/system.tar.xz $ZIPDIR/tgpkernel/files/system.tar.xz
mv -f $ZIPDIR/tgpkernel/kernels.tar.xz $ZIPDIR/tgpkernel/files/kernels.tar.xz

echo "Cleaning up ..."
cd $ZIPDIR/tgpkernel/anykernel2
rm -rf META-INF tgpkernel patch tools anykernel.sh
rm -rf $ZIPDIR/tgpkernel/system
rm -rf $ZIPDIR/tgpkernel/kernels

echo "Building Zip File ..."
cd $ZIPDIR
zip -9gq $ZIP_NAME -r META-INF/ -x "*~"
zip -9gq $ZIP_NAME -r tgpkernel/ -x "*~" 
if [ -n `which java` ]; then
	echo "Java Detected, Signing Zip File ..."
	mv $ZIP_NAME old$ZIP_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 old$ZIP_NAME $ZIP_NAME
	rm old$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $OUTPUT/$ZIP_NAME
cd $RDIR
}

OPTION_1()
{
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $OUTPUT/boot.img
mv -f $OUTPUT/build.log $OUTPUT/build-g930x.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the output folder"
echo "You can now find your build-g930x.log file in the output folder"
echo ""
exit
}

OPTION_2()
{
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $OUTPUT/boot.img
mv -f $OUTPUT/build.log $OUTPUT/build-g935x.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the output folder"
echo "You can now find your build-g935x.log file in the output folder"
echo ""
exit
}

OPTION_3()
{
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $OUTPUT/g930x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g930x.log
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $OUTPUT/g935x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g935x.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your g930x.img in the output folder"
echo "You can now find your g935x.img in the output folder"
echo "You can now find your build-g930x.log file in the output folder"
echo "You can now find your build-g935x.log file in the output folder"
echo ""
exit
}

OPTION_4()
{
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ ! -d "$ZIPDIR" ] && mkdir $ZIPDIR
cp -rf $RDIR/build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/files
mkdir -p $ZIPDIR/tgpkernel/kernels
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/g930x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g930x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G930x.$ANDROIDVERSION.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the output folder"
echo "You can now find your build-g930x.log file in the output folder"
echo ""
exit
}

OPTION_5()
{
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ ! -d "$ZIPDIR" ] && mkdir $ZIPDIR
cp -rf $RDIR/build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/files
mkdir -p $ZIPDIR/tgpkernel/kernels
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/g935x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g935x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G935x.$ANDROIDVERSION.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the output folder"
echo "You can now find your build-g935x.log file in the output folder"
echo ""
exit
}

OPTION_6()
{
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ ! -d "$ZIPDIR" ] && mkdir $ZIPDIR
cp -rf $RDIR/build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/files
mkdir -p $ZIPDIR/tgpkernel/kernels
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/g930x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g930x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G930x.$ANDROIDVERSION.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
rm -rf $ZIPDIR
[ ! -d "$ZIPDIR" ] && mkdir $ZIPDIR
cp -rf $RDIR/build/zip/* $ZIPDIR
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/g935x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g935x.log
ZIP_NAME=$KERNELNAME.G935x.$ANDROIDVERSION.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip files in the output folder"
echo "You can now find your build-g930x.log file in the output folder"
echo "You can now find your build-g935x.log file in the output folder"
echo ""
exit
}

OPTION_7()
{
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
[ ! -d "$ZIPDIR" ] && mkdir $ZIPDIR
cp -rf $RDIR/build/zip/* $ZIPDIR
mkdir -p $ZIPDIR/tgpkernel/files
mkdir -p $ZIPDIR/tgpkernel/kernels
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/g930x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g930x.log
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $OUTPUT/build.log
mv -f $WORKDIR/ramdisk/image-new.img $ZIPDIR/tgpkernel/kernels/g935x.img
mv -f $OUTPUT/build.log $OUTPUT/build-g935x.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G93xx.$ANDROIDVERSION.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIPDIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$ZIPDIR" ] && rm -rf $ZIPDIR
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the output folder"
echo "You can now find your build-g930x.log file in the output folder"
echo "You can now find your build-g935x.log file in the output folder"
echo ""
exit
}

OPTION_0()
{
FUNC_CLEAN
exit
}

OPTION_00()
{
ccache -C
exit
}

# ----------------------------------
# CHECK COMMAND LINE FOR ANY ENTRIES
# ----------------------------------
if [ $1 == 0 ]; then
	OPTION_0
fi
if [ $1 == 00 ]; then
	OPTION_00
fi
if [ $1 == 1 ]; then
	OPTION_1
fi
if [ $1 == 2 ]; then
	OPTION_2
fi
if [ $1 == 3 ]; then
	OPTION_3
fi
if [ $1 == 4 ]; then
	OPTION_4
fi
if [ $1 == 5 ]; then
	OPTION_5
fi
if [ $1 == 6 ]; then
	OPTION_6
fi
if [ $1 == 7 ]; then
	OPTION_7
fi

# -------------
# PROGRAM START
# -------------
clear
echo "TGPKernel S7 Build Script v$BUILD_SCRIPT -- Kernel Version: v$VERSION_NUMBER"
echo ""
echo " 0) Clean Workspace"
echo "00) Clean CCACHE"
echo ""
echo " 1) Build TGPKernel boot.img for S7"
echo " 2) Build TGPKernel boot.img for S7 Edge"
echo " 3) Build TGPKernel boot.img for S7 + S7 Edge"
echo " 4) Build TGPKernel boot.img and .zip for S7"
echo " 5) Build TGPKernel boot.img and .zip for S7 Edge"
echo " 6) Build TGPKernel boot.img and .zip for S7 + S7 Edge (Seperate)"
echo " 7) Build TGPKernel boot.img and .zip for S7 + S7 Edge (All-In-One)"
echo ""
echo " 9) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "0" ]; then
	OPTION_0
elif [ $prompt == "00" ]; then
	OPTION_00
elif [ $prompt == "1" ]; then
	OPTION_1
elif [ $prompt == "2" ]; then
	OPTION_2
elif [ $prompt == "3" ]; then
	OPTION_3
elif [ $prompt == "4" ]; then
	OPTION_4
elif [ $prompt == "5" ]; then
	OPTION_5
elif [ $prompt == "6" ]; then
	OPTION_6
elif [ $prompt == "7" ]; then
	OPTION_7
elif [ $prompt == "9" ]; then
	exit
fi

