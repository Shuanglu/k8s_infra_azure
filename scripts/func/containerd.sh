#!/bin/bash

containerd() {
    echo 'Installing the containerd'
    apt-get update -y && apt-get install -y containerd=1.2.6-0ubuntu1~16.04.3 
}
