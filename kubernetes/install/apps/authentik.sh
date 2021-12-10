#!/bin/bash

helm upgrade -i authentik authentik \
  --repo https://charts.goauthentik.io \
  --create namespace -n authentik \
  --set authentik.secret_key="${SECRET_KEY}" \
  --set s3_backup.access_key="${ACCESS_KEY}" \
  --set s3_backup.secret_key="${SECRET_KEY}" \
  --set s3_backup.bucket="${BUCKET_NAME}" \
  --set s3_backup.host="${S3_HOST}" \
  --set s3_backup.insecure_skip_verify: true \
  --set postgresql.host=acid-authentik \
  --set postgresql.name=authentik \
  --set postgresql.user=postgres \
  --set postgresql.password=${POSGRES_PASSWORD} \
  --set redis.password="${REDIS_PASSWORD}" \
  --set redis.enabled=true \
  --set redis.auth.enabled=true

# create postgresql
cat <<-eof | kubectl apply -f -
kind: "postgresql"
apiVersion: "acid.zalan.do/v1"
metadata:
  name: "acid-authentik"
  namespace: "authentik"
  labels:
    team: acid
spec:
  teamId: "acid"
  postgresql:
    version: "13"
  numberOfInstances: 1
  volume:
    size: "10Gi"
  users:
    authentik: []
  databases:
    authentik: authentik
  allowedSourceRanges:
    # IP ranges to access your cluster go here
  resources:
    requests:
      cpu: 100m
      memory: 100Mi
    limits:
      cpu: 500m
      memory: 500Mi
eof
