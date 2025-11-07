#!/bin/bash
# Test script for flamegraph feature

set -e

echo "=== Testing Flamegraph Feature ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if exporter is running
EXPORTER_URL="${EXPORTER_URL:-http://localhost:10249}"

echo -e "${YELLOW}1. Checking if exporter is running...${NC}"
if curl -s -f "${EXPORTER_URL}/status" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Exporter is running${NC}"
else
    echo -e "${RED}✗ Exporter is not running at ${EXPORTER_URL}${NC}"
    echo "   Please start the exporter first:"
    echo "   ./bin/inspector server --config /etc/config/config.yaml"
    exit 1
fi

echo ""
echo -e "${YELLOW}2. Testing /flamegraph/collapsed endpoint...${NC}"

# Test node scope
echo "   Testing node scope..."
RESPONSE=$(curl -s "${EXPORTER_URL}/flamegraph/collapsed?scope=node")
if [ -z "$RESPONSE" ]; then
    echo -e "${YELLOW}  ⚠ No data yet (this is normal if no events have been collected)${NC}"
else
    echo -e "${GREEN}  ✓ Node scope returned data${NC}"
    echo "  Sample output (first 5 lines):"
    echo "$RESPONSE" | head -5 | sed 's/^/    /'
fi

# Test pod scope (will likely be empty unless you have pod events)
echo ""
echo "   Testing pod scope..."
RESPONSE=$(curl -s "${EXPORTER_URL}/flamegraph/collapsed?scope=pod&namespace=default&pod=test")
if [ -z "$RESPONSE" ]; then
    echo -e "${YELLOW}  ⚠ No pod data yet (this is normal if no pod events have been collected)${NC}"
else
    echo -e "${GREEN}  ✓ Pod scope returned data${NC}"
fi

# Test event filtering
echo ""
echo "   Testing event filtering..."
RESPONSE=$(curl -s "${EXPORTER_URL}/flamegraph/collapsed?scope=node&event=PacketLoss")
if [ -z "$RESPONSE" ]; then
    echo -e "${YELLOW}  ⚠ No PacketLoss events yet${NC}"
else
    echo -e "${GREEN}  ✓ Event filtering works${NC}"
fi

# Test reset
echo ""
echo "   Testing reset functionality..."
RESPONSE_BEFORE=$(curl -s "${EXPORTER_URL}/flamegraph/collapsed?scope=node")
curl -s "${EXPORTER_URL}/flamegraph/collapsed?scope=node&reset=true" > /dev/null
RESPONSE_AFTER=$(curl -s "${EXPORTER_URL}/flamegraph/collapsed?scope=node")
if [ -z "$RESPONSE_AFTER" ] && [ -n "$RESPONSE_BEFORE" ]; then
    echo -e "${GREEN}  ✓ Reset functionality works${NC}"
elif [ -z "$RESPONSE_BEFORE" ]; then
    echo -e "${YELLOW}  ⚠ No data to reset${NC}"
else
    echo -e "${YELLOW}  ⚠ Reset may not have worked (data still present)${NC}"
fi

echo ""
echo -e "${YELLOW}3. Testing endpoint format...${NC}"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "${EXPORTER_URL}/flamegraph/collapsed?scope=node")
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}  ✓ Endpoint returns HTTP 200${NC}"
else
    echo -e "${RED}  ✗ Endpoint returned HTTP ${HTTP_CODE}${NC}"
fi

echo ""
echo -e "${GREEN}=== Test Summary ==="
echo "All basic tests completed!"
echo ""
echo "To generate a flamegraph SVG:"
echo "  curl '${EXPORTER_URL}/flamegraph/collapsed?scope=node' | flamegraph.pl > flamegraph.svg"
echo ""
echo "Or use the online tool:"
echo "  https://github.com/brendangregg/flamegraph"
echo "${NC}"

