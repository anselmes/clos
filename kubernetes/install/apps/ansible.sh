#!/bin/bash

# install
helm upgrade -i awx awx \
  --repo https://adwerx.github.io/charts \
  --create-namespace -n ansible \
  --set secretKey=changeme \
  --set secret_key=changeme \
  --set defaultAdminUser=admin \
  --set default_admin_user=admin \
  --set defaultAdminPassword=changeme \
  --set default_admin_password=changeme \
  --set service.type=LoadBalancer \
  --set postgresql.postgresqlUsername=awx \
  --set postgresql.postgresqlPassword=changeme \
  --set postgresql.postgresqlDatabase=awx \
  --set postgresql.persistence.enabled=true \
  --set postgresql.metrics.enabled=false \
  --set extraConfiguration='INSIGHTS_URL_BASE: "https://awx.${ZONE}.local"'

# ingress
cat <<-eof | kubectl apply -f -
apiVersion: networking.x-k8s.io/v1alpha1
kind: HTTPRoute
metadata:
  name: awx
  namespace: ansible
  labels:
    gateway: All
spec:
  hostnames:
    - "ansible.lb.${PRIMARY_DOMAIN_NAME}"
  rules:
    - forwardTo:
        - serviceName: awx
          port: 8080
eof
