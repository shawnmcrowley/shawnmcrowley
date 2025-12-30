# AWS ECS Deployment Guide - Simple Container Setup

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Create ECR Repository](#step-1-create-ecr-repository)
4. [Step 2: Build and Push Docker Image](#step-2-build-and-push-docker-image)
5. [Step 3: Create ECS Cluster](#step-3-create-ecs-cluster)
6. [Step 4: Create Task Definition](#step-4-create-task-definition)
7. [Step 5: Run Your Container](#step-5-run-your-container)
8. [Step 6: Access Your Application](#step-6-access-your-application)
9. [Managing Your Container](#managing-your-container)
10. [Troubleshooting](#troubleshooting)
11. [Appendix: Production Setup](#appendix-production-setup)

## Overview

This guide walks you through deploying a single Docker container to AWS ECS using the simplest approach. The workflow is:

1. Create an ECR repository to store your Docker image
2. Build and push your Docker image to ECR
3. Create an ECS cluster (using Fargate for simplicity)
4. Define a task (blueprint for your container)
5. Run the task as a container
6. Access your running application

**Launch Type**: We'll use **AWS Fargate** which is serverless - no EC2 instances to manage.

## Prerequisites

### Required AWS Permissions

You need an AWS account with permissions to:
- Create and manage ECR repositories
- Create and manage ECS clusters, tasks, and services
- Create IAM roles
- View CloudWatch logs

### Local Requirements

- Docker installed on your local machine
- AWS CLI installed and configured (`aws configure`)
- A Dockerfile for your application

### IAM Roles Setup

Before starting, create two IAM roles that ECS will use:

#### Option A: Using AWS Console

1. Go to **IAM Console** → **Roles** → **Create role**
2. Select **AWS service** → **Elastic Container Service** → **Elastic Container Service Task**
3. Click **Next**
4. Attach policy: **AmazonECSTaskExecutionRolePolicy**
5. Name it: `ecsTaskExecutionRole`
6. Click **Create role**

Repeat for task role:
1. Create another role with same trust policy
2. Attach policies your application needs (S3, DynamoDB, etc.)
3. Name it: `ecsTaskRole`

#### Option B: Using AWS CLI

```bash
# Create trust policy file
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create execution role
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# Create task role (for your application)
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document file://trust-policy.json
```

## Step 1: Create ECR Repository

ECR (Elastic Container Registry) is where you'll store your Docker images.

### Using AWS Console

1. Go to **Amazon ECR** in AWS Console
2. Click **Create repository**
3. Select **Private**
4. Repository name: `my-application`
5. Enable **Scan on push** (optional but recommended)
6. Click **Create repository**
7. **Copy the repository URI** - you'll need this (looks like: `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-application`)

### Using AWS CLI

```bash
# Create repository
aws ecr create-repository \
  --repository-name my-application \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true

# Output will include the repository URI
```

## Step 2: Build and Push Docker Image

### Step 2.1: Build Your Docker Image Locally

```bash
# Navigate to your application directory
cd /path/to/your/app

# Build the image
docker build -t my-application:latest .

# Verify the image
docker images | grep my-application
```

### Step 2.2: Authenticate Docker with ECR

#### Using AWS Console

1. Go to **Amazon ECR** → **Repositories**
2. Click on your repository (`my-application`)
3. Click **View push commands** button
4. Copy and run the first command (authentication)

#### Using AWS CLI

```bash
# Get authentication token and login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# You should see "Login Succeeded"
```

### Step 2.3: Tag Your Image

```bash
# Replace with your actual repository URI
docker tag my-application:latest \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/my-application:latest
```

### Step 2.4: Push to ECR

```bash
# Push the image
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-application:latest
```

### Step 2.5: Verify Upload

#### Using AWS Console

1. Go to **Amazon ECR** → **Repositories** → `my-application`
2. You should see your image with tag `latest`
3. Note the **Image URI** - you'll need this

#### Using AWS CLI

```bash
aws ecr describe-images \
  --repository-name my-application \
  --region us-east-1
```

## Step 3: Create ECS Cluster

A cluster is a logical grouping of tasks or services. For a simple setup, you just need one.

### Using AWS Console

1. Go to **Amazon ECS** in AWS Console
2. Click **Clusters** in left sidebar
3. Click **Create cluster**
4. **Cluster name**: `my-cluster`
5. **Infrastructure**: Leave as **AWS Fargate (serverless)**
6. Click **Create**

### Using AWS CLI

```bash
aws ecs create-cluster \
  --cluster-name my-cluster \
  --region us-east-1
```

## Step 4: Create Task Definition

A task definition is a blueprint that describes how to run your container.

### Using AWS Console

1. Go to **Amazon ECS** → **Task Definitions**
2. Click **Create new task definition** → **Create new task definition**
3. **Task definition family name**: `my-application-task`

#### Infrastructure Requirements
4. **Launch type**: Select **AWS Fargate**
5. **Operating system/Architecture**: **Linux/X86_64**
6. **CPU**: `0.25 vCPU` (or adjust based on needs)
7. **Memory**: `0.5 GB` (or adjust based on needs)
8. **Task role**: Select `ecsTaskRole` (if your app needs AWS permissions)
9. **Task execution role**: Select `ecsTaskExecutionRole`

#### Container Details
10. **Container name**: `my-application`
11. **Image URI**: Paste your full ECR image URI
    - Example: `123456789012.dkr.ecr.us-east-1.amazonaws.com/my-application:latest`
12. **Port mappings**: 
    - **Container port**: `8080` (change to your app's port)
    - **Protocol**: `TCP`
    - **Port name**: `http` (optional)
    - **App protocol**: `HTTP` (optional)

#### Environment Variables (Optional)
13. Scroll to **Environment variables** section
14. Click **Add environment variable** for each variable
    - **Key**: `ENV_VAR_NAME`
    - **Value**: `value`

#### Logging
15. Scroll to **Logging** section
16. **Log driver**: `awslogs` (selected by default)
17. **Log group**: `/ecs/my-application` (will be created automatically)
18. Leave other logging options as default

19. Click **Create** at the bottom

### Using AWS CLI

First, create a log group:

```bash
aws logs create-log-group \
  --log-group-name /ecs/my-application \
  --region us-east-1
```

Create a file named `task-definition.json`:

```json
{
  "family": "my-application-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::123456789012:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ecsTaskRole",
  "containerDefinitions": [
    {
      "name": "my-application",
      "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-application:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENV_VAR_NAME",
          "value": "value"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-application",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

Register the task definition:

```bash
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json \
  --region us-east-1
```

## Step 5: Run Your Container

Now you'll launch a task (running instance of your container).

### Using AWS Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click **Tasks** tab
3. Click **Run new task**

#### Environment
4. **Compute options**: Select **Launch type**
5. **Launch type**: **FARGATE**
6. **Platform version**: **LATEST**

#### Deployment Configuration
7. **Task definition**: 
   - **Family**: Select `my-application-task`
   - **Revision**: Select **LATEST**
8. **Desired tasks**: `1`

#### Networking
9. **VPC**: Select your default VPC or an existing VPC
10. **Subnets**: Select at least one subnet (preferably public for testing)
11. **Security group**: 
    - Create new security group OR select existing
    - **Name**: `my-application-sg`
    - **Inbound rules**: Add rule
      - **Type**: Custom TCP
      - **Port range**: `8080` (your container port)
      - **Source**: `0.0.0.0/0` (for testing - restrict in production)
12. **Public IP**: **ENABLED** (so you can access it)

13. Click **Create**

Your task will start. Wait for status to change from **PROVISIONING** → **PENDING** → **RUNNING**.

### Using AWS CLI

First, get your VPC and subnet information:

```bash
# List VPCs
aws ec2 describe-vpcs --region us-east-1

# List subnets (use a subnet from your VPC)
aws ec2 describe-subnets --region us-east-1
```

Create a security group:

```bash
# Create security group
aws ec2 create-security-group \
  --group-name my-application-sg \
  --description "Security group for my application" \
  --vpc-id vpc-xxxxx \
  --region us-east-1

# Add inbound rule for your application port
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0 \
  --region us-east-1
```

Run the task:

```bash
aws ecs run-task \
  --cluster my-cluster \
  --task-definition my-application-task \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-xxxxx],
    securityGroups=[sg-xxxxx],
    assignPublicIp=ENABLED
  }" \
  --region us-east-1
```

## Step 6: Access Your Application

### Find Your Container's Public IP

#### Using AWS Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click **Tasks** tab
3. Click on your running task
4. In the task details, look for **Public IP** under the **Configuration** section
5. Copy the public IP address

#### Using AWS CLI

```bash
# List tasks
aws ecs list-tasks \
  --cluster my-cluster \
  --region us-east-1

# Get task details (replace TASK_ARN with actual ARN)
aws ecs describe-tasks \
  --cluster my-cluster \
  --tasks TASK_ARN \
  --region us-east-1 \
  --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' \
  --output text

# Get public IP from network interface (replace ENI_ID)
aws ec2 describe-network-interfaces \
  --network-interface-ids ENI_ID \
  --region us-east-1 \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

### Access Your Application

```bash
# Test your application (replace with your public IP and port)
curl http://PUBLIC_IP:8080

# Or open in browser
http://PUBLIC_IP:8080
```

### View Logs

#### Using AWS Console

1. Go to **CloudWatch** → **Log groups**
2. Find `/ecs/my-application`
3. Click on the log group
4. Click on the latest log stream
5. View your container logs

#### Using AWS CLI

```bash
# Tail logs in real-time
aws logs tail /ecs/my-application --follow --region us-east-1
```

## Managing Your Container

### Stop Your Container

#### Using AWS Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click **Tasks** tab
3. Select your running task (checkbox)
4. Click **Stop** button
5. Confirm

#### Using AWS CLI

```bash
# List running tasks
aws ecs list-tasks \
  --cluster my-cluster \
  --region us-east-1

# Stop the task (replace TASK_ARN)
aws ecs stop-task \
  --cluster my-cluster \
  --task TASK_ARN \
  --region us-east-1
```

### Update Your Application

When you have a new version:

1. **Build and push new image** to ECR (repeat Step 2)
2. **Update task definition** with new image or create new revision (repeat Step 4)
3. **Stop old task** (if running)
4. **Run new task** with updated task definition (repeat Step 5)

### Execute Commands in Running Container

To access your container's shell for debugging:

#### Enable ECS Exec First

**Using AWS Console:**
1. Edit your task definition
2. Scroll to **Monitoring and logging**
3. Check **Enable Execute Command**
4. Create new revision

Your task role needs SSM permissions. Add this policy to `ecsTaskRole`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
```

**Run new task with ECS Exec enabled:**

```bash
aws ecs run-task \
  --cluster my-cluster \
  --task-definition my-application-task \
  --launch-type FARGATE \
  --enable-execute-command \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-xxxxx],
    securityGroups=[sg-xxxxx],
    assignPublicIp=ENABLED
  }" \
  --region us-east-1
```

#### Connect to Container

```bash
# Get your task ARN
aws ecs list-tasks \
  --cluster my-cluster \
  --region us-east-1

# Execute interactive shell (replace TASK_ARN)
aws ecs execute-command \
  --cluster my-cluster \
  --task TASK_ARN \
  --container my-application \
  --interactive \
  --command "/bin/bash" \
  --region us-east-1
```

You'll now have a bash shell inside your container!

### View Resource Usage

#### Using AWS Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click on your running task
3. View **Metrics** tab for CPU and Memory usage

#### Using AWS CLI

```bash
# Get task metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=my-application Name=ClusterName,Value=my-cluster \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average \
  --region us-east-1
```

## Troubleshooting

### Container Won't Start

1. **Check CloudWatch logs** for error messages
2. **Verify IAM roles**:
   - Execution role can pull from ECR
   - Execution role can write to CloudWatch Logs
3. **Check task definition**:
   - Correct image URI
   - Sufficient CPU/memory allocation
   - Valid port mappings
4. **Verify security group** allows outbound internet access

### Can't Access Application

1. **Verify task is RUNNING** (not STOPPED or PENDING)
2. **Check security group**:
   - Inbound rule allows traffic on container port
   - Source IP is correct (0.0.0.0/0 for testing)
3. **Verify Public IP is assigned**
4. **Check application logs** for startup errors
5. **Verify container is listening on 0.0.0.0** not 127.0.0.1

### Task Stops Immediately

1. Check **Stopped reason** in task details
2. Common causes:
   - Application crashes (check logs)
   - Failed health checks
   - Insufficient memory
   - Port conflicts

### Can't Push to ECR

1. **Verify authentication**: Re-run the ECR login command
2. **Check IAM permissions**: User needs ECR push permissions
3. **Verify repository exists**: Check repository name spelling
4. **Check image tag format**: Must include full repository URI

## Quick Reference

```bash
# Authentication
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Build and push
docker build -t my-app .
docker tag my-app:latest ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
docker push ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/my-app:latest

# Run task
aws ecs run-task --cluster my-cluster --task-definition my-app-task --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"

# View logs
aws logs tail /ecs/my-application --follow

# Stop task
aws ecs stop-task --cluster my-cluster --task TASK_ARN

# Connect to container
aws ecs execute-command --cluster my-cluster --task TASK_ARN --container my-app --interactive --command "/bin/bash"
```

---

# Appendix: Production Setup

This section covers advanced configurations for production environments including high availability, load balancing, auto-scaling, and security hardening.

## A. ECS Service (Long-Running Applications)

For production applications that should always be running, use an ECS Service instead of running tasks directly.

### Benefits of Services

- Automatic restart if container fails
- Maintain desired number of running tasks
- Integrate with load balancers
- Rolling updates with zero downtime
- Auto-scaling capabilities

### Create Service - Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click **Services** tab → **Create**
3. **Compute options**: Launch type
4. **Launch type**: FARGATE
5. **Task definition**: Select your task definition family and revision
6. **Service name**: `my-application-service`
7. **Desired tasks**: `2` (for high availability)
8. Configure networking (same as task)
9. **Load balancing**: Skip for now (see section B)
10. Click **Create**

### Create Service - CLI

```bash
aws ecs create-service \
  --cluster my-cluster \
  --service-name my-application-service \
  --task-definition my-application-task:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-xxxxx,subnet-yyyyy],
    securityGroups=[sg-xxxxx],
    assignPublicIp=ENABLED
  }" \
  --region us-east-1
```

### Update Service

```bash
# Deploy new version (force new deployment)
aws ecs update-service \
  --cluster my-cluster \
  --service my-application-service \
  --force-new-deployment \
  --region us-east-1

# Scale service
aws ecs update-service \
  --cluster my-cluster \
  --service my-application-service \
  --desired-count 5 \
  --region us-east-1
```

## B. Application Load Balancer Setup

For production, use an Application Load Balancer to distribute traffic across multiple containers.

### Step 1: Create Target Group

#### Using Console

1. Go to **EC2** → **Target Groups** → **Create target group**
2. **Target type**: IP addresses
3. **Target group name**: `my-app-tg`
4. **Protocol**: HTTP
5. **Port**: `8080`
6. **VPC**: Select your VPC
7. **Health check path**: `/health` (adjust to your app's health endpoint)
8. **Health check interval**: 30 seconds
9. Click **Next**
10. **Skip registering targets** (ECS will do this automatically)
11. Click **Create target group**

#### Using CLI

```bash
aws elbv2 create-target-group \
  --name my-app-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id vpc-xxxxx \
  --target-type ip \
  --health-check-enabled \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --region us-east-1
```

### Step 2: Create Application Load Balancer

#### Using Console

1. Go to **EC2** → **Load Balancers** → **Create load balancer**
2. Select **Application Load Balancer**
3. **Load balancer name**: `my-app-alb`
4. **Scheme**: Internet-facing
5. **IP address type**: IPv4
6. **VPC**: Select your VPC
7. **Mappings**: Select at least 2 availability zones
8. **Security groups**: 
   - Create new security group
   - Allow HTTP (80) and/or HTTPS (443) from 0.0.0.0/0
9. **Listeners**:
   - **Protocol**: HTTP
   - **Port**: 80
   - **Default action**: Forward to `my-app-tg`
10. Click **Create load balancer**

#### Using CLI

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name my-app-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --region us-east-1

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:region:account:loadbalancer/app/my-app-alb/xxxxx \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:region:account:targetgroup/my-app-tg/xxxxx \
  --region us-east-1
```

### Step 3: Update ECS Service with Load Balancer

#### Using Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click **Services** → Select your service → **Update service**
3. Scroll to **Load balancing**
4. **Load balancer type**: Application Load Balancer
5. **Load balancer**: Select `my-app-alb`
6. **Target group**: Select `my-app-tg`
7. **Container to load balance**: Select your container and port
8. **Health check grace period**: 60 seconds
9. Update **Network configuration**:
   - Change **Public IP** to **DISABLED** (ALB will handle public access)
   - Update security group to only allow traffic from ALB security group
10. Click **Update**

#### Using CLI

```bash
aws ecs update-service \
  --cluster my-cluster \
  --service my-application-service \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:...,containerName=my-application,containerPort=8080" \
  --health-check-grace-period-seconds 60 \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-xxxxx,subnet-yyyyy],
    securityGroups=[sg-xxxxx],
    assignPublicIp=DISABLED
  }" \
  --region us-east-1
```

### Access Application via Load Balancer

1. Go to **EC2** → **Load Balancers**
2. Select your load balancer
3. Copy the **DNS name** (e.g., `my-app-alb-123456789.us-east-1.elb.amazonaws.com`)
4. Access your application: `http://my-app-alb-123456789.us-east-1.elb.amazonaws.com`

## C. Auto Scaling

Automatically scale your containers based on metrics like CPU or memory usage.

### Step 1: Register Scalable Target

#### Using Console

1. Go to **Amazon ECS** → **Clusters** → `my-cluster`
2. Click **Services** → Select your service
3. Click **Auto Scaling** tab
4. Click **Create**
5. **Scaling policy name**: `cpu-scaling`
6. **ECS service metric**: ECSServiceAverageCPUUtilization
7. **Target value**: 70 (scale when CPU > 70%)
8. **Scale-out cooldown**: 60 seconds
9. **Scale-in cooldown**: 300 seconds
10. **Minimum tasks**: 2
11. **Maximum tasks**: 10
12. Click **Create**

#### Using CLI

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/my-cluster/my-application-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10 \
  --region us-east-1

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/my-cluster/my-application-service \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json \
  --region us-east-1
```

Create `scaling-policy.json`:

```json
{
  "TargetValue": 70.0,
  "PredefinedMetricSpecification": {
    "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
  },
  "ScaleInCooldown": 300,
  "ScaleOutCooldown": 60
}
```

## D. HTTPS/SSL Setup

Add HTTPS support to your Application Load Balancer.

### Step 1: Request SSL Certificate (AWS Certificate Manager)

#### Using Console

1. Go to **AWS Certificate Manager**
2. Click **Request certificate**
3. Select **Request a public certificate**
4. **Domain name**: `myapp.example.com`
5. **Validation method**: DNS validation (recommended)
6. Click **Request**
7. Follow DNS validation instructions
8. Wait for status to become **Issued**

#### Using CLI

```bash
aws acm request-certificate \
  --domain-name myapp.example.com \
  --validation-method DNS \
  --region us-east-1
```

### Step 2: Add HTTPS Listener to ALB

#### Using Console

1. Go to **EC2** → **Load Balancers** → Select your ALB
2. Click **Listeners** tab → **Add listener**
3. **Protocol**: HTTPS
4. **Port**: 443
5. **Default action**: Forward to your target group
6. **Security policy**: ELBSecurityPolicy-TLS13-1-2-2021-06
7. **Default SSL certificate**: Select your ACM certificate
8. Click **Add**

#### Using CLI

```bash
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:aws:acm:... \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:... \
  --region us-east-1
```

### Step 3: Redirect HTTP to HTTPS (Optional)

Modify the HTTP listener to redirect to HTTPS:

```bash
aws elbv2 modify-listener \
  --listener-arn arn:aws:elasticloadbalancing:... \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" \
  --region us-east-1
```

## E. Multi-AZ Deployment

Deploy your application across multiple Availability Zones for high availability.

### Configuration

When creating your service:

1. **Subnets**: Select subnets from at least 2 different Availability Zones
2. **Desired count**: Use at least 2 tasks
3. ECS will automatically distribute tasks across AZs

Example:

```bash
aws ecs create-service \
  --cluster my-cluster \
  --service-name my-application-service \
  --task-definition my-application-task \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={
    subnets=[subnet-us-east-1a,subnet-us-east-1b,subnet-us-east-1c],
    securityGroups=[sg-xxxxx],
    assignPublicIp=DISABLED
  }" \
  --load-bal