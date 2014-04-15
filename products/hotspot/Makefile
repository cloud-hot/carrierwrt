
# (C) 2013 CarrierWrt.org

#
# Product profile: hotspot (Next generation hotspot)
#

define Product/hotspot

	CONFIG += \
		CONFIG_BUSYBOX_CONFIG_TELNETD=n \
		CONFIG_PACKAGE_luci=y \
		CONFIG_PACKAGE_dmsetup=y \
		CONFIG_PACKAGE_dm-verity=y
			
	SETTINGS := uci-product.sh

endef

define Customization/default

	CONFIG += \
		CONFIG_PACKAGE_luci-theme-bootstrap=y \
		CONFIG_PACKAGE_luci-branding=y \
		CONFIG_PACKAGE_libcurl=y \
		CONFIG_LIBCURL_OPENSSL=y \
		CONFIG_LIBCURL_THREADED_RESOLVER=y \
		CONFIG_LIBCURL_ZLIB=y \
		CONFIG_LIBCURL_CRYPTO_AUTH=y \
		CONFIG_PACKAGE_lua-mosquitto=y \
		CONFIG_PACKAGE_mqtt-service=y \
		CONFIG_PACKAGE_easycwmp=y \
		CONFIG_EASYCWMP_DEVEL=y \
		CONFIG_EASYCWMP_DEBUG=y \
		CONFIG_PACKAGE_hotspot=y

	SETTINGS := uci-customization.sh

	TESTED := \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin

endef
