#
# Copyright (C) 2007 FON Wireless Ltd. All rights reserved.
#
# $Id: Makefile 1158 2007-11-29 18:02:21Z jesus.pico $
#
include $(TOPDIR)/rules.mk

PKG_NAME:=fonsmcd
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/fonsmcd
  SECTION:=fon
  CATEGORY:=Fonera
  TITLE:=FON Status Magager Client
  DEPENDS:=+libdaemon +liblua +luci-lib-nixio
  URL:=http://www.fon.com
endef

define Package/fonscmd/description
  FON Status Manager Client Daemon
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./luasrc/* $(PKG_BUILD_DIR)/
	$(CP) ./config/* $(PKG_BUILD_DIR)/
endef

define Package/fonsmcd/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/public_sm_rsa_key.pem $(1)/etc/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/hotspot.uci $(1)/etc/config/hotspot
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hotspot.init $(1)/etc/init.d/hotspot
	$(INSTALL_DIR) $(1)/etc/fon
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fonsmcd.conf $(1)/etc/fon/
	$(INSTALL_DIR) $(1)/etc/fonstated
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/StartFonsmcd $(1)/etc/fonstated/	
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dbg.lua $(1)/usr/lib/lua/

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luad $(1)/usr/sbin/
	$(LN) /usr/sbin/luad $(1)/usr/sbin/fonsmcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hotspotd.lua $(1)/usr/sbin/
	$(LN) /usr/sbin/luad $(1)/usr/sbin/supd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/supd.lua $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fcheck.sh $(1)/usr/bin/fcheck
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fntp.sh $(1)/usr/bin/fntp
endef

$(eval $(call BuildPackage,fonsmcd))
