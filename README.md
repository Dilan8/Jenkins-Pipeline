# 🚀 Automated CI/CD Pipeline — AWS

A fully automated, production-grade CI/CD pipeline built from scratch on AWS. A single `git push` triggers the entire flow — build, containerise, push to registry, and deploy — with zero manual steps.

**Live URL:** http://cicd-alb-1557082758.ap-southeast-2.elb.amazonaws.com

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Pipeline Flow](#pipeline-flow)
- [Infrastructure](#infrastructure)
- [Monitoring](#monitoring)
- [Technologies](#technologies)
- [How to Deploy](#how-to-deploy)
- [Security](#security)
- [Author](#author)

---

## Overview

This project demonstrates a production-equivalent CI/CD pipeline using AWS native services and infrastructure as code. The entire AWS infrastructure is defined in Terraform and can be destroyed and recreated with two commands.

| Before | After |
|--------|-------|
| Manual SSH into server | Fully automated |
| Manual docker build | Jenkins builds automatically |
| Manual docker push | Image pushed to ECR automatically |
| Manual container restart | ECS deploys automatically |
| IP changes on every restart | Stable ALB DNS name |
| No scaling | Auto scales up to 5 tasks |
| No visibility | Live Grafana dashboard |

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
   Amazon ECR          Amazon CloudWatch
   (Docker images)     (Metrics + Logs)
      │                      │
      ▼                      ▼
   Amazon S3           Grafana Cloud
   (Terraform state)   (Live Dashboard)
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
    │
    ├── Stage 2: docker build (multi-stage Dockerfile)
    │
    ├── Stage 3: docker push → ECR (via IAM role, no credentials stored)
    │
    └── Stage 4: aws ecs update-service → app is live ✅
```

---

## Infrastructure

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

---

## Monitoring

### Grafana Dashboard — CI/CD Project Overview

Live monitoring dashboard connected to AWS CloudWatch showing real-time metrics.

| Panel | Metric | What it shows |
|-------|--------|---------------|
| ECS CPU Utilization % | `AWS/ECS CPUUtilization` | Container CPU — spike visible on every deployment |
| ECS Memory Usage % | `AWS/ECS MemoryUtilization` | Container memory consumption over time |
| ALB Request Count | `AWS/ApplicationELB RequestCount` | Requests hitting the load balancer per minute |
| ALB Response Time | `AWS/ApplicationELB TargetResponseTime` | App response speed in seconds (0.002-0.004s) |

### How metrics flow

```
ECS Fargate container
  using CPU and Memory
        │
        │ automatically every 1 minute
        │ no agent or config needed
        ▼
AWS CloudWatch
  stores metrics
  retains data 15 months
        │
        │ Grafana reads via IAM user
        │ CloudWatchReadOnlyAccess
        │ CloudWatchLogsReadOnlyAccess
        ▼
Grafana Cloud Dashboard
  displays as live charts
```

### Grafana setup

```
1. Created Grafana Cloud account (free tier)
2. Created IAM user: grafana-cloudwatch-reader
   Policies: CloudWatchReadOnlyAccess + CloudWatchLogsReadOnlyAccess
3. Added CloudWatch as data source (region: ap-southeast-2)
4. Built dashboard with 4 panels querying CloudWatch metrics
```

### What the metrics tell you

```
ECS CPU spike     → deployment happened (Jenkins pushed new image)
ECS Memory steady → app is healthy, no memory leak
ALB Request Count → real user traffic hitting the app
ALB Response Time → app responding in under 5ms
```

---

## Technologies

| Category | Tools |
|----------|-------|
| CI/CD | Jenkins, GitHub webhooks, GitHub Actions |
| Containers | Docker (multi-stage), Amazon ECR |
| Runtime | AWS ECS Fargate, ALB, Auto Scaling |
| Infrastructure | Terraform, AWS VPC, EC2, IAM, S3, Elastic IP |
| Monitoring | Grafana Cloud, AWS CloudWatch metrics and logs |
| Application | React, Vite, Node.js |

---

## How to Deploy

### Step 1 — Create S3 backend bucket

```bash
aws s3api create-bucket \
  --bucket terraform-state-cicd-YOUR_ACCOUNT_ID \
  --region ap-southeast-2 \
  --create-bucket-configuration LocationConstraint=ap-southeast-2
```

### Step 2 — Configure variables

```bash
# terraform/terraform.tfvars
region        = "ap-southeast-2"
instance_type = "t3.micro"
your_ip       = "YOUR_IP/32"
key_pair_name = "YOUR_KEY_PAIR"
```

### Step 3 — Deploy

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 4 — Configure Grafana monitoring

```
1. Create free account at grafana.com
2. Create IAM user: grafana-cloudwatch-reader
   Attach: CloudWatchReadOnlyAccess + CloudWatchLogsReadOnlyAccess
3. Generate access keys
4. Add CloudWatch data source in Grafana (region: ap-southeast-2)
5. Build dashboard panels for ECS and ALB metrics
```

### Destroy everything

```bash
terraform destroy
```

---

## Security

| Layer | Protection |
|-------|-----------|
| Network | VPC isolation, ECS not exposed to internet directly |
| Identity | IAM roles with least privilege, no access keys in code |
| Container | ECR private registry, vulnerability scanning on push |
| Application | ECS only reachable through ALB |
| State | Terraform state encrypted in S3 |
| DDoS | AWS Shield Standard (free, automatic on ALB) |
| Monitoring | Grafana read-only IAM user, cannot modify AWS resources |

---

## Author

**Dilan Vasantharaj** — Site Reliability Engineer | DevOps | AWS

- 📧 vasandarajdilan64@gmail.com
- 💻 [github.com/Dilan8](https://github.com/Dilan8)
- 🔗 [linkedin.com/in/dilan-vasandaraj](https://linkedin.com/in/dilan-vasandaraj)
- 📍 Melbourne, Australia

---

*Destroy and recreate everything with two commands: `terraform init && terraform apply`*