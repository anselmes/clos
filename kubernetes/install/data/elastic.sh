#!/bin/bash

# install eck-operator
kubectl operator install -C -c stable -n operators elastic-cloud-eck

# create eck cluster
cat <<-eof | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  nodeSets:
  - name: default
    count: ${ECK_NODE_COUNT:-1}
    config:
      xpack.ml.enabled: true
      node.store.allow_mmap: false
      node.roles:
        - master
        - data
        - ingest
        - ml
        - transform
    volumeClaimTemplates:
      - metadata:
          name: elasticsearch-data # Do not change this name unless you set up a volume mount for the data path.
        spec:
          storageClassName: openebs-lvm-localpv
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: ${ECK_DISK_SIZE:-50}Gi
    podTemplate:
          spec:
            initContainers:
            - name: install-plugins
              command:
              - sh
              - -c
              - |
                bin/elasticsearch-plugin install --batch repository-gcs
                bin/elasticsearch-plugin install --batch analysis-icu
eof

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: elastic
  namespace: default
  labels:
    gateway: default
spec:
  gateways:
      allow:  All
  hostnames:
    - "elastic.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: elastic-es-http
          port: 5601
eof
