variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "g1-training"
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "compute_environment_type" {
  description = "Type of compute environment for AWS Batch"
  type        = string
  default     = "MANAGED"
}

variable "instance_types" {
  description = "EC2 instance types for AWS Batch compute environment"
  type        = list(string)
  default     = ["p3.2xlarge", "g4dn.xlarge"]
}

variable "max_vcpus" {
  description = "Maximum vCPUs for the compute environment"
  type        = number
  default     = 16
}

variable "job_queue_priority" {
  description = "Priority of the job queue"
  type        = number
  default     = 1
}

variable "job_name" {
  description = "Name of the training job"
  type        = string
  default     = "g1-training-job"
}

variable "job_vcpus" {
  description = "Number of vCPUs for the job"
  type        = number
  default     = 8
}

variable "job_memory" {
  description = "Memory (in MiB) for the job"
  type        = number
  default     = 30000
}

variable "command_args" {
  description = "Command line arguments for the training job"
  type        = list(string)
  default     = ["--task", "G1-Walking-v0", "--num_envs", "16", "--max_iterations", "1000"]
}