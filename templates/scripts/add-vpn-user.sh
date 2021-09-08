#!/bin/bash

CLUSTER=$(kubectl config current-context | cut -d"/" -f2)

# this is a local script for a system user to generate VPN configuration for cluster ${CLUSTER}

NAMESPACE=<% .Name %>
REGION=<% index .Params `region` %>

if [[ "$CLUSTER" = *"-stage-"* ]]; then
  DEFAULT_IP="10.10.199.200"
else
  DEFAULT_IP="10.10.99.200"
fi

# get pod id for execution
POD=$(kubectl -n vpn get pods --selector=app=wireguard -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
  echo "Warning: No VPN service running yet"
  exit 1
fi

function k8s_exec() {
  kubectl -n vpn exec $POD wireguard --container wireguard -- /bin/bash -c "$1"
}

# get name
echo "Current cluster is '${CLUSTER}'"
echo -n "Enter your name: " && read name
echo
echo "Generating your client configuration file..."

# collect keys
server_public_key=$(k8s_exec "cat /etc/wireguard/privatekey | wg pubkey")
client_private_key=$(k8s_exec "wg genkey")
client_public_key=$(k8s_exec "echo -n $client_private_key | wg pubkey | tr -d \"\r\n\f\"")

# get next available IP
existing_ips=$(k8s_exec "cat /etc/wireguard/wg0.conf | grep AllowedIPs| cut -d\" \" -f3 | cut -d\"/\" -f1 | sort")
# Default start at 201 if no existing IPs are found
existing_ips=${existing_ips:-$DEFAULT_IP}
last_ip=$(echo "$existing_ips" | tr -cd "[:alnum:].\n" | tail -1)
next_ip=$last_ip
while [[ "$existing_ips" =~ "$next_ip" ]]; do
  next_ip=${next_ip%.*}.$((${next_ip##*.}+1))
done

# get DNS server setting
dns_server=$(k8s_exec "cat /etc/resolv.conf | grep nameserver | tail -1 | cut -d\" \" -f2 | tr -d \"\r\n\f\"")

# get CIDRs for allowed IP subnets
VPCNAME=${CLUSTER%-$REGION}-vpc
vpc_cidr=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=${VPCNAME} | jq -r '.Vpcs[].CidrBlock')
[[ -z "$vpc_cidr" ]] && vpc_cidr="10.10.0.0/16"
k8s_cidr="172.16.0.0/12"

# get Endpoint DNS
EXTERNAL_DNS=$(kubectl -nvpn get svc wireguard -o jsonpath='{.metadata.annotations.external-dns\.alpha\.kubernetes\.io/hostname}')

# generate config file
CONFIG_DIR=~/.wireguard
mkdir -p $CONFIG_DIR
CONFIG_FILE=$CONFIG_DIR/wg-client-${CLUSTER}.conf

# Output TF line
echo
echo "Configuration for user '$name' generated at $CONFIG_FILE with:"
echo "  - public key : $client_public_key"
echo "  - private key: $client_private_key"
echo "  - client IP  : $next_ip/32"
echo
echo "Please modify kubernetes/terraform/environments/<env>/main.tf and append the following line to var.vpn_client_publickeys."
echo "Then apply the terraform, or ask an administrator to."
echo
printf '    ["%s", "%s", "%s"],\n' "$name" "$next_ip/32" "$client_public_key"
echo
echo "You can download the client at https://www.wireguard.com/install/"
echo "After this is done you should be able to open the wireguard client, import a tunnel file from ~/.wireguard/ and activate the tunnel."
echo
echo "When it is running you should be able to access internal resources, eg. mysql -h <aws rds hostname>"
echo "You will be able to connect to resources within both the VPC and the Kubernetes cluster."
echo

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
DNS = $dns_server

[Peer]
# VPN server side
PublicKey = $server_public_key
AllowedIPs = $vpc_cidr, $k8s_cidr, $dns_server/32
Endpoint = $EXTERNAL_DNS:51820

EOF

