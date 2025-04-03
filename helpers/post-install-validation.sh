#!/bin/bash

# Check if the namespace argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

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

# Set the namespace from the command line argument
namespace="$1"

kubectl get pods -n "$namespace" -l app.kubernetes.io/instance=shield

podNameList=`kubectl get pods -n "$namespace" -l sysdig/component=host --no-headers -o custom-columns=":metadata.name"`
for podName in $podNameList
do
	echo "========== " $podName
        kubectl logs -n "$namespace" $podName | grep Error,
done

podNameList=`kubectl get pods -n "$namespace" -l sysdig/component=cluster --no-headers -o custom-columns=":metadata.name"`
for podName in $podNameList
do
	echo "========== " $podName
        kubectl logs -n "$namespace" $podName | grep 'level\":\"ERROR\"'
done
