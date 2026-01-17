# Deploying Dev Container Applications to AWS ECS

## Overview Architecture

```
Local Development (VSCode + Dev Container) 
    ↓
Build & Push to Amazon ECR (Container Registry)
    ↓
Deploy to Amazon ECS (Elastic Container Service)
```

---

## Prerequisites

- AWS Account with appropriate IAM permissions
- AWS CLI installed and configured
- Docker Desktop installed
- VSCode with Dev Containers extension
- Git repository for your project

---

## Part 1: Setting Up Dev Container in VSCode

### Quick Start: Enable Dev Container in VSCode UI

1. **Install the Dev Containers extension**
   - Open VSCode
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Dev Containers" by Microsoft
   - Click Install

2. **Create or open a project folder**
   - Open VSCode
   - File > Open Folder
   - Select your project folder

3. **Open Dev Container configuration**
   - Press F1 or View > Command Palette
   - Type "Dev Containers: Add Dev Container Configuration Files..."
   - Select your project folder

4. **Choose a base image**
   - Select "From predefined configuration examples"
   - Browse or search for your desired base image
   - Example: Type "python:3.11" in the search bar
   - Select "Python 3" or click "Show More Definitions" to see all available images
   - Choose the specific image (e.g., "Python 3.11" or "Python 3.11 Slim")
   - Optionally select additional features (e.g., Node.js, common utilities)
   - Click OK

5. **Review and customize configuration**
   - VSCode will create `.devcontainer/devcontainer.json` and `.devcontainer/Dockerfile`
   - Review the generated files and make any needed modifications

6. **Open in Dev Container**
   - Press F1 or View > Command Palette
   - Type "Dev Containers: Reopen in Container"
   - VSCode will build and start the container

7. **Verify the container is running**
   - The bottom-left corner should show "Dev Container: python:3.11" (or your chosen image)
   - Open a terminal (Ctrl+`) - you're now inside the container
   - Run `python --version` to verify Python 3.11 is installed

**Alternative: Use Docker Compose instead of Dockerfile**

If you prefer using Docker Compose:

1. In the Dev Container configuration screen, select "Use Docker Compose"
2. VSCode will create `docker-compose.yml` in the `.devcontainer` folder
3. Configure your services in the docker-compose file

### For Next.js 16 Application

**Directory Structure:**
```
my-nextjs-app/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── Dockerfile.prod
├── next.config.js
├── package.json
└── src/
```

**`.devcontainer/devcontainer.json`:**
```json
{
  "name": "Next.js 16 Dev Container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "forwardPorts": [3000],
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  }
}
```

**`.devcontainer/Dockerfile`:**
```dockerfile
FROM node:20-alpine

WORKDIR /workspace

RUN apk add --no-cache git

# Install global packages
RUN npm install -g npm@latest
```

**`Dockerfile.prod` (for ECS deployment):**
```dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
```

### For Python Application

**Directory Structure:**
```
my-python-app/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── Dockerfile.prod
├── requirements.txt
├── app.py
└── src/
```

**`.devcontainer/devcontainer.json`:**
```json
{
  "name": "Python Dev Container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "forwardPorts": [8000],
  "postCreateCommand": "pip install -r requirements.txt",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  }
}
```

**`.devcontainer/Dockerfile`:**
```dockerfile
FROM python:3.11-slim

WORKDIR /workspace

RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip
```

**`Dockerfile.prod`:**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "app.py"]
```

### For n8n Workflow

**Directory Structure:**
```
my-n8n-workflow/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── Dockerfile.prod
└── workflows/
    └── my-workflow.json
```

**`.devcontainer/devcontainer.json`:**
```json
{
  "name": "n8n Dev Container",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "forwardPorts": [5678],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-azuretools.vscode-docker"
      ]
    }
  }
}
```

**`.devcontainer/Dockerfile`:**
```dockerfile
FROM n8nio/n8n:latest

USER root
RUN apk add --no-cache git
USER node
```

