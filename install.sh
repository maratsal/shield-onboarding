#!/bin/bash

# Source functions used by this script
source ./helpers/functions.sh

# Run preinstall Checks
chmod +x ./helpers/pre-install-validation.sh
./helpers/pre-install-validation.sh

# Ask the user if they want to continue after viewing the pre-install validations
read -p "Do you want to continue with the installation after reviewing the pre-install validations? (yes/no): " CONTINUE_INSTALL

if [[ "$CONTINUE_INSTALL" != "yes" ]]; then
    echo "Installation aborted by the user."
    exit 0
fi

# Check to see if the user wants to answer or if they've already filled out the cluster-specific-values.yaml manually
read -p "Have you already updated the cluster-specific-values.yaml file? (yes/no): " UPDATE_FILE

if [[ "$UPDATE_FILE" == "no" ]]; then
    update_sysdig_accesskey  # Get Access Key and Set as Variable
    update_cluster_name      # Get Cluster Name and Update Values
    update_vz_vsadid         # Get vz-vsadid and Update Values   
    update_vz_vastid         # Get vz-vastid and Update Values
    update_proxy_settings    # Get Proxy Settings and Update Values
    update_priority_class    # Get Priority Class and Update Values
else
    echo "Skipping updates to cluster-specific-values.yaml as it was already updated manually."
    echo
fi

# Get the namespace from the user
update_namespace

# Call the function to confirm values
confirm_values

# Logon to OCI Registry that contains our shield charts
REGISTRY="jfrog.idonthaveany.boats"
SHIELD_CHART_VERSION=0.10.0
echo "Logging into OCI Registry: $REGISTRY"
helm registry login $REGISTRY

# Check if the login command was successful (return code 0)
if [ $? -ne 0 ]; then
  echo "Error: Helm registry login failed."
  exit 1
fi


# Start Sysdig Install
helm upgrade --install --create-namespace \
    -n $NAMESPACE \
    -f ./helpers/base-values.yaml -f cluster-specific-values.yaml  \
    --set sysdig_endpoint.access_key=$SYSDIG_ACCESS_KEY \
    shield \
    oci://$REGISTRY/sysdigcharts/shield\
    --version $SHIELD_CHART_VERSION


# Run post-install validation
echo
echo "Sleeping for 5 minutes to allow for pods to start..."
sleep 600
chmod +x ./helpers/post-install-validation.sh
./helpers/post-install-validation.sh $NAMESPACE
