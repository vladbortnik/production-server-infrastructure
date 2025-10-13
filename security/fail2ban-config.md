# Fail2Ban Configuration

Complete guide for setting up Fail2Ban to protect your server from brute-force attacks and unauthorized access attempts.

## Overview

Fail2Ban is an intrusion prevention system that:
- **Monitors log files** for malicious activity
- **Bans IP addresses** after failed login attempts
- **Works with UFW/iptables** to block traffic
- **Protects SSH, Nginx, and other services**

## How It Works

```
1. Service generates logs (SSH, Nginx, etc.)
     ↓
2. Fail2Ban monitors logs for patterns (failed logins, 404 errors, etc.)
     ↓
3. Matches pattern against filters
     ↓
4. Counts failures from same IP
     ↓
5. If threshold exceeded → Ban IP for specified time
     ↓
6. Updates firewall (UFW/iptables) to block IP
```

## Installation

### 1. Install Fail2Ban

```bash
# Update package list
sudo apt update

# Install Fail2Ban
sudo apt install fail2ban -y

# Verify installation
fail2ban-client --version
```

### 2. Start and Enable Service

```bash
# Start Fail2Ban
sudo systemctl start fail2ban

# Enable on boot
sudo systemctl enable fail2ban

# Check status
sudo systemctl status fail2ban
```

## Configuration

### Configuration File Structure

```
/etc/fail2ban/
├── fail2ban.conf          # Main configuration (don't edit)
├── fail2ban.local         # Local overrides (create this)
├── jail.conf              # Jail definitions (don't edit)
├── jail.local             # Local jail overrides (create this)
├── filter.d/              # Filter patterns
│   ├── sshd.conf
│   ├── nginx-http-auth.conf
│   └── ...
├── action.d/              # Actions to take
│   ├── iptables.conf
│   ├── ufw.conf
│   └── ...
└── jail.d/                # Additional jail configurations
```

**Important:**
- Never edit `.conf` files directly (they get overwritten on updates)
- Create `.local` files for customization
- `.local` files override `.conf` files

### Create Local Configuration

```bash
# Copy default jail configuration
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit local configuration
sudo nano /etc/fail2ban/jail.local
```

## Basic Configuration

### Default Jail Settings

Edit `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
# Ban time (seconds) - 1 hour
bantime = 3600

# Find time window (seconds) - 10 minutes
# If 'maxretry' failures occur within 'findtime', IP is banned
findtime = 600

# Maximum retry attempts before ban
maxretry = 5

# Action to take when banning
# ban & send email notification
banaction = ufw
# Or for iptables: banaction = iptables-multiport

# Email notifications (optional)
destemail = your-email@example.com
sendername = Fail2Ban
mta = sendmail

# Action shortcuts
action = %(action_)s
# action_ = ban only
# action_mw = ban & send email with whois report
# action_mwl = ban & send email with whois & log lines
```

### SSH Protection (sshd)

