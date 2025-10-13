# System Architecture

Detailed technical architecture of the production-grade multi-application server infrastructure.

## Table of Contents

- [Overview](#overview)
- [Infrastructure Layer](#infrastructure-layer)
- [Network Architecture](#network-architecture)
- [Application Layer](#application-layer)
- [Security Layer](#security-layer)
- [Data Flow](#data-flow)
- [Scaling Considerations](#scaling-considerations)

## Overview

### Architecture Principles

This infrastructure follows these key principles:

1. **Defense in Depth**: Multiple security layers (firewall, intrusion prevention, SSL, headers)
2. **Network Segregation**: Isolated networks for different security zones
3. **Resource Management**: Defined limits to prevent resource exhaustion
4. **High Availability**: Designed for 99.9%+ uptime
5. **Scalability**: Architecture supports horizontal scaling

### Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Cloud Provider** | DigitalOcean | VPS hosting |
| **Operating System** | Ubuntu 24.04 LTS | Server OS |
| **Web Server** | Nginx | Reverse proxy, SSL termination, load balancing |
| **Containerization** | Docker & Docker Compose | Application isolation |
| **Security** | UFW, Fail2Ban, Let's Encrypt | Firewall, intrusion prevention, SSL |
| **Web Framework** | Flask + Gunicorn | Python web applications |
| **Databases** | PostgreSQL 16.4, MySQL 8.0 | Data persistence |
| **DNS** | DigitalOcean DNS | Domain management |

## Infrastructure Layer

### DigitalOcean Droplet Specifications

```
┌──────────────────────────────────────┐
│     DigitalOcean Droplet             │
├──────────────────────────────────────┤
│ OS:        Ubuntu 24.04 LTS (Noble)  │
│ RAM:       2 GB                      │
│ CPU:       1 vCPU                    │
│ Storage:   25 GB SSD                 │
│ Region:    NYC3 Data Center          │
│ IPv4:      Assigned                  │
│ IPv6:      Assigned                  │
└──────────────────────────────────────┘
```

### Resource Allocation

**Per-Application Resource Limits:**
- Memory Limit: 384 MB
- Memory Reservation: 192 MB (guaranteed)
- CPU Quota: 0.3 cores (30% of one CPU)

**System Reserved:**
- OS & System Processes: ~512 MB
- Nginx: ~50 MB
- Monitoring Tools: ~100 MB
- Available for Applications: ~1.3 GB

**Current Allocation:**
- Portfolio (static): ~50 MB
- Recipe App (web + db): 768 MB
- BookFinder App (web + db): 768 MB
- **Total Used**: ~1.6 GB (buffer for spikes)

## Network Architecture

### Public-Facing Network

```
                          Internet
                             │
                             ▼
                    ┌────────────────┐
                    │  DNS Provider  │
                    │  (DigitalOcean)│
                    └───────┬────────┘
                            │
                            ▼
           ┌────────────────────────────┐
           │    Server IP Address       │
           │    (Public IPv4/IPv6)      │
           └────────┬───────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
Port 80 (HTTP)           Port 443 (HTTPS)
        │                       │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   UFW Firewall        │
        │   (Port Filtering)    │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   Fail2Ban            │
        │   (Intrusion Prevention)│
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   Nginx (Port 80/443) │
        │   - SSL Termination   │
        │   - Reverse Proxy     │
        │   - Load Balancing    │
        └───────────┬───────────┘
                    │
        ┌───────────┴───────────────────┐
        │                               │
        ▼                               ▼
  Static Files              Reverse Proxy to
  (Portfolio)              Docker Applications
```

### DNS Configuration

| Record Type | Name | Value | Purpose |
|------------|------|-------|---------|
| A | @ | Server IPv4 | Root domain |
| A | www | Server IPv4 | WWW subdomain |
| A | recipe | Server IPv4 | Recipe app subdomain |
| A | bookfinder | Server IPv4 | BookFinder app subdomain |
| AAAA | @ | Server IPv6 | Root domain (IPv6) |
| AAAA | www | Server IPv6 | WWW subdomain (IPv6) |

### Docker Network Architecture

#### Network Topology

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Host                          │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Frontend Network (Bridge)                │  │
│  │         Subnet: 172.20.0.0/16                    │  │
│  │                                                  │  │
│  │  ┌──────────────┐        ┌──────────────┐      │  │
│  │  │ Recipe Web   │        │Bookfinder Web│      │  │
│  │  │ 172.20.0.2   │        │ 172.20.0.3   │      │  │
│  │  └──────┬───────┘        └──────┬───────┘      │  │
│  │         │                        │              │  │
│  │         │    Exposed Ports       │              │  │
│  │         │    Host:5002           │ Host:5001    │  │
│  │         │    ▲                   ▲              │  │
│  └─────────┼────┼───────────────────┼──────────────┘  │
│            │    │                   │                 │
│            │    └───────┬───────────┘                 │
│            │            │                             │
│  ┌─────────┼────────────┼────────────────────────┐   │
│  │         │    Backend Network (Bridge)         │   │
│  │         │    Subnet: 172.21.0.0/16            │   │
│  │         │                                     │   │
│  │  ┌──────▼────────┐        ┌──────────────┐   │   │
│  │  │ Recipe Web    │────────│ PostgreSQL   │   │   │
│  │  │ 172.21.0.2    │        │ 172.21.0.3   │   │   │
│  │  └───────────────┘        │ Port: 5432   │   │   │
│  │                           │ (internal)   │   │   │
│  │                           └──────────────┘   │   │
│  │  ┌───────────────┐        ┌──────────────┐   │   │
│  │  │Bookfinder Web │────────│    MySQL     │   │   │
│  │  │ 172.21.0.4    │        │ 172.21.0.5   │   │   │
│  │  └───────────────┘        │ Port: 3306   │   │   │
│  │                           │ (internal)   │   │   │
│  │                           └──────────────┘   │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

#### Network Segregation Benefits

1. **Frontend Network**:
   - Accessible from host (via port mapping)
   - Routes traffic through Nginx
   - Allows web services to communicate with internet

2. **Backend Network**:
   - Isolated from internet
   - Only accessible by web services
   - Database ports (3306, 5432) not exposed to host
   - Prevents direct database access from outside

3. **Security Advantages**:
   - Database compromise doesn't expose ports to internet
   - Web service compromise is contained
   - Clear separation of concerns
   - Follows principle of least privilege

## Application Layer

### Application Stack

```
┌────────────────────────────────────────────────────────┐
│                  Application Layer                      │
├────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │         Portfolio Website (Static)              │  │
│  │  • HTML, CSS, JavaScript                        │  │
│  │  • Nginx direct serving                         │  │
│  │  • Static asset caching                         │  │
│  │  • Root: /var/www/vladbortnik.dev              │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │         Recipe Web App (Dockerized)             │  │
│  │  ┌─────────────────────────────────────────┐   │  │
│  │  │ Flask Application                        │   │  │
│  │  │  • Python 3.x                           │   │  │
│  │  │  • Gunicorn WSGI (4 workers)           │   │  │
│  │  │  • Port: 5002                          │   │  │
│  │  │  • Spoonacular API integration         │   │  │
│  │  └───────────────┬─────────────────────────┘   │  │
│  │                  │                              │  │
│  │  ┌───────────────▼─────────────────────────┐   │  │
│  │  │ PostgreSQL 16.4                         │   │  │
│  │  │  • Named volume: postgres_data          │   │  │
│  │  │  • Internal port: 5432                  │   │  │
│  │  │  • Not exposed to host                  │   │  │
│  │  └─────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────┘  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐  │
│  │      BookFinder Web App (Dockerized)            │  │
│  │  ┌─────────────────────────────────────────┐   │  │
│  │  │ Flask Application                        │   │  │
│  │  │  • Python 3.x                           │   │  │
│  │  │  • Gunicorn WSGI (4 workers)           │   │  │
│  │  │  • Port: 5001                          │   │  │
│  │  │  • Azure Vision API integration        │   │  │
│  │  └───────────────┬─────────────────────────┘   │  │
│  │                  │                              │  │
│  │  ┌───────────────▼─────────────────────────┐   │  │
│  │  │ MySQL 8.0                               │   │  │
│  │  │  • Named volume: mysql_data             │   │  │
│  │  │  • Internal port: 3306                  │   │  │
│  │  │  • Not exposed to host                  │   │  │
│  │  └─────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### Gunicorn Configuration

**Workers**: 4 per application
- Formula: (2 × CPU cores) + 1 = (2 × 1) + 1 = 3-4 workers
- Handles concurrent requests
- Process isolation for stability

**Binding**: 0.0.0.0:PORT
- Listens on all container interfaces
- Accessible from host via port mapping

**Benefits**:
- Better than Flask development server
- Production-grade WSGI server
- Load balancing across workers
- Graceful worker restarts

## Security Layer

### Multi-Layer Security Architecture

```
┌──────────────────────────────────────────────────────┐
│              Security Layers (Defense in Depth)      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Layer 1: Network Firewall (UFW)                    │
│  ┌────────────────────────────────────────────────┐ │
│  │ • Default: Deny all incoming                   │ │
│  │ • Allow: 22 (SSH), 80 (HTTP), 443 (HTTPS)     │ │
│  │ • Rate limiting on SSH                         │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Layer 2: Intrusion Prevention (Fail2Ban)           │
│  ┌────────────────────────────────────────────────┐ │
│  │ • Monitors SSH, Nginx logs                     │ │
│  │ • Bans IPs after failed attempts               │ │
│  │ • Protection: brute-force, port scans, bots    │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Layer 3: SSL/TLS (Let's Encrypt)                   │
│  ┌────────────────────────────────────────────────┐ │
│  │ • TLS 1.2 & 1.3 only                          │ │
│  │ • Strong cipher suites (PFS)                   │ │
│  │ • OCSP stapling                                │ │
│  │ • A+ SSL Labs rating                           │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Layer 4: Security Headers (Nginx)                  │
│  ┌────────────────────────────────────────────────┐ │
│  │ • Content-Security-Policy (CSP)                │ │
│  │ • X-Frame-Options (clickjacking protection)    │ │
│  │ • X-Content-Type-Options (MIME sniffing)       │ │
│  │ • HSTS (force HTTPS)                           │ │
│  │ • Referrer-Policy                              │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Layer 5: Network Isolation (Docker)                │
│  ┌────────────────────────────────────────────────┐ │
│  │ • Frontend/backend network segregation         │ │
│  │ • Database ports not exposed to host           │ │
│  │ • Container-to-container isolation             │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  Layer 6: Application Security                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ • Environment variables for secrets            │ │
│  │ • Input validation                             │ │
│  │ • Parameterized queries (SQL injection)        │ │
│  │ • CSRF protection                              │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

### Security Ratings

| Service | Rating | Tested By |
|---------|--------|-----------|
| SSL/TLS | A+ | SSL Labs (Qualys) |
| HTTP Observatory | A+ | Mozilla |
| Security Headers | A | SecurityHeaders.com |

## Data Flow

### Request Flow - Static Content (Portfolio)

```
1. User Request
   https://vladbortnik.dev

   ↓

2. DNS Resolution
   vladbortnik.dev → Server IP

   ↓

3. UFW Firewall
   Port 443 (HTTPS) → Allow

   ↓

4. Fail2Ban Check
   IP not banned → Allow

   ↓

5. Nginx (SSL Termination)
   • Decrypt HTTPS traffic
   • Verify SSL certificate
   • Apply security headers

   ↓

6. Nginx (Static File Serving)
   • Read file from /var/www/vladbortnik.dev/html/
   • Apply caching headers
   • Compress response (gzip)

   ↓

7. Response
   HTML/CSS/JS → User's Browser
```

### Request Flow - Dynamic Content (Flask Apps)

```
1. User Request
   https://recipe.vladbortnik.dev/api/search

   ↓

2. DNS Resolution
   recipe.vladbortnik.dev → Server IP

   ↓

3. UFW Firewall
   Port 443 (HTTPS) → Allow

   ↓

4. Fail2Ban Check
   IP not banned → Allow

   ↓

5. Nginx (SSL Termination)
   • Decrypt HTTPS traffic
   • Verify SSL certificate
   • Apply security headers

   ↓

6. Nginx (Reverse Proxy)
   • Route to localhost:5002
   • Add proxy headers (X-Real-IP, X-Forwarded-For)
   • Buffer response

   ↓

7. Docker (Frontend Network)
   • Forward to recipe_web container
   • Port: 5002

   ↓

8. Gunicorn (WSGI Server)
   • Receive request
   • Forward to Flask app
   • Worker process handles request

   ↓

9. Flask Application
   • Route request to endpoint
   • Process business logic
   • Query database if needed

   ↓

10. Docker (Backend Network)
    • Connect to PostgreSQL container
    • Port: 5432 (internal only)

    ↓

11. PostgreSQL Database
    • Execute query
    • Return results

    ↓

12. Response Path (Reverse)
    Database → Flask → Gunicorn → Docker → Nginx → User
```

### External API Integration Flow

```
Flask App (Recipe)
    ↓
Spoonacular API
    • Recipe database
    • Ingredient information
    • Nutrition data

Flask App (BookFinder)
    ↓
Azure Vision API
    • ISBN extraction from images
    • OCR processing
    • Book cover recognition
```

## Scaling Considerations

### Vertical Scaling (Current Approach)

**Upgrade Droplet Resources:**
- 2 GB RAM → 4 GB RAM
- 1 vCPU → 2 vCPU
- Increase Docker resource limits proportionally

**Advantages:**
- Simple (no architecture changes)
- No complexity overhead
- Cost-effective for small-medium traffic

**Limitations:**
- Single point of failure
- Limited by largest available droplet
- Downtime during upgrades

### Horizontal Scaling (Future Growth)

```
┌─────────────────────────────────────────────────────┐
│                 Load Balancer                        │
│              (Nginx / DigitalOcean LB)              │
└────────┬────────────────┬───────────────┬───────────┘
         │                │               │
         ▼                ▼               ▼
    ┌────────┐      ┌────────┐      ┌────────┐
    │ App    │      │ App    │      │ App    │
    │Server 1│      │Server 2│      │Server 3│
    └────┬───┘      └────┬───┘      └────┬───┘
         │                │               │
         └────────────────┴───────────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │  Managed DB   │
                 │  (PostgreSQL) │
                 └───────────────┘
```

**Required Changes:**
1. Separate database tier (managed PostgreSQL)
2. Shared storage for static assets (S3/Spaces)
3. Load balancer configuration
4. Session management (Redis)
5. Database connection pooling

### Database Scaling

**Current**: Single database per application
**Future Options**:

1. **Managed Databases** (DigitalOcean Managed Databases)
   - Automated backups
   - High availability
   - Automatic failover
   - Connection pooling

2. **Read Replicas**
   - Master-slave replication
   - Distribute read traffic
   - Improve performance

3. **Database Sharding**
   - Horizontal partitioning
   - Distribute data across servers
   - For very large datasets

### Caching Layer

**Current**: Nginx static file caching
**Future Options**:

1. **Redis**
   - Session storage
   - API response caching
   - Rate limiting

2. **Varnish**
   - HTTP caching
   - Reduced backend load
   - Improved response times

3. **CDN (CloudFlare)**
   - Global edge caching
   - DDoS protection
   - SSL/TLS termination

## Monitoring and Observability

### Current Monitoring

- **Umami Analytics**: Web traffic tracking
- **Nginx Logs**: Access and error logs
- **Fail2Ban Logs**: Security events
- **Docker Stats**: Container resource usage

### Recommended Additions

1. **Application Performance Monitoring (APM)**
   - New Relic / DataDog
   - Request tracing
   - Error tracking
   - Performance metrics

2. **Infrastructure Monitoring**
   - Prometheus + Grafana
   - System metrics (CPU, RAM, disk)
   - Alert configuration
   - Historical data

3. **Log Aggregation**
   - ELK Stack (Elasticsearch, Logstash, Kibana)
   - Centralized logging
   - Log analysis
   - Search capabilities

4. **Uptime Monitoring**
   - UptimeRobot / Pingdom
   - External health checks
   - Downtime alerts
   - Status page

## Disaster Recovery

### Backup Strategy

**What to Backup:**
1. Database data (PostgreSQL, MySQL)
2. Docker volumes
3. Nginx configurations
4. SSL certificates
5. Application code
6. Environment variables

**Backup Frequency:**
- Databases: Daily (automated)
- Configurations: On change
- Full system: Weekly

**Backup Storage:**
- DigitalOcean Spaces / AWS S3
- Off-site location
- Encrypted backups
- 30-day retention

### Recovery Procedures

1. **Database Recovery**
   ```bash
   docker exec recipe_db pg_dump > backup.sql
   cat backup.sql | docker exec -i recipe_db psql
   ```

2. **Full System Recovery**
   - Provision new droplet
   - Restore configurations
   - Restore Docker volumes
   - Restore databases
   - Verify functionality

**Recovery Time Objective (RTO)**: 2 hours
**Recovery Point Objective (RPO)**: 24 hours

## Additional Resources

- [DigitalOcean Documentation](https://docs.digitalocean.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)
- [12-Factor App Methodology](https://12factor.net/)
