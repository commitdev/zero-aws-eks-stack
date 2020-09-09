[Interface]
Address = ${tpl_server_address}
ListenPort = 51820
PostUp = wg set wg0 private-key /etc/wireguard/privatekey && iptables -A FORWARD -s ${tpl_server_address} -d ${tpl_destination_subnets} -j ACCEPT && iptables -A FORWARD -s ${tpl_server_address} -j DROP && iptables -t nat -A POSTROUTING -s ${tpl_server_address} -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -s ${tpl_server_address} -d ${tpl_destination_subnets} -j ACCEPT && iptables -D FORWARD -s ${tpl_server_address} -j DROP && iptables -t nat -D POSTROUTING -s ${tpl_destination_subnets} -o eth0 -j MASQUERADE

${tpl_client_peers}
