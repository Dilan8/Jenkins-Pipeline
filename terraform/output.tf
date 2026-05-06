output "jenkins_public_ip" {
  description = "Jenkins permanent IP — never changes"
  value       = aws_eip.jenkins.public_ip
}

output "ecr_repository_url" {
  description = "Use this in your Jenkinsfile for docker push"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "Use this in Jenkins for aws ecs update-service"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Use this in Jenkins for aws ecs update-service"
  value       = aws_ecs_service.app.name
}

output "alb_dns_name" {
  description = "Open your React app at this URL"
  value       = "http://${aws_lb.main.dns_name}"
}