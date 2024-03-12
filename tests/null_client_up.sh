#!/bin/sh
#
# Stop the parent process (openvpn) gracefully after a small delay

# Get parent process id
MY_PPID=$(ps -o ppid= -C null_client_up.sh)

# Allow OpenVPN to finish initializing while waiting in the background and then
# killing the process gracefully.
(sleep 5 ; kill -15 $MY_PPID) &
