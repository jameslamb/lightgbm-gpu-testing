#!/bin/bash

set -e -u -o pipefail

# following https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

# install docker
sudo apt-get update -y
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io

sudo systemctl enable docker
sudo systemctl start docker

# install nvidia-docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add - \
    && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# get nvidia drivers and tools
# (versions selected by choosing the newest thing shown in `apt search nvidia-driver`)
sudo add-apt-repository ppa:graphics-drivers/ppa --yes
sudo apt-get update -y
sudo apt-get install -y \
    nvidia-driver-515 \
    nvidia-utils-515

# install conda
echo "installing conda..."
ARCH=$(uname -m)
sudo curl \
    -L \
    -o miniforge.sh \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${ARCH}.sh

sudo sh miniforge.sh -b -p /opt/miniforge
export PATH="/opt/miniforge/bin:${PATH}"

conda create \
    --name lgb-gpu \
    -c conda-forge \
    --yes \
        python=3.9 \
        numpy \
        scikit-learn \
        wheel

echo "done installing conda"

echo "cloning LightGBM"
sudo git clone \
    --recursive \
    https://github.com/microsoft/LightGBM.git \
    /usr/local/src/LightGBM
echo "done cloning LightGBM"

sudo usermod -aG docker $USER

# reboot the machine
# sudo reboot
