#!/bin/bash

#set -x
if [ -f /var/log/scripts/provision.complete ]; then
  exit 0
fi

echo $(date),$(hostname) 

for i in `ls /var/log/scripts/func/*.sh`;
do
    source $i
done
echo 'Prepare to install containerd'
containerd
echo 'Prepare to install k8s'
k8s_install

echo 'Prepare to configure k8s'
token=$1
echo $token
echo $2
master_fqdn=$2
echo $master_fqdn
ca_hash=$5
hostname=`hostname`
validation=`echo $hostname | grep -o 'k8s-master'`
if [ "$validation" == "k8s-master" ]; then
  echo 'Prepare kubeadm'
  k8s_conf_master $token $master_fqdn
  echo 'Prepare to install calico'
  install_calico
fi

validation=`echo $hostname | grep -o 'k8s-agent'`
if [ "$validation" == "k8s-agent" ]; then
  echo 'Prepare kubeadm'
  set -x
  k8s_conf_agent $token $master_fqdn $ca_hash
  set +x
fi