#!/bin/bash
set -e

# AWS eBrew Laravel Deployment Script
# Advanced Architecture with Free Tier Components

PROJECT_NAME="ebrew-laravel"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "🚀 Starting AWS deployment for eBrew Laravel..."

# Step 1: Create ECR Repository
echo "📦 Creating ECR repository..."
aws ecr create-repository --repository-name $PROJECT_NAME --region $REGION || true

# Step 2: Build and Push Docker Image
echo "🐳 Building Docker image..."
docker build -t $PROJECT_NAME .

# Tag and push to ECR
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$PROJECT_NAME"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

docker tag $PROJECT_NAME:latest $ECR_URI:latest
docker push $ECR_URI:latest

echo "✅ Docker image pushed to ECR"

# Step 3: Deploy CloudFormation Stack
echo "☁️ Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file aws/cloudformation-template.yaml \
    --stack-name $PROJECT_NAME-infrastructure \
    --parameter-overrides \
        ProjectName=$PROJECT_NAME \
        Environment=production \
        DatabasePassword=MySecurePassword123! \
    --capabilities CAPABILITY_IAM \
    --region $REGION

echo "✅ Infrastructure deployed"

# Step 4: Create ECS Service
echo "🔧 Creating ECS service..."

# Update task definition with actual values
sed -i "s/YOUR_ACCOUNT_ID/$ACCOUNT_ID/g" aws/ecs-task-definition.json

# Register task definition
aws ecs register-task-definition \
    --cli-input-json file://aws/ecs-task-definition.json \
    --region $REGION

# Get cluster name and target group ARN
CLUSTER_NAME=$(aws cloudformation describe-stacks \
    --stack-name $PROJECT_NAME-infrastructure \
    --query 'Stacks[0].Outputs[?OutputKey==`ECSCluster`].OutputValue' \
    --output text --region $REGION)

TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --names $PROJECT_NAME-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text --region $REGION)

# Get subnet IDs
SUBNET_IDS=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=$PROJECT_NAME-public-subnet-*" \
    --query 'Subnets[].SubnetId' \
    --output text --region $REGION | tr '\t' ',')

# Get security group ID
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=$PROJECT_NAME-ecs-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text --region $REGION)

# Create ECS service
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $PROJECT_NAME-service \
    --task-definition $PROJECT_NAME-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_IDS],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=ebrew-laravel-container,containerPort=80" \
    --region $REGION

echo "🎉 ECS service created"

# Step 5: Deploy Lambda Functions
echo "⚡ Deploying Lambda functions..."

# Create deployment package
cd aws/lambda
zip -r functions.zip functions.js node_modules/ || zip -r functions.zip functions.js
cd ../..

# Create order processing function
aws lambda create-function \
    --function-name $PROJECT_NAME-order-processor \
    --runtime nodejs18.x \
    --role arn:aws:iam::$ACCOUNT_ID:role/lambda-execution-role \
    --handler functions.processOrder \
    --zip-file fileb://aws/lambda/functions.zip \
    --environment Variables="{DB_HOST=placeholder,DB_USERNAME=admin,DB_PASSWORD=MySecurePassword123!,DB_DATABASE=ebrew_laravel}" \
    --region $REGION || true

# Create image resizing function
aws lambda create-function \
    --function-name $PROJECT_NAME-image-resizer \
    --runtime nodejs18.x \
    --role arn:aws:iam::$ACCOUNT_ID:role/lambda-execution-role \
    --handler functions.resizeProductImage \
    --zip-file fileb://aws/lambda/functions.zip \
    --region $REGION || true

echo "✅ Lambda functions deployed"

# Step 6: Get Application URL
ALB_DNS=$(aws cloudformation describe-stacks \
    --stack-name $PROJECT_NAME-infrastructure \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text --region $REGION)

echo ""
echo "🎉 Deployment Complete!"
echo "📱 Your eBrew Laravel application is available at:"
echo "   http://$ALB_DNS"
echo ""
echo "🏗️ Architecture deployed:"
echo "   ✅ Docker containerization (ECS Fargate)"
echo "   ✅ Load balancing (Application Load Balancer)"
echo "   ✅ Auto-scaling (ECS Service)"
echo "   ✅ Serverless functions (Lambda)"
echo "   ✅ Managed database (RDS MySQL)"
echo "   ✅ Security groups and VPC"
echo "   ✅ CloudWatch monitoring"
echo ""
echo "⚠️ Note: It may take 5-10 minutes for the service to be fully available"