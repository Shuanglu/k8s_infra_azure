#!/bin/bash
continue=0
while [ "$continue" == 0 ]
do
  read -p "Please input service princiapl client ID to login to Azure: " clientid
  read -p "Please input service princiapl secret to login to Azure: " secret
  read -p "Please input service princiapl tenant to login to Azure: " tenant
  read -p "Please input subscription ID: " sub 
  while [ "$continue" == 0 ]
  do
    echo "Logging to Azure. Please wait"
    az login --service-principal -u $clientid -p $secret --tenant $tenant
    if [ $? -eq 0 ]; then
      az account set -s $sub
      continue=1
    else
      echo "Failed to login. Please retry"
    fi
  done
  read -p "Please input the apiserver fqdn: " apiserver
  read -p "Please input the token. Default one is 'abcdef.0123456789abcdef' " token
  if [ -z "$token" ]; then
    token='abcdef.0123456789abcdef'
  fi
  tokenValidation=`echo $token | grep -Eo '[a-z0-9]{6}.[a-z0-9]{16}'`
  if [ -n "$tokenValidation" ]; then
    echo 'Token validation passed'   
    continue=1
  else
    echo "Tokne has to be [a-z0-9]{6}.[a-z0-9]{16}'. Please retry"
  fi
  read -p "Please input the Storage account name: " sa
  echo "Generating the sas token and load it to the script"
  end=`date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'`
  #set -x
  sas=`az storage account generate-sas --permissions cdlruwap --account-name $sa --services b --resource-types co --expiry $end` 
  #set +x
  sas=`echo -n "$sas"|sed 's/"//g'`
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate the sas token"
  fi
  #set -x
  cat /dev/null > ./scripts/func/env.sh 
  echo "sas='$sas'" > ./scripts/func/env.sh 
  #set +x
  if [ "$?" -eq 0 ]; then
    continue=1
  fi
  read -p "Please input the Script container name: " container
  read -p "Whether needs to create the Script container(Yes/No)? " container_exist
  if [ $container_exist == "Yes" ]; then
    #set -x
    curl -X PUT -H "x-ms-blob-public-access: blob" -H "Content-Length: 0" "https://$sa.blob.core.windows.net/$container?restype=container&$sas"
    #set +x
  fi
  read -p "Please input the Kubeconfig container name: " scontainer 
  read -p "Whether needs to create the Kubeconfig container(Yes/No)?" ccontainer
  if [ "$ccontainer" == "Yes" ]; then
    curl -X PUT -H "Content-Length: 0" "https://$sa.blob.core.windows.net/$scontainer?restype=container&$sas"
  fi
done


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
  read -p "Would you like to upload the scripts file to blob storage(Yes/No)? " upload
  if [ $upload == "Yes" ]; then
    echo "Uploading the tar file to blob storage"
    tar -cvf script.tar scripts/
    #az storage blob upload --account-name $sa --container-name $container --name scripts.tar --file scripts.tar --sas-token $sas
    #set -x
    curl -X PUT -T ./script.tar -H "x-ms-blob-type: BlockBlob" "https://$sa.blob.core.windows.net/$container/scripts.tar?$sas"
    #set +x
    if [ "$?" -ne 0 ]; then
      echo "Failed to upload blob. Please retry"
    else
      echo "Upload successfully"
      continue=1
    fi
  elif [ $upload == "No" ]; then
    echo "Skip upload the tar file"   
    continue=1
  else
    echo "Not a valid option. Please retry"
  fi
done



ca_hash=`openssl x509 -pubkey -in ./scripts/conf/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'`
read -p "Which node would you like to provision(Master/Agent)? " nodetype
read -p "Please input the resource group name " resource_group
if [ "$nodetype" == "Master" ]; then
  read -p "Please input the master vmss name " master
  read -p 'Whether this is the 1st Master(Yes/No)? ' first
  read -p "Please input the instance ID " instance

  scriptblob="https://$sa.blob.core.windows.net/$container/scripts.tar?"
  scriptblobd="https://$sa.blob.core.windows.net/$container/scripts.tar"
  confblob="https://$sa.blob.core.windows.net/$scontainer/admin.conf?"
  echo $scriptblob
  set -x
  #az vmss run-command invoke --command-id RunShellScript --scripts 'echo $1;echo $2' --parameters $token "$apiserver" $scriptblob "${confblob}" -g $resource_group -n $master --instance-id $instance
  az vmss run-command invoke --command-id RunShellScript --scripts "cd /var/log/; ls script*; if [ "$?" -eq 0 ]; then rm -rf scripts*;fi;timeout 30 wget $scriptblobd --quiet; if [ $? -ne 0 ]; then echo 'failed to download' && exit 1;fi; tar -xvf scripts.tar > /dev/null 2>&1 && cd scripts && chmod -R 777 * && bash -c './main.sh $token $apiserver $scriptblob $confblob $first' >>/var/log/scripts/initilization.log 2>&1; if [ $? -eq 0 ];then echo 'succeed'; else echo 'failed';fi" --parameters $token $apiserver $scriptblob $confblob $first -g $resource_group -n $master --instance-id $instance
  set +x

fi
if [ "$nodetype" == "Agent" ]; then
  read -p "Please input the agent vmss name " agent
  read -p "Please input the instance ID " instance
  az vmss run-command invoke --command-id RunShellScript --scripts "cd /var/log/; ls script*; if [ "$?" -eq 0 ]; then rm -rf scripts*;fi;timeout 30 wget $scriptblobd --quiet; if [ $? -ne 0 ]; then echo 'failed to download' && exit 1;fi; tar -xvf scripts.tar > /dev/null 2>&1 && cd scripts && chmod -R 777 * && bash -c './main.sh $token $apiserver $scriptblob $confblob $first' >>/var/log/scripts/initilization.log 2>&1; if [ $? -eq 0 ];then echo 'succeed'; else echo 'failed';fi" --parameters $token $apiserver $scriptblob $confblob $first -g $resource_group -n $master --instance-id $instance
fi