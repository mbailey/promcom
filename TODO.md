TODO
====

- document how to use with ec2 discovery
  - document how to get security group
    - add security group to stack outputs
    - make repo public

- durable
  - separate EBS volume that gets mounted
  - how do we make grafana configs/data durable?
  - work out how to make it not replace instance when AmazonLinux2 ami changes
  ```
     {
       "ParameterKey": "ImageId",
       "ParameterValue": "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2",
  -    "ResolvedValue": "ami-04481c741a0311bbb"
  +    "ResolvedValue": "ami-0c3228fd049cdb151"
     },
  ```

- sd_ec2 should contain a label with stack name and maybe instance-id

- how to keep local configs
  - fork and remove from .gitignore?

- grafana
  - document how to save dashboard as JSON
  - document sharing grafana graph without login
  - can we give readonly access without login?


# Monitoring

- whitebox: service claims to be working
- blackbox/synthetic: we can actually use service
- passive: we see others are using the service
