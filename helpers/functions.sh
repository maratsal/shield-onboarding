#!/bin/bash

#
# Check for kubectl or oc binary presence
#
if ! command -v kubectl &> /dev/null; then
  if command -v oc &> /dev/null; then
    kubectl() {
      # Call 'oc' with the same arguments passed to 'kubectl'
      command oc "$@"
    }
  else
    echo -e "\033[31mkubectl or oc is not installed or not in PATH. Please install kubectl or oc before proceeding.\033[0m"
    exit 1
  fi
fi

update_vz_vsadid() {
    # Extract the current value of "vz-vsadid" from the YAML file
    CURRENT_VZ_VSADID=$(grep 'vz-vsadid:' cluster-specific-values.yaml | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    if [[ "$CURRENT_VZ_VSADID" == "\"CHANGE_ME\"" ]]; then
        RESPONSE="yes"
    else
        echo "The current value of 'vz-vsadid' is: $CURRENT_VZ_VSADID"
        while true; do
            read -p "Do you want to change it? (yes/no): " RESPONSE
            if [[ "$RESPONSE" == "yes" || "$RESPONSE" == "no" ]]; then
                break
            else
                echo "Please enter 'yes' or 'no'."
            fi
        done
    fi

    if [[ "$RESPONSE" == "yes" ]]; then
        while true; do
            read -p "Enter the new value for 'vz-vsadid' (only lowercase letters and numbers, max length 10): " NEW_VZ_VSADID

            # Validate the input: only lowercase letters and numbers, max length 10
            if [[ "$NEW_VZ_VSADID" =~ ^[a-z0-9]{1,10}$ ]]; then
                break
            else
                echo "Invalid input. Please enter only lowercase letters and numbers with a maximum length of 10."
            fi
        done

        # Update the value in the YAML file
        yq eval -i '.cluster_config.tags.vz-vsadid = "'"$NEW_VZ_VSADID"'"' cluster-specific-values.yaml

        CURRENT_VZ_VSADID=$NEW_VZ_VSADID
    else
        echo "No changes made to 'vz-vsadid'."
    fi
    echo
}
update_vz_vastid() {
    # Extract the current value of "vz-vastid" from the YAML file
    CURRENT_VZ_VASTID=$(grep 'vz-vastid:' cluster-specific-values.yaml | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    if [[ "$CURRENT_VZ_VASTID" == "\"CHANGE_ME\"" ]]; then
        RESPONSE="yes"
    else
        echo "The current value of 'vz-vastid' is: $CURRENT_VZ_VASTID"
        while true; do
            read -p "Do you want to change it? (yes/no): " RESPONSE
            if [[ "$RESPONSE" == "yes" || "$RESPONSE" == "no" ]]; then
                break
            else
                echo "Please enter 'yes' or 'no'."
            fi
        done
    fi

        if [[ "$RESPONSE" == "yes" ]]; then
            while true; do
                read -p "Enter the new value for 'vz-vastid' (only lowercase letters and numbers, max length 10): " NEW_VZ_VASTID

                # Validate the input: only lowercase letters and numbers, max length 10
                if [[ "$NEW_VZ_VASTID" =~ ^[a-z0-9]{1,10}$ ]]; then
                    break
                else
                    echo "Invalid input. Please enter only lowercase letters and numbers with a maximum length of 10."
                fi
            done

            # Update the value in the YAML file
            yq eval -i '.cluster_config.tags.vz-vastid = "'"$NEW_VZ_VASTID"'"' cluster-specific-values.yaml

            CURRENT_VZ_VASTID=$NEW_VZ_VASTID
        else
            echo "No changes made to 'vz-vastid'."
        fi
    echo
}
update_cluster_name() {
    # Extract the current value of cluster name from the YAML file
    CURRENT_CLUSTER_NAME=$(grep 'name:' cluster-specific-values.yaml | head -1 | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    if [[ "$CURRENT_CLUSTER_NAME" == "\"CHANGE_ME\"" ]]; then
        RESPONSE="yes"
    else
        echo "The current cluster name is: $CURRENT_CLUSTER_NAME"
        while true; do
            read -p "Do you want to change it? (yes/no): " RESPONSE
            if [[ "$RESPONSE" == "yes" || "$RESPONSE" == "no" ]]; then
                break
            else
                echo "Please enter 'yes' or 'no'."
            fi
        done
    fi

    if [[ "$RESPONSE" == "yes" ]]; then
        while true; do
            read -p "Enter Business Unit Name: " BUSINESS_UNIT

            # Validate Business Unit name: must be 1-63 characters, lowercase, alphanumeric, or '-' and must start/end with alphanumeric
            if [[ "$BUSINESS_UNIT" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] && [[ ${#BUSINESS_UNIT} -le 63 ]]; then
                break
            else
                echo "Invalid Business Unit name. It must be 1-63 characters long, contain only lowercase letters, numbers, or '-', and start/end with an alphanumeric character."
            fi
        done

        while true; do
            read -p "Enter the environment (allowed values: test, dev, qa, stg, preprod, prod): " ENVIRONMENT

            # Validate the environment input
            if [[ "$ENVIRONMENT" =~ ^(test|dev|qa|stg|preprod|prod)$ ]]; then
            break
            else
            echo "Invalid environment. Please enter one of the allowed values: test, dev, qa, stg, preprod, prod."
            fi
        done

        # Get environment
        node_labels=$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels}' 2>/dev/null)
        
        if [[ "$node_labels" == *"eks.amazonaws.com"* || "$node_labels" == *"instance-type"* ]]; then
            PLATFORM="eks"
        elif [[ "$node_labels" == *"openshift"* ]]; then
            PLATFORM="ocp"
        elif [[ "$node_labels" == *"cloud.google.com/gke-nodepool"* ]]; then
            PLATFORM="gke"
        else
            PLATFORM="oss"
        fi

        while true; do
            read -p "Enter the new cluster name: " -e -i $(echo $BUSINESS_UNIT-$PLATFORM-$ENVIRONMENT-$CURRENT_VZ_VASTID-$CURRENT_VZ_VSADID | tr -d '"') NEW_CLUSTER_NAME

            # Validate cluster name: must be 1-253 characters, lowercase, alphanumeric, or '-', and must start/end with alphanumeric
            if [[ "$NEW_CLUSTER_NAME" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] && [[ ${#NEW_CLUSTER_NAME} -le 253 ]]; then
            break
            else
            echo "Invalid cluster name. It must be 1-253 characters long, contain only lowercase letters, numbers, or '-', and start/end with an alphanumeric character."
            fi
        done

        # Update both occurrences in the YAML file - the name and the tag
        yq eval -i '.cluster_config.name = "'"$NEW_CLUSTER_NAME"'"' cluster-specific-values.yaml
        yq eval -i '.cluster_config.tags.cluster = "'"$NEW_CLUSTER_NAME"'"' cluster-specific-values.yaml

        echo "Cluster name has been updated to: $NEW_CLUSTER_NAME"
    else
        echo "No changes made to cluster name."
    fi
    echo
}
update_sysdig_accesskey() {
    # Prompt the user to specify the Sysdig access key
    while true; do
        read -p "Enter the Sysdig agent access key: " SYSDIG_ACCESS_KEY

        # Validate the access key format (UUID format)
        if [[ "$SYSDIG_ACCESS_KEY" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
            break
        else
            echo "Invalid access key format. Please enter a valid access key"
        fi
    done

    # Keep asking for the access key until it is not empty
    while [[ -z "$SYSDIG_ACCESS_KEY" ]]; do
        echo "Error: Sysdig agent access key must be specified."
        read -p "Enter the Sysdig agent access key: " SYSDIG_ACCESS_KEY
    done
    echo
}
update_proxy_settings() {
    # Ask if proxy is required
    while true; do
        read -p "Does your kubernetes cluster require a proxy for internet connectivity? (yes/no): " PROXY_REQUIRED
        if [[ "$PROXY_REQUIRED" == "yes" || "$PROXY_REQUIRED" == "no" ]]; then
            break
        else
            echo "Please enter 'yes' or 'no'."
        fi
    done

    if [[ "$PROXY_REQUIRED" == "yes" ]]; then
        # Get HTTP proxy
        while true; do
            read -p "Enter HTTP proxy URL (format: http://proxy.local:9999): " HTTP_PROXY
            if [[ "$HTTP_PROXY" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$ ]]; then
            break
            else
            echo "Invalid URL. Please enter a valid HTTP proxy URL (format: http://proxy.local:9999 or https://proxy.local:9999)."
            fi
        done

        # Get HTTPS proxy
        while true; do
            read -p "Enter HTTPS proxy URL (format: http://proxy.local:9999): " -e -i $HTTP_PROXY HTTPS_PROXY
            if [[ "$HTTPS_PROXY" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$ ]]; then
            break
            else
            echo "Invalid URL. Please enter a valid HTTPS proxy URL (format: http://proxy.local:9999 or https://proxy.local:9999)."
            fi
        done

        no_proxy_cluster_ip=$(kubectl get service kubernetes -o jsonpath='{.spec.clusterIP}'; echo)
        no_proxy_cluster_ip+=",localhost,127.0.0.1"
        # Get no_proxy list
        while true; do
            read -p "Enter NO_PROXY hosts (comma seperated, leave empty if none): " -e -i $no_proxy_cluster_ip NO_PROXY
            if [[ "$NO_PROXY" =~ ^([a-zA-Z0-9.-]+|[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?)(,([a-zA-Z0-9.-]+|[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?))*$ ]]; then
            break
            else
            echo "Invalid format. Please enter a valid comma-separated list of hostnames, IP addresses, or CIDR blocks."
            fi
        done

        # Update the values in the YAML file using yq
        yq eval -i '.proxy.http_proxy = "'"$HTTP_PROXY"'"' cluster-specific-values.yaml
        yq eval -i '.proxy.https_proxy = "'"$HTTPS_PROXY"'"' cluster-specific-values.yaml
        yq eval -i '.proxy.no_proxy = "'"$NO_PROXY"'"' cluster-specific-values.yaml
        else
        # Clear any existing proxy settings using yq
        yq eval -i "del(.proxy)" cluster-specific-values.yaml

        echo "No proxy will be used."
    fi
    echo
}
update_namespace() {
    # Prompt the user to specify the namespace
    while true; do
        read -p "Enter the namespace where you want to install Sysdig (default: sysdig): " NAMESPACE

        # Use "sysdig" as the default namespace if none is provided
        if [[ -z "$NAMESPACE" ]]; then
            NAMESPACE="sysdig"
        fi

        # Validate namespace: must be 1-63 characters, lowercase, alphanumeric, or '-' and must start/end with alphanumeric
        if [[ "$NAMESPACE" =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] && [[ ${#NAMESPACE} -le 63 ]]; then
            break
        else
            echo "Invalid namespace. It must be 1-63 characters long, contain only lowercase letters, numbers, or '-', and start/end with an alphanumeric character."
        fi
    done

    echo "Sysdig will be installed in the namespace: $NAMESPACE"
    echo
}
confirm_values() {
    echo "Contents of cluster-specific-values.yaml:"
    yq eval cluster-specific-values.yaml
    echo
    echo
    echo -e "\033[1;33mInstallation Namespace: $NAMESPACE\033[0m"
    echo -e "\033[1;33mInstallation Access Key: ${SYSDIG_ACCESS_KEY:0:6}******${SYSDIG_ACCESS_KEY: -6}\033[0m"
    echo
    while true; do
        read -p "Do you want to proceed with these values? (yes/no): " PROCEED
        if [[ "$PROCEED" == "yes" || "$PROCEED" == "no" ]]; then
            break
        else
            echo "Please enter 'yes' or 'no'."
        fi
    done

    if [[ "$PROCEED" != "yes" ]]; then
        echo "Exiting installation as per user request."
        exit 1
    fi

    echo
}
update_priority_class() {
    while true; do
        read -p "Do you want to specify a Kubernetes priority class? (yes/no): " USE_PRIORITY_CLASS
        if [[ "$USE_PRIORITY_CLASS" == "yes" || "$USE_PRIORITY_CLASS" == "no" ]]; then
            break
        else
            echo "Please enter 'yes' or 'no'."
        fi
    done
    
    if [[ "$USE_PRIORITY_CLASS" == "yes" ]]; then
        # Retrieve the list of available priority classes
        PRIORITY_CLASSES=$(kubectl get priorityclass -o custom-columns="NAME:.metadata.name" --no-headers)
        
        # Default value suggestion
        while true; do
            echo "Available priority classes:"
            echo "$PRIORITY_CLASSES"
            read -p "Enter the priority class name [system-node-critical]: " PRIORITY_CLASS_NAME
            
            # Use default if nothing was entered
            PRIORITY_CLASS_NAME=${PRIORITY_CLASS_NAME:-system-node-critical}
            
            # Check if the entered value is in the list of available priority classes
            if echo "$PRIORITY_CLASSES" | grep -qw "$PRIORITY_CLASS_NAME"; then
            break
            else
            echo "Invalid priority class name. Please choose from the available priority classes."
            fi
        done
        # Use default if nothing was entered
        PRIORITY_CLASS_NAME=${PRIORITY_CLASS_NAME:-system-node-critical}
        
        # Update both priority class name entries in the YAML file using yq
        yq eval -i '.host.priority_class.name = "'"$PRIORITY_CLASS_NAME"'"' cluster-specific-values.yaml
        
        echo "Priority class set to: $PRIORITY_CLASS_NAME for host components."
        else
        # Clear any existing priority class settings using yq
        yq eval -i 'del(.host.priority_class)' cluster-specific-values.yaml
        
        echo "No priority class will be used."
        fi
    echo
}
update_resource_sizing() {
    # Determine the cluster size based on the number of nodes
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)

    # Path to the YAML files
    YAML_FILE="cluster-specific-values.yaml"
    PROFILE_FILE="./helpers/sizing-template.yaml"

    # Determine the cluster profile based on the node count
    if [[ "$NODE_COUNT" -lt 2 ]]; then
        PROFILE="small"
    elif [[ "$NODE_COUNT" -ge 2 && "$NODE_COUNT" -le 12 ]]; then
        PROFILE="medium"
    else
        PROFILE="large"
    fi

    # Get the resource values for the determined profile
    SHIELD_REQUEST_CPU=$(yq eval ".profiles.$PROFILE.host.resources.shield.requests.cpu" "$PROFILE_FILE")
    SHIELD_REQUEST_MEMORY=$(yq eval ".profiles.$PROFILE.host.resources.shield.requests.memory" "$PROFILE_FILE")
    SHIELD_LIMIT_CPU=$(yq eval ".profiles.$PROFILE.host.resources.shield.limits.cpu" "$PROFILE_FILE")
    SHIELD_LIMIT_MEMORY=$(yq eval ".profiles.$PROFILE.host.resources.shield.limits.memory" "$PROFILE_FILE")
    
    CLUSTER_REQUEST_CPU=$(yq eval ".profiles.$PROFILE.cluster.resources.requests.cpu" "$PROFILE_FILE")
    CLUSTER_REQUEST_MEMORY=$(yq eval ".profiles.$PROFILE.cluster.resources.requests.memory" "$PROFILE_FILE")
    CLUSTER_LIMIT_CPU=$(yq eval ".profiles.$PROFILE.cluster.resources.limits.cpu" "$PROFILE_FILE")
    CLUSTER_LIMIT_MEMORY=$(yq eval ".profiles.$PROFILE.cluster.resources.limits.memory" "$PROFILE_FILE")

    # Apply the resource settings to the cluster-specific-values.yaml file
    yq eval -i --prettyPrint ".host.resources.shield = {\"requests\": {\"cpu\": \"$SHIELD_REQUEST_CPU\", \"memory\": \"$SHIELD_REQUEST_MEMORY\"}, \"limits\": {\"cpu\": \"$SHIELD_LIMIT_CPU\", \"memory\": \"$SHIELD_LIMIT_MEMORY\"}}" "$YAML_FILE"
    
    yq eval -i --prettyPrint ".cluster.resources = {\"requests\": {\"cpu\": \"$CLUSTER_REQUEST_CPU\", \"memory\": \"$CLUSTER_REQUEST_MEMORY\"}, \"limits\": {\"cpu\": \"$CLUSTER_LIMIT_CPU\", \"memory\": \"$CLUSTER_LIMIT_MEMORY\"}}" "$YAML_FILE"
}
