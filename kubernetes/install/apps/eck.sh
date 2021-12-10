#!/bin/bash

# install enterprise search
cat <<-eof | kubectl apply -f -
apiVersion: enterprisesearch.k8s.elastic.co/v1
kind: EnterpriseSearch
metadata:
  name: enterprise-search
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  count: ${ECK_SEARCH_COUNT:-1}
  elasticsearchRef:
    name: elasticsearch
eof

# install apm server
cat <<-eof | kubectl apply -f -
apiVersion: apm.k8s.elastic.co/v1
kind: ApmServer
metadata:
  name: apm-server
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  count: ${APM_SVR_COUNT:-1}
  elasticsearchRef:
    name: elasticsearch
  kibanaRef:
      name: kibana
  config:
    name: elastic-apm
    apm-server.jaeger.grpc.enabled: true
    apm-server.jaeger.grpc.host: 0.0.0.0:14250
  http:
    service:
      spec:
        ports:
          - name: http
            port: 8200
            targetPort: 8200
          - name: grpc
            port: 14250
            targetPort: 14250
eof

# install kibana
cat <<-eof | kubectl apply -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  count: ${KIBANA_COUNT:-1}
  elasticsearchRef:
    name: elasticsearch
    namespace: default
  enterpriseSearchRef:
    name: enterprise-search
  config:
    xpack.fleet.agents.elasticsearch.host: "https://elasticsearch-es-http.default.svc:9200"
    xpack.fleet.agents.fleet_server.hosts: ["https://fleet-server-agent-http.default.svc:8220"]
    xpack.fleet.packages:
      - name: kubernetes
        version: latest
      - name: apm
        version: latest
      - name: docker
        version: latest
    xpack.fleet.agentPolicies:
      - name: Default Fleet Server on ECK policy
        is_default_fleet_server: true
        package_policies:
          - name: fleet_server-1
            package:
              name: fleet_server
      - name: Default Elastic Agent on ECK policy
        is_default: true
        unenroll_timeout: 900
        package_policies:
          - name: system-1
            package:
              name: system
          - name: docker-1
            package:
              name: docker
          - name: mongodb-1
            package:
              name: mongodb
          - name: postgresql-1
            package:
              name: postgresql
          - name: redis-1
            package:
              name: redis
          - name: rabbitmq-1
            package:
              name: rabbitmq
          - name: auditd-1
            package:
              name: auditd
          - name: linux-1
            package:
              name: linux
          - name: panw-1
            package:
              name: panw
          - name: network_traffic-1
            package:
              name: network_traffic
          - name: netflow-1
            package:
              name: netflow
          - name: iptables-1
            package:
              name: iptables
          - name: apm-1
            package:
              name: apm
            inputs:
              - type: apm
                enabled: true
                vars:
                  - name: host
                    value: 0.0.0.0:8200
          - name: docker-1
            package:
              name: docker
          - name: mongodb-1
            package:
              name: mongodb
          - name: postgresql-1
            package:
              name: postgresql
          - name: redis-1
            package:
              name: redis
          - name: rabbitmq-1
            package:
              name: rabbitmq
          - name: auditd-1
            package:
              name: auditd
          - name: linux-1
            package:
              name: linux
          - name: panw-1
            package:
              name: panw
          - name: network_traffic-1
            package:
              name: network_traffic
          - name: netflow-1
            package:
              name: netflow
          - name: iptables-1
            package:
              name: iptables
eof

# install fleet-managed agents
cat <<-eof | kubectl apply -f -
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: fleet-server
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  elasticsearchRefs:
    - name: elasticsearch
  kibanaRef:
    name: kibana
  mode: fleet
  fleetServerEnabled: true
  deployment:
    replicas: ${FLEET_AGENT_RC:-1}
    podTemplate:
      spec:
        serviceAccountName: fleet-server
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0
---
apiVersion: agent.k8s.elastic.co/v1alpha1
kind: Agent
metadata:
  name: elastic-agent
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  kibanaRef:
    name: kibana
  fleetServerRef:
    name: fleet-server
  mode: fleet
  daemonSet:
    podTemplate:
      spec:
        serviceAccountName: elastic-agent
        hostNetwork: true
        dnsPolicy: ClusterFirstWithHostNet
        automountServiceAccountToken: true
        securityContext:
          runAsUser: 0
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fleet-server
  namespace: default
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: elastic-agent
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fleet-server
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - nodes
    verbs:
      - get
      - watch
      - list
  - apiGroups: ["coordination.k8s.io"]
    resources:
      - leases
    verbs:
      - get
      - create
      - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: elastic-agent
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - nodes
      - namespaces
      - events
      - services
      - configmaps
    verbs:
      - get
      - watch
      - list
  - apiGroups: ["coordination.k8s.io"]
    resources:
      - leases
    verbs:
      - get
      - create
      - update
  - nonResourceURLs:
      - "/metrics"
    verbs:
      - get
  - apiGroups: ["extensions"]
    resources:
      - replicasets
    verbs:
      - "get"
      - "list"
      - "watch"
  - apiGroups:
      - "apps"
    resources:
      - statefulsets
      - deployments
      - replicasets
    verbs:
      - "get"
      - "list"
      - "watch"
  - apiGroups:
      - ""
    resources:
      - nodes/stats
    verbs:
      - get
  - apiGroups:
      - "batch"
    resources:
      - jobs
    verbs:
      - "get"
      - "list"
      - "watch"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fleet-server
subjects:
  - kind: ServiceAccount
    name: fleet-server
    namespace: default
roleRef:
  kind: ClusterRole
  name: fleet-server
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: elastic-agent
subjects:
  - kind: ServiceAccount
    name: elastic-agent
    namespace: default
roleRef:
  kind: ClusterRole
  name: elastic-agent
  apiGroup: rbac.authorization.k8s.io
eof

# install maps server
cat <<-eof | kubectl apply -f -
apiVersion: maps.k8s.elastic.co/v1alpha1
kind: ElasticMapsServer
metadata:
  name: elasticsearch-maps-server
  namespace: default
spec:
  version: ${ECK_VERSION:-7.15.0}
  count: ${ECK_MAPS_COUNT:-1}
  elasticsearchRef:
    name: elasticsearch
eof

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: kibana
  namespace: default
  labels:
    gateway: default
spec:
  gateways:
      allow:  All
  hostnames:
    - "kibana.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: kibana-kb-http
          port: 5601
eof
