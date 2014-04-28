#!/bin/ash

# This script upgrades configuration files, as required by the currently
# running firmware. It will be run after every firmware upgrade and
# every settings restore.
# Since we can't tell from which version we are upgrading / restoring
# (could be very old or even the same version as the current firmware),
# this script should handle all possible configurations and be
# idempotent.

. /etc/functions.sh

# In 2.3.7.0 beta3, ddns was switched from ez-ipupdate to ddns-script.
# If the ddns config does not contain a new-style config section, for
# use with ddns-scripts, have one created (and preserve the settings, if
# any).
config_load 'ddns'
if [ -z "$(config_get ddns_scripts TYPE)" ]; then
	uci set ddns.ddns_scripts=service
	srv="$(config_get ddns srv)"
	if [ -n "$srv" -a "$srv" != "none" ]; then
		uci set 'ddns.ddns_scripts.enabled=1'
		uci set 'ddns.ddns_scripts.service_name=dyndns.org'
		uci set "ddns.ddns_scripts.username=$(config_get ddns user)"
		uci set "ddns.ddns_scripts.password=$(config_get ddns pass)"
		uci set "ddns.ddns_scripts.domain=$(config_get ddns dns)"
		uci set 'ddns.ddns_scripts.ip_source=none'
	fi
	uci delete ddns.ddns
	uci commit ddns
fi
config_clear

# Firmware 2.3.7.0 did not properly backs up the OpenVPN port numbers in
# /etc/config/services. As of 2.3.8.0, the port numbers in
# /etc/config/services are no longer backed up at all. In either case,
# the port number is backed up properly in /etc/config/openvpn, so run
# this script to update the services config as well.
/etc/fonstated/ReconfOpenVPN"
