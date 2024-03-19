#!/bin/sh

do_client_test() {
    test_name=$1

    "${openvpn}" \
        $client_base_opts \
        $client_proto_opts \
        $client_remote_opts \
        $client_cert_opts \
        $client_connect_opts \
        $client_log_opts \
        $client_script_opts

    grep "Initialization Sequence Completed" "${log}" > /dev/null

    if [ $? -eq 0 ]; then
        echo "Success: ${test_name}"

    else
        echo "Fail: ${test_name}"
        retval=1
    fi

    rm -f "${log}"
}

srcdir="${srcdir:-.}"
top_builddir="${top_builddir:-..}"
openvpn="${openvpn:-${top_builddir}/src/openvpn/openvpn}"
sample_keys="${sample_keys:-${top_builddir}/sample/sample-keys}"
ca="${ca:-${sample_keys}/ca.crt}"
client_cert="${client_cert:-${sample_keys}/client.crt}"
client_key="${client_key:-${sample_keys}/client.key}"
ta="${ta:-${sample_keys}/ta.key}"
log="${log:-${srcdir}/test-client.log}"

rm -f "${log}"

# Return value for the entire test suite. Gets set to 1 if any test fails.
export retval=0

client_base_opts="--client --dev null --ifconfig-noexec --nobind --persist-tun --verb 3"
client_proto_opts="--proto udp --cipher AES-256-CBC"
client_cert_opts="--ca "${ca}" --cert "${client_cert}" --key "${client_key}" --tls-auth "${ta}" 1"
client_connect_opts="--resolv-retry 0 --connect-retry-max 3 --server-poll-timeout 1 --explicit-exit-notify 3"
client_log_opts="--log ${log}"
client_script_opts="--script-security 2 --up null_client_up.sh"

client_remote_opts="--remote 127.0.0.1 1194 udp --remote-cert-tls server"
do_client_test base_1194

#client_remote_opts="--remote 127.0.0.1 1195 udp --remote-cert-tls server"
#do_client_test base_1195

exit $retval
