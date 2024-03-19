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
    sudo_cmd="${sudo_cmd} -b"
fi

srcdir="${srcdir:-.}"
server_pid_file="${pid_file:-${srcdir}/t_server_null_server.pid}"

# Do not start if the test server is running already - something that should never
# happen in circumstances.
pgrep -F "${server_pid_file}" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "ERROR: already running --dev null test server needs to be killed manually!"
    exit 1
fi

$sudo_cmd "${srcdir}/t_server_null_server.sh"

"${srcdir}/t_server_null_client.sh"

