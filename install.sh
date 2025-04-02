#!/bin/bash

# Source functions used by this script
source ./helpers/functions.sh

# Run preinstall Checks
chmod +x ./helpers/pre-install-validation.sh
./helpers/pre-install-validation.sh

# Check the exit code of pre-install-validation.sh
if [ $? -ne 0 ]; then
    echo -e "\e[31mPre-install validation FAILED.\e[0m"
    while true; do
        read -p "Do you still want to continue with the installation? (yes/no): " CONTINUE_AFTER_FAILURE
        if [[ "$CONTINUE_AFTER_FAILURE" == "yes" || "$CONTINUE_AFTER_FAILURE" == "no" ]]; then
            break
        else
            echo "Please enter 'yes' or 'no'."
        fi
    done
    if [[ "$CONTINUE_AFTER_FAILURE" != "yes" ]]; then
        echo "Installation aborted by the user due to pre-install validation failure."
        exit 1
    fi
fi

# Extract values from cluster-specific-values.yaml
SHIELD_CHART_VERSION=$(grep '# Shield Chart:' cluster-specific-values.yaml | awk '{print $4}')
REGISTRY=$(grep '# OCI Registry:' cluster-specific-values.yaml | awk '{print $4}')

# Check if the values exist, if not, error out
if [[ -z "$SHIELD_CHART_VERSION" ]]; then
    echo "Error: Shield Chart version not found in cluster-specific-values.yaml"
    exit 1
fi

if [[ -z "$REGISTRY" ]]; then
    echo "Error: OCI Registry not found in cluster-specific-values.yaml"
    exit 1
fi

# If change_me is present in cluster-specific-values.yaml assume they need to update the values

if grep -q "CHANGE_ME" cluster-specific-values.yaml; then
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

# Check to see if access key was specified in cluster-specific-values.yaml
ACCESS_KEY=$(grep 'access_key:' cluster-specific-values.yaml | awk '{print $2}' | tr -d '"')

if [[ -z "$ACCESS_KEY" && -z "$SYSDIG_ACCESS_KEY" ]]; then
    update_sysdig_accesskey
fi

# Get the namespace from the user
update_namespace

# Call the function to confirm values
confirm_values

# Logon to OCI Registry that contains our shield charts
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
sleep 300
chmod +x ./helpers/post-install-validation.sh
./helpers/post-install-validation.sh $NAMESPACE

# Commit configuration to git

# Read cluster name from cluster-specific-values.yaml and save it as a variable
CLUSTER_NAME=$(grep 'name:' cluster-specific-values.yaml | head -1 | awk '{print $2}' | tr -d '"')

if [[ -z "$CLUSTER_NAME" ]]; then
    echo "Error: Unable to find cluster name"
    exit 1
fi

git checkout -b $CLUSTER_NAME
git add .
git commit -m "Commiting config for $CLUSTER_NAME on $(date +%Y-%m-%d)"
git push -u origin $CLUSTER_NAME

