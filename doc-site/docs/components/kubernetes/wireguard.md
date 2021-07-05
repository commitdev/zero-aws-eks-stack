---
title: WireGuard VPN support
sidebar_label: WireGuard
sidebar_position: 4
---

## Overview
WireGuard® is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography. This allows users to access internal resources securely.

A WireGuard pod will be started inside the cluster and users can be added to it by appending lines to `kubernetes/terraform/environments/<env>/main.tf`:
```
  vpn_client_publickeys = [
    # name, IP, public key
    ["Your Name", "10.10.199.203/32", "yz6gNspLJE/HtftBwcj5x0yK2XG6+/SHIaZ****vFRc="],
  ]
```


## Adding a user
A new user can add themselves to the VPN server easily. Any user with access to the kubernetes cluster should be able to run the script `scripts/add-vpn-user.sh`
This will ask for their name, and automatically generate a line like the one above, which they can then add to the terraform and apply themselves, or give the line to an administrator and ask them to apply it.
The environment they are added to will be decided by the current `kubectl` context. You can see your current context with `kubectl config current-context`.
A user will need to repeat this for each environment they need access to (for example, staging and production.)

*Note that this will try to detect the next available IP address for the user but you should still take care to ensure there are no duplicate IPs in the list.*

It will also generate a WireGuard client config file on their local machine which will be properly populated with all the values to allow them to connect to the server.


## Downloading the WireGuard Client
The WireGuard client can be downloaded at [https://www.wireguard.com/install/](https://www.wireguard.com/install/)

Once connected to the VPN, the user should have direct access to anything running inside the AWS VPC.