---
title: Issuing and renewing TLS certificates
sidebar_label: Cert Manager
sidebar_position: 2
---

## Overview
cert-manager is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as Let’s Encrypt and more.

For any ingresses that specify that they need TLS, cert-manager will automatically provision a certificate using Lets Encrypt, and handle renewing it automatically on a regular basis. Alongside external-dns, this allows you to make sure your new domains are always secured using HTTPS.

## How It Works
The sub-component ingress-shim watches Ingress resources across your cluster. If it observes an Ingress with annotations described in the Supported Annotations section, it will ensure a Certificate resource with the name provided in the tls.secretName field and configured as described on the Ingress exists. For example:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    # add an annotation indicating the issuer to use.
    cert-manager.io/cluster-issuer: nameOfClusterIssuer
  name: myIngress
  namespace: myIngress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: myservice
            port:
              number: 80
  tls: # < placing a host in the TLS config will determine what ends up in the cert's subjectAltNames
  - hosts:
    - example.com
    secretName: myingress-cert # < cert-manager will store the created certificate in this secret.
```

## Documentation
Checkout [Cert-manager's documentation][docs] for more information.

[docs]: https://cert-manager.io/docs/