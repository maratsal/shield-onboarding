#!/bin/bash

echo -e "\033[33mIs helm installed and running a version > 3.9?\033[0m"
helm version
echo

echo -e "\033[33mIs helm installed and running a version > 3.9?\033[0m"
helm version
echo

echo -e "\033[33mAre you logged into the correct cluster?\033[0m"
kubectl config get-contexts
echo

echo -e "\033[33mIs there enough resources available on the cluster?\033[0m"
nodes=$(kubectl get nodes -o custom-columns=":.metadata.name")
for node in $nodes; do
  echo "Node: $node"
  kubectl describe node $node | grep --color=never -i "Allocated resources" -A 8
done
echo

echo -e "\033[33mAre the nodes running a minimium kernel version of 5.8?\033[0m"
kubectl describe nodes | grep --color=never -E 'Name:|Kernel Version:'
echo
