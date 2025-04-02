#!/bin/bash

echo -e "\033[32mRunning pre-install validation...\033[0m"


#
# check for yq already installed or use bundled arm/amd binaries with alias
#
if ! command -v yq &> /dev/null; then
  arch=$(uname -m)
  if [[ "$arch" == "x86_64" ]]; then
    yq() {
      ./helpers/yq_linux_amd64 "$@"
    }
    echo -e "\033[32myq is installed.\033[0m"
  elif [[ "$arch" == "aarch64" ]]; then
    yq() {
      ./helpers/yq_linux_arm64 "$@"
    }
    echo -e "\033[32myq is installed.\033[0m"
  else
    echo -e "\033[31mUnsupported platform type: $arch. Please install yq manually.\033[0m"
    exit 1
  fi
fi

#
# Check for kubectl or oc binary presence
#
if ! command -v kubectl &> /dev/null; then
  if command -v oc &> /dev/null; then
    echo -e "\033[33mkubectl is not installed, but oc is available. Creating an alias for kubectl as oc.\033[0m"
    alias kubectl=oc
  else
    echo -e "\033[31mkubectl or oc is not installed or not in PATH. Please install kubectl or oc before proceeding.\033[0m"
    exit 1
  fi
else
  echo -e "\033[32mkubectl is installed.\033[0m"
fi

# Check for previous sysdig install and require uninstallation first if present
if kubectl get all --all-namespaces --show-labels | grep -q "sysdig/"; then
  echo -e "\033[31mSysdig components detected. Please remove them before proceeding.\033[0m"
  exit 1
else
  echo -e "\033[32mNo existing Sysdig components found.\033[0m"
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
read -r -p $'Are you logged into the correct cluster '"$current_context"' (yes/no)? ' response
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
# Validate node resources
#
cpu_threshold=1500
memory_threshold=512000

# Fetch node info and display memory/cpu allocatable
kubectl get nodes -o custom-columns=":.metadata.name,:.status.allocatable.cpu,:.status.allocatable.memory" | while read -r node cpu memory; do
    # Skip the header line
    if [[ "$node" == "" ]]; then
        continue
    fi

    # Extract CPU value in m (remove 'm' suffix)
    cpu_value=$(echo "$cpu" | sed 's/m//')
    
    # Extract memory value
    memory_value=$(echo "$memory" | sed 's/Ki//')
    
    # Check if CPU or memory is below threshold
    if [[ "$cpu_value" -lt $cpu_threshold || "$memory_value" -lt $memory_threshold ]]; then
      echo -e "\033[33mNode $node has less than the threshold:\033[0m"
      echo -e "\033[33m  CPU Allocatable: $cpu\033[0m"
      echo -e "\033[33m  Memory Allocatable: $memory\033[0m"
      echo
    else
      echo -e "\033[32mNode $node meets the threshold:\033[0m"
      echo -e "\033[32m  CPU Allocatable: $cpu\033[0m"
      echo -e "\033[32m  Memory Allocatable: $memory\033[0m"
      echo
    fi
done

while true; do
    read -r -p $'Do you have enough resources available on the cluster nodes (yes/no)? ' RESPONSE
    if [[ "$RESPONSE" == "yes" || "$RESPONSE" == "no" ]]; then
        break
    else
        echo "Please enter 'yes' or 'no'."
    fi
done

if [[ "$response" != "yes" ]]; then
  echo -e "\033[31mExiting. Please reallocate resources and try again.\033[0m"
  exit 1
fi

#
# Validate Kernel Versions For Universal EBPF Support
#
error_found=false
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.nodeInfo.kernelVersion}{"\n"}{end}' | while read -r node kernel_version; do
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