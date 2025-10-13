# UFW (Uncomplicated Firewall) Setup

Complete guide for configuring UFW firewall on Ubuntu server to secure your production environment.

## Overview

UFW provides a simple interface for managing iptables firewall rules. This setup:
- **Blocks all incoming traffic** by default
- **Allows only essential ports** (SSH, HTTP, HTTPS)
- **Allows all outgoing traffic**
- **Protects against unauthorized access**

## Prerequisites

- Ubuntu 24.04 LTS server
- Root or sudo access
- SSH access to the server

## Installation

### 1. Install UFW

UFW is usually pre-installed on Ubuntu. If not:

```bash
sudo apt update
sudo apt install ufw -y
```

### 2. Verify Installation

```bash
ufw --version
```

## Initial Configuration

### 1. Set Default Policies

```bash
# Deny all incoming traffic by default
sudo ufw default deny incoming

# Allow all outgoing traffic by default
sudo ufw default allow outgoing
```

### 2. Allow SSH (CRITICAL - Do This First!)

**⚠️ WARNING:** Always allow SSH before enabling UFW, or you'll lock yourself out!

```bash
# Allow SSH on default port (22)
sudo ufw allow ssh

# Or specify port explicitly
sudo ufw allow 22/tcp

# If using custom SSH port (e.g., 2222)
sudo ufw allow 2222/tcp
```

### 3. Allow HTTP and HTTPS

```bash
# Allow HTTP (port 80)
sudo ufw allow http
# Or: sudo ufw allow 80/tcp

# Allow HTTPS (port 443)
sudo ufw allow https
# Or: sudo ufw allow 443/tcp

# Allow both HTTP and HTTPS with Nginx profile
sudo ufw allow 'Nginx Full'
```

### 4. Enable UFW

```bash
sudo ufw enable
```

**You'll see:**
```
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

Type `y` and press Enter (safe if you allowed SSH in step 2).

### 5. Verify Status

```bash
sudo ufw status verbose
```

**Expected output:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)                ALLOW IN    Anywhere (v6)
```

## Port Management

### Allow Specific Ports

```bash
# Allow single port
sudo ufw allow 8080/tcp

# Allow port range
sudo ufw allow 6000:6007/tcp

# Allow UDP port
sudo ufw allow 53/udp

# Allow from specific IP
sudo ufw allow from 203.0.113.4

# Allow from specific IP to specific port
sudo ufw allow from 203.0.113.4 to any port 22

# Allow from subnet
sudo ufw allow from 192.168.1.0/24
```

### Deny Specific Ports

```bash
# Deny specific port
sudo ufw deny 25/tcp

# Deny from specific IP
sudo ufw deny from 203.0.113.100
```

### Delete Rules

```bash
# List rules with numbers
sudo ufw status numbered

# Delete by number
sudo ufw delete 3

# Delete by rule specification
sudo ufw delete allow 8080/tcp
```

## Application Profiles

### List Available Profiles

```bash
sudo ufw app list
```

**Common profiles:**
- Nginx Full (ports 80, 443)
- Nginx HTTP (port 80)
- Nginx HTTPS (port 443)
- OpenSSH (port 22)

### View Profile Details

```bash
sudo ufw app info 'Nginx Full'
```

**Output:**
```
Profile: Nginx Full
Title: Web Server (Nginx, HTTP + HTTPS)
Description: Small, but very powerful and efficient web server

Ports:
  80,443/tcp
```

### Allow Application Profile

```bash
sudo ufw allow 'Nginx Full'
```

## Advanced Configuration

### Rate Limiting (SSH Brute-Force Protection)

Limit connection attempts to prevent brute-force attacks:

```bash
# Limit SSH connections (max 6 attempts in 30 seconds)
sudo ufw limit ssh

# Or for custom port
sudo ufw limit 2222/tcp
```

**How it works:**
- Tracks connection attempts
- Blocks IP after 6 attempts in 30 seconds
- Automatic unblock after ban period

### Logging

```bash
# Enable logging (default: low)
sudo ufw logging on

# Set logging level
sudo ufw logging low     # Default
sudo ufw logging medium  # More verbose
sudo ufw logging high    # Very verbose
sudo ufw logging full    # All packets

# Disable logging
sudo ufw logging off
```

**View logs:**
```bash
sudo tail -f /var/log/ufw.log
```

### Allow Localhost Communication

```bash
# Allow all on loopback interface
sudo ufw allow in on lo
sudo ufw allow out on lo
```

### Interface-Specific Rules

```bash
# Allow on specific interface
sudo ufw allow in on eth0 to any port 80

# Deny on specific interface
sudo ufw deny in on eth1 to any port 443
```

## Docker Compatibility

Docker can bypass UFW rules. To fix this:

### 1. Configure Docker to Use UFW

Edit Docker daemon configuration:

```bash
sudo nano /etc/docker/daemon.json
```

**Add:**
```json
{
  "iptables": false
}
```

**Or configure UFW to handle Docker:**

```bash
# Edit UFW configuration
sudo nano /etc/ufw/after.rules
```

**Add before the final COMMIT:**
```bash
# BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
```

**Restart UFW:**
```bash
sudo ufw reload
```

## Common Server Configurations

### Web Server (Nginx/Apache)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw limit ssh
sudo ufw enable
```

### Web Server + Database (Restricted)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'

# Only allow database access from specific IP (e.g., app server)
sudo ufw allow from 192.168.1.100 to any port 5432 proto tcp  # PostgreSQL
sudo ufw allow from 192.168.1.100 to any port 3306 proto tcp  # MySQL

sudo ufw limit ssh
sudo ufw enable
```

