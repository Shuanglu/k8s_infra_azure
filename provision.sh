#!/bin/bash
read -p "Please input service princiapl client ID to login to Azure: " clientid
read -p "Please input service princiapl secret to login to Azure: " secret
read -p "Please input service princiapl tenant to login to Azure: " tenant
az login --service-principal -u $clientid -p $secret --tenant $tenant
continue=0
while [ "$continue" == 0 ]
do
  if [ -f "./scripts/conf/ca.crt" ]; then
    read -p 'CA pair exists. Would you like to clean up the existing CA(Yes/No)? ' cleanup
    if [ "$cleanup" == "Yes" ]; then
      echo "Deletng the existing CA"
      rm -rf ./scripts/conf/ca*
      echo "Generate the new CA"
      openssl genrsa -out ./scripts/conf/ca.key 2048 
      openssl req -new -x509 -key ./scripts/conf/ca.key -subj '/CN=kubernetes' -out ./scripts/conf/ca.crt
      if [ -f "./scripts/conf/ca.crt" ]; then
        echo "CA pair has been created"
        continue=1
      fi
    elif [ "$cleanup" != "No" ]; then
      echo "Not a valid option. Please retry"
    else
      echo "Will use the existing CA"
      continue=1
    fi
  fi
done
continue=0
while [ "$continue" == 0 ]
do
  read -p "Would you like to upload the scripts file to blob storage(Yes/No)? " upload
  if [ $upload == "Yes" ]; then
    echo "Uploading the tar file to blob storage"
    tar -cvf script.tar scripts/
    read -p "Please input the Storage account name: " sa
    read -p "Please input the Container name: " container
    az storage blob upload --account-name $sa --container-name $container --name scripts.tar --file scripts.tar --auth-mode login
    if [ "$?" -ne 0 ]; then
      echo "Failed to upload blob. Please retry"
    else
      echo "Upload successfully"
      continue=1
    fi
  elif [ $upload == "No"]; then
    echo "Skip upload the tar file"
    continue=1
  else
    echo "Not a valid option. Please retry"
  fi
done
contine=0
while [ "$continue" == 0 ]
do
  read -p "Please input the token. Default one is 'abcdef.0123456789abcdef' " token
  tokenValidation=`echo $token | grep -Eo '[a-z0-9]{6}.[a-z0-9]{16}'`
  if [ -n $tokenValidation ]; then
    echo 'Token validation passed'   
    continue=1
  else
    echo "Tokne has to be [a-z0-9]{6}.[a-z0-9]{16}'. Please retry"
  fi
done
read -p "Please input the apiserver fqdn: " apiserver
ca_hash=`openssl x509 -pubkey -in ./scripts/conf/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`
read -p "Which node would you like to provision(Master/Agent)? " nodetype
if [ "$nodetype" == "Master" ]; then
  read -p 'Whether this is the 1st Master(yes/No)? ' first
  if [ "$first" == "Yes" ]; then
    read -p "Please input the instance ID" instance
    az vmss run-command invoke --command-id RunShellScript --scripts 'cd /var/log/; if [ -f scripts.tar ]; then rm -rf scripts*;fi;timeout 30 wget https://$1.blob.core.windows.net/$2/scripts.tar --quiet; if [ $? -ne 0 ]; then echo "failed to download" && exit 1;fi; tar -xvf scripts.tar > /dev/null 2>&1 && cd scripts && chmod -R 777 * && bash -c "./main.sh $3 $4" >>/var/log/scripts/initilization.log 2>&1; if [ $? -eq 0 ];then echo "succeed";else echo "failed";fi' --parameters $sa $container $token $apiserver -g k8s-infra -n k8s-master --instance-id $instance
  elif [ "$first" == "No" ]; then
    read -p "Please input the instance ID" instance
    az vmss run-command invoke --command-id RunShellScript --scripts 'cd /var/log/; if [ -f scripts.tar ]; then rm -rf scripts*;fi;timeout 30 wget https://$1.blob.core.windows.net/$2/scripts.tar --quiet; if [ $? -ne 0 ]; then echo "failed to download" && exit 1;fi; tar -xvf scripts.tar > /dev/null 2>&1 && cd scripts && chmod -R 777 * && bash -c "./main.sh $3 $4 $5" >>/var/log/scripts/initilization.log 2>&1; if [ $? -eq 0 ];then echo "succeed";else echo "failed";fi' --parameters $sa $container $token $apiserver $first -g k8s-infra -n k8s-master --instance-id $instance
  fi
fi
if [ "$nodetype" == "Agent" ]; then
  az vmss run-command invoke --command-id RunShellScript --scripts 'cd /var/log/; if [ -f scripts.tar ]; then rm -rf scripts*;fi;timeout 30 wget https://$1.blob.core.windows.net/$2/scripts.tar --quiet; if [ $? -ne 0 ]; then echo "failed to download" && exit 1;fi; tar -xvf scripts.tar > /dev/null 2>&1 && cd scripts && chmod -R 777 * && bash -c "./main.sh $3 $4 $5" >>/var/log/scripts/initilization.log 2>&1; if [ $? -eq 0 ];then echo "succeed";else echo "failed";fi' --parameters $sa $container $token $apiserver $ca_hash -g k8s-infra -n k8s-agent --instance-id 1
fi