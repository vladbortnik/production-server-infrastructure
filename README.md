# Production-Grade Multi-Application Server

A complete infrastructure setup for hosting multiple web applications on a single DigitalOcean droplet using Docker, Nginx, and comprehensive security measures.

![Production Server Infrastructure](assets/images/hero/server-setup-title-img-overlay.jpg)

<div align="center">

[![SSL Rating](https://img.shields.io/badge/SSL%20Labs-A-brightgreen)](https://www.ssllabs.com/ssltest/)
[![Security Headers](https://img.shields.io/badge/Security%20Headers-A%2B-brightgreen)](https://securityheaders.com/)
[![HTTP Observatory](https://img.shields.io/badge/HTTP%20Observatory-A%2B-brightgreen)](https://observatory.mozilla.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Nginx](https://img.shields.io/badge/Nginx-Configured-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com/)

<br>

🌐 **Live Demo:** [![View Showcase](https://img.shields.io/badge/View-Project_Showcase-0EA5E9?style=flat-square&logo=google-chrome&logoColor=white)](https://vladbortnik.dev/server-setup.html)

</div>

## 📑 Navigation

<table>
<tr><td>

### 🎯 Quick Start
- [At a Glance](#-at-a-glance)
- [Motivation](#-motivation)
- [Project Outcomes](#-project-outcomes)
- [Tech Stack](#-tech-stack)

### 🏗️ Technical Deep-Dive
- [Architecture Overview](#-architecture)
- [Hidden Database Pattern](#-the-hidden-database-pattern)
- [Load Balancing Intelligence](#-load-balancing-smarter-than-you-think)
- [Resource Management](#-resource-limits-prevent-disasters)

</td><td>

### 💡 Insights & Learning
- [Challenges & Solutions](#-challenges--solutions)
- [Lessons Learned](#-lessons-learned)
- [Security Journey](#-security-hardening)

### 📚 Resources & Community
- [Build Guide](#-want-to-build-something-similar)
- [Documentation](#-documentation)
- [Use Cases](#-use-cases)
- [Connect with Me](#-lets-connect)

</td></tr>
</table>

## 🎯 At a Glance

<div align="center">
  <img src="assets/images/architecture/server-setup-diagram.webp" width="800px" alt="Complete Production Infrastructure Architecture">
  <br><br>
  <strong>Complete production infrastructure on $12/month</strong><br>
  3 applications • A+ security ratings • 99.9% uptime • Full control over the stack
</div>

<br>

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

### DNS Configuration

<div align="center">
  <img src="assets/images/architecture/dns-dashboard.png" width="700px" alt="DNS Configuration Dashboard">
  <br>
  <em>DigitalOcean DNS management: A records for main domain and subdomains pointing to single droplet</em>
</div>

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

---

## 🔒 The Hidden Database Pattern

<div align="center">
  <img src="assets/images/docker/networks-diagram.png" width="750px" alt="Docker Network Segregation Architecture">
</div>

### How Docker Networks Protect Your Data

Here's a security insight most developers miss: **Your database doesn't need internet access.**

#### 🚨 The Problem

Default Docker setups expose database ports (5432, 3306) to the host machine. Even with firewall rules in place, this creates an unnecessary attack surface. If someone compromises your server, those ports become visible.

####  ✅ The Solution

Docker network segregation creates two isolated networks with different access levels:

| Network | Purpose | Internet Access | Who Can Connect |
|---------|---------|-----------------|-----------------|
| **Frontend** | Web services | ✅ Yes | Nginx → App containers |
| **Backend** | Databases only | ❌ No | App containers → Databases |

```yaml
# docker-compose.yml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # ← This is the magic line

services:
  web:
    networks:
      - frontend  # Can talk to Nginx
      - backend   # Can talk to database

  database:
    networks:
      - backend   # ONLY accessible via backend network
```

#### 🎯 The Result

**Database ports never touch the host machine.** Even if someone compromises the server, they can't see ports 5432 or 3306. From the WAN perspective, those ports literally don't exist.

> **Defense in Depth:** This pattern adds a security layer that works even if firewall rules fail. Multiple security layers compound, making each subsequent breach exponentially harder.

📂 **Explore:** [Docker configurations](docker/) | [Network setup guide](docs/architecture.md)

---

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

### 🐳 Docker Infrastructure Overview

<div align="center">
  <img src="assets/images/docker/docker-diagram.webp" width="700px" alt="Complete Docker Architecture">
  <br>
  <em>Full Docker infrastructure showing network segregation, container relationships, and data flow</em>
</div>

**Key Features:**
- **Network Isolation** - Frontend/backend segregation protects databases
- **Resource Management** - Memory and CPU limits prevent cascading failures
- **Volume Persistence** - Named volumes for database data survival
- **Port Security** - Only necessary ports exposed to host

📂 **Details:** [Network Segregation Story](#-the-hidden-database-pattern) | [Resource Management Story](#-resource-limits-prevent-disasters)

---

## 💾 Resource Limits Prevent Disasters

<div align="center">
  <img src="assets/images/docker/docker-stats.png" width="750px" alt="Docker Container Resource Usage">
  <br>
  <em>Real-time resource monitoring: predictable, controlled, safe</em>
</div>

### The Catastrophe You're Avoiding

**Scenario without resource limits:**

```
1. Traffic spike hits Recipe app
2. Memory leak in application code
3. Container consumes 1.8GB of 2GB total RAM
4. Database gets OOM (Out of Memory) killed
5. Both Recipe and BookFinder apps crash
6. Everything goes down
```

**Scenario with resource limits:**

```
1. Traffic spike hits Recipe app
2. Memory leak in application code
3. Container hits 384MB limit
4. That specific container restarts
5. Other services keep running
6. System stays operational
```

### How Docker Resource Management Works

```yaml
# docker-compose.yml
services:
  web:
    deploy:
      resources:
        limits:
          memory: 384M      # Hard cap - kill container if exceeded
          cpus: '0.3'       # Max 30% of one CPU core
        reservations:
          memory: 192M      # Guaranteed minimum allocation
```

#### Key Concepts

**Memory Limits vs Reservations:**
- **Limit** = Maximum allowed (hard cap)
- **Reservation** = Guaranteed minimum (Docker scheduler ensures this is available)
- **Gap between them** = Burst capacity for traffic spikes

**Why 384MB limit?**
- 2GB total RAM / 3 apps = ~666MB per app
- Leave 30% buffer for OS and spikes = 384MB limit
- Result: Predictable behavior, no resource starvation

**Current Utilization:**
- 📊 **65% RAM usage** (1.3GB / 2GB) - Room for growth
- ⚙️ **40% CPU usage** - Comfortable headroom
- 💾 **8GB disk** (32% of capacity) - Space for logs and data

> **Lesson:** Constraints drive optimization. Without limits, bugs become production incidents. With limits, failures are isolated and recoverable.

📂 **Explore:** [Docker compose files](docker/) | [Resource tuning guide](docs/architecture.md)

---

## ⚖️ Load Balancing: Smarter Than You Think

<div align="center">
  <img src="assets/images/nginx/load-balancer.png" width="750px" alt="Nginx Load Balancer Configuration">
</div>

### The Algorithms That Keep Your App Online

When traffic spikes, one server isn't enough. But how do you split traffic fairly across multiple backend servers? The algorithm matters more than you might think.

#### 🔄 Round Robin (Default)
Requests distributed evenly in rotation: Server1 → Server2 → Server3 → Server1...

```nginx
upstream backend {
    server app1:5001;
    server app2:5002;
    server app3:5003;
}
```

**Best for:** Stateless applications, servers with equal capacity

---

#### 🔢 IP Hash
Same client IP always routes to the same server

```nginx
upstream backend {
    ip_hash;
    server app1:5001;
    server app2:5002;
}
```

**Best for:** Session persistence without shared storage (sticky sessions)
**Why it matters:** User stays on same server, maintaining session state

---

#### ⚡ Least Connections
Traffic goes to the server with fewest active connections

```nginx
upstream backend {
    least_conn;
    server app1:5001;
    server app2:5002;
}
```

**Best for:** Long-lived connections, varying request processing times
**Why it matters:** Prevents one server from being overwhelmed while others sit idle

---

#### ⚖️ Weighted Distribution
Some servers handle more traffic based on their capacity

```nginx
upstream backend {
    server powerful_server:5001 weight=3;
    server normal_server:5002 weight=1;
    # Powerful server gets 75% of traffic
}
```

**Best for:** Mixed server specs, gradual rollouts (canary deployments), A/B testing

---

> **Pro Tip:** Start with Round Robin for simplicity. Switch to IP Hash only if session management requires it (adds server affinity constraints). Use Least Connections for backends with unpredictable processing times.

📂 **Explore:** [Nginx configurations](nginx/sites-available/) | [Load balancing setup](docs/architecture.md)

---

## 🔧 Additional Nginx Capabilities

**Reverse Proxy & SSL Termination**
- Routes traffic to appropriate Docker containers based on subdomain
- Handles HTTPS encryption/decryption at the edge
- Adds security headers to all responses

**Multi-Domain Server Blocks**
- Hosts portfolio, recipe app, and bookfinder on same server
- Each domain gets isolated configuration
- Independent SSL certificates per subdomain

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

---

<div align="center">

## 🌟 Let's Connect

[![Portfolio](https://img.shields.io/badge/Portfolio-vladbortnik.dev-0EA5E9?style=for-the-badge&logo=google-chrome&logoColor=white)](https://vladbortnik.dev)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/vladyslav-bortnik)
[![Twitter](https://img.shields.io/badge/Twitter-@vladbortnik__dev-1DA1F2?style=for-the-badge&logo=x&logoColor=white)](https://x.com/vladbortnik_dev)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/vladbortnik)

<br>

### 📝 Blog Series: From Zero to Production

*Coming Soon* - Deep-dives into production infrastructure setup

```
🔐 Part 1: Docker Network Security Patterns
⚖️ Part 2: Nginx Load Balancing Algorithms Explained
🔒 Part 3: SSL Automation & Certificate Management
💰 Part 4: Cost Optimization: Self-Hosted vs Managed Platforms
📊 Part 5: Monitoring & Observability Best Practices
```

*Subscribe to my [blog](https://vladbortnik.dev/blog) for updates when these drop*

</div>

---

<div align="center">

**Built with ❤️ by [Vlad Bortnik](https://vladbortnik.dev)**
Software Engineer | DevOps Enthusiast

<br>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

⭐ **If this helped you, star the repo!** It helps others discover it.

</div>
