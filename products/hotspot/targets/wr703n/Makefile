
# (C) 2013 CarrierWrt.org

#
# Target: wr703n
#

define Target/wr703n

	CONFIG += \
		CONFIG_TARGET_ar71xx=y \
		CONFIG_TARGET_ar71xx_generic_TLWR703=y \
		CONFIG_TARGET_ROOTFS_JFFS2=n \
		CONFIG_PACKAGE_kmod-usb-storage=y \
		CONFIG_PACKAGE_kmod-fs-ext4=y \
		CONFIG_PACKAGE_block-mount=y \
		CONFIG_PACKAGE_e2fsprogs=y \
		CONFIG_PACKAGE_dmsetup=y \
                CONFIG_PACKAGE_dm-verity=y

	IMAGES := \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin

endef
