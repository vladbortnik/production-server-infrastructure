# Deployment Documentation

This document provides comprehensive information about how this production server infrastructure was deployed and configured.

## Infrastructure Overview

**Hosting Provider:** DigitalOcean
**Droplet Specifications:**
- **RAM:** 2GB
- **CPU:** 1 vCPU (shared)
- **Storage:** 25GB SSD
- **Operating System:** Ubuntu 24.04 LTS
- **Monthly Cost:** $12/month

**Domain Management:** DigitalOcean DNS
**SSL Certificates:** Let's Encrypt (via Certbot)

---

## Deployment Architecture

### Multi-Application Setup
This server hosts 3 applications on a single droplet:

1. **Portfolio Website** (vladbortnik.dev)
   - Static site served directly by Nginx
   - Located: `/var/www/portfolio`

2. **Recipe App** (recipe.vladbortnik.dev)
   - Flask application in Docker container
   - PostgreSQL database
   - Subdomain routing via Nginx

3. **Book Finder App** (bookfinder.vladbortnik.dev)
   - Flask application in Docker container
   - MySQL database
   - Subdomain routing via Nginx

---

## Deployment Process

### Phase 1: Server Provisioning

1. **Create DigitalOcean Droplet**
   ```bash
   # Created via DigitalOcean web interface
   # Selected: Ubuntu 24.04 LTS, Basic plan, 2GB RAM/$12 month
   ```

2. **Initial Server Access**
   ```bash
   # SSH into server as root
   ssh root@<server-ip>

   # Update system packages
   apt update && apt upgrade -y
   ```

3. **Create Non-Root User**
   ```bash
   # Create user with sudo privileges
   adduser vlad
   usermod -aG sudo vlad

   # Setup SSH key authentication
   mkdir -p /home/vlad/.ssh
   cp ~/.ssh/authorized_keys /home/vlad/.ssh/
   chown -R vlad:vlad /home/vlad/.ssh
   chmod 700 /home/vlad/.ssh
   chmod 600 /home/vlad/.ssh/authorized_keys
   ```

---

### Phase 2: DNS Configuration

**Configured in DigitalOcean DNS:**

| Type | Hostname | Value | TTL |
|------|----------|-------|-----|
| A | @ | `<droplet-ip>` | 3600 |
| A | recipe | `<droplet-ip>` | 3600 |
| A | bookfinder | `<droplet-ip>` | 3600 |
| A | www | `<droplet-ip>` | 3600 |

**Nameservers pointed to DigitalOcean:**
- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

---

### Phase 3: Security Hardening

1. **UFW Firewall Setup**
   ```bash
   # Install and configure UFW
   apt install ufw

   # Allow SSH, HTTP, HTTPS
   ufw allow 22/tcp    # SSH
   ufw allow 80/tcp    # HTTP
   ufw allow 443/tcp   # HTTPS

   # Enable firewall
   ufw enable
   ```

2. **Fail2Ban Installation**
   ```bash
   # Install Fail2Ban for intrusion prevention
   apt install fail2ban

   # Configure jails for SSH and HTTP
   cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
   systemctl enable fail2ban
   systemctl start fail2ban
   ```

3. **SSH Hardening**
   ```bash
   # Edit /etc/ssh/sshd_config
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes

   # Restart SSH service
   systemctl restart sshd
   ```

---

### Phase 4: Software Installation

1. **Install Nginx**
   ```bash
   apt install nginx
   systemctl enable nginx
   systemctl start nginx
   ```

2. **Install Docker & Docker Compose**
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh

   # Add user to docker group
   usermod -aG docker vlad

   # Install Docker Compose
   apt install docker-compose-plugin
   ```

3. **Install Certbot**
   ```bash
   apt install certbot python3-certbot-nginx
   ```

---

### Phase 5: Application Deployment

1. **Deploy Portfolio Website**
   ```bash
   # Create directory
   mkdir -p /var/www/portfolio

   # Upload static files via SCP/Git
   # Configure Nginx server block
   ```

2. **Deploy Dockerized Applications**
   ```bash
   # Create project directories
   mkdir -p /home/vlad/apps/recipe-app
   mkdir -p /home/vlad/apps/bookfinder-app

   # Copy docker-compose.yml files
   # Pull/build Docker images
   docker compose up -d
   ```

---

### Phase 6: Nginx Configuration

**Server Blocks Created:**

1. `/etc/nginx/sites-available/portfolio.conf`
   - Main domain (vladbortnik.dev)
   - Static file serving

2. `/etc/nginx/sites-available/recipe-subdomain.conf`
   - Subdomain (recipe.vladbortnik.dev)
   - Reverse proxy to Docker container (port 5001)

3. `/etc/nginx/sites-available/bookfinder-subdomain.conf`
   - Subdomain (bookfinder.vladbortnik.dev)
   - Reverse proxy to Docker container (port 5002)

**Security Headers:**
- Created `/etc/nginx/snippets/security-headers.conf`
- Included in all server blocks
- Headers: CSP, X-Frame-Options, HSTS, X-Content-Type-Options, etc.

**Enable Sites:**
```bash
ln -s /etc/nginx/sites-available/portfolio.conf /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/recipe-subdomain.conf /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/bookfinder-subdomain.conf /etc/nginx/sites-enabled/

