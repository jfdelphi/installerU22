#!/bin/bash

hostnamectl

local_ip=$(hostname -I | awk '{print $1}')
echo "Local IP: $local_ip"

public_ip=$(curl -s ifconfig.me)
echo "Public IP: $public_ip"
