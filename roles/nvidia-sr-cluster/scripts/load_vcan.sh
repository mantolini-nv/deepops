#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

modprobe vcan
ip link add dev vcan0 type vcan
ip link set up vcan0
