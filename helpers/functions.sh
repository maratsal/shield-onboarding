#!/bin/bash

update_vz_vsadid() {
    # Extract the current value of "vz-vsadid" from the YAML file
    CURRENT_VZ_VSADID=$(grep 'vz-vsadid:' cluster-specific-values.yaml | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    echo "The current value of 'vz-vsadid' is: $CURRENT_VZ_VSADID"
    read -p "Do you want to change it? (yes/no): " RESPONSE

    if [[ "$RESPONSE" == "yes" ]]; then
        read -p "Enter the new value for 'vz-vsadid': " NEW_VZ_VSADID

        # Update the value in the YAML file
        sed -i "s/vz-vsadid: .*/vz-vsadid: \"$NEW_VZ_VSADID\"/" cluster-specific-values.yaml

        echo "'vz-vsadid' has been updated to: $NEW_VZ_VSADID"
    else
        echo "No changes made to 'vz-vsadid'."
    fi
    echo
}

update_vz_vastid() {
    # Extract the current value of "vz-vastid" from the YAML file
    CURRENT_VZ_VASTID=$(grep 'vz-vastid:' cluster-specific-values.yaml | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    echo "The current value of 'vz-vastid' is: $CURRENT_VZ_VASTID"
    read -p "Do you want to change it? (yes/no): " RESPONSE

    if [[ "$RESPONSE" == "yes" ]]; then
        read -p "Enter the new value for 'vz-vastid': " NEW_VZ_VASTID

        # Update the value in the YAML file
        sed -i "s/vz-vastid: .*/vz-vastid: \"$NEW_VZ_VASTID\"/" cluster-specific-values.yaml

        echo "'vz-vastid' has been updated to: $NEW_VZ_VASTID"
    else
        echo "No changes made to 'vz-vastid'."
    fi
    echo
}
update_cluster_name() {
    # Extract the current value of cluster name from the YAML file
    CURRENT_CLUSTER_NAME=$(grep 'name:' cluster-specific-values.yaml | head -1 | awk '{print $2}' | tr -d '"')

    # Display the current value to the user and ask if they want to change it
    echo "The current cluster name is: $CURRENT_CLUSTER_NAME"
    read -p "Do you want to change it? (yes/no): " RESPONSE

    if [[ "$RESPONSE" == "yes" ]]; then
        read -p "Enter the new cluster name: " NEW_CLUSTER_NAME

        # Update both occurrences in the YAML file - the name and the tag
        sed -i "s/name: \"$CURRENT_CLUSTER_NAME\"/name: \"$NEW_CLUSTER_NAME\"/" cluster-specific-values.yaml
        sed -i "s/cluster: \"$CURRENT_CLUSTER_NAME\"/cluster: \"$NEW_CLUSTER_NAME\"/" cluster-specific-values.yaml

        echo "Cluster name has been updated to: $NEW_CLUSTER_NAME"
    else
        echo "No changes made to cluster name."
    fi
    echo
}


update_sysdig_accesskey() {
    # Prompt the user to specify the Sysdig access key
    read -p "Enter the Sysdig access key: " SYSDIG_ACCESS_KEY

    # Keep asking for the access key until it is not empty
    while [[ -z "$SYSDIG_ACCESS_KEY" ]]; do
        echo "Error: Sysdig access key must be specified."
        read -p "Enter the Sysdig access key: " SYSDIG_ACCESS_KEY
    done
    echo
}

update_proxy_settings() {
    # Ask if proxy is required
    read -p "Do you require a proxy for network connections? (yes/no): " PROXY_REQUIRED

    if [[ "$PROXY_REQUIRED" == "yes" ]]; then
        # Get HTTP proxy
        read -p "Enter HTTP proxy URL (format: http://proxy.local:9999): " HTTP_PROXY
        
        # Get HTTPS proxy
        read -p "Enter HTTPS proxy URL (format: http://proxy.local:9999): " HTTPS_PROXY
        
        # Get no_proxy list
        echo "Enter hosts/IPs to exclude from proxy (comma-separated, leave empty if none)"
        read -p "Example: localhost,127.0.0.1,10.0.0.0/8: " NO_PROXY

        # Update the values in the YAML file
        sed -i "s|http_proxy:.*|http_proxy: \"$HTTP_PROXY\"|" cluster-specific-values.yaml
        sed -i "s|https_proxy:.*|https_proxy: \"$HTTPS_PROXY\"|" cluster-specific-values.yaml
        sed -i "s|no_proxy:.*|no_proxy: \"$NO_PROXY\"|" cluster-specific-values.yaml

        echo "Proxy settings have been updated."
    else
        # Clear any existing proxy settings
        sed -i "s|http_proxy:.*|http_proxy:|" cluster-specific-values.yaml
        sed -i "s|https_proxy:.*|https_proxy:|" cluster-specific-values.yaml
        sed -i "s|no_proxy:.*|no_proxy:|" cluster-specific-values.yaml
        
        echo "No proxy will be used."
    fi
    echo
}

update_namespace() {
    # Prompt the user to specify the namespace
    read -p "Enter the namespace where you want to install Sysdig (default: sysdig): " NAMESPACE

    # Use "sysdig" as the default namespace if none is provided
    if [[ -z "$NAMESPACE" ]]; then
        NAMESPACE="sysdig"
    fi

    echo "Sysdig will be installed in the namespace: $NAMESPACE"
    echo
}

confirm_values() {
    echo "Contents of cluster-specific-values.yaml:"
    cat cluster-specific-values.yaml
    echo
    echo
    echo "Namespace: $NAMESPACE"
    echo "Sysdig Access Key: $SYSDIG_ACCESS_KEY"
    echo
    read -p "Do you want to proceed with these values? (yes/no): " PROCEED

    if [[ "$PROCEED" != "yes" ]]; then
        echo "Exiting installation as per user request."
        exit 1
    fi

    echo
}

update_priority_class() {
    read -p "Do you want to specify a kubernetes priority class? (yes/no): " USE_PRIORITY_CLASS
    
    if [[ "$USE_PRIORITY_CLASS" == "yes" ]]; then
        # Default value suggestion
        read -p "Enter the priority class name [system-node-critical]: " PRIORITY_CLASS_NAME
        
        # Use default if nothing was entered
        PRIORITY_CLASS_NAME=${PRIORITY_CLASS_NAME:-system-node-critical}
        
        # Update both priority class name entries in the YAML file
        sed -i "/host:/{:a;n;/priority_class:/{:b;n;/name:/s/name:.*/name: \"$PRIORITY_CLASS_NAME\"/;};/priority_class:/ba;}" cluster-specific-values.yaml
        sed -i "/cluster:/{:a;n;/priority_class:/{:b;n;/name:/s/name:.*/name: \"$PRIORITY_CLASS_NAME\"/;};/priority_class:/ba;}" cluster-specific-values.yaml
        
        echo "Priority class set to: $PRIORITY_CLASS_NAME for both host and cluster components."
    else
        # Clear any existing priority class settings
        sed -i "/host:/{:a;n;/priority_class:/{:b;n;/name:/s/name:.*/name:/;};/priority_class:/ba;}" cluster-specific-values.yaml
        sed -i "/cluster:/{:a;n;/priority_class:/{:b;n;/name:/s/name:.*/name:/;};/priority_class:/ba;}" cluster-specific-values.yaml
        
        echo "No priority class will be used."
    fi
    echo
}