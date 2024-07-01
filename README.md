# ![aws](https://github.com/julien-muke/Search-Engine-Website-using-AWS/assets/110755734/01cd6124-8014-4baa-a5fe-bd227844d263)     How to Deploy AWS Auto Scaling Group with Terraform.


## <a name="introduction">🤖 Introduction</a>

AWS Auto Scaling groups (ASGs) let you easily scale and manage a collection of EC2 instances that run the same instance configuration. You can then manage the number of running instances manually or dynamically, allowing you to lower operating costs. Since ASGs are dynamic, Terraform does not manage the underlying instances directly because every scaling action would introduce state drift. You can use Terraform lifecycle arguments to avoid drift or accidental changes.

Terraform is an infrastructure as code (Iac) tool that automates infrastructure provisioning. It is the most popular and offers support for multiple clouds.

In this tutorial, you will use Terraform to provision and manage an Auto Scaling group and learn how Terraform configuration supports the dynamic aspects of the resource. You will launch an ASG with traffic managed by a load balancer and define a scaling policy to automatically modify the number of instances running in the group. You will learn how to use lifecycle arguments to avoid unwanted scaling of your ASG.


## <a name="design">📐 Architecture Diagram</a>

![ECS Terraform](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/7b028d20-dbbe-4228-883f-2eb9a2851095)


## <a name="steps">☑️ Steps</a>

The procedure for deploying this architecture on AWS consists of the following steps:

* Create a VPC, Subnets, and Configure network requirements.
* Create EC2 instances with Auto scaling group and Launch template.
* Create a Load balancer with a target group to the Auto Scaling group.


## 📝 Prerequisites

This tutorial assumes that you are familiar with the standard Terraform workflow. If you are new to Terraform, complete the [Get Started tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started) first.

For this tutorial, you will need:

* [Terraform v1.8+ installed locally](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
    
* An [AWS account](https://portal.aws.amazon.com/billing/signup) with [credentials configured for Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).
    
* The [AWS CLI](https://aws.amazon.com/cli/)

##  	:octocat: Clone example repository

Clone the [example repository](https://github.com/julien-muke/learn-terraform-aws-asg) for this tutorial, which contains configuration for an Auto Scaling group.

```bash
git clone https://github.com/julien-muke/learn-terraform-aws-asg.git
```

Change into the repository directory.

```bash
cd learn-terraform-aws-asg
```

## Review configuration

In your code editor, open the `main.tf` file to review the configuration in this repository.

<details>
<summary><code>main.tf</code></summary>

```bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      hashicorp-learn = "aws-asg"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_launch_configuration" "terramino" {
  name_prefix     = "learn-terraform-aws-asg-"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.terramino_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "terramino" {
  name                 = "terramino"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.terramino.name
  vpc_zone_identifier  = module.vpc.public_subnets

  health_check_type    = "ELB"

  tag {
    key                 = "Name"
    value               = "HashiCorp Learn ASG - Terramino"
    propagate_at_launch = true
  }
}

resource "aws_lb" "terramino" {
  name               = "learn-asg-terramino-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terramino_lb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "terramino" {
  load_balancer_arn = aws_lb.terramino.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terramino.arn
  }
}

resource "aws_lb_target_group" "terramino" {
  name     = "learn-asg-terramino"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}


resource "aws_autoscaling_attachment" "terramino" {
  autoscaling_group_name = aws_autoscaling_group.terramino.id
  alb_target_group_arn   = aws_lb_target_group.terramino.arn
}

resource "aws_security_group" "terramino_instance" {
  name = "learn-asg-terramino-instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.terramino_lb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "terramino_lb" {
  name = "learn-asg-terramino-lb"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}
```
</details>


This configuration uses the vpc module to create a new VPC with public subnets for you to provision the rest of the resources in. The other resources reference the VPC module's outputs. For example, the `aws_lb_target_group` resource references the VPC ID. 

![1](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/1c906a25-917d-4ef8-864a-d3c37851c01c)


## EC2 Launch Template

A launch template specifies the EC2 instance configuration that an ASG will use to launch each new instance. 

![2](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/3313785d-3149-42d0-a793-c81d8afc43b7)


Launch configurations support many arguments and customization options for your instances.

This configuration specifies:

* `name_prefix` a name prefix to use for all versions of this launch configuration. Terraform will append a unique identifier to the prefix for each launch configuration created.

* ` image_id` an Amazon Linux AMI specified by a data source.

* `instance_type` an instance type.

* `user_data` a user data script, which configures the instances to run the user-data.sh file in this repository at launch time. The user data script installs dependencies and initializes Terramino, a Terraform-skinned Tetris application. 

* `security_groups` a security group to associate with the instances. The security group (defined later in this file) allows ingress traffic on port 80 and egress traffic to all endpoints.

## Auto Scaling group

An ASG is a logical grouping of EC2 instances running the same configuration. ASGs allow for dynamic scaling and make it easier to manage a group of instances that host the same services. 

![3](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/dbae640b-1856-40f7-a907-44e5a732ef07)


This ASG configuration sets:

* the minimum and maximum number of instances allowed in the group.

* the desired count to `launch desired_capacity`.

* a launch configuration to use for each instance in the group.

* a list of subnets where the ASGs will launch new instances. This configuration references the public subnets created by the `vpc` module.

## Load balancer resources

Since you will launch multiple instances running your Terramino application, you must provision a load balancer to distribute traffic across the instances. 

The `aws_lb` resource creates an application load balancer, which routes traffic at the application layer.

![4](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/5fa10b1f-5bec-4ef4-9998-4777708c2336)


The `aws_lb_listener` resource specifies how to handle any HTTP requests to port 80. In this case, it forwards all requests to the load balancer to a target group. You can define multiple listeners with distinct listener rules for more complex traffic routing. 

![5](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/ca575d1e-8f54-439a-92fd-70fd354a6382)


A target group defines the collection of instances your load balancer sends traffic to. It does not manage the configuration of the targets in that group directly, but instead specifies a list of destinations the load balancer can forward requests to. 


![6](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/db2b49de-7492-40ad-aa35-208901e8a919)


While you can use an `aws_lb_target_group_attachment` resource to directly associate an EC2 instance or other target type with the target group, the dynamic nature of instances in an ASG makes that hard to maintain in configuration. Instead, this configuration links your Auto Scaling group with the target group using the `aws_autoscaling_attachment` resource. This allows AWS to automatically add and remove instances from the target group over their lifecycle. 

## Security groups

This configuration also defines two security groups: one to associate with your ASG EC2 instances, and another for the load balancer.

![7](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/153a6e3e-00b3-43c8-af99-8d3cf01899c2)

Both of these security groups allow ingress HTTP traffic on port 80 and all outbound traffic. However, the aws_security_group.terramino_instance` group restricts inbound traffic to requests coming from any source associated with the `aws_security_group.terramino_lb` security group, ensuring that only requests forwarded from your load balancer will reach your instances. 

## Apply configuration

In your terminal, initialize your configuration by running the following command:

```bash
terraform init
```

