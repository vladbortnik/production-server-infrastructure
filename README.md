# Production-Grade Multi-Application Server Infrastructure

Real-world Nginx and Docker configurations from a production server hosting multiple Flask applications on a single DigitalOcean droplet.

![Server Infrastructure](assets/images/hero/server-setup-title-img-overlay.jpg)

<div align="center">

[![SSL Rating](https://img.shields.io/badge/SSL%20Labs-A-brightgreen)](https://www.ssllabs.com/ssltest/)
[![Security Headers](https://img.shields.io/badge/Security%20Headers-A-brightgreen)](https://securityheaders.com/)
[![HTTP Observatory](https://img.shields.io/badge/HTTP%20Observatory-A%2B-brightgreen)](https://observatory.mozilla.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[🌐 Live Demo](https://vladbortnik.dev) • [📖 Configs](#configuration-files) • [🔒 Security](#security)

</div>

---

## What This Repository Contains

This repository provides **production-tested configuration files** from my actual multi-application server setup:

- ✅ **2 Nginx configurations**: Simple reverse proxy + load-balanced setup
- ✅ **2 Docker Compose files**: Single instance + 3-instance load-balanced
- ✅ **Database migration script**: Automatic Flask-Migrate execution
- ✅ **SSL/TLS guide**: DNS-01 challenge for wildcard certificates
- ✅ **Security configs**: TLS 1.3, security headers, A+ ratings

**Not included**: Generic examples or theoretical explanations. Every configuration here is extracted from real, working production servers.

---

## Architecture

<div align="center">
  <img src="assets/images/architecture/server-setup-diagram.webp" width="800px" alt="Production Server Architecture">
  <br><br>
  <em>Single DigitalOcean droplet running Nginx + Docker, hosting 3 applications on subdomains</em>
</div>

### Infrastructure Overview

**Single Server Setup:**
- **Host**: DigitalOcean Droplet (Ubuntu 24.04 LTS, 2GB RAM, 1 vCPU)
- **Web Server**: Nginx (reverse proxy, SSL termination, load balancing)
- **Containerization**: Docker + Docker Compose
- **Applications**: 3 Flask apps (Portfolio, Recipe App, BookFinder)
- **Databases**: PostgreSQL 16.4, MySQL
- **SSL/TLS**: Let's Encrypt with wildcard certificate

### DNS Configuration

<div align="center">
  <img src="assets/images/architecture/dns-dashboard.png" width="700px" alt="DNS A Records Configuration">
  <br><br>
  <em>All subdomains point to the same droplet IP. Nginx routes traffic based on Host header.</em>
</div>

**Domain structure:**
- `vladbortnik.dev` → Portfolio (static site served by Nginx)
- `recipe.vladbortnik.dev` → Recipe App (Dockerized Flask + PostgreSQL)
- `bookfinder.vladbortnik.dev` → BookFinder App (Dockerized Flask + MySQL)

---

## Tech Stack

**Infrastructure:**
- Ubuntu 24.04 LTS
- Nginx (reverse proxy + load balancer)
- Docker & Docker Compose
- DigitalOcean DNS

**Application:**
- Flask web framework
- Gunicorn WSGI server (4 workers per instance)
- PostgreSQL 16.4
- MySQL

**Security:**
- Let's Encrypt SSL/TLS (wildcard certificate via DNS-01 challenge)
- TLS 1.3 only
- Security headers (HSTS, CSP, X-Frame-Options, etc.)
- UFW firewall
- Fail2Ban

---

## Repository Structure

```
production-server-infrastructure/
├── README.md                           # This guide
├── LICENSE                             # MIT License
│
├── nginx/                              # Nginx configuration files
│   ├── recipe-simple.conf              # Single backend server
│   └── recipe-loadbalanced.conf        # 3 servers with ip_hash load balancing
│
├── docker/                             # Docker Compose configurations
│   ├── simple/
│   │   ├── docker-compose.yml          # 1 web + db + auto migrations
│   │   └── scripts/
│   │       └── wait-for-migrations.sh  # Database migration automation
│   └── loadbalanced/
│       └── docker-compose.yml          # 3 web instances + db with network segregation
│
├── docs/
│   └── ssl-setup.md                    # SSL/TLS configuration guide
│
└── assets/images/                      # Architecture diagrams and screenshots
```

---

## Configuration Files

### Simple Setup (Single Instance)

**Purpose:** Development, staging, or low-traffic production applications.

#### Docker Compose Configuration

[`docker/simple/docker-compose.yml`](docker/simple/docker-compose.yml)

```yaml
services:
  web:
    build: .
    command: gunicorn -w 4 -b 0.0.0.0:5002 run:app
    ports:
      - "5002:5002"
    depends_on:
      - db
      - migration
    restart: unless-stopped

  migration:
    build: .
    command: ./scripts/wait-for-migrations.sh
    depends_on:
      - db
    restart: "no"  # Runs once and exits

  db:
    image: postgres:16.4
    ports:
      - "5432:5432"  # ⚠️ Database port exposed to host
    restart: unless-stopped
```

**Key characteristics:**
- **1 web container** with Gunicorn (4 workers)
- **Automatic migrations** via dedicated migration service
- **Database port exposed** (`5432:5432`) for easy debugging
- **No network segregation** - uses default Docker network
- **No resource limits** - simpler configuration

**Migration Script:** [`docker/simple/scripts/wait-for-migrations.sh`](docker/simple/scripts/wait-for-migrations.sh)

This Bash script waits for PostgreSQL to be ready, then runs Flask-Migrate commands automatically (`flask db init`, `flask db migrate`, `flask db upgrade`).

#### Nginx Configuration

[`nginx/recipe-simple.conf`](nginx/recipe-simple.conf)

Nginx acts as a reverse proxy, forwarding HTTPS requests to the Flask application on port 5002. Learn more about [Nginx reverse proxy configuration](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/).

```nginx
# HTTP → HTTPS redirect
server {
    listen 80;
    server_name your-app.your-domain.com;
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server with reverse proxy
server {
    listen 443 ssl http2;

    # TLS 1.3 only (maximum security)
    ssl_protocols TLSv1.3;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Reverse proxy to Flask app
    location / {
        proxy_pass http://127.0.0.1:5002;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Usage:**
```bash
cd docker/simple
docker-compose up -d
```

---

### Load-Balanced Setup (3 Instances)

**Purpose:** Production environments requiring high availability and horizontal scaling.

#### Nginx Load Balancer Configuration

[`nginx/recipe-loadbalanced.conf`](nginx/recipe-loadbalanced.conf)

<div align="center">
  <img src="assets/images/nginx/load-balancer.png" width="750px" alt="Nginx Upstream Block">
  <br><br>
  <em>Nginx upstream configuration with ip_hash algorithm for session persistence</em>
</div>

```nginx
upstream recipe_app {
    ip_hash;  # Same client IP → same backend server

    server 127.0.0.1:5002 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:5003 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:5004 max_fails=3 fail_timeout=30s;
}

server {
    listen 443 ssl http2;
    # ... SSL configuration ...

    location / {
        proxy_pass http://recipe_app;  # Forward to upstream group
        # ... proxy headers ...
    }
}
```

**Why `ip_hash`?** The `ip_hash` directive ensures the same client IP always connects to the same backend server, maintaining session state without requiring shared session storage (like Redis). This is crucial for stateful Flask applications that store session data locally.

Learn more about [Nginx load balancing algorithms](https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/) and the [upstream module](https://nginx.org/en/docs/http/ngx_http_upstream_module.html).

**Health checks:**
- `max_fails=3`: Mark server unavailable after 3 failed attempts
- `fail_timeout=30s`: Wait 30 seconds before retrying

#### Docker Compose with Network Segregation

[`docker/loadbalanced/docker-compose.yml`](docker/loadbalanced/docker-compose.yml)

<div align="center">
  <img src="assets/images/docker/docker-diagram.webp" width="750px" alt="Docker Network Architecture">
  <br><br>
  <em>Network segregation: Frontend (Internet-accessible) vs Backend (database-only)</em>
</div>

```yaml
networks:
  frontend:  # Internet-accessible
  backend:   # Database access only

services:
  web1:
    build: .
    command: gunicorn -w 4 -b 0.0.0.0:5002 run:app
    networks:
      - frontend  # Can communicate with Nginx
      - backend   # Can communicate with database
    ports:
      - "5002:5002"
    mem_limit: 384m
    mem_reservation: 192m
    cpus: 0.3
    restart: unless-stopped

  web2:
    # ... same config, port 5003:5002 ...

  web3:
    # ... same config, port 5004:5002 ...

  db:
    image: postgres:16.4
    networks:
      - backend  # ONLY accessible via backend network
    # ports:     # ✅ Port NOT exposed to host
    #   - "5432:5432"
    mem_limit: 384m
    mem_reservation: 192m
    cpus: 0.3
```

**Network segregation explained:** The database is connected ONLY to the `backend` network, making it inaccessible from the Internet even if the firewall fails. Web containers connect to both networks, allowing them to receive traffic from Nginx (frontend) and query the database (backend). Learn more about [Docker Compose networking](https://docs.docker.com/compose/networking/).

<div align="center">
  <img src="assets/images/docker/networks-diagram.png" width="700px" alt="Docker Network Topology">
  <br><br>
  <em>Network topology showing 5 bridge networks including frontend/backend segregation</em>
</div>

**Resource limits explained:** Each container has explicit memory and CPU limits to prevent resource starvation. If one container experiences a memory leak and hits its 384MB limit, Docker kills only that container while others continue running. Learn more about [Docker resource constraints](https://docs.docker.com/config/containers/resource_constraints/).

**Why these values?**
- 2GB total RAM ÷ 3 web instances ≈ 666MB per app
- 384MB limit leaves 30% buffer for OS and traffic spikes
- 192MB reservation guarantees minimum resources

**⚠️ Migration note:** The automatic migration service doesn't work reliably with multiple instances. Run migrations manually before starting:
```bash
docker-compose run --rm web1 flask db upgrade
```

**Usage:**
```bash
cd docker/loadbalanced
docker-compose up -d
docker stats  # Monitor resource usage
```

---

## Simple vs Load-Balanced Comparison

| Feature | Simple Setup | Load-Balanced Setup |
|---------|-------------|---------------------|
| **Web instances** | 1 | 3 |
| **Networks** | Default (no segregation) | `frontend` + `backend` |
| **Database port** | Exposed (`5432:5432`) | Not exposed (internal only) |
| **Resource limits** | None | 384MB mem, 0.3 CPU per container |
| **Auto migrations** | Yes (dedicated service) | No (manual: `docker-compose run --rm web1 flask db upgrade`) |
| **Load balancing** | No | Yes (`ip_hash` algorithm) |
| **High availability** | No (single point of failure) | Yes (survives 1-2 instance failures) |
| **Best for** | Development, staging, small apps | Production with traffic spikes |

---

## SSL/TLS Configuration

### DNS-01 Challenge for Wildcard Certificates

For servers hosting multiple applications on subdomains, **DNS-01 challenge** is the optimal SSL validation method.

**Why DNS-01 over HTTP-01?**

| Feature | HTTP-01 | DNS-01 |
|---------|---------|--------|
| **Wildcard certificates** | ❌ Not supported | ✅ Supported (`*.yourdomain.com`) |
| **Port 80 requirement** | ✅ Must be open | ❌ Not required |
| **Multiple subdomains** | ❌ One cert per subdomain | ✅ One cert for all |

**My setup:** A single wildcard certificate (`*.vladbortnik.dev`) covers all subdomains: `recipe.vladbortnik.dev`, `bookfinder.vladbortnik.dev`, and any future additions.

**Detailed guide:** [`docs/ssl-setup.md`](docs/ssl-setup.md) explains DNS-01 vs HTTP-01 challenges with examples.

**External resources:**
- [Let's Encrypt Challenge Types](https://letsencrypt.org/docs/challenge-types/) - Official documentation
- [Certbot Documentation](https://eff-certbot.readthedocs.io/) - Installation and automation

---

## Security

This infrastructure achieves A/A+ security ratings through modern TLS configuration and comprehensive security headers.

### Security Test Results

<div align="center">

| SSL Labs | HTTP Observatory | Security Headers |
|----------|------------------|------------------|
| ![SSL Labs A](assets/images/security/ssl-lab-test-score.png) | ![HTTP Observatory A+](assets/images/security/http-observatory-benchmark-score.png) | ![Security Headers A](assets/images/security/security-headers-score.png) |
| **Grade: A** | **Grade: A+** | **Grade: A** |

</div>

**Test your own setup:**
- [SSL Labs Server Test](https://www.ssllabs.com/ssltest/) - Comprehensive SSL/TLS analysis
- [Mozilla Observatory](https://observatory.mozilla.org/) - Security configuration scanner
- [Security Headers Test](https://securityheaders.com/) - HTTP header analyzer

### TLS 1.3 Configuration

Both Nginx configurations use TLS 1.3 exclusively for maximum security and performance:

```nginx
ssl_protocols TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;
```

**Benefits of TLS 1.3:**
- Faster handshakes (1-RTT vs 2-RTT in TLS 1.2)
- Removal of vulnerable cipher suites
- Always-encrypted metadata
- Forward secrecy by default

Generate your own secure SSL configuration at [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/).

### Security Headers

All responses include these security headers:

```nginx
# HSTS - Forces HTTPS for 2 years
add_header Strict-Transport-Security "max-age=63072000" always;

# Prevents clickjacking attacks
add_header X-Frame-Options "SAMEORIGIN" always;

# Prevents MIME-type sniffing
add_header X-Content-Type-Options "nosniff" always;

# Referrer policy for privacy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Permissions policy (disable sensitive browser features)
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;

# Content Security Policy (customize per application)
add_header Content-Security-Policy "default-src 'self' data:; img-src 'self' data: blob:; font-src 'self' data:;" always;
```

Learn more about [OWASP Secure Headers recommendations](https://owasp.org/www-project-secure-headers/) and [Mozilla security headers documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers#security).

### Additional Security Measures

<div align="center">
  <img src="assets/images/security/fail2ban.png" width="600px" alt="Fail2Ban Logs">
  <br><br>
  <em>Fail2Ban automatically bans IPs after repeated failed authentication attempts</em>
</div>

**UFW Firewall:**
```bash
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP (redirects to HTTPS)
ufw allow 443/tcp  # HTTPS
ufw enable
```

**Fail2Ban:** Monitors logs and automatically bans malicious IP addresses after repeated failed SSH or HTTP authentication attempts.

---

## Key Learnings from Production

### 1. Database Port Isolation

**Simple setup:** Database port `5432:5432` is exposed to the host, making it accessible from the Internet (protected only by firewall).

**Load-balanced setup:** Database port is **not exposed**. The database exists only on the `backend` network, accessible solely by web containers. Even if the firewall fails, the database remains isolated.

### 2. ip_hash for Session Persistence

The `ip_hash` load balancing algorithm routes the same client IP to the same backend server, maintaining session state without requiring shared session storage like Redis. This is simpler for stateful Flask applications.

### 3. Resource Limits Prevent Cascading Failures

Without resource limits, a memory leak in one container can consume all available RAM, crashing the database and other applications. With limits (`mem_limit: 384m`), Docker kills only the problematic container while others continue running.

### 4. Network Segregation > Firewall Alone

Network segregation provides defense in depth. The database is unreachable from the Internet by design, not just by configuration. This architectural approach is more reliable than firewall rules alone.

### 5. DNS-01 Simplifies Multi-Subdomain SSL

A single wildcard certificate (`*.yourdomain.com`) via DNS-01 challenge covers all subdomains, simplifying certificate management and renewal.

### 6. Auto Migrations Don't Scale

The automatic migration service works well with a single instance but can cause race conditions with multiple instances. Manual migrations are more reliable for load-balanced setups.

---

## Usage

### Prerequisites

- Ubuntu 24.04 LTS server (2GB RAM minimum)
- Domain name with DNS access
- Basic knowledge of Linux, Docker, and Nginx

### Quick Start

```bash
# 1. Install dependencies
apt update && apt upgrade -y
apt install nginx docker.io docker-compose certbot ufw fail2ban

# 2. Clone this repository
git clone https://github.com/yourusername/production-server-infrastructure.git
cd production-server-infrastructure

# 3. Choose your setup
cd docker/simple              # For single instance
# OR
cd docker/loadbalanced        # For load-balanced setup

# 4. Copy and customize docker-compose.yml for your application

# 5. Deploy
docker-compose up -d

# 6. Configure Nginx
cp nginx/recipe-simple.conf /etc/nginx/sites-available/your-app
# Edit the file to match your domain
ln -s /etc/nginx/sites-available/your-app /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# 7. Obtain SSL certificate
certbot --nginx -d your-app.your-domain.com

# 8. Configure firewall
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp
ufw enable
```

---

## Documentation

- [`nginx/recipe-simple.conf`](nginx/recipe-simple.conf) - Single instance reverse proxy
- [`nginx/recipe-loadbalanced.conf`](nginx/recipe-loadbalanced.conf) - Load-balanced configuration
- [`docker/simple/docker-compose.yml`](docker/simple/docker-compose.yml) - Simple Docker setup
- [`docker/loadbalanced/docker-compose.yml`](docker/loadbalanced/docker-compose.yml) - Load-balanced Docker setup
- [`docker/simple/scripts/wait-for-migrations.sh`](docker/simple/scripts/wait-for-migrations.sh) - Migration automation script
- [`docs/ssl-setup.md`](docs/ssl-setup.md) - SSL/TLS configuration guide

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

## Connect With Me

[![Portfolio](https://img.shields.io/badge/Portfolio-vladbortnik.dev-0EA5E9?style=for-the-badge&logo=google-chrome&logoColor=white)](https://vladbortnik.dev)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/vladbortnik)
[![Twitter](https://img.shields.io/badge/Twitter-@vladbortnik__dev-1DA1F2?style=for-the-badge&logo=x&logoColor=white)](https://x.com/vladbortnik_dev)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/vladbortnik)
[![Contact](https://img.shields.io/badge/Contact_Me-Get_In_Touch-00C853?style=for-the-badge&logo=gmail&logoColor=white)](https://vladbortnik.dev/contact.html)

<br>

**Built with real production experience by [Vlad Bortnik](https://vladbortnik.dev)**

*Software Engineer | DevOps Enthusiast | Infrastructure Architect*

<br>

⭐ **Found this helpful? Star the repo!** It helps others discover production-ready configurations.

</div>
