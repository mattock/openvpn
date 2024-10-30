#!/bin/sh
#
# Requirements for this script:
#
# - Must be run from openvpn/tests directory
# - Must have openvpn/tests/lwipovpnbuild/lwipovpn available

# Problem:
#
# If the client is _not_ daemonized (--daemon) or backgrounded with "&" then
# pinging the client IP (10.29.41.2) _outside of this script_ will work.
#
# If client is daemonized or backgrounded, then lwipovpn process dies right
# after initialization:
#
# 2024-10-30 06:57:21 lwipovpnbuild/lwipovpn
# 2024-10-30 06:57:21 unix device [internal:af_unix] opened
# 2024-10-30 06:57:21 ./null_client_up.sh internal:af_unix 1500 0 10.29.41.2 255.255.255.0 init
# Could not convert ifconfig_ipv6_local=(not set) to IPv6 address: Success
# SNMP private MIB start, detecting sensors.
# lwipovpn init complete: type=tun mtu=1500 local_ip=10.29.41.2 netmask=255.255.255.0 gw=10.29.41.1 local_ipv6=::
# 2024-10-30 06:57:21 Initialization Sequence Completed
# 2024-10-30 06:57:21 Data Channel: cipher 'AES-256-GCM', peer-id: 0
# 2024-10-30 06:57:21 Timers: ping-restart 120
# 2024-10-30 06:57:21 Protocol options: explicit-exit-notify 3, protocol-flags cc-exit tls-ekm dyn-tls-crypt
# 2024-10-30 06:57:21 Child process PID 2491973 for afunix dead? Return code: 0


# Launch the server
sudo ../src/openvpn/openvpn --daemon --local 127.0.0.1 --dev tun --topology subnet --max-clients 10 --persist-tun --verb 3 --ca ./../sample/sample-keys/ca.crt --dh ./../sample/sample-keys/dh2048.pem --cert ./../sample/sample-keys/server.crt --key ./../sample/sample-keys/server.key --tls-auth ./../sample/sample-keys/ta.key 0 --server 10.29.41.0 255.255.255.0 --lport 1194 --proto udp --management 127.0.0.1 11194 --status server.status 1 --log server.log --writepid server.pid --explicit-exit-notify 3

sleep 3

# Launch the client. The client up script kills the client after 5 seconds. If the client is backgrounded or daemonized then lwipovpn process dies.
../src/openvpn/openvpn --client --nobind --remote-cert-tls server --persist-tun --verb 3 --resolv-retry infinite --connect-retry-max 3 --server-poll-timeout 5 --explicit-exit-notify 3 --script-security 2 --dev null --dev-node unix:lwipovpnbuild/lwipovpn --up ./null_client_up.sh --ca ./../sample/sample-keys/ca.crt --cert ./../sample/sample-keys/client.crt --key ./../sample/sample-keys/client.key --tls-auth ./../sample/sample-keys/ta.key 1 --remote 127.0.0.1 1194 udp --proto udp --writepid lwip_client.pid --setenv pid lwip_client.pid --log lwip_client.log

sleep 1

# This will fail either because lwipovpn process is dead, or because client is
# not backgrounded and we never get this far before the client is dead.
fping -c 5 10.29.41.2

# Kill server
sudo kill $(cat server.pid)
