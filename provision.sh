#!/bin/bash


loginAzure(){
  clientid=$1
  secret=$2
  tenant=$3
  sub=$4
  echo "Logging to Azure. Please wait"
  az login --service-principal -u $clientid -p $secret --tenant $tenant
  if [ $? -eq 0 ]; then
    az account set -s $sub
    if [ $? -eq 0 ]; then
      echo "Complete Login process"
    else
      exit 22
    fi
  else
    exit 21
  fi
}

tokenValidation(){
  token=$1
  if [ -z "$token" ]; then
    token='abcdef.0123456789abcdef'
  fi
  tokenValidation=`echo $token | grep -Eo '[a-z0-9]{6}.[a-z0-9]{16}'`
  if [ -z "$tokenValidation" ]; then   
    exit 23
  fi
}

sasGeneration(){
    storageAccount=$1
    echo "Generating the sas token and load it to the script"
    end=`date -u -d "30 minutes" '+%Y-%m-%dT%H:%MZ'`
    #set -x
    sas=`az storage account generate-sas --permissions cdlruwap --account-name $storageAccount --services b --resource-types co --expiry $end` 
    #set +x
    sas=`echo -n "$sas"|sed 's/"//g'`
    if [ "$?" -ne 0 ]; then
      exit 24
    fi
    #set -x
    cat /dev/null > ./scripts/func/env.sh 
    echo "sas='$sas'" > ./scripts/func/env.sh 
}

createScriptContainer(){
  storageAccount=$1 
  scriptContainer=$2 
  scriptContainer_exist=$3
  if [ "$scriptContainer_exist" == "Yes" ]; then
    #set -x
    curl -X PUT -H "x-ms-blob-public-access: blob" -H "Content-Length: 0" "https://$storageAccount.blob.core.windows.net/$scriptContainer?restype=container&$sas"
    #set +x
  fi
} 

createConfContainer(){
  storageAccount=$1 
  confContainer=$2 
  confContainer_exist=$3
  if [ "$confContainer_exist" == "Yes" ]; then
    curl -X PUT -H "Content-Length: 0" "https://$sa.blob.core.windows.net/$confContainer?restype=container&$sas"
  fi
}

pkiGeneration(){
  cleanup=$1
  if [ -d "./scripts/conf/pki" ]; then
    echo "Deletng the existing PKI"
    rm -rf ./scripts/conf/pki
  fi
  echo "Generate the new certificates to the PKI folder(https://kubernetes.io/docs/setup/best-practices/certificates/)"
  mkdir ./scripts/conf/pki
  echo "Generate the CA for 'kubernetes'"
  openssl genrsa -out ./scripts/conf/pki/ca.key 2048 
  openssl req -new -x509 -key ./scripts/conf/pki/ca.key -subj '/CN=kubernetes-ca' -out ./scripts/conf/pki/ca.crt
  if [ -f "./scripts/conf/pki/ca.crt" ] && [ -f "./scripts/conf/pki/ca.key" ]; then
    echo "k8s CA pair has been created successfully"
  else
    exit 25
  fi
}

scriptUploadFunc(){
  scriptUpload=$1
  storageAccount=$2
  scriptContainer$3
  sas=$4
  if [ $scriptUpload == "Yes" ]; then
    echo "Uploading the tar file to blob storage"
    tar -cvf script.tar scripts/
    #az storage blob upload --account-name $sa --container-name $container --name scripts.tar --file scripts.tar --sas-token $sas
    #set -x
    curl -X PUT -T ./script.tar -H "x-ms-blob-type: BlockBlob" "https://$storageAccount.blob.core.windows.net/$scriptContainer/scripts.tar?$sas"
    #set +x
    if [ "$?" -ne 0 ]; then
      echo "Failed to upload blob. Please retry"
      exit 26
    else
      echo "Upload successfully"
    fi
  elif [ $scriptUpload == "No" ]; then
    echo "Skip upload the tar file"   
  else
    echo "Not a valid option. Please retry"
    exit 27
  fi
}

execution(){
  resourceGroup=$1
  vmss=$2
  instance=$3
  nodeType=$4
  storageAccount=$5
  scriptContainer$6
  confContainer=$7
  sas=$8
  scriptblob="https://$storageAccount.blob.core.windows.net/$scriptContainer/scripts.tar"
  confblob="https://$storageAccount.blob.core.windows.net/$confContainer/admin.conf?"
  if [ "$nodeType" == "Master" ]; then
    az vmss run-command invoke --command-id RunShellScript --scripts "cd /var/log/; ls script*; if [ "$?" -eq 0 ]; then rm -rf scripts*;fi;timeout 30 wget $scriptblob --quiet; if [ $? -ne 0 ]; then echo 'failed to download' && exit 1;fi; tar -xvf scripts.tar > /dev/null 2>&1 && cd scripts && chmod -R 777 * && bash -c './main.sh $token $apiserver $scriptblob $confblob $nodeType' >>/var/log/scripts/initilization.log 2>&1; if [ $? -eq 0 ];then echo 'succeed'; else echo 'failed';fi" --parameters $token $apiserver $scriptblob $confblob $master -g $resourceGroup -n $vmss --instance-id $instance
    if [ "$?" -ne 0 ]; then
      exit 28
    fi
  fi
}

