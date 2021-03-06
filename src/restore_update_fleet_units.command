#!/bin/bash

# restore_update_fleet_units.command
#

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}"/functions.sh

# get App's Resources folder
res_folder=$(cat ~/kube-cluster/.env/resouces_path)

# get VMs IPs
master_vm_ip=$(~/bin/corectl q -i k8smaster-01)
node1_vm_ip=$(~/bin/corectl q -i k8snode-01)
node2_vm_ip=$(~/bin/corectl q -i k8snode-02)

# path to the bin folder where we store our binary files
export PATH=${HOME}/kube-cluster/bin:$PATH

# copy files to ~/kube-cluster/bin
cp -f "${res_folder}"/bin/* ~/kube-cluster/bin
chmod 755 ~/kube-cluster/bin/*
rm -f ~/kube-cluster/bin/gen_kubeconfig

# copy fleet units
cp -R "${res_folder}"/fleet/ ~/kube-cluster/fleet
#

# restart fleet units
echo "Redeploying fleet units:"
# set fleetctl tunnel
export FLEETCTL_ENDPOINT=http://$master_vm_ip:2379
export FLEETCTL_DRIVER=etcd
export FLEETCTL_STRICT_HOST_KEY_CHECKING=false
cd ~/kube-cluster/fleet
echo " "
echo "Destroying Kubernetes fleet units ..."
~/kube-cluster/bin/fleetctl destroy kube-apiserver.service
~/kube-cluster/bin/fleetctl destroy kube-controller-manager.service
~/kube-cluster/bin/fleetctl destroy kube-scheduler.service
~/kube-cluster/bin/fleetctl destroy kube-kubelet.service
~/kube-cluster/bin/fleetctl destroy kube-proxy.service
echo " "
sleep 5
echo "Starting Kubernetes fleet units ..."
~/kube-cluster/bin/fleetctl start kube-apiserver.service
~/kube-cluster/bin/fleetctl start kube-controller-manager.service
~/kube-cluster/bin/fleetctl start kube-scheduler.service
~/kube-cluster/bin/fleetctl start kube-kubelet.service
~/kube-cluster/bin/fleetctl start kube-proxy.service
#
sleep 5
echo " "
echo "fleetctl list-units:"
~/kube-cluster/bin/fleetctl list-units
echo " "

# set kubernetes master
export KUBERNETES_MASTER=http://$master_vm_ip:8080
echo Waiting for Kubernetes cluster to be ready. This can take a few minutes...
spin='-\|/'
i=1
until ~/kube-cluster/bin/kubectl version | grep 'Server Version' >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\b${spin:i++%${#sp}:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node1_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
i=1
until ~/kube-cluster/bin/kubectl get nodes | grep $node2_vm_ip >/dev/null 2>&1; do i=$(( (i+1) %4 )); printf "\r${spin:$i:1}"; sleep .1; done
echo " "
#
echo " "
echo "kubectl get nodes:"
~/kube-cluster/bin/kubectl get nodes
echo " "
#
echo "Kubernetes cluster info:"
~/kube-cluster/bin/kubectl cluster-info
echo " "

echo "Fleet units restored/updated !!!"
pause 'Press [Enter] key to continue...'




