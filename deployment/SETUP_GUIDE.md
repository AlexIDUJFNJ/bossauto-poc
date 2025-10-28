# BossAuto PoC - Complete Setup Guide

## Prerequisites on VPS

- Ubuntu 20.04+ (or similar Linux)
- Node.js 18+ installed
- PostgreSQL 14+ installed
- nginx installed
- PM2 for process management
- n8n installed (Docker or npm)

## Step-by-Step Setup

### 1. Install Required Software

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install nginx
sudo apt install -y nginx

# Install PM2
sudo npm install -g pm2

# Install n8n (choose one method)
# Method 1: Using npm
sudo npm install -g n8n

# Method 2: Using Docker
# sudo docker run -d --name n8n \
#   -p 5678:5678 \
#   -v ~/.n8n:/home/node/.n8n \
#   n8nio/n8n
```

### 2. Configure PostgreSQL

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database and user
CREATE DATABASE bossauto;
CREATE USER quantum WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE bossauto TO quantum;
\q

# Test connection
psql -U quantum -d bossauto -h localhost

# Import schema
psql -U quantum -d bossauto -f /var/www/html/Automotive/database/schema.sql

# Import sample data (optional)
psql -U quantum -d bossauto -f /var/www/html/Automotive/database/sample_data.sql

# Verify tables
psql -U quantum -d bossauto -c "\dt"
```

### 3. Setup Mock API

```bash
# Navigate to project
cd /var/www/html/Automotive/mock-api

# Install dependencies
npm install

# Test locally
node server.js
# Should see: "🚀 BossAuto Mock BC API running on port 3001"
# Press Ctrl+C to stop

# Start with PM2
pm2 start server.js --name bossauto-mock-api
pm2 save
pm2 startup  # Follow instructions to enable auto-start

# Verify
pm2 status
curl http://localhost:3001/health
```

### 4. Configure nginx

```bash
# Copy nginx config
sudo cp /var/www/html/Automotive/deployment/nginx-automotive.conf /etc/nginx/sites-available/automotive

# Create symbolic link
sudo ln -s /etc/nginx/sites-available/automotive /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Test endpoints
curl http://webscansearch.name/automotive/health
```

### 5. Setup n8n

```bash
# Create n8n user data directory
mkdir -p ~/.n8n

# Set environment variables
export N8N_HOST="0.0.0.0"
export N8N_PORT=5678
export N8N_PROTOCOL="http"
export WEBHOOK_URL="https://webscansearch.name"
export N8N_BASIC_AUTH_ACTIVE=true
export N8N_BASIC_AUTH_USER="admin"
export N8N_BASIC_AUTH_PASSWORD="your_secure_password"

# Start n8n with PM2
pm2 start n8n --name n8n -- start
pm2 save

# Access n8n
# Open browser: http://webscansearch.name:5678
# Login with credentials set above
```

### 6. Import n8n Workflow

1. Open n8n: `http://webscansearch.name:5678`
2. Login with credentials
3. Click "Import from File"
4. Select `/var/www/html/Automotive/n8n-workflows/flujo-1-approval-engine.json`
5. Configure credentials:

#### PostgreSQL Credential
```
Name: BossAuto PostgreSQL
Type: Postgres
Host: localhost
Port: 5432
Database: bossauto
User: quantum
Password: [your_password]
```

#### Telegram Credential (if using)
```
Name: BossAuto Telegram Bot
Type: Telegram
Access Token: [your_bot_token]
```

### 7. Configure Telegram Bot (Optional)

```bash
# Create bot via @BotFather on Telegram
# 1. Start chat with @BotFather
# 2. Send: /newbot
# 3. Follow instructions
# 4. Save the token

# Get your chat_id
# 1. Start chat with your bot
# 2. Send any message
# 3. Visit: https://api.telegram.org/bot<TOKEN>/getUpdates
# 4. Look for "chat":{"id": YOUR_CHAT_ID}

# Test notification
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "<YOUR_CHAT_ID>",
    "text": "🎯 BossAuto PoC activated!",
    "parse_mode": "HTML"
  }'
```

### 8. Test the Complete Flow

