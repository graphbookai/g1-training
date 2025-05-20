terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

#   Consider storing state remotely for team collaboration
  backend "s3" {
    bucket = "rsamf-g1-training-terraform-state"
    key    = "github-iam/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# GitHub OIDC Provider for secure authentication
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"] # GitHub OIDC thumbprints
}

# IAM role that GitHub Actions will assume
resource "aws_iam_role" "github_actions" {
  name = var.github_actions_role_name
  
  # Trust relationship to allow GitHub Actions to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  # Add a tag for easier identification
  tags = {
    Name        = "GitHub Actions Role for G1 Training"
    Environment = var.environment
    Project     = "G1 Robot Training"
  }
}

# ECR permissions
resource "aws_iam_policy" "ecr_permissions" {
  name        = "github-actions-ecr-policy"
  description = "Policy for GitHub Actions to interact with ECR"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:CreateRepository",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:PutLifecyclePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Batch permissions
resource "aws_iam_policy" "batch_permissions" {
  name        = "github-actions-batch-policy"
  description = "Policy for GitHub Actions to interact with AWS Batch"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "batch:DescribeJobDefinitions",
          "batch:DescribeJobQueues",
          "batch:DescribeComputeEnvironments",
          "batch:RegisterJobDefinition",
          "batch:CreateJobQueue",
          "batch:CreateComputeEnvironment",
          "batch:UpdateComputeEnvironment",
          "batch:UpdateJobQueue",
          "batch:SubmitJob"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM permissions for creating and managing roles
resource "aws_iam_policy" "iam_permissions" {
  name        = "github-actions-iam-policy"
  description = "Policy for GitHub Actions to manage IAM roles for Batch"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:GetInstanceProfile"
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:role/aws_batch_*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetInstanceProfile"
        ]
        Resource = "arn:aws:iam::${var.aws_account_id}:instance-profile/aws_batch_*"
      }
    ]
  })
}

# EC2 permissions for managing batch compute environment
resource "aws_iam_policy" "ec2_permissions" {
  name        = "github-actions-ec2-policy"
  description = "Policy for GitHub Actions to manage EC2 resources for Batch"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_permissions.arn
}

resource "aws_iam_role_policy_attachment" "attach_batch_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.batch_permissions.arn
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.iam_permissions.arn
}

resource "aws_iam_role_policy_attachment" "attach_ec2_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ec2_permissions.arn
}

# CloudWatch Logs permissions for AWS Batch job logs
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_logs_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}