#!/bin/bash
set -e

# -------------------------------
# 0. Add swap (Jenkins needs it on t3.micro)
# -------------------------------
dd if=/dev/zero of=/swapfile bs=128M count=16
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# -------------------------------
# 1. SSM Agent (for Session Manager)
# -------------------------------
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# -------------------------------
# 2. Install Jenkins
# -------------------------------
dnf install -y java-17-amazon-corretto

wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

dnf install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# -------------------------------
# 3. Install Docker
# -------------------------------
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins

# -------------------------------
# 4. Restart Jenkins (apply docker group)
# -------------------------------
systemctl restart jenkins