#!/bin/bash

update_vz_vsadid() {
    # Extract the current value of "vz-vsadid" from the YAML file
    CURRENT_VZ_VSADID=$(grep 'vz-vsadid:' cluster-specific-values.yaml | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    if [[ "$CURRENT_VZ_VSADID" == "\"CHANGE_ME\"" ]]; then
        RESPONSE="yes"
    else
        echo "The current value of 'vz-vsadid' is: $CURRENT_VZ_VSADID"
        read -p "Do you want to change it? (yes/no): " RESPONSE
    fi

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
    if [[ "$CURRENT_VZ_VASTID" == "\"CHANGE_ME\"" ]]; then
        RESPONSE="yes"
    else
        echo "The current value of 'vz-vastid' is: $CURRENT_VZ_VASTID"
        read -p "Do you want to change it? (yes/no): " RESPONSE
    fi

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
    CURRENT_CLUSTER_NAME=$(grep 'name:' cluster-specific-values.yaml | head -1 | awk '{print $2}')

    # Display the current value to the user and ask if they want to change it
    if [[ "$CURRENT_CLUSTER_NAME" == "\"CHANGE_ME\"" ]]; then
        RESPONSE="yes"
    else
        echo "The current cluster name is: $CURRENT_CLUSTER_NAME"
        read -p "Do you want to change it? (yes/no): " RESPONSE
    fi

    if [[ "$RESPONSE" == "yes" ]]; then
        read -p "Enter the new cluster name: " NEW_CLUSTER_NAME

        # Update both occurrences in the YAML file - the name and the tag
        sed -i "s/name: $CURRENT_CLUSTER_NAME/name: \"$NEW_CLUSTER_NAME\"/" cluster-specific-values.yaml
        sed -i "s/cluster: $CURRENT_CLUSTER_NAME/cluster: \"$NEW_CLUSTER_NAME\"/" cluster-specific-values.yaml

        echo "Cluster name has been updated to: $NEW_CLUSTER_NAME"
    else
        echo "No changes made to cluster name."
    fi
    echo
}


update_sysdig_accesskey() {
    # Prompt the user to specify the Sysdig access key
    read -p "Enter the Sysdig agent access key: " SYSDIG_ACCESS_KEY

    # Keep asking for the access key until it is not empty
    while [[ -z "$SYSDIG_ACCESS_KEY" ]]; do
        echo "Error: Sysdig agent access key must be specified."
        read -p "Enter the Sysdig agent access key: " SYSDIG_ACCESS_KEY
    done
    echo
}

update_proxy_settings() {
    # Ask if proxy is required
    read -p "Do you require a proxy for network connections? (yes/no): " PROXY_REQUIRED

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
            read -p "Enter HTTPS proxy URL (format: http://proxy.local:9999): " HTTPS_PROXY
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
    awk '{print "\033[1;33m" $0 "\033[0m"}' cluster-specific-values.yaml
    echo
    echo
    echo -e "\033[1;33mInstallation Namespace: $NAMESPACE\033[0m"
    echo -e "\033[1;33mInstallation Access Key: ${SYSDIG_ACCESS_KEY:0:6}******${SYSDIG_ACCESS_KEY: -6}\033[0m"
    echo
    read -p "Do you want to proceed with these values? (yes/no): " PROCEED

    if [[ "$PROCEED" != "yes" ]]; then
        echo "Exiting installation as per user request."
        exit 1
    fi

    echo
}

update_priority_class() {
    read -p "Do you want to specify a Kubernetes priority class? (yes/no): " USE_PRIORITY_CLASS
    
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