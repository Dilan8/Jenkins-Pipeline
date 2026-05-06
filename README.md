# 🚀 Automated CI/CD Pipeline — AWS

A fully automated, production-grade CI/CD pipeline built from scratch on AWS. A single `git push` triggers the entire flow — build, containerise, push to registry, and deploy — with zero manual steps.

**Live URL:** http://cicd-alb-1557082758.ap-southeast-2.elb.amazonaws.com

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Flow](#pipeline-flow)
- [Infrastructure](#infrastructure)
- [Technologies](#technologies)
- [Project Structure](#project-structure)
- [How to Deploy](#how-to-deploy)
- [Security](#security)
- [Author](#author)

---

## Overview

This project demonstrates a production-equivalent CI/CD pipeline using AWS native services and infrastructure as code. The entire AWS infrastructure is defined in Terraform and can be destroyed and recreated with two commands.

**What problem does this solve?**

| Before | After |
|--------|-------|
| Manual SSH into server | Fully automated |
| Manual docker build | Jenkins builds automatically |
| Manual docker push | Image pushed to ECR automatically |
| Manual container restart | ECS deploys automatically |
| IP changes on every restart | Stable ALB DNS name |
| No scaling | Auto scales up to 5 tasks |

---

## Architecture

```
Developer Laptop
      │
      │ git push
      ▼
   GitHub
      │
      │ webhook (port 8080)
      ▼
┌─────────────────────────────────────┐
│           AWS VPC 10.0.0.0/16       │
│                                     │
│  ┌─────────────┐  ┌──────────────┐  │
│  │ Public      │  │ Public       │  │
│  │ Subnet A    │  │ Subnet B     │  │
│  │ 10.0.1.0/24 │  │ 10.0.2.0/24  │  │
│  │             │  │              │  │
│  │ EC2 Jenkins │  │ ECS Fargate  │  │
│  │ port 8080   │  │ port 5173    │  │
│  └─────────────┘  └──────────────┘  │
│                                     │
│  ALB (port 80) → ECS (port 5173)    │
│  Auto Scaling  min:1 max:5          │
└─────────────────────────────────────┘
      │
      ▼
   Amazon ECR
   (Docker images)
      │
      ▼
   Amazon S3
   (Terraform state)
```

---

## Pipeline Flow

```
git push
    │
    ▼
GitHub webhook fires → Jenkins EC2
    │
    ├── Stage 1: npm install
    │           installs React dependencies
    │
    ├── Stage 2: docker build
    │           multi-stage Dockerfile
    │           Stage 1: build React app (Vite)
    │           Stage 2: serve with lightweight server
    │
    ├── Stage 3: docker push → ECR
    │           authenticated via IAM role
    │           no credentials stored anywhere
    │
    └── Stage 4: aws ecs update-service
                ECS pulls new image from ECR
                starts new task
                old task stopped
                app is live ✅
```

---

## Infrastructure

All infrastructure is defined as code in Terraform:

| File | What it creates |
|------|----------------|
| `vpc.tf` | VPC, 2 public subnets (AZ-2a + AZ-2b), Internet Gateway, route tables |
| `security.tf` | Jenkins SG (ports 22, 8080), ECS SG (port 5173 from ALB only), ALB SG |
| `ec2.tf` | Jenkins EC2 (t3.micro), IAM role, Elastic IP, user data bootstrap |
| `ecr.tf` | Private Docker registry, lifecycle policy (keep last 10 images) |
| `ecs.tf` | ECS cluster, Fargate task definition, service, CloudWatch logs |
| `alb.tf` | Application Load Balancer, target group, health checks, listener |
| `autoscaling.tf` | ECS Auto Scaling — scales on CPU 60%, min 1, max 5 tasks |
| `variables.tf` | region, instance_type, your_ip, key_pair_name |
| `outputs.tf` | Jenkins IP, ECR URL, ALB DNS name |
| `backend.tf` | S3 remote state with encryption |

### Networking Design

```
Internet → Internet Gateway → ALB (port 80)
                           → ALB → ECS task (port 5173)
                           
Jenkins EC2:
  Inbound:  port 22 (SSH, your IP only)
            port 8080 (Jenkins UI + webhooks)
  Outbound: all (ECR push, npm install, git pull)

ECS task:
  Inbound:  port 5173 from ALB SG only
            (cannot be reached directly from internet)
  Outbound: all (ECR image pull, CloudWatch logs)
```

### IAM Roles — No Credentials Stored Anywhere

| Role | Used By | Permissions |
|------|---------|-------------|
| `jenkins-ec2-role` | Jenkins EC2 | ECR push, ECS deploy, SSM |
| `ecs-task-execution-role` | ECS Fargate | ECR pull, CloudWatch write |

---

## Technologies

### CI/CD & Containerisation
- **Jenkins** — CI/CD engine, runs on EC2, triggered by GitHub webhook
- **Docker** — multi-stage builds, final image contains only production files
- **Amazon ECR** — private Docker registry, scan on push enabled
- **GitHub Actions** — portfolio deployment to GitHub Pages

### AWS Infrastructure
- **ECS Fargate** — serverless container runtime, no servers to manage
- **ALB** — Application Load Balancer, stable DNS, health checks, auto failover
- **EC2** — Jenkins build server (t3.micro, Amazon Linux 2023)
- **VPC** — custom network, 2 public subnets across 2 Availability Zones
- **IAM** — instance roles, no access keys stored anywhere
- **S3** — encrypted remote Terraform state
- **CloudWatch** — container logs, 7 day retention
- **Elastic IP** — permanent IP for Jenkins, survives EC2 restarts

### Infrastructure as Code
- **Terraform** — all AWS resources defined as code
- **Remote state** — S3 backend with encryption
- **Auto Scaling** — target tracking on CPU 60%, min 1 max 5 tasks

### Application
- **React** — frontend application
- **Vite** — build tool, fast compilation
- **Node.js / npm** — runtime and package manager

---

## Project Structure

```
Jenkins-Pipeline/
├── react-app/              ← React application source
│   ├── src/
│   │   └── App.jsx
│   ├── package.json
│   └── vite.config.js
├── terraform/              ← All infrastructure as code
│   ├── vpc.tf
│   ├── security.tf
│   ├── ec2.tf
│   ├── ecr.tf
│   ├── ecs.tf
│   ├── alb.tf
│   ├── autoscaling.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── userdata.sh
├── Dockerfile              ← Multi-stage container build
├── Jenkinsfile             ← Pipeline definition
└── README.md
```

---

## How to Deploy

### Prerequisites
- AWS CLI configured
- Terraform installed (v1.0+)
- AWS account with appropriate permissions

### Step 1 — Create S3 backend bucket

```bash
aws s3api create-bucket \
  --bucket terraform-state-cicd-YOUR_ACCOUNT_ID \
  --region ap-southeast-2 \
  --create-bucket-configuration LocationConstraint=ap-southeast-2

aws s3api put-bucket-versioning \
  --bucket terraform-state-cicd-YOUR_ACCOUNT_ID \
  --versioning-configuration Status=Enabled
```

### Step 2 — Configure variables

```bash
# terraform/terraform.tfvars
region        = "ap-southeast-2"
instance_type = "t3.micro"
your_ip       = "YOUR_IP/32"
key_pair_name = "YOUR_KEY_PAIR"
```

### Step 3 — Deploy infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 4 — Configure Jenkins

```bash
# Get Jenkins URL from outputs
terraform output jenkins_public_ip

# Open in browser
http://JENKINS_IP:8080

# Get initial password
ssh -i your-key.pem ec2-user@JENKINS_IP
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 5 — Add GitHub webhook

```
GitHub repo → Settings → Webhooks → Add webhook
Payload URL: http://JENKINS_IP:8080/github-webhook/
Content type: application/json
Events: push
```

### Step 6 — Access the app

```bash
terraform output alb_dns_name
# Open the URL in browser
```

### Destroy everything

```bash
terraform destroy
```

---

## Security

| Layer | Protection |
|-------|-----------|
| Network | VPC isolation, security groups, ECS not exposed to internet |
| Identity | IAM roles with least privilege, no access keys stored |
| Container | ECR private registry, vulnerability scanning on push |
| Application | ECS only reachable through ALB |
| State | Terraform state encrypted in S3 |
| DDoS | AWS Shield Standard (free, automatic on ALB) |

**Planned improvements:**
- HTTPS with ACM certificate
- Custom domain via Route 53
- WAF rules on ALB
- Private subnets for ECS
- Secrets Manager for sensitive config

---

## Author

**Dilan Vasantharaj**
Site Reliability Engineer | DevOps | AWS

- 📧 vasandarajdilan64@gmail.com
- 💻 [github.com/Dilan8](https://github.com/Dilan8)
- 🔗 [linkedin.com/in/dilan-vasandaraj](https://linkedin.com/in/dilan-vasandaraj)
- 📍 Melbourne, Australia

---

*Infrastructure as Code — destroy and recreate everything with two commands*
```
terraform init && terraform apply
```
