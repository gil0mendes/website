#!/bin/bash

# prepare nomad client to connect with the server
mkdir -p /opt/certs
echo "$NOMAD_TMP_CERT" > /opt/certs/ca.pem
export NOMAD_CACERT="/opt/certs/ca.pem"

# do the deploy
levant deploy deploy/job.nomadtpl
