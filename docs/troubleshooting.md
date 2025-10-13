# Troubleshooting Guide

Common issues and solutions for production server deployment and maintenance.

## Table of Contents

- [Server Access Issues](#server-access-issues)
- [Nginx Issues](#nginx-issues)
- [SSL/TLS Issues](#ssltls-issues)
- [Docker Issues](#docker-issues)
- [Application Issues](#application-issues)
- [Database Issues](#database-issues)
- [Security Issues](#security-issues)
- [Performance Issues](#performance-issues)
- [Diagnostic Commands](#diagnostic-commands)

## Server Access Issues

### Cannot SSH to Server

**Symptom**: Connection timeout or "Connection refused"

**Possible Causes**:
1. Server is down
2. Wrong IP address
3. Firewall blocking SSH
4. SSH service not running

**Solutions**:

```bash
# 1. Verify server is running (from DigitalOcean console)
# Check droplet status in dashboard

# 2. Verify correct IP address
ping YOUR_SERVER_IP

# 3. Check if SSH port is open (from local machine)
telnet YOUR_SERVER_IP 22
# or
nmap -p 22 YOUR_SERVER_IP

# 4. Access via console (DigitalOcean Recovery Console)
# Then check SSH service
sudo systemctl status sshd

# Restart SSH if needed
sudo systemctl restart sshd

# Check firewall rules
sudo ufw status
sudo ufw allow ssh  # If SSH was blocked
```

### SSH Key Authentication Fails

**Symptom**: "Permission denied (publickey)"

**Solutions**:

```bash
# 1. Check if correct key is being used (local machine)
ssh -vvv deployer@YOUR_SERVER_IP
# Look for "Offering public key" messages

# 2. Verify key permissions (local machine)
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 3. Check authorized_keys on server (via console)
cat ~/.ssh/authorized_keys
# Ensure your public key is present

# 4. Check permissions on server
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 5. Check SSH config on server
sudo nano /etc/ssh/sshd_config
# Ensure:
# PubkeyAuthentication yes
# AuthorizedKeysFile .ssh/authorized_keys

sudo systemctl restart sshd
```

### Locked Out After UFW Enable

**Symptom**: Can't connect after enabling UFW

**Solution**:

```bash
# Access via DigitalOcean console

# Disable UFW
sudo ufw disable

# Add SSH rule
sudo ufw allow ssh

# Re-enable UFW
sudo ufw enable

# Verify
sudo ufw status
```

## Nginx Issues

### 502 Bad Gateway

**Symptom**: "502 Bad Gateway" error when accessing site

**Causes**: Backend application not running or unreachable

**Solutions**:

```bash
# 1. Check if application is running
docker ps
# Ensure application containers are up

# 2. Check if application is listening on correct port
sudo netstat -tulpn | grep :5002
sudo netstat -tulpn | grep :5001

# 3. Check application logs
docker-compose logs recipe_web
docker-compose logs bookfinder_web

# 4. Test backend directly
curl http://localhost:5002
curl http://localhost:5001

# 5. Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# 6. Verify proxy_pass in Nginx config
sudo nano /etc/nginx/sites-available/recipe-subdomain.conf
# Check proxy_pass http://localhost:5002;

# 7. Restart services
docker-compose restart
sudo systemctl restart nginx
```

### 403 Forbidden

**Symptom**: "403 Forbidden" when accessing static site

**Causes**: File permissions or missing index file

**Solutions**:

```bash
# 1. Check if index.html exists
ls -la /var/www/yourdomain.com/html/

# 2. Check file permissions
sudo chown -R www-data:www-data /var/www/yourdomain.com/
sudo chmod -R 755 /var/www/yourdomain.com/

# 3. Check Nginx config
sudo nano /etc/nginx/sites-available/portfolio.conf
# Verify root path and index directive

# 4. Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# 5. Test Nginx config
sudo nginx -t

# 6. Reload Nginx
sudo systemctl reload nginx
```

### 404 Not Found

**Symptom**: "404 Not Found" for valid pages

**Solutions**:

```bash
# 1. Check if files exist in correct location
ls -la /var/www/yourdomain.com/html/

# 2. Check Nginx root directive
sudo nano /etc/nginx/sites-available/portfolio.conf
# Verify root path matches file location

# 3. Check for try_files directive
# location / {
#     try_files $uri $uri/ =404;
# }

# 4. Test configuration
sudo nginx -t

# 5. Reload Nginx
sudo systemctl reload nginx

# 6. Clear browser cache
# Force refresh: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
```

### Nginx Won't Start

**Symptom**: Nginx fails to start or reload

**Solutions**:

```bash
# 1. Test configuration
sudo nginx -t
# This will show exactly what's wrong

# 2. Check for port conflicts
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# 3. Kill process using port 80/443
sudo fuser -k 80/tcp
sudo fuser -k 443/tcp

# 4. Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# 5. Verify syntax in all enabled sites
sudo nginx -t -c /etc/nginx/sites-enabled/portfolio.conf

# 6. Start Nginx
sudo systemctl start nginx

# 7. Check status
sudo systemctl status nginx
```

## SSL/TLS Issues

### SSL Certificate Generation Fails

**Symptom**: Certbot fails to generate certificate

**Solutions**:

```bash
# 1. Check DNS is pointing to server
dig yourdomain.com
nslookup yourdomain.com

# 2. Ensure port 80 is accessible
curl http://yourdomain.com
# Should return content or redirect to HTTPS

# 3. Check firewall
sudo ufw status | grep 80
sudo ufw allow 80/tcp

# 4. Check Nginx is serving on port 80
sudo netstat -tulpn | grep :80

# 5. Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# 6. Try with verbose output
sudo certbot --nginx -d yourdomain.com --verbose

# 7. Check Certbot logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Mixed Content Warnings

**Symptom**: Browser shows mixed content warning

**Solutions**:

```bash
# 1. Check all resources are loaded over HTTPS
# View browser console (F12)
# Look for "Mixed Content" warnings

# 2. Update resources to use HTTPS
# Change: http://example.com/script.js
# To: https://example.com/script.js
# Or use protocol-relative: //example.com/script.js

# 3. Add Content-Security-Policy header
sudo nano /etc/nginx/snippets/security-headers.conf
# Add: add_header Content-Security-Policy "upgrade-insecure-requests" always;

# 4. Test configuration
sudo nginx -t

# 5. Reload Nginx
sudo systemctl reload nginx
```

### Certificate Expiring Soon

**Symptom**: Certificate about to expire

**Solutions**:

```bash
# 1. Check certificate expiry
sudo certbot certificates

# 2. Test renewal process
sudo certbot renew --dry-run

# 3. Renew certificates manually
sudo certbot renew

# 4. Check Certbot timer is active
sudo systemctl status certbot.timer

# 5. Enable timer if disabled
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# 6. Check renewal logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Invalid SSL Certificate

**Symptom**: Browser shows "Your connection is not private"

**Solutions**:

```bash
# 1. Check certificate validity
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates

# 2. Check certificate matches domain
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -subject

# 3. Verify Nginx is using correct certificate
sudo nano /etc/nginx/sites-available/portfolio.conf
# Check ssl_certificate and ssl_certificate_key paths

# 4. Test Nginx config
sudo nginx -t

# 5. Reload Nginx
sudo systemctl reload nginx

# 6. Clear browser cache
# Or test in incognito/private mode
```

## Docker Issues

### Container Won't Start

**Symptom**: Docker container exits immediately

**Solutions**:

```bash
# 1. Check container logs
docker-compose logs recipe_web

# 2. Check container status
docker-compose ps

# 3. Check for port conflicts
sudo netstat -tulpn | grep :5002

# 4. Verify environment variables
docker-compose config
# Shows resolved configuration

# 5. Check .env file exists and is valid
cat .env
# Verify all required variables are set

# 6. Rebuild container
docker-compose up -d --build --force-recreate

# 7. Run container interactively to debug
docker-compose run recipe_web /bin/bash
```

### Container Can't Connect to Database

**Symptom**: Application shows database connection error

**Solutions**:

```bash
# 1. Check if database container is running
docker ps | grep db

# 2. Check if containers are on same network
docker network inspect recipe-app_backend
# Verify both web and db containers are listed

# 3. Check database logs
docker-compose logs recipe_db

# 4. Verify database credentials in .env
cat .env
# Check POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB

# 5. Test database connection from web container
docker exec -it recipe_web /bin/bash
# Then try: psql -h db -U recipe_user -d recipe_db

# 6. Check if database is ready
docker exec recipe_db pg_isready

# 7. Restart containers in correct order
docker-compose down
docker-compose up -d db
# Wait 10 seconds
docker-compose up -d web
```

### Out of Disk Space

**Symptom**: "No space left on device" error

**Solutions**:

```bash
# 1. Check disk usage
df -h

# 2. Check Docker disk usage
docker system df

# 3. Remove unused containers
docker container prune -f

# 4. Remove unused images
docker image prune -a -f

# 5. Remove unused volumes (CAUTION: May delete data)
docker volume prune -f
# Better: Remove specific unused volume
docker volume ls
docker volume rm volume_name

# 6. Remove all unused Docker resources
docker system prune -a -f

# 7. Check logs taking up space
sudo du -sh /var/log/*
sudo journalctl --vacuum-size=100M

# 8. Check large files
sudo du -ah / | sort -rh | head -20
```

### Docker Network Issues

**Symptom**: Containers can't communicate

**Solutions**:

```bash
# 1. List networks
docker network ls

# 2. Inspect network
docker network inspect recipe-app_backend

# 3. Verify containers are on correct network
docker inspect recipe_web | grep NetworkMode
docker inspect recipe_db | grep NetworkMode

# 4. Recreate networks
docker-compose down
docker-compose up -d

# 5. Test connectivity between containers
docker exec recipe_web ping recipe_db
docker exec recipe_web nc -zv recipe_db 5432
```

## Application Issues

### Application Crashes

**Symptom**: Container keeps restarting

**Solutions**:

```bash
# 1. Check logs
docker-compose logs -f recipe_web

# 2. Check resource usage
docker stats

# 3. Increase resource limits in docker-compose.yml
mem_limit: 512m  # Increase from 384m

# 4. Check for uncaught exceptions in code
# Review application logs

# 5. Run container without restart policy
docker-compose up recipe_web
# This keeps container running to see error

# 6. Check dependencies are installed
docker exec recipe_web pip list
```

### Slow Response Times

**Symptom**: Application takes long to respond

**Solutions**:

```bash
# 1. Check resource usage
docker stats
htop

# 2. Check if hitting memory limits
docker inspect recipe_web | grep Memory

# 3. Increase Gunicorn workers
# In docker-compose.yml:
command: gunicorn -w 6 -b 0.0.0.0:5002 run:app

# 4. Enable Nginx caching
sudo nano /etc/nginx/sites-available/recipe-subdomain.conf
# Add caching directives

# 5. Check database query performance
docker exec -it recipe_db psql -U recipe_user -d recipe_db
# Run: EXPLAIN ANALYZE SELECT ...;

# 6. Check network latency
ping localhost
```

### Environment Variables Not Loaded

**Symptom**: Application can't find configuration

**Solutions**:

```bash
# 1. Check .env file exists
ls -la .env

# 2. Verify env_file directive in docker-compose.yml
cat docker-compose.yml | grep env_file

# 3. Check environment variables in container
docker exec recipe_web env | grep POSTGRES

# 4. Rebuild container
docker-compose down
docker-compose up -d --build

# 5. Use docker-compose config to verify
docker-compose config
```

## Database Issues

### Database Won't Start

**Symptom**: Database container exits or won't start

**Solutions**:

```bash
# 1. Check logs
docker-compose logs recipe_db

# 2. Check if volume is corrupted
docker volume inspect recipe-app_postgres_data

# 3. Check file permissions
docker exec recipe_db ls -la /var/lib/postgresql/data/

# 4. Try starting with fresh volume (CAUTION: Deletes data)
docker-compose down
docker volume rm recipe-app_postgres_data
docker-compose up -d

# 5. Check disk space
df -h

# 6. Check if port is in use
sudo netstat -tulpn | grep :5432
```

### Can't Connect to Database

**Symptom**: Connection refused or authentication failed

**Solutions**:

```bash
# 1. Check if database is running
docker ps | grep db

# 2. Check database logs
docker-compose logs recipe_db

# 3. Verify credentials
docker exec -it recipe_db env | grep POSTGRES

# 4. Test connection
docker exec -it recipe_db psql -U recipe_user -d recipe_db

# 5. Check if database is ready
docker exec recipe_db pg_isready

# 6. Reset password (PostgreSQL)
docker exec -it recipe_db psql -U postgres
# ALTER USER recipe_user WITH PASSWORD 'new_password';

# 7. Check network connectivity
docker network inspect recipe-app_backend
```

### Database Corruption

**Symptom**: Database errors, can't query data

**Solutions**:

```bash
# 1. Check database integrity (PostgreSQL)
docker exec recipe_db psql -U recipe_user -d recipe_db -c "SELECT pg_stat_database.datname, pg_size_pretty(pg_database_size(pg_stat_database.datname)) FROM pg_stat_database;"

# 2. Restore from backup
cat backup.sql | docker exec -i recipe_db psql -U recipe_user -d recipe_db

# 3. Repair database (PostgreSQL)
docker exec recipe_db psql -U postgres -c "REINDEX DATABASE recipe_db;"

# 4. Check disk space
df -h

# 5. If severe, recreate database
docker-compose down
docker volume rm recipe-app_postgres_data
# Restore from backup
docker-compose up -d
```

## Security Issues

### Server Under Attack

**Symptom**: High CPU usage, many failed login attempts

**Solutions**:

```bash
# 1. Check Fail2Ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# 2. Check for banned IPs
sudo fail2ban-client banned

# 3. Check authentication logs
sudo grep "Failed password" /var/log/auth.log | tail -50

# 4. Ban specific IP manually
sudo fail2ban-client set sshd banip ATTACKER_IP

# 5. Lower maxretry in Fail2Ban
sudo nano /etc/fail2ban/jail.local
# maxretry = 2

# 6. Check Nginx access logs for unusual activity
sudo tail -1000 /var/log/nginx/access.log | grep -E "404|403|500"

# 7. Block IP range with UFW
sudo ufw deny from 203.0.113.0/24
```

### Fail2Ban Not Banning

**Symptom**: Attacks continue, IPs not getting banned

**Solutions**:

```bash
# 1. Check Fail2Ban is running
sudo systemctl status fail2ban

# 2. Check jail configuration
sudo fail2ban-client status sshd

# 3. Test filter against logs
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# 4. Check if using correct banaction
sudo nano /etc/fail2ban/jail.local
# banaction = ufw

# 5. Reload Fail2Ban
sudo fail2ban-client reload

# 6. Check Fail2Ban logs
sudo tail -f /var/log/fail2ban.log
```

### Suspicious Traffic

**Symptom**: Unknown IPs accessing server

**Solutions**:

```bash
# 1. Check access logs
sudo tail -1000 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -20

# 2. Check for specific patterns
sudo grep "404" /var/log/nginx/access.log | tail -50
sudo grep "exploit" /var/log/nginx/access.log

# 3. Block specific IPs
sudo ufw deny from SUSPICIOUS_IP

# 4. Enable additional Fail2Ban jails
sudo nano /etc/fail2ban/jail.local
# Enable nginx-badbots, nginx-404, etc.

# 5. Check for unauthorized access
sudo last | head -20
sudo lastb | head -20  # Failed logins
```

## Performance Issues

### High CPU Usage

**Symptom**: Server sluggish, high CPU load

**Solutions**:

```bash
# 1. Check overall CPU usage
top
htop

# 2. Check Docker container usage
docker stats

# 3. Identify high-CPU process
ps aux --sort=-%cpu | head -10

# 4. Check for infinite loops in application
docker-compose logs recipe_web | grep -i error

# 5. Increase resource limits
# Edit docker-compose.yml
cpus: 0.5  # Increase from 0.3

# 6. Check for cryptocurrency miners
ps aux | grep -i mine
```

### High Memory Usage

**Symptom**: Out of memory errors, swapping

**Solutions**:

```bash
# 1. Check memory usage
free -h

# 2. Check Docker usage
docker stats

# 3. Identify memory hogs
ps aux --sort=-%mem | head -10

# 4. Increase container memory limit
# Edit docker-compose.yml
mem_limit: 512m  # Increase from 384m

# 5. Clear cache
sync; echo 3 | sudo tee /proc/sys/vm/drop_caches

# 6. Restart services
docker-compose restart
sudo systemctl restart nginx
```

### Disk I/O Issues

**Symptom**: Slow file operations

**Solutions**:

```bash
# 1. Check disk I/O
iotop

# 2. Check disk usage
df -h

# 3. Check inode usage
df -i

# 4. Find large files
sudo find / -type f -size +100M -exec ls -lh {} \\; 2>/dev/null

# 5. Clean up logs
sudo journalctl --vacuum-size=100M
sudo find /var/log -type f -name "*.log" -size +100M

# 6. Optimize Docker volumes
docker system prune -a -f
```

## Diagnostic Commands

### System Information

```bash
# OS version
lsb_release -a

# Kernel version
uname -r

# System resources
free -h
df -h

# CPU info
lscpu

# Memory info
cat /proc/meminfo

# System load
uptime
```

### Network Diagnostics

```bash
# Network interfaces
ip addr show

# Routing table
ip route show

# Open ports
sudo netstat -tulpn

# DNS resolution
dig yourdomain.com
nslookup yourdomain.com

# Test connectivity
ping yourdomain.com
curl -I https://yourdomain.com

# Trace route
traceroute yourdomain.com
```

### Service Status

```bash
# Nginx
sudo systemctl status nginx

# Docker
sudo systemctl status docker

# Fail2Ban
sudo systemctl status fail2ban

# UFW
sudo ufw status verbose

# All services
systemctl list-units --type=service --state=running
```

### Log Files

```bash
# System logs
sudo journalctl -xe

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Authentication logs
sudo tail -f /var/log/auth.log

# Docker logs
docker-compose logs -f

# Fail2Ban logs
sudo tail -f /var/log/fail2ban.log
```

## Getting Help

If issues persist:

1. **Check documentation**: Review relevant docs in this repository
2. **Search logs**: Often errors contain exact cause
3. **Google error messages**: Many issues have known solutions
4. **Stack Overflow**: Search or ask questions
5. **GitHub Issues**: Open issue in this repository
6. **Official documentation**: Consult docs for specific tools

## Emergency Procedures

### Server Completely Unresponsive

1. Access DigitalOcean console
2. Power cycle droplet (last resort)
3. Access via recovery console
4. Check logs: `journalctl -xe`
5. Restart critical services

### Complete Service Outage

1. Take snapshot/backup immediately
2. Check all service statuses
3. Review recent changes
4. Rollback if needed
5. Restore from backup if necessary

---

**Remember**: Always backup before making major changes!
