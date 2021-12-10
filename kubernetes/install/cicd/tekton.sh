#!/bin/bash

# operator
kubectl operator install -C -c alpha -n operators tektoncd-operator

# install
cat <<-eof | kubectl apply -f -
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonConfig
metadata:
  name: config
  namespace: operators
spec:
  profile: all
  targetNamespace: tekton-pipelines
---
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonPipeline
metadata:
  name: pipeline
  namespace: operators
spec:
  targetNamespace: tekton-pipelines
---
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonTrigger
metadata:
  name: trigger
  namespace: operators
spec:
  targetNamespace: tekton-pipelines
---
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonDashboard
metadata:
  name: dashboard
  namespace: operators
spec:
  targetNamespace: tekton-pipelines
---
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonResult
metadata:
  name: result
  namespace: operators
spec:
  targetNamespace: tekton-pipelines
eof

# pipelines
kubectl apply -n pipelines -f https://raw.githubusercontent.com/tektoncd/catalog/main/pipeline/buildpacks/0.1/buildpacks.yaml

# dependencies
tkn hub install -n pipelines task git-clone
tkn hub install -n pipelines task buildpacks
tkn hub install -n pipelines task buildpacks-phases

# lang
tkn hub install -n pipelines task golang-build
tkn hub install -n pipelines task golang-test
tkn hub install -n pipelines task npm

# events
tkn hub install -n pipelines task cloudevent

# utils
tkn hub install -n pipelines task kn
tkn hub install -n pipelines task curl
tkn hub install -n pipelines task ansible-runner
tkn hub install -n pipelines task kubeconfig-creator
tkn hub install -n pipelines task kubernetes-actions

# git
tkn hub install -n pipelines task create-gitlab-release
tkn hub install -n pipelines task gitlab-add-label

# cloud
tkn hub install -n pipelines task kind
tkn hub install -n pipelines task helm-upgrade-from-repo
tkn hub install -n pipelines task eks-cluster-create
tkn hub install -n pipelines task eks-cluster-teardown
