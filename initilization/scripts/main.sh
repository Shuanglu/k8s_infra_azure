#!/bin/bash

#set -x
if [ -f /var/log/initilization/provision.complete ]; then
  exit 0
fi

echo $(date),$(hostname) >> /var/log/initilization/initilization.log

for i in "/var/log/initilization/scripts/*";
do  
    #echo $i
    source $i
done
containerd
k8s_install
k8s_conf