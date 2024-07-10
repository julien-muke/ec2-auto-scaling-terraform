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

You can create a new file for each configuration or continue in the same `main.ft` file. (Separating resources into different files makes it easier to understand and maintain the infrastructure).

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

In your code editor, open the `gateways-public.tf` file to review the configuration.


<details>
<summary><code>gateways-public.tf</code></summary>

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

## 4. Create Gateway for Private Subnet

This code snippet is used to configure networking resources in an AWS environment using Terraform.

In your code editor, open the `gateways-private.tf` file to review the configuration.

<details>
<summary><code>gateways-private.tf</code></summary>

```bash
# Elastic IP for NAT gateway
resource "aws_eip" "jm_eip" {
  depends_on = [aws_internet_gateway.jm_gw]
  domain = "vpc"
  tags = {
    Name = "jm_EIP_for_NAT"
  }
}

# NAT gateway for private subnets 
# (for the private subnet to access internet - eg. ec2 instances downloading softwares from internet)
resource "aws_nat_gateway" "jm_nat_for_private_subnet" {
  allocation_id = aws_eip.jm_eip.id
  subnet_id     = aws_subnet.jm_subnet_1a.id # nat should be in public subnet

  tags = {
    Name = "jm NAT for private subnet"
  }

  depends_on = [aws_internet_gateway.jm_gw]
}

# route table - connecting to NAT
resource "aws_route_table" "jm_rt_private" {
  vpc_id = aws_vpc.jm_main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.jm_nat_for_private_subnet.id
  }
}

# associate the route table with private subnet
resource "aws_route_table_association" "jm_rta3" {
  subnet_id      = aws_subnet.jm_subnet_2.id
  route_table_id = aws_route_table.jm_rt_private.id
}
```
</details>

This code sets up a NAT Gateway with an Elastic IP address in a public subnet. It then creates a route table for private subnets that routes all internet-bound traffic to the NAT Gateway. Finally, it associates this route table with a private subnet, enabling resources in that subnet to access the internet while remaining private and inaccessible from the internet.

This setup is commonly used in AWS to provide internet access to resources that need to remain isolated in private subnets, such as databases or internal applications, while still allowing them to download updates or access external services.

## 5. Configuring the Load Balancer

This code snippet is used to configure an Application Load Balancer (ALB) and a Target Group in AWS environment using Terraform.

In your code editor, open the `lb-with-targetGroup.tf` file to review the configuration.

<details>
<summary><code>lb-with-targetGroup.tf</code></summary>

```bash
resource "aws_lb" "jm_lb" {
  name               = "jm-lb-asg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jm_sg_for_elb.id]
  subnets            = [aws_subnet.jm_subnet_1a.id, aws_subnet.jm_subnet_1b.id]
  depends_on         = [aws_internet_gateway.jm_gw]
}

resource "aws_lb_target_group" "jm_alb_tg" {
  name     = "jm-tf-lb-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.jm_main.id
}

resource "aws_lb_listener" "jm_front_end" {
  load_balancer_arn = aws_lb.jm_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jm_alb_tg.arn
  }
}
```
</details>

This code sets up an Application Load Balancer that acts as a single point of entry for incoming traffic. It also creates a Target Group, which is a logical group of resources (e.g: EC2 instances) that will receive the traffic forwarded by the Load Balancer. The Listener is configured to forward incoming HTTP traffic on port 80 to the Target Group.

This setup is commonly used in AWS to distribute incoming traffic across multiple resources (e.g: EC2 instances) for better availability, fault tolerance, and scalability. The Load Balancer acts as a single point of entry, while the Target Group manages the registered targets that will handle the actual traffic.


## 6. Creating the Auto Scaling Group

This code snippet is used to define resources in Terraform for creating an Auto Scaling Group (ASG) and a Launch Template in AWS.

In your code editor, open the `ec2-with-asg.tf` file to review the configuration.

<details>
<summary><code>ec2-with-asg.tf</code></summary>

