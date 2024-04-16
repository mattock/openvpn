#!/usr/bin/env bash
#
# Run this stress test as root to avoid sudo authorization from timing out.

count=1

. ./t_server_null_default.rc

export pid_files=""
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    pid_files="${pid_files} ${srcdir}/${server_name}.pid"
done

LOG_BASEDIR="make-check"
mkdir -p "${LOG_BASEDIR}"

while [ $count -lt 100 ]; do
    count=$(( count + 1 ))
    make check > /dev/null 2>&1
    retval=$?

    echo "Iteration ${count}: return value ${retval}" >> "${LOG_BASEDIR}/make-check.log"
    if [ $retval -ne 0 ]; then
	DIR="${LOG_BASEDIR}/make-check-${count}"
        mkdir -p "${DIR}"
	cp t_server_null*.log "${DIR}/"
	cp test-suite.log "${DIR}/"
	ps aux|grep openvpn|grep -vE '(suppress|grep)' > "${DIR}/psaux"
    fi

    # Wait until the server has probably killed itself due to lack of client activity
    sleep 10
done
