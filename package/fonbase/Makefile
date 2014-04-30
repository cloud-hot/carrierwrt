# Copyright (C) 2008 FON Wireless Ltd.
# All rights reserved.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
include $(TOPDIR)/rules.mk

PKG_NAME:=fonbase
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/fonbase
  SECTION:=fon
  CATEGORY:=Fonera
  TITLE:=FON Base System
  DEPENDS:=+ntpclient +vboot_utils +fonstate +fonsmcd +iptables-mod-nat-extra
  URL:=http://www.fon.com
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Package/fonbase/description
  FON Base System
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) \
		-I$(STAGING_DIR)/usr/include/ \
		-fPIC -shared -Wl,-soname,azureus \
		-o $(PKG_BUILD_DIR)/fon.so ./src/fon.c
endef

define Package/fonbase/install
	$(CP) ./files/* $(1)/
	$(CP) ./targets/f01/* $(1)/
	mkdir -p $(1)/usr/lib/lua/
	echo $(REVISION) > $(1)/etc/fon_svn
	# If there is a "svn" tag in the beta or rc revision (meaning
	# unreleased svn version), replace it with a verbose revision
	# spec. The REVISION variable is filled by
	# openwrt/include/toplevel.mk.
	sed -i '/option \(beta\|rc\)/s/svn/$(REVISION)/' $(1)/etc/config/system
	# Make a copy of the config file used to build this firmware
	$(CP) $(TOPDIR)/.config $(1)/etc/openwrt-config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fon.so $(1)/usr/lib/lua/
endef

$(eval $(call BuildPackage,fonbase))