### Development Server (More Open)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 3000/tcp  # Node.js dev server
sudo ufw allow 5000/tcp  # Flask dev server
sudo ufw allow 8000/tcp  # Django dev server
sudo ufw limit ssh
sudo ufw enable
```

## Firewall Status and Monitoring

### Check Status

```bash
# Brief status
sudo ufw status

# Detailed status
sudo ufw status verbose

# Numbered rules (useful for deletion)
sudo ufw status numbered
```

### Monitor Blocked Traffic

```bash
# Enable logging if not already enabled
sudo ufw logging medium

# Watch logs in real-time
sudo tail -f /var/log/ufw.log

# Search for blocked traffic
sudo grep -i block /var/log/ufw.log

# Search for blocked traffic from specific IP
sudo grep -i "203.0.113.4" /var/log/ufw.log | grep -i block
```

### Statistics

```bash
# View raw iptables rules
sudo iptables -L -n -v

# View UFW rules
sudo ufw show raw
```

## Troubleshooting

### Can't SSH After Enabling UFW

**Problem:** Locked out of server

**Solution (from console access):**
```bash
# Disable UFW
sudo ufw disable

# Add SSH rule
sudo ufw allow ssh

# Re-enable UFW
sudo ufw enable
```

**Prevention:**
Always add SSH rule before enabling UFW!

### Service Not Accessible

**Check if port is allowed:**
```bash
sudo ufw status | grep PORT_NUMBER
```

**Allow the port:**
```bash
sudo ufw allow PORT_NUMBER/tcp
```

**Check if service is listening:**
```bash
sudo netstat -tulpn | grep PORT_NUMBER
```

### UFW Rules Not Working

**Reload UFW:**
```bash
sudo ufw reload
```

**Reset UFW (CAUTION - removes all rules):**
```bash
sudo ufw reset
# Then reconfigure from scratch
```

**Check UFW service status:**
```bash
sudo systemctl status ufw
```

**Restart UFW service:**
```bash
sudo systemctl restart ufw
```

### Docker Containers Not Accessible

See [Docker Compatibility](#docker-compatibility) section above.

### Can't Delete Rule

**List rules with numbers:**
```bash
sudo ufw status numbered
```

**Delete by number (from top to bottom):**
```bash
sudo ufw delete 5
sudo ufw delete 4
sudo ufw delete 3
```

## Security Best Practices

### ✅ Principle of Least Privilege

Only open ports that are absolutely necessary:

```bash
# Good: Only essential ports
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'

# Bad: Opening everything
sudo ufw allow 1:65535/tcp  # DON'T DO THIS!
```

### ✅ Use Rate Limiting for SSH

Prevent brute-force attacks:

```bash
sudo ufw limit ssh
```

### ✅ Restrict Database Access

Never expose databases to the internet:

```bash
# Bad: Database accessible from anywhere
sudo ufw allow 5432/tcp

# Good: Database only from application server
sudo ufw allow from 192.168.1.100 to any port 5432
```

### ✅ Regular Audits

Review firewall rules regularly:

```bash
# Monthly audit
sudo ufw status numbered

# Check for unnecessary rules
# Remove any rules that are no longer needed
```

### ✅ Enable Logging

Monitor blocked traffic:

```bash
sudo ufw logging medium
sudo tail -f /var/log/ufw.log
```

### ✅ Document Changes

Keep a record of firewall changes:

```bash
# Create firewall documentation
echo "$(date): Added rule for port 8080" >> /root/ufw-changelog.txt
```

## Backup and Restore

### Backup Rules

```bash
# Backup UFW rules
sudo cp /etc/ufw/user.rules /root/ufw-backup-$(date +%Y%m%d).rules
sudo cp /etc/ufw/user6.rules /root/ufw6-backup-$(date +%Y%m%d).rules

# Or backup entire UFW directory
sudo tar -czf /root/ufw-backup-$(date +%Y%m%d).tar.gz /etc/ufw/
```

### Restore Rules

```bash
# Disable UFW
sudo ufw disable

# Restore rules
sudo cp /root/ufw-backup-YYYYMMDD.rules /etc/ufw/user.rules
sudo cp /root/ufw6-backup-YYYYMMDD.rules /etc/ufw/user6.rules

# Enable UFW
sudo ufw enable
```

## Useful Commands Reference

```bash
# Status
sudo ufw status                    # Brief status
sudo ufw status verbose            # Detailed status
sudo ufw status numbered           # Numbered rules

# Enable/Disable
sudo ufw enable                    # Enable firewall
sudo ufw disable                   # Disable firewall
sudo ufw reload                    # Reload rules

# Allow
sudo ufw allow PORT                # Allow port
sudo ufw allow PORT/tcp            # Allow TCP port
sudo ufw allow PORT/udp            # Allow UDP port
sudo ufw allow from IP             # Allow from IP
sudo ufw allow 'App Name'          # Allow application

# Deny
sudo ufw deny PORT                 # Deny port
sudo ufw deny from IP              # Deny from IP

# Delete
sudo ufw delete NUM                # Delete by number
sudo ufw delete allow PORT         # Delete by specification

# Rate Limiting
sudo ufw limit ssh                 # Limit SSH connections

# Logging
sudo ufw logging on                # Enable logging
sudo ufw logging medium            # Set logging level
sudo ufw logging off               # Disable logging

# Application Profiles
sudo ufw app list                  # List profiles
sudo ufw app info 'App Name'       # Profile details

# Reset
sudo ufw reset                     # Reset all rules (CAUTION!)
```

## Additional Resources

- [UFW Official Documentation](https://help.ubuntu.com/community/UFW)
- [DigitalOcean UFW Essentials](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)
- [Ubuntu UFW Manual](http://manpages.ubuntu.com/manpages/focal/man8/ufw.8.html)
- [UFW with Docker](https://github.com/chaifeng/ufw-docker)
