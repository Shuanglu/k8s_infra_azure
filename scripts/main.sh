#!/bin/bash

#set -x
if [ -f /var/log/scripts/provision.complete ]; then
  exit 0
fi

echo $(date),$(hostname) >> /var/log/scripts/initilization.log

for i in `ls /var/log/scripts/func/*.sh`;
do
    source $i
done
echo 'Prepare to install containerd'
containerd
echo 'Prepare to install k8s'
k8s_install
echo 'Prepare to configure k8s'
k8s_conf