#!/bin/bash

#
# Check for kubectl binary presence
#
if ! command -v kubectl &> /dev/null; then
  echo -e "\033[31mkubectl is not installed or not in PATH. Please install kubectl before proceeding.\033[0m"
  exit 1
else
  echo -e "\033[32mkubectl is installed.\033[0m"
fi

# Check for previous sysdig install and require uninstallation first if present
if kubectl get all --all-namespaces --show-labels | grep -q "sysdig/"; then
  echo -e "\033[31mSysdig components are already installed. Please remove them before proceeding.\033[0m"
  exit 1
else
  echo -e "\033[32mNo existing Sysdig components found. Proceeding with installation.\033[0m"
fi

#
# Helm Binary Check
#
helm_version=$(helm version --short 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+')
if [[ $helm_version =~ ^v([0-9]+)\.([0-9]+)$ ]]; then
  major=${BASH_REMATCH[1]}
  minor=${BASH_REMATCH[2]}
  if (( major < 3 || (major == 3 && minor < 9) )); then
    echo -e "\033[31mHelm version is less than v3.9. Please upgrade Helm.\033[0m"
    exit 1
  else
    echo -e "\033[32mHelm version $helm_version is supported.\033[0m"
  fi
else
  echo -e "\033[31mUnable to determine Helm version. Please ensure Helm is installed.\033[0m"
  exit 1
fi

#
# Kubernetes Current Context Verification
#
current_context=$(kubectl config current-context)
echo -e "\033[33mAre you logged into the correct cluster $current_context? (yes/no)\033[0m"
read -r response
if [[ "$response" != "yes" ]]; then
  echo -e "\033[31mExiting. Please log into the correct cluster and try again.\033[0m"
  exit 1
fi

#
# Check cluster permissions
#
permissions=(
  "get nodes"
  "list nodes"
  "get pods"
  "list pods"
  "create pods"
  "get deployments"
  "create deployments"
  "get daemonsets"
  "create daemonsets"
  "get secrets"
  "create secrets"
  "get configmaps"
  "create configmaps"
)

for permission in "${permissions[@]}"; do
  if kubectl auth can-i $permission &> /dev/null; then
    echo -e "\033[32mYou have permission to $permission.\033[0m"
  else
    echo -e "\033[31mYou do NOT have permission to $permission. Please ensure the necessary permissions are granted.\033[0m"
    exit 1
  fi
done


#
# Validated resources
#
echo -e "\033[33mAre there enough resources available on the cluster?\033[0m"
nodes=$(kubectl get nodes -o custom-columns=":.metadata.name")
for node in $nodes; do
  echo "Node: $node"
  kubectl describe node $node | grep --color=never -i "Allocated resources" -A 8
done
read -r response
if [[ "$response" != "yes" ]]; then
  echo -e "\033[31mExiting. Please reallocate resources and try again.\033[0m"
  exit 1
fi

#
# Validate Kernel Versions For Universal EBPF Support
#
echo -e "\033[33mChecking if nodes are running a minimum kernel version of 5.8...\033[0m"
error_found=false
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.nodeInfo.kernelVersion}{"\n"}{end}' | while read -r node kernel_version; do
  echo "Node: $node, Kernel Version: $kernel_version"
  version_check=$(echo "$kernel_version" | awk -F. '{printf "%d%02d", $1, $2}')
  if (( version_check < 508 )); then
    echo -e "\033[31mNode $node has kernel version $kernel_version, which is less than 5.8. Exiting.\033[0m"
    error_found=true
  fi
done

if $error_found; then
  exit 1
else
  echo -e "\033[32mAll nodes have kernel versions >= 5.8. Validation passed.\033[0m"
fi