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
	cp -a ${PACK}/${MACH}/common/linux/uInitrd ${dest_path}/
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

	(cd $BOOT ; tar czvf ${TOPDIR}/SD/${BOARD}/BPI-BOOT-${BOARD}.tgz .) 2>&1 > /dev/null
	(cd $ROOT ; tar czvf ${TOPDIR}/SD/${BOARD}/${KERNEL_MODULES}-Kernel.tgz lib/modules) 2>&1 > /dev/null
	(cd $ROOT ; tar czvf ${TOPDIR}/SD/${BOARD}/${KERNEL_HEADERS}-Kernel.tgz usr/src/${KERNEL_HEADERS}) 2>&1 > /dev/null
	(cd $ROOT ; tar czvf ${TOPDIR}/SD/${BOARD}/BOOTLOADER-${BOARD}.tgz usr/lib/u-boot/bananapi) 2>&1 > /dev/null
}

pack_deb()
{
	echo "pack bsp deb"
	local pkgname=${BOARD}-bsp
	local pkgdir=/tmp/${pkgname}-deb
	local version=`date +"%Y%m%d"`

	rm -rf ${TOPDIR}/SD/${BOARD}-bsp*.deb
	rm -rf $pkgdir
	mkdir -p ${pkgdir}/DEBIAN
	cp -a ${TOPDIR}/SD/${BOARD}/BPI-ROOT/* ${pkgdir}/
	cp -a ${TOPDIR}/SD/${BOARD}/BPI-BOOT ${pkgdir}/boot

	# control file
	cat <<-EOF > ${pkgdir}/DEBIAN/control
	Package: $pkgname
	Version: ${version}-1
	Section: kernel
	Architecture: $ARCH
	Maintainer: BPI
	Installed-Size: 1
	Priority: optional
	Depends: bash
	Description: Bananapi bsp
	EOF

	# pre install script
	cat <<-EOF > ${pkgdir}/DEBIAN/preinst
	#!/bin/bash

	del_boot() {
		boot_device=\$(mountpoint -d /boot)

		for file in /dev/* ; do
			CURRENT_DEVICE=\$(printf "%d:%d" \$(stat --printf="0x%t 0x%T" \$file))
			if [[ "\$CURRENT_DEVICE" = "\$boot_device" ]]; then
				boot_partition=\$file
				break
			fi
		done

		bootfstype=\$(blkid -s TYPE -o value \$boot_partition)
		if [ "\$bootfstype" = "vfat" ]; then
			rm -rf /boot/*
		fi
	}

	# del current boot files
	mountpoint -q /boot && del_boot

	# del current root files
	rm -rf /lib/modules/*-BPI-M5
	rm -rf /usr/src/*-BPI-M5
	rm -rf /usr/lib/u-boot/bananapi/${BOARD}/${BOARD}-512b.img.gz

	EOF

	chmod 755 $pkgdir/DEBIAN/preinst

	# post install script
	cat <<-EOF > ${pkgdir}/DEBIAN/postinst
	#!/bin/bash

	# install bootloader
	rootpart=\$(df -P / | tail -n 1 | awk '/.*/ { print \$1 }')
	dev=\$(lsblk -n -o PKNAME \$rootpart)
	bootloader=/usr/lib/u-boot/bananapi/${BOARD}/${BOARD}-512b.img.gz
	if [ -f \$bootloader ]; then
		gunzip -c \${bootloader} | dd of=/dev/\${dev} bs=512 seek=1
	fi

	EOF

	chmod 755 $pkgdir/DEBIAN/postinst

	fakeroot dpkg-deb -b $pkgdir ${TOPDIR}/SD/${BOARD}
}

pack_bootloader
pack_boot
pack_root
tar_packages
pack_deb

echo "pack finish"

ls -l SD/${BOARD}/*.tgz
