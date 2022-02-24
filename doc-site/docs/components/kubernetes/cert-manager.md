---
title: Issuing and renewing TLS certificates
sidebar_label: Cert Manager
sidebar_position: 2
---

## Overview
`cert-manager` is a native Kubernetes certificate management controller. It can help with issuing certificates from a variety of sources, such as [Let's Encrypt](https://letsencrypt.org) and more.

For any ingresses that specify that they need TLS, `cert-manager` will automatically provision a certificate using Let's Encrypt, and handle renewing it automatically on a regular basis. Alongside [external-dns](https://github.com/kubernetes-sigs/external-dns), this allows you to make sure your new domains are always secured using HTTPS.

## How It Works
`cert-manager` watches `Ingress` resources across your cluster. If it observes an `Ingress` with one of it's annotations, it will ensure a Certificate resource with the name provided in the tls.secretName field exists. See the example below.

Zero sets up two `ClusterIssuer`s by default which provide different ways of verifying your certificates.
- `clusterissuer-letsencrypt-production` uses the HTTP issuer, which requires Let's Encrypt to do an HTTP call to your service to verify it.
- `clusterissuer-letsencrypt-production-dns` uses the DNS issuer, which creates a DNS record Let's Encrypt will check to verify that you own the domain.

:::note
The name "production" in the clusterissuers refers to the fact that we are using the "production" version of Let's Encrypt, which is what we want in almost all cases unless we are testing Let's Encrypt itself.
:::

In the case of the HTTP `ClusterIssuer`, external-dns working properly will be required, since that is what will create a Route53 DNS record that points at the load balancer in front of your cluster. Both `external-dns` and `cert-manager` are configured by annotations and configuration in the `Ingress`.



## Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    # This annotation is for cert-manager, it specifies which certificate issuer to use
    cert-manager.io/cluster-issuer: clusterissuer-letsencrypt-production
    # This annotation is for external-dns
    external-dns.alpha.kubernetes.io/hostname: example.com
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
Checkout [`cert-manager`'s documentation][docs] for more information.

[docs]: https://cert-manager.io/docs/
