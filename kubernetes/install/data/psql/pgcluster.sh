#!/bin/bash

# create cluster
cat <<-eof | kubectl apply -f -
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  name: local-${CLUSTER_NAME}
  namespace: default
  labels:
    team: local
spec:
  teamId: local
  postgresql:
    version: "13"
  numberOfInstances: ${PG_INSTANCES_NUMBER:-1}
  enableConnectionPooler: true
  allowedSourceRanges: []
  volume:
    size: ${PG_VOL_SIZE:-120}Gi
    storageClass: openebs-device
  users:
    cloudos:
      - superuser
      - createdb
  databases:
    ${CLUSTER_NAME}: cloudos
  preparedDatabases: {}
  # standby: # for standby cluster
  #   s3_wal_path: "s3://${PG_S3_PATH}"
eof
