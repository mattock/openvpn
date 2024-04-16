#!/bin/sh
#
launch_server() {
    local server_name=$1
    local server_exec=$2
    local server_conf=$3
    local status="${server_name}.status"
    local pid="${server_name}.pid"

    # Ensure that old status and pid files are gone
    rm -f "${status}" "${pid}"

    "${server_exec}" \
        $server_conf \
        --status "${status}" 1 \
        --writepid "${pid}" \
        --explicit-exit-notify 3
}

# Load base/default configuration
. ./t_server_null_default.rc

# Load local configuration, if any
test -r ./t_server_null.rc && . ./t_server_null.rc

# Launch test servers
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    eval server_exec=\"\$SERVER_EXEC_$SUF\"
    eval server_conf=\"\$SERVER_CONF_$SUF\"

    launch_server "${server_name}" "${server_exec}" "${server_conf}"
done

# Create a list of all applicable client pid files. It allows checking "global"
# status of client connections to the --dev null test servers as a whole.
#
# Also create a list of server management ports which is used to kill the
# servers gracefully using the management interface once all clients have
# disconnected.
#
export pid_files=""
export mgmt_ports=""
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    eval mgmt_port=\"\$SERVER_MGMT_PORT_$SUF\"

    pid_files="${pid_files} ${srcdir}/${server_name}.pid"
    mgmt_ports="${mgmt_ports} ${mgmt_port}" 
done

# Wait until there are at least some client connections before starting the countdown timer.
sleep 2

# Wait until clients are no more, based on the presence of their pid files.
# Wait at least five seconds to avoid killing the servers prematurely.
count=0
maxcount=3
while [ $count -le $maxcount ]; do
    ls t_server_null_client.sh*.pid > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "Clients connected"
        count=0
        sleep 1
    else
        echo "No clients connected"
        ((count++))
        sleep 1
    fi
    echo "Count: $count"
done

echo "All clients have disconnected from all servers"

for MGMT_PORT in $mgmt_ports
do
    echo "signal SIGTERM"|nc 127.0.0.1 $MGMT_PORT
done
