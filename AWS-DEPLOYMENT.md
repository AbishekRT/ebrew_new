# eBrew Laravel - AWS Advanced Deployment

## 🏗️ Architecture Overview

This deployment showcases advanced AWS features within the free tier limits:

### **🚀 Advanced Features Implemented:**

1. **Containerization**
   - ✅ Docker containerization
   - ✅ Amazon ECS with Fargate
   - ✅ Auto-scaling containers
   - ✅ Health checks and monitoring

2. **Load Balancing & High Availability**
   - ✅ Application Load Balancer (ALB)
   - ✅ Multi-AZ deployment
   - ✅ Auto-scaling groups
   - ✅ Health-based routing

3. **Serverless Architecture**
   - ✅ AWS Lambda functions
   - ✅ Event-driven processing
   - ✅ Serverless order processing
   - ✅ Image resizing automation

4. **Security Best Practices**
   - ✅ VPC with public/private subnets
   - ✅ Security groups (firewall rules)
   - ✅ IAM roles and policies
   - ✅ Secrets Manager integration
   - ✅ Database encryption

5. **Database & Storage**
   - ✅ Amazon RDS MySQL (managed database)
   - ✅ Multi-AZ availability
   - ✅ Automated backups
   - ✅ Amazon S3 for file storage

6. **Monitoring & Logging**
   - ✅ CloudWatch logs
   - ✅ Application metrics
   - ✅ Health monitoring
   - ✅ Automated alerts

## 📋 Prerequisites

1. **AWS Account** with free tier eligibility
2. **AWS CLI** installed and configured
3. **Docker** installed locally
4. **Node.js & npm** for Lambda functions

## 🚀 Deployment Steps

### **Step 1: Clone and Prepare**
```bash
git clone https://github.com/AbishekRT/ebrew_new.git
cd ebrew_new
```

### **Step 2: Configure AWS CLI**
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### **Step 3: Deploy Infrastructure**
```bash
chmod +x aws/deploy.sh
./aws/deploy.sh
```

### **Step 4: Update Environment Variables**
After deployment, update `.env.aws` with actual values:
- RDS endpoint from AWS Console
- Load Balancer DNS name
- S3 bucket name

### **Step 5: Configure Domain (Optional)**
```bash
# Create Route 53 hosted zone
aws route53 create-hosted-zone --name yourdomain.com --caller-reference $(date +%s)

# Create SSL certificate
aws acm request-certificate --domain-name yourdomain.com --validation-method DNS
```

## 🏗️ Architecture Diagram

```
Internet → CloudFront → ALB → ECS Fargate (Laravel)
                         ↓           ↓
                    Lambda Functions  RDS MySQL
                         ↓
                    S3 Storage
```

## 💰 Cost Optimization (Free Tier)

### **What's Free:**
- ✅ ECS Fargate: 20GB-hours/month
- ✅ RDS db.t2.micro: 750 hours/month
- ✅ Lambda: 1M requests/month
- ✅ ALB: 750 hours/month
- ✅ S3: 5GB storage
- ✅ CloudWatch: Basic monitoring

### **Estimated Costs After Free Tier:**
- **Total: ~$25-35/month**
- ECS Fargate: ~$15/month
- RDS MySQL: ~$15/month
- S3 & Data Transfer: ~$2-5/month

## 🔧 Management Commands

### **Scale Application:**
```bash
aws ecs update-service \
    --cluster ebrew-laravel-cluster \
    --service ebrew-laravel-service \
    --desired-count 3
```

### **Deploy Updates:**
```bash
# Build and push new image
docker build -t ebrew-laravel .
docker tag ebrew-laravel:latest $ECR_URI:latest
docker push $ECR_URI:latest

# Update ECS service
aws ecs update-service \
    --cluster ebrew-laravel-cluster \
    --service ebrew-laravel-service \
    --force-new-deployment
```

### **Monitor Logs:**
```bash
aws logs tail /ecs/ebrew-laravel --follow
```

## 📊 Advanced Features Demonstrated

1. **Containerization**: Full Docker containerization with ECS orchestration
2. **Microservices**: Lambda functions for specific tasks
3. **Auto-scaling**: ECS service scales based on demand
4. **Load Balancing**: Traffic distributed across multiple containers
5. **Security**: VPC, security groups, encrypted database
6. **Monitoring**: CloudWatch integration for logs and metrics
7. **High Availability**: Multi-AZ deployment across availability zones

## 🎯 University Assignment Compliance

This deployment demonstrates:

✅ **Containerization**: Docker + ECS Fargate
✅ **Advanced Hosting**: AWS with multiple services
✅ **Scalability**: Auto-scaling and load balancing  
✅ **Security**: VPC, security groups, encryption
✅ **Fault Tolerance**: Multi-AZ, health checks
✅ **Serverless**: Lambda functions
✅ **Modern Architecture**: Cloud-native design patterns

## 📱 Access Your Application

After deployment, your eBrew Laravel application will be available at:
**http://[ALB-DNS-NAME]**

The deployment script will display the exact URL upon completion.

---

**Note**: This architecture showcases professional-grade AWS deployment patterns while staying within free tier limits for the first 12 months.