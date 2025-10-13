# Deployment Guide

Step-by-step guide to deploy a production-grade multi-application server from scratch.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Phase 1: Server Setup](#phase-1-server-setup)
- [Phase 2: Security Hardening](#phase-2-security-hardening)
- [Phase 3: Web Server Configuration](#phase-3-web-server-configuration)
- [Phase 4: Application Deployment](#phase-4-application-deployment)
- [Phase 5: SSL Configuration](#phase-5-ssl-configuration)
- [Phase 6: Monitoring and Maintenance](#phase-6-monitoring-and-maintenance)
- [Deployment Checklist](#deployment-checklist)

## Prerequisites

### Required Resources

- [ ] DigitalOcean account (or any VPS provider)
- [ ] Domain name with DNS access
- [ ] SSH key pair generated
- [ ] GitHub account (for code repository)
- [ ] Local terminal/SSH client

### Required Knowledge

- Basic Linux command line
- Understanding of DNS concepts
- Basic networking knowledge
- Familiarity with Docker (helpful)

### Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| DigitalOcean Droplet (2GB) | $12-18 |
| Domain Name | $10-15/year |
| **Total** | ~$12-18/month |

## Phase 1: Server Setup

### Step 1.1: Create DigitalOcean Droplet

1. **Log in to DigitalOcean**
   - Go to https://cloud.digitalocean.com/

2. **Create New Droplet**
   - Click "Create" → "Droplets"

3. **Choose Configuration**:
   ```
   Distribution: Ubuntu 24.04 LTS
   Plan: Basic
   CPU: Regular
   RAM: 2 GB
   Storage: 25 GB SSD
   Price: $12-18/month
   ```

4. **Choose Datacenter Region**:
   - Select closest to your target audience
   - Example: NYC3, SFO3, LON1, etc.

5. **Authentication**:
   - Choose "SSH Keys"
   - Add your public SSH key
   - Don't use password authentication

6. **Hostname**:
   - Choose meaningful name: `prod-server-01`

7. **Create Droplet**
   - Wait 1-2 minutes for provisioning

8. **Note IP Address**
   - Write down your droplet's IP address

### Step 1.2: Initial Server Access

```bash
# Connect to server via SSH
ssh root@YOUR_SERVER_IP

# Update system packages
apt update && apt upgrade -y

# Reboot if kernel was updated
reboot
```

### Step 1.3: Create Non-Root User (Security Best Practice)

```bash
# Reconnect after reboot
ssh root@YOUR_SERVER_IP

# Create new user
adduser deployer

# Add to sudo group
usermod -aG sudo deployer

# Setup SSH for new user
mkdir -p /home/deployer/.ssh
cp /root/.ssh/authorized_keys /home/deployer/.ssh/
chown -R deployer:deployer /home/deployer/.ssh
chmod 700 /home/deployer/.ssh
chmod 600 /home/deployer/.ssh/authorized_keys

# Test new user (from local machine)
ssh deployer@YOUR_SERVER_IP

# If successful, disable root login
sudo nano /etc/ssh/sshd_config
```

**Change:**
```
PermitRootLogin no
PasswordAuthentication no
```

**Apply changes:**
```bash
sudo systemctl restart sshd
```

### Step 1.4: Install Required Software

```bash
# Update package index
sudo apt update

# Install Nginx
sudo apt install nginx -y

# Install Docker
sudo apt install docker.io -y

# Install Docker Compose
sudo apt install docker-compose -y

# Install Certbot (for SSL)
sudo apt install certbot python3-certbot-nginx -y

# Install UFW (firewall)
sudo apt install ufw -y

# Install Fail2Ban (intrusion prevention)
sudo apt install fail2ban -y

# Install Git (for deployments)
sudo apt install git -y

# Add deployer to docker group
sudo usermod -aG docker deployer

# Log out and back in for group changes to take effect
exit
ssh deployer@YOUR_SERVER_IP
```

### Step 1.5: Verify Installations

```bash
# Check Nginx
nginx -v

# Check Docker
docker --version
docker-compose --version

# Check Certbot
certbot --version

# Verify services are running
sudo systemctl status nginx
sudo systemctl status docker
```

## Phase 2: Security Hardening

### Step 2.1: Configure UFW Firewall

```bash
# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (CRITICAL - do this first!)
sudo ufw allow ssh
sudo ufw limit ssh  # Rate limiting

# Allow HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Enable firewall
sudo ufw enable

# Verify configuration
sudo ufw status verbose
```

**Expected output:**
```
Status: active
To                         Action      From
--                         ------      ----
22/tcp                     LIMIT       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

### Step 2.2: Configure Fail2Ban

```bash
# Copy default configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit configuration
sudo nano /etc/fail2ban/jail.local
```

**Add/modify:**
```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = ssh
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
```

**Start and enable:**
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo systemctl status fail2ban

# Verify
sudo fail2ban-client status
```

### Step 2.3: Configure SSH Hardening

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config
```

**Recommended settings:**
```
Port 22                          # Or change to non-standard port
PermitRootLogin no               # Disable root login
PasswordAuthentication no        # Key-based only
PubkeyAuthentication yes         # Enable key auth
MaxAuthTries 3                   # Limit auth attempts
ClientAliveInterval 300          # Timeout idle sessions
ClientAliveCountMax 2            # Number of timeouts
```

**Restart SSH:**
```bash
sudo systemctl restart sshd
```

## Phase 3: Web Server Configuration

### Step 3.1: Configure DNS

**In your DNS provider (DigitalOcean, Namecheap, etc.):**

| Record Type | Name | Value | TTL |
|------------|------|-------|-----|
| A | @ | YOUR_SERVER_IP | 3600 |
| A | www | YOUR_SERVER_IP | 3600 |
| A | recipe | YOUR_SERVER_IP | 3600 |
| A | bookfinder | YOUR_SERVER_IP | 3600 |

**Wait for DNS propagation (5-30 minutes):**
```bash
# Check from local machine
dig yourdomain.com
nslookup yourdomain.com
```

### Step 3.2: Clone Repository

```bash
# Navigate to home directory
cd ~

# Clone your server infrastructure repository
git clone https://github.com/yourusername/server-infrastructure.git
cd server-infrastructure
```

### Step 3.3: Configure Nginx

```bash
# Copy security headers
sudo cp nginx/security-headers.conf /etc/nginx/snippets/security-headers.conf

# Copy site configurations (update domain names first!)
sudo cp nginx/sites-available/portfolio.conf /etc/nginx/sites-available/
sudo cp nginx/sites-available/recipe-subdomain.conf /etc/nginx/sites-available/
sudo cp nginx/sites-available/bookfinder-subdomain.conf /etc/nginx/sites-available/

# Update domain names in all .conf files
sudo nano /etc/nginx/sites-available/portfolio.conf
# Replace vladbortnik.dev with your domain

sudo nano /etc/nginx/sites-available/recipe-subdomain.conf
# Replace recipe.vladbortnik.dev with your subdomain

sudo nano /etc/nginx/sites-available/bookfinder-subdomain.conf
# Replace bookfinder.vladbortnik.dev with your subdomain

# Enable sites
sudo ln -s /etc/nginx/sites-available/portfolio.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/recipe-subdomain.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/bookfinder-subdomain.conf /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 3.4: Deploy Static Website

```bash
# Create web directory
sudo mkdir -p /var/www/yourdomain.com/html

# Set permissions
sudo chown -R $USER:$USER /var/www/yourdomain.com/html
sudo chmod -R 755 /var/www/yourdomain.com

# Upload your static files
# Option 1: Using SCP from local machine
scp -r /path/to/local/website/* deployer@YOUR_SERVER_IP:/var/www/yourdomain.com/html/

# Option 2: Using Git
cd /var/www/yourdomain.com/html
git clone https://github.com/yourusername/portfolio-website.git .

# Test in browser
# Visit http://yourdomain.com (should work without SSL for now)
```

## Phase 4: Application Deployment

### Step 4.1: Prepare Application Code

For each application (recipe-app, bookfinder-app):

```bash
# Navigate to application directory
cd ~/server-infrastructure/docker/recipe-app

# Create .env file
nano .env
```

**Example .env:**
```bash
# Database Configuration
POSTGRES_DB=recipe_db
POSTGRES_USER=recipe_user
POSTGRES_PASSWORD=STRONG_PASSWORD_HERE

# Application Configuration
FLASK_APP=run.py
FLASK_ENV=production
SECRET_KEY=GENERATE_RANDOM_SECRET_KEY

# API Keys
SPOONACULAR_API_KEY=your_api_key_here
```

**Create Dockerfile:**
```dockerfile
FROM python:3.11-slim

WORKDIR /code

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose port
EXPOSE 5002

# Run Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5002", "run:app"]
```

**Create requirements.txt:**
```
Flask==3.0.0
gunicorn==21.2.0
psycopg2-binary==2.9.9
python-dotenv==1.0.0
requests==2.31.0
```

### Step 4.2: Deploy with Docker Compose

```bash
# Ensure you're in the app directory
cd ~/server-infrastructure/docker/recipe-app

# Build and start containers
docker-compose up -d --build

# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Verify containers are running
docker ps
```

**Repeat for other applications:**
```bash
cd ~/server-infrastructure/docker/bookfinder-app
# Same steps as above
```

### Step 4.3: Verify Applications

```bash
# Test locally
curl http://localhost:5002
curl http://localhost:5001

# Check Docker networks
docker network ls
docker network inspect recipe-app_backend

# Check volumes
docker volume ls
```

## Phase 5: SSL Configuration

### Step 5.1: Generate SSL Certificates

```bash
# For main domain
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# For subdomains
sudo certbot --nginx -d recipe.yourdomain.com
sudo certbot --nginx -d bookfinder.yourdomain.com
```

**Follow prompts:**
1. Enter email address
2. Agree to Terms of Service
3. Choose to redirect HTTP to HTTPS (option 2)

### Step 5.2: Verify SSL Configuration

```bash
# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Check certificate status
sudo certbot certificates
```

### Step 5.3: Test in Browser

Visit your sites:
- https://yourdomain.com
- https://recipe.yourdomain.com
- https://bookfinder.yourdomain.com

Check for:
- ✅ Green padlock
- ✅ Valid certificate
- ✅ No mixed content warnings

### Step 5.4: Verify SSL Rating

Test at: https://www.ssllabs.com/ssltest/

**Target: A+ rating**

## Phase 6: Monitoring and Maintenance

### Step 6.1: Set Up Log Monitoring

```bash
# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# View application logs
docker-compose logs -f recipe_web
docker-compose logs -f bookfinder_web

# View system logs
sudo journalctl -f
```

### Step 6.2: Configure Automatic Backups

```bash
# Create backup script
nano ~/backup.sh
```

**Script content:**
```bash
#!/bin/bash
# Backup script for databases and configurations

BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec recipe_db pg_dump -U recipe_user recipe_db > $BACKUP_DIR/recipe_db_$DATE.sql

# Backup MySQL
docker exec bookfinder_db mysqldump -u bookfinder_user -p$MYSQL_PASSWORD bookfinder_db > $BACKUP_DIR/bookfinder_db_$DATE.sql

# Backup Nginx configs
tar -czf $BACKUP_DIR/nginx_config_$DATE.tar.gz /etc/nginx/

# Delete backups older than 30 days
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

**Make executable and schedule:**
```bash
chmod +x ~/backup.sh

# Add to crontab
crontab -e
```

**Add line:**
```
0 2 * * * /home/deployer/backup.sh >> /home/deployer/backup.log 2>&1
```

### Step 6.3: Monitor Resource Usage

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check Docker stats
docker stats

# Monitor system resources
htop  # Install if needed: sudo apt install htop
```

### Step 6.4: Set Up Monitoring Alerts (Optional)

**Option 1: UptimeRobot (Free)**
1. Sign up at https://uptimerobot.com/
2. Add monitors for each domain
3. Set up email/SMS alerts

**Option 2: DigitalOcean Monitoring**
1. Enable in Droplet settings
2. Configure CPU/memory alerts
3. Set up email notifications

## Deployment Checklist

### Pre-Deployment
- [ ] Server provisioned and accessible
- [ ] SSH key authentication configured
- [ ] Non-root user created
- [ ] All software installed
- [ ] DNS records configured and propagated

### Security
- [ ] UFW firewall enabled and configured
- [ ] Fail2Ban installed and running
- [ ] SSH hardened (no root, no password)
- [ ] SSL certificates generated
- [ ] Security headers configured
- [ ] A+ SSL rating achieved

### Applications
- [ ] Docker installed and running
- [ ] Applications deployed via Docker Compose
- [ ] Environment variables configured
- [ ] Databases initialized
- [ ] Application logs accessible

### Web Server
- [ ] Nginx installed and running
- [ ] Site configurations in place
- [ ] SSL/TLS configured
- [ ] HTTP to HTTPS redirect working
- [ ] Static files serving correctly
- [ ] Reverse proxy working

### Testing
- [ ] All domains accessible via HTTPS
- [ ] SSL certificates valid
- [ ] Applications functioning correctly
- [ ] Database connections working
- [ ] Security headers present
- [ ] Logs being generated

### Monitoring
- [ ] Log rotation configured
- [ ] Backup script in place
- [ ] Monitoring alerts configured
- [ ] Resource usage within limits

## Post-Deployment Tasks

### Week 1
- [ ] Monitor logs daily
- [ ] Check resource usage
- [ ] Verify backups running
- [ ] Test all functionality

### Month 1
- [ ] Review Fail2Ban logs
- [ ] Check SSL certificate expiry
- [ ] Analyze traffic patterns
- [ ] Optimize resource allocation

### Ongoing
- [ ] Update system packages monthly
- [ ] Review security logs weekly
- [ ] Test backups quarterly
- [ ] Update dependencies regularly

## Rollback Procedures

### Application Rollback

```bash
# Stop containers
docker-compose down

# Checkout previous version
git checkout PREVIOUS_COMMIT

# Rebuild and restart
docker-compose up -d --build
```

### Database Rollback

```bash
# Restore from backup
cat backup.sql | docker exec -i recipe_db psql -U recipe_user -d recipe_db
```

### Configuration Rollback

```bash
# Restore Nginx config
sudo cp /etc/nginx/sites-available/portfolio.conf.bak /etc/nginx/sites-available/portfolio.conf
sudo nginx -t
sudo systemctl reload nginx
```

## Troubleshooting Common Issues

See [troubleshooting.md](troubleshooting.md) for detailed solutions to common problems.

## Additional Resources

- [DigitalOcean Initial Server Setup](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu)
- [Docker Deployment Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/beginners_guide.html)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## Support

If you encounter issues:
1. Check [troubleshooting.md](troubleshooting.md)
2. Review application logs
3. Check service status
4. Consult official documentation
5. Open GitHub issue if needed

---

**Deployment completed!** 🎉

Your production server should now be fully operational with:
- ✅ Secure HTTPS connections
- ✅ Multiple applications running
- ✅ Production-grade security
- ✅ Automated backups
- ✅ Monitoring in place
