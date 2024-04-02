#!/bin/bash

launch_client() {
    local test_name=$1
    local log="${test_name}.log"
    local pid="${test_name}.pid"
    local openvpn_exec=$2
    local openvpn_conf=$3

    # Ensure that old log and pid files are gone
    rm -f "${log}" "${pid}"

    "${openvpn_exec}" \
        $openvpn_conf \
        --writepid "${pid}" \
        --setenv l_pid $pid \
        --log "${log}" &
}

wait_for_results() {
    # Wait until tests have finished
    tests_running="yes"

    # Wait until at least one OpenVPN client process has started an created its
    # pidfile to prevent exiting prematurely
    sleep 1

    while [ "${tests_running}" == "yes" ]; do
        tests_running="no"
        for t in $test_names; do
            if [ -f "${t}.pid" ]; then
                tests_running="yes"
            fi
        done

        if [ "${tests_running}" == "yes" ]; then
            echo "Waiting 1 second for tests to finish"
            sleep 1
        fi
    done
}

get_client_test_result() {
    local l_test_name=$1
    local l_should_pass=$2
    local l_log="${l_test_name}.log"

    grep "Initialization Sequence Completed" "${l_log}" > /dev/null
    local l_exit_code=$?

    if [ $l_exit_code -eq 0 ] && [ "${l_should_pass}" = "yes" ]; then
        echo "PASS ${l_test_name}"
    elif [ $l_exit_code -eq 1 ] && [ "${l_should_pass}" = "no" ]; then
        echo "PASS ${l_test_name} (test failure)"
    elif [ $l_exit_code -eq 0 ] && [ "${l_should_pass}" = "no" ]; then
        echo "FAIL ${l_test_name} (test failure)"
        cat "${l_log}"
        retval=1
    elif [ $l_exit_code -eq 1 ] && [ "${l_should_pass}" = "yes" ]; then
        echo "FAIL ${l_test_name}"
        cat "${l_log}"
        retval=1
    fi
}


# Load base tests
. ./t_server_null_default.rc

# Load additional, local tests, if any
test -r ./t_server_null.rc && . ./t_server_null.rc

# Return value for the entire test suite. Gets set to 1 if any test fails.
export retval=0

# We use the list of all test names to determine when all OpenVPN clients have
# exited and it is safe to check the test results.
test_names=""

for SUF in $TEST_RUN_LIST
do
    eval test_name=\"\$TEST_NAME_$SUF\"
    eval openvpn_exec=\"\$OPENVPN_EXEC_$SUF\"
    eval openvpn_conf=\"\$OPENVPN_CONF_$SUF\"

    test_names="${test_names} ${test_name}"
    launch_client "${test_name}" "${openvpn_exec}" "${openvpn_conf}"
done

# Wait until all OpenVPN clients have exited
wait_for_results

for SUF in $TEST_RUN_LIST
do
    eval test_name=\"\$TEST_NAME_$SUF\"
    eval should_pass=\"\$SHOULD_PASS_$SUF\"

    get_client_test_result "${test_name}" $should_pass
done

exit $retval
