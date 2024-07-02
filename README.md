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

In your code editor, open the `main.tf` file to review the configuration in this repository.

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
  region                   = "us-east-1"
  shared_config_files      = ["/Path/to/.aws/config"]
  shared_credentials_files = ["/Path/to/.aws/credentials"]
  profile                  = "PROFILE"
}
```
</details>

Here's a breakdown of what the code does:

* `terraform` specifies the required provider and its version for Terraform to work with AWS resources.

* `hashicorp/aws` is the source for the AWS provider, which is an official provider maintained by HashiCorp.

* `version = "~> 5.0"` specifies that the AWS provider version should be within the 5.x range, allowing for minor updates but not major version changes.

* `provider "aws"` configures the AWS provider itself.

* `region = "us-east-1"` sets the AWS region to "us-east-1", which is the Northern Virginia region.

Terraform to use the AWS provider (a plugin that allows Terraform to interact with AWS resources) and sets the region to Northern Virginia. This configuration is necessary for Terraform to manage AWS resources, such as EC2 instances, S3 buckets, or Auto Scaling groups, within the specified region.

It's important to note that while this code sets the default region, Terraform can still manage resources across multiple regions by specifying the region within individual resource blocks.

Overall, this code serves as the initial setup for using Terraform to provision and manage AWS resources, ensuring that Terraform has the necessary provider and region configuration to interact with the AWS API.

