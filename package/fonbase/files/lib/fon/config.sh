#!/bin/sh

# This script contains all kinds of fon-specific configuration stuff. In
# particular, it translates the fon-specific network configuration stuff
# in /etc/config/fon (written by luci) to OpenWRT network configuration
# files in /etc/config/network and /etc/config/wireless (which are again
# processed by ifup, ifdown, /lib/network, /sbin/wifi and /lib/wifi).

. /lib/config/uci.sh
. /etc/functions.sh

# First, set some device-dependent variables, such as interface names.
# This minimizes the device-dependent code below (though not completely
# removes it).

fon_device=$(cat /etc/fon_device)
case "$fon_device" in
	fonera20n)
		lan_ifname="eth0.1"
		wan_ifname="eth0.2"
		wifi_device="rt3052"
		wifi_ifname="ra1"
		private_wifi_ifname="ra0"
		wan_wifi_ifname="apcli0"
		# This variable is used by /etc/init.d/mgmtnetwork
		mgmt_ifname="br-lan"
		# TODO: Seems this one is used by
		# /etc/init.d/chillispot, but it uses a hardcoded ifname
		# for 2.0g. This MAC address should probably be loaded
		# into a uci variable by config_fon or something, so
		# everything (chilli, fonsmcd, registration url, etc.
		# can use it).
		wifi_ifname_mac="ra1"
	;;
	fonera20)
		lan_ifname="eth0.0"
		wan_ifname="eth0.1"
		wifi_device="wifi0"
		wifi_ifname="ath0"
		private_wifi_ifname="ath1"
		wan_wifi_ifname="ath2"
		# This variable is used by /etc/init.d/mgmtnetwork
		mgmt_ifname="br-lan"
	;;
	fonera01)
		lan_ifname="eth0.0"
		wan_ifname="eth0.1"
		wifi_device="radio0"
		wifi_ifname="wlan0"
		private_wifi_ifname="ath1"
		wan_wifi_ifname="ath2"
		# This variable is used by /etc/init.d/mgmtnetwork
		mgmt_ifname="br-lan"
	;;
	*)
		mgmt_ifname="eth0"
		wan_ifname="eth0"
	;;
esac

get_default_psk() {
	# Load the default WPA psk from the boardconfig mtd partition
	case "$fon_device" in
		fonera20n)
			dd if=$(find_mtd_part boardconfig) bs=$((0x1026)) skip=1 count=1 2>/dev/null | head -c10
			;;
		fonera20)
			dd if=$(find_mtd_part boardconfig) bs=$((0x88)) skip=1 count=1 2>/dev/null | head -c10
			;;
		fonera01)
			dd if=$(find_mtd_part boardconfig) bs=$((0x88)) skip=1 count=1 2>/dev/null | head -c10
			;;
	esac
}

load_config() {
	# FON's config network sections have the same name as 
	# the interface groups, so their options will be used
	local OLD_SECTIONS="$CONFIG_SECTIONS"
	NO_CALLBACK=1
	. /etc/config/fon
	unset NO_CALLBACK
	CONFIG_SECTIONS="$OLD_SECTIONS"
}

config_firewall() {
	local M
	. /etc/config/firewall
	uci_remove "firewall" "hotspot_lan"
	uci_remove "firewall" "lan" "masq"
	M=`uci get fon.wan.mode`
	[ "$M" = "bridge" -o "$M" = "wifi-bridge" ] && {
		uci_set "firewall" "lan" "masq" "1"
		uci_add "firewall" "forwarding" "hotspot_lan"
		uci_set "firewall" "hotspot_lan" "src" "hotspot"
		uci_set "firewall" "hotspot_lan" "dest" "lan"
	}
}

