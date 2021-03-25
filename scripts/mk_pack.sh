#!/bin/bash

die() {
        echo "$*" >&2
        exit 1
}

[ -s "./env.sh" ] || die "please run ./configure first."

set -e

. ./env.sh

echo "pack $BOARD"

BOOTLOADER=${TOPDIR}/SD/${BOARD}/100MB
BOOT=${TOPDIR}/SD/${BOARD}/BPI-BOOT
ROOT=${TOPDIR}/SD/${BOARD}/BPI-ROOT
PLATFORM=linux

PACK=${TOPDIR}/aml-pack
KERN_DIR=${TOPDIR}/linux-aml

if [ -d ${TOPDIR}/SD ]; then
	rm -rf ${TOPDIR}/SD
fi

mkdir -p $BOOTLOADER
mkdir -p $BOOT
mkdir -p $ROOT

pack_bootloader()
{
	echo "pack bootlader"

	${TOPDIR}/scripts/bootloader.sh $BOARD

	cp /tmp/${BOARD}-512b.img.gz ${BOOTLOADER}/
}

pack_boot()
{
	echo "pack boot"

	dest_path=${BOOT}

	mkdir -p $dest_path
	mkdir -p $dest_path/overlays
	cp -a ${PACK}/${MACH}/common/linux/* ${dest_path}/
	cp -a ${PACK}/${MACH}/${BOARD}/linux/* ${dest_path}/
	cp -a ${KERN_DIR}/arch/${ARCH}/boot/Image.gz ${dest_path}/
	cp -a ${KERN_DIR}/arch/${ARCH}/boot/dts/amlogic/${KERNEL_DTB} ${dest_path}/
	cp -a ${KERN_DIR}/arch/${ARCH}/boot/dts/amlogic/overlays/${BOARD}/*.dtbo ${dest_path}/overlays/
}

pack_root()
{
	echo "pack root"

	# bootloader files
	bootloader_path=${ROOT}/usr/lib/u-boot/bananapi/${BOARD}

	mkdir -p $bootloader_path
	cp -a ${BOOTLOADER}/${BOARD}*.gz ${bootloader_path}/

	# kernel modules files
	modules_path=${ROOT}/lib/modules
	mkdir -p $modules_path
	cp -a ${KERN_DIR}/output/lib/modules/${KERNEL_MODULES} ${modules_path}/

	# kernel headers files
	headers_path=${ROOT}/usr/src/
	mkdir -p $headers_path
	cp -a ${KERN_DIR}/output/usr/src/${KERNEL_HEADERS} ${headers_path}/
}

tar_packages()
{
	echo "tar download packages"

	(cd $BOOT ; tar czvf ${TOPDIR}/SD/${BOARD}/BPI-BOOT-${BOARD}.tgz .)
	(cd $ROOT ; tar czvf ${TOPDIR}/SD/${BOARD}/${KERNEL_MODULES}-Kernel.tgz lib/modules)
	(cd $ROOT ; tar czvf ${TOPDIR}/SD/${BOARD}/${KERNEL_HEADERS}-Kernel.tgz usr/src/${KERNEL_HEADERS})
	(cd $ROOT ; tar czvf ${TOPDIR}/SD/${BOARD}/BOOTLOADER-${BOARD}.tgz usr/lib/u-boot/bananapi)
}

pack_bootloader
pack_boot
pack_root
tar_packages

echo "pack finish"
