# Production-Grade Multi-Application Server

A complete infrastructure setup for hosting multiple web applications on a single DigitalOcean droplet using Docker, Nginx, and comprehensive security measures.

[![SSL Rating](https://img.shields.io/badge/SSL%20Labs-A%2B-brightgreen)](https://www.ssllabs.com/ssltest/)
[![Security Headers](https://img.shields.io/badge/Security%20Headers-A%2B-brightgreen)](https://securityheaders.com/)
[![HTTP Observatory](https://img.shields.io/badge/HTTP%20Observatory-A%2B-brightgreen)](https://observatory.mozilla.org/)

## 🌐 Live Demo

[View detailed project showcase](https://vladbortnik.dev/server-setup.html)

## 📋 Overview

This project demonstrates a production-grade server infrastructure capable of hosting:
- Static portfolio website
- Multiple Dockerized web applications (Flask/Gunicorn)
- Database services (PostgreSQL, MySQL)
- Secure SSL/TLS termination
- Advanced security hardening

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        DigitalOcean Droplet                      │
│                         Ubuntu 24.04 LTS                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐                                     │
│  │ Fail2Ban │  │   UFW    │  ◄─── Security Layer                │
│  │          │  │ Firewall │                                      │
│  └──────────┘  └──────────┘                                      │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Nginx Server                            │  │
│  │  • Reverse Proxy      • Load Balancing                     │  │
│  │  • SSL Termination    • Request Caching                    │  │
│  │  • Server Blocks      • Security Headers                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│          │                    │                    │             │
│          ▼                    ▼                    ▼             │
│  ┌────────────┐    ┌─────────────────┐  ┌─────────────────┐   │
│  │ Portfolio  │    │  Docker App #1  │  │  Docker App #2  │   │
│  │  Website   │    │  ┌───────────┐  │  │  ┌───────────┐  │   │
│  │  (Static)  │    │  │Flask/     │  │  │  │Flask/     │  │   │
│  │            │    │  │Gunicorn   │  │  │  │Gunicorn   │  │   │
│  └────────────┘    │  └─────┬─────┘  │  │  └─────┬─────┘  │   │
│                    │        │        │  │        │        │   │
│                    │  ┌─────▼─────┐  │  │  ┌─────▼─────┐  │   │
│                    │  │   MySQL   │  │  │  │PostgreSQL │  │   │
│                    │  └───────────┘  │  │  └───────────┘  │   │
│                    └─────────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   External APIs    │
                    │ • Azure Vision     │
                    │ • Spoonacular      │
                    └────────────────────┘
```

## 🛠️ Tech Stack

### Infrastructure
- **Hosting**: DigitalOcean Droplet (2GB RAM / 1vCPU / 25GB SSD)
- **OS**: Ubuntu 24.04 LTS
- **Web Server**: Nginx
- **Containerization**: Docker & Docker Compose
- **DNS**: DigitalOcean DNS Management

### Security
- **SSL/TLS**: Let's Encrypt (Certbot)
- **Firewall**: UFW (Uncomplicated Firewall)
- **Intrusion Prevention**: Fail2Ban
- **Security Headers**: CSP, X-Frame-Options, HSTS, etc.

### Applications
- **Web Framework**: Flask with Gunicorn
- **Databases**: PostgreSQL 16.4, MySQL
- **APIs**: Azure Vision API, Spoonacular API

## ✨ Key Features

### 🔒 Security Hardening
- **SSL/TLS A+ Rating**: Perfect forward secrecy, strong ciphers
- **Security Headers**: Content Security Policy, XSS protection
- **Firewall Configuration**: UFW with strict port rules
- **Intrusion Prevention**: Fail2Ban for SSH and HTTP protection
- **Automated SSL Renewal**: Certbot timer for certificate management

### 🐳 Docker Infrastructure
- **Network Segregation**: Frontend/backend network isolation
- **Resource Management**: Memory limits, CPU quotas
- **Volume Persistence**: Named volumes for database data
- **Port Isolation**: Database ports not exposed to internet

### ⚡ Nginx Configuration
- **Reverse Proxy**: Routes traffic to backend applications
- **Load Balancing**: Distributes traffic across services
- **Server Blocks**: Multi-domain hosting on single server
- **Caching**: Static content caching for performance
- **HTTP/2**: Modern protocol support

## 📁 Repository Structure

```
server-infrastructure/
├── README.md                      # This file
├── docker/                        # Docker configurations
│   ├── recipe-app/
│   │   └── docker-compose.yml
│   └── bookfinder-app/
│       └── docker-compose.yml
├── nginx/                         # Nginx configurations
│   ├── sites-available/
│   │   ├── portfolio.conf
│   │   ├── recipe-subdomain.conf
│   │   └── bookfinder-subdomain.conf
│   └── security-headers.conf
├── security/                      # Security documentation
│   ├── ufw-setup.md
│   ├── fail2ban-config.md
│   └── ssl-setup.md
├── docs/                          # Additional documentation
│   ├── architecture.md
│   ├── deployment-guide.md
│   └── troubleshooting.md
└── diagrams/                      # Architecture diagrams
```

## 🚀 Quick Start

### Prerequisites
- Ubuntu 24.04 LTS server
- Root or sudo access
- Domain name with DNS configured
- DigitalOcean account (or any VPS provider)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/server-infrastructure.git
cd server-infrastructure
```

2. **Install dependencies**
```bash
sudo apt update
sudo apt install nginx docker.io docker-compose certbot python3-certbot-nginx ufw fail2ban -y
```

3. **Configure Nginx**
```bash
sudo cp nginx/sites-available/* /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/portfolio.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

4. **Set up SSL**
```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

5. **Deploy applications**
```bash
cd docker/recipe-app
docker-compose up -d
```

See [Deployment Guide](docs/deployment-guide.md) for detailed instructions.

## 📊 Performance Metrics

- **SSL Labs Score**: A
- **HTTP Observatory**: A+
- **Security Headers**: A+
- **Uptime**: 99.9%+
- **Response Time**: <100ms (static content)

## 🔧 Configuration Highlights

### Docker Network Segregation
- **Frontend Network**: Public-facing web services
- **Backend Network**: Database-only access (isolated from internet)
- **Port Mapping**: Only necessary ports exposed (e.g., 5002:5002)

### Resource Management
- **Memory Limit**: 384MB per container
- **Memory Reservation**: 192MB guaranteed
- **CPU Quota**: 0.3 cores allocated

### Security Headers
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-eval'..." always;
```

## 📖 Documentation

- [Architecture Details](docs/architecture.md) - In-depth system design
- [Deployment Guide](docs/deployment-guide.md) - Step-by-step deployment
- [Security Setup](security/) - Security configuration guides
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## 🎯 Use Cases

This infrastructure setup is ideal for:
- Hosting multiple web applications on a budget
- Learning production-grade DevOps practices
- Portfolio/personal website with side projects
- Small business web presence
- Development and testing environments

## 🛡️ Security Best Practices

- ✅ Automated SSL certificate renewal
- ✅ Firewall rules (only ports 22, 80, 443 open)
- ✅ Fail2Ban for brute-force protection
- ✅ Security headers (CSP, HSTS, X-Frame-Options)
- ✅ Database port isolation from internet
- ✅ Regular security audits via SSL Labs & Observatory
- ✅ Docker network segregation

## 📝 Lessons Learned

- **Network Isolation**: Properly segregating frontend and backend networks prevents unauthorized database access
- **Resource Limits**: Setting memory/CPU limits prevents resource exhaustion
- **Security Headers**: CSP and other headers significantly improve security posture
- **Automated Renewals**: Certbot timer ensures SSL certificates never expire
- **Load Balancing**: Even with one server, Nginx load balancing prepares for future scaling

## 🤝 Contributing

This is a personal portfolio project, but suggestions and improvements are welcome! Feel free to:
- Open issues for questions or suggestions
- Submit pull requests for improvements
- Share your own infrastructure setups

## 📄 License

MIT License - feel free to use this configuration for your own projects.

## 🔗 Links

- [Live Portfolio](https://vladbortnik.dev)
- [Detailed Project Showcase](https://vladbortnik.dev/server-setup.html)
- [LinkedIn](https://linkedin.com/in/vladyslav-bortnik)
- [GitHub](https://github.com/vladbortnik)

## 📧 Contact

**Vlad Bortnik**
Backend Developer | DevOps Enthusiast
[vladbortnik.dev](https://vladbortnik.dev)

---

⭐ If you find this project helpful, consider giving it a star!
