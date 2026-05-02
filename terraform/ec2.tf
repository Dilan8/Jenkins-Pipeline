# IAM Role for Jenkins EC2
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = { Name = "jenkins-ec2-role" }
}

# Attach ECR permission to role
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

# Attach ECS permission to role
resource "aws_iam_role_policy_attachment" "ecs_access" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# Instance profile — wrapper so EC2 can use the role
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}

# The actual EC2 instance
resource "aws_instance" "jenkins" {
  ami                    = "ami-0de129bfeba4c4f09"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = file("userdata.sh")

  tags = { Name = "jenkins-server" }
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}