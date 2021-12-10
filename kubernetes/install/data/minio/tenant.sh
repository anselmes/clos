#!/bin/bash

# add tenant
kubectl minio tenant create ${TENANT_NAME} --servers ${TENANT_SERVER_COUNT} --volumes 4 --capacity ${TENANT_SIZE} --namespace default --storage-class openebs-device

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: BackendPolicy
metadata:
  name: minio
  namespace: default
  annotations:
    networking.x-k8s.io/app-protocol: https
spec:
  backendRefs:
    - group: core
      kind: Service
      name: minio
      port: 443
  tls:
    certificateAuthorityRef:
      group: core
      kind: Secret
      name: ${TENANT_NAME}-tls
---
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: console
  namespace: default
  labels:
    gateway: default
spec:
  gateways:
    allow: All
  hostnames:
    - "minio-console.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: console
          port: 9090
---
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: minio
  namespace: default
  labels:
    gateway: default
spec:
  gateways:
    allow: All
  hostnames:
    - "minio.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: minio
          port: 443
eof
