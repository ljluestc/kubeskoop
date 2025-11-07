# Testing Flamegraph Feature

## Overview
This feature adds flamegraph support for kernel stack collection for pods and nodes. It aggregates kernel stacks from eBPF events and exposes them in folded format suitable for flamegraph visualization.

## Files Changed
1. `pkg/exporter/sink/flame.go` - New flame aggregator sink implementation
2. `pkg/exporter/sink/flame_test.go` - Unit tests
3. `pkg/exporter/sink/sink.go` - Registered "flame" sink type
4. `pkg/exporter/cmd/server.go` - Added `/flamegraph/collapsed` HTTP endpoint

## Manual Testing Steps

### 1. Build the Exporter
```bash
cd /home/calelin/dev/kubeskoop
GOTOOLCHAIN=go1.23.4 make build-exporter
```

### 2. Configure Exporter with Flame Sink

Create or update your exporter config file (e.g., `/etc/config/config.yaml`):

```yaml
event:
  sinks:
    - name: flame
    # You can keep other sinks too
    - name: stderr
  
  probes:
    - name: packetloss
      args:
        EnableStack: true  # Required to collect stacks
    - name: tcpretrans
    - name: tcpreset
```

### 3. Start the Exporter
```bash
./bin/inspector server --config /etc/config/config.yaml
```

### 4. Generate Some Events
To test, you need to trigger events that collect kernel stacks. For example:
- Packet loss events (if you have packet drops)
- TCP retransmissions
- TCP resets

### 5. Query Flamegraph Data

#### Get Node-wide Collapsed Stacks
```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=node'
```

Expected output format (folded stacks):
```
kfree_skb+0x100;nf_hook_slow+0x200;ip_forward+0x300 5
tcp_retransmit_skb+0x100;tcp_write_xmit+0x200 3
```

#### Get Pod-specific Collapsed Stacks
```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=pod&namespace=default&pod=my-pod'
```

#### Filter by Event Type
```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=node&event=PacketLoss'
```

#### Reset After Fetching
```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=node&reset=true'
```

### 6. Generate Flamegraph SVG

If you have `flamegraph.pl` installed:

```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=node' | \
  flamegraph.pl > flamegraph.svg
```

Or using the online tool at https://github.com/brendangregg/flamegraph

## Unit Tests

Run the unit tests (requires Go 1.23+):

```bash
cd /home/calelin/dev/kubeskoop
GOTOOLCHAIN=go1.23.4 go test ./pkg/exporter/sink -v -run TestFlame
```

## Integration Testing

1. Deploy exporter in a Kubernetes cluster
2. Enable flame sink in config
3. Enable stack collection for probes (e.g., `EnableStack: true` for packetloss)
4. Wait for events to be collected
5. Query the endpoint and verify:
   - Node scope returns aggregated stacks
   - Pod scope returns pod-specific stacks
   - Event filtering works
   - Reset functionality works

## Expected Behavior

- **Aggregation**: Stacks are aggregated by scope (node/pod) and event type
- **Counting**: Duplicate stacks are counted (shown as number after stack)
- **Format**: Output is in folded format: `stack;frames;here count`
- **Thread-safe**: Multiple goroutines can safely add events concurrently
- **Memory**: Data is kept in-memory until reset or exporter restart

## Troubleshooting

1. **No data returned**: 
   - Check if events are being generated (check logs)
   - Verify stack collection is enabled (`EnableStack: true`)
   - Check if flame sink is enabled in config

2. **Empty stacks**:
   - Verify kernel symbols are available (`/proc/kallsyms`)
   - Check eBPF programs are loaded successfully

3. **Build errors**:
   - Use `GOTOOLCHAIN=go1.23.4` to match go.mod requirements
   - Or use Docker build: `docker run --rm -v $(pwd):/work -w /work golang:1.23-bullseye make build-exporter`

