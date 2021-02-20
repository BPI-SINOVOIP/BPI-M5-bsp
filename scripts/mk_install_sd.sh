#!/bin/bash

DEVICE=
VARIANT=
BOARD=
TARGET=

echo "--------------------------------------------------------------------------------"
echo "  1. M5/M2Pro"
echo "  2. C4"
echo "--------------------------------------------------------------------------------"

read -p "Please choose a target to install(1-2): " board
echo

if [ -z "${board}" ]; then
	echo -e "\033[31mNo install target choose \033[0m"
	exit 1
fi

case ${board} in
	1) BOARD="m5";;
	2) BOARD="c4";;
esac

TARGET=SD/bpi-${BOARD}

if [ ! -d ${TARGET} ]; then
	echo -e "\033[31mtarget install files does not exist, please check the build. \033[0m"
	exit 1
fi

read -p "Please type the SD device(/dev/sdX): " DEVICE
echo

if [ ! -b ${DEVICE} ]; then
	echo -e "\033[31mNo SD device exists \033[0m"
	exit 1
fi

read -p  "${VARIANT} type will be intalled to ${DEVICE}, [Y/n] " input
echo

case ${input} in
	[yY]) echo "Yes";;
	[nN]) echo "No, stop install";;
	*)
	  echo -e "\033[31mInvalid input \033[0m"
	  exit 1
	  ;;
esac

echo

BOOTLOADER=${TARGET}/100MB/bpi-${BOARD}-512b.img.gz

## download bootloader
if [ ! -f ${BOOTLOADER} ]; then
	echo -e "\033[31mbootloader download file not exist, please check you build. \033[0m"
	exit 1
fi

echo "sudo gunzip -c ${BOOTLOADER} | dd of=${DEVICE} bs=512 seek=1"
sudo gunzip -c ${BOOTLOADER} | sudo dd of=${DEVICE} bs=512 seek=1
sync
echo
echo "bootloader download finished"
echo

## boot and root
cd ${TARGET}
if command -v bpi-update > /dev/null 2>&1; then
	sudo bpi-update -d ${DEVICE}
else
	cd -
	echo -e "\033[31mbpi-update command not exists, please install it before run this script, more reference to https://github.com/BPI-SINOVOIP/bpi-tools \033[0m"
	exit 1
fi
cd -

## end

