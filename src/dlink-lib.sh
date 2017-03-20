#!/usr/bin/env bash
#
# gfWRT - WirelessRouTer for your GirlFriend!
# https://github.com/acrossfw/gfWRT
#
#
# Copyright AcrossFW 2016
# License APACHE-2.0 
# https://www.acrossfw.com
#
# D-Link Lib for gfWRT
#
set -euo pipefail
IFS=$'\n\t'

dlink::login() {
  local dlink_ip=${1:-}
  local userpass=${2:-}

  [[ ! "$dlink_ip" ]] || [[ ! "userpass" ]] && {
    printf "ERROR: dlink::login <dlink_ip> <userpass>\n" >&2
    return -1
  }

  local username
  local password

  if [[ "$userpass" =~ : ]]; then
    username=${userpass%%:*}
    password=${userpass#*:}
  else
    username=userpass
    password=''
  fi

  # Request URL:http://192.168.0.1/my_cgi.cgi?0.5771658769679171
  curl -sSD - \
    --data 'request=login&admin_user_name=YWRtaW4A&admin_user_pwd=&user_type=0' \
    "http://$dlink_ip/my_cgi.cgi?0.5771658769679171"
}

# 'bin/openwrt-15.05.1-ar71xx-generic-dir-505-a1-squashfs-factory.bin'
dlink::firmware_upload() {
  local firmware_file=${1:-}

  [[ -f "$firmware_file" ]] || {
    printf 'ERROR: dlink::flash firmware file not exist: %s' "$firmware_file" >&2
    return -1
  }

  curl -v \
    -F "file=@$firmware_file" \
    -F "which_action=load_fw" \
    http://192.168.0.1/my_cgi.cgi
}

dlink::firmware_upgrade() {
  curl -v \
    --data 'request=firmware_upgrade' \
    http://192.168.0.1/my_cgi.cgi
}

dlink::reboot() {
  curl -v \
    --data 'request=reboot' \
    http://192.168.0.1/my_cgi.cgi
}

