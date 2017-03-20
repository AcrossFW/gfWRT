#!/usr/bin/env bash
#
# gfWRT - WirelessRouTer for your GirlFriend!
# https://github.com/acrossfw/gfWRT
#
# Copyright AcrossFW 2016
# License APACHE-2.0 
# https://www.acrossfw.com
#
# SSH Library for gfWRT
#
set -euo pipefail
IFS=$'\n\t'

ssh::init() {
  local hostport="$1"
  local userpass="$2"
  local ssh_identity="$3"
  local authorized_keys="$4"

  declare -g ssh_user
  declare -g ssh_host
  declare -g cmd_ssh
  declare -g cmd_scp

  local ssh_port

  ssh_host=${hostport%%:*}
  ssh_port=${hostport##*:}

  [[ "$ssh_port" ]] || ssh_port=22
  [[ "$ssh_port" =~ ^[0-9]+$ ]] || {
    gfwrt::log "ERROR: ssh:init port invalid: %d" "$ssh_port"
  }

  ssh_user=${userpass%%:*}
  ssh_pass=${userpass#*:}

  [[ "$ssh_pass" ]] || {
    gfwrt::log "ERROR: ssh:init pass empty"
  }
  
  ssh_identity=$(eval echo "$ssh_identity")
  [[ -f "$ssh_identity" ]] || {
    echo "ERROR: ssh:init can not found identify key file."
    return -1
  }

  local options='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o CheckHostIP=no'
  cmd_ssh="ssh $options -i $ssh_identity -p $ssh_port $ssh_user@$ssh_host"  
  cmd_scp="scp $options -i $ssh_identity -P $ssh_port"

  [[ "$authorized_keys" ]] && {
    ssh::init_authorized_keys "$ssh_pass" "$authorized_keys" '/etc/dropbear/authorized_keys'
  }
}

ssh::scp() {
  ssh::backend "$cmd_scp $@"
}

ssh::ssh() {
  ssh::backend "$cmd_ssh $@"
}

ssh::backend() {
  local -a command
  IFS=' ' read -a command <<<"$@"
  "${command[@]}"
}

ssh::user() {
  echo "$ssh_user"
}

ssh::host() {
  echo "$ssh_host"
}

ssh::init_authorized_keys() {
  local password=$1
  local authorized_keys=$2
  local authorized_file=$3

  [[ -x ./bin/sshpass.sh ]] || {
    gfwrt::log "ERROR: ssh::init_authorized_keys can not find sshpass.sh"
    return -1
  }

  local -a cmd_sshpass
  IFS=' ' read -a cmd_sshpass <<<"./bin/sshpass.sh $cmd_ssh"
  echo "$password" | "${cmd_sshpass[@]}" \
    "echo $authorized_keys >> $authorized_file"
}
