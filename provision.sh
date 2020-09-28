#!/bin/bash

openssl genrsa -out ./scripts/conf/ca.key 2048 
openssl req -new -x509 -key ./scripts/conf/ca.key -subj '/CN=kubernetes' -out ./scripts/conf/ca.crt
