# ECS Cluster — just a logical grouping, no servers with Fargate
resource "aws_ecs_cluster" "main" {
  name = "cicd-cluster"
  tags = { Name = "cicd-cluster" }
}

# -------------------------------------------------------
# IAM role for ECS — so ECS can pull images from ECR
# NOTE: This is DIFFERENT from the Jenkins EC2 role
#   Jenkins EC2 role  = PUSH images to ECR
#   This role         = PULL images from ECR on task start
# -------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch log group — where your container logs go
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/cicd-react-app"
  retention_in_days = 7
}

# Task definition — the blueprint for your container
# Think of it as: what image, how much CPU/RAM, which port
resource "aws_ecs_task_definition" "app" {
  family                   = "cicd-react-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256" # 0.25 vCPU
  memory                   = "512" # MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "react-app"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = 5173
      hostPort      = 5173
      protocol      = "tcp"
    }]

    # Without this you have ZERO visibility when container crashes
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/cicd-react-app"
        awslogs-region        = "ap-southeast-2"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

# ECS Service — keeps your container alive 24/7
# If container crashes, service automatically restarts it
resource "aws_ecs_service" "app" {
  name            = "cicd-react-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  # IMPORTANT — stops Terraform fighting with Jenkins deployments
  # Jenkins updates task_definition on every deploy
  # Without this line, terraform apply would undo Jenkins's work
  lifecycle {
    ignore_changes = [task_definition]
  }
}