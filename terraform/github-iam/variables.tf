variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "AWS account ID where resources will be created"
  type        = string
}

variable "github_actions_role_name" {
  description = "Name of the IAM role that GitHub Actions will assume"
  type        = string
  default     = "github-actions-g1-training-role"
}

variable "github_org" {
  description = "GitHub organization or username that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "development"
}