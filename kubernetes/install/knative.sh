#!/bin/bash

# operator
kubectl operator install -C -c alpha -n operators knative-operator

# install
cat <<-eof | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: knative-serving
  labels:
    istio-injection: enabled
---
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: knative-serving
spec:
  mtls:
    mode: PERMISSIVE
---
apiVersion: operator.knative.dev/v1alpha1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
spec:
  high-availability:
    replicas: 3
  config:
    features:
      autodetect-http2: "enabled"
    network:
      autoTLS: "Enabled"
      httpProtocol: "Redirected"
    domain:
      "svc.${KN_DOMAIN_NAME}": ""
eof

# addons
kubectl apply -f https://github.com/knative/serving/releases/download/v0.24.0/serving-hpa.yaml
kubectl apply -f https://github.com/knative/net-certmanager/releases/download/v0.24.0/release.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/v0.24.0/serving-nscert.yaml

# patch
envsubst <<-eof # TODO: patch config-certmanager
  issuerRef: |
    kind: ClusterIssuer
    name: ${KN_CLUSTER_ISSUER}
eof
