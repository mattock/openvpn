#!/bin/sh

do_client_test() {
    TEST_NAME=$1

    "${OPENVPN}" \
        $CLIENT_BASE_OPTS \
        $CLIENT_PROTO_OPTS \
        $CLIENT_REMOTE_OPTS \
        $CLIENT_CERT_OPTS \
        $CLIENT_CONNECT_OPTS \
        $CLIENT_LOG_OPTS \
        $CLIENT_SCRIPT_OPTS

    grep "Initialization Sequence Completed" "${LOG}" > /dev/null

    if [ $? -eq 0 ]; then
        echo "Success: ${TEST_NAME}"

    else
        echo "Fail: ${TEST_NAME}"
        RETVAL=1
    fi

    rm -f "${LOG}"
}

. ./t_server_null.vars

LOG="./test-client.log"

rm -f "${LOG}"

# Return value for the entire test suite. Gets set to 1 if any test fails.
export RETVAL=0

CLIENT_BASE_OPTS="--client --dev null --ifconfig-noexec --nobind --persist-tun --verb 3"
CLIENT_PROTO_OPTS="--proto udp --cipher AES-256-CBC"
CLIENT_REMOTE_OPTS="--remote 127.0.0.1 1194 udp --remote-cert-tls server"
CLIENT_CERT_OPTS="--ca "${CA}" --cert "${CLIENT_CERT}" --key "${CLIENT_KEY}" --tls-auth "${TA}" 1"
CLIENT_CONNECT_OPTS="--resolv-retry 0 --connect-retry-max 3 --server-poll-timeout 1 --explicit-exit-notify 3"
CLIENT_LOG_OPTS="--log ${LOG}"
CLIENT_SCRIPT_OPTS="--script-security 2 --up null_client_up.sh"

do_client_test base_1194

CLIENT_REMOTE_OPTS="--remote 127.0.0.1 1195 udp --remote-cert-tls server"
do_client_test base_1195


CLIENT_REMOTE_OPTS="--remote 127.0.0.1 1194 udp --remote-cert-tls server"
do_client_test base_1194_2

exit $RETVAL
