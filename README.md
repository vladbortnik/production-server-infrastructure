# Production-Grade Multi-Application Server

A complete infrastructure setup for hosting multiple web applications on a single DigitalOcean droplet using Docker, Nginx, and comprehensive security measures.

![Production Server Infrastructure](assets/images/hero/server-setup-title-img.png)

[![SSL Rating](https://img.shields.io/badge/SSL%20Labs-A-brightgreen)](https://www.ssllabs.com/ssltest/)
[![Security Headers](https://img.shields.io/badge/Security%20Headers-A%2B-brightgreen)](https://securityheaders.com/)
[![HTTP Observatory](https://img.shields.io/badge/HTTP%20Observatory-A%2B-brightgreen)](https://observatory.mozilla.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Nginx](https://img.shields.io/badge/Nginx-Configured-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)

## 🌐 Live Demo

[View detailed project showcase](https://vladbortnik.dev/server-setup.html)

## 📑 Table of Contents

- [Live Demo](#-live-demo)
- [Overview](#-overview)
- [Motivation](#-motivation)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Key Features](#-key-features)
- [Project Outcomes](#-project-outcomes)
- [Docker Infrastructure](#-docker-infrastructure)
- [Nginx Configuration](#-nginx-configuration)
- [Security Implementation](#-security-hardening)
- [Challenges & Solutions](#-challenges--solutions)
- [Lessons Learned](#-lessons-learned)
- [Want to Build Something Similar?](#-want-to-build-something-similar)
- [Documentation](#-documentation)
- [Use Cases](#-use-cases)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

## 📋 Overview

This project demonstrates a production-grade server infrastructure capable of hosting:
- Static portfolio website
- Multiple Dockerized web applications (Flask/Gunicorn)
- Database services (PostgreSQL, MySQL)
- Secure SSL/TLS termination
- Advanced security hardening

## 💡 Motivation

As a backend developer, I wanted to deeply understand production infrastructure beyond managed platforms like Heroku or Vercel. This project was born from three key goals:

### Why I Built This

1. **Learn by Doing** - Move beyond tutorials to real production deployment challenges
2. **Cost Efficiency** - Host multiple applications on one $12/month droplet vs $50+/month on managed services
3. **Full Control** - Own the entire stack from DNS configuration to database optimization

### Why Not Use Managed Services?

| Aspect | This Setup | Heroku/Render | AWS Lightsail | Vercel |
|--------|------------|---------------|---------------|---------|
| **Monthly Cost** | $12 | $50+ | $30+ | $20+ |
| **Learning Value** | Deep infrastructure knowledge | Limited | Medium | Minimal |
| **Flexibility** | Complete control | Constrained | Good | Platform-specific |
| **Customization** | Unlimited | Limited | Good | Framework-locked |
| **Multi-App Hosting** | Yes (unlimited) | Per-app pricing | Yes | Limited |
| **DevOps Skills** | Comprehensive | Basic | Intermediate | Deployment only |

**The Trade-off:** More setup complexity in exchange for deeper understanding, complete control, and significant cost savings.

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

### Visual Architecture Diagram

![Server Architecture Diagram](assets/images/architecture/server-setup-diagram.webp)

*Interactive architecture showing the complete infrastructure from DigitalOcean hosting to external APIs, including security layers, Nginx routing, Docker containers, and database services.*

### DNS Configuration

![DNS Dashboard](assets/images/architecture/dns-dashboard.png)

*DigitalOcean DNS management showing A records for the main domain and subdomains, all pointing to the same droplet IP address.*

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

## 📊 Project Outcomes

### Security Ratings Achieved

<div align="center">

| SSL Labs | HTTP Observatory | Security Headers |
|----------|------------------|------------------|
| ![SSL Labs A](assets/images/security/ssl-lab-test-score.png) | ![HTTP Observatory A+](assets/images/security/http-observatory-benchmark-score.png) | ![Security Headers A](assets/images/security/security-headers-score.png) |
| **Grade: A** | **Grade: A+** | **Grade: A** |

</div>

### Performance & Cost Metrics

**Uptime & Reliability:**
- ✅ **99.9%+ uptime** over 6 months of operation
- ✅ **Response time**: <100ms for static content, <200ms for dynamic content
- ✅ **Zero security incidents** since deployment

**Cost Efficiency:**
- 💰 **$12/month** - Total infrastructure cost
- 📊 **3 applications** - Hosted on single droplet
- 🔄 **~$4/app/month** - Actual cost per application
- 📈 **70% cost savings** vs managed platforms ($50+/month equivalent)

**Resource Utilization:**
- 🧮 **65% RAM usage** - 1.3GB out of 2GB allocated
- ⚙️ **40% CPU usage** - Average load under normal traffic
- 💾 **8GB disk usage** - 32% of 25GB SSD capacity
- 🐳 **6 Docker containers** - Running across 2 networks

### What This Demonstrates

**Technical Skills:**
- ✅ Production-grade infrastructure design and implementation
- ✅ Advanced Docker networking and container orchestration
- ✅ Nginx configuration for reverse proxy and load balancing
- ✅ Comprehensive security hardening (SSL A+, CSP, Fail2Ban)
- ✅ DNS management and subdomain configuration
- ✅ Linux server administration (Ubuntu 24.04 LTS)

**DevOps Practices:**
- ✅ Infrastructure as Code mindset
- ✅ Security-first approach
- ✅ Cost optimization strategies
- ✅ Real-world problem-solving
- ✅ Documentation and knowledge sharing

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

## 📚 Want to Build Something Similar?

This repository documents a completed production infrastructure. The setup process involves manual server configuration, security hardening, and application deployment.

**If you'd like to replicate this setup, comprehensive guides are available:**

- 📖 **[Complete Deployment Guide](docs/deployment-guide.md)** - Step-by-step instructions from server provisioning to application deployment
- 🏛️ **[Architecture Details](docs/architecture.md)** - Technical deep-dive into system design and network topology
- 🔒 **[Security Setup](security/)** - Hardening procedures, SSL configuration, and firewall rules
- 🐛 **[Troubleshooting Guide](docs/troubleshooting.md)** - Common issues and solutions

**Quick Overview:**
```bash
# High-level steps (see deployment guide for details)
1. Provision DigitalOcean droplet (Ubuntu 24.04 LTS)
2. Configure DNS records
3. Install Nginx, Docker, Certbot, UFW, Fail2Ban
4. Deploy applications via Docker Compose
5. Configure SSL certificates with Let's Encrypt
6. Apply security hardening
```

**Note:** This is not a plug-and-play solution. It requires understanding of Linux, Docker, Nginx, and networking concepts. Estimated setup time: 4-6 hours for experienced developers.

## 📊 Performance Metrics

- **SSL Labs Score**: A
- **HTTP Observatory**: A+
- **Security Headers**: A+
- **Uptime**: 99.9%+
- **Response Time**: <100ms (static content)

## 🔧 Configuration Highlights

### 🐳 Docker Infrastructure

![Docker Architecture](assets/images/docker/docker-diagram.webp)

*Docker network segregation showing frontend/backend network isolation, resource management, and database port protection.*

**Network Segregation:**
- **Frontend Network**: Public-facing web services accessible from Nginx
- **Backend Network**: Database-only access (isolated from internet)
- **Port Mapping**: Only necessary ports exposed (e.g., 5002:5002, 5001:5001)
- **Security**: Database ports (5432, 3306) not exposed to host or internet

![Docker Compose Configuration](assets/images/docker/docker-compose.png)

*docker-compose.yml showing service definitions, network configuration, resource limits, and volume mounts.*

![Docker Container Status](assets/images/docker/docker-ps.png)

*Running containers with port mappings, status, and resource allocation.*

![Docker Stats](assets/images/docker/docker-stats.png)

*Real-time resource usage showing memory, CPU, and network I/O for each container.*

**Resource Management:**
- **Memory Limit**: 384MB per container
- **Memory Reservation**: 192MB guaranteed
- **CPU Quota**: 0.3 cores allocated
- **Volume Persistence**: Named volumes for database data

### ⚡ Nginx Configuration

![Nginx Reverse Proxy](assets/images/nginx/reverse-proxy.png)

*Nginx as a reverse proxy forwarding requests to Docker containers while handling SSL termination.*

![Nginx Load Balancer](assets/images/nginx/load-balancer.png)

*Load balancing configuration distributing traffic across multiple backend servers.*

![Nginx Server Blocks](assets/images/nginx/server-blocks.png)

*Virtual host configuration enabling multiple domains on a single server.*

**Configuration Features:**
- **Reverse Proxy**: Routes traffic to appropriate Docker containers
- **SSL Termination**: Handles HTTPS encryption/decryption
- **Load Balancing**: Distributes traffic for high availability
- **Server Blocks**: Multi-domain hosting (portfolio, recipe, bookfinder)
- **Caching**: Static content caching for improved performance
- **Security Headers**: CSP, X-Frame-Options, HSTS, etc.

### 🔒 Security Headers
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

## 🔧 Challenges & Solutions

### Challenge 1: Database Port Exposure Risk
**Problem:** Initial Docker setup exposed PostgreSQL (5432) and MySQL (3306) ports directly to the host machine, creating a potential security vulnerability.

**Solution:**
- Implemented Docker network segregation with separate frontend and backend networks
- Backend network accessible only to web application containers
- Database ports remain internal to Docker network, never exposed to host
- Result: Databases completely isolated from internet access

**Learning:** Defense in depth requires multiple layers. Even with firewall rules, unexposed ports eliminate entire attack vectors.

---

### Challenge 2: SSL Certificate Automation
**Problem:** Manual SSL certificate renewal every 90 days is error-prone and causes downtime if forgotten.

**Solution:**
- Configured Certbot systemd timer for automatic renewal checks twice daily
- Set up renewal hooks to reload Nginx after certificate updates
- Implemented monitoring to verify timer execution
- Created backup procedures for certificate files

**Learning:** Automation isn't just about convenience—it's about reliability. Scheduled renewals eliminated certificate expiration incidents.

---

### Challenge 3: Resource Management on Limited Hardware
**Problem:** 2GB RAM droplet hosting multiple applications risked memory exhaustion and container crashes.

**Solution:**
- Set memory limits (384MB) and reservations (192MB) per container
- Configured CPU quotas (0.3 cores) to prevent CPU hogging
- Implemented container restart policies
- Monitored resource usage with `docker stats`
- Result: Stable operation at 65% RAM usage with headroom for traffic spikes

**Learning:** Constraints drive optimization. Explicit resource limits prevent cascading failures and make scaling decisions data-driven.

---

### Challenge 4: Nginx Configuration for Multiple Apps
**Problem:** Hosting three different applications (static site + two Docker apps) on subdomains required complex routing.

**Solution:**
- Created separate server blocks for each subdomain
- Configured reverse proxy directives with proper headers
- Set up SSL for each subdomain
- Implemented path-based routing where needed
- Used location blocks for optimized static file serving

**Learning:** Nginx's flexibility shines in multi-app scenarios. Well-structured configs are easier to maintain than monolithic configurations.

---

### Challenge 5: Docker Network Communication
**Problem:** Initial attempts at container-to-container communication failed due to network misconfiguration.

**Solution:**
- Created custom bridge networks instead of default network
- Assigned services to appropriate networks in docker-compose
- Used service names for DNS resolution within Docker networks
- Documented network topology in architecture diagrams

**Learning:** Docker's built-in DNS resolves service names automatically on custom networks. Understanding Docker networking fundamentals is crucial.

---

## 📝 Lessons Learned

### Technical Insights

**1. Network Security Through Isolation**
Docker network segregation proved more effective than firewall rules alone. The backend network architecture prevents database access even if other security layers fail. This "defense in depth" approach provides peace of mind and demonstrates enterprise-grade thinking.

**2. Resource Management is About Stability, Not Just Limits**
Setting explicit memory and CPU limits wasn't just about preventing overconsumption—it provided predictable behavior under load. Memory reservations guaranteed minimum resources, while limits prevented runaway processes. This made the system's behavior consistent and debuggable.

**3. Security Headers Dramatically Improve Ratings**
Adding Content Security Policy, X-Frame-Options, and HSTS headers took security ratings from B to A+. The implementation effort was minimal (one Nginx config file), but the security improvement was substantial. Headers are low-hanging fruit for security hardening.

**4. Automation Reduces Operational Burden**
Certbot's automatic renewal timer eliminated certificate expiration concerns. Fail2Ban automatically blocks malicious IPs. Docker restart policies handle container failures. Each automation reduced potential failure points and operational overhead.

**5. Documentation is a Force Multiplier**
Creating comprehensive documentation during setup made troubleshooting faster and knowledge transfer easier. Architecture diagrams clarified complex concepts. Step-by-step guides enabled reproducibility. Documentation transformed this from a one-off project into a learning resource.

### DevOps Practices

**Infrastructure as Code Mindset**
Even though this isn't fully automated with Terraform or Ansible, documenting configurations in Git provides version control, traceability, and reproducibility. This approach bridges manual setup and full IaC.

**Monitoring Before Scaling**
Understanding current resource utilization (65% RAM, 40% CPU) informs scaling decisions with data rather than guesswork. Monitoring tools like `docker stats` and Nginx logs provide visibility into system health.

**Security First, Not Security Later**
Implementing UFW, Fail2Ban, SSL, and security headers from day one created a secure foundation. Retrofitting security is harder than building it in from the start.

**Cost-Performance Trade-offs**
A $12/month droplet performs admirably for moderate traffic. Knowing when to optimize vs when to scale vertically vs when to scale horizontally comes from understanding current limits and costs.

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
Software Engineer | DevOps Enthusiast
[vladbortnik.dev](https://vladbortnik.dev)

---

⭐ If you find this project helpful, consider giving it a star!
