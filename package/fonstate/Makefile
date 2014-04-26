# Copyright (C) 2008 FON Wireless Ltd.
# All rights reserved.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# blogic@openwrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=fonstate
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/fonstate
  SECTION:=fon
  CATEGORY:=Fonera
  TITLE:=FON Base System
  DEPENDS:=+uci 
  URL:=http://www.fon.com
endef

define Package/fonstate/description
  FON Base System
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CONFIGURE_OPTS) CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -std=gnu99" LDFLAGS="$(TARGET_LDFLAGS)" \
		$(MAKE) -C $(PKG_BUILD_DIR)
endef

define Package/fonstate/install
	$(INSTALL_DIR) $(1)/sbin/ $(1)/usr/lib/fonstate/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fonstated $(1)/sbin/
	rm -rf $(1)/sbin/fs
	ln -s /sbin/fonstated $(1)/sbin/fs
	cp -r ./files/* $(1)/
endef

$(eval $(call BuildPackage,fonstate))

