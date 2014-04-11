include $(TOPDIR)/rules.mk

PKG_NAME    := mqtt-service
PKG_VERSION := 1.0
PKG_RELEASE := 1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION  := net
  CATEGORY := Network
  TITLE    := Some useful mqtt service for tr069 and other components
  URL      := 
  DEPENDS  := +lua-mosquitto
endef

define Package/$(PKG_NAME)/description
  Scripts that add mqtt notification support for tr069 and other service.
endef

define Build/Compile

endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR)  $(1)/lib/mqtt
	$(INSTALL_BIN) ./files/lib/mqtt/mqtt-tr069.lua \
			$(1)/lib/mqtt/mqtt-tr069.lua
endef

$(eval $(call BuildPackage,$(PKG_NAME),))
