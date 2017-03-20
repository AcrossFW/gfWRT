#!/usr/bin/env bash
#
# gfWRT - WirelessRouTer for your GirlFriend!
# https://github.com/acrossfw/gfWRT
#
# Copyright AcrossFW 2016
# License APACHE-2.0 
# https://www.acrossfw.com
#
# UCI Library for gfWRT
#
set -euo pipefail
IFS=$'\n\t'

uci::main() {
  uci::system
  uci::network
  uci::firewall
  uci::dns
  uci::shadowsocks

  uci::apply_id
  uci::commit
}

uci::system() {
  ssh::ssh "uci batch" <<_UCI_BATCH_
    rename system.@system[0]='setting'

    rename dropbear.@dropbear[0]='setting'
    # Case Sensitive in DropBear
    set dropbear.setting.PasswordAuth='off'
_UCI_BATCH_
}

uci::network() {
  ssh::ssh "uci batch" <<_UCI_BATCH_
    set network.wwan=interface
    set network.wwan.proto=dhcp

    set wireless.radio0.channel='auto'
    set wireless.radio0.disabled='0'

    rename wireless.@wifi-iface[0]='ap' 
    set wireless.ap.mode='ap'
    set wireless.ap.encryption='psk2'
    set wireless.ap.disabled='0'
    set wireless.ap.ssid='$GFWRT_DEFAULT_SSID'
    set wireless.ap.key='$GFWRT_DEFAULT_PASS'
    set wireless.ap.network='lan'

    add wireless wifi-iface
    rename wireless.@wifi-iface[-1]='client'
    set wireless.client.network='wwan'
    set wireless.client.mode='sta'
    set wireless.client.disabled='1'
    set wireless.client.ssid='VPNet'
    set wireless.client.encryption='psk2'
    set wireless.client.device='radio0'
    set wireless.client.key='vpnet.io'
    set wireless.client.network='wwan'
_UCI_BATCH_
}

uci::firewall() {
  uci::firewall_rename_zone_wan
  ssh::ssh "uci batch" <<_UCI_BATCH_
    delete firewall.wan.network
    add_list firewall.wan.network='wan'
    add_list firewall.wan.network='wan6'
    add_list firewall.wan.network='wwan'    
_UCI_BATCH_
}

uci::firewall_rename_zone_wan() {
  # No expand here. because it need run inside WRT
  ssh::ssh <<'_CMD_'
    [ `uci get firewall.wan.name` = 'wan' ] || {
      FIREWALL_ZONE=`uci show firewall | grep 'firewall.@zone' | grep -i '\.name=.*wan'`
      FIREWALL_ZONE="${FIREWALL_ZONE%.name=*}"
      uci rename "$FIREWALL_ZONE"='wan'
    }
_CMD_
}

uci::dns() {
  ssh::ssh "uci batch" <<_UCI_BATCH_
    rename dhcp.@dnsmasq[0]='dnsmasq'
    set dhcp.dnsmasq.noresolv='1'
    delete dhcp.dnsmasq.server
    add_list dhcp.dnsmasq.server='127.0.0.1#5353'

    rename chinadns.@chinadns[0]='setting'
    set chinadns.setting.enable='1'
    set chinadns.setting.bidirectional='1'
    set chinadns.setting.chnroute='/etc/chinadns_chnroute.txt'
    set chinadns.setting.port='5353'
    set chinadns.setting.server='114.114.114.114,127.0.0.1:5300'
_UCI_BATCH_
}

uci::shadowsocks() {
  ssh::ssh "uci batch" <<_UCI_BATCH_
    rename shadowsocks.@servers[0]='server'
    rename shadowsocks.@port_forward[0]='dns'
    rename shadowsocks.@access_control[0]='ac'
    rename shadowsocks.@global[0]='setting'

    set shadowsocks.setting=global
    set shadowsocks.setting.global_server='server'
    set shadowsocks.setting.udp_relay_server='same'

    set shadowsocks.server.alias='ss'
    set shadowsocks.server.auth_enable='1'
    set shadowsocks.server.auth='1'
    set shadowsocks.server.server='$SHADOWSOCKS_SERVER'
    set shadowsocks.server.server_port='$SHADOWSOCKS_PORT'
    set shadowsocks.server.local_port='1080'
    set shadowsocks.server.password='$SHADOWSOCKS_PASS'
    set shadowsocks.server.timeout='60'
    set shadowsocks.server.encrypt_method='$SHADOWSOCKS_ENCRYPT_METHOD'

    set shadowsocks.dns.enable='1'
    set shadowsocks.dns.local_port='5300'
    set shadowsocks.dns.destination='8.8.4.4:53'

    set shadowsocks.ac.wan_bp_list='/etc/chinadns_chnroute.txt'
    set shadowsocks.ac.lan_target='SS_SPEC_WAN_AC'
_UCI_BATCH_
}

uci::commit() {
  ssh::ssh uci commit "$@"
}

uci::revert() {
  ssh::ssh uci revert "$@"
}

#
# post uci script(in here document) must NOT expand in this script
# it should expand inside gfWRT
#
uci::apply_id() {
  ssh::ssh <<'_CMD_NO_EXPANSION_'
    ap_id=$(ip addr show $(awk 'NR==3{print $1}' /proc/net/wireless \
      | tr -d :) | grep ether | awk '{print $2}' | awk -F: '{print $5$6}')
    ssid="$(uci get wireless.ap.ssid)-${ap_id:-ERROR}"
    uci set wireless.ap.ssid="$ssid"
    uci set system.setting.hostname="$ssid"
_CMD_NO_EXPANSION_
}
