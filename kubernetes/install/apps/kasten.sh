#!/bin/bash

# install
helm upgrade -i k10 k10 --repo https://charts.kasten.io --create-namespace -n kasten-io

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: k10
  namespace: kasten-io
  labels:
    gateway: All
spec:
  hostnames:
    - "backup.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: gateway
          port: 8000
eof
