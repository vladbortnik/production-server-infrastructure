# Nginx Configuration

This directory contains Nginx server configurations for hosting multiple domains with SSL/TLS, reverse proxy, and security hardening.

## Directory Structure

```
nginx/
├── README.md                      # This file
├── sites-available/
│   ├── portfolio.conf             # Main portfolio website (static)
│   ├── recipe-subdomain.conf      # Recipe app reverse proxy
│   └── bookfinder-subdomain.conf  # BookFinder app reverse proxy
└── security-headers.conf          # Security headers snippet
```

## Features

### 🔒 SSL/TLS Configuration (A+ Rating)
- **TLS 1.2 and 1.3** only (no legacy protocols)
- **Strong cipher suites** with perfect forward secrecy
- **OCSP stapling** for improved SSL performance
- **Automatic HTTP to HTTPS redirect**

### 🛡️ Security Headers (A+ Rating)
- **Content-Security-Policy** - XSS protection
- **X-Frame-Options** - Clickjacking protection
- **X-Content-Type-Options** - MIME sniffing protection
- **Referrer-Policy** - Referrer information control
- **Permissions-Policy** - Feature/API usage control
- **HSTS** - Force HTTPS connections

### ⚡ Performance Optimization
- **HTTP/2** support
- **Static asset caching** with long expiration
- **Proxy buffering** for reverse proxy
- **Compression** (gzip/brotli)

### 🔄 Reverse Proxy
- Routes traffic to backend Flask/Gunicorn applications
- Proper header forwarding (X-Real-IP, X-Forwarded-For)
- SSL termination at Nginx level
- WebSocket support

## Installation

### 1. Copy Configuration Files

**Security headers snippet:**
```bash
sudo cp security-headers.conf /etc/nginx/snippets/security-headers.conf
```

**Server configurations:**
```bash
sudo cp sites-available/*.conf /etc/nginx/sites-available/
```

### 2. Enable Sites

```bash
# Enable portfolio site
sudo ln -s /etc/nginx/sites-available/portfolio.conf /etc/nginx/sites-enabled/

# Enable recipe subdomain
sudo ln -s /etc/nginx/sites-available/recipe-subdomain.conf /etc/nginx/sites-enabled/

# Enable bookfinder subdomain
sudo ln -s /etc/nginx/sites-available/bookfinder-subdomain.conf /etc/nginx/sites-enabled/
```

### 3. Test Configuration

```bash
sudo nginx -t
```

### 4. Reload Nginx

```bash
sudo systemctl reload nginx
```

## SSL Certificate Setup

### Using Certbot (Let's Encrypt)

**Install Certbot:**
```bash
sudo apt install certbot python3-certbot-nginx -y
```

**Generate certificates:**

```bash
# Main domain
sudo certbot --nginx -d vladbortnik.dev -d www.vladbortnik.dev

# Recipe subdomain
sudo certbot --nginx -d recipe.vladbortnik.dev

# BookFinder subdomain
sudo certbot --nginx -d bookfinder.vladbortnik.dev
```

**Auto-renewal:**
Certbot automatically sets up a systemd timer for renewal. Check it with:
```bash
sudo systemctl status certbot.timer
```

**Manual renewal test:**
```bash
sudo certbot renew --dry-run
```

## Configuration Customization

### Update Domain Names

Replace `vladbortnik.dev` with your domain in all configuration files:

```bash
# In each .conf file
server_name yourdomain.com www.yourdomain.com;
```

### Update SSL Certificate Paths

After generating certificates with Certbot, paths will be automatically configured. Manual format:
```nginx
ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
```

### Customize Security Headers

Edit `security-headers.conf` to match your application's needs. For example, if you use external CDNs:

```nginx
# Allow external scripts from CDN
add_header Content-Security-Policy "default-src 'self'; script-src 'self' https://cdn.example.com;" always;
```

### Adjust Reverse Proxy Ports

If your applications run on different ports:

```nginx
# Change port in location block
location / {
    proxy_pass http://localhost:YOUR_PORT;
    ...
}
```

## Server Block Types