**`Dockerfile.prod`:**
```dockerfile
FROM n8nio/n8n:latest

USER root

# Copy workflow files
COPY --chown=node:node workflows/ /home/node/.n8n/workflows/

USER node

EXPOSE 5678

CMD ["n8n"]
```

---

## Part 2: AWS Setup

### Step 1: Create ECR Repository

```bash
# Set variables
export AWS_REGION=us-east-1
export APP_NAME=my-app
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ECR repository
aws ecr create-repository \
    --repository-name ${APP_NAME} \
    --region ${AWS_REGION} \
    --image-scanning-configuration scanOnPush=true
```

### Step 2: Authenticate Docker to ECR

```bash
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### Step 3: Build and Push Docker Image

```bash
# Build production image
docker build -f Dockerfile.prod -t ${APP_NAME}:latest .

# Tag image for ECR
docker tag ${APP_NAME}:latest \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}:latest

# Push to ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}:latest
```

---

## Part 3: ECS Cluster Setup

### Step 1: Create ECS Cluster

```bash
aws ecs create-cluster \
    --cluster-name ${APP_NAME}-cluster \
    --region ${AWS_REGION}
```

### Step 2: Create Task Execution Role

**Create `task-execution-role-trust-policy.json`:**
```json
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
```

```bash
# Create IAM role
aws iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file://task-execution-role-trust-policy.json

# Attach AWS managed policy
aws iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### Step 3: Create Task Definition

