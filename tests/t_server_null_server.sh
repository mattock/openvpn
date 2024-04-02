#!/bin/sh
#
launch_server() {
    local server_name=$1
    local server_conf=$2
    local status="${server_name}.status"
    local pid="${server_name}.pid"

    # Ensure that old status and pid files are gone
    rm -f "${status}" "${pid}"

    "${OPENVPN_EXEC}" \
        $server_conf \
        --status "${status}" 1 \
        --writepid "${pid}" \
        --explicit-exit-notify 3
}

. ./t_server_null_default.rc

# Launch test servers
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    eval server_conf=\"\$SERVER_CONF_$SUF\"

    launch_server "${server_name}" "${server_conf}"
done

# Wait for clients to disconnect
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"

    status="${srcdir}/${server_name}.status"
    pid="${srcdir}/${server_name}.pid"

    # Wait until no clients are connected anymore, then exit
    count=0
    while [ $count -lt 10 ]; do
        if grep -q "${CLIENT_MATCH}" "${status}"; then
            count=0
            sleep 1
            continue
        else
            ((count++))
            sleep 1
            continue
        fi
    done

    kill `cat $pid`

    test -f $pid && rm -f $pid
    test -f $status && rm -f $status

done
