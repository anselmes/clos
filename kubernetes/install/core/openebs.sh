#!/bin/bash

# operator
kubectl operator install -C -c alpha -n operators openebs
# kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount operators:openebs-operator ebs-admin # TODO: review

# install
kubectl create ns openebs
cat <<-eof | kubectl apply -f -
apiVersion: openebs.io/v1alpha1
kind: OpenEBSInstallTemplate
metadata:
  name: oebs
  namespace: openebs
spec:
  rbac:
    create: true
    pspEnabled: false
    kyvernoEnabled: false
  serviceAccount:
    create: true
    name: openebs-maya-operator
  imagePullSecrets: []
  release:
    version: 3.0.0
  legacy:
    enabled: false
  image:
    pullPolicy: IfNotPresent
    repository: ''
  apiserver:
    enabled: true
    image: openebs/m-apiserver
    imageTag: 2.12.2
    replicas: 1
    ports:
      externalPort: 5656
      internalPort: 5656
    sparse:
      enabled: 'true'
    nodeSelector: {}
    tolerations: []
    affinity: {}
    healthCheck:
      initialDelaySeconds: 30
      periodSeconds: 60
    resources: {}
  defaultStorageConfig:
    enabled: 'true'
  varDirectoryPath:
    baseDir: /var/openebs
  provisioner:
    enabled: true
    image: openebs/openebs-k8s-provisioner
    imageTag: 2.12.2
    replicas: 1
    enableLeaderElection: true
    patchJivaNodeAffinity: enabled
    nodeSelector: {}
    tolerations: []
    affinity: {}
    healthCheck:
      initialDelaySeconds: 30
      periodSeconds: 60
    resources: {}
  localprovisioner:
    enabled: true
    image: openebs/provisioner-localpv
    imageTag: 3.0.0
    replicas: 1
    enableLeaderElection: true
    enableDeviceClass: true
    enableHostpathClass: true
    basePath: /var/openebs/local
    waitForBDBindTimeoutRetryCount: '12'
    nodeSelector: {}
    tolerations: []
    affinity: {}
    healthCheck:
      initialDelaySeconds: 30
      periodSeconds: 60
    resources: {}
  snapshotOperator:
    enabled: true
    controller:
      image: openebs/snapshot-controller
      imageTag: 2.12.2
      resources: {}
    provisioner:
      image: openebs/snapshot-provisioner
      imageTag: 2.12.2
      resources: {}
    replicas: 1
    enableLeaderElection: true
    upgradeStrategy: Recreate
    nodeSelector: {}
    tolerations: []
    affinity: {}
    healthCheck:
      initialDelaySeconds: 30
      periodSeconds: 60
  ndm:
    enabled: true
    image: openebs/node-disk-manager
    imageTag: 1.7.0
    sparse:
      path: /var/openebs/sparse
      size: '10737418240'
      count: '0'
    filters:
      enableOsDiskExcludeFilter: true
      osDiskExcludePaths: //etc/hosts/boot
      enableVendorFilter: true
      excludeVendors: 'CLOUDBYT,OpenEBS'
      enablePathFilter: true
      includePaths: ''
      excludePaths: /dev/loop/dev/fd0/dev/sr0/dev/ram/dev/dm-/dev/md/dev/rbd/dev/zd
    probes:
      enableSeachest: true
    nodeSelector: {}
    tolerations: []
    healthCheck:
      initialDelaySeconds: 30
      periodSeconds: 60
    resources: {}
  ndmOperator:
    enabled: true
    image: openebs/node-disk-operator
    imageTag: 1.7.0
    replicas: 1
    upgradeStrategy: Recreate
    nodeSelector: {}
    tolerations: []
    healthCheck:
      initialDelaySeconds: 15
      periodSeconds: 20
    readinessCheck:
      initialDelaySeconds: 5
      periodSeconds: 10
    resources: {}
  ndmExporter:
    enabled: true
    image:
      registry: null
      repository: openebs/node-disk-exporter
      pullPolicy: IfNotPresent
      tag: 1.7.0
    nodeExporter:
      name: ndm-node-exporter
      podLabels:
        name: openebs-ndm-node-exporter
      metricsPort: 9101
    clusterExporter:
      name: ndm-cluster-exporter
      podLabels:
        name: openebs-ndm-cluster-exporter
      metricsPort: 9100
  webhook:
    enabled: true
    image: openebs/admission-server
    imageTag: 2.12.2
    failurePolicy: Fail
    replicas: 1
    healthCheck:
      initialDelaySeconds: 30
      periodSeconds: 60
    nodeSelector: {}
    tolerations: []
    affinity: {}
    hostNetwork: false
    resources: {}
  helper:
    image: openebs/linux-utils
    helperImageTag: 3.0.0
  featureGates:
    enabled: true
    GPTBasedUUID:
      enabled: true
      featureGateFlag: GPTBasedUUID
    APIService:
      enabled: true
      featureGateFlag: APIService
      address: '0.0.0.0:9115'
    UseOSDisk:
      enabled: false
      featureGateFlag: UseOSDisk
    ChangeDetection:
      enabled: true
      featureGateFlag: ChangeDetection
  crd:
    enableInstall: true
  policies:
    monitoring:
      enabled: true
      image: openebs/m-exporter
      imageTag: 2.12.2
  analytics:
    enabled: true
    pingInterval: 24h
  jiva:
    image: openebs/jiva
    imageTag: 2.12.2
    replicas: 3
    defaultStoragePath: /var/openebs
    enabled: false
    openebsLocalpv:
      enabled: false
    localpv-provisioner:
      openebsNDM:
        enabled: false
  cstor:
    pool:
      image: openebs/cstor-pool
      imageTag: 2.12.2
    poolMgmt:
      image: openebs/cstor-pool-mgmt
      imageTag: 2.12.2
    target:
      image: openebs/cstor-istgt
      imageTag: 2.12.2
    volumeMgmt:
      image: openebs/cstor-volume-mgmt
      imageTag: 2.12.2
    enabled: true
    openebsNDM:
      enabled: false
  openebs-ndm:
    enabled: true
  localpv-provisioner:
    enabled: true
    openebsNDM:
      enabled: false
  zfs-localpv:
    enabled: false
  lvm-localpv:
    enabled: true
  nfs-provisioner:
    enabled: true
  cleanup:
    image:
      registry: ''
      repository: bitnami/kubectl
      tag: ''
      imagePullSecrets: []
eof

# default storage class
kubectl annotate sc openebs-hostpath storageclass.kubernetes.io/is-default-class="true" --overwrite
