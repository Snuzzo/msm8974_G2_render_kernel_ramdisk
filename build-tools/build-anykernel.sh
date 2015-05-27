#!/bin/bash
BUILD_TOP=$PWD
#
#  Build Script for Render Kernel for OPO!
#  Based off AK'sbuild script - Thanks!
#

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="zImage"
DTBIMAGE="dtb"

# Kernel Details
VER=Render-Kernel

# Vars
export LOCALVERSION=~`echo $VER`
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=RenderBroken
export KBUILD_BUILD_HOST=RenderServer.net
export CCACHE=ccache
export CROSS_COMPILE=$BUILD_TOP/toolchains/arm-cortex_a15-linux-gnueabihf-linaro_4.9/bin/arm-cortex_a15-linux-gnueabihf-


# Paths
KERNEL_DIR=$BUILD_TOP/source
REPACK_DIR=$BUILD_TOP/out/g2/ozip
ZIMAGE_DIR=$BUILD_TOP/source/arch/arm/boot
OUT_DIR=$BUILD_TOP/zips/g2-zips
buildtools=$BUILD_TOP/ramdisk/build-tools
MODULES_DIR=$REPACK_DIR/system/lib/modules


function lunch(){
mkdir -p $MODULES_DIR
cp -r $buildtools/ozip/* $REPACK_DIR
echo "Pick variant..."
select choice in d800 d801 d802 d803 ls980 vs980 f320x l01f
do
case "$choice" in
	"d800")
		variant="d800"
		config="d800_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/d800.lz4
		break;;
	"d801")
		variant="d801"
		config="d801_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/d801.lz4
		break;;
	"d802")
		variant="d802"
		config="d802_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/d802.lz4
		break;;
	"d803")
		variant="d803"
		config="d803_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/d803.lz4
		break;;
	"ls980")
		variant="ls980"
		config="ls980_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/ls980.lz4
		break;;
	"vs980")
		variant="vs980"
		config="vs980_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/vs980.lz4
		break;;
	"f320x")
		variant="f320x"
		config="f320x_defconfig"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk/f320x.lz4
		break;;
	"l01f")
		variant="l01f"
		config="l01f_defconfig"
#		ramdisk=$BUILD_TOP/ramdisk/ramdisk/f320x.lz4
		break;;
esac
done

echo "Panel variant..."
select panel in lgd jdi
do
case "$panel" in
	"lgd")
		cmdline="console=ttyHSL0,115200,n8 androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_lgd_cmd androidboot.selinux=permissive"
		break;;
	"jdi")
		cmdline="console=ttyHSL0,115200,n8 androidboot.hardware=g2 user_debug=31 msm_rtb.filter=0x0 mdss_mdp.panel=1:dsi:0:qcom,mdss_dsi_g2_jdi_cmd androidboot.selinux=permissive"
		break;;
esac
done

echo "Pick target..."
select target in lg aosp
do
case "$target" in
	"lg")
		# Already set
		rdflag=1
		rom="LG"
		break;;
	"aosp")
		rdflag=2
		rom="LP"
		ramdisk=$BUILD_TOP/ramdisk/ramdisk_android_L
		break;;
esac
done
}

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		cd $ZIP_MOVE
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
		cd $BUILD_TOP
}

function make_kernel {
		cd $KERNEL_DIR
		make $config > /dev/null
		time make $THREAD > /dev/null
		cp -vr $ZIMAGE_DIR/zImage $BUILD_TOP/out/g2/ozip/
}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$buildtools/dtbTool -s 2048 -o $BUILD_TOP/out/g2/dt.img $BUILD_TOP/source/arch/arm/boot/
}

function make_zip {
		cd $REPACK_DIR
		zip -r9 RenderKernel-CM12_"$variant"-R.zip *
		mv RenderKernel-CM12_"$variant"-R.zip $OUT_DIR
		cd $OUT_DIR
		md5sum RenderKernel-CM12_"$variant"-R.zip > RenderKernel-CM12_"$variant"-R.zip.md5
		cd $BUILD_TOP
}


DATE_START=$(date +"%s")

echo -e "${green}"
echo "Render Kernel Creation Script:"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		lunch
		make_kernel
		make_dtb
		make_modules
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
