#!/bin/bash

# cluster
cat <<-eof | kubectl apply -f -
apiVersion: redis.redis.opstreelabs.in/v1beta1
kind: RedisCluster
metadata:
  name: redis
spec:
  clusterSize: ${REDIS_CL_RC:-1}
  kubernetesConfig:
    image: 'quay.io/opstree/redis:v6.2.5'
  redisExporter:
    enabled: false
    image: 'quay.io/opstree/redis-exporter:1.0'
  redisLeader:
    serviceType: ClusterIP
  redisFollower:
    serviceType: ClusterIP
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: openebs-cstor-csi
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
eof
