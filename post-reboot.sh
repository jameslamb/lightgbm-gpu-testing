#!/bin/bash

set -e -u -o pipefail

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