**For Next.js (`task-definition-nextjs.json`):**
```json
{
  "family": "nextjs-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "nextjs-container",
      "image": "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/my-app:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/nextjs-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**For Python (`task-definition-python.json`):**
```json
{
  "family": "python-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "python-container",
      "image": "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/my-app:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/python-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**For n8n (`task-definition-n8n.json`):**
```json
{
  "family": "n8n-app",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "n8n-container",
      "image": "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/my-app:latest",
      "portMappings": [
        {
          "containerPort": 5678,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "N8N_BASIC_AUTH_ACTIVE",
          "value": "true"
        },
        {
          "name": "N8N_BASIC_AUTH_USER",
          "value": "admin"
        },
        {
          "name": "N8N_BASIC_AUTH_PASSWORD",
          "value": "change-this-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/n8n-app",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### Step 4: Create CloudWatch Log Group

```bash
aws logs create-log-group \
    --log-group-name /ecs/${APP_NAME} \
    --region ${AWS_REGION}
```

### Step 5: Register Task Definition

```bash
# Replace placeholders in task definition
sed -i "s/ACCOUNT_ID/${AWS_ACCOUNT_ID}/g" task-definition.json
sed -i "s/REGION/${AWS_REGION}/g" task-definition.json

# Register task definition
aws ecs register-task-definition \
    --cli-input-json file://task-definition.json \
    --region ${AWS_REGION}
```

---

## Part 4: Network Configuration

### Create VPC Resources (if not existing)

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.VpcId' \
    --output text)

# Create public subnets
SUBNET_1=$(aws ec2 create-subnet \
    --vpc-id ${VPC_ID} \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${AWS_REGION}a \
    --query 'Subnet.SubnetId' \
    --output text)

SUBNET_2=$(aws ec2 create-subnet \
    --vpc-id ${VPC_ID} \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ${AWS_REGION}b \
    --query 'Subnet.SubnetId' \
    --output text)

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

aws ec2 attach-internet-gateway \
    --vpc-id ${VPC_ID} \
    --internet-gateway-id ${IGW_ID}

# Create route table
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id ${VPC_ID} \
    --query 'RouteTable.RouteTableId' \
    --output text)

aws ec2 create-route \
    --route-table-id ${ROUTE_TABLE_ID} \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id ${IGW_ID}

aws ec2 associate-route-table \
    --subnet-id ${SUBNET_1} \
    --route-table-id ${ROUTE_TABLE_ID}

aws ec2 associate-route-table \
    --subnet-id ${SUBNET_2} \
    --route-table-id ${ROUTE_TABLE_ID}

# Create security group
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name ${APP_NAME}-sg \
    --description "Security group for ${APP_NAME}" \
    --vpc-id ${VPC_ID} \
    --query 'GroupId' \
    --output text)

# Allow inbound traffic (adjust port based on your app)
aws ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0
```

---

## Part 5: Create ECS Service

```bash
aws ecs create-service \
    --cluster ${APP_NAME}-cluster \
    --service-name ${APP_NAME}-service \
    --task-definition ${APP_NAME}:1 \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_1},${SUBNET_2}],securityGroups=[${SECURITY_GROUP_ID}],assignPublicIp=ENABLED}" \
    --region ${AWS_REGION}
```

---

## Part 6: (Optional) Add Application Load Balancer

### Create ALB

```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name ${APP_NAME}-alb \
    --subnets ${SUBNET_1} ${SUBNET_2} \
    --security-groups ${SECURITY_GROUP_ID} \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

# Create target group (adjust port)
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
    --name ${APP_NAME}-tg \
    --protocol HTTP \
    --port 3000 \
    --vpc-id ${VPC_ID} \
    --target-type ip \
    --health-check-path / \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Create listener
aws elbv2 create-listener \
    --load-balancer-arn ${ALB_ARN} \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN}

# Update service to use ALB
aws ecs update-service \
    --cluster ${APP_NAME}-cluster \
    --service ${APP_NAME}-service \
    --load-balancers targetGroupArn=${TARGET_GROUP_ARN},containerName=${APP_NAME}-container,containerPort=3000 \
    --region ${AWS_REGION}
```

---

## Part 7: CI/CD Pipeline (GitHub Actions)

**`.github/workflows/deploy.yml`:**

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: my-app
  ECS_CLUSTER: my-app-cluster
  ECS_SERVICE: my-app-service
  CONTAINER_NAME: my-app-container

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -f Dockerfile.prod -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

      - name: Download task definition
        run: |
          aws ecs describe-task-definition \
            --task-definition ${{ env.ECS_SERVICE }} \
            --query taskDefinition > task-definition.json

      - name: Fill in the new image ID in the Amazon ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: ${{ env.CONTAINER_NAME }}
          image: ${{ steps.build-image.outputs.image }}

      - name: Deploy Amazon ECS task definition
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true
```

---

## Part 8: Useful Commands

### Monitor Deployment

```bash
# Check service status
aws ecs describe-services \
    --cluster ${APP_NAME}-cluster \
    --services ${APP_NAME}-service \
    --region ${AWS_REGION}

# View running tasks
aws ecs list-tasks \
    --cluster ${APP_NAME}-cluster \
    --service-name ${APP_NAME}-service \
    --region ${AWS_REGION}

# View logs
aws logs tail /ecs/${APP_NAME} --follow
```

### Update Service

```bash
# Force new deployment
aws ecs update-service \
    --cluster ${APP_NAME}-cluster \
    --service ${APP_NAME}-service \
    --force-new-deployment \
    --region ${AWS_REGION}
```

### Scale Service

```bash
# Scale to 3 instances
aws ecs update-service \
    --cluster ${APP_NAME}-cluster \
    --service ${APP_NAME}-service \
    --desired-count 3 \
    --region ${AWS_REGION}
```

---

## Summary

This guide covers the complete workflow from local development using VSCode Dev Containers to production deployment on AWS ECS. The key steps are:

1. Develop locally in Dev Container
2. Build production Docker image
3. Push to Amazon ECR
4. Create ECS cluster and task definition
5. Deploy as ECS service
6. (Optional) Add load balancing and CI/CD

Each application type (Next.js, Python, n8n) follows the same pattern but with different configurations for ports, environment variables, and resource requirements.
