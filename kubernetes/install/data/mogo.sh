#!/bin/bash

# install operator
helm upgrade \
  -i mongodb-enterprise-operator mongodb-enterprise-operator \
  -n mongodb-operator \
  --reuse-values \
  --create-namespace \
  --repo https://mongodb.github.io/helm-charts \
  --set watchNamespace="*"

# create admin api key
kubectl create secret generic ops-manager-admin-key \
  -n mongodb-operator \
  --from-literal=user=${OPS_MGR_USER} \
  --from-literal=publicApiKey=${OPS_MGR_PUB_API_KEY}

# add oss creds
kubectl create secret generic mongodb-oss-creds \
  -n mongodb-operator \
  --from-literal=accessKey=${S3_ACCESS_KEY:-mongo} \
  --from-literal=secretKey=${S3_SECRET_KEY}

# create admin creds
kubectl create secret generic ops-manager-admin-creds \
  -n default \
  --from-literal=FirstName=Ops \
  --from-literal=LastName=Manager \
  --from-literal=Username=admin \
  --from-literal=Password=${OPS_MGR_ADMIN_PWD}

# install ops-manager
cat <<-eof | kubectl apply -f -
apiVersion: mongodb.com/v1
kind: MongoDBOpsManager
metadata:
  name: ops-manager
  namespace: default
spec:
  version: 5.0.0
  replicas: ${OPS_MANAGER_RC:-1}
  adminCredentials: ops-manager-admin-creds
  applicationDatabase:
    members: 3
    podSpec:
      persistence:
        single:
          storageClass: openebs-cstor-csi
  agent:
    startupOptions:
      serverSelectionTimeoutSeconds: "20"
  configuration:
    automation.versions.source: mongodb
    mms.ignoreInitialUiSetup: "true"
    mms.adminEmailAddr: admin@opsmanager.local
    mms.fromEmailAddr: support@opsmanager.local
    mms.replyToEmailAddr: no-reply@opsmanager.local
    mms.mail.hostname: ${SMTP_EMAIL:-'email-smtp.us-east-1.amazonaws.com'}
    mms.mail.port: "465"
    mms.mail.ssl: "true"
    mms.mail.transport: smtp
    mms.minimumTLSVersion: TLSv1.2
eof

# add config & secret
cat <<-eof | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongodb-${CLUSTER_NAME}
  namespace: default
data:
  baseUrl: http://ops-manager-svc.default.svc.cluster.local:8080
  projectName: ${OPS_MGR_PROJECT_NAME}
  orgId: ${OPS_MGR_ORG_ID}
eof

cat <<-eof | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-${CLUSTER_NAME}-creds
  namespace: default
stringData:
  user: ${OPS_MGR_USER}
  publicApiKey: ${OPS_MGR_PUB_API_KEY}
eof

# create cluster
cat <<-eof | kubectl apply -f -
apiVersion: mongodb.com/v1
kind: MongoDB
metadata:
  name: mongodb
  namespace: default
spec:
  version: 5.0.0
  type: ReplicaSet
  members: 3
  logLevel: WARN
  persistent: true
  service: mongodb-${CLUSTER_NAME}-svc
  credentials: mongodb-${CLUSTER_NAME}-creds
  opsManager:
    configMapRef:
      name: mongodb-${CLUSTER_NAME}
  agent:
    startupOptions:
      maxLogFiles: "30"
      dialTimeoutSeconds: "40"
  podSpec:
    persistence:
      single:
        storageClass: openebs-cstor-csi
eof
