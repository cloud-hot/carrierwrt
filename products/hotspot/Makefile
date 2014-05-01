
# (C) 2013 CarrierWrt.org

#
# Product profile: hotspot (Next generation hotspot)
#

define Product/hotspot

	CONFIG += \
		CONFIG_BUSYBOX_CONFIG_TELNETD=n \
		CONFIG_PACKAGE_dmsetup=y \
		CONFIG_PACKAGE_dm-verity=y
			
	SETTINGS := uci-product.sh

endef

define Customization/default

	CONFIG += \
		CONFIG_PACKAGE_fon-luci=y  \
		CONFIG_PACKAGE_luci-admin-fon_nousb=y  \
		CONFIG_PACKAGE_luci-admin-fon-rpc=y \
		CONFIG_PACKAGE_luci-app-debug=y \
		CONFIG_PACKAGE_luci-app-facebook=y \
		CONFIG_PACKAGE_luci-app-fonfw=y \
		CONFIG_PACKAGE_luci-app-openvpn=y \
		CONFIG_PACKAGE_luci-app-qos=y \
		CONFIG_PACKAGE_luci-app-wizard-fonera2=y \
		CONFIG_PACKAGE_luci-cbi=y \
		CONFIG_PACKAGE_luci-core=y \
		CONFIG_PACKAGE_luci-core_compile=y \
		CONFIG_PACKAGE_luci-fon=y \
		CONFIG_PACKAGE_luci-http=y \
		CONFIG_PACKAGE_luci-httpclient=y \
		CONFIG_PACKAGE_luci-json=y \
		CONFIG_PACKAGE_luci-luanet=y \
		CONFIG_PACKAGE_luci-lucid=y \
		CONFIG_PACKAGE_luci-nixio=y \
		CONFIG_PACKAGE_luci-nixio_openssl=y \
		CONFIG_PACKAGE_luci-px5g=y \
		CONFIG_PACKAGE_luci-sgi-cgi=y \
		CONFIG_PACKAGE_luci-sys=y \
		CONFIG_PACKAGE_luci-twitter=y \
		CONFIG_PACKAGE_luci-uci=y \
		CONFIG_PACKAGE_luci-uvl=y \
		CONFIG_PACKAGE_luci-web=y \
		CONFIG_PACKAGE_luci-theme-fon=y \
		CONFIG_PACKAGE_luci-i18n-english=y \
		CONFIG_PACKAGE_luci-i18n-zh_cn=y \
		CONFIG_PACKAGE_fonbase=y \
		CONFIG_PACKAGE_fonstate=y \
		CONFIG_PACKAGE_fonsmcd=y \
		CONFIG_PACKAGE_vboot_utils=y \
		CONFIG_PACKAGE_libcurl=y \
		CONFIG_LIBCURL_OPENSSL=y \
		CONFIG_LIBCURL_THREADED_RESOLVER=y \
		CONFIG_LIBCURL_ZLIB=y \
		CONFIG_LIBCURL_CRYPTO_AUTH=y \
		CONFIG_PACKAGE_lua-mosquitto=y \
		CONFIG_PACKAGE_mqtt-service=y \
		CONFIG_PACKAGE_easycwmp=y \
		CONFIG_EASYCWMP_DEVEL=y \
		CONFIG_EASYCWMP_DEBUG=y

	SETTINGS := uci-customization.sh

	TESTED := \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin

endef
