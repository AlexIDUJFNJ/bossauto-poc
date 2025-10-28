#!/bin/bash

# BossAuto PoC - Deployment Script
# Deploy to VPS: quantum@188.245.77.73

set -e  # Exit on error

echo "🚀 BossAuto PoC Deployment Script"
echo "=================================="

# Configuration
VPS_HOST="quantum@188.245.77.73"
VPS_PATH="/var/www/html/Automotive"
LOCAL_PATH="/Users/alex/UpWork/Automotive"
DOMAIN="webscansearch.name"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${YELLOW}📦 Step 1: Creating directories on VPS...${NC}"
ssh $VPS_HOST "mkdir -p $VPS_PATH/{database,mock-api,docs}"

echo ""
echo -e "${YELLOW}📤 Step 2: Uploading database schema...${NC}"
scp $LOCAL_PATH/database/schema.sql $VPS_HOST:$VPS_PATH/database/
scp $LOCAL_PATH/database/sample_data.sql $VPS_HOST:$VPS_PATH/database/

echo ""
echo -e "${YELLOW}📤 Step 3: Uploading Mock API...${NC}"
scp $LOCAL_PATH/mock-api/package.json $VPS_HOST:$VPS_PATH/mock-api/
scp $LOCAL_PATH/mock-api/server.js $VPS_HOST:$VPS_PATH/mock-api/

echo ""
echo -e "${YELLOW}📤 Step 4: Uploading documentation...${NC}"
scp $LOCAL_PATH/README.md $VPS_HOST:$VPS_PATH/
scp $LOCAL_PATH/docs/* $VPS_HOST:$VPS_PATH/docs/ 2>/dev/null || echo "No docs to upload"

echo ""
echo -e "${YELLOW}🔧 Step 5: Installing dependencies...${NC}"
ssh $VPS_HOST "cd $VPS_PATH/mock-api && npm install --production"

echo ""
echo -e "${YELLOW}🗄️  Step 6: Setting up PostgreSQL...${NC}"
ssh $VPS_HOST "psql -U quantum -d bossauto -f $VPS_PATH/database/schema.sql || echo 'Note: Run PostgreSQL setup manually if needed'"

echo ""
echo -e "${YELLOW}🚀 Step 7: Starting Mock API (PM2)...${NC}"
ssh $VPS_HOST "cd $VPS_PATH/mock-api && pm2 start server.js --name bossauto-mock-api || pm2 restart bossauto-mock-api"

echo ""
echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Configure nginx reverse proxy for Mock API"
echo "  2. Import n8n workflow"
echo "  3. Configure environment variables in n8n"
echo "  4. Test webhook endpoint"
echo ""
echo "🔗 URLs:"
echo "  Mock API Health: http://$DOMAIN:3001/health"
echo "  Webhook (after n8n setup): https://$DOMAIN/automotive/webhook/purchase-request"
echo ""