# Configure the hardware switch, if needed. This is separate from
# config_network below, since it must be run at boot after the ethernet
# driver was loaded, while config_network is run before.
config_switch() {
	local wanmode wan_as_lan
	config_get wanmode wan mode
	# This settings determines if the wan port should be used as a
	# lan port, or remain unused (in wifi mode).
	config_get wan_as_lan wan wan_as_lan

	case "$fon_device" in
		fonera20n)
			if [ "$wanmode" = "bridge" -o \( "$wanmode" = "wifi" -a "$wan_as_lan" = "1" \) -o "$wanmode" = "wifi-bridge" ]; then
				# Configure the hardware switch to move
				# port 4 (the WAN port) to VLAN 1 (the
				# LAN vlan)
				switch vlan set 0 1 1111111
				switch vlan set 1 2 0000011
				switch reg w 48 1001
			else
				# Configure the hardware switch to move
				# port 4 (the WAN port) to VLAN 2 (the
				# WAN vlan)
				switch vlan set 0 1 1111011
				switch vlan set 1 2 0000111
				switch reg w 48 1002
			fi
			;;

		*)
			# There is no hardware switch in other devices
			;;
	esac
}

config_network() {
	local wanmode lanip lanmask langateway landns wanmacaddr mtu
	local wifiproto wanproto hostname mac wanip wanmask wangateway
	local wandns wanusername wanpassword wanpptp_server wan_as_lan

	config_get wanmode wan mode

	###################################
	# Setup the loopback network
	###################################
	uci_remove "network" "loopback" 2> /dev/null
	uci_add "network" "interface" "loopback"
	uci_set "network" "loopback" "proto" "static"
	uci_set "network" "loopback" "ifname" "lo"
	uci_set "network" "loopback" "ipaddr" "127.0.0.1"
	uci_set "network" "loopback" "netmask" "255.255.255.0"

	###################################
	# Setup bridging
	###################################

	# By default, add only the lan port(s) to the lan bridge (the
	# wifi interface will be added later when it is brought up,
	# since it references the "lan" network in /etc/config/wireless)
	lan_devs="$lan_ifname"

	# In bridge mode and wifi mode, we turn the WAN port
	# into a LAN port. In bridge and wifi-bridge mode, there is
	# additional setup below to disable the wan network alltogether

	case "$fon_device" in
		fonera20n)
			# Set up the hardware switch
			config_switch
			;;
		*)
			# This settings determines if the wan port should be used as a
			# lan port, or remain unused (in wifi mode).
			config_get wan_as_lan wan wan_as_lan

			if [ "$wanmode" = "bridge" -o \( "$wanmode" = "wifi" -a "$wan_as_lan" = "1" \) -o "$wanmode" = "wifi-bridge" ]; then
				# Add the wan device to the lan bridge
				# so we have software bridging.
				lan_devs="$lan_devs $wan_ifname"
			fi
			;;
	esac

	###################################
	# Setup the lan network
	###################################
	uci_remove "network" "lan" 2> /dev/null

	# The lan network is always a bridge with a static address
	uci_add "network" "interface" "lan"
	uci_set "network" "lan" "type" "bridge"
	uci_set "network" "lan" "proto" "static"

	if [ "$wanmode" == "bridge" -o "$wanmode" == "wifi-bridge" ]; then
		# In bridge mode, use the static address from the WAN
		# configuration for the LAN interface.
		config_get lanip wan ipaddr
		config_get lanmask wan netmask
		config_get langateway wan gateway
		config_get landns wan dns
	else
		# In all other cases, just use the ip addr / netmask from
		# the LAN configuration.
		config_get lanip lan ipaddr
		config_get lanmask lan netmask
	fi

	uci_set "network" "lan" "ifname" "$lan_devs"
	uci_set "network" "lan" "ipaddr" "${lanip:-192.168.0.250}"
	uci_set "network" "lan" "netmask" "${lanmask:-255.255.255.0}"
	[ -n "$langateway" ] && uci_set "network" "lan" "gateway" "$langateway"
	[ -n  "$landns" ] && uci_set "network" "lan" "dns" "$landns"

	###################################
	# Setup the wan network
	###################################
	uci_remove "network" "wan" 2> /dev/null

	uci_add "network" "interface" "wan"

	# Set the wan ifname
	case "$wanmode" in
		wifi)
			uci_set "network" "wan" "ifname" "$wan_wifi_ifname"
			# Note that we don't set the wan_wifi_ifname in
			# the wan network in wifi-bridge mode, since
			# ap_client always runs ifup wan, which would
			# destroy the bridge config created by the wifi
			# scripts...
			;;
		umts)
			uci_set "network" "wan" "ifname" "ppp-wan"
			;;
		*)
			uci_set "network" "wan" "ifname" "$wan_ifname"

			# Allow overriding the WAN mac address for every mode that
			# actually uses the WAN ethernet interface
			config_get wanmacaddr wan macaddr
			[ -n "$wanmacaddr" ] && uci_set "network" "wan" "macaddr" "$wanmacaddr"
			;;
	esac

	# Set the wan proto
	case "$wanmode" in
		wifi)
			# For wifi-wan mode, wmode (which can be
			# static or dhcp) determines how to
			# actually configure the interface.
			config_get wifiproto wan wmode
			wanproto="${wifiproto:-dhcp}"
			;;
		bridge | wifi-bridge)
			# For bridge mode, disable the wan network. Note
			# that we can't completely remove the network
			# (which would be more appropriate), since that
			# will prevent ConfigWan from deconfiguring the
			# old address, resulting in a broken network
			# when switching to bridge mode.
			wanproto="none"
			;;
		*)
			# For all others, just use the wanmode
			# as the wan proto
			wanproto="${wanmode:-dhcp}"
			;;
	esac
	uci_set "network" "wan" "proto" "$wanproto"

	# Set other relevant variables. Note that we switch on
	# $wanproto now instead of wanmode, so we do the setup
	# for the actually used proto instead of the configured
	# mode (which will be different in wifi-wan mode, for
	# example).
	case "$wanproto" in
		dhcp)
			# This hostname is used in DHCP requests
			hostname=`uci get system.@system[0].hostname`
			mac=`ifconfig $wan_ifname | grep HWaddr| sed "s/.*HWaddr //g" |sed "s/://g"`
			uci_set "network" "wan" "hostname" "${hostname}-${mac}"
			# Note that the dns_static option set by
			# luci is processed by
			# /usr/share/udhcpc/default.script
			# directly.
			;;
		static)
			config_get wanip wan ipaddr
			config_get wanmask wan netmask
			config_get wangateway wan gateway
			config_get wandns wan dns
			uci_set "network" "wan" "ipaddr" "$wanip"
			uci_set "network" "wan" "netmask" "${wanmask:-255.255.255.0}"
			uci_set "network" "wan" "gateway" "$wangateway"
			uci_set "network" "wan" "dns" "$wandns"
			;;
		pptp)
			# This section is a bit messy, because it seems to
			# be unused (there doesn't seem to actually be any
			# code to handle the pptp case in /lib/network)?
			config_get wanusername wan username
			config_get wanpassword wan password
			config_get wanpptp_server wan pptp_server
			uci_set "network" "wan" "username" "$wanusername"
			uci_set "network" "wan" "password" "$wanpassword"
			uci_set "network" "wan" "device" "eth0.2"
			uci_set "network" "wan" "ipproto" "dhcp"
			uci_set "network" "wan" "server" "$wanpptp_server"
			# TODO: mtu2 variable is set by luci but ignored
			# here?
			;;
		pppoe)
			config_get wanusername wan username
			config_get wanpassword wan password
			config_get wandns wan dns_static
			config_get mtu wan mtu
			uci_set "network" "wan" "username" "$wanusername"
			uci_set "network" "wan" "password" "$wanpassword"
			if [ -z "$wandns" -o "$wandns" = "0" ]; then
				uci_set "network" "wan" "peerdns" "1"
			else
				uci_set "network" "wan" "dns" "$wandns"
				uci_set "network" "wan" "peerdns" "0"
			fi
			uci_set "network" "wan" "mtu" "$mtu"
			;;
		wifi)
			;;
		umts)
			uci_set "network" "wan" "udiald_device" $(config_get wan umts_device)
			uci_set "network" "wan" "udiald_apn" $(config_get advanced umts_apn)
			uci_set "network" "wan" "udiald_pin" $(config_get advanced umts_pin)
			uci_set "network" "wan" "udiald_user" $(config_get advanced umts_user)
			uci_set "network" "wan" "udiald_pass" $(config_get advanced umts_pass)
			uci_set "network" "wan" "udiald_mode" $(config_get advanced umts_mode)
			uci_set "network" "wan" "udiald_verbosity" $(config_get advanced umts_verbosity)
			config_get dns advanced umts_dns
			if [ "$dns" = "0" ]; then # Use provider default DNS
				config_get dns advanced umts_custom_dns
			fi
			if [ "$dns" = "1" ]; then # Automatic DNS
				dns=""
			fi
			# This one is processed by /etc/ppp/ip-up.d/10-umts
			uci_set "network" "wan" "dns" "$dns"
			if [ "$dns" != "" ]; then # Static DNS specified, don't ask peer for one
				uci_set "network" "wan" "usepeerdns" "0"
			fi
			;;
		none)
			;;
	esac

	# Don't bring up the wan interface automatically. This will
	# be done by a switch hotplug script when a cable is plugged in,
	# or when the ttyUSB umts device is ready, etc.
	uci_set "network" "wan" "auto" "0"


	###################################
	# Setup the hotspot network
	###################################

	# This network is configured by chillispot
	uci_remove "network" "hotspot" 2> /dev/null
	uci_add "network" "interface" "hotspot"
	uci_set "network" "hotspot" "ifname" "tun0"
	uci_set "network" "hotspot" "proto" "none"

	# This is a dummy network referred to by the "public" wifi-iface
	# below in config_wireless
	uci_remove "network" "hotspotwifi" 2> /dev/null
	uci_add "network" "interface" "hotspotwifi"
	uci_set "network" "hotspotwifi" "proto" "none"

	uci commit network
}

