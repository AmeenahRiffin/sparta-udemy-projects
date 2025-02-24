# Project 7: Bash script only used in user data to run app when creating a VM from an app image #
# Objective: Run the app with pm2 when the VM is created from the app image #

# Set environment variable and start app
export DB_HOST=mongodb://localhost:27017/posts ## To be changed to private ip of db

# Check if app is running, if not start it
if ! pm2 list | grep -q "app"; then
    cd app
    pm2 start app.js
fi