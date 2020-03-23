#!/bin/bash

## TODO: improve this to avoid repeating cycle
## check ping for trusted peers with tcpping
function checkPeers() {
    sed -e '/address/!d' -e '/#/d' -e 's@^.*/ip./\([^/]*\)/tcp/\([0-9]*\).*@\1 \2@' "$JORMUNGANDR_CONFIG" |
        while read -r addr port; do
            tcpping -x 1 "$addr" "$port"
        done
}

## check which IPs your pool has quarantined
function quarantinedIps() {
    echo "List of IP addresses that were quarantined somewhat recently:"
    curl -s "$JORMUNGANDR_RESTAPI_URL"/v0/network/p2p/quarantined | rg -o "/ip4/.{0,16}" | sed -r '/\n/!s/[0-9.]+/\n&\n/;/^([0-9]{1,3}\.){3}[0-9]{1,3}\n/P;D' | sort -u
    echo "End of somewhat recently quarantined IP addresses."
}

## check how many quaratined IPs are in the above list?
function nOfQuarantinedIps() {
    echo "How many IP addresses were quarantined?"
    quarantinedIps | wc -l
}

## check if your pool was recently quarantined
function isPoolQuarantined() {
    this_node=$(quarantinedIps | rg "${JORMUNGANDR_PUBLIC_IP_ADDR}")
    if [ -n "${this_node}" ]; then
        echo "ERROR! You were quarantined at some point in the recent past!"
        echo "Execute '$SCRIPTNAME --connected-estab' to confirm that you are connecting to other nodes."
    else
        echo "You are clean as a whistle."
    fi
}

## how many other nodes is my pool connected to?
function showEstab() {
    total="$(netstat -punt 2>/dev/null | grep jormungandr | grep -c ESTAB)"
    printf "\\nCurrently ESTABLISHED to a Total of %s nodes\\n\\n" "${total}"
}

## count connections to nodes and order them by highest number of connections
## accepts 1 paramenter to filter out connections less than supplied number
function connectedIps() {
    if [ -n "$1" ]; then
        howManyConnections="$1"
        if ! [[ "$howManyConnections" =~ ^[0-9]+$ ]]; then
            echo "Sorry integers only"
            exit 1
        fi
    else
        echo "you must provide one paramenter, it must be a valid integer for a minum number of connections to check against"
        echo "e.g: $SCRIPTNAME --connected-ips 10 -- this will show IPs that are connect 10 or more times"
        exit 1
    fi

    echo -e "\\nIP addresses that are connected more than $howManyConnections times:\\n"
    netstat -tn 2>/dev/null | tail -n +3 | awk '{print $5}' | grep -E -v "127.0.0.1|$JORMUNGANDR_PUBLIC_IP_ADDR" | cut -d: -f1 | sort | uniq -c | sort -nr | awk "{if (\$1 >= $howManyConnections) print \$1,\$2}"
    echo
}


