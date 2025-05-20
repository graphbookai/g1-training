terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # You can uncomment this block to configure remote state storage in S3 if needed
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "g1-training/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = var.aws_region
}

# Create a local for the image tag
locals {
  ecr_image_tag = "${var.ecr_repository_url}:${var.image_tag}"
}