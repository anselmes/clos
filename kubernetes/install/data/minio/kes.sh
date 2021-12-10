#!/bin/bash

# create minio kes (required for minio)
# TODO: create secretid for minio kes
vault read auth/approle/role/kms/role-id
vault write -f auth/approle/role/kms/secret-id
