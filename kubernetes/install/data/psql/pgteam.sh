#!/bin/bash

# create team
cat <<-eof | kubectl apply -f -
apiVersion: acid.zalan.do/v1
kind: PostgresTeam
metadata:
  name: local
  namespace: default
spec:
  additionalSuperuserTeams:
    acid:
      - postgres_superusers
    cloudos:
      - postgres_superusers
  additionalTeams:
    acid: []
    cloudos: []
    postgres_superusers: []
  additionalMembers:
    acid:
      - cloudos
    cloudos:
      - cloudos
      - admin
eof
