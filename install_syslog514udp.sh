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

###############
#### RULES ####
###############

#
# First some standard log files.  Log by facility.
#
auth,authpriv.*                 /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog
#cron.*                         /var/log/cron.log
daemon.*                        -/var/log/daemon.log
kern.*                          -/var/log/kern.log
lpr.*                           -/var/log/lpr.log
mail.*                          -/var/log/mail.log
user.*                          -/var/log/user.log

#
# Logging for the mail system.  Split it up so that
# it is easy to write scripts to parse these files.
#
mail.info                       -/var/log/mail.info
mail.warn                       -/var/log/mail.warn
mail.err                        /var/log/mail.err

#
# Some "catch-all" log files.
#
*.=debug;\
        auth,authpriv.none;\
        mail.none               -/var/log/debug
*.=info;*.=notice;*.=warn;\
        auth,authpriv.none;\
        cron,daemon.none;\
        mail.none               -/var/log/messages

#
# Emergencies are sent to everybody logged in.
#
*.emerg                         :omusrmsg:*

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
sudo systemctl status rsyslog 

# Verify if the firewall allows UDP syslog traffic
echo "Configuring firewall to allow traffic on port $SYSLOG_PORT (UDP)..."
sudo ufw allow $SYSLOG_PORT/udp

echo "Syslog configuration completed. Logs are being sent to $REMOTE_SYSLOG_IP via UDP on port $SYSLOG_PORT."
logger "Test message from hostname: $(hostname)"
