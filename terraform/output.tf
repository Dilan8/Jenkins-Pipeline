output "jenkins_public_ip" {
  description = "Open Jenkins at this IP on port 8080"
  value       = aws_instance.jenkins.public_ip
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