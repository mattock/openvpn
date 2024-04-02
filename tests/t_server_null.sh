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

$sudo_cmd "${srcdir}/t_server_null_server.sh"

"${srcdir}/t_server_null_client.sh"

