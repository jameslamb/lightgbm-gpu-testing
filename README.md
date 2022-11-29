# lightgbm-gpu-testing

## Create an EC2

I got a GPU-enabled EC2 instance on AWS with the following specifications.

- **AMI**: Ubuntu 18.04 (ami-0b152cfd354c4c7a4)
- **instance type**: g4dn.xlarge (1 NVIDIA T4 GPU)
- **region**: us-west-2
- **root volume size**: 100GB

ARM

- **AMI**: Ubuntu 22.02 (ami-0db84aebfa8d17e23)
- **instance type**: g5g.2xlarge (1 NVIDIA T4G Tensor Core GPU, 16GB GPU memory)
- **region**: us-west-2
- **root volume size**: 100GB

## Get this repo

shell in

```shell
chmod 0400 "${HOME}/.aws/gpu-testing.cer"

EC2_HOST="ec2-35-91-68-40.us-west-2.compute.amazonaws.com"
ssh \
    -i "${HOME}/.aws/gpu-testing.cer" \
    ubuntu@${EC2_HOST}
```

Clone this repo.

```shell
sudo git clone \
    --depth 1 \
    https://github.com/jameslamb/lightgbm-gpu-testing.git \
    /usr/local/src/lightgbm-gpu-testing
```

Run the setup.

```shell
/usr/local/src/lightgbm-gpu-testing/setup.sh
```

Reboot the instance.

```shell
sudo reboot
```

Shell back in and restart nvidia-docker.

```shell
EC2_HOST="ec2-35-91-68-40.us-west-2.compute.amazonaws.com"
ssh \
    -i "${HOME}/.aws/gpu-testing.cer" \
    ubuntu@${EC2_HOST}

/usr/local/src/lightgbm-gpu-testing/post-reboot.sh
```
