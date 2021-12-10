#!/bin/bash

helm upgrade \
  -i metrics-server metrics-server \
  -n kube-system \
  --reuse-values \
  --repo https://charts.bitnami.com/bitnami
