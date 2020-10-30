.PHONY: all clean help
.PHONY: u-boot kernel kernel-config
.PHONY: linux pack

include chosen_board.mk

K_CROSS_COMPILE=$(K_COMPILE_TOOL)/aarch64-linux-gnu-

ROOTFS=$(CURDIR)/rootfs/linux/default_linux_rootfs.tar.gz

Q=
J=$(shell expr `grep ^processor /proc/cpuinfo  | wc -l` \* 2)

all: bsp

clean: u-boot-clean kernel-clean
	rm -f chosen_board.mk env.sh

distclean: clean
	rm -rf SD/

pack: aml-pack
	$(Q)scripts/mk_pack.sh

install:
	$(Q)scripts/mk_install_sd.sh

u-boot: 
	$(Q)$(MAKE) -C u-boot-aml $(UBOOT_CONFIG)
	$(Q)$(MAKE) -C u-boot-aml

u-boot-clean:
	$(Q)$(MAKE) -C u-boot-aml distclean


kernel:
	$(Q)$(MAKE) -C linux-aml ARCH=$(ARCH) CROSS_COMPILE=${K_CROSS_COMPILE} $(KERNEL_CONFIG)
	$(Q)$(MAKE) -C linux-aml ARCH=$(ARCH) CROSS_COMPILE=${K_CROSS_COMPILE} -j$J
	$(Q)$(MAKE) -C linux-aml ARCH=$(ARCH) CROSS_COMPILE=${K_CROSS_COMPILE} -j$J INSTALL_MOD_PATH=output modules_install
	$(Q)scripts/install_kernel_headers.sh ${K_CROSS_COMPILE} 

kernel-clean:
	$(Q)$(MAKE) -C linux-aml ARCH=$(ARCH) -j$J distclean
	rm -rf linux-aml/output/

kernel-config: $(K_DOT_CONFIG)
	$(Q)$(MAKE) -C linux-aml ARCH=$(ARCH) $(KERNEL_CONFIG)
	$(Q)$(MAKE) -C linux-aml ARCH=$(ARCH) -j$J menuconfig
	cp linux-aml/.config linux-aml/arch/$(ARCH)/configs/$(KERNEL_CONFIG)

bsp: u-boot kernel

help:
	@echo ""
	@echo "Usage:"
	@echo "  make bsp             - Default 'make'"
	@echo "  make pack            - pack the images and rootfs to a PhenixCard download image."
	@echo "  make clean"
	@echo ""
	@echo "Optional targets:"
	@echo "  make kernel           - Builds linux kernel"
	@echo "  make kernel-config    - Menuconfig"
	@echo "  make u-boot          - Builds u-boot"
	@echo ""

