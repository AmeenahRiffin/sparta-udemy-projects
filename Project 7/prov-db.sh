#!/bin/bash

echo -e "\033[32mStarting database provisioning script...\033[0m"
sudo apt update -y || { echo -e "\033[32mFailed to update package lists\033[0m"; exit 1; }

# Add MongoDB GPG key if not already added
echo -e "\033[32mChecking and adding MongoDB GPG key...\033[0m"
if ! apt-key list | grep -q "MongoDB"; then
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add - || { echo -e "\033[32mFailed to add MongoDB GPG key\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB GPG key added successfully\033[0m"
else
    echo -e "\033[32mMongoDB GPG key already present\033[0m"
fi

# Add MongoDB repository if not already added
echo -e "\033[32mChecking and adding MongoDB repository...\033[0m"
if [ ! -f "/etc/apt/sources.list.d/mongodb-org-6.0.list" ]; then
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list || { echo -e "\033[32mFailed to add MongoDB repository\033[0m"; exit 1; }
    sudo apt-get update || { echo -e "\033[32mFailed to update package lists after adding repository\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB repository added successfully\033[0m"
else
    echo -e "\033[32mMongoDB repository already configured\033[0m"
fi

# Install libssl if not already installed
echo -e "\033[32mChecking and installing libssl1.1...\033[0m"
if ! dpkg -l | grep -q "libssl1.1"; then
    sudo wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb || { echo -e "\033[32mFailed to download libssl1.1\033[0m"; exit 1; }
    sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb || { echo -e "\033[32mFailed to install libssl1.1\033[0m"; exit 1; }
    echo -e "\033[32mlibssl1.1 installed successfully\033[0m"
else
    echo -e "\033[32mlibssl1.1 already installed\033[0m"
fi

# Install MongoDB if not already installed
echo -e "\033[32mChecking and installing MongoDB...\033[0m"
if ! dpkg -l | grep -q "mongodb-org"; then
    sudo apt-get install -y mongodb-org || { echo -e "\033[32mFailed to install MongoDB\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB installed successfully\033[0m"
else
    echo -e "\033[32mMongoDB already installed\033[0m"
fi

# Update MongoDB config if not already updated
echo -e "\033[32mChecking and updating MongoDB configuration...\033[0m"
if grep -q "  bindIp: 127.0.0.1" /etc/mongod.conf; then
    sudo sed -i "s/  bindIp: 127.0.0.1/  bindIp: 0.0.0.0/" /etc/mongod.conf || { echo -e "\033[32mFailed to update MongoDB configuration\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB configuration updated successfully\033[0m"
else
    echo -e "\033[32mMongoDB configuration already set\033[0m"
fi

# Start and enable MongoDB service if not already running
echo -e "\033[32mChecking and starting MongoDB service...\033[0m"
if ! systemctl is-active --quiet mongod; then
    sudo systemctl start mongod || { echo -e "\033[32mFailed to start MongoDB service\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB service started successfully\033[0m"
else
    echo -e "\033[32mMongoDB service already running\033[0m"
fi

echo -e "\033[32mChecking and enabling MongoDB service on startup...\033[0m"
if ! systemctl is-enabled --quiet mongod; then
    sudo systemctl enable mongod || { echo -e "\033[32mFailed to enable MongoDB service\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB service enabled successfully\033[0m"
else
    echo -e "\033[32mMongoDB service already enabled at startup\033[0m"
fi

echo -e "\033[32mSetting database host environment variable...\033[0m"



# Check if app is running, if not start it
echo -e "\033[32mChecking and starting application...\033[0m"
if ! pm2 list | grep -q "app"; then
    cd app || { echo -e "\033[32mFailed to change to app directory\033[0m"; exit 1; }
    pm2 start app.js || { echo -e "\033[32mFailed to start application\033[0m"; exit 1; }
    echo -e "\033[32mApplication started successfully\033[0m"
else
    echo -e "\033[32mApplication already running\033[0m"
fi

echo -e "\033[32mDatabase provisioning completed successfully\033[0m"