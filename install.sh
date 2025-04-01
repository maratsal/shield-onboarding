#!/bin/bash
$REGISTRY = "jfrog.idonthaveany.boats"

# Logon to OCI Registry that contains our shield charts
helm registry login $REGISTRY

# Check if the login command was successful (return code 0)
if [ $? -ne 0 ]; then
  echo "Error: Helm registry login failed."
  exit 1
fi

# Start Sysdig Install
helm upgrade --install --create-namespace \
    -n sysdig \
    -f values.yaml -f base-values.yaml -f cluster-specific-values.yaml  \
    shield \
    oci://$REGISTRY/sysdigcharts/shield\
    --version 0.10.0