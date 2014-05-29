
# (C) 2013 CarrierWrt.org

#
# Product profile: iSmart (Next generation smart home)
#

define Product/iSmart

	CONFIG += \
		CONFIG_BUSYBOX_CONFIG_TELNETD=n

endef

define Customization/default

	CONFIG += \
		CONFIG_PACKAGE_luci=y \
		CONFIG_PACKAGE_luci-app-radvd=y \
		CONFIG_PACKAGE_luci-theme-openwrt=y \
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
		CONFIG_EASYCWMP_DEBUG=y \
		CONFIG_PACKAGE_uhttpd-mod-lua=y \
		CONFIG_PACKAGE_libubus-lua=y \
		CONFIG_PACKAGE_uhttpd=y \
		CONFIG_PACKAGE_6LoWPAN=y \
		CONFIG_PACKAGE_6LoWPAN-6LoWPANd=y \
		CONFIG_PACKAGE_6LoWPAN-FirmwareDistribution=y \
		CONFIG_PACKAGE_6LoWPAN-JIPd=y \
		CONFIG_PACKAGE_6LoWPAN-JIPweb=y \
		CONFIG_PACKAGE_6LoWPAN-libJIP=y \
		CONFIG_PACKAGE_6LoWPAN-libJIP-CLI=y \
		CONFIG_PACKAGE_6LoWPAN-libJIP-test=n \
		CONFIG_PACKAGE_JennicModuleProgrammer=y \
		CONFIG_PACKAGE_GatewayFactoryTest=y \
		CONFIG_PACKAGE_libtecla=y \
		CONFIG_PACKAGE_mrd6=y \
		CONFIG_PACKAGE_serial-tester=n \
		CONFIG_PACKAGE_freeradius2=y \
		CONFIG_PACKAGE_libiwinfo=y \
		CONFIG_PACKAGE_gw6c=y \
		CONFIG_PACKAGE_libftdi=y \
		CONFIG_PACKAGE_iSmart=y \
		CONFIG_PACKAGE_libusb=y \
		CONFIG_PACKAGE_libxml2=y \
		CONFIG_PACKAGE_radvd=y \
		CONFIG_PACKAGE_dbus=y \
		CONFIG_PACKAGE_libavahi=y \
		CONFIG_PACKAGE_libavahi-client=y \
		CONFIG_PACKAGE_libavahi-dbus-support=y \
		CONFIG_PACKAGE_avahi-daemon=y \
		CONFIG_PACKAGE_avahi-utils=y \
		CONFIG_PACKAGE_dnsmasq-dhcpv6=y \
		CONFIG_PACKAGE_wireless-tools=y \
		CONFIG_PACKAGE_libsqlite3=y \
		CONFIG_PACKAGE_freeradius2-mod-files=y \
		CONFIG_PACKAGE_freeradius2-mod-greylist=y \
		CONFIG_PACKAGE_freeradius2-mod-pap=y \
		CONFIG_PACKAGE_freeradius2-utils=y \
		CONFIG_PACKAGE_ip6tables=y \
		CONFIG_PACKAGE_6in4=y \
		CONFIG_PACKAGE_6rd=y \
		CONFIG_PACKAGE_6to4=y \
		CONFIG_PACKAGE_kmod-usb-serial=y \
		CONFIG_PACKAGE_kmod-usb-serial-ftdi=y \
		CONFIG_PACKAGE_dbus-utils=y


	FEEDS += \
		mosquitto \
		libcurl \
		libmicroxml \
		shflags \
		ntpclient \
		libdaemon \
		freeradius2 \
		gw6c \
		libftdi \
		libxml2 \
		radvd \
		libavahi-client

	TESTED := \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-factory.bin \
		ar71xx/openwrt-ar71xx-generic-tl-wr703n-v1-squashfs-sysupgrade.bin

endef
