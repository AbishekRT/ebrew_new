#!/bin/bash

# ===================================================================
# eBrew Laravel AWS Deployment - Quick Setup Script
# ===================================================================
# This script prepares and runs the complete deployment
# Run this on your EC2 instance: ./quick-deploy.sh
# ===================================================================

set -e  # Exit on any error

echo "🚀 eBrew Laravel AWS Deployment Starting..."
echo "================================================"

# ===================================================================
# 1. System Information
# ===================================================================
echo "📊 System Information:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk: $(df -h / | awk '/\/$/ {print $4}') available"
echo "User: $(whoami)"
echo ""

# ===================================================================
# 2. Pre-deployment Checks
# ===================================================================
echo "🔍 Running pre-deployment checks..."

# Check if we're on Ubuntu
if ! lsb_release -d | grep -q "Ubuntu"; then
    echo "❌ This script is designed for Ubuntu. Exiting."
    exit 1
fi

# Check for sudo access
if ! sudo -n true 2>/dev/null; then
    echo "❌ This script requires sudo access. Please run with sudo or configure passwordless sudo."
    exit 1
fi

# Check internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    echo "❌ No internet connectivity. Please check your network connection."
    exit 1
fi

echo "✅ Pre-deployment checks passed"
echo ""

# ===================================================================
# 3. GitHub Repository Check
# ===================================================================
echo "📦 Checking GitHub repository access..."

REPO_URL="https://github.com/AbishekRT/ebrew_new.git"
TEMP_DIR="/tmp/ebrew-check"

if git clone $REPO_URL $TEMP_DIR &> /dev/null; then
    echo "✅ GitHub repository is accessible"
    rm -rf $TEMP_DIR
else
    echo "❌ Cannot access GitHub repository: $REPO_URL"
    echo "Please check if the repository exists and is public."
    exit 1
fi

echo ""

# ===================================================================
# 4. Clone Repository and Prepare Deployment
# ===================================================================
echo "📥 Cloning repository for deployment..."

DEPLOY_DIR="/tmp/ebrew-deploy-$(date +%Y%m%d-%H%M%S)"
git clone $REPO_URL $DEPLOY_DIR

if [ ! -f "$DEPLOY_DIR/deploy-to-aws.sh" ]; then
    echo "❌ Deployment script not found in repository"
    exit 1
fi

cd $DEPLOY_DIR

# ===================================================================
# 5. Make Scripts Executable
# ===================================================================
echo "🔧 Preparing deployment scripts..."
chmod +x deploy-to-aws.sh
if [ -f "post-deployment-setup.sh" ]; then
    chmod +x post-deployment-setup.sh
fi

# ===================================================================
# 6. Display Deployment Information
# ===================================================================
echo ""
echo "🎯 Deployment Summary:"
echo "================================================"
echo "Repository: $REPO_URL"
echo "Deploy Directory: $DEPLOY_DIR" 
echo "Target Location: /var/www/ebrew"
echo "Database: MySQL (local) + MongoDB Atlas (cloud)"
echo "Web Server: Nginx"
echo "PHP Version: 8.2"
echo "Expected Duration: 10-15 minutes"
echo ""

# ===================================================================
# 7. Final Confirmation
# ===================================================================
echo "⚠️  IMPORTANT NOTES:"
echo "- This will install and configure multiple services"
echo "- Existing web server configurations may be overwritten"
echo "- The process will take 10-15 minutes to complete"
echo "- You can monitor progress in real-time"
echo ""

read -p "🚀 Ready to start deployment? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled by user"
    exit 1
fi

# ===================================================================
# 8. Run Main Deployment
# ===================================================================
echo ""
echo "🚀 Starting main deployment process..."
echo "================================================"

# Run the deployment script
if sudo ./deploy-to-aws.sh; then
    echo ""
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "================================================"
    echo ""
    echo "📍 Your application is now available at:"
    echo "   🌐 http://$(curl -s ifconfig.me || echo '16.171.36.211')"
    echo ""
    echo "🔍 Quick verification commands:"
    echo "   sudo systemctl status nginx php8.2-fpm mysql"
    echo "   curl -I http://localhost"
    echo ""
    echo "📊 Check logs if needed:"
    echo "   tail -f /var/www/ebrew/storage/logs/laravel.log"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Test your application in a web browser"
    echo "2. Verify FAQ and registration pages work" 
    echo "3. Set up SSL certificate if you have a domain"
    echo "4. Configure regular backups"
    echo ""
else
    echo ""
    echo "❌ DEPLOYMENT FAILED!"
    echo "================================================"
    echo ""
    echo "🔍 Check these log files for errors:"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo "   sudo tail -f /var/log/php8.2-fpm.log"
    echo "   tail -f /var/www/ebrew/storage/logs/laravel.log"
    echo ""
    echo "🔧 Try these troubleshooting steps:"
    echo "1. Check system resources: df -h && free -h"
    echo "2. Verify internet connection: ping google.com"
    echo "3. Check service status: sudo systemctl status nginx mysql"
    echo "4. Review the deployment script logs above"
    echo ""
    echo "💬 For support, provide the error messages from the logs"
    exit 1
fi

# ===================================================================
# 9. Optional Post-Deployment Setup
# ===================================================================
echo ""
read -p "🔒 Run additional security and optimization setup? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]] && [ -f "post-deployment-setup.sh" ]; then
    echo "🔧 Running post-deployment setup..."
    if sudo ./post-deployment-setup.sh; then
        echo "✅ Post-deployment setup completed successfully"
    else
        echo "⚠️ Post-deployment setup had some issues (check logs above)"
    fi
fi

# ===================================================================
# 10. Cleanup
# ===================================================================
echo ""
echo "🧹 Cleaning up temporary files..."
cd /
rm -rf $DEPLOY_DIR

echo ""
echo "🎊 eBrew Laravel deployment complete!"
echo "Your application should now be running at: http://$(curl -s ifconfig.me 2>/dev/null || echo '16.171.36.211')"
echo ""
echo "📖 For detailed documentation, see:"
echo "   - /var/www/ebrew/COMPLETE-AWS-DEPLOYMENT.md"
echo "   - /var/www/ebrew/AWS-DEPLOYMENT-GUIDE.md"
echo ""

exit 0