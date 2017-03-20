#!/usr/bin/env bash
#
# gfWRT - WirelessRouTer for your GirlFriend!
# https://github.com/acrossfw/gfWRT
#
# Copyright AcrossFW 2016
# License APACHE-2.0 
# https://www.acrossfw.com
#
# gfWRT Library
#
set -euo pipefail
IFS=$'\n\t'

gfwrt::password() {
  local password=$1

  ssh::ssh <<_CMD_
    (echo '$password'; sleep 1; echo '$password') \
      | passwd root
_CMD_
}

gfwrt::reboot() {
  ssh::ssh reboot
}

gfwrt::service() {
  local service=$1
  local action=$2

  ssh::ssh "/etc/init.d/${service}" "$action" || {
    gfwrt::log "ERROR: gfwrt::service %s %s failed" "$service" "$action"
    return -1
  }
}

gfwrt::log() {
  printf $@ >&2
  echo >&2
}

gfwrt::create_password() {
  local ip=$1
  local password=$2

  [[ "$password" ]] || {
    gfwrt::log "ERROR: gfwrt::create_password usage: <ip> <password>"
  }

  local cookie_file
  local stok_path

  # login root with empty password
  cookie_file="/tmp/acrossfw.$$"
  if stok_path=$(curl -sSD - --cookie-jar "$cookie_file" --data 'luci_username=root&luci_password=' "http://$ip/cgi-bin/luci" \
                  | grep Location \
                  | awk '{print $2}' \
                  | awk '{ sub(/\r$/,""); print }'
                ); then
    # create password
    curl -sS -o /dev/null --cookie "$cookie_file" \
          --data "cbi.submit=1&cbid.system._pass.pw1=$password&cbid.system._pass.pw2=$password&cbid.dropbear.cfg024dd4.Interface=&cbid.dropbear.cfg024dd4.Port=22&cbi.cbe.dropbear.cfg024dd4.PasswordAuth=1&cbid.dropbear.cfg024dd4.PasswordAuth=on&cbi.cbe.dropbear.cfg024dd4.RootPasswordAuth=1&cbid.dropbear.cfg024dd4.RootPasswordAuth=on&cbi.cbe.dropbear.cfg024dd4.GatewayPorts=1&cbid.dropbear._keys._data=&cbi.apply=Save & Apply" \
    "http://192.168.1.1${stok_path}/admin/system/admin" || {
      gfwrt::log "ERROR: gfwrt::create_password create password failed with error code %d" $?
      return -1
    }
  else
    gfwrt::log "WARNING: gfwrt::create_password root login without password failed with error code %d" $?
  fi

  stok_path=$(curl -sSD - --cookie-jar "$cookie_file" --data "luci_username=root&luci_password=$password" "http://$ip/cgi-bin/luci" | grep Location | awk '{print $2}') || {
    gfwrt::log "ERROR: gfwrt::create_password root login with password failed with error code %d" $?
    return -1  
  }
  gfwrt::log "gfwrt::create_password root login with password succ"
  
  unlink "$cookie_file"

  local retry
  local -a cmd_port_test
  retry=0
  IFS=' ' read -a cmd_port_test <<<"nc -v -z -w 3 $ip 22"

  while [[ "$retry" < 9 ]]; do
    "${cmd_port_test[@]}" && break
    ((++retry))
    gfwrt::log "gfwrt::create_password waiting dropbear restarting ... $retry times"
    sleep 1
  done
  "${cmd_port_test[@]}"
}