interactive(){

  continue=0
  while [ "$continue" == 0 ]
  do
    echo "Let's login to Azure at first"
    read -p "Please input service princiapl client ID to login to Azure: " clientid
    read -p "Please input service princiapl secret to login to Azure: " secret
    read -p "Please input service princiapl tenant to login to Azure: " tenant
    read -p "Please input subscription ID: " sub 
    loginAzure $clientid $secret $tenant $sub
    res=$?
    if [ "$res" -eq 21 ]; then
      echo "Failed to login. Please retry"
    elif [ "$res" -eq 22 ]; then
      echo "Failed to set up subscription. Please retry"
    else
      continue=1
      res=0
    fi
  done

  continue=0
  while [ "$continue" -eq 0 ]
  do
    echo "Let's input the cluster information for provisioning"
    read -p "Please input the apiserver fqdn: " apiserver
    read -p "Please input the resource group name " resourceGroup
    read -p "Please input the token. Default one is 'abcdef.0123456789abcdef' " token
    tokenValidation $token
    res=$?
    if [ "$res" -eq 23 ]; then
      echo "$token is invalid. Tokne has to be [a-z0-9]{6}.[a-z0-9]{16}'. Please retry"
    else
      echo 'Token validation passed'
      continue=1
      res=0
    fi
  done

  continue=0
  while [ "$continue" -eq 0 ]
  do
    echo "Let's input the information for storage"
    read -p "Please input the Storage account name: " storageAccount
    sasGeneration $storageAccount
    res=$?
    #set +x
    if [ "$res" -eq 24 ]; then
      echo "Failed to generate the sas token"
    else
      echo" SAS token has been generated. Please protect the env.sh under scripts/func folder"
      continue=1
      res=0
    fi
  done

  continue=0
  while [ "$continue" -eq 0 ]
  do
    read -p "Please input the Script container name: " scriptContainer
    read -p "Whether needs to create the Script container(Yes/No)? " scriptContainer_exist
    createScriptContainer $storageAccount $scriptContainer $scriptContainer_exist
    read -p "Please input the Kubeconfig container name: " confContainer 
    read -p "Whether needs to create the Kubeconfig container(Yes/No)?" confContainer_exist
    createConfContainer $storageAccount $confContainer $confContainer_exist
    continue=1
  done


  continue=0
  while [ "$continue" == 0 ]
  do
    echo "Prepare certificates"
    if [ -d "./scripts/conf/pki" ]; then
      read -p 'PKI folder exists. Would you like to clean up the existing PKI(Yes/No)? ' cleanup
    fi
    if [ "$cleanup" == "Yes" ]; then
      pkiGeneration $cleanup
    fi
    res=$?
    if [ "$res" -eq 25 ]; then
      echo "pki failed to be generated. Please retry"
    else
      continue=1
      res=0
    fi
  done

  continue=0
  while [ "$continue" == 0 ]
  do
    echo "Scripts/configs update"
    read -p "Would you like to upload the scripts file to blob storage(Yes/No)? " scriptUpload
    scriptUploadFunc $scriptUpload $storageAccount $scriptContainer $sas
    res=$?
    if [ "$res" -eq 26 ]; then
      echo "Failed to upload. Please retry"
    elif [ "$res" -eq 27 ]; then
      echo "Not a valid option for uploading. Please retry"
    else
      echo "Upload successfully"
      continue=1
      res=0
    fi
  done

  continue=0
  while [ "$continue" == 0 ]
  do
    echo "Execute the command on the VM"
    read -p "Please input the VMSS name: " vmss
    read -p "Please input the instance ID " instance
    read -p "Please input the node type(Master/Agent) " nodeType
    while [ "$continue" == 0 ]
    do
      read -p 'Whether this is the 1st Master(Yes/No)? ' first
      if [ "$first" == "No" ]; then
        echo "Currently only single control plane is supported. Please retry. "
      else
        continue=1
      fi
    done
    execution $resourceGroup $vmss $instance $nodeType $storageAccount $scriptContainer $confContainer $sas
    res=$?
    if [ "$res" -eq 0 ]; then
      echo "Provision complete."
    elif [ "$res" -eq 28 ]; then
      echo "Execution command on the VM failed."
    fi
  done
}


main(){
  continue=0
  while [ "$continue" == 0 ]
  do
    read -p "Interactive mode(Yes/No)? " interactive
    if [ "$interactive" == "Yes" ]; then
      interactive
      continue=1
    elif [ "$interactive" == "No" ]; then
      echo "Please input the absolute path of the parameter file" paraPath
      auto $paraPath
      continue=1
    else
      echo "Invalid option. Please retry"
    fi
  done
}

set -x
main 2>&1|tee ./provision.log

set +x