#!/bin/bash
set -e

# 0. Fix /tmp
systemctl stop tmp.mount || true
systemctl disable tmp.mount || true
systemctl daemon-reload
echo "tmpfs /tmp tmpfs defaults,size=4G 0 0" >> /etc/fstab
mount -o remount,size=4G tmpfs /tmp || true

# 1. Swap
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=128M count=16
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

# 2. Install all required packages
dnf install -y wget git nodejs npm

# 3. SSM Agent
dnf install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# 4. Java 21 — Jenkins now requires Java 21 minimum
dnf install -y java-21-amazon-corretto

# 5. Jenkins
wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
dnf install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# 6. Docker
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins

# 7. Restart Jenkins
systemctl restart jenkins