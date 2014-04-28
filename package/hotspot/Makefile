#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=hotspot
PKG_VERSION:=0.1.0
PKG_RELEASE:=alpha

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/hotspot
	SECTION:=hotspot
	CATEGORY:=hotspot
	DEPENDS:=+libdaemon +liblua +luci-nixio
	TITLE:=hotspot managment daemon
	URL:=http://www.hotspot.net
	MAINTAINER:=wenjie.zhang <wei.a.yang@gmail.com>
endef

define Package/hotspot/description
	This package contains the hotspot daemon code and support libraries.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./luasrc/* $(PKG_BUILD_DIR)/
	$(CP) ./config/* $(PKG_BUILD_DIR)/
endef

define Package/hotspot/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/hotspot.uci $(1)/etc/config/hotspot
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hotspot.init $(1)/etc/init.d/hotspot
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dbg.lua $(1)/usr/lib/lua/

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luad $(1)/usr/sbin/
	$(LN) /usr/sbin/luad $(1)/usr/sbin/hotspotd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hotspotd.lua $(1)/usr/sbin/
	$(LN) /usr/sbin/luad $(1)/usr/sbin/supd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/supd.lua $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fcheck.sh $(1)/usr/bin/fcheck
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fntp.sh $(1)/usr/bin/fntp
endef

$(eval $(call BuildPackage,hotspot))
