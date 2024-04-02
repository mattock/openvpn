#!/bin/sh
#
if [ "${server_id}" = "" ]; then
    echo "ERROR: server_id environment variable must be defined!"
    exit 1
fi

. ./t_server_null_default.rc

# Settings that change between server setups
status_file="${status_file:-${srcdir}/${server_id}.status}"
pid_file="${pid_file:-${srcdir}/${server_id}.pid}"
client_match="${client_match:-Test-Client}"
proto="${proto:-udp}"
lport="${lport:-1194}"

"${OPENVPN_EXEC}" \
    --daemon \
    --local 127.0.0.1 \
    --lport "${lport}" \
    --proto "${proto}" \
    --dev tun \
    --ca "${CA}" \
    --dh "${DH}" \
    --cert "${SERVER_CERT}" \
    --key "${SERVER_KEY}" \
    --tls-auth "${TA}" 0 \
    --topology subnet \
    --server 10.29.41.0 255.255.255.0 \
    --keepalive 10 120 \
    --cipher AES-256-CBC \
    --max-clients $MAX_CLIENTS \
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
