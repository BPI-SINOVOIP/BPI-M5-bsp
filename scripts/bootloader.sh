#!/bin/bash

die() {
        echo "$*" >&2
        exit 1
}

[ -s "./env.sh" ] || die "please run ./configure first."

. ./env.sh

O=$1
if [ ! -z $O ] ; then
	BOARD=$O
fi

TMP_FILE=/tmp/${BOARD}.tmp
IMG_FILE=/tmp/${BOARD}-512b.img

UBOOT=$TOPDIR/u-boot-aml/sd_fuse/u-boot.bin
if [ ! -e "$UBOOT" ]; then
	echo -e "\033[31m u-boot.bin not exit, please build u-boot before pack\033[0m"
	exit 1
fi

(sudo dd if=/dev/zero of=${TMP_FILE} bs=1M count=1) >/dev/null 2>&1
LOOP_DEV=`sudo losetup -f --show ${TMP_FILE}`
(sudo dd if=$UBOOT of=${LOOP_DEV} bs=512 seek=1) >/dev/null 2>&1
sudo sync
sudo losetup -d ${LOOP_DEV}
(dd if=${TMP_FILE} of=${IMG_FILE} bs=512 skip=1 count=2047 status=noxfer) >/dev/null 2>&1

if [ -f ${IMG_FILE}.gz ]; then
	rm -f ${IMG_FILE}.gz
fi

echo "gzip ${IMG_FILE}"
gzip ${IMG_FILE}
sudo rm -f ${TMP_FILE}
