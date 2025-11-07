# Creating a Pull Request for Flamegraph Feature

## Step 1: Check Current Status

```bash
cd /home/calelin/dev/kubeskoop
git status
```

You should see:
- `pkg/exporter/sink/flame.go` (new)
- `pkg/exporter/sink/flame_test.go` (new)
- `pkg/exporter/sink/sink.go` (modified)
- `pkg/exporter/cmd/server.go` (modified)

## Step 2: Create a Feature Branch

```bash
git checkout -b feature/flamegraph-kernel-stacks
```

## Step 3: Stage Your Changes

```bash
git add pkg/exporter/sink/flame.go
git add pkg/exporter/sink/flame_test.go
git add pkg/exporter/sink/sink.go
git add pkg/exporter/cmd/server.go
```

## Step 4: Commit Your Changes

```bash
git commit -m "feat: support flamegraph of kernel stack collection for pod/node

- Add flame aggregator sink to collect and aggregate kernel stacks
- Expose HTTP endpoint /flamegraph/collapsed for querying collapsed stacks
- Support node and pod scoped stack aggregation
- Support event type filtering and reset functionality
- Add unit tests for flame aggregator and HTTP handler

Fixes #137"
```

## Step 5: Push to Your Fork

If you haven't forked yet:
1. Go to https://github.com/alibaba/kubeskoop
2. Click "Fork" button
3. Add your fork as remote:

```bash
git remote add fork https://github.com/YOUR_USERNAME/kubeskoop.git
```

Then push:

```bash
git push fork feature/flamegraph-kernel-stacks
```

## Step 6: Create Pull Request

1. Go to https://github.com/alibaba/kubeskoop
2. You should see a banner suggesting to create a PR from your branch
3. Click "Compare & pull request"
4. Fill in the PR description:

```markdown
## Description
This PR adds support for flamegraph visualization of kernel stack collection for pods and nodes.

## Changes
- Added `FlameAggregator` sink to collect and aggregate kernel stacks from eBPF events
- Exposed HTTP endpoint `/flamegraph/collapsed` for querying collapsed stacks
- Support for node and pod scoped stack aggregation
- Event type filtering and reset functionality
- Unit tests included

## Usage
1. Enable flame sink in exporter config:
```yaml
event:
  sinks:
    - name: flame
  probes:
    - name: packetloss
      args:
        EnableStack: true
```

2. Query collapsed stacks:
```bash
# Node-wide
curl 'http://localhost:10249/flamegraph/collapsed?scope=node'

# Pod-specific
curl 'http://localhost:10249/flamegraph/collapsed?scope=pod&namespace=default&pod=my-pod'
```

3. Generate flamegraph:
```bash
curl 'http://localhost:10249/flamegraph/collapsed?scope=node' | flamegraph.pl > flamegraph.svg
```

## Testing
- [x] Unit tests added and passing
- [x] Manual testing completed
- [x] HTTP endpoint tested
- [x] Node and pod scopes verified

## Related Issue
Fixes #137
```

5. Click "Create pull request"

## Step 7: Address Review Comments

If reviewers request changes:
1. Make the changes
2. Commit and push:
```bash
git add .
git commit -m "fix: address review comments"
git push fork feature/flamegraph-kernel-stacks
```

The PR will automatically update.

## Alternative: Using GitHub CLI

If you have `gh` CLI installed:

```bash
# After pushing your branch
gh pr create --title "feat: support flamegraph of kernel stack collection for pod/node" \
  --body "$(cat <<'EOF'
## Description
This PR adds support for flamegraph visualization of kernel stack collection for pods and nodes.

## Changes
- Added FlameAggregator sink to collect and aggregate kernel stacks
- Exposed HTTP endpoint /flamegraph/collapsed
- Support for node and pod scoped aggregation
- Event type filtering and reset functionality

Fixes #137
EOF
)"
```

## PR Checklist

Before submitting, ensure:
- [ ] Code compiles without errors
- [ ] Unit tests pass
- [ ] Code follows project style guidelines
- [ ] Documentation updated (if needed)
- [ ] Commit message follows conventional commits format
- [ ] PR description is clear and complete