config_wireless() {
	local mode channel ht country diversity rtxant ssid encryption
	local wpa_crypto enc pwd key mode auth crypt

	###################################
	# Setup the wifi device
	###################################
	config_get channel advanced channel
	config_get mode advanced bgmode
	uci_add "wireless" "wifi-device" "$wifi_device"
	uci_set "wireless" "$wifi_device" "channel" "$channel"
	case $fon_device in
		fonera20n)
			config_get ht advanced ht
			config_get country advanced country
			# Lookup the regdomain for the country
			regdom=$(echo "for i, v in ipairs(loadfile('/etc/3166en.db.lua')()) do if v[1] == '$country' then print(v[3]) end end" | lua)
			uci_set "wireless" "$wifi_device" "type" "rt3052"
			uci_set "wireless" "$wifi_device" "ht" "${ht:-40}"
			uci_set "wireless" "$wifi_device" "country" "${country}"
			uci_set "wireless" "$wifi_device" "regdom" "${regdom:-0}"
			uci_set "wireless" "$wifi_device" "mode" "$mode"
			local wifi_switch=`cat /proc/gpio_switch`
			uci_set "wireless" "$wifi_device" "disabled" "${wifi_switch:-0}"
			;;
		fonera20)
			config_get diversity advanced diversity
			config_get rtxant advanced rtxant
			case "$mode" in
				B|b) mode=11b;;
				G|g) mode=11g;;
				*) mode=auto;;
			esac
			uci_set "wireless" "$wifi_device" "type" "atheros"
			uci_set "wireless" "$wifi_device" "mode" "$mode"
			uci_set "wireless" "$wifi_device" "diversity" "$diversity"
			uci_set "wireless" "$wifi_device" "rxantenna" "$rtxant"
			uci_set "wireless" "$wifi_device" "txantenna" "$rtxant"
			uci_remove "wireless" "$wifi_device" "disabled" 2> /dev/null
			;;
		fonera01)
			config_get diversity advanced diversity
			config_get rtxant advanced rtxant
			case "$mode" in
				B|b) mode=11b;;
				G|g) mode=11g;;
				N|n) mode=11n;;
				*) mode=auto;;
			esac
			uci_set "wireless" "$wifi_device" "type" "atheros"
			uci_set "wireless" "$wifi_device" "mode" "$mode"
			uci_set "wireless" "$wifi_device" "diversity" "$diversity"
			uci_set "wireless" "$wifi_device" "rxantenna" "$rtxant"
			uci_set "wireless" "$wifi_device" "txantenna" "$rtxant"
			uci_remove "wireless" "$wifi_device" "disabled" 2> /dev/null
			;;
	esac

	###################################
	# Setup the public wifi network
	###################################
	uci_remove "wireless" "public" 2> /dev/null
	uci_add "wireless" "wifi-iface" "public"
	uci_set "wireless" "public" "device" "$wifi_device"
	uci_set "wireless" "public" "ifname" "$wifi_ifname"
	uci_set "wireless" "public" "network" "hotspotwifi"
	uci_set "wireless" "public" "mode" "ap"
	uci_set "wireless" "public" "ssid" "off"
	uci_set "wireless" "public" "hidden" "0"
	uci_set "wireless" "public" "encryption" "none"
	uci_set "wireless" "public" "isolate" "1"

	###################################
	# Setup the private wifi network
	###################################
	config_get ssid private essid
	config_get encryption private encryption
	config_get wpa_crypto private wpa_crypto
	config_get disable_wps private disable_wps
	uci_remove "wireless" "private" 2> /dev/null
	uci_add "wireless" "wifi-iface" "private"
	uci_set "wireless" "private" "device" "$wifi_device"
	uci_set "wireless" "private" "ifname" "$private_wifi_ifname"
	uci_set "wireless" "private" "network" "lan"
	uci_set "wireless" "private" "mode" "ap"
	uci_set "wireless" "private" "ssid" "$ssid"
	uci_set "wireless" "private" "hidden" "0"

	case "$encryption" in
		wpa*|WPA*|Mixed|mixed)
			case "$fon_device" in
				# The ra_wifi and madwifi / hostapd
				# driver scripts accept their wpa
				# parameters in different formats.
				# Perhaps this should be unified
				# sometime.
				fonera20n)
					uci_set "wireless" "private" "encryption" "$encryption"
					uci_set "wireless" "private" "wpa_crypto" "$wpa_crypto"

					if [ "$disable_wps" == "1" ]; then
						uci_set "wireless" "private" "wps" "0"
					else
						uci_set "wireless" "private" "wps" "1"
					fi

					;;
				fonera20)
					case "$encryption" in
						WPA|WPA1|wpa|wpa1) enc=psk;;
						WPA2|wpa2) enc=psk2;;
						Mixed|mixed) enc=psk-mixed;;
					esac
					uci_set "wireless" "private" "encryption" "$enc${wpa_crypto:+/$wpa_crypto}"
					;;
				fonera01)
					case "$encryption" in
						WPA|WPA1|wpa|wpa1) enc=psk;;
						WPA2|wpa2) enc=psk2;;
						Mixed|mixed) enc=psk-mixed;;
					esac
					uci_set "wireless" "private" "encryption" "$enc${wpa_crypto:+/$wpa_crypto}"
					;;
			esac
			pwd=`/sbin/uci get fon.private.password`
			uci_set "wireless" "private" "key" "$pwd"
		;;
		WEP|wep)
			config_get key private key
			uci_set "wireless" "private" "encryption" "wep"
			uci_set "wireless" "private" "key" "1"
			uci_set "wireless" "private" "key1" "$key"
		;;
		open|none)
			uci_set "wireless" "private" "encryption" "none"
		;;
	esac

	###################################
	# Setup the wifi client interface
	# for wifi-wan mode, if enabled.
	###################################

	config_get mode wan mode
	uci_remove "wireless" "uplink" 2> /dev/null
	uci_add "wireless" "wifi-iface" "uplink"
	uci_set "wireless" "uplink" "device" "$wifi_device"
	uci_set "wireless" "uplink" "ifname" "$wan_wifi_ifname"
	uci_set "wireless" "uplink" "mode" "sta"
	[ "$mode" == "wifi" -o "$mode" == "wifi-bridge" ] && {
		config_get ssid wan ssid
		config_get auth wan auth
		config_get channel wan channel
		if [ "$mode" == "wifi" ]; then
			uci_set "wireless" "uplink" "network" "wan"
		else
			# In wifi-bridge mode, the wifi-wan interface
			# should get bridged into the lan network
			uci_set "wireless" "uplink" "network" "lan"
		fi
		uci_set "wireless" "uplink" "ssid" "$ssid"
		uci_set "wireless" "uplink" "hidden" "0"
		# TODO: Is this needed just for 2.0n?
		[ "$fon_device" = "fonera20n" ] && uci_set "wireless" "$wifi_device" "channel" "$channel"
		case "$auth" in
			wpa*|WPA*|Mixed|mixed)
				case "$fon_device" in
					fonera20n)
						case "$auth" in
							WPA|WPA1|wpa|wpa1) enc=WPAPSK;;
							*) enc=WPA2PSK;;
						esac
						config_get crypto wan crypto
						case "$crypto" in
							aes|AES) crypt=AES;;
							*) crypt=TKIP;;
						esac
						uci_set "wireless" "uplink" "wpa_crypto" "$crypt"
						;;
					fonera20)
						case "$auth" in
							WPA|WPA1|wpa|wpa1) enc=psk;;
							WPA2|wpa2) enc=psk2;;
							Mixed|mixed) enc=psk-mixed;;
						esac
						;;
					fonera01)
						case "$auth" in
							WPA|WPA1|wpa|wpa1) enc=psk;;
							WPA2|wpa2) enc=psk2;;
							Mixed|mixed) enc=psk-mixed;;
						esac
						;;
				esac
				uci_set "wireless" "uplink" "encryption" "$enc"
				pwd=`/sbin/uci get fon.wan.psk`
				uci_set "wireless" "uplink" "key" "$pwd"
			;;
			WEP|wep)
				config_get key wan key1
				uci_set "wireless" "uplink" "encryption" "WEP"
				uci_set "wireless" "uplink" "key" "1"
				uci_set "wireless" "uplink" "key1" "$key"
			;;
			open|none)
				uci_set "wireless" "uplink" "encryption" "OPEN"
			;;
		esac
	}

	uci commit wireless
}

