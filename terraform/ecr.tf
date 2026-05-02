# ECR repository — stores your Docker images
resource "aws_ecr_repository" "app" {
  name                 = "cicd-react-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "cicd-react-app" }
}

# Lifecycle policy — keeps only last 10 images, deletes old ones
# This saves storage costs automatically
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images only"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}