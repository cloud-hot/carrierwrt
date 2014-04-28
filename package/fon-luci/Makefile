include $(TOPDIR)/rules.mk

PKG_BRANCH:=

PKG_NAME:=luci
PKG_RELEASE:=1
PKG_VERSION:=0.9+svn
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

PKG_BUILD_DEPENDS:=libnotimpl
LUA_TARGET:=source
PKG_SELECTED_MODULES:=
LUCI_CFLAGS:=


include $(INCLUDE_DIR)/package.mk

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -r ./luci/* $(PKG_BUILD_DIR)
	$(call Build/Prepare/Default)	
endef

define Build/Configure
endef

### Templates ###

define Package/luci/libtemplate
  SECTION:=luci
  CATEGORY:=Luci
  TITLE:=LuCI - Lua Configuration Interface
  URL:=http://luci.freifunk-halle.net/
  MAINTAINER:=Steven Barth <steven-at-midlink-dot-org>
  SUBMENU:=LuCI Libraries
  DEPENDS:=+luci-core
endef

define Package/luci/fftemplate
  $(call Package/luci/libtemplate)
  SUBMENU:=LuCI Freifunk Support (GERMAN ONLY)
  DEPENDS:=+luci-mod-freifunk
endef

define Package/luci/httpdtemplate
  $(call Package/luci/libtemplate)
  SUBMENU:=LuCI Non-Forking HTTP-Daemon (EXPERIMENTAL)
  DEPENDS:=+luci-httpd
endef

define Package/luci/i18ntemplate
  $(call Package/luci/libtemplate)
  SUBMENU:=LuCI Translations
  DEPENDS:=+luci-web
endef

define Package/luci/thtemplate
  $(call Package/luci/libtemplate)
  SUBMENU:=LuCI Themes
  DEPENDS:=+luci-web
endef

define Package/luci/webtemplate
  $(call Package/luci/libtemplate)
  SUBMENU:=LuCI Components
endef


define Package/luci/install/template
	$(CP) -a $(PKG_BUILD_DIR)/$(2)/dist/* $(1)/ -R
	$(CP) -a $(PKG_BUILD_DIR)/$(2)/ipkg/* $(1)/CONTROL/ 2>/dev/null || true
endef



### Core package ###

define Package/luci-core
  $(call Package/luci/libtemplate)
  DEPENDS:=+lua
  TITLE:=LuCI core libraries
endef

define Package/luci-core/install
	$(call Package/luci/install/template,$(1),libs/core)
endef

define Package/luci-core/config
       choice
               prompt "Build Target"
               default PACKAGE_luci-core_compile

       config PACKAGE_luci-core_compile
               bool "Precompiled"

       config PACKAGE_luci-core_stripped
               bool "Stripped"

       config PACKAGE_luci-core_source
               bool "Full Source"

       endchoice
endef

ifneq ($(CONFIG_PACKAGE_luci-core_compile),)
  LUA_TARGET:=compile
endif

ifneq ($(CONFIG_PACKAGE_luci-core_stripped),)
  LUA_TARGET:=strip
endif


### Libraries ###
define Package/luci-fon
  $(call Package/luci/libtemplate)
  DEPENDS+=+luci-web +luci-uvl +luci-uci
  TITLE:=luci fon
endef

define Package/luci-fon/install
	$(call Package/luci/install/template,$(1),libs/fon)
endef

define Package/luci-uploadd
  $(call Package/luci/libtemplate)
  DEPENDS+=+luci-uci
  TITLE:=fon uploader
endef

define Package/luci-uploadd/install
	$(call Package/luci/install/template,$(1),libs/uploadd)
endef

define Package/luci-cbi
  $(call Package/luci/libtemplate)
  DEPENDS+=+luci-web +luci-uvl +luci-uci
  TITLE:=Configuration Binding Interface
endef

define Package/luci-cbi/install
	$(call Package/luci/install/template,$(1),libs/cbi)
endef


define Package/luci-uci
  $(call Package/luci/libtemplate)
  DEPENDS+=+libuci-lua
  TITLE:=High-Level UCI API
endef

define Package/luci-uci/install
	$(call Package/luci/install/template,$(1),libs/uci)
endef


define Package/luci-fastindex
  $(call Package/luci/libtemplate)
  TITLE:=Fastindex indexing module
endef

define Package/luci-fastindex/install
	$(call Package/luci/install/template,$(1),libs/fastindex)
endef


define Package/luci-http
  $(call Package/luci/libtemplate)
  TITLE:=HTTP Protocol implementation
endef

define Package/luci-http/install
	$(call Package/luci/install/template,$(1),libs/http)
endef


define Package/luci-httpclient
  $(call Package/luci/libtemplate)
  TITLE:=HTTP(S) client library
  DEPENDS+=+luci-http +luci-nixio
endef

define Package/luci-httpclient/install
	$(call Package/luci/install/template,$(1),libs/httpclient)
endef


define Package/luci-ipkg
  $(call Package/luci/libtemplate)
  TITLE:=LuCI IPKG/OPKG call abstraction library
endef

define Package/luci-ipkg/install
	$(call Package/luci/install/template,$(1),libs/ipkg)
endef


define Package/luci-json
  $(call Package/luci/libtemplate)
  TITLE:=LuCI JSON Library
endef

define Package/luci-json/install
	$(call Package/luci/install/template,$(1),libs/json)
endef


define Package/luci-lucid
  $(call Package/luci/libtemplate)
  TITLE:=LuCId Superserver
  DEPENDS+=+luci-nixio +luci-http +luci-px5g
endef

define Package/luci-lucid/install
	$(call Package/luci/install/template,$(1),libs/lucid)
	$(call Package/luci/install/template,$(1),libs/lucid-http)
endef


NIXIO_TLS:=axtls

define Package/luci-nixio
  $(call Package/luci/libtemplate)
  TITLE:=NIXIO Socket Library
  DEPENDS:=
endef

define Package/luci-nixio/install
	$(call Package/luci/install/template,$(1),libs/nixio)
endef

define Package/luci-nixio/config
	choice
		prompt "TLS Provider"
		default PACKAGE_luci-nixio_openssl

		config PACKAGE_luci-nixio_axtls
			bool "Builtin (axTLS)"
			select PACKAGE_dropbear
			select PACKAGE_dropbearconvert

		config PACKAGE_luci-nixio_cyassl
			bool "CyaSSL"
			select PACKAGE_libcyassl-luci

		config PACKAGE_luci-nixio_openssl
			bool "OpenSSL"
			select PACKAGE_libopenssl
	endchoice
endef

ifneq ($(CONFIG_PACKAGE_luci-nixio_openssl),)
  NIXIO_TLS:=openssl
endif

ifneq ($(CONFIG_PACKAGE_luci-nixio_cyassl),)
  NIXIO_TLS:=cyassl
  LUCI_CFLAGS+=-I$(STAGING_DIR)/usr/include/cyassl
endif


define Package/luci-px5g
  $(call Package/luci/libtemplate)
  TITLE:=PX5G RSA Keymaster
  DEPENDS:=+luci-nixio
endef

define Package/luci-px5g/install
	$(call Package/luci/install/template,$(1),libs/px5g)
endef


define Package/luci-sys
  $(call Package/luci/libtemplate)
  TITLE:=LuCI Linux/POSIX system library
endef

define Package/luci-sys/install
	$(call Package/luci/install/template,$(1),libs/sys)
endef


define Package/luci-web
  $(call Package/luci/libtemplate)
  DEPENDS+=+luci-http +luci-sys +luci-uci +luci-sgi-cgi
  TITLE:=MVC Webframework
endef

define Package/luci-web/conffiles
/etc/config/luci
endef

define Package/luci-web/install
	$(call Package/luci/install/template,$(1),libs/web)
endef


define Package/luci-uvl
  $(call Package/luci/libtemplate)
  DEPENDS+=+luci-sys +luci-uci +luci-core
  TITLE:=UVL - UCI Validation Layer
endef

define Package/luci-uvl/install
	$(call Package/luci/install/template,$(1),libs/uvl)
endef



### HTTPD ###

define Package/luci-httpd
  $(call Package/luci/httpdtemplate)
  DEPENDS:=+luci-http 
  TITLE:=Server Core
endef

define Package/luci-httpd/install
	$(call Package/luci/install/template,$(1),libs/httpd)
endef


### Modules ###

define Package/luci-admin-fon
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-web +luci-cbi +luci-theme-fon +luci-i18n-english +luci-i18n-zh_cn +luci-luanet +luci-twitter +mobile-broadband-provider-info
  TITLE:=Web UI Core Module
endef

define Package/luci-admin-fon/install
	$(call Package/luci/install/template,$(1),modules/admin-fon)
endef

define Package/luci-admin-fon_nousb
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-web +luci-cbi +luci-theme-fon \
  	+luci-lucid \
	+luci-nixio \
	+luci-httpclient \
	+luci-fon \
	+luci-app-ddns \
	+luci-app-fonfw \
	+luci-app-fonlivestats \
	+luci-app-twitter \
  	+luci-admin-rpc \
	+luci-luanet \
	+luci-i18n-english +luci-i18n-zh_cn
  TITLE:=Web UI Core Module
endef

define Package/luci-admin-fon_nousb/install
	$(call Package/luci/install/template,$(1),modules/admin-fon_nousb)
endef

define Package/luci-admin-rpc
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-json
  TITLE:=LuCI RPC - JSON-RPC API
endef

define Package/luci-admin-rpc/install
	$(call Package/luci/install/template,$(1),modules/rpc)
endef

define Package/luci-admin-fon-rpc
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-json
  TITLE:=FON RPC - JSON-RPC API
endef

define Package/luci-admin-fon-rpc/install
	$(call Package/luci/install/template,$(1),modules/fon-rpc)
endef


### Applications ###

define Package/luci-app-youtube
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=youtube plugin
endef

define Package/luci-app-youtube/install
	$(call Package/luci/install/template,$(1),applications/luci-youtube)
endef

define Package/luci-app-openvpn
  $(call Package/luci/webtemplate)
  TITLE:=OpenVpn
  DEPENDS+=+openvpn +openssl-util +zip
endef

define Package/luci-app-openvpn/install
	$(call Package/luci/install/template,$(1),applications/luci-openvpn)
endef

define Package/luci-app-qos
  $(call Package/luci/webtemplate)
  TITLE:=QoS
endef

define Package/luci-app-qos/install
	$(call Package/luci/install/template,$(1),applications/luci-qos)
endef

define Package/luci-app-ushare
  $(call Package/luci/webtemplate)
  TITLE:=uShare
  DEPENDS:=+ushare
endef

define Package/luci-app-ushare/install
	$(call Package/luci/install/template,$(1),applications/luci-ushare)
endef

define Package/luci-app-upgrade
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=upgrade plugin
endef

define Package/luci-app-upgrade/install
	$(call Package/luci/install/template,$(1),applications/luci-upgrade)
endef

define Package/luci-app-picasa
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=picasa plugin
endef

define Package/luci-app-picasa/install
	$(call Package/luci/install/template,$(1),applications/luci-picasa)
endef

define Package/luci-app-flickr
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=flickr plugin
endef

define Package/luci-app-flickr/install
	$(call Package/luci/install/template,$(1),applications/luci-flickr)
endef

define Package/luci-app-facebook
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=facebook plugin
endef

define Package/luci-app-facebook/install
	$(call Package/luci/install/template,$(1),applications/luci-facebook)
endef

define Package/luci-app-music
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon +luci-httpclient
  TITLE:=music plugin
endef

define Package/luci-app-music/install
	$(call Package/luci/install/template,$(1),applications/luci-music)
endef

define Package/luci-app-debug
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=debug info plugin
endef

define Package/luci-app-debug/install
	$(call Package/luci/install/template,$(1),applications/luci-debug)
endef

define Package/luci-app-twitter
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-twitter
  TITLE:=twitter plugin
endef

define Package/luci-app-twitter/install
	$(call Package/luci/install/template,$(1),applications/luci-twitter)
endef

define Package/luci-app-ddns
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=Dynamic DNS configuration module
endef

define Package/luci-app-ddns/install
	$(call Package/luci/install/template,$(1),applications/luci-ddns)
endef

define Package/luci-app-fonfw
  $(call Package/luci/webtemplate)
  DEPENDS+=+luci-admin-fon
  TITLE:=FON Firewall
endef

define Package/luci-app-fonfw/install
	$(call Package/luci/install/template,$(1),applications/luci-fonfw)
endef

define Package/luci-app-fonlivestats/install
	$(call Package/luci/install/template,$(1),applications/luci-fonlivestats)
endef

define Package/luci-app-fonlivestats
  $(call Package/luci/webtemplate)
  TITLE:=Live Statistic
endef

define Package/luci-app-torrent
  $(call Package/luci/webtemplate)
  TITLE:=torrent luci pages
endef

define Package/luci-app-torrent/install
	$(call Package/luci/install/template,$(1),applications/luci-torrent)
endef

define Package/luci-app-wizard-fonera2
  $(call Package/luci/webtemplate)
  TITLE:=Wizard for foner2
endef

define Package/luci-app-wizard-fonera2/install
	$(call Package/luci/install/template,$(1),applications/luci-wizard-fonera2)
endef

define Package/luci-app-bugme-register
  $(call Package/luci/webtemplate)
  TITLE:=bugme register
endef

define Package/luci-app-bugme-register/install
	$(call Package/luci/install/template,$(1),applications/luci-bugme-register)
endef

define Package/luci-app-olpc
  $(call Package/luci/webtemplate)
  TITLE:=olpc luci pages
  DEPENDS:=+kmod-olpc-wifi
endef

define Package/luci-app-olpc/install
	$(call Package/luci/install/template,$(1),applications/luci-olpc)
endef

define Package/luci-app-fonbrowser
  $(call Package/luci/webtemplate)
  TITLE:=luci filebrowser
endef

define Package/luci-app-fonbrowser/install
	$(call Package/luci/install/template,$(1),applications/luci-fonbrowser)
endef

define Package/luci-app-fonbackup
  $(call Package/luci/webtemplate)
  TITLE:=luci fonbackup api
  DEPENDS+=+pure-ftpd
endef

define Package/luci-app-fonbackup/install
	$(call Package/luci/install/template,$(1),applications/luci-fonbackup)
endef

define Package/luci-app-fonwebcam
  $(call Package/luci/webtemplate)
  TITLE:=luci webacm 
endef

define Package/luci-app-fonwebcam/install
	$(call Package/luci/install/template,$(1),applications/luci-webcam)
endef

define Package/luci-app-fonprinter
  $(call Package/luci/webtemplate)
  TITLE:=luci printer
endef

define Package/luci-app-fonprinter/install
	$(call Package/luci/install/template,$(1),applications/luci-printer)
endef


define Package/luci-app-downloadmanager
$(call Package/luci/webtemplate)
TITLE:=luci downloadmanager
endef

define Package/luci-app-downloadmanager/install
$(call Package/luci/install/template,$(1),applications/luci-downloadmanager)
endef


define Package/luci-app-ffrpc
$(call Package/luci/webtemplate)
DEPENDS+=+luci-admin-fon-rpc
TITLE:=Firefox RPC API
endef

define Package/luci-app-ffrpc/install
$(call Package/luci/install/template,$(1),applications/luci-ffrpc)
endef

define Package/luci-app-wol
  $(call Package/luci/webtemplate)
  TITLE:=Wake-on-LAN
  DEPENDS+=+etherwake
endef

define Package/luci-app-wol/install
$(call Package/luci/install/template,$(1),applications/luci-wol)
endef


### Server Gateway Interfaces ###

define Package/luci-sgi-cgi
  $(call Package/luci/libtemplate)
  TITLE:=SGI for CGI
endef

define Package/luci-sgi-cgi/install
	$(call Package/luci/install/template,$(1),libs/sgi-cgi)
endef

define Package/luci-sgi-luci
  $(call Package/luci/libtemplate)
  DEPENDS+=+luci-httpd
  TITLE:=SGI for LuCI HTTPD
endef

define Package/luci-sgi-luci/install
	$(call Package/luci/install/template,$(1),libs/sgi-luci)
endef

define Package/luci-sgi-webuci
  $(call Package/luci/libtemplate)
  TITLE:=SGI for Webuci
endef

define Package/luci-sgi-webuci/install
	$(call Package/luci/install/template,$(1),libs/sgi-webuci)
endef

define Package/luci-lucittpd
  $(call Package/luci/libtemplate)
  TITLE:=lucittpd
endef

define Package/luci-lucittpd/install
	$(call Package/luci/install/template,$(1),libs/lucittpd)
endef

define Package/luci-luanet
  $(call Package/luci/libtemplate)
  TITLE:=luanet
  DEPENDS+=+libiw
endef

define Package/luci-luanet/install
	$(call Package/luci/install/template,$(1),libs/luanet)
endef

define Package/luci-twitter
  $(call Package/luci/libtemplate)
  TITLE:=twitter
endef

define Package/luci-twitter/install
	$(call Package/luci/install/template,$(1),libs/twitter)
endef

define Package/luci-uvc
  $(call Package/luci/libtemplate)
  TITLE:=uvc webcam adaptor
endef

define Package/luci-uvc/install
	$(call Package/luci/install/template,$(1),libs/uvc)
endef

### Themes ###
define Package/luci-theme-fon
  $(call Package/luci/thtemplate)
  TITLE:=FON
endef

define Package/luci-theme-fon/install
	$(call Package/luci/install/template,$(1),themes/fon)
endef

### Translations ###
define Package/luci-i18n-french
  $(call Package/luci/i18ntemplate)
  TITLE:=French
endef

define Package/luci-i18n-french/install
	$(call Package/luci/install/template,$(1),i18n/french)
endef

define Package/luci-i18n-italian
  $(call Package/luci/i18ntemplate)
  TITLE:=Italian
endef

define Package/luci-i18n-italian/install
	$(call Package/luci/install/template,$(1),i18n/italian)
endef

define Package/luci-i18n-dutch
  $(call Package/luci/i18ntemplate)
  TITLE:=Dutch
endef

define Package/luci-i18n-dutch/install
	$(call Package/luci/install/template,$(1),i18n/dutch)
endef

define Package/luci-i18n-zh_tw
  $(call Package/luci/i18ntemplate)
  TITLE:=zh_tw
endef

define Package/luci-i18n-zh_tw/install
	$(call Package/luci/install/template,$(1),i18n/zh_TW)
endef

define Package/luci-i18n-zh_cn
  $(call Package/luci/i18ntemplate)
  TITLE:=zh_cn
endef

define Package/luci-i18n-zh_cn/install
	$(call Package/luci/install/template,$(1),i18n/zh_CN)
endef

define Package/luci-i18n-german
  $(call Package/luci/i18ntemplate)
  TITLE:=German
endef

define Package/luci-i18n-german/install
	$(call Package/luci/install/template,$(1),i18n/german)
endef

define Package/luci-i18n-portuguese
  $(call Package/luci/i18ntemplate)
  TITLE:=Portuguese
endef

define Package/luci-i18n-portuguese/install
	$(call Package/luci/install/template,$(1),i18n/portuguese)
endef

define Package/luci-i18n-hungarian
  $(call Package/luci/i18ntemplate)
  TITLE:=Hungarian
endef

define Package/luci-i18n-hungarian/install
	$(call Package/luci/install/template,$(1),i18n/hungarian)
endef

define Package/luci-i18n-japanese
  $(call Package/luci/i18ntemplate)
  TITLE:=Japanese
endef

define Package/luci-i18n-japanese/install
	$(call Package/luci/install/template,$(1),i18n/japanese)
endef

define Package/luci-i18n-basque
  $(call Package/luci/i18ntemplate)
  TITLE:=Basque
endef

define Package/luci-i18n-basque/install
	$(call Package/luci/install/template,$(1),i18n/basque)
endef

define Package/luci-i18n-catalan
  $(call Package/luci/i18ntemplate)
  TITLE:=Catalan
endef

define Package/luci-i18n-catalan/install
	$(call Package/luci/install/template,$(1),i18n/catalan)
endef

define Package/luci-i18n-polish
  $(call Package/luci/i18ntemplate)
  TITLE:=Polish
endef

define Package/luci-i18n-polish/install
	$(call Package/luci/install/template,$(1),i18n/polish)
endef

define Package/luci-i18n-spanish
  $(call Package/luci/i18ntemplate)
  TITLE:=Spanish
endef

define Package/luci-i18n-spanish/install
	$(call Package/luci/install/template,$(1),i18n/spanish)
endef

define Package/luci-i18n-english
  $(call Package/luci/i18ntemplate)
  TITLE:=English
endef

define Package/luci-i18n-english/install
	$(call Package/luci/install/template,$(1),i18n/english)
endef

### Compile ###
ifneq ($(CONFIG_PACKAGE_luci-core),)
	PKG_SELECTED_MODULES+=libs/core
endif
ifneq ($(CONFIG_PACKAGE_luci-fon),)
	PKG_SELECTED_MODULES+=libs/fon
endif
ifneq ($(CONFIG_PACKAGE_luci-uploadd),)
	PKG_SELECTED_MODULES+=libs/uploadd
endif
ifneq ($(CONFIG_PACKAGE_luci-cbi),)
	PKG_SELECTED_MODULES+=libs/cbi
endif
ifneq ($(CONFIG_PACKAGE_luci-fastindex),)
	PKG_SELECTED_MODULES+=libs/fastindex
endif
ifneq ($(CONFIG_PACKAGE_luci-http),)
	PKG_SELECTED_MODULES+=libs/http
endif
ifneq ($(CONFIG_PACKAGE_luci-httpclient),)
	PKG_SELECTED_MODULES+=libs/httpclient
endif
ifneq ($(CONFIG_PACKAGE_luci-ipkg),)
	PKG_SELECTED_MODULES+=libs/ipkg
endif
ifneq ($(CONFIG_PACKAGE_luci-json),)
	PKG_SELECTED_MODULES+=libs/json
endif
ifneq ($(CONFIG_PACKAGE_luci-lucid),)
	PKG_SELECTED_MODULES+=libs/lucid libs/lucid-http
endif
ifneq ($(CONFIG_PACKAGE_luci-nixio),)
	PKG_SELECTED_MODULES+=libs/nixio
endif
ifneq ($(CONFIG_PACKAGE_luci-px5g),)
	PKG_SELECTED_MODULES+=libs/px5g
endif
ifneq ($(CONFIG_PACKAGE_luci-uci),)
	PKG_SELECTED_MODULES+=libs/uci
endif
ifneq ($(CONFIG_PACKAGE_luci-sys),)
	PKG_SELECTED_MODULES+=libs/sys
endif
ifneq ($(CONFIG_PACKAGE_luci-web),)
	PKG_SELECTED_MODULES+=libs/web
endif
ifneq ($(CONFIG_PACKAGE_luci-uvl),)
	PKG_SELECTED_MODULES+=libs/uvl
endif
ifneq ($(CONFIG_PACKAGE_luci-httpd),)
	PKG_SELECTED_MODULES+=libs/httpd
endif
ifneq ($(CONFIG_PACKAGE_luci-admin-fon),)
	PKG_SELECTED_MODULES+=modules/admin-fon
endif
ifneq ($(CONFIG_PACKAGE_luci-admin-fon_nousb),)
	PKG_SELECTED_MODULES+=modules/admin-fon_nousb
endif
ifneq ($(CONFIG_PACKAGE_luci-admin-rpc),)
	PKG_SELECTED_MODULES+=modules/rpc
endif
ifneq ($(CONFIG_PACKAGE_luci-admin-fon-rpc),)
	PKG_SELECTED_MODULES+=modules/fon-rpc
endif
ifneq ($(CONFIG_PACKAGE_luci-mod-freifunk),)
	PKG_SELECTED_MODULES+=modules/freifunk
endif

ifneq ($(CONFIG_PACKAGE_luci-freifunk-community),)
	PKG_SELECTED_MODULES+=applications/freifunk-community
endif

ifneq ($(CONFIG_PACKAGE_luci-app-ffwizard-leipzig),)
	PKG_SELECTED_MODULES+=applications/luci-ffwizard-leipzig
endif
ifneq ($(CONFIG_PACKAGE_luci-app-youtube),)
	PKG_SELECTED_MODULES+=applications/luci-youtube
endif
ifneq ($(CONFIG_PACKAGE_luci-app-openvpn),)
	PKG_SELECTED_MODULES+=applications/luci-openvpn
endif
ifneq ($(CONFIG_PACKAGE_luci-app-ushare),)
	PKG_SELECTED_MODULES+=applications/luci-ushare
endif
ifneq ($(CONFIG_PACKAGE_luci-app-qos),)
	PKG_SELECTED_MODULES+=applications/luci-qos
endif
ifneq ($(CONFIG_PACKAGE_luci-app-upgrade),)
	PKG_SELECTED_MODULES+=applications/luci-upgrade
endif
ifneq ($(CONFIG_PACKAGE_luci-app-picasa),)
	PKG_SELECTED_MODULES+=applications/luci-picasa
endif
ifneq ($(CONFIG_PACKAGE_luci-app-flickr),)
	PKG_SELECTED_MODULES+=applications/luci-flickr
endif
ifneq ($(CONFIG_PACKAGE_luci-app-facebook),)
	PKG_SELECTED_MODULES+=applications/luci-facebook
endif
ifneq ($(CONFIG_PACKAGE_luci-app-music),)
	PKG_SELECTED_MODULES+=applications/luci-music
endif
ifneq ($(CONFIG_PACKAGE_luci-app-debug),)
	PKG_SELECTED_MODULES+=applications/luci-debug
endif
ifneq ($(CONFIG_PACKAGE_luci-app-twitter),)
	PKG_SELECTED_MODULES+=applications/luci-twitter
endif
ifneq ($(CONFIG_PACKAGE_luci-app-ntpc),)
	PKG_SELECTED_MODULES+=applications/luci-ntpc
endif
ifneq ($(CONFIG_PACKAGE_luci-app-ddns),)
	PKG_SELECTED_MODULES+=applications/luci-ddns
endif
ifneq ($(CONFIG_PACKAGE_luci-app-fonfw),)
	PKG_SELECTED_MODULES+=applications/luci-fonfw
endif
ifneq ($(CONFIG_PACKAGE_luci-app-torrent),)
	PKG_SELECTED_MODULES+=applications/luci-torrent
endif
ifneq ($(CONFIG_PACKAGE_luci-app-wizard-fonera2),)
	PKG_SELECTED_MODULES+=applications/luci-wizard-fonera2
endif
ifneq ($(CONFIG_PACKAGE_luci-app-olpc),)
	PKG_SELECTED_MODULES+=applications/luci-olpc
endif
ifneq ($(CONFIG_PACKAGE_luci-app-fonlivestats),)
	PKG_SELECTED_MODULES+=applications/luci-fonlivestats
endif
ifneq ($(CONFIG_PACKAGE_luci-app-bugme-register),)
	PKG_SELECTED_MODULES+=applications/luci-bugme-register
endif
ifneq ($(CONFIG_PACKAGE_luci-app-fonbrowser),)
	PKG_SELECTED_MODULES+=applications/luci-fonbrowser
endif
ifneq ($(CONFIG_PACKAGE_luci-app-fonbackup),)
	PKG_SELECTED_MODULES+=applications/luci-fonbackup
endif
ifneq ($(CONFIG_PACKAGE_luci-app-fonprinter),)
	PKG_SELECTED_MODULES+=applications/luci-printer
endif
ifneq ($(CONFIG_PACKAGE_luci-app-fonwebcam),)
	PKG_SELECTED_MODULES+=applications/luci-webcam
endif
ifneq ($(CONFIG_PACKAGE_luci-app-ushare),)
        PKG_SELECTED_MODULES+=applications/luci-ushare
endif
ifneq ($(CONFIG_PACKAGE_luci-app-hd_idle),)
       PKG_SELECTED_MODULES+=applications/luci-hd_idle
endif
ifneq ($(CONFIG_PACKAGE_luci-app-tinyproxy),)
       PKG_SELECTED_MODULES+=applications/luci-tinyproxy
endif
ifneq ($(CONFIG_PACKAGE_luci-app-initmgr),)
       PKG_SELECTED_MODULES+=applications/luci-initmgr
endif
ifneq ($(CONFIG_PACKAGE_luci-app-downloadmanager),)
       PKG_SELECTED_MODULES+=applications/luci-downloadmanager
endif
ifneq ($(CONFIG_PACKAGE_luci-app-ffrpc),)
       PKG_SELECTED_MODULES+=applications/luci-ffrpc
endif
ifneq ($(CONFIG_PACKAGE_luci-app-wol),)
	PKG_SELECTED_MODULES+=applications/luci-wol
endif


ifneq ($(CONFIG_PACKAGE_luci-sgi-cgi),)
	PKG_SELECTED_MODULES+=libs/sgi-cgi
endif
ifneq ($(CONFIG_PACKAGE_luci-sgi-luci),)
	PKG_SELECTED_MODULES+=libs/sgi-luci
endif
ifneq ($(CONFIG_PACKAGE_luci-sgi-webuci),)
	PKG_SELECTED_MODULES+=libs/sgi-webuci
endif
ifneq ($(CONFIG_PACKAGE_luci-lucittpd),)
	PKG_SELECTED_MODULES+=libs/lucittpd
endif
ifneq ($(CONFIG_PACKAGE_luci-luanet),)
	PKG_SELECTED_MODULES+=libs/luanet
endif
ifneq ($(CONFIG_PACKAGE_luci-twitter),)
	PKG_SELECTED_MODULES+=libs/twitter
endif
ifneq ($(CONFIG_PACKAGE_luci-uvc),)
	PKG_SELECTED_MODULES+=libs/uvc
endif
ifneq ($(CONFIG_PACKAGE_luci-theme-fon),)
	PKG_SELECTED_MODULES+=themes/fon
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-french),)
	PKG_SELECTED_MODULES+=i18n/french
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-italian),)
	PKG_SELECTED_MODULES+=i18n/italian
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-zh_tw),)
	PKG_SELECTED_MODULES+=i18n/zh_TW
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-zh_cn),)
	PKG_SELECTED_MODULES+=i18n/zh_CN
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-german),)
	PKG_SELECTED_MODULES+=i18n/german
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-portuguese),)
	PKG_SELECTED_MODULES+=i18n/portuguese
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-dutch),)
	PKG_SELECTED_MODULES+=i18n/dutch
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-hungarian),)
	PKG_SELECTED_MODULES+=i18n/hungarian
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-japanese),)
	PKG_SELECTED_MODULES+=i18n/japanese
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-basque),)
	PKG_SELECTED_MODULES+=i18n/basque
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-catalan),)
	PKG_SELECTED_MODULES+=i18n/catalan
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-polish),)
	PKG_SELECTED_MODULES+=i18n/polish
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-spanish),)
	PKG_SELECTED_MODULES+=i18n/spanish
endif
ifneq ($(CONFIG_PACKAGE_luci-i18n-english),)
	PKG_SELECTED_MODULES+=i18n/english
endif


MAKE_FLAGS += \
	MODULES="$(PKG_SELECTED_MODULES)" \
	LUA_TARGET="$(LUA_TARGET)" \
	LUA_SHLIBS="-llua -lm -ldl -lcrypt" \
	CFLAGS="$(TARGET_CFLAGS) $(LUCI_CFLAGS) -I$(STAGING_DIR)/usr/include" \
	LDFLAGS="$(TARGET_LDFLAGS) -L$(STAGING_DIR)/usr/lib" \
	NIXIO_TLS="$(NIXIO_TLS)" OS="Linux"


$(eval $(call BuildPackage,luci-core))
$(eval $(call BuildPackage,luci-cbi))
$(eval $(call BuildPackage,luci-fon))
$(eval $(call BuildPackage,luci-uploadd))
$(eval $(call BuildPackage,luci-fastindex))
$(eval $(call BuildPackage,luci-http))
$(eval $(call BuildPackage,luci-httpclient))
$(eval $(call BuildPackage,luci-ipkg))
$(eval $(call BuildPackage,luci-json))
$(eval $(call BuildPackage,luci-lucid))
$(eval $(call BuildPackage,luci-nixio))
$(eval $(call BuildPackage,luci-px5g))
$(eval $(call BuildPackage,luci-uci))
$(eval $(call BuildPackage,luci-sys))
$(eval $(call BuildPackage,luci-web))
$(eval $(call BuildPackage,luci-uvl))

$(eval $(call BuildPackage,luci-httpd))

$(eval $(call BuildPackage,luci-admin-fon))
$(eval $(call BuildPackage,luci-admin-fon_nousb))
$(eval $(call BuildPackage,luci-admin-rpc))
$(eval $(call BuildPackage,luci-admin-fon-rpc))

$(eval $(call BuildPackage,luci-app-youtube))
$(eval $(call BuildPackage,luci-app-openvpn))
$(eval $(call BuildPackage,luci-app-qos))
$(eval $(call BuildPackage,luci-app-ushare))
$(eval $(call BuildPackage,luci-app-upgrade))
$(eval $(call BuildPackage,luci-app-picasa))
$(eval $(call BuildPackage,luci-app-flickr))
$(eval $(call BuildPackage,luci-app-facebook))
$(eval $(call BuildPackage,luci-app-music))
$(eval $(call BuildPackage,luci-app-debug))
$(eval $(call BuildPackage,luci-app-twitter))
$(eval $(call BuildPackage,luci-app-ddns))
$(eval $(call BuildPackage,luci-app-fonfw))
$(eval $(call BuildPackage,luci-app-torrent))
$(eval $(call BuildPackage,luci-app-wizard-fonera2))
#$(eval $(call BuildPackage,luci-app-olpc))
#$(eval $(call BuildPackage,luci-app-bugme-register))
$(eval $(call BuildPackage,luci-app-fonbrowser))
$(eval $(call BuildPackage,luci-app-fonbackup))
$(eval $(call BuildPackage,luci-app-fonprinter))
$(eval $(call BuildPackage,luci-app-fonwebcam))
$(eval $(call BuildPackage,luci-app-fonlivestats))
$(eval $(call BuildPackage,luci-app-downloadmanager))
$(eval $(call BuildPackage,luci-app-ffrpc))
$(eval $(call BuildPackage,luci-app-wol))

$(eval $(call BuildPackage,luci-sgi-cgi))
$(eval $(call BuildPackage,luci-sgi-luci))
$(eval $(call BuildPackage,luci-sgi-webuci))
$(eval $(call BuildPackage,luci-lucittpd))
$(eval $(call BuildPackage,luci-luanet))
$(eval $(call BuildPackage,luci-twitter))
$(eval $(call BuildPackage,luci-uvc))

$(eval $(call BuildPackage,luci-theme-fon))

$(eval $(call BuildPackage,luci-i18n-french))
$(eval $(call BuildPackage,luci-i18n-italian))
$(eval $(call BuildPackage,luci-i18n-german))
$(eval $(call BuildPackage,luci-i18n-portuguese))
$(eval $(call BuildPackage,luci-i18n-zh_tw))
$(eval $(call BuildPackage,luci-i18n-zh_cn))
$(eval $(call BuildPackage,luci-i18n-dutch))
$(eval $(call BuildPackage,luci-i18n-hungarian))
$(eval $(call BuildPackage,luci-i18n-japanese))
$(eval $(call BuildPackage,luci-i18n-basque))
$(eval $(call BuildPackage,luci-i18n-catalan))
$(eval $(call BuildPackage,luci-i18n-polish))
$(eval $(call BuildPackage,luci-i18n-spanish))
$(eval $(call BuildPackage,luci-i18n-english))
