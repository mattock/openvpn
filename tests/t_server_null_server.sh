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
status_files=""
pid_files=""
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"

    status_files="${status_files} ${srcdir}/${server_name}.status"
    pid_files="${pid_files} ${srcdir}/${server_name}.pid"
done

# Wait until no clients are connected to any test server. Wait at least five seconds
# to avoid killing the servers prematurely.
count=0
while [ $count -lt 10 ]; do
    if cat $status_files|grep -q "${CLIENT_MATCH}"; then
        count=0
        sleep 1
        continue
    else
        ((count++))
        sleep 1
        continue
    fi
done

# All clients have now exited. Kill all server processes and remove their pid
# files, if any.
for PID_FILE in $pid_files
do
    kill `cat $PID_FILE`
    test -r "${PID_FILE}" && rm -f "${PID_FILE}"
done

# Remove server status files, if present.
for STATUS_FILE in $status_files
do
    test -r "${STATUS_FILE}" && rm -f "${STATUS_FILE}"
done
