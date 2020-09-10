#!/bin/bash

CLIENT_IP=$1

if [ -z $${CLIENT_IP} ]; then
  echo "$0 <client IP>"
  exit 1
fi

PEERS_FILE="/tmp/wg0-peers.csv"

peer=$(grep $${CLIENT_IP} $${PEERS_FILE})
IFS='|' read -r -a columns <<< "$peer"
name=$${columns[0]}
ip=$${columns[1]}
pubkey=$${columns[2]}

tmpfile="/tmp/wg0-client-$${name}.conf"
cat > "$${tmpfile}" <<- EOF
#
# This is a generated VPN(wireguard) client configuration based on your IP and public key. The only part you need to fill is <my private key> part
# Steps:
#  1. fill in <my private key> part
#  2. copy & past all content to your client
#  3. active client
#  4. access to the destination, eg, mysql -h 10.10.10.79 -uxxx -p
#

[Interface]
# VPN client side: for user "$${name}"
PrivateKey = <my private key>
ListenPort = 34567
Address = $${ip}

[Peer]
# VPN server side (no need to change)
PublicKey = $(wg pubkey < /etc/wireguard/privatekey)
AllowedIPs = ${tpl_destination_subnets}
Endpoint = ${tpl_client_endpoint_dns}:51820

EOF


# Output
cat "$${tmpfile}"
