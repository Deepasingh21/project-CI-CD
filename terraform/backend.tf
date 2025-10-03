terraform {
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket         = "my-terraform-state-prod"   # change if needed
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