```bash
# ASG with Launch template
resource "aws_launch_template" "jm_ec2_launch_templ" {
  name_prefix   = "sh_ec2_launch_templ"
  image_id      = "ami-06c68f701d8090592" # To note: AMI is specific for each region
  instance_type = "t2.micro"
  user_data     = filebase64("user_data.sh")

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.jm_subnet_2.id
    security_groups             = [aws_security_group.jm_sg_for_ec2.id]
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "jm-instance" # Name for the EC2 instances
    }
  }
}

resource "aws_autoscaling_group" "jm_asg" {
  # no of instances
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  # Connect to the target group
  target_group_arns = [aws_lb_target_group.jm_alb_tg.arn]

  vpc_zone_identifier = [ # Creating EC2 instances in private subnet
    aws_subnet.jm_subnet_2.id
  ]

  launch_template {
    id      = aws_launch_template.jm_ec2_launch_templ.id
    version = "$Latest"
  }
}
```
</details>


This code sets up an Auto Scaling Group that will automatically maintain a single EC2 instance with a specific configuration (defined by the Launch Template). The instance will be launched in a private subnet, associated with a security group, and connected to a load balancer target group.

The Launch Template acts as a blueprint for the EC2 instances, specifying details like the Amazon Machine Image, instance type, network settings, and user data script to run during launch. The Auto Scaling Group ensures that there is always one instance running with the specified configuration, automatically replacing instances if they become unhealthy or are terminated.

## 7. User data file to run Web server

This script updates the system packages, installs the Apache HTTP Server, starts and enables the Apache service, and creates a simple "Hello World" HTML page that displays the system's hostname. This script is likely intended to set up a basic Apache web server on the system it is executed on.


<details>
<summary><code>user_data.sh</code></summary>

```bash
#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
```
</details>

## 8. Security access rules for EC2 and Load Balancer

The provided code snippet defines two security groups in AWS using Terraform.

In your code editor, open the `sg.tf` file to review the configuration.

<details>
<summary><code>sg.tf</code></summary>

```bash
resource "aws_security_group" "jm_sg_for_elb" {
  name   = "jm-sg_for_elb"
  vpc_id = aws_vpc.jm_main.id
  
  ingress {
    description      = "Allow http request from anywhere"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "Allow https request from anywhere"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "jm_sg_for_ec2" {
  name   = "jm-sg_for_ec2"
  vpc_id = aws_vpc.jm_main.id

  ingress {
    description     = "Allow http request from Load Balancer"
    protocol        = "tcp"
    from_port       = 80 # range of
    to_port         = 80 # port numbers
    security_groups = [aws_security_group.jm_sg_for_elb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
</details>

This code defines two security groups: one for the Elastic Load Balancer (ELB) that allows incoming HTTP and HTTPS traffic from anywhere, and another for the EC2 instances that only allows incoming HTTP traffic from the ELB security group. This setup is commonly used in web applications where the ELB distributes traffic to the EC2 instances, and the instances are not directly accessible from the internet.

## 9. Apply configuration

Let’s look at the terraform commands that we would be needing every time we deploy any changes.

* The terraform fmt command is used to rewrite Terraform configuration files to a canonical format and style.

```bash
terraform fmt
```

* The validate command in Terraform is used to verify the correctness of Terraform configuration files.

```bash
terraform validate
```

* The terraform plan command creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.

```bash
terraform plan
```

* The terraform apply command executes the actions proposed in a Terraform plan to create, update, or destroy infrastructure.

```bash
terraform apply
```

Now, apply the configuration to create the VPC and networking resources, Auto Scaling group, launch configuration, load balancer, and target group. Respond `yes` to the prompt to confirm the operation.

## Now, let's check if our resources has been deployed to AWS Cloud.

* Go to AWS Console and [sign in](https://console.aws.amazon.com/).
* In the navigation pane, choose EC2 instance.

![b](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/f01d1f1f-6b23-4eb9-95ac-c1c2d659fcfd)

* In the navigation pane, choose VPC.

![h](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/6c9c7f8c-aa48-4505-994d-f18e6b515c48)


* In the navigation pane, choose subnet.

![e](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/60e1e6be-b96d-4072-b8e4-96771894ab95)

* In the navigation pane, choose security group.

![i](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/1cb233a6-cfc3-4f05-928b-50bd563aed92)

* In the navigation pane, choose  Load Balancer.
* Under EC2 service select the load balancer that we created and copy the DNS name.

![f](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/b49b38a0-73fa-47c5-804b-6ae1fd5acbea)

* Open your browser and paste the URL

![g](https://github.com/julien-muke/ec2-auto-scaling-terraform/assets/110755734/ba5f62f7-cc0d-4c6b-b256-f5e7e031dfbd)


## Add scaling policy

This configuration sets up a scaling policy that will scale out the Auto Scaling group by adding one instance when the average CPU utilization across the group exceeds 80%, and scale in by removing one instance when the average CPU utilization drops below 20%. The CloudWatch alarms monitor the CPU utilization metric and trigger the respective scaling policies when the thresholds are breached.

Note that you may need to adjust the thresholds, evaluation periods, and other settings based on your specific requirements and workload patterns.

Open your `autoscaling_policy_cloudwatch.tf` file and paste in the following configuration for an automated scaling policy and Cloud Watch metric alarm.

<details>
<summary><code>autoscaling_policy_cloudwatch.tf</code></summary>

```bash
# Step Scaling Policy for Scale Out
resource "aws_autoscaling_policy" "jm_asg_scale_out_policy" {
  name                      = "jm-asg-scale-out-policy"
  autoscaling_group_name    = aws_autoscaling_group.jm_asg.name
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  estimated_instance_warmup = 300 # 5 minutes

  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment          = 1
  }
}

