#!/bin/bash

export RELEASE=v0.35.0

# install kubevirt
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml"

# create kubevirt
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml"
