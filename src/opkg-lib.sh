#!/usr/bin/env bash
#
# gfWRT - WirelessRouTer for your GirlFriend!
# https://github.com/acrossfw/gfWRT
#
# Copyright AcrossFW 2016
# License APACHE-2.0 
# https://www.acrossfw.com
#
# opkg Library for gfWRT
#
set -euo pipefail
IFS=$'\n\t'

opkg::init() { 
  ssh::ssh <<_CMD_
    [ -d /tmp/gfwrt ] || mkdir /tmp/gfwrt/
    sed -i s/"check_signature .*$"/"check_signature 0"/ /etc/opkg.conf
    echo 'src/gz openwrt_dist http://openwrt-dist.sourceforge.net/releases/ar71xx/packages' >> /etc/opkg/customfeeds.conf
    echo 'src/gz openwrt_dist_luci http://openwrt-dist.sourceforge.net/releases/luci/packages' >> /etc/opkg/customfeeds.conf
_CMD_
}

opkg::install() {
  [[ -d "./ipk/" ]] || {
    gfwrt::log "ERROR: gfwrt::install ./ipk/ not found"
    return -1
  }
  ssh::scp -r ./ipk/ "$(ssh::user)@$(ssh::host):/tmp/ipk/"
  ssh::ssh <<_CMD_
    opkg install /tmp/ipk/*.ipk
    # rm -fr /tmp/ipk/
_CMD_
}
