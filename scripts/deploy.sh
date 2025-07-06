#!/bin/bash

echo "Starting Docker installation and container deployment..."

# Install Docker
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Fix Docker permissions
echo "Setting up Docker permissions..."
sudo groupadd -f docker
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
echo "Note: For permanent permission fix, please log out and log back in after this script completes"

# Clean up existing containers
echo "Cleaning up existing containers..."
sudo docker stop focusflow-app || true
sudo docker rm focusflow-app || true

# Clean up all Docker images
echo "Removing all Docker images..."
# Remove all containers (running or stopped)
sudo docker rm -f $(sudo docker ps -aq) || echo "No containers to remove"

# Remove all images related to focusflow
echo "Removing all focusflow images..."
sudo docker rmi -f $(sudo docker images | grep focusflow | awk '{print $3}') || echo "No focusflow images to remove"

# Remove all dangling images (untagged images)
echo "Removing all dangling images..."
sudo docker image prune -f

# Pull the FocusFlow container
echo "Pulling FocusFlow container..."
sudo docker pull mubaraklouis/focusflow:1.4.5

# Ask user if they want to run in debug mode
echo ""
echo "Do you want to run the container in debug mode? (y/n)"
read -r debug_mode

if [ "$debug_mode" = "y" ]; then
  # Run container with interactive shell for debugging
  echo "Starting container in debug mode with interactive shell..."
  sudo docker run --name focusflow-app \
    -p 8000:8000 \
    -e "PORT=8000" \
    -e "DEBUG=true" \
    -it mubaraklouis/focusflow:1.4.5 /bin/sh
else
  # Run with standard configuration but with more environment variables
  echo "Running FocusFlow container with standard configuration..."
  sudo docker run --name focusflow-app \
    -p 8000:8000 \
    -e "PORT=8000" \
    -e "NODE_ENV=production" \
    -e "DEBUG=true" \
    --restart unless-stopped \
    -d mubaraklouis/focusflow:1.4.5

  # Check if container is running
  echo "Checking container status..."
  sudo docker ps
  echo "If no container is listed above or it's restarting, checking logs..."
  sudo docker ps -a

  # Show extended logs for debugging
  echo ""
  echo "Extended container logs (last 50 lines):"
  sudo docker logs focusflow-app --tail 50

  # Additional debugging information
  echo ""
  echo "Container inspection (might reveal configuration issues):"
  sudo docker inspect focusflow-app | grep -A 10 "State"
fi

echo ""
echo "Docker installation and container deployment completed!"
echo ""
echo "Troubleshooting tips if container keeps restarting:"
echo "1. Check logs for specific error messages: sudo docker logs focusflow-app"
echo "2. Try running with interactive shell: sudo docker run -it --rm mubaraklouis/focusflow:1.4.5 /bin/sh"
echo "3. Check if required environment variables are set"
echo "4. Verify the container's entrypoint script is executable"
echo ""
echo "============================================================"
echo "IMPORTANT: To use Docker without sudo, log out and log back in"
echo "or run the following command to apply changes in current session:"
echo "    newgrp docker"
echo "============================================================"