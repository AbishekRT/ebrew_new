# SSH Setup Commands for GitHub on EC2

## Step 1: Connect to EC2

```bash
# Use the full path to your SSH key (adjust path as needed)
ssh -i "D:\Users\ansyp\Downloads\ebrew-key.pem" ubuntu@16.171.36.211
# OR if key is in current directory:
ssh -i "./ebrew-key.pem" ubuntu@16.171.36.211
```

## Step 2: Generate SSH Key on EC2

```bash
# Generate a new SSH key pair on your EC2 instance
ssh-keygen -t ed25519 -C "your_email@example.com"

# When prompted:
# - Press Enter for default file location (~/.ssh/id_ed25519)
# - Press Enter for empty passphrase (or set one if you prefer)
# - Press Enter again to confirm
```

## Step 3: Copy the Public Key

```bash
# Display and copy the public key content
cat ~/.ssh/id_ed25519.pub
```

## Step 4: Add Key to GitHub

1. Copy the entire output from the previous command
2. Go to GitHub.com → Settings → SSH and GPG keys
3. Click "New SSH key"
4. Paste the key content
5. Give it a title like "EC2 eBrew Server"
6. Click "Add SSH key"

## Step 5: Test SSH Connection to GitHub

```bash
# Test the SSH connection to GitHub
ssh -T git@github.com

# You should see a message like:
# "Hi AbishekRT! You've successfully authenticated, but GitHub does not provide shell access."
```

## Step 6: Clone Repository via SSH

```bash
# Clone your repository using SSH
git clone git@github.com:AbishekRT/ebrew_new.git /var/www/ebrew

# Set proper ownership
sudo chown -R ubuntu:ubuntu /var/www/ebrew
```

## Step 7: Verify Repository Access

```bash
# Navigate to the project directory
cd /var/www/ebrew

# Check git status
git status

# Test if you can pull updates
git pull origin main
```
