# ECR repository for storing the Docker container image
resource "aws_ecr_repository" "g1_training" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable tag immutability if needed
  # image_tag_mutability = "IMMUTABLE"
}

# ECR lifecycle policy to clean up old images
resource "aws_ecr_lifecycle_policy" "g1_training_lifecycle" {
  repository = aws_ecr_repository.g1_training.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}