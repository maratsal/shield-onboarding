#!/bin/bash

# TODO - Optional API checks for dupe cluster name, cluster status, scan results after X minutes
# Potential issues with needing to disconnect/reconnect proxy access to access Internet and K8s Cluster from jumpboxes

check_api_for_dupe_clustername() {
    # Prompt the user for the API token
    read -p "Enter your API token: " api_token

    # Prompt the user for the cluster name
    read -p "Enter your cluster name: " cluster_name

    # Make a GET request with the Authorization Bearer header
    response=$(curl -s -H "Authorization: Bearer $api_token" "https://app.us4.sysdig.com/api/cloud/v2/dataSources/agents?limit=100&offset=0&cluster=$cluster_name")

    connected_flag=$(echo "$response" | yq eval '.details[] | select(.connected == true)' - | wc -l)

    # If connected_flag > 0, then set the flag and print relevant details
    if [ "$connected_flag" -gt 0 ]; then
        echo -e "\e[31mPotential Duplicate Cluster Name - Connected agent(s) found with the same cluster name $cluster_name\e[0m"
        echo "$response" | yq eval '.details[] | select(.connected == true) | "agentStatus=" + .agentStatus + ", agentVersion=" + .agentVersion + ", clusterName=" + .clusterName' -
    fi
}

check_api_for_connected_cluster(){
    # Make a GET request with the Authorization Bearer header
    response=$(curl -s -H "Authorization: Bearer $api_token" "https://app.us4.sysdig.com/api/cloud/v2/dataSources/agents?limit=100&offset=0&cluster=$cluster_name")

    connected_flag=$(echo "$response" | yq eval '.details[] | select(.connected == true)' - | wc -l)

    # If connected_flag > 0, then set the flag and print relevant details
    if [ "$connected_flag" -le 0 ]; then
        echo -e "\e[31mNo Connected Agents Connected for: $cluster_name\e[0m"
        echo "$response" | yq eval '.details[] | select(.connected == true) | "agentStatus=" + .agentStatus + ", agentVersion=" + .agentVersion + ", clusterName=" + .clusterName' -
    else
        echo -e "\e[32mAgents Connected for: $cluster_name\e[0m"
        echo "$response" | yq eval '.details[] | select(.connected == true) | "agentStatus=" + .agentStatus + ", agentVersion=" + .agentVersion + ", clusterName=" + .clusterName' -
    fi
}

check_api_for_scan_results()
{
    # Sleep for 20 minutes, printing remaining time every minute
    for ((i=20; i>0; i--)); do
        echo "Waiting to check scan results... $i minute(s) remaining."
        sleep 60
    done

    # Make a GET request with the Authorization Bearer header
    response=$(curl -s -H "Authorization: Bearer $api_token" "https://app.us4.sysdig.com/api/scanning/runtime/v2/workflows/results?cursor&filter=kubernetes.cluster.name%20%3D%20%22$cluster_name%22&limit=100&order=desc&sort=runningVulnsBySev&zones")

    scan_results=$(echo $response | yq eval '.data[].recordDetails.mainAssetName' - | wc -l)

    # Check if scan results are available
    if [ "$scan_results" -gt 0 ]; then
        echo -e "\e[32mScan results are available for cluster: $cluster_name\e[0m"
        echo "$response" | yq eval '.data[] | select(.recordDetails) | "     " + .recordDetails.mainAssetName' -
    else
        echo -e "\e[31mNo completed scan results found for cluster: $cluster_name\e[0m"
    fi
}