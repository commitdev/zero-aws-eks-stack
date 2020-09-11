#!/bin/bash

PROJECT=<% .Name %>
CONTEXT=$(kubectl config current-context | cut -d"/" -f2)

# this is a local script for Dev to generate VPN configuration for project ${PROJECT}

# get pod id for execution
POD=$(kubectl -n vpn get pods | grep wireguard | cut -d' ' -f1)

if [ -z "$POD" ]; then
  echo "Warning: No VPN service running yet"
  exit 1
fi 
EXEC="kubectl -n vpn exec -it $POD --"

# get name
echo -n "Enter your name: "
read name

# collect keys
server_public_key=$($EXEC cat /etc/wireguard/privatekey | wg pubkey)
client_private_key=$($EXEC wg genkey)
client_public_key=$($EXEC echo -n $client_private_key | wg pubkey)

# get next available IP
existing_ips=$($EXEC cat /etc/wireguard/wg0.conf | grep AllowedIPs| cut -d" " -f3 | cut -d"/" -f1 | sort)
last_ip=$(echo "$existing_ips" | tail -1)
next_ip=$last_ip
while [[ "$existing_ips" =~ "$next_ip" ]]; do
  next_ip=${next_ip%.*}.$((${next_ip##*.}+1))
done

# generate config file
CONFIG_DIR=~/.wireguard/${PROJECT}
mkdir -p $CONFIG_DIR
CONFIG_FILE=$CONFIG_DIR/wg-client-${CONTEXT}.conf

# Output TF line
echo "Configuration generated at $CONFIG_FILE with:"
echo "  - public key : $client_public_key"
echo "  - private key: $client_private_key"
echo "  - client IP  : $next_ip/32"
echo
echo "Please ask DevOps to apply VPN server change with the following line appended to var.vpn_client_publickeys list:"
echo
printf '    ["%s", "%s", "%s"]' "$name" "$next_ip/32" "$client_public_key"
echo

# generate client conf
cat <<-EOF > ${CONFIG_FILE}

#
# This is a generated VPN(wireguard) client configuration
#
# Next Steps:
#  1. apply VPN server change with following line in var.vpn_client_publickeys
#     ["$name", "$next_ip/32", "$client_public_key"]
#  2. put configuration into your wireguard client application and activate the channel
#  3. access to the destination, eg. mysql -h 10.10.10.79 -uxxx -p
#

# Configuration content

[Interface]
# VPN client side: for user "$name"
PrivateKey = $client_private_key
ListenPort = 34567
Address = $next_ip/32

[Peer]
# VPN server side
PublicKey = $server_public_key
AllowedIPs = 0.0.0.0/0
Endpoint = vpn.piggycloud-staging.me:51820

EOF

