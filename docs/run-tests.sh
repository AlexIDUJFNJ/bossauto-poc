#!/bin/bash

# BossAuto PoC - Automated Testing Script
# Quick test all approval scenarios

set -e

# Configuration
WEBHOOK_URL="${WEBHOOK_URL:-http://webscansearch.name/automotive/webhook/purchase-request}"
TEST_DATA_FILE="/Users/alex/UpWork/Automotive/docs/test-requests.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         BossAuto PoC - Automated Test Suite              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to run a test
run_test() {
    local test_name=$1
    local test_key=$2
    local expected=$3

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Test: $test_name${NC}"
    echo -e "Expected: $expected"
    echo ""

    # Extract request data from JSON
    local request_data=$(jq -c ".$test_key.request" "$TEST_DATA_FILE")

    # Make request
    echo "Sending request..."
    local response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$request_data")

    # Pretty print response
    echo -e "${GREEN}Response:${NC}"
    echo "$response" | jq '.'

    # Check if successful
    if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Test passed!${NC}"
    else
        echo -e "${RED}✗ Test failed or error occurred${NC}"
    fi

    echo ""
    sleep 2  # Delay between tests
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Install it with: brew install jq${NC}"
    exit 1
fi

# Check if test data file exists
if [ ! -f "$TEST_DATA_FILE" ]; then
    echo -e "${RED}Error: Test data file not found: $TEST_DATA_FILE${NC}"
    exit 1
fi

# Health check first
echo -e "${BLUE}Running health check...${NC}"
health_response=$(curl -s http://webscansearch.name/automotive/health)
if echo "$health_response" | jq -e '.status == "ok"' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Mock API is healthy${NC}"
else
    echo -e "${RED}✗ Mock API health check failed${NC}"
    echo "$health_response"
    echo ""
    echo "Please ensure the Mock API is running:"
    echo "  pm2 status"
    echo "  pm2 logs bossauto-mock-api"
    exit 1
fi
echo ""

# Run all tests
echo -e "${BLUE}Starting test suite...${NC}"
echo ""

run_test "1. Auto-Approval (< \$1,000)" \
         "test_1_auto_approval" \
         "Status: approved, Level: auto"

run_test "2. Manager Approval (\$1K - \$5K)" \
         "test_2_manager_approval" \
         "Status: pending_approval, Level: manager"

run_test "3. Director Approval (\$5K - \$20K)" \
         "test_3_director_approval" \
         "Status: pending_approval, Level: director"

run_test "4. CEO Approval (≥ \$20K)" \
         "test_4_ceo_approval" \
         "Status: pending_approval, Level: ceo"

run_test "5. Boundary Test (\$999)" \
         "test_5_boundary_999" \
         "Status: approved, Level: auto"

run_test "6. Boundary Test (\$1,000)" \
         "test_6_boundary_1000" \
         "Status: pending_approval, Level: manager"

run_test "7. Multiple Items (\$8,550)" \
         "test_7_multiple_items" \
         "Status: pending_approval, Level: director"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  Test Suite Completed                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Check the database for results:"
echo "  psql -U quantum -d bossauto -c \"SELECT request_id, total_amount, status, approval_level FROM purchase_requests ORDER BY created_at DESC LIMIT 10;\""
echo ""
echo "Check system logs:"
echo "  pm2 logs bossauto-mock-api --lines 50"
echo "  pm2 logs n8n --lines 50"
echo ""
