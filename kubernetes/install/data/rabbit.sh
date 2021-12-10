#!/bin/bash

# install rabbitmq operator
kubectl rabbitmq install-cluster-operator

# create cluster
kubectl rabbitmq create ${CLUSTER_NAME} -n default --replicas ${RABBIT_RC:-1} --storage-class openebs-cstor-csi

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: rabbitmq
  namespace: default
  labels:
    gateway: default
spec:
  gateways:
      allow:  All
  hostnames:
    - "rabbitmq.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: andromeda-nodes
          port: 4369
eof
