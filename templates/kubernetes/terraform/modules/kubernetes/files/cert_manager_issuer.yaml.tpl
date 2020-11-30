apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: "${name}"
spec:
  acme:
    server: "${acme_server}"
    # Email address used for ACME registration
    email: "${acme_registration_email}"
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: clusterissuer-letsencrypt-${environment}-secret
    # Enable the HTTP-01 challenge provider
    solvers:
      - http01:
          ingress:
            class: nginx

---

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: "${name}-dns"
spec:
  acme:
    server: "${acme_server}"
    # Email address used for ACME registration
    email: "${acme_registration_email}"
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: clusterissuer-letsencrypt-${environment}-secret
    # Enable the DNS-01 challenge provider
    solvers:
      - dns01:
          route53:
            region: ${region}
            hostedZoneID: ${hosted_zone_id}
