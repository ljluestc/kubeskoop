#!/bin/bash
# Quick test script for flamegraph feature

set -e

echo "=== Quick Test for Flamegraph Feature ==="
echo ""

# Check if exporter is built
if [ ! -f "./bin/inspector" ]; then
    echo "Building exporter..."
    GOTOOLCHAIN=go1.23.4 make build-exporter
fi

echo "1. Starting exporter with test config..."
echo "   Config: test-config.yaml"
echo "   Endpoint: http://localhost:10249"
echo ""
echo "   Run this in another terminal:"
echo "   ./bin/inspector server --config test-config.yaml"
echo ""
echo "2. After exporter starts, test the endpoint:"
echo ""
echo "   # Check if exporter is running:"
echo "   curl http://localhost:10249/status"
echo ""
echo "   # Get node-wide collapsed stacks:"
echo "   curl 'http://localhost:10249/flamegraph/collapsed?scope=node'"
echo ""
echo "   # Get pod-specific stacks:"
echo "   curl 'http://localhost:10249/flamegraph/collapsed?scope=pod&namespace=default&pod=test'"
echo ""
echo "   # Filter by event type:"
echo "   curl 'http://localhost:10249/flamegraph/collapsed?scope=node&event=PacketLoss'"
echo ""
echo "   # Reset after fetching:"
echo "   curl 'http://localhost:10249/flamegraph/collapsed?scope=node&reset=true'"
echo ""
echo "3. Or run the automated test script:"
echo "   ./test_flamegraph.sh"
echo ""
