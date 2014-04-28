#!/bin/ash

# This script creates a file /tmp/sysupgrade.tgz containing all relevant
# settings to be backed up. This is done mostly by putting complete
# files into the tarball. However, some files in /etc/config only need
# to be backed up partially (because only a small part is
# user-changeable and the rest could change between firmware versions).
# For this reason, there is an embedded script below, that generates
# some uci commands to restore just those settings. These commands are
# stored in /etc/uci-defaults/zzz-upgrade, where they will  be run at
# next boot (after an upgrade) or by luci (after a settings restore).

# Also note that this script is shipped in the main firmware for the
# settings backup through the webgui, but also copied into the tarballs
# for firmware releases.

# This is the embedded script that cherry-picks various config options.
sh << 'END_OF_SUBSCRIPT' > /etc/uci-defaults/zzz-upgrade
. /etc/functions.sh

# Preserve the pass_good variable, which seems to be the only
# user-settable setting in the system config.
config_load 'system'

if [ "$(config_get fon pass_good)" = "1" ]; then
    echo "uci set system.fon.pass_good=1"
    echo "uci commit system"
fi

config_clear

# Preserve the per-service 'fwall' setting, which seems to be the only
# user-settable setting from the services config.
echo "uci import -m services <<EOF"
config_load 'services'
save_service() {
    val="$(config_get "$1" 'fwall')"
    if [ -n "$val" ]; then
	echo "config 'service' '$1'"
	echo "	option 'fwall' '$val'"
    fi
}
config_foreach save_service 'service'
config_clear

echo "EOF"
echo "uci commit services"

# Backup firewall settings for fmg images (just torrent is supported
# right now)
config_load 'fmg'
echo "uci set fmg.torrent.fwall=$(config_get torrent fwall)"
echo "uci commit fmg"
config_clear

# Preserve all port forwards (redirect sections) from the firewall
# config. This is the only part of the firewall config that can be
# changed by the user. By not backing up the rest of the file, we
# prevent problems with changes made to the (default) firewall config in
# r1585 and r1857 that would be overwritten when backing up the complete
# file.
echo "uci import -m firewall <<EOF"
config_cb() {
    [ "$1" = "redirect" ] && echo "config '$1' '$2'"
}

option_cb() {
    local type=$(config_get "$CONFIG_SECTION" TYPE)
    [ "$type" = "redirect" ] &&
	echo "	option '$1' '$2'"
}


config_load 'firewall'
config_clear
echo "EOF"
echo "uci commit firewall"
reset_cb

# Preserve all download and cookie sections from the dlmanager config.
# This allows new providers to be added, without throwing away the
# existing cookies (logins) and downloads. We use the callbacks instead
# of foreach here, since we don't know all of the option names in
# advance.
echo "uci import -m luci_dlmanager <<EOF"
config_cb() {
    [ "$1" = "cookie" -o "$1" = "download" ] && echo "config '$1' '$2'"
}

option_cb() {
    local type=$(config_get "$CONFIG_SECTION" TYPE)
    [ "$type" = "cookie" -o  "$type" = "download" ] && 
	echo "	option '$1' '$2'"
}


config_load 'luci_dlmanager'
# Also keep some dlmanager settings
echo "config 'dlmanager' 'dlmanager'"
echo "	option base '$(config_get dlmanager base)'"
echo "	option threads '$(config_get dlmanager threads)'"
echo "	option when '$(config_get dlmanager when)'"
echo "EOF"
echo "uci commit luci_dlmanager"
config_clear
reset_cb

# Save qos settings
config_load 'qos'

echo "uci set 'qos.wan.enabled=$(config_get wan enabled)'"
echo "uci set 'qos.wan.download=$(config_get wan download)'"
echo "uci set 'qos.wan.upload=$(config_get wan upload)'"
echo "uci commit qos"

config_clear

# Keep OpenVPN settings
config_load 'openvpn'

echo "uci import -m openvpn <<EOF"
echo "config 'openvpn' 'openvpn'"
for o in enable lan wan keepalive max_clients proto port tls_auth client_to_client public; do
	echo "	option '$o' '$(config_get openvpn $o)'"
done
save_client() {
    echo "config 'client' '$1'"
    echo "	option 'name' '$(config_get "$1" name)'"
    echo "	option 'ip' '$(config_get "$1" ip)'"
}
config_foreach save_client 'client'
echo "EOF"
echo "uci commit openvpn"
config_clear

# Save luci language setting
config_load 'luci'

echo "uci set luci.main.lang=$(config_get main lang)"
echo "uci commit luci"

config_clear

END_OF_SUBSCRIPT

# Create the tarball, containing a bunch of complete config files and
# the above generated uci commands.
tar cvzf /tmp/sysupgrade.tgz /etc/uci-defaults /etc/passwd /etc/group /etc/dropbear /etc/samba/smbpasswd /etc/samba/secrets.tdb /etc/firewall.user /etc/config/upnpd /etc/config/registered /etc/config/gdata /etc/config/facebook /etc/config/flickr /etc/config/mountd /etc/config/fon /etc/config/ddns /etc/config/wizard /etc/pureftpd.passwd /etc/pureftpd.pdb /etc/config/pureftpd /etc/config/samba /etc/config/twitter /etc/config/luci_ethers /etc/openvpn/keys /etc/config/uploadd /etc/nixio /etc/config/luci_wol

# Rememove the zzz-upgrade file again. It ended up in the tarball, no
# need to run it again on the next upgrade.
rm /etc/uci-defaults/zzz-upgrade
