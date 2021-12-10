#!/bin/bash

# TODO: install
helm upgrade -i harbor harbor \
    --repo https://charts.bitnami.com/bitnami \
    --create-namespace -n pipelines

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: BackendPolicy
metadata:
  name: harbor
  namespace: services
  annotations:
    networking.x-k8s.io/app-protocol: https
spec:
  backendRefs:
    - group: core
      kind: Service
      name: hcr-harbor
      port: 443
  tls:
    certificateAuthorityRef:
      group: core
      kind: Secret
      name: hcr-harbor-nginx
---
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: harbor
  namespace: services
  labels:
    gateway: All
spec:
  hostnames:
    - "hcr.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: hcr-harbor
          port: 443
eof
