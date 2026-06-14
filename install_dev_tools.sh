#!/bin/bash

echo "Updating packages..."
sudo apt update

#Docker
if command -v docker >/dev/null 2>&1; then
	echo "Docker already installed"
else
	echo "Installing Docker..."
	sudo apt install -y docker.io
	sudo systemctl enable docker
	sudo systemctl start docker
fi

#Docker Compose
if docker compose version >/dev/null 2>&1; then
	echo "Docker compose already installed"
else
	echo "Installing docker compose..."
	sudo apt install -y docker-compose-v2
fi

#Python
if command -v python3 >/dev/null 2>&1; then
	echo "Python already installed"
else
	echo "Installing Python..."
	sudo apt install -y python3
fi

#pip
if command -v pip3 >/dev/null 2>&1; then
	echo "Pip already installed"
else
	echo "Installing pip..."
	sudo apt install -y python3-pip
fi

#Django
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
echo "Docker compose:"
docker compose version
echo "Python:"
python3 --version
echo "Django:"
python3 -m django --version
