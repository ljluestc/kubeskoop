# Build and Test Guide for Flamegraph Feature

## Prerequisites

- Go 1.23+ (or use GOTOOLCHAIN to download automatically)
- Make
- curl (for testing HTTP endpoints)

## 1. Build the Exporter

### Option A: Using GOTOOLCHAIN (Recommended)
```bash
cd /home/calelin/dev/kubeskoop
GOTOOLCHAIN=go1.23.4 make build-exporter
```

This will:
- Automatically download Go 1.23.4 if needed
- Build the exporter binary to `bin/inspector`

### Option B: Using Docker
```bash
cd /home/calelin/dev/kubeskoop
docker run --rm \
  -v $(pwd):/go/src/github.com/alibaba/kubeskoop \
  -w /go/src/github.com/alibaba/kubeskoop \
  golang:1.23-bullseye \
  bash -c 'make build-exporter'
```

### Verify Build
```bash
ls -lh bin/inspector
# Should show the binary file
```

## 2. Run Unit Tests

### Run All Flamegraph Tests
```bash
cd /home/calelin/dev/kubeskoop
GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -v -run TestFlame
```

Expected output:
```
=== RUN   TestFlameAggregator
--- PASS: TestFlameAggregator (0.00s)
=== RUN   TestFlameSink
--- PASS: TestFlameSink (0.00s)
=== RUN   TestServeFlameCollapsed
--- PASS: TestServeFlameCollapsed (0.00s)
PASS
ok      github.com/alibaba/kubeskoop/pkg/exporter/sink    0.123s
```

### Run All Sink Tests
```bash
GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -v
```

### Run Tests with Coverage
```bash
GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -v -run TestFlame -cover
```

### Run Tests with Coverage Report
```bash
GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -run TestFlame -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
# Open coverage.html in browser
```

## 3. Manual Integration Testing

### Step 1: Create Test Config
The test config is already created at `test-config.yaml`. Verify it:
```bash
cat test-config.yaml
```

### Step 2: Start the Exporter
```bash
cd /home/calelin/dev/kubeskoop
./bin/inspector server --config test-config.yaml
```

You should see output like:
```
INFO[0000] start with config file test-config.yaml
INFO[0000] start event probe packetloss
INFO[0000] start event probe tcpretrans
INFO[0000] start event probe tcpreset
INFO[0000] inspector start metric server, listenAddr: [::]:10249
```

### Step 3: Test HTTP Endpoints (in another terminal)

#### Check Exporter Status
```bash
curl http://localhost:10249/status | jq .
```

#### Test Flamegraph Endpoint - Node Scope
```bash
# Get all node-wide collapsed stacks
curl 'http://localhost:10249/flamegraph/collapsed?scope=node'

# Expected output (if events have been collected):
# kfree_skb+0x100;nf_hook_slow+0x200;ip_forward+0x300 5
# tcp_retransmit_skb+0x100;tcp_write_xmit+0x200 3
```

#### Test Flamegraph Endpoint - Pod Scope
```bash
# Get pod-specific collapsed stacks
curl 'http://localhost:10249/flamegraph/collapsed?scope=pod&namespace=default&pod=test-pod'
```

#### Test Event Type Filtering
```bash
# Filter by event type
curl 'http://localhost:10249/flamegraph/collapsed?scope=node&event=PacketLoss'
curl 'http://localhost:10249/flamegraph/collapsed?scope=node&event=TCPRetrans'
```

#### Test Reset Functionality
```bash
# Get data
DATA=$(curl -s 'http://localhost:10249/flamegraph/collapsed?scope=node')
echo "Before reset: $DATA"

# Reset
curl -s 'http://localhost:10249/flamegraph/collapsed?scope=node&reset=true' > /dev/null

# Verify reset
DATA_AFTER=$(curl -s 'http://localhost:10249/flamegraph/collapsed?scope=node')
echo "After reset: $DATA_AFTER"
# Should be empty
```

### Step 4: Run Automated Test Script
```bash
cd /home/calelin/dev/kubeskoop
./test_flamegraph.sh
```

This script will:
- Check if exporter is running
- Test all endpoint variations
- Verify HTTP status codes
- Test reset functionality

## 4. Generate Flamegraph Visualization

### Option A: Using flamegraph.pl (if installed)
```bash
# Get collapsed stacks and generate SVG
curl 'http://localhost:10249/flamegraph/collapsed?scope=node' | \
  flamegraph.pl > flamegraph.svg

# Open in browser
xdg-open flamegraph.svg  # Linux
open flamegraph.svg      # macOS
```

### Option B: Using Online Tool
1. Get collapsed stacks:
```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=node' > collapsed.txt
```

2. Go to https://github.com/brendangregg/flamegraph
3. Copy contents of `collapsed.txt` and paste into the online tool
4. Download the generated SVG

## 5. Troubleshooting

### Build Issues

**Problem**: `compile: version "go1.21.5" does not match go tool version "go1.24.4"`

**Solution**: Use GOTOOLCHAIN
```bash
GOTOOLCHAIN=go1.23.4 make build-exporter
```

**Problem**: `go: command not found`

**Solution**: Install Go or use Docker build (see Option B above)

### Test Issues

**Problem**: Tests fail with "no such file or directory"

**Solution**: Make sure you're in the project root:
```bash
cd /home/calelin/dev/kubeskoop
```

**Problem**: Exporter won't start

**Solution**: Check config file exists and is valid:
```bash
cat test-config.yaml
./bin/inspector server --config test-config.yaml
```

### Runtime Issues

**Problem**: No data returned from endpoint

**Possible causes**:
1. No events have been collected yet (wait for network activity)
2. Stack collection not enabled (check `EnableStack: true` in config)
3. Flame sink not enabled (check config has `name: flame` in sinks)

**Solution**: 
- Check exporter logs for errors
- Verify probes are running: `curl http://localhost:10249/status`
- Wait for network events to occur

**Problem**: Endpoint returns 404

**Solution**: 
- Verify exporter is running: `curl http://localhost:10249/status`
- Check endpoint path: `/flamegraph/collapsed` (not `/flamegraph/collapse`)
- Check server logs for route registration

## 6. Quick Test Checklist

- [ ] Exporter builds successfully
- [ ] Unit tests pass
- [ ] Exporter starts without errors
- [ ] `/status` endpoint returns 200
- [ ] `/flamegraph/collapsed?scope=node` returns 200 (may be empty initially)
- [ ] Event filtering works (`?event=PacketLoss`)
- [ ] Reset functionality works (`?reset=true`)
- [ ] Pod scope works (`?scope=pod&namespace=X&pod=Y`)

## 7. Example Test Session

```bash
# 1. Build
cd /home/calelin/dev/kubeskoop
GOTOOLCHAIN=go1.23.4 make build-exporter

# 2. Run unit tests
GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -v -run TestFlame

# 3. Start exporter (in background)
./bin/inspector server --config test-config.yaml &
EXPORTER_PID=$!

# 4. Wait for startup
sleep 2

# 5. Test endpoints
curl http://localhost:10249/status
curl 'http://localhost:10249/flamegraph/collapsed?scope=node'

# 6. Stop exporter
kill $EXPORTER_PID
```

## 8. Continuous Testing

For continuous testing during development:

```bash
# Terminal 1: Run exporter
./bin/inspector server --config test-config.yaml

# Terminal 2: Watch endpoint
watch -n 1 "curl -s 'http://localhost:10249/flamegraph/collapsed?scope=node' | head -20"

# Terminal 3: Run tests on file changes
find pkg/exporter/sink -name "*.go" | entr -r go test ./pkg/exporter/sink -run TestFlame
```

