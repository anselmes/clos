#!/bin/bash

# postres operator
helm upgrade \
  -i postgres-operator postgres-operator \
  -n postgres-operator \
  --create-namespace \
  --reuse-values \
  --repo https://opensource.zalando.com/postgres-operator/charts/postgres-operator

# configure postgres
cat <<-eof | kubectl apply -f -
apiVersion: acid.zalan.do/v1
kind: OperatorConfiguration
metadata:
  name: postgres-operator
  namespace: postgres-operator
configuration:
  kubernetes:
    enable_cross_namespace_secret: true
  load_balancer:
    db_hosted_zone: ${DB_ZONE_NAME}
  logical_backup:
    logical_backup_s3_access_key_id: ${S3_ACCESS_KEY}
    logical_backup_s3_bucket: ${S3_BUCKET_NAME}
    logical_backup_s3_region: ${S3_REGRION}
    logical_backup_s3_endpoint: ${S3_HOST}
    logical_backup_s3_secret_access_key: ${S3_ACCESS_KEY}
  teams_api:
    enable_postgres_team_crd: true
    enable_postgres_team_crd_superusers: true
    enable_teams_api: true
eof

# TODO: review postgres operator ui
cat <<-eof | helm upgrade \
  -i postgres-operator-ui postgres-operator-ui \
  -n postgres-operator \
  --reuse-values \
  --repo https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui \
  -f -
envs:
  teams:
    - local
eof

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: operator-ui
  namespace: postgres-operator
  labels:
    gateway: default
spec:
  gateways:
      allow:  All
  hostnames:
    - "postgres-operator-ui.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: postgres-operator-ui
          port: 80
eof
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: operator-api
  namespace: postgres-operator
  labels:
    gateway: default
spec:
  gateways:
      allow:  All
  hostnames:
    - "postgres-operator-api.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: postgres-operator
          port: 8080
eof
