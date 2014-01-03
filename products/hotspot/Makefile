
# (C) 2013 CarrierWrt.org

#
# Product profile: hotspot (Next generation hotspot)
#

define Product/hotspot

	CONFIG += \
		CONFIG_BUSYBOX_CONFIG_TELNETD=n \
		CONFIG_PACKAGE_luci=y
			
	SETTINGS := uci-product.sh

endef

define Customization/default

	CONFIG += \
		CONFIG_PACKAGE_luci-theme-bootstrap=y \
		CONFIG_PACKAGE_luci-branding=y
	
	SETTINGS := uci-customization.sh

	TESTED := \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin

endef
