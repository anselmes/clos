#!/bin/bash

# install
helm upgrade -i kubeapps kubeapps --repo https://charts.bitnami.com/bitnami --create-namespace -n kubeapps

# creds
kubectl create serviceaccount kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: kubeapps
  namespace: kubeapps
  labels:
    gateway: All
spec:
  hostnames:
    - "apps.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: apps-kubeapps
          port: 80
eof
