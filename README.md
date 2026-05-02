# Jenkins-Pipeline
"I built a fully automated CI/CD pipeline on AWS 
from scratch. The infrastructure is defined entirely 
in Terraform — VPC, subnets, security groups, EC2 
for Jenkins, ECR for Docker images, and ECS Fargate 
for serverless container hosting.

When a developer pushes code to GitHub, a webhook 
automatically triggers Jenkins. Jenkins builds the 
React application using Vite, creates a Docker image 
using a multi-stage Dockerfile, pushes it to ECR, 
and then triggers an ECS service update to deploy 
the new container.

The security is handled through IAM roles — no 
credentials are stored anywhere. Jenkins uses an 
instance role to push to ECR, and ECS uses a task 
execution role to pull images. The entire 
infrastructure can be recreated with two commands: 
terraform init and terraform apply."

# What you just built from scratch
Developer pushes code to GitHub
        ↓
GitHub webhook triggers Jenkins automatically
        ↓
Jenkins pulls code from GitHub
        ↓
npm install + npm run build (React/Vite)
        ↓
Docker builds multi-stage image
        ↓
Image pushed to Amazon ECR
        ↓
ECS Fargate pulls image from ECR
        ↓
React app live at http://54.79.74.135:5173 ✅

# Technologies you used — full lis

✅ GitHub          — source code + webhook trigger
✅ Jenkins         — CI/CD engine on EC2
✅ Docker          — containerisation
✅ Amazon ECR      — private Docker registry
✅ Amazon ECS      — serverless container hosting
✅ AWS Fargate     — no servers to manage
✅ AWS EC2         — Jenkins server
✅ AWS VPC         — private network
✅ Subnets         — public subnets across 2 AZs
✅ Internet Gateway— VPC front door
✅ Route Tables    — traffic routing
✅ Security Groups — firewall rules
✅ IAM Roles       — secure AWS permissions
✅ Terraform       — infrastructure as code
✅ S3              — remote Terraform state
✅ Node.js/npm     — React dependencies
✅ Vite            — React build tool

# What I learned 

Networking:

  ✅ IP addresses (public vs private)
  ✅ Ports and protocols
  ✅ TCP vs UDP
  ✅ SSH and key pairs
  ✅ HTTP vs HTTPS
  ✅ Security groups
  ✅ End to end request flow

Terraform:
  ✅ Providers and resources
  ✅ Variables and outputs
  ✅ State file and remote state
  ✅ Data sources
  ✅ IAM roles vs users
  ✅ Complete project structure

AWS:
  ✅ VPC, subnets, IGW, route tables
  ✅ EC2, security groups, key pairs
  ✅ ECR, ECS, Fargate
  ✅ IAM roles and policies
  ✅ S3 backend


