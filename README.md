# lightgbm-gpu-testing

I got a GPU-enabled EC2 instance on AWS with the following specifications.

- **AMI**: Ubuntu 18.04 (ami-0b152cfd354c4c7a4)
- **instance type**: g4dn.xlarge (1 NVIDIA T4 GPU)
- **region**: us-west-2
- **root volume size**: 100GB

```shell
chmod 0400 "${HOME}/.aws/gpu-testing-2.cer"
ssh \
    -i "${HOME}/.aws/gpu-testing-2.cer" \
    ubuntu@ec2-52-43-42-235.us-west-2.compute.amazonaws.com
```

ARM

- **AMI**: Ubuntu 22.02 (ami-0db84aebfa8d17e23)
- **instance type**: g5g.2xlarge (1 NVIDIA T4G Tensor Core GPU, 16GB GPU memory)
- **region**: us-west-2
- **root volume size**: 100GB

```shell
ssh \
    -i "${HOME}/.aws/gpu-testing.cer" \
    ubuntu@ec2-52-43-171-110.us-west-2.compute.amazonaws.com
```