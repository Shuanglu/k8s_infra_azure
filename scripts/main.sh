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
containerd > /var/log/scripts/initilization.log 2>&1
k8s_install > /var/log/scripts/initilization.log 2>&1
k8s_conf > /var/log/scripts/initilization.log 2>&1