# Install Promcom

This is a spike to assist learning Prometheus (and friends).

## Prerequisites

- [bash-my-aws](https://github.com/bash-my-universe/bash-my-aws): handy commands
- git
- podman-compose (or docker-compose)

### docker aliases

I use podman as a drop in docker replacement but use `docker` and `docker-compose`
commands to make these instructions easier for others who still use them.

```shell
echo "alias docker='podman'"
echo "alias docker-compose='podman compose'"
```

## Option 1: Setup manually on a host (fedora)

Use these commands to setup on workstation or VM.

### Install node_exporter on host (fedora)

XXX Work out why SELinux is preventing some containers from accessing shared files

```shell
sudo setenforce 0
```

This exports host metrics and makes them available to prometheus docker container.

```shell
sudo dnf install -y golang-github-prometheus-node-exporter
sudo systemctl enable --now node_exporter
```

### Run containers for prometheus, grafana, etc

```shell
git clone https://github.com/mbailey/promcom.git
cd promcom
docker-compose up
```

## Option 2: Setup from scratch on AWS

### Create keypair for SSH access to instance

If you choose to use an existing EC2 SSH Keypair instead, provide a reference
to it in config/CONFIG_FILE.

```shell
$ keypair-create "promcom-$(aws-account-alias)-$(region)"
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/m/.ssh/promcom-keypair.
Your public key has been saved in /home/m/.ssh/promcom-keypair.pub.
The key fingerprint is:
SHA256:zabQZr9krW6lnpYUpYSU4/RlRXJ6k5pvmwbqq1/8EFo m@lath
The key's randomart image is:
+---[RSA 4096]----+
|       ..o  .o+  |
|        = . ++ . |
|       o + =. +  |
|       ..o+  + . |
|      . S +.E    |
|       + +.=oo   |
|        ..===.o  |
|         o*= +.o |
|        .OX. .+  |
+----[SHA256]-----+
{
    "KeyName": "promcom-failmode-ap-southeast-2",
    "KeyFingerprint": "bd:aa:bc:58:b3:b0:14:6d:22:0a:f9:77:35:fc:d9:02"
}
```

### Create CloudFormation stack

1. **Change to the cloudformation directory**

    ```shell
    cd cloudformation
    ```

1. **Create and edit a new file with CloudFormation Parameters**

    ```shell
    cp params/promcom-params-skeleton.json params/promcom-params-example.json
    ```

    Hints:
    - If you created an SSH Keypair in the previous step, use that KeyName
    - ELB and Instance should be in the same Availability Zone (AZ)
    - You probably want the InstanceSubnetId to be a private subnet
    - You probably want the ELBSubnetId to be a public subnet

1. **Deploy CloudFormation Stack**

    ```shell
    stack-create params/promcom-params-example.json --capabilities=CAPABILITY_IAM
    ```

1. **Get hostname of the ELB**

    ```shell
    $ stack-outputs promcom-example
    IndexURL       https://metrics.example.com/  Web page linking to services
    SecurityGroup  sg-09411fafc6c01a911          PromCom Instance Security Group
    ```

### Deploy the app to the instance

1. **Configure local config file**

    It will look something like this:

    ```shell
    $ cat config/ENVIRONMENT_NAME
    PROMCOM_TARGET_HOST=metrics.example.com
    PROMCOM_SSH_PRIVATE_KEY="~/.ssh/promcom-example"
    ```

    Edit it or create a copy to edit.

    Update the file with hostname (from `stack-outputs`) and SSH private key.

1. **Run the deploy script with the provisioner enabled**

    ```shell
    script/deploy config/example-target --provision
    ```

### Test it's working

1. **View web interfaces**

    The following services should be available via your web browser:
    - Prometheus
    - Grafana
    - Alertmanager
    - Blackbox exporter
    - nginx (for experimenting with exposition at /metrics)

    They are linked to from an index page exposed by your load balancer:

    ```shell
    $ stack-outputs promcom-example
    Web page linking to all the services  IndexURL  https://promcom-example.failmode.com.au/
    ```

1. **SSH to instance**

    ```shell
    $ script/promcom-ssh config/example-target
    Last login: Mon Mar 11 00:59:15 2019 from ip-10-52-3-22.ap-southeast-2.compute.internal

           __|  __|_  )
           _|  (     /   Amazon Linux 2 AMI
          ___|\___|___|

    https://aws.amazon.com/amazon-linux-2/
    6 package(s) needed for security, out of 8 available
    Run "sudo yum update" to apply all updates.
    [ec2-user@ip-10-1-2-3 ~]$

    ```

### Troubleshooting

Check console output of instance:

```shell
$ stack-instances promcom-foobar | instance-console
Console output for EC2 Instance i-03cce8a813d1c70a5
[    0.000000] Linux version 4.14.97-90.72.amzn2.x86_64 (mockbuild@ip-10-0-1-59) (gcc version 7.3.1 20180303 (Red Hat 7.3.1-5) (GCC)) #1 SMP Tue Feb 5 20:46:19 UTC 2019
[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-4.14.97-90.72.amzn2.x86_64 root=UUID=d224eff3-ac37-4a24-a33d-b499ca34c533 ro console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 nvme_core.io_timeout=4294967295 rd.emergency=poweroff rd.shell=0
[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'
[    0.000000] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256
[    0.000000] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'standard' format.
[    0.000000] e820: BIOS-provided physical RAM map:
...
```

SSH to instance (via ELB):

```shell
$ script/promcom-ssh config/example-target
The authenticity of host 'promcom-foobar.failmode.com (13.211.189.222)' can't be established.
ECDSA key fingerprint is SHA256:1dgeeF77qejZIyhvEK69GwO9AiQMSngFYd5+DTQ5Oqc.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'promcom-foobar.failmode.com,1.2.3.4' (ECDSA) to the list of known hosts.

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
5 package(s) needed for security, out of 8 available
Run "sudo yum update" to apply all updates.
$
```

## Delete Stack

To protect against accidental loss of data, EC2 Instance Temination Protection is enabled in the stack.

To delete the stack you'll need to disable this first:

```shell
[m@lath resi-leads-staging-Dev promcom (mike)]$ stack-instances promcom-example | instance-termination-protection-disable
You are about to disable termination protection on the following instances:
i-0e793a7d1be43dcc9  ami-0c3228fd049cdb151  t2.medium  running  None  2019-03-11T08:53:44.000Z  ap-southeast-2a  vpc-b1789ad6
Are you sure you want to continue? y
```

Now you should be able to delete the stack:

```shell
stack-delete promcom-example
```