nginx -t
systemctl reload nginx
```

---

### Phase 7: SSL Certificate Setup

```bash
# Obtain certificates for all domains
certbot --nginx -d vladbortnik.dev -d www.vladbortnik.dev
certbot --nginx -d recipe.vladbortnik.dev
certbot --nginx -d bookfinder.vladbortnik.dev

# Verify auto-renewal
systemctl status certbot.timer
certbot renew --dry-run
```

**Automatic Renewal:**
- Certbot systemd timer runs twice daily
- Automatically renews certificates 30 days before expiration
- Reloads Nginx after successful renewal

---

### Phase 8: Docker Network Configuration

**Created Custom Networks:**

1. **Frontend Network**
   - Bridge driver
   - Internet access enabled
   - Connects: Nginx → Application containers

2. **Backend Network**
   - Bridge driver
   - **Internal only** (no internet access)
   - Connects: Application containers → Databases

**Resource Limits Applied:**
```yaml
deploy:
  resources:
    limits:
      memory: 384M
      cpus: '0.3'
    reservations:
      memory: 192M
```

---

## Monitoring & Maintenance

### Health Checks

**Docker Container Status:**
```bash
docker ps
docker stats
```

**Nginx Status:**
```bash
systemctl status nginx
nginx -t
```

**SSL Certificate Status:**
```bash
certbot certificates
```

**Firewall Status:**
```bash
ufw status verbose
```

**Fail2Ban Status:**
```bash
fail2ban-client status
fail2ban-client status sshd
```

### Log Locations

- **Nginx Access:** `/var/log/nginx/access.log`
- **Nginx Error:** `/var/log/nginx/error.log`
- **Docker Logs:** `docker logs <container-name>`
- **Fail2Ban:** `/var/log/fail2ban.log`
- **UFW:** `/var/log/ufw.log`

---

## Backup Strategy

**What to Backup:**
1. Docker volumes (database data)
2. Nginx configuration files
3. SSL certificates (`/etc/letsencrypt/`)
4. Application code and docker-compose files

**Backup Commands:**
```bash
# Database backup
docker exec postgres_container pg_dump -U user dbname > backup.sql

# Volume backup
docker run --rm -v volume_name:/data -v $(pwd):/backup ubuntu tar czf /backup/backup.tar.gz /data

# SSL certificates
tar czf letsencrypt-backup.tar.gz /etc/letsencrypt/
```

---

## Deployment Timeline

**Total Deployment Time:** ~6 hours

| Phase | Duration |
|-------|----------|
| Server provisioning & DNS | 30 min |
| Security hardening | 1 hour |
| Software installation | 30 min |
| Application deployment | 2 hours |
| Nginx configuration | 1 hour |
| SSL setup | 30 min |
| Testing & debugging | 1.5 hours |

---

## Lessons Learned

### What Went Well
- Docker network segregation provided excellent security isolation
- Certbot automation eliminated manual certificate management
- UFW + Fail2Ban combination provided strong security baseline
- Resource limits prevented container resource hogging

### Challenges Encountered
1. **Docker network DNS resolution** - Required using service names instead of localhost
2. **SSL certificate domain validation** - Needed to ensure DNS propagation before running Certbot
3. **Nginx configuration testing** - Multiple iterations to get reverse proxy headers correct
4. **Database persistence** - Initial setup used bind mounts; switched to named volumes

### Would Do Differently
- Implement Infrastructure as Code (Terraform/Ansible) for reproducibility
- Set up automated backups from day one
- Configure log rotation earlier to prevent disk space issues
- Implement monitoring (Prometheus/Grafana) sooner

---

## Future Improvements

**Short-term:**
- [ ] Add automated backup script with cron job
- [ ] Implement log aggregation (ELK stack or similar)
- [ ] Set up monitoring and alerting (Uptime Kuma, Prometheus)
- [ ] Configure CDN for static assets

**Long-term:**
- [ ] Migrate to Infrastructure as Code (Terraform)
- [ ] Implement CI/CD pipeline for application updates
- [ ] Add load balancing for horizontal scaling
- [ ] Set up staging environment

---

## Cost Breakdown

| Service | Monthly Cost |
|---------|-------------|
| DigitalOcean Droplet (2GB) | $12.00 |
| Domain registration (amortized) | $1.00 |
| SSL Certificates (Let's Encrypt) | $0.00 |
| **Total** | **$13.00/month** |

**Cost per application:** ~$4.33/month

**Comparison to managed platforms:**
- Heroku (3 apps): ~$50/month
- Render (3 apps): ~$45/month
- AWS Lightsail (comparable): ~$30/month

**Savings:** 60-75% compared to managed alternatives

---

## Support & Troubleshooting

**Common Issues:**

1. **Container won't start**
   - Check logs: `docker logs <container>`
   - Verify network: `docker network ls`
   - Check resources: `docker stats`

2. **502 Bad Gateway**
   - Verify application is running
   - Check Nginx upstream configuration
   - Verify Docker network connectivity

3. **SSL Certificate Error**
   - Check certificate expiration: `certbot certificates`
   - Test renewal: `certbot renew --dry-run`
   - Verify DNS records

---

## Contact & Resources

**Project Repository:** https://github.com/vladbortnik/production-server-infrastructure
**Live Demo:** https://vladbortnik.dev/server-setup.html
**Developer:** Vlad Bortnik (https://vladbortnik.dev)

**Official Documentation:**
- [DigitalOcean Droplets](https://docs.digitalocean.com/products/droplets/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
