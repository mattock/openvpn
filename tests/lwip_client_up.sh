#!/bin/sh
#
# Add this client's IP to a file
if ! grep -q "$ifconfig_local" ./$test_name.ips; then
    echo -n "$ifconfig_local " >> ./$test_name.ips
fi

# Determine the OpenVPN PID from its pid file. This works reliably even when
# the OpenVPN process is backgrounded for parallel tests.
MY_PPID=`cat $pid`

# Allow OpenVPN to finish initializing while waiting in the background and then
# killing the process gracefully. Also wait for fping tests to finish.
(sleep 5

count=0
maxcount=15
while [ $count -le $maxcount ]; do
    if pgrep fping > /dev/null 2>&1; then
        echo "Waiting for fping to exit ($count/$maxcount)"
        count=$(( count + 1))
        sleep 1
    else
        echo "fping not running anymore"
        break
    fi
done

kill -15 $MY_PPID
) &
