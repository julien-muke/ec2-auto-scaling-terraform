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

## Apply configuration

In your terminal, initialize your configuration by running the following command:

```bash
terraform init
```

![8](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/b25cb8d0-4bab-420e-8cdf-00a005265baa)


## Review configuration

## 1. Initial setup for using Terraform

In your code editor, open the `main.tf` file to review the configuration.

<details>
<summary><code>main.tf</code></summary>

```bash
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
```
</details>


Terraform to use the AWS provider (a plugin that allows Terraform to interact with AWS resources) and sets the region to Northern Virginia. This configuration is necessary for Terraform to manage AWS resources, such as EC2 instances, S3 buckets, or Auto Scaling groups, within the specified region.

It's important to note that while this code sets the default region, Terraform can still manage resources across multiple regions by specifying the region within individual resource blocks.

Overall, this code serves as the initial setup for using Terraform to provision and manage AWS resources, ensuring that Terraform has the necessary provider and region configuration to interact with the AWS API.

## 2. Define resources in Terraform for creating a VPC and subnets on AWS.

In your code editor, open the `vpc-with-subnets.ft` file to review the configuration.

<details>
<summary><code>vpc-with-subnets.ft</code></summary>

```bash
# VPC
resource "aws_vpc" "jm_main" {
  cidr_block = "10.0.0.0/23" # 512 IPs 
  tags = {
    Name = "jm-vpc"
  }
}

# Creating 1st public subnet 
resource "aws_subnet" "jm_subnet_1a" {
  vpc_id                  = aws_vpc.jm_main.id
  cidr_block              = "10.0.0.0/27" #32 IPs
  map_public_ip_on_launch = true          # public subnet
  availability_zone       = "us-east-1a"
}

# Creating 2nd public subnet 
resource "aws_subnet" "jm_subnet_1b" {
  vpc_id                  = aws_vpc.jm_main.id
  cidr_block              = "10.0.0.32/27" #32 IPs
  map_public_ip_on_launch = true           # public subnet
  availability_zone       = "us-east-1b"
}

# Creating 1st private subnet 
resource "aws_subnet" "jm_subnet_2" {
  vpc_id                  = aws_vpc.jm_main.id
  cidr_block              = "10.0.1.0/27" #32 IPs
  map_public_ip_on_launch = false         # private subnet
  availability_zone       = "us-east-1b"
}
```
</details>

This code creates a VPC with two public subnets (one in each of the `us-east-1a` and `us-east-1b` Availability Zones) and one private subnet in the `us-east-1b` Availability Zone. This setup is commonly used for hosting web applications, where the public subnets are used for internet-facing resources (e.g., load balancers, web servers), and the private subnet is used for resources that should not be directly accessible from the internet (e.g., databases, internal services).

## 3. Creating an Internet Gateway and configuring routing tables

This step is to allow internet access for the public subnets in the VPC.

In your code editor, open the `gateways-public` file to review the configuration.


<details>
<summary><code>main.tf</code></summary>

```bash
# Internet Gateway
resource "aws_internet_gateway" "jm_gw" {
  vpc_id = aws_vpc.jm_main.id
}

# route table for public subnet - connecting to Internet gateway
resource "aws_route_table" "jm_rt_public" {
  vpc_id = aws_vpc.jm_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jm_gw.id
  }
}

# associate the route table with public subnet 1
resource "aws_route_table_association" "jm_rta1" {
  subnet_id      = aws_subnet.jm_subnet_1a.id
  route_table_id = aws_route_table.jm_rt_public.id
}
# associate the route table with public subnet 2
resource "aws_route_table_association" "jm_rta2" {
  subnet_id      = aws_subnet.jm_subnet_1b.id
  route_table_id = aws_route_table.jm_rt_public.id
}
```
</details>

By creating an Internet Gateway and associating it with a route table that has a route to the internet (0.0.0.0/0), instances launched in the public subnets `jm_subnet_1a` and  `jm_subnet_1b` will have internet access. This is a common setup for hosting web applications, where the public subnets contain internet-facing resources like load balancers and web servers.

The private subnet `jm_subnet_2` is not associated with this route table, so instances launched in that subnet will not have direct internet access. This is often desirable for resources like databases or internal services that should not be directly accessible from the internet.