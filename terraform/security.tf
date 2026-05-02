# -----------------------------
# Jenkins Security Group
# -----------------------------
resource "aws_security_group" "jenkins" {
  name        = "cicd-jenkins-sg"
  description = "Security group for Jenkins EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "cicd-jenkins-sg"
  }
}

# SSH access (port 22) - only your IP
resource "aws_security_group_rule" "jenkins_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.your_ip] # replace with your IP
  security_group_id = aws_security_group.jenkins.id
}

# Jenkins UI access (port 8080) - only your IP
resource "aws_security_group_rule" "jenkins_ui" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [var.your_ip] # replace with your IP
  security_group_id = aws_security_group.jenkins.id
}

# Allow all outbound traffic from Jenkins
resource "aws_security_group_rule" "jenkins_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # all traffic
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins.id
}

# -----------------------------
# ECS Tasks Security Group
# -----------------------------
resource "aws_security_group" "ecs_tasks" {
  name        = "cicd-ecs-tasks-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "cicd-ecs-tasks-sg"
  }
}

# Allow public access to app (port 5173)
resource "aws_security_group_rule" "ecs_app_inbound" {
  type              = "ingress"
  from_port         = 5173
  to_port           = 5173
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # public access
  security_group_id = aws_security_group.ecs_tasks.id
}

# Allow all outbound traffic from ECS
resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_tasks.id
}