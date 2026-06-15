#!/bin/bash

set -e

echo "Updating packages..."
sudo apt update

# Docker
if command -v docker >/dev/null 2>&1; then
    echo "Docker already installed"
else
    echo "Installing Docker..."

    sudo apt install -y ca-certificates curl

    sudo install -m 0755 -d /etc/apt/keyrings

    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc

    sudo chmod a+r /etc/apt/keyrings/docker.asc

    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt update

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker
fi

# Docker Compose
if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose already installed"
else
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose-plugin
fi

# Python
if command -v python3 >/dev/null 2>&1; then
    if python3 -c 'import sys; exit(0 if sys.version_info >= (3,9) else 1)'; then
        echo "Python 3.9+ already installed"
    else
        echo "Python version is lower than 3.9"
        exit 1
    fi
else
    echo "Installing Python..."
    sudo apt install -y python3 python3-pip
fi

# pip
if command -v pip3 >/dev/null 2>&1; then
    echo "Pip already installed"
else
    echo "Installing pip..."
    sudo apt install -y python3-pip
fi

# Django
if python3 -m django --version >/dev/null 2>&1; then
    echo "Django already installed"
else
    echo "Installing Django..."
    python3 -m pip install --break-system-packages django
fi

echo ""
echo "Installed versions:"
echo "Docker:"
docker --version

echo "Docker Compose:"
docker compose version

echo "Python:"
python3 --version

echo "Django:"
python3 -m django --version