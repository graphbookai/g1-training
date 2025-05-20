# IAM roles for AWS Batch
resource "aws_iam_role" "aws_batch_service_role" {
  name = "aws_batch_service_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Instance role for EC2 instances in the compute environment
resource "aws_iam_role" "ec2_instance_role" {
  name = "aws_batch_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "s3_access_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # For saving training results
}

resource "aws_iam_instance_profile" "batch_instance_profile" {
  name = "aws_batch_instance_profile"
  role = aws_iam_role.ec2_instance_role.name
}

# AWS Batch compute environment
resource "aws_batch_compute_environment" "g1_training" {
  compute_environment_name = "g1-training-compute-env"

  compute_resources {
    max_vcpus = var.max_vcpus
    security_group_ids = [
      aws_security_group.batch_sg.id
    ]
    subnets = [
      aws_default_subnet.default_az1.id
    ]
    type                = "EC2"
    allocation_strategy = "BEST_FIT_PROGRESSIVE"
    instance_role       = aws_iam_instance_profile.batch_instance_profile.arn
    instance_type       = var.instance_types
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = var.compute_environment_type
  depends_on   = [aws_iam_role_policy_attachment.batch_service_role_policy]
}

# Default subnet for AWS Batch
resource "aws_default_subnet" "default_az1" {
  availability_zone = "${var.aws_region}a"
}

# Security group for AWS Batch
resource "aws_security_group" "batch_sg" {
  name        = "aws_batch_compute_environment_security_group"
  description = "Security group for AWS Batch compute environment"
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Job queue that jobs can be submitted to
resource "aws_batch_job_queue" "g1_training" {
  name                 = "g1-training-job-queue"
  state                = "ENABLED"
  priority             = var.job_queue_priority
  compute_environments = [aws_batch_compute_environment.g1_training.arn]
}

# Job definition
resource "aws_batch_job_definition" "g1_training" {
  name = var.job_name
  type = "container"

  container_properties = jsonencode({
    image      = local.ecr_image_tag
    vcpus      = var.job_vcpus
    memory     = var.job_memory
    command    = ["python", "train.py"] 
    environment = [
      {
        name  = "NVIDIA_VISIBLE_DEVICES"
        value = "all"
      },
      {
        name  = "NVIDIA_DRIVER_CAPABILITIES"
        value = "compute,utility"
      }
    ]
    resourceRequirements = [
      {
        type  = "GPU"
        value = "1"
      }
    ]
    linuxParameters = {
      devices = [
        {
          hostPath      = "/dev/nvidia0"
          containerPath = "/dev/nvidia0"
          permissions   = ["read", "write"]
        }
      ]
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/job"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "g1-training"
      }
    }
  })
}

# Job submission
resource "null_resource" "submit_job" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws batch submit-job \
        --job-name ${var.job_name}-${formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())} \
        --job-queue ${aws_batch_job_queue.g1_training.name} \
        --job-definition ${aws_batch_job_definition.g1_training.name} \
        --container-overrides '{"command": ["python", "train.py", "${join("\", \"", var.command_args)}"]}'
    EOT
  }

  depends_on = [
    aws_batch_job_definition.g1_training,
    aws_batch_job_queue.g1_training
  ]
}