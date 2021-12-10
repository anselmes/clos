#!/bin/bash

# add gateway crd
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.3.0" | kubectl apply -f -

# install operator
istioctl operator init

# deploy istio
cat <<-eof | kubectl apply -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
  namespace: istio-system
spec:
  profile: default
  values:
    global:
      jwtPolicy: third-party-jwt
      istiod:
        enableAnalysis: false
      proxy:
        autoInject: enabled
eof

# istio gateway certificate
cat <<-eof | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: default-gw-cert
  namespace: istio-system
spec:
  secretName: default-gw-tls
  commonName: lb.${ZONE}.${DOMAIN}
  issuerRef:
    kind: ClusterIssuer
    name: default
  dnsNames:
    - lb.${ZONE}.${DOMAIN}
    - "*.lb.${ZONE}.${DOMAIN}"
eof

# add gateway class
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: GatewayClass
metadata:
  name: istio
spec:
  controller: istio.io/gateway-controller
eof

# add default gateway
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: Gateway
metadata:
  name: default
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
    - hostname: lb.${ZONE}.${DOMAIN}
      port: 443
      protocol: HTTPS
      routes:
        kind: HTTPRoute
        namespaces:
          from: All
        selector:
          matchLabels:
            gateway: istio-default
      tls:
        mode: Terminate
        certificateRef:
          group: core
          kind: Secret
          name: default-gw-tls
        routeOverride:
          certificate: Deny
    - hostname: "*.lb.${ZONE}.${DOMAIN}"
      port: 443
      protocol: HTTPS
      routes:
        kind: HTTPRoute
        namespaces:
          from: All
      tls:
        mode: Terminate
        certificateRef:
          group: core
          kind: Secret
          name: default-gw-tls
        routeOverride:
          certificate: Deny
eof

# annotate default gateway (optional: requires external-dns)
kubectl annotate svc -n istio-system istio-ingressgateway \
  external-dns.alpha.kubernetes.io/hostname="lb.${ZONE}.${DOMAIN},*.lb.${ZONE}.${DOMAIN}" \
  --overwrite
