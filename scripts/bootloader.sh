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

IMG_FILE=/tmp/${BOARD}-512b.img

UBOOT=$TOPDIR/u-boot-aml/sd_fuse/u-boot.bin
if [ ! -e "$UBOOT" ]; then
	echo -e "\033[31m u-boot.bin not exit, please build u-boot before pack\033[0m"
	exit 1
fi

if [ -f ${IMG_FILE}.gz ]; then
	rm -f ${IMG_FILE}.gz
fi

cp ${UBOOT} ${IMG_FILE}
echo "gzip ${IMG_FILE}"
gzip ${IMG_FILE}
sudo rm -f ${TMP_FILE}
