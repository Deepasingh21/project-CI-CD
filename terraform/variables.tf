variable "aws_region" { default = "us-east-1" }
variable "cluster_name" { default = "project-ci-cd-eks" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnets" { default = ["10.0.1.0/24","10.0.2.0/24"] }
variable "private_subnets" { default = ["10.0.11.0/24","10.0.12.0/24"] }
variable "node_instance_type" { default = "t3.medium" }
variable "node_desired_capacity" { default = 2 }
variable "ecr_repo_name" { default = "my-erc-repo-01" }
