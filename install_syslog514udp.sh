#!/bin/bash

# Variables
REMOTE_SYSLOG_IP="10.88.0.184"  # Replace with your remote syslog server IP
SYSLOG_PORT="514"                 # Standard syslog port for UDP

# Install rsyslog if not already installed
echo "Installing rsyslog if not already installed..."
sudo apt update
sudo apt install -y rsyslog

# Backup original rsyslog configuration
echo "Backing up the original rsyslog configuration..."
sudo cp /etc/rsyslog.conf /etc/rsyslog.conf.bak

# Update rsyslog.conf for remote UDP logging
echo "Configuring rsyslog to send logs to $REMOTE_SYSLOG_IP via UDP..."

sudo bash -c "cat >> /etc/rsyslog.conf <<EOL

# Enable UDP syslog reception
module(load=\"imudp\")
input(type=\"imudp\" port=\"$SYSLOG_PORT\")

# Send all logs to remote syslog server via UDP
*.* @$REMOTE_SYSLOG_IP:$SYSLOG_PORT
EOL"

# Restart rsyslog service to apply changes
echo "Restarting rsyslog service..."
sudo systemctl restart rsyslog

# Check the status of rsyslog
echo "Checking rsyslog status..."
sudo systemctl status rsyslog | grep "active (running)"

# Verify if the firewall allows UDP syslog traffic
echo "Configuring firewall to allow traffic on port $SYSLOG_PORT (UDP)..."
sudo ufw allow $SYSLOG_PORT/udp

echo "Syslog configuration completed. Logs are being sent to $REMOTE_SYSLOG_IP via UDP on port $SYSLOG_PORT."

logger "test"