# CloudWatch Metric Alarm for Scale Out
resource "aws_cloudwatch_metric_alarm" "jm_asg_scale_out_alarm" {
  alarm_name          = "jm-asg-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120" # 2 minutes
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jm_asg.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale out"
  alarm_actions     = [aws_autoscaling_policy.jm_asg_scale_out_policy.arn]
}

# Step Scaling Policy for Scale In
resource "aws_autoscaling_policy" "jm_asg_scale_in_policy" {
  name                      = "jm-asg-scale-in-policy"
  autoscaling_group_name    = aws_autoscaling_group.jm_asg.name
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  estimated_instance_warmup = 300 # 5 minutes

  step_adjustment {
    metric_interval_upper_bound = 0
    scaling_adjustment          = -1
  }
}

# CloudWatch Metric Alarm for Scale In
resource "aws_cloudwatch_metric_alarm" "jm_asg_scale_in_alarm" {
  alarm_name          = "jm-asg-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120" # 2 minutes
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jm_asg.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale in"
  alarm_actions     = [aws_autoscaling_policy.jm_asg_scale_in_policy.arn]
}

```
</details>

Apply the configuration to create the metric alarm and scaling policy. Respond `yes` to the prompt to confirm the operation.

## 💡 Conclusion

Deploying an AWS Auto Scaling Group with Terraform streamlines the management and scalability of your cloud infrastructure. By utilizing Terraform’s declarative configuration, you can automate the creation, modification, and scaling of your Auto Scaling Group, ensuring your application can dynamically adjust to varying workloads. 

This approach not only enhances resource efficiency but also simplifies the infrastructure as code (IaC) practice, promoting consistency and repeatability in your deployments. Ultimately, combining Terraform with AWS Auto Scaling empowers your organization to maintain high availability, optimize costs, and achieve greater agility in your cloud operations.

## Destroy configuration

Now that you have completed this tutorial, destroy the AWS resources you provisioned to avoid incurring unnecessary costs. Respond `yes` to the prompt to confirm the operation. 

```bash
terraform destroy
```