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

# Load default and local configurations
. ./t_server_null_default.rc
test -r ./t_server_null.rc && . ./t_server_null.rc

# Launch test servers
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    eval server_exec=\"\$SERVER_EXEC_$SUF\"
    eval server_conf=\"\$SERVER_CONF_$SUF\"

    launch_server "${server_name}" "${server_exec}" "${server_conf}"
done

# Create a list of status and pid files. The former allows checking "global" status of client
# connections across --dev null test servers.
export status_files=""
export pid_files=""
export mgmt_ports=""
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    eval mgmt_port=\"\$SERVER_MGMT_PORT_$SUF\"

    status_files="${status_files} ${srcdir}/${server_name}.status"
    pid_files="${pid_files} ${srcdir}/${server_name}.pid"
    mgmt_ports="${mgmt_ports} ${mgmt_port}" 
done

# Wait until no clients are connected to any test server. Wait at least five seconds
# to avoid killing the servers prematurely.
count=0
while [ $count -lt 5 ]; do
    if cat $status_files|grep -qE "(${CLIENT_MATCH}|UNDEF)"; then
	echo "Clients connected, count reset to 0"
        count=0
        sleep 1
        continue
    else
	echo "No clients connected, count at ${count}"
	#cat $status_files
        ((count++))
        sleep 1
        continue
    fi
done

echo "All clients disconnected from all servers"

#sleep 300

for MGMT_PORT in $mgmt_ports
do
    echo "signal SIGTERM"|nc 127.0.0.1 $MGMT_PORT
done

# Pidfile-based approach seems unreliable. If it fails once, the game seems to
# be over.  However, it is still useful as a fallback in case management
# interface is not available.
for PID_FILE in $pid_files
do
    kill `cat $PID_FILE`
done
