include $(TOPDIR)/rules.mk

PKG_NAME    := openwisp-firmware
PKG_VERSION := 1.0
PKG_RELEASE := 1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION  := net
  CATEGORY := Network
  TITLE    := openwisp-firmware for hotspot system
  URL      := 
endef

define Package/$(PKG_NAME)/description
  OpenWISP is a software platform that can be used to implement a complete Wi-Fi service.
endef

define Build/Compile

endef

define Package/$(PKG_NAME)/install
	# install scripts
	$(INSTALL_DIR)  $(1)/etc/owispmanager
	$(INSTALL_DATA) ./files/common.sh \
			$(1)/etc/owispmanager/common.sh
	$(INSTALL_DATA) ./files/owispmanager.sh \
			$(1)/etc/owispmanager/owispmanager.sh
	$(INSTALL_DATA) ./files/failover.sh \
			$(1)/etc/owispmanager/failover.sh
	# install tools
	$(INSTALL_DIR)  $(1)/etc/owispmanager/tools
	$(INSTALL_DATA) ./files/tools/mac80211.sh \
			$(1)/etc/owispmanager/tools/mac80211.sh
	$(INSTALL_DATA) ./files/tools/madwifi.sh \
			$(1)/etc/owispmanager/tools/madwifi.sh
	# install service
	$(INSTALL_DIR)  $(1)/etc/init.d
	$(INSTALL_DATA) ./files/htpdate/htpdate.init \
			$(1)/etc/init.d/htpdate
	$(INSTALL_DIR)  $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./files/htpdate/htpdate.default \
			$(1)/etc/uci-defaults/htpdate
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
echo '::respawn:/etc/owispmanager/owispmanager.sh' >>$${IPKG_INSTROOT}/etc/inittab
echo '::respawn:/etc/owispmanager/failover.sh' >>$${IPKG_INSTROOT}/etc/inittab
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME),))
