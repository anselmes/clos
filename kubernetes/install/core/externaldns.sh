#!/bin/bash

export CF_EMAIL="administrator@anselm.es"
export CF_TOKEN="ogdfDrjWqV7jii_ApMlpkb37SDhlMqlC29ujT8QO"
export IF_WAPI_PASSWORD="changeme"
export RFC_2136_TSIG_SECRET="changeme"
export PROVIDER="cloudflare"
export ZONE_NAME="nidavellir.anselmes.cloud"

kubectl create secret generic -n kube-system e-dns-creds \
  --from-literal cloudflare_api_token=${CF_TOKEN} \
  --from-literal infoblox_wapi_password=${IF_WAPI_PASSWORD} \
  --from-literal rfc2136_tsig_secret=${RFC_2136_TSIG_SECRET}

# cloudflare
helm upgrade \
  -i external-dns external-dns \
  -n kube-system \
  --reuse-values \
  --repo https://charts.bitnami.com/bitnami \
  --set crd.create=true \
  --set provider=${PROVIDER} \
  --set cloudflare.apiToken=${CF_TOKEN} \
  --set cloudflare.email=${CF_EMAIL} \
  --set cloudflare.proxied=false
  --set sources="{crd,service,istio-gateway,istio-virtualservice}" \

# rfc2136
# helm upgrade \
#   -i external-dns external-dns \
#   -n kube-system \
#   --reuse-values \
#   --repo https://charts.bitnami.com/bitnami \
#   --set crd.create=true \
#   --set provider=${PROVIDER} \
#   --set rfc2136.host=${RFC_2136_HOST:-127.0.0.1} \
#   --set rfc2136.zone=${ZONE_NAME} \
#   --set rfc2136.secretName="e-dns-creds" \
#   --set rfc2136.tsigKeyname="external-dns" \
#   --set sources="{crd,service,istio-gateway,istio-virtualservice}"

# infoblox
helm upgrade \
  -i external-dns external-dns \
  -n kube-system \
  --reuse-values \
  --repo https://charts.bitnami.com/bitnami \
  --set crd.create=true \
  --set provider='infoblox' \
  --set infoblox.wapiUsername='admin' \
  --set infoblox.wapiPassword='VMware123!' \
  --set infoblox.gridHost='192.168.0.250' \
  --set infoblox.view='default' \
  --set infoblox.noSslVerify=true \
  --set sources='{crd,service}'
