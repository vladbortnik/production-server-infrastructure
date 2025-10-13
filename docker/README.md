# Docker Configuration

This directory contains Docker Compose configurations for deploying web applications with proper network segregation and resource management.

## Directory Structure

```
docker/
├── README.md                      # This file
├── recipe-app/
│   └── docker-compose.yml         # Recipe app configuration
└── bookfinder-app/
    └── docker-compose.yml         # BookFinder app configuration
```

## Key Features

### 🔒 Network Segregation

Each application uses two isolated networks:

- **Frontend Network**: Allows communication between web service and Nginx reverse proxy
- **Backend Network**: Private network for database communication only

This architecture ensures that:
- Database ports are never exposed to the internet
- Only the web service can access the database
- Each component is isolated for security

### 📊 Resource Management

Each container has defined resource limits:

```yaml
mem_limit: 384m          # Maximum memory usage
mem_reservation: 192m    # Guaranteed memory allocation
cpus: 0.3               # CPU quota (30% of one core)
```

Benefits:
- Prevents resource exhaustion on shared server
- Ensures fair resource distribution
- Protects against memory leaks
- Allows predictable performance

### 💾 Volume Persistence

Named volumes ensure data persistence across container restarts:

- `postgres_data` - PostgreSQL database storage
- `mysql_data` - MySQL database storage

Data is stored on the host filesystem and survives container rebuilds.

## Deployment

### Prerequisites

1. Docker and Docker Compose installed
2. Application code in the respective directories
3. Environment variables configured in `.env` files

### Environment Variables

Create a `.env` file in each application directory:

**Recipe App (.env example):**
```bash
# Database Configuration
POSTGRES_DB=recipe_db
POSTGRES_USER=recipe_user
POSTGRES_PASSWORD=your_secure_password

# Application Configuration
FLASK_APP=run.py
FLASK_ENV=production
SECRET_KEY=your_secret_key

# API Keys
SPOONACULAR_API_KEY=your_api_key
```

**BookFinder App (.env example):**
```bash
# Database Configuration
MYSQL_DATABASE=bookfinder_db
MYSQL_USER=bookfinder_user
MYSQL_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_root_password

# Application Configuration
FLASK_APP=run.py
FLASK_ENV=production
SECRET_KEY=your_secret_key

# API Keys
AZURE_VISION_KEY=your_api_key
AZURE_VISION_ENDPOINT=your_endpoint
```

### Deploy an Application

1. **Navigate to application directory:**
```bash
cd docker/recipe-app
```

2. **Create environment file:**
```bash
cp .env.example .env
# Edit .env with your values
nano .env
```

3. **Build and start containers:**
```bash
docker-compose up -d
```

4. **Check status:**
```bash
docker-compose ps
```

5. **View logs:**
```bash
docker-compose logs -f
```

### Useful Commands

**Stop containers:**
```bash
docker-compose down
```

**Rebuild containers:**
```bash
docker-compose up -d --build
```

**View resource usage:**
```bash
docker stats
```

**Access database shell:**
```bash
# PostgreSQL
docker exec -it recipe_db psql -U recipe_user -d recipe_db

# MySQL
docker exec -it bookfinder_db mysql -u bookfinder_user -p bookfinder_db
```

**Backup database:**
```bash
# PostgreSQL
docker exec recipe_db pg_dump -U recipe_user recipe_db > backup.sql

# MySQL
docker exec bookfinder_db mysqldump -u bookfinder_user -p bookfinder_db > backup.sql
```

**Restore database:**
```bash
# PostgreSQL
cat backup.sql | docker exec -i recipe_db psql -U recipe_user -d recipe_db

# MySQL
cat backup.sql | docker exec -i bookfinder_db mysql -u bookfinder_user -p bookfinder_db
```

## Network Architecture

```
┌────────────────────────────────────────────────────┐
│                  Docker Host                        │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │         Frontend Network (Bridge)            │  │
│  │                                              │  │
│  │  ┌────────────┐                             │  │
│  │  │ Web Service├────────┐                    │  │
│  │  │  (Flask)   │        │                    │  │
│  │  └────────────┘        │                    │  │
│  │         │              │                    │  │
│  └─────────┼──────────────┼────────────────────┘  │
│            │              │                        │
│        Port 5001/5002     │                        │
│            │              │                        │
│  ┌─────────┼──────────────┼────────────────────┐  │
│  │         │    Backend Network (Bridge)       │  │
│  │         │              │                    │  │
│  │  ┌──────▼──────┐  ┌───▼─────────┐          │  │
│  │  │ Web Service │  │  Database   │          │  │
│  │  │  (Flask)    ├──┤ (PostgreSQL │          │  │
│  │  └─────────────┘  │  or MySQL)  │          │  │
│  │                   └─────────────┘          │  │
│  │                   Port: 5432/3306          │  │
│  │                   (NOT exposed)            │  │
│  └────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

## Security Best Practices

✅ **Database Port Isolation**
- Database ports (5432, 3306) are NOT exposed to the host
- Only accessible via internal Docker network
- Prevents unauthorized external access

✅ **Network Segregation**
- Frontend and backend networks are separate
- Limits blast radius of potential security breaches
- Follows principle of least privilege

✅ **Resource Limits**
- Prevents DoS through resource exhaustion
- Ensures fair resource sharing
- Protects against runaway processes

✅ **Environment Variables**
- Sensitive data stored in `.env` files
- `.env` files excluded from version control
- Easy to rotate credentials

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs web
docker-compose logs db

# Check container status
docker-compose ps
```

### Database connection issues

```bash
# Verify networks
docker network ls
docker network inspect recipe-app_backend

# Check if containers are on same network
docker inspect recipe_web | grep Networks
docker inspect recipe_db | grep Networks
```

### Performance issues

```bash
# Monitor resource usage
docker stats

# Check if hitting resource limits
docker-compose logs | grep -i "memory\|cpu"
```

### Port conflicts

```bash
# Check what's using the port
sudo netstat -tulpn | grep :5001
sudo lsof -i :5001

# Change port in docker-compose.yml
ports:
  - "5003:5002"  # Changed from 5002:5002
```

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Networking Guide](https://docs.docker.com/network/)
- [Docker Resource Constraints](https://docs.docker.com/config/containers/resource_constraints/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
