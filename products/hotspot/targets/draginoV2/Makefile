
# (C) 2013 CarrierWrt.org

#
# Target: draginoV2
#

define Target/draginoV2

	CONFIG += \
		CONFIG_TARGET_ar71xx=y \
		CONFIG_TARGET_ar71xx_generic=y \
		CONFIG_TARGET_ar71xx_generic_DRAGINO2=y \
		CONFIG_TARGET_ROOTFS_JFFS2=n \
		CONFIG_PACKAGE_uboot-ar71xx-nbg460n_550n_550nh=y \
		CONFIG_PACKAGE_kmod-usb-storage=y \
		CONFIG_PACKAGE_kmod-fs-ext4=y \
		CONFIG_PACKAGE_block-mount=y \
		CONFIG_PACKAGE_e2fsprogs=y \
		CONFIG_PACKAGE_usb-modeswitch=y \
		CONFIG_PACKAGE_usb-modeswitch-data=y \
		CONFIG_PACKAGE_draginoV2=y

	IMAGES := \
		ar71xx/openwrt-ar71xx-generic-dragino2-kernel.bin \
		ar71xx/openwrt-ar71xx-generic-dragino2-rootfs-squashfs.bin \
		ar71xx/openwrt-ar71xx-generic-dragino2-squashfs-sysupgrade.bin

endef
