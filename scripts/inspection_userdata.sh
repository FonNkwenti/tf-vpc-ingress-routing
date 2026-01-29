#!/bin/bash
echo "Enabling IP Forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
yum install -y tcpdump
