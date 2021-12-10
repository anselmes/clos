#!/bin/bash

helm upgrade \
  -i external-secrets kubernetes-external-secrets \
  -n kube-system \
  --reuse-values \
  --repo https://external-secrets.github.io/kubernetes-external-secrets
