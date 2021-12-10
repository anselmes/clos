#!/bin/bash

# install minio operator
kubectl minio init

# install direct-csi
kubectl direct-csi install --crd

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: console
  namespace: minio-operator
  labels:
    gateway: default
spec:
  gateways:
      allow:  All
  hostnames:
    - "minio-operator.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: console
          port: 9090
eof
