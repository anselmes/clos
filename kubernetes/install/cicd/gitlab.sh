#!/bin/bash

# TODO: create oss

# TODO: add oss creds

# install gitlab
helm upgrade -i \
  -n default \
  --reuse-values \
  --repo https://charts.gitlab.io \
  --set global.hosts.domain=${GITLAB_BASE_DOMAIN} \
  --set global.hosts.https=true \
  --set global.hosts.gitlab.name=gitlab.${GITLAB_BASE_DOMAIN} \
  --set global.hosts.ssh.name=git.${GITLAB_BASE_DOMAIN} \
  --set global.hosts.registry.name=registry.${GITLAB_BASE_DOMAIN} \
  --set global.hosts.pages.name=pages.${GITLAB_BASE_DOMAIN} \
  --set global.ingress.enabled=false \
  --set global.gitlab.license.secret=gitlab-license \
  --set global.gitlab.license.key=license \
  --set global.initialRootPassword.secret=gitlab-credentials \
  --set global.initialRootPassword.key=password \
  --set global.psql.password.secret=gitlab-db-creds \
  --set global.psql.password.key=psql_password \
  --set global.psql.host=local-${CLUSTER_NAME}-pooler.default.svc.cluster.local \
  --set global.psql.port=5432 \
  --set global.psql.database=gitlab \
  --set global.psql.username=gitlab \
  --set global.psql.ssl.secret=${GITLAB_PG_SSL} \
  --set global.psql.ssl.serverCA='' \
  --set global.psql.ssl.clientCertificate='' \
  --set global.psql.ssl.clientKey='' \
  --set global.redis.password.secret=gitlab-db-creds \
  --set global.redis.password.key=redis_password \
  --set global.redis.host=redis-headless.default.svc.cluster.local \
  --set global.redis.port=6379 \
  --set global.redis.scheme=rediss \
  --set global.minio.enabled=false \
  --set global.appConfig.object_store.enabled=true \
  --set global.appConfig.connection.secret=gitlab-oss-creds \
  --set global.appConfig.connection.key=gitlab \
  --set global.pages.enabled=true \
  --set global.pages.accessControl=true \
  --set global.pages.objectStore.connection.secret=gitlab-oss-creds \
  --set global.pages.objectStore.connection.key=pages \
  --set global.time_zone=America/Toronto \
  --set global.tracing.connection.string=opentracing://jeager?http_endpoint=http://apm-server-apm-http.default.svc.cluster.local:14250
  --set certmanager.installCRDs=false \
  --set certmanager.install=false \
  --set nginx-ingress.enabled=false \
  --set prometheus.install=false \
  --set redis.install=false \
  --set postgresql.install=false \
  --set gitaly.persistence.storageClass=openebs-cstor-csi
