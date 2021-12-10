#!/bin/bash

# create redis database
cat <<-eof | kubectl apply -f -
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: redis-${CLUSTER_NAME}-db
  namespace: redis-operator
spec: {}
eof
