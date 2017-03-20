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

source src/gfwrt-lib.sh
source src/ssh-lib.sh
source src/uci-lib.sh
source src/opkg-lib.sh

OPENWRT_DEFAULT_IP='192.168.1.1'

GFWRT_DEFAULT_PASS='vpnet.io'
GFWRT_DEFAULT_SSID='gfWRT'
GFWRT_AUTHORIZRD_KEYS='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6GRsnNc1judMmIFeYzu02KbkkWW0mkrOusAe1kdEW9MeXIgq4cOjMMYHGHLxQR+WU4/yexpKdBlDUNSJiw7uSTyGl0ORwwKZfAeMlaFWRCtIrPh1DBugjZQKcAxoKaMeH2lzHIj5H/tCrgyjmQ6foUG70cKFQFtp6+aSURr1Oj12mQGD/JsfTRw2nnLdDA7TEV9SmhThliu7voq/u50doZjutFmASQVJJ+QD2jISyc7DGudVoQWNqsy6fJyHqnFKWpvlLMw22MgXOJEKpGS616jHGLqwvCCFghSl2+Dh3XVkhtL5WV9mU0dyqcesr347TH7FtVwufhI7yArU7+qin dev@acrossfw.com'

SHADOWSOCKS_SERVER='8.8.8.8'
SHADOWSOCKS_PORT='18388'
SHADOWSOCKS_PASS='vpnet.io'
SHADOWSOCKS_ENCRYPT_METHOD='salsa20'

main() {
  gfwrt::create_password "$OPENWRT_DEFAULT_IP" "$GFWRT_DEFAULT_PASS"
  ssh::init "$OPENWRT_DEFAULT_IP:22" "root:$GFWRT_DEFAULT_PASS" ~/.ssh/afw.id_rsa "$GFWRT_AUTHORIZRD_KEYS"

  opkg::init
  opkg::install

  uci::main
  
  gfwrt::service shadowsocks reload
  gfwrt::service shadowsocks enable

  gfwrt::service chinadns reload
  gfwrt::service chinadns enable || true # bug compatible with chinadns, which will return 1 ?

  gfwrt::service system reload
  gfwrt::service dropbear reload
  gfwrt::service network reload
  
  echo '#######################################################'
  echo ' Congratulations, gfWRT is ready for your Girl Friend! '
  echo
  echo ' gfWRT Default Setting: '
  echo " 1. Wifi SSID ${GFWRT_DEFAULT_SSID}-XXXX"
  echo " 2. Password $GFWRT_DEFAULT_PASS"
  echo " 3. IP Address $OPENWRT_DEFAULT_IP"
  echo
  echo ' Now Network is Reloading ... '
  echo ' Please wait 30-60 seconds ... '
  echo '#######################################################'
}

main "$@"
