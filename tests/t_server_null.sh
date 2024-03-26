#!/bin/sh
#
if [ `id -un` == "root" ]; then
    sudo_cmd=""
else
    sudo_cmd=`which sudo`
    if [ $? -ne 0 ]; then
        echo "ERROR: $0: not running as root and sudo not found!"
        exit 1
    fi
    sudo_cmd="${sudo_cmd} -E -b"
fi

srcdir="${srcdir:-.}"

export server_id="t_server_null_server-1194_udp"
export lport="1194"
export proto="udp"
$sudo_cmd "${srcdir}/t_server_null_server.sh"

export server_id="t_server_null_server-1195_tcp"
export lport="1195"
export proto="tcp"
$sudo_cmd "${srcdir}/t_server_null_server.sh"

unset server_id
unset lport
unset proto

"${srcdir}/t_server_null_client.sh"

