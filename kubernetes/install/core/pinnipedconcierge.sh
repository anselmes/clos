#!/bin/bash

# install pinnped concierge
kubectl apply -f https://get.pinniped.dev/v0.12.0/install-pinniped-concierge-crds.yaml
kubectl apply -f https://get.pinniped.dev/v0.12.0/install-pinniped-concierge.yaml