```bash
# Test 1: Auto-approval (< $1,000)
curl -X POST https://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{
    "purchase_request_id": "PR-TEST-001",
    "requester": {
      "name": "Test User",
      "department": "Testing",
      "email": "test@company.com"
    },
    "items": [
      {
        "item_code": "TEST-001",
        "description": "Test Item",
        "quantity": 10,
        "unit_price": 50,
        "total": 500
      }
    ],
    "total_amount": 500,
    "currency": "USD",
    "supplier": {
      "name": "Test Supplier",
      "code": "SUP-TEST"
    },
    "requested_date": "2025-01-28T10:00:00Z",
    "delivery_date": "2025-02-15"
  }'

# Test 2: Manager approval (> $1,000)
curl -X POST https://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d '{
    "purchase_request_id": "PR-TEST-002",
    "requester": {
      "name": "Test User 2",
      "department": "Testing",
      "email": "test2@company.com"
    },
    "items": [
      {
        "item_code": "TEST-002",
        "description": "Test Item 2",
        "quantity": 100,
        "unit_price": 25,
        "total": 2500
      }
    ],
    "total_amount": 2500,
    "currency": "USD",
    "supplier": {
      "name": "Test Supplier",
      "code": "SUP-TEST"
    },
    "requested_date": "2025-01-28T10:00:00Z",
    "delivery_date": "2025-02-15"
  }'

# Verify in database
psql -U quantum -d bossauto -c "SELECT request_id, total_amount, status, approval_level FROM purchase_requests ORDER BY created_at DESC LIMIT 5;"

# Check logs
pm2 logs bossauto-mock-api --lines 50
pm2 logs n8n --lines 50
```

## Troubleshooting

### Mock API not responding
```bash
pm2 status
pm2 logs bossauto-mock-api
pm2 restart bossauto-mock-api
```

### PostgreSQL connection issues
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Check connection
psql -U quantum -d bossauto -h localhost

# View PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### n8n workflow errors
```bash
# Check n8n logs
pm2 logs n8n

# Restart n8n
pm2 restart n8n

# Check n8n executions in UI
# Go to: http://webscansearch.name:5678 → Executions
```

### nginx errors
```bash
# Check nginx error log
sudo tail -f /var/log/nginx/automotive-error.log

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

## Security Considerations (Production)

⚠️ **This is a PoC - NOT production-ready!**

For production deployment:

1. **Enable HTTPS**:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d webscansearch.name
```

2. **Add authentication to webhook**:
- Use API keys
- Implement JWT tokens
- Add rate limiting

3. **Secure PostgreSQL**:
- Use strong passwords
- Restrict network access
- Enable SSL connections

4. **Firewall configuration**:
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

5. **Regular backups**:
```bash
# Database backup
pg_dump -U quantum bossauto > /backup/bossauto_$(date +%Y%m%d).sql

# Automate with cron
0 2 * * * pg_dump -U quantum bossauto > /backup/bossauto_$(date +\%Y\%m\%d).sql
```

## Monitoring

```bash
# System resources
htop

# PM2 monitoring
pm2 monit

# Application logs
pm2 logs bossauto-mock-api
pm2 logs n8n

# nginx access log
sudo tail -f /var/log/nginx/automotive-access.log

# Database queries
psql -U quantum -d bossauto -c "SELECT * FROM pending_requests_summary;"
```

## Quick Reference - Useful Commands

```bash
# Restart all services
pm2 restart all

# View all PM2 processes
pm2 list

# Stop services
pm2 stop bossauto-mock-api
pm2 stop n8n

# Check database
psql -U quantum -d bossauto

# Test Mock API
curl http://localhost:3001/health

# Test webhook
curl -X POST https://webscansearch.name/automotive/webhook/purchase-request \
  -H "Content-Type: application/json" \
  -d @test-request.json

# View logs
journalctl -u nginx -f
pm2 logs --lines 100
```

## Next Steps

Once PoC is working:

1. ✅ Test all approval levels
2. ✅ Verify SLA calculations
3. ✅ Test error scenarios
4. ✅ Create video demo
5. ✅ Prepare proposal for client
6. 🚀 Submit Upwork proposal with live demo!

---

**Support**: quantum@webscansearch.name
