#!/bin/bash

# install redis operator
kubectl create namespace redis-operator
kubectl apply -n redis-operator -f https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/master/bundle.yaml

# patch operator
CERT=$(kubectl view-secret -n redis-operator admission-tls cert)
CERT_BASE_64=$(encode64 ${CERT})
curl https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/master/admission/webhook.yaml | \
  sed -e 's/NAMESPACE_OF_SERVICE_ACCOUNT/redis-operator/g' | \
  kubectl create -f -
# TODO: review patching
cat <<-eof | kubectl patch validatingwebhookconfiguration redb-admission --type merge -p -
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: redb-admission
webhooks:
  - name: redb.admission.redislabs
    admissionReviewVersions:
      - v1
    clientConfig:
      caBundle: ${CERT_BASE_64}
eof
