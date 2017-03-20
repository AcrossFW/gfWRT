#!/usr/bin/env bash
#
# script that passes password from stdin to ssh. 
# 
# Copyright (C) 2010 André Frimberger <andre OBVIOUS_SIGN frimberger.de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# http://andre.frimberger.de/index.php/linux/reading-ssh-password-from-stdin-the-openssh-5-6p1-compatible-way/
# https://www.exratione.com/2014/08/bash-script-ssh-automation-without-a-password-prompt/
#

if [ -n "$SSH_ASKPASS_PASSWORD" ]; then
    cat <<< "$SSH_ASKPASS_PASSWORD"
elif [ $# -lt 1 ]; then
    echo "Usage: echo password | $0 <ssh command line options>" >&2
    exit 1
else
    read SSH_ASKPASS_PASSWORD

    export SSH_ASKPASS=$0
    export SSH_ASKPASS_PASSWORD

    [ "$DISPLAY" ] || export DISPLAY=dummydisplay:0

    # use setsid to detach from tty
	exec setsid "$@" </dev/null
fi
