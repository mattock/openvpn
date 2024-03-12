#!/bin/sh
#
. ./t_server_null.vars

"${OPENVPN}" \
    --local 127.0.0.1 \
    --lport 1194 \
    --proto udp \
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
    --max-clients 1 \
    --persist-tun \
    --verb 3 \
    --explicit-exit-notify 3 &

SERVER_PID=$!

sleep 600
kill $SERVER_PID