In `/etc/fail2ban/jail.local`:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3        # Ban after 3 failed attempts
bantime = 1h        # Ban for 1 hour
findtime = 10m      # Within 10 minute window
```

**Time format:**
- `s` = seconds
- `m` = minutes
- `h` = hours
- `d` = days

### Nginx Protection

#### Nginx HTTP Auth

```ini
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 1h
```

#### Nginx 404 Errors (Scanner/Bot Detection)

```ini
[nginx-noscript]
enabled = true
port = http,https
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
bantime = 24h
```

#### Nginx Bad Bots

```ini
[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 24h
```

#### Nginx Proxy (Exploit Attempts)

```ini
[nginx-noproxy]
enabled = true
port = http,https
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 24h
```

## Custom Filters

### Create Custom Nginx Filter

Create filter for excessive 404 errors:

```bash
sudo nano /etc/fail2ban/filter.d/nginx-404.conf
```

**Content:**
```ini
[Definition]
failregex = ^<HOST> - .* "(GET|POST|HEAD).*HTTP.*" 404 .*$
ignoreregex =
```

**Create jail:**

In `/etc/fail2ban/jail.local`:

```ini
[nginx-404]
enabled = true
port = http,https
filter = nginx-404
logpath = /var/log/nginx/access.log
maxretry = 20       # Allow some 404s
bantime = 1h
findtime = 10m
```

### Create Custom SSH Filter (Port Scan Detection)

```bash
sudo nano /etc/fail2ban/filter.d/ssh-portscan.conf
```

**Content:**
```ini
[Definition]
failregex = ^.* Did not receive identification string from <HOST>$
            ^.* Connection closed by <HOST> port .* \[preauth\]$
ignoreregex =
```

**Create jail:**

```ini
[ssh-portscan]
enabled = true
port = ssh
filter = ssh-portscan
logpath = /var/log/auth.log
maxretry = 2
bantime = 24h
```

## Advanced Configuration

### Permanent Bans

Ban IP permanently after repeated offenses:

```bash
sudo nano /etc/fail2ban/jail.local
```

**Add recidive jail:**
```ini
[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
bantime = -1        # Permanent ban (-1 or 10y)
findtime = 1d       # 1 day lookback
maxretry = 3        # 3 bans within 1 day = permanent ban
```

### Whitelist IPs

Ignore specific IPs (trusted sources):

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 203.0.113.5
```

**Format:**
- Single IP: `203.0.113.5`
- CIDR range: `192.168.1.0/24`
- Multiple IPs: space-separated

### Email Notifications

#### Configure Email

```ini
[DEFAULT]
destemail = admin@example.com
sendername = Fail2Ban Alert
mta = sendmail

# Use action with email
action = %(action_mwl)s
```

**Actions:**
- `%(action_)s` - Ban only (no email)
- `%(action_mw)s` - Ban + email with WHOIS
- `%(action_mwl)s` - Ban + email with WHOIS + log lines

#### Install Mail Transfer Agent

```bash
# Install sendmail
sudo apt install sendmail -y

# Or use msmtp (lighter alternative)
sudo apt install msmtp msmtp-mta -y
```

### Integration with UFW

Ensure Fail2Ban uses UFW for banning:

```ini
[DEFAULT]
banaction = ufw
```

**Or for iptables:**
```ini
[DEFAULT]
banaction = iptables-multiport
```

## Managing Fail2Ban

### Service Management

```bash
# Start Fail2Ban
sudo systemctl start fail2ban

# Stop Fail2Ban
sudo systemctl stop fail2ban

# Restart Fail2Ban
sudo systemctl restart fail2ban

# Reload configuration
sudo fail2ban-client reload

# Check status
sudo systemctl status fail2ban
```

### Jail Management

```bash
# List all jails
sudo fail2ban-client status

# Check specific jail status
sudo fail2ban-client status sshd

# Start jail
sudo fail2ban-client start sshd

# Stop jail
sudo fail2ban-client stop sshd

# Reload jail
sudo fail2ban-client reload sshd
```

### Ban Management

```bash
# View banned IPs for jail
sudo fail2ban-client status sshd

# Manually ban IP
sudo fail2ban-client set sshd banip 203.0.113.100

# Manually unban IP
sudo fail2ban-client set sshd unbanip 203.0.113.100

# Unban all IPs from jail
sudo fail2ban-client unban --all
```

### Log Monitoring

```bash
# View Fail2Ban logs
sudo tail -f /var/log/fail2ban.log

# Search for bans
sudo grep "Ban" /var/log/fail2ban.log

# Search for unbans
sudo grep "Unban" /var/log/fail2ban.log

# Check specific IP
sudo grep "203.0.113.100" /var/log/fail2ban.log
```

## Testing Configuration

### Test Filter Pattern

```bash
# Test filter against log file
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# Test custom filter
sudo fail2ban-regex /var/log/nginx/access.log /etc/fail2ban/filter.d/nginx-404.conf
```

**Output shows:**
- Lines matched
- Ignored lines
- Match details

### Test Jail Configuration

```bash
# Reload Fail2Ban to apply changes
sudo fail2ban-client reload

# Check if jails are running
sudo fail2ban-client status

# Check specific jail
sudo fail2ban-client status sshd
```

### Simulate Attack (Testing)

**SSH brute-force test:**
```bash
# From another machine, attempt failed logins
ssh baduser@your-server-ip  # Repeat 3+ times

# Check if IP gets banned
sudo fail2ban-client status sshd
```

**Nginx 404 test:**
```bash
# Generate 404 errors
for i in {1..25}; do curl http://your-server.com/nonexistent-page; done

# Check if IP gets banned
sudo fail2ban-client status nginx-404
```

## Monitoring and Statistics

### Current Bans

```bash
# List all currently banned IPs
sudo fail2ban-client banned

# Check specific jail
sudo fail2ban-client status sshd
```

**Output:**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 5
|  |- Total failed:     127
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 3
   |- Total banned:     42
   `- Banned IP list:   203.0.113.100 203.0.113.101 203.0.113.102
```

### Ban Statistics

```bash
# View Fail2Ban log
sudo cat /var/log/fail2ban.log | grep "Ban"

# Count total bans
sudo grep -c "Ban" /var/log/fail2ban.log

# Top 10 banned IPs
sudo grep "Ban" /var/log/fail2ban.log | awk '{print $NF}' | sort | uniq -c | sort -nr | head -10
```

### UFW/iptables Verification

```bash
# Check UFW rules (look for Fail2Ban entries)
sudo ufw status numbered

# Check iptables rules
sudo iptables -L fail2ban-sshd -n
```

## Troubleshooting

### Jail Not Starting

**Check configuration syntax:**
```bash
sudo fail2ban-client -d
```

**Check jail status:**
```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

**Common issues:**
- Incorrect log file path
- Missing filter file
- Syntax errors in configuration

### IP Not Getting Banned

**Test filter against logs:**
```bash
sudo fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```

**Check if enough failures occurred:**
```bash
# View failed attempts
sudo grep "Failed password" /var/log/auth.log | tail -20
```

**Verify jail is enabled:**
```bash
sudo fail2ban-client status sshd
```

### Can't Unban IP

**Manually remove from UFW:**
```bash
sudo ufw status numbered
sudo ufw delete [rule-number]
```

**Manually remove from iptables:**
```bash
sudo iptables -L fail2ban-sshd -n --line-numbers
sudo iptables -D fail2ban-sshd [line-number]
```

**Restart Fail2Ban:**
```bash
sudo systemctl restart fail2ban
```

### Email Notifications Not Working

**Test sendmail:**
```bash
echo "Test email" | mail -s "Test" your-email@example.com
```

**Check mail logs:**
```bash
sudo tail -f /var/log/mail.log
```

**Verify mta setting:**
```ini
[DEFAULT]
mta = sendmail
```

## Security Best Practices

### ✅ Use Aggressive SSH Settings

```ini
[sshd]
enabled = true
maxretry = 3
bantime = 1h
findtime = 10m
```

### ✅ Enable Recidive Jail

Permanently ban repeat offenders:

```ini
[recidive]
enabled = true
bantime = -1
maxretry = 3
findtime = 1d
```

### ✅ Whitelist Trusted IPs

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 your-office-ip
```

### ✅ Monitor Logs Regularly

```bash
# Weekly check
sudo fail2ban-client status
sudo grep "Ban" /var/log/fail2ban.log | tail -50
```

### ✅ Combine with SSH Key Authentication

```bash
# Disable password authentication in /etc/ssh/sshd_config
PasswordAuthentication no
```

### ✅ Use Longer Ban Times for Sensitive Services

```ini
[sshd]
bantime = 24h  # Longer ban for SSH

[nginx-http-auth]
bantime = 1h   # Shorter for web services
```

## Backup and Restore

### Backup Configuration

```bash
# Backup Fail2Ban configuration
sudo tar -czf /root/fail2ban-backup-$(date +%Y%m%d).tar.gz /etc/fail2ban/

# Backup banned IPs database
sudo cp /var/lib/fail2ban/fail2ban.sqlite3 /root/fail2ban-db-backup-$(date +%Y%m%d).sqlite3
```

### Restore Configuration

```bash
# Extract backup
sudo tar -xzf /root/fail2ban-backup-YYYYMMDD.tar.gz -C /

# Restart Fail2Ban
sudo systemctl restart fail2ban
```

## Complete Configuration Example

### /etc/fail2ban/jail.local

```ini
[DEFAULT]
# Ban settings
bantime = 1h
findtime = 10m
maxretry = 5

# Whitelist
ignoreip = 127.0.0.1/8 ::1

# Actions
banaction = ufw
action = %(action_)s

# Email (optional)
# destemail = admin@example.com
# sendername = Fail2Ban
# mta = sendmail
# action = %(action_mwl)s

# SSH Protection
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h

# SSH Port Scan
[ssh-portscan]
enabled = true
port = ssh
filter = ssh-portscan
logpath = /var/log/auth.log
maxretry = 2
bantime = 24h

# Nginx HTTP Auth
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 1h

# Nginx 404
[nginx-404]
enabled = true
port = http,https
filter = nginx-404
logpath = /var/log/nginx/access.log
maxretry = 20
bantime = 1h

# Nginx Bad Bots
[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 24h

# Recidive (Repeat Offenders)
[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
bantime = 1w
findtime = 1d
maxretry = 3
```

## Additional Resources

- [Fail2Ban Official Documentation](https://www.fail2ban.org/)
- [Fail2Ban Manual](https://fail2ban.readthedocs.io/)
- [DigitalOcean Fail2Ban Guide](https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu)
- [Fail2Ban GitHub](https://github.com/fail2ban/fail2ban)
