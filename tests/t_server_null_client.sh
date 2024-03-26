#!/bin/bash

launch_client() {

    local l_test_name=$1
    local l_log="${l_test_name}.log"
    local l_pid="${l_test_name}.pid"
    local l_client_base_opts=$client_base_opts
    local l_client_proto_opts=$client_proto_opts
    local l_client_cipher_opts=$client_cipher_opts
    local l_client_remote_opts=$client_remote_opts
    local l_client_cert_opts=$client_cert_opts
    local l_client_connect_opts=$client_connect_opts
    local l_client_script_opts=$client_script_opts
    local l_openvpn=$openvpn

    # Ensure that old log and pid files are gone
    rm -f "${l_log}" "${l_pid}"

    "${l_openvpn}" \
        $l_client_base_opts \
        $l_client_proto_opts \
        $l_client_cipher_opts \
        $l_client_remote_opts \
        $l_client_cert_opts \
        $l_client_connect_opts \
        $l_client_script_opts \
        --writepid "${l_pid}" \
        --setenv l_pid $l_pid \
        --log "${l_log}" &
}

get_client_test_result() {
    local l_test_name=$1
    local l_should_pass=$2
    local l_log="${l_test_name}.log"

    grep "Initialization Sequence Completed" "${l_log}" > /dev/null
    local l_exit_code=$?

    if [ $l_exit_code -eq 0 ] && [ $l_should_pass -eq 0 ]; then
        echo "PASS ${l_test_name}"
    elif [ $l_exit_code -eq 1 ] && [ $l_should_pass -ne 0 ]; then
        echo "PASS ${l_test_name} (test failure)"
    elif [ $l_exit_code -eq 0 ] && [ $l_should_pass -ne 0 ]; then
        echo "FAIL ${l_test_name} (test failure)"
        cat "${l_log}"
        retval=1
    elif [ $l_exit_code -eq 1 ] && [ $l_should_pass -eq 0 ]; then
        echo "FAIL ${l_test_name}"
        cat "${l_log}"
        retval=1
    fi
}

srcdir="${srcdir:-.}"
top_builddir="${top_builddir:-..}"
openvpn="${openvpn:-${top_builddir}/src/openvpn/openvpn}"
sample_keys="${sample_keys:-${top_builddir}/sample/sample-keys}"
ca="${ca:-${sample_keys}/ca.crt}"
client_cert="${client_cert:-${sample_keys}/client.crt}"
client_key="${client_key:-${sample_keys}/client.key}"
ta="${ta:-${sample_keys}/ta.key}"

# Return value for the entire test suite. Gets set to 1 if any test fails.
export retval=0

# Basic settings that don't generally change between tests
client_base_opts="--client --dev null --ifconfig-noexec --nobind --persist-tun --verb 3"
client_cipher_opts="--cipher AES-256-CBC"
client_cert_opts="--remote-cert-tls server --ca "${ca}" --cert "${client_cert}" --key "${client_key}" --tls-auth "${ta}" 1"
client_connect_opts="--resolv-retry 0 --connect-retry-max 3 --server-poll-timeout 1 --explicit-exit-notify 3"
client_script_opts="--script-security 2 --up null_client_up.sh"

# Cache the path current (just-compiled) openvpn
current_openvpn=$openvpn

test_names=""

# Launch OpenVPN clients in parallel
test_name="t_server_null_client.sh-openvpn_current"
test_names="${test_names} ${test_name}"
openvpn=$current_openvpn
client_remote_opts="--remote 127.0.0.1 1194 udp"
client_proto_opts="--proto udp"
launch_client "${test_name}"

test_name="t_server_null_client.sh-openvpn_current_fail"
test_names="${test_names} ${test_name}"
openvpn=$current_openvpn
client_remote_opts="--remote 127.0.0.1 11194 udp"
client_proto_opts="--proto udp"
launch_client "${test_name}"

test_name="t_server_null_client.sh-openvpn_2_6_8"
test_names="${test_names} ${test_name}"
openvpn="/usr/sbin/openvpn"
client_remote_opts="--remote 127.0.0.1 1194 udp"
client_proto_opts="--proto udp"
launch_client "${test_name}"

# Wait until tests have finished
tests_running="yes"

# Wait until all OpenVPN client processes have started up and created their
# pidfiles
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

# Check test results
test_name="t_server_null_client.sh-openvpn_current"
should_pass=0
get_client_test_result "${test_name}" $should_pass

test_name="t_server_null_client.sh-openvpn_current_fail"
should_pass=1
get_client_test_result "${test_name}" $should_pass

test_name="t_server_null_client.sh-openvpn_2_6_8"
should_pass=0
get_client_test_result "${test_name}" $should_pass

exit $retval
