#!/bin/sh
#
srcdir="${srcdir:-.}"
top_builddir="${top_builddir:-..}"
openvpn="${openvpn:-${top_builddir}/src/openvpn/openvpn}"
sample_keys="${sample_keys:-${top_builddir}/sample/sample-keys}"
ca="${ca:-${sample_keys}/ca.crt}"
dh="${dh:-${sample_keys}/dh2048.pem}"
server_cert="${server_cert:-${sample_keys}/server.crt}"
server_key="${server_key:-${sample_keys}/server.key}"
ta="${ta:-${sample_keys}/ta.key}"
status_file="${status_file:-${srcdir}/t_server_null_server.status}"
pid_file="${pid_file:-${srcdir}/t_server_null_server.pid}"
client_match="${client_match:-Test-Client}"
proto="${proto:-udp}"
lport="${lport:-1194}"

"${openvpn}" \
    --daemon \
    --local 127.0.0.1 \
    --lport "${lport}" \
    --proto "${proto}" \
    --dev tun \
    --ca "${ca}" \
    --dh "${dh}" \
    --cert "${server_cert}" \
    --key "${server_key}" \
    --tls-auth "${ta}" 0 \
    --topology subnet \
    --server 10.29.41.0 255.255.255.0 \
    --keepalive 10 120 \
    --cipher AES-256-CBC \
    --max-clients 1 \
    --persist-tun \
    --verb 3 \
    --status "${status_file}" 1 \
    --writepid "${pid_file}" \
    --explicit-exit-notify 3

# Wait until no clients are connected anymore, then exit
count=0
while [ $count -lt 10 ]; do
    if grep -q "${client_match}" "${status_file}"; then
	count=0
	sleep 1
        continue
    else
        ((count++))
        sleep 1
	continue
    fi
done

kill `cat $pid_file`

test -f $pid_file && rm -f $pid_file
test -f $status_file && rm -f $status_file
