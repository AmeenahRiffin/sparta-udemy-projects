#!/bin/bash

echo -e "\033[32mStarting Sparta App provisioning script...\033[0m"

# Update package lists if not updated in last hour
echo -e "\033[32mChecking if package lists need updating...\033[0m"
if [ ! -f "/var/cache/apt/pkgcache.bin" ] || [ $(stat -c %Y /var/cache/apt/pkgcache.bin) -lt $(date +%s -d "1 hour ago") ]; then
    sudo apt update -y || { echo -e "\033[31mFailed to update package lists\033[0m"; exit 1; }
    echo -e "\033[32mPackage lists updated successfully\033[0m"
else
    echo -e "\033[32mPackage lists are up to date\033[0m"
fi

# Install packages if not present
echo -e "\033[32mChecking and installing required packages...\033[0m"
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx || { echo -e "\033[31mFailed to install nginx\033[0m"; exit 1; }
    echo -e "\033[32mNginx installed successfully\033[0m"
else
    echo -e "\033[32mNginx is already installed\033[0m"
fi

if ! command -v git &> /dev/null; then
    sudo apt install -y git || { echo -e "\033[31mFailed to install git\033[0m"; exit 1; }
    echo -e "\033[32mGit installed successfully\033[0m"
else
    echo -e "\033[32mGit is already installed\033[0m"
fi

# Install Node.js if not present
echo -e "\033[32mChecking and installing Node.js...\033[0m"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - || { echo -e "\033[31mFailed to setup Node.js repository\033[0m"; exit 1; }
    sudo apt install -y nodejs || { echo -e "\033[31mFailed to install Node.js\033[0m"; exit 1; }
    echo -e "\033[32mNode.js installed successfully\033[0m"
else
    echo -e "\033[32mNode.js is already installed\033[0m"
fi

# Install NVM if not present
echo -e "\033[32mChecking and installing NVM...\033[0m"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash || { echo -e "\033[31mFailed to install NVM\033[0m"; exit 1; }
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install node || { echo -e "\033[31mFailed to install Node via NVM\033[0m"; exit 1; }
    echo -e "\033[32mNVM installed successfully\033[0m"
else
    echo -e "\033[32mNVM is already installed\033[0m"
fi

# Add MongoDB repository if not already added
echo -e "\033[32mChecking and adding MongoDB repository...\033[0m"
if [ ! -f "/etc/apt/sources.list.d/mongodb-org-6.0.list" ]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add - || { echo -e "\033[31mFailed to add MongoDB GPG key\033[0m"; exit 1; }
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt-get update || { echo -e "\033[31mFailed to update package lists after adding MongoDB repository\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB repository added successfully\033[0m"
else
    echo -e "\033[32mMongoDB repository is already configured\033[0m"
fi

# Install libssl if not present
echo -e "\033[32mChecking and installing libssl...\033[0m"
if ! dpkg -l | grep -q libssl1.1; then
    wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb || { echo -e "\033[31mFailed to download libssl\033[0m"; exit 1; }
    sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb || { echo -e "\033[31mFailed to install libssl\033[0m"; exit 1; }
    echo -e "\033[32mLibssl installed successfully\033[0m"
else
    echo -e "\033[32mLibssl is already installed\033[0m"
fi

# Install MongoDB if not present
echo -e "\033[32mChecking and installing MongoDB...\033[0m"
if ! command -v mongod &> /dev/null; then
    sudo apt-get install -y mongodb-org || { echo -e "\033[31mFailed to install MongoDB\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB installed successfully\033[0m"
    
    # Configure and start MongoDB
    sudo systemctl start mongod || { echo -e "\033[31mFailed to start MongoDB\033[0m"; exit 1; }
    sudo systemctl enable mongod || { echo -e "\033[31mFailed to enable MongoDB\033[0m"; exit 1; }
    echo -e "\033[32mMongoDB service started and enabled successfully\033[0m"
else
    echo -e "\033[32mMongoDB is already installed\033[0m"
fi

# Enable and start nginx
echo -e "\033[32mEnabling and starting Nginx...\033[0m"
sudo systemctl enable nginx
if ! systemctl is-active --quiet nginx; then
    sudo systemctl start nginx || { echo -e "\033[31mFailed to start Nginx\033[0m"; exit 1; }
    echo -e "\033[32mNginx started successfully\033[0m"
else
    echo -e "\033[32mNginx is already running\033[0m"
fi

# Clone repository
echo -e "\033[32mChecking and cloning repository...\033[0m"
cd ~
if [ ! -d "tech501-sparta-app" ]; then
    git clone https://github.com/AmeenahRiffin/tech501-sparta-app/ || { echo -e "\033[31mFailed to clone repository\033[0m"; exit 1; }
    echo -e "\033[32mRepository cloned successfully\033[0m"
else
    echo -e "\033[32mRepository is already cloned\033[0m"
fi

# Install pm2 globally first
echo -e "\033[32mChecking and installing pm2...\033[0m"
if ! command -v pm2 &> /dev/null; then
    sudo npm install pm2 -g || { echo -e "\033[31mFailed to install pm2\033[0m"; exit 1; }
    echo -e "\033[32mPm2 installed successfully\033[0m"
else
    echo -e "\033[32mPm2 is already installed\033[0m"
fi

# Install npm dependencies
echo -e "\033[32mChecking and installing npm dependencies...\033[0m"
cd ~/tech501-sparta-app/app || { echo -e "\033[31mFailed to change to app directory\033[0m"; exit 1; }
if [ ! -d "node_modules" ]; then
    npm install || { echo -e "\033[31mFailed to install npm dependencies\033[0m"; exit 1; }
    echo -e "\033[32mNpm dependencies installed successfully\033[0m"
else
    echo -e "\033[32mNpm dependencies are already installed\033[0m"
fi

# Set environment variable for DB_HOST
export DB_HOST=mongodb://localhost:27017/posts
echo "export DB_HOST=mongodb://localhost:27017/posts" >> ~/.bashrc

# Start the application with pm2
echo -e "\033[32mStarting application with pm2...\033[0m"
pm2 start app.js || { echo -e "\033[31mFailed to start application with pm2\033[0m"; exit 1; }

# Update nginx configuration
echo -e "\033[32mChecking and updating Nginx configuration...\033[0m"
if ! grep -q "proxy_pass http://127.0.0.1:3000;" /etc/nginx/sites-available/default; then
    sudo sed -i 's|try_files.*|proxy_pass http://127.0.0.1:3000;|' /etc/nginx/sites-available/default || { echo -e "\033[31mFailed to update Nginx configuration\033[0m"; exit 1; }
    sudo systemctl restart nginx || { echo -e "\033[31mFailed to restart Nginx\033[0m"; exit 1; }
    echo -e "\033[32mNginx configuration updated successfully\033[0m"
else
    echo -e "\033[32mNginx configuration is already updated\033[0m"
fi

echo -e "\033[32mProvisioning completed successfully.\033[0m"