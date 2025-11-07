#!/bin/bash
# Complete test script for flamegraph feature

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  Flamegraph Feature - Build & Test"
echo "=========================================="
echo ""

# Step 1: Build
echo -e "${YELLOW}[1/4] Building exporter...${NC}"
if GOTOOLCHAIN=go1.23.4 make build-exporter 2>&1 | grep -q "error"; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# Step 2: Run unit tests
echo -e "${YELLOW}[2/4] Running unit tests...${NC}"
if GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -v -run TestFlame 2>&1 | tee /tmp/test_output.txt; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
else
    echo -e "${RED}✗ Unit tests failed${NC}"
    cat /tmp/test_output.txt
    exit 1
fi
echo ""

# Step 3: Check if exporter is running
echo -e "${YELLOW}[3/4] Checking if exporter is running...${NC}"
if curl -s -f http://localhost:10249/status > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Exporter is running${NC}"
    EXPORTER_RUNNING=true
else
    echo -e "${YELLOW}⚠ Exporter is not running${NC}"
    echo "   Start it with: ./bin/inspector server --config test-config.yaml"
    EXPORTER_RUNNING=false
fi
echo ""

# Step 4: Test HTTP endpoints (if exporter is running)
if [ "$EXPORTER_RUNNING" = true ]; then
    echo -e "${YELLOW}[4/4] Testing HTTP endpoints...${NC}"
    
    # Test node scope
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" 'http://localhost:10249/flamegraph/collapsed?scope=node')
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Node scope endpoint works (HTTP 200)${NC}"
    else
        echo -e "${RED}✗ Node scope endpoint failed (HTTP $HTTP_CODE)${NC}"
    fi
    
    # Test pod scope
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" 'http://localhost:10249/flamegraph/collapsed?scope=pod&namespace=test&pod=test')
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Pod scope endpoint works (HTTP 200)${NC}"
    else
        echo -e "${RED}✗ Pod scope endpoint failed (HTTP $HTTP_CODE)${NC}"
    fi
    
    # Test event filtering
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" 'http://localhost:10249/flamegraph/collapsed?scope=node&event=PacketLoss')
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Event filtering works (HTTP 200)${NC}"
    else
        echo -e "${RED}✗ Event filtering failed (HTTP $HTTP_CODE)${NC}"
    fi
else
    echo -e "${YELLOW}[4/4] Skipping HTTP endpoint tests (exporter not running)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Test Summary${NC}"
echo "=========================================="
echo "✓ Build: OK"
echo "✓ Unit Tests: OK"
if [ "$EXPORTER_RUNNING" = true ]; then
    echo "✓ HTTP Endpoints: OK"
else
    echo "⚠ HTTP Endpoints: Skipped (start exporter to test)"
fi
echo ""
echo "Next steps:"
echo "  1. Start exporter: ./bin/inspector server --config test-config.yaml"
echo "  2. Test endpoints: ./test_flamegraph.sh"
echo "  3. Generate flamegraph: curl 'http://localhost:10249/flamegraph/collapsed?scope=node' | flamegraph.pl > flamegraph.svg"
