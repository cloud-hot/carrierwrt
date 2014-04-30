# Copyright (C) 2014 KING KONG Wireless Ltd.
# All rights reserved.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# blogic@openwrt.org
#

include $(TOPDIR)/rules.mk

PKG_NAME:=vboot_utils
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/vboot_utils
  SECTION:=fon
  CATEGORY:=Fonera
  TITLE:=FON firmware RSA check tools
  DEPENDS:=+libopenssl +liblua
  URL:=http://www.fon.com
endef

define Package/vboot_utils/description
  Vboot_utils is based on chromeos vboot_reference
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(TARGET_CONFIGURE_OPTS) CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -std=gnu99" LDFLAGS="$(TARGET_LDFLAGS)" \
		$(MAKE) -C $(PKG_BUILD_DIR)
endef

define Package/vboot_utils/install
	$(INSTALL_DIR) $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/vbutil_firmware $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/vbutil_keyblock $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/vbutil_key $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/dumpRSAPublicKey $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/common.sh $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/make_pair.sh $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/make_keyblock.sh $(1)/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/fonverify_fonera20 $(1)/sbin/fonverify_kon
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/fon/pkg/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/utility/fonverify.lua $(1)/usr/lib/lua/luci/fon/pkg/verify.lua
	$(INSTALL_DIR) $(1)/etc/fonstated/
	$(INSTALL_DATA) ./files/etc/FlashDevice $(1)/etc/fonstated/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/libfonrsa.so.1.0.1 $(1)/usr/lib/libfonrsa.so.1
	rm -f $(1)/usr/lib/lua/fonrsa.so
	ln -s /usr/lib/libfonrsa.so.1 $(1)/usr/lib/lua/fonrsa.so
endef

$(eval $(call BuildPackage,vboot_utils))

