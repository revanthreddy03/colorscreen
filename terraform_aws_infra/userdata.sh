#!/bin/bash
sudo yum upgrade
sudo yum install git -y
sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user