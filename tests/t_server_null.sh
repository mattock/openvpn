#!/usr/bin/env bash
#
TSERVER_NULL_SKIP_RC="${TSERVER_NULL_SKIP_RC:-77}"

if ! [ -r "./t_server_null.rc" ] ; then
    echo "$0: cannot find './t_server_null.rc. SKIPPING TEST.'" >&2
    exit "${TSERVER_NULL_SKIP_RC}"
fi

if [ `id -un` == "root" ]; then
    use_sudo="no"
else
    use_sudo="yes"
    sudo_cmd=`which sudo`
    if [ $? -ne 0 ]; then
        echo "ERROR: $0: not running as root and sudo not found!"
        exit 1
    fi
    sudo_cmd="${sudo_cmd} -E -b"
fi

srcdir="${srcdir:-.}"

if [ "${use_sudo}" = "yes" ]; then
    $sudo_cmd "${srcdir}/t_server_null_server.sh"
else
    "${srcdir}/t_server_null_server.sh" &
fi

"${srcdir}/t_server_null_client.sh"

