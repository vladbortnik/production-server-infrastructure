# SSL/TLS Setup Guide: DNS-01 vs HTTP-01 Challenge

## Overview

Let's Encrypt offers multiple validation methods to prove you own a domain before issuing SSL/TLS certificates. Understanding which validation type to use is crucial for a multi-application server setup.

## Let's Encrypt Challenge Types

Let's Encrypt offers 3 types of domain validation:

1. **HTTP-01 Challenge** - Most common, validates via HTTP
2. **DNS-01 Challenge** - Validates via DNS records, supports wildcards
3. **TLS-ALPN-01** - Validates via TLS, less common

## Why DNS-01 Challenge is Perfect for Multi-App Setups

### The Problem with HTTP-01

The HTTP-01 challenge is the most common validation method, but it has limitations:

- ❌ **Cannot validate wildcard certificates** (e.g., `*.yourdomain.com`)
- ❌ **Requires port 80 to be accessible** from the Internet
- ❌ **One certificate per subdomain** - meaning you need to manage multiple certificates

### The DNS-01 Solution

For a server hosting multiple applications on subdomains (like `recipe.yourdomain.com`, `app1.yourdomain.com`, `app2.yourdomain.com`), **DNS-01 is the ideal choice**:

- ✅ **Supports wildcard certificates** - One certificate covers `*.yourdomain.com`
- ✅ **Works behind firewalls** - No need to expose port 80 during validation
- ✅ **Perfect for subdomain-based routing** - Issue once, use for all subdomains
- ✅ **Simpler certificate management** - One renewal process for all apps

### My Setup

In my production environment, I use DNS-01 challenge to secure multiple applications:

- `https://vladbortnik.dev/` - Portfolio website
- `https://recipe.vladbortnik.dev/` - Recipe application
- `https://bookfinder.vladbortnik.dev/` - BookFinder application
- `https://tldrx.vladbortnik.dev/` - TLDR summarizer

All these subdomains are secured with a **single wildcard certificate** (`*.vladbortnik.dev`), validated using DNS-01 challenge.

## How DNS-01 Challenge Works

1. **Request certificate** from Let's Encrypt for `*.yourdomain.com`
2. **Let's Encrypt provides a token** that you must add as a DNS TXT record
3. **Add TXT record** to your DNS provider (e.g., `_acme-challenge.yourdomain.com`)
4. **Let's Encrypt queries DNS** to verify the TXT record exists
5. **Certificate issued** once validation passes

## Implementation

### Prerequisites

- Access to your DNS provider's API or management panel
- Certbot installed on your server
- DNS plugin for Certbot (depends on your DNS provider)

### Example with Certbot

```bash
# Install Certbot with DNS plugin (example for DigitalOcean)
sudo apt install certbot python3-certbot-dns-digitalocean

# Configure DNS credentials
sudo nano /etc/letsencrypt/digitalocean.ini
# Add: dns_digitalocean_token = YOUR_API_TOKEN

# Request wildcard certificate
sudo certbot certonly \
  --dns-digitalocean \
  --dns-digitalocean-credentials /etc/letsencrypt/digitalocean.ini \
  -d yourdomain.com \
  -d *.yourdomain.com
```

### Certificate Renewal

DNS-01 certificates auto-renew just like HTTP-01:

```bash
# Test renewal
sudo certbot renew --dry-run

# Automatic renewal (typically handled by systemd timer or cron)
sudo certbot renew
```

## When to Use Each Challenge Type

| Scenario | Recommended Challenge |
|----------|----------------------|
| Single domain (e.g., `example.com`) | HTTP-01 |
| Multiple subdomains (e.g., `app1.example.com`, `app2.example.com`) | DNS-01 |
| Wildcard certificate needed | DNS-01 (only option) |
| Server behind firewall | DNS-01 |
| Simple setup with port 80 accessible | HTTP-01 |

## External Resources

- [Let's Encrypt: Challenge Types](https://letsencrypt.org/docs/challenge-types/) - Official documentation
- [Certbot Documentation](https://eff-certbot.readthedocs.io/) - Installation and usage guides
- [DNS Plugins for Certbot](https://eff-certbot.readthedocs.io/en/stable/using.html#dns-plugins) - Provider-specific plugins

## Security Considerations

- 🔐 **Protect DNS API tokens** - Store credentials securely with restricted permissions
- 🔄 **Monitor certificate expiration** - Set up renewal notifications
- 📝 **Test renewals regularly** - Use `--dry-run` to verify renewal process works
- 🛡️ **Use TLS 1.3** - As shown in the Nginx configurations, prefer modern TLS versions

---

**Note:** The Nginx configurations in this repository (`nginx/recipe-simple.conf` and `nginx/recipe-loadbalanced.conf`) are configured to use TLS 1.3 with modern security settings compatible with Let's Encrypt certificates.