config_dhcp() {
	local enable dhcp

	dhcp=`uci get fon.lan.dhcp`
	mode=`uci get fon.wan.mode`
	if [ "$dhcp" -eq 0 -o "$mode" = "bridge" -o "$mode" = "wifi-bridge" ]; then
		uci_set "dhcp" "lan" "ignore" "1"
	else
		uci_remove "dhcp" "lan" "ignore"
	fi
}

config_fon() {
	# This is called exactly once after a firmware flash or factory
	# reset, to set the initial wpa psk. In 2.0g this happens to be
	# the serial number as well, but for 2.0n this is a different
	# number.
	local default_psk psk
	psk=`uci -q get fon.private.password`
	default_psk=`get_default_psk`

	# Set the current wpa PSK if none is set yet. We need to check
	# this, since we are also called after a firmware update that
	# preserved the fon config file. We don't want to overwrite a
	# psk set by the user.
	if [ -z "$psk"]; then
		# Note that this is not the admin password, as
		# the name might suggest, but the wifi PSK. 
		uci_set "fon" "private" "password"  "$default_psk"
	fi

	# Also store the default psk separately, which is used as
	# a default after switch (back) to wpa.
	uci_set "fon" "private" "default_psk"  "$default_psk"
}

config_umts() {
	# This is called on startup, to remove the umts mode (just like
	# /etc/hotplug/usb/10-umts does when the stick is unplugged).
	WAN=`uci get fon.wan.mode`
	if [ "$WAN" = "umts" ]; then
		# Restore the old mode, or dhcp if no old mode is set
		# (the latter should never happen)
		OLDWAN=`uci get fon.wan.old_mode`
		uci set fon.wan.mode=${OLDWAN:-dhcp}
		uci del fon.wan.old_mode
		uci del fon.wan.umts_device

		uci commit fon
	fi
}

config_timezone() {
	config_get timezone advanced timezone
	if [ -n "$timezone" ]; then
		tzdesc=$(cat /etc/timezones.db | awk "\$1 == \"$timezone\" {print \$2}")
		# /etc/init.d/boot takes care of putting this in /etc/TZ
		uci_set "system" "@system[0]" "timezone" "$tzdesc"
		uci commit system
	fi
}

load_config

case "$1" in
	network)
		# Make sure fonsmcd is started or stopped appropriately
		# (StartFonsmcd also stops it if wifi or sharing is
		# disabled).
		fs -l StartFonsmcd
		config_network;;
	wireless) config_wireless;;
	dhcp) config_dhcp;;
	fon) config_fon;;
	firewall) config_firewall;;
	3g) config_umts;;
	switch) config_switch;;
	timezone) config_timezone;;
	*) true;;
esac


# vim: set ts=8 sw=8 sts=8 noexpandtab:
