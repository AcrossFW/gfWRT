#!/usr/bin/env bash
#
# gfWRT - WirelessRouTer for your GirlFriend!
# https://github.com/acrossfw/gfWRT
#
# Copyright AcrossFW 2016
# License APACHE-2.0 
# https://www.acrossfw.com
#
# this script can help you turn a OpenWRT v15 to gfWRT v1 on D-Link DIR-505
#
set -euo pipefail
IFS=$'\n\t'

source ../src/dlink-lib.sh

main() {
  dlink::login "$@"
  dlink::firmware_upload 'openwrt-15.05.1-ar71xx-generic-dir-505-a1-squashfs-factory.bin'
  dlink::firmware_upgrade
  dlink::reboot
}

main "$@"
