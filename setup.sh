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

# reboot the machine
sudo reboot

# back in, in a new session, check that drivers were set up correctly
nvidia-smi

# install nvidia-docker
sudo apt-get update -y
sudo systemctl stop docker
sudo apt-get install -y \
    nvidia-docker2
sudo systemctl restart docker

# check that nvidia-docker was set up correctly,
# and works for the base image relevant to this PR
sudo docker run \
    --rm \
    --gpus all \
    nvidia/cuda:8.0-cudnn5-devel \
    nvidia-smi

# install conda
ARCH=$(uname -m)
sudo curl \
    -L \
    -o miniforge.sh \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${ARCH}.sh

sudo sh miniforge.sh -b -p /opt/miniforge
export PATH="/opt/miniforge/bin:${PATH}"

conda create \
    --name lgb-wheel-test \
    -c conda-forge \
    --yes \
        python=3.9 \
        numpy \
        scikit-learn \
        wheel


# build lightgbm wheel
source activate lgb-wheel-test
sudo mkdir /usr/local/src/LightGBM
sudo git clone \
    --recursive \
    https://github.com/jgiannuzzi/LightGBM.git \
    --branch linux-gpu-wheel \
    /usr/local/src/LightGBM

cd /usr/local/src/LightGBM/python-package


python setup.py bdist_wheel \
    --integrated-opencl \
    --plat-name=manylinux2014_aarch64 \
    --python-tag py3


BUILD_ID=13868
sudo wget \
    -O artifacts.zip \
    "https://dev.azure.com/lightgbm-ci/lightgbm-ci/_apis/build/builds/${BUILD_ID}/artifacts?artifactName=PackageAssets&api-version=7.1-preview.5&%24format=zip"

