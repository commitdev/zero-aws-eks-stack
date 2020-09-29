[Interface]
Address = ${tpl_server_address}
ListenPort = 51820
PostUp = wg set wg0 private-key /etc/wireguard/privatekey
PostUp   = iptables -A FORWARD -i wg0 -s ${tpl_server_address} -j ACCEPT
PostUp   = iptables -A FORWARD -s ${tpl_server_address} -j DROP
PostUp   = iptables -t nat -A POSTROUTING -s ${tpl_server_address} -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -s ${tpl_server_address} -j ACCEPT
PostDown = iptables -D FORWARD -s ${tpl_server_address} -j DROP
PostDown = iptables -t nat -D POSTROUTING -s ${tpl_server_address} -o eth0 -j MASQUERADE

${tpl_client_peers}
