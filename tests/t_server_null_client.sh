#!/bin/bash

launch_client() {
    local test_name=$1
    local log="${test_name}.log"
    local pid="${test_name}.pid"
    local client_exec=$2
    local client_conf=$3

    # Ensure that old log and pid files are gone
    rm -f "${log}" "${pid}"

    "${client_exec}" \
        $client_conf \
        --writepid "${pid}" \
        --setenv pid $pid \
        --log "${log}" &
}

wait_for_results() {
    # Wait until tests have finished
    tests_running="yes"

    # Wait a bit to allow an OpenVPN client process to create a pidfile to
    # prevent exiting too early
    sleep 1

    while [ "${tests_running}" == "yes" ]; do
        tests_running="no"
        for t in $test_names; do
            if [ -f "${t}.pid" ]; then
                tests_running="yes"
            fi
        done

        if [ "${tests_running}" == "yes" ]; then
            echo "Waiting 1 second for clients to exit"
            sleep 1
        fi
    done
}

get_client_test_result() {
    local test_name=$1
    local should_pass=$2
    local log="${test_name}.log"

    grep "Initialization Sequence Completed" "${log}" > /dev/null
    local exit_code=$?

    if [ $exit_code -eq 0 ] && [ "${should_pass}" = "yes" ]; then
        echo "PASS ${test_name}"
    elif [ $exit_code -eq 1 ] && [ "${should_pass}" = "no" ]; then
        echo "PASS ${test_name} (test failure)"
    elif [ $exit_code -eq 0 ] && [ "${should_pass}" = "no" ]; then
        echo "FAIL ${test_name} (test failure)"
        cat "${log}"
        retval=1
    elif [ $exit_code -eq 1 ] && [ "${should_pass}" = "yes" ]; then
        echo "FAIL ${test_name}"
        cat "${log}"
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
    eval client_exec=\"\$CLIENT_EXEC_$SUF\"
    eval client_conf=\"\$CLIENT_CONF_$SUF\"

    test_names="${test_names} ${test_name}"
    launch_client "${test_name}" "${client_exec}" "${client_conf}"
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
