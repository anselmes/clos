#!/bin/bash

# TODO: install etcd

# install vault
helm upgrade \
  -i vault vault \
  -n vault \
  --create-namespace \
  --reuse-values \
  --repo https://helm.releases.hashicorp.com

# create approle (required for minio)
# TODO: add approle
vault write auth/approle/role/kms token_num_uses=0 secret_id_num_uses=0 period=5m
vault write auth/approle/role/kms policies=allow_kms

# encode vault ca
export VAULT_CA_BUNDLE="$(kubectl view-secret vault-tls ca.crt)"
export VAULT_CA_BUNDLE_BASE64="$(encode64 ${VAULT_CA_BUNDLE})"

# create vault cluster issuer
# TODO: review vault ca
cat <<-eof | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: vault-cluster-ca
  namespace: cert-manager
spec:
  vault:
    path: cert/sign/default
    server: https://vault.vault:8200
    caBundle: ${VAULT_CA_BUNDLE_BASE64}
    auth:
      kubernetes:
        role: cert-manager
        mountPath: /v1/auth/kubernetes
        secretRef:
          name: ${CM_SA_SECRET}
          key: token
eof

# TODO: review - ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: BackendPolicy
metadata:
  name: vault
  namespace: vault
  annotations:
    networking.x-k8s.io/app-protocol: https
spec:
  backendRefs:
    - group: core
      kind: Service
      name: vault
      port: 8200
  tls:
    certificateAuthorityRef:
      group: core
      kind: Secret
      name: vault
---
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: vault
  namespace: vault
  labels:
    gateway: All
spec:
  hostnames:
    - "vault.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: vault
          port: 8200
eof
