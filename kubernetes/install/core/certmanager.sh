#!/bin/bash

# install certmanager
kubectl cert-manager experimental install -n cert-manager

# add clusterissuer
cat <<-eof | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: default
spec:
  selfSigned: {}
eof
