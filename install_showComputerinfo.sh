#!/bin/bash

# Define the URL to download the script
SCRIPT_URL="https://raw.githubusercontent.com/jfdelphi/installerU22/main/showComputerinfo.sh"
# Define where to save the downloaded script
SCRIPT_PATH="/usr/local/bin/showComputerinfo.sh"

# Step 1: Download the showComputerinfo.sh script
echo "Downloading showComputerinfo.sh script..."
wget -O "$SCRIPT_PATH" "$SCRIPT_URL"

# Check if the script was downloaded successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to download the script from $SCRIPT_URL"
    exit 1
fi

# Step 2: Make the downloaded script executable
echo "Making $SCRIPT_PATH executable..."
sudo chmod +x "$SCRIPT_PATH"

# Step 3: Create or edit /etc/rc.local
echo "Setting up /etc/rc.local..."
sudo bash -c 'cat > /etc/rc.local <<EOF
#!/bin/bash
'$SCRIPT_PATH'
exit 0
EOF'

# Step 4: Make /etc/rc.local executable
echo "Making /etc/rc.local executable..."
sudo chmod +x /etc/rc.local

# Step 5: Create systemd service for rc.local if it doesn't exist
if [ ! -f /etc/systemd/system/rc-local.service ]; then
    echo "Creating /etc/systemd/system/rc-local.service..."
    sudo bash -c 'cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF'
fi

# Step 6: Enable and start rc-local service
echo "Enabling and starting rc-local service..."
sudo systemctl enable rc-local
sudo systemctl start rc-local

# Check if the rc.local service is running
if systemctl status rc-local | grep -q "active (running)"; then
    echo "Success: rc.local service is running. Your script will now run at startup."
else
    echo "Error: rc.local service is not running. Check the status using 'systemctl status rc-local'."
fi