### Static Website (portfolio.conf)
- Serves static HTML/CSS/JS files
- Optimized caching for assets
- Direct file serving

### Reverse Proxy (recipe/bookfinder.conf)
- Proxies requests to backend applications
- SSL termination
- Header forwarding
- Buffer configuration

## Load Balancing (Optional)

To add load balancing across multiple backend servers:

```nginx
# Define upstream block
upstream recipe_backend {
    least_conn;  # Load balancing method
    server 127.0.0.1:5002;
    server 127.0.0.1:5003;
    server 127.0.0.1:5004;
}

# Update proxy_pass
location / {
    proxy_pass http://recipe_backend;
    ...
}
```

**Load balancing methods:**
- `least_conn` - Least number of active connections
- `ip_hash` - Session persistence based on client IP
- `round_robin` - Default, distributes evenly

## Useful Commands

### Check Nginx Status
```bash
sudo systemctl status nginx
```

### View Error Logs
```bash
sudo tail -f /var/log/nginx/error.log
```

### View Access Logs
```bash
# All access logs
sudo tail -f /var/log/nginx/access.log

# Specific site
sudo tail -f /var/log/nginx/portfolio_access.log
sudo tail -f /var/log/nginx/recipe_access.log
```

### Test Configuration
```bash
sudo nginx -t
```

### Reload Configuration
```bash
sudo systemctl reload nginx
```

### Restart Nginx
```bash
sudo systemctl restart nginx
```

### Check Nginx Version
```bash
nginx -v
```

## Security Testing

### Test SSL Configuration
```bash
# Using SSL Labs (online)
https://www.ssllabs.com/ssltest/analyze.html?d=yourdomain.com

# Using testssl.sh (local)
./testssl.sh yourdomain.com
```

### Test Security Headers
```bash
# Using securityheaders.com (online)
https://securityheaders.com/?q=https://yourdomain.com

# Using curl (local)
curl -I https://yourdomain.com
```

### Test HTTP Observatory
```bash
# Online tool
https://observatory.mozilla.org/
```

## Troubleshooting

### 502 Bad Gateway
- Check if backend application is running
- Verify correct port in proxy_pass
- Check application logs

```bash
# Check if application is listening
sudo netstat -tulpn | grep :5002

# Check if process is running
ps aux | grep gunicorn
```

### 404 Not Found (Static Site)
- Verify root directory path
- Check file permissions
- Ensure index.html exists

```bash
# Check permissions
ls -la /var/www/vladbortnik.dev/html/

# Set correct permissions
sudo chown -R www-data:www-data /var/www/vladbortnik.dev/
sudo chmod -R 755 /var/www/vladbortnik.dev/
```

### SSL Certificate Errors
- Verify certificate files exist
- Check certificate validity
- Ensure correct paths in configuration

```bash
# Check certificate
sudo certbot certificates

# Check certificate expiration
echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates
```

### Configuration Syntax Errors
```bash
# Test configuration
sudo nginx -t

# Check specific file
sudo nginx -t -c /etc/nginx/sites-available/portfolio.conf
```

## Performance Tuning

### Enable Gzip Compression

Add to `/etc/nginx/nginx.conf`:
```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;
```

### Enable Brotli Compression (Optional)
```bash
sudo apt install nginx-module-brotli -y
```

### Adjust Worker Processes
In `/etc/nginx/nginx.conf`:
```nginx
worker_processes auto;
worker_connections 1024;
```

## Best Practices

✅ **Always test configuration before reload**
```bash
sudo nginx -t && sudo systemctl reload nginx
```

✅ **Keep security headers updated**
- Review CSP regularly
- Update based on application changes

✅ **Monitor logs regularly**
- Check for unusual patterns
- Identify performance issues

✅ **Backup configurations**
```bash
sudo tar -czf nginx-backup-$(date +%Y%m%d).tar.gz /etc/nginx/
```

✅ **Use separate log files per site**
- Easier troubleshooting
- Better analytics

✅ **Disable server tokens**
In `/etc/nginx/nginx.conf`:
```nginx
server_tokens off;
```

## Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
