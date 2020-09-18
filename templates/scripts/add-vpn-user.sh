#!/bin/bash

CLUSTER=$(kubectl config current-context | cut -d"/" -f2)

# this is a local script for a system user to generate VPN configuration for cluster ${CLUSTER}

# get pod id for execution
POD=$(kubectl -n vpn get pods | grep wireguard | cut -d' ' -f1)
EXTERNAL_DNS=$(kubectl -nvpn get svc wireguard -o jsonpath='{.metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}')

if [ -z "$POD" ]; then
  echo "Warning: No VPN service running yet"
  exit 1
fi
EXEC="kubectl -n vpn exec -it $POD -- /bin/bash -c"

# get name
echo -n "Enter your name: "
read name

# collect keys
server_public_key=$($EXEC "cat /etc/wireguard/privatekey | wg pubkey")
client_private_key=$($EXEC "wg genkey")
client_public_key=$($EXEC "echo -n $client_private_key | wg pubkey")

# get next available IP
existing_ips=$($EXEC "cat /etc/wireguard/wg0.conf | grep AllowedIPs| cut -d\" \" -f3 | cut -d\"/\" -f1 | sort")
last_ip=$(echo "$existing_ips" | tr -cd "[:alnum:]." | tail -1)
next_ip=$last_ip
while [[ "$existing_ips" =~ "$next_ip" ]]; do
  next_ip=${next_ip%.*}.$((${next_ip##*.}+1))
done

# generate config file
CONFIG_DIR=~/.wireguard
mkdir -p $CONFIG_DIR
CONFIG_FILE=$CONFIG_DIR/wg-client-${CLUSTER}.conf

# Output TF line
echo "Configuration generated at $CONFIG_FILE with:"
echo "  - public key : $client_public_key"
echo "  - private key: $client_private_key"
echo "  - client IP  : $next_ip/32"
echo
echo "Please modify kubernetes/terraform/environments/<env>/main.tf and append the following line to var.vpn_client_publickeys."
echo "Then apply the terraform, or ask an administrator to."
echo
printf '    ["%s", "%s", "%s"]' "$name" "$next_ip/32" "$client_public_key"
echo
echo "After this is done you should be able to open the wireguard client and activate the tunnel."
echo "You can download the client at https://www.wireguard.com/install/"
echo
echo "When it is running you should be able to access internal resources, e.g. mysql -h 10.10.10.123"
# generate client conf
cat <<-EOF > ${CONFIG_FILE}

#
# This is a generated VPN(wireguard) client configuration
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
AllowedIPs = 10.10.0.0/16
Endpoint = $EXTERNAL_DNS:51820

EOF

