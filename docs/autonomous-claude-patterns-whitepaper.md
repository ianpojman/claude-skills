# Autonomous Claude Patterns: A Comprehensive Guide

**Version**: 1.0
**Date**: 2025-11-19
**Author**: Based on production experience and community research

---

## Table of Contents

1. [Introduction](#introduction)
2. [The Multi-Stage Task Problem](#the-problem)
3. [Pattern Comparison](#pattern-comparison)
4. [Pattern 1: Continuous Claude (NPM Tool)](#pattern-1-continuous-claude)
5. [Pattern 2: Shell Loop with Iteration Forcing](#pattern-2-shell-loop)
6. [Pattern 3: Active Monitoring Scripts](#pattern-3-monitoring-scripts)
7. [Pattern 4: Claude Headless Mode](#pattern-4-headless-mode)
8. [Pattern 5: Autonomous Supervision Skill](#pattern-5-skill-based)
9. [Combining Patterns](#combining-patterns)
10. [Production Case Study](#case-study)
11. [Best Practices](#best-practices)

---

## Introduction

Claude Code is powerful for autonomous tasks, but often stops prematurely between stages of multi-step workflows. This whitepaper documents proven patterns for maintaining autonomous execution across hours-long tasks.

**The Core Challenge**: Claude's natural tendency to pause and seek confirmation after completing a sub-task, even when explicitly instructed to continue.

**The Solution**: Structured patterns that force continuation through iteration counting, state machines, and explicit progression logic.

---

## The Multi-Stage Task Problem

### Typical Failure Pattern

```
User: "Build the project, run tests, and fix any failures. Be autonomous."

Claude:
  ✓ Starts build
  ✓ Build completes
  ✗ "The build is complete. Let me know when you're ready for tests."
  [STOPS WAITING FOR USER]
```

### What We Want Instead

```
User: "Build the project, run tests, and fix any failures. Be autonomous."

Claude:
  ✓ Starts build (Stage 1/3)
  ✓ Build completes
  ✓ "Stage 1/3 complete. Proceeding to Stage 2/3: Running tests..."
  ✓ Runs tests automatically
  ✓ Tests fail
  ✓ "Stage 2/3: Tests failed. Proceeding to Stage 3/3: Analyzing failures..."
  ✓ Fixes issues
  ✓ "Stage 3/3 complete. Rerunning tests..."
  [CONTINUES UNTIL SUCCESS]
```

---

## Pattern Comparison

| Pattern | Setup Complexity | Best For | Autonomy Level | Overnight Capable | User Control |
|---------|-----------------|----------|----------------|-------------------|--------------|
| **Continuous Claude** | Low (npm install) | Code iterations | ⭐⭐⭐⭐ | ✅ Yes | Medium |
| **Shell Loop** | Medium (bash script) | Custom workflows | ⭐⭐⭐⭐⭐ | ✅ Yes | High |
| **Monitoring Scripts** | Medium (event-driven) | Build/test pipelines | ⭐⭐⭐⭐ | ✅ Yes | High |
| **Headless Mode** | Low (built-in flag) | Single-run tasks | ⭐⭐ | ❌ No | Low |
| **Supervision Skill** | Low (skill file) | Mixed task types | ⭐⭐⭐ | ⚠️ Partial | Medium |

---

## Pattern 1: Continuous Claude (NPM Tool)

### Overview

Open-source CLI wrapper that runs Claude in a loop with persistent context.

**Repository**: `AnandChowdhary/continuous-claude`

### Installation

```bash
npm install -g continuous-claude
```

### Basic Usage

```bash
continuous-claude "Fix all TypeScript errors in the project"
```

### Advanced Usage with Configuration

```bash
# Create config file
cat > .continuous-claude.json <<EOF
{
  "maxIterations": 50,
  "iterationDelay": 5000,
  "contextFile": ".claude-context",
  "stopCondition": "all tests pass"
}
EOF

# Run with config
continuous-claude "Refactor authentication system to use JWT"
```

### Example Prompts

#### Example 1: Iterative Bug Fixing

**Prompt**:
```
Fix all linting errors in src/. After each file, run eslint
again and continue to the next file. Don't stop until
eslint reports 0 errors.
```

**What Happens**:
- Iteration 1: Fixes errors in `file1.js`, runs eslint → 47 errors remain
- Iteration 2: Fixes errors in `file2.js`, runs eslint → 32 errors remain
- ...continues until 0 errors
- Iteration 15: Runs eslint → 0 errors → Task complete

#### Example 2: Test-Driven Development

**Prompt**:
```
Implement the UserService class to make all tests pass.
Run 'npm test' after each change. Keep iterating until
all 25 tests are green.
```

**What Happens**:
- Iteration 1: Implements basic structure → 5/25 tests pass
- Iteration 2: Adds validation logic → 12/25 tests pass
- Iteration 3: Fixes edge cases → 18/25 tests pass
- ...continues...
- Iteration 7: All 25 tests pass → Task complete

#### Example 3: Documentation Generation

**Prompt**:
```
Generate JSDoc comments for all exported functions in src/.
After each file, run 'npm run docs:validate'. Continue until
documentation coverage reaches 100%.
```

### Pros & Cons

**Pros**:
- Zero-config simplicity
- Handles context persistence
- Built-in iteration limiting
- Works with any programming language

**Cons**:
- Less control over iteration logic
- Can't easily integrate with external tools (AWS CLI, etc.)
- Black-box behavior (harder to debug)

### When to Use

- Pure code iteration tasks
- When you want "set it and forget it" simplicity
- Tasks measurable by test success or linter output

---

## Pattern 2: Shell Loop with Iteration Forcing

### Overview

Custom bash script with explicit iteration counter that forces Claude to continue.

### Basic Template

```bash
#!/bin/bash

ITERATION_COUNT=50
TASK_DESC="Your task description here"

for i in $(seq 1 $ITERATION_COUNT); do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "ITERATION $i/$ITERATION_COUNT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cat <<EOF | claude -p --dangerously-skip-permissions
$TASK_DESC

Current iteration: $i of $ITERATION_COUNT
You MUST continue to the next step. Do not stop or ask for permission.

Previous iterations completed:
$(cat .iteration_log 2>/dev/null || echo "None")

Next step: [Your logic here]
EOF

  # Log this iteration
  echo "Iteration $i: $(date)" >> .iteration_log

  # Optional: Check completion condition
  if check_completion_condition; then
    echo "✅ Task completed at iteration $i"
    break
  fi

  sleep 5
done

echo "Loop complete. Total iterations: $i"
```

### Advanced Template with State Machine

```bash
#!/bin/bash

MAX_ITERATIONS=100
CURRENT_STATE="INIT"
ITERATION=1

while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "[$ITERATION/$MAX_ITERATIONS] State: $CURRENT_STATE"

  case $CURRENT_STATE in
    "INIT")
      cat <<EOF | claude -p --dangerously-skip-permissions
Initialize the project:
1. Create directory structure
2. Install dependencies
3. Set up configuration

When complete, create a file: .state_INIT_COMPLETE
EOF

      if [ -f .state_INIT_COMPLETE ]; then
        CURRENT_STATE="BUILD"
        ITERATION=1  # Reset counter for new state
      fi
      ;;

    "BUILD")
      cat <<EOF | claude -p --dangerously-skip-permissions
Build the project. Current build iteration: $ITERATION

If build succeeds, create: .state_BUILD_COMPLETE
If build fails, analyze and fix the error, then retry.
EOF

      if [ -f .state_BUILD_COMPLETE ]; then
        CURRENT_STATE="TEST"
        ITERATION=1
      fi
      ;;

    "TEST")
      cat <<EOF | claude -p --dangerously-skip-permissions
Run tests. Current test iteration: $ITERATION

If all tests pass, create: .state_TEST_COMPLETE
If tests fail, fix failures and rerun tests.
EOF

      if [ -f .state_TEST_COMPLETE ]; then
        CURRENT_STATE="COMPLETE"
      fi
      ;;

    "COMPLETE")
      echo "✅ All states completed successfully!"
      exit 0
      ;;
  esac

  ((ITERATION++))
  sleep 10
done

echo "⚠️ Max iterations reached in state: $CURRENT_STATE"
```

### Example Prompts

#### Example 1: Database Migration

**Script**:
```bash
#!/bin/bash

for i in {1..20}; do
  cat <<EOF | claude -p --dangerously-skip-permissions
Migration Task - Iteration $i/20

Current status: $(cat .migration_status 2>/dev/null || echo "Not started")

Steps:
1. Create migration file if not exists
2. Run migration: npm run migrate
3. Verify schema: npm run verify-schema
4. Update .migration_status with results

If any step fails, fix the issue and retry.
Do not stop until .migration_status shows "COMPLETE".
EOF

  if grep -q "COMPLETE" .migration_status 2>/dev/null; then
    echo "✅ Migration complete at iteration $i"
    break
  fi

  sleep 15
done
```

**Example Output**:
```
[1/20] Creating migration file...
[2/20] Running migration... ERROR: Column 'email' already exists
[3/20] Fixing migration file...
[4/20] Running migration... SUCCESS
[5/20] Verifying schema... SUCCESS
✅ Migration complete at iteration 5
```

#### Example 2: Multi-Service Deployment

**Script**:
```bash
#!/bin/bash

SERVICES=("auth" "api" "worker" "frontend")
ITERATION=1
MAX_PER_SERVICE=10

for service in "${SERVICES[@]}"; do
  echo "Deploying $service..."

  for i in $(seq 1 $MAX_PER_SERVICE); do
    cat <<EOF | claude -p --dangerously-skip-permissions
Deploy $service service - Attempt $i/$MAX_PER_SERVICE

Steps:
1. Build $service: docker build -t $service .
2. Push to registry: docker push registry/$service
3. Deploy to k8s: kubectl apply -f k8s/$service.yaml
4. Verify health: curl http://$service/health

If deployment fails, analyze logs and fix issues.
Create .deploy_${service}_COMPLETE when successful.
EOF

    if [ -f .deploy_${service}_COMPLETE ]; then
      echo "✅ $service deployed successfully"
      break
    fi

    sleep 20
  done

  if [ ! -f .deploy_${service}_COMPLETE ]; then
    echo "❌ Failed to deploy $service after $MAX_PER_SERVICE attempts"
    exit 1
  fi
done

echo "🎉 All services deployed successfully!"
```

### Pros & Cons

**Pros**:
- Complete control over iteration logic
- Can integrate any external tools
- Easy to debug (plain bash)
- Supports complex state machines

**Cons**:
- Requires bash scripting knowledge
- More setup work than Continuous Claude
- Need to handle edge cases manually

### When to Use

- Custom workflows with external tool integration
- Multi-state pipelines (build → test → deploy)
- When you need full control over iteration logic

---

## Pattern 3: Active Monitoring Scripts

### Overview

Event-driven scripts that monitor external systems and trigger actions when conditions are met.

### Basic Monitoring Template

```bash
#!/bin/bash

MAX_WAIT_MINUTES=60
CHECK_INTERVAL_SECONDS=30
ELAPSED=0

echo "Monitoring started..."

while [ $ELAPSED -lt $((MAX_WAIT_MINUTES * 60)) ]; do
  CURRENT_STATUS=$(check_external_system_status)

  echo "[$(date +'%H:%M:%S')] Status: $CURRENT_STATUS"

  case $CURRENT_STATUS in
    "SUCCESS")
      echo "✅ System ready. Triggering next action..."
      trigger_next_action
      exit 0
      ;;

    "FAILED")
      echo "❌ System failed. Analyzing..."
      analyze_failure
      exit 1
      ;;

    "IN_PROGRESS")
      echo "⏳ Still running... (${ELAPSED}s elapsed)"
      ;;
  esac

  sleep $CHECK_INTERVAL_SECONDS
  ELAPSED=$((ELAPSED + CHECK_INTERVAL_SECONDS))
done

echo "⚠️ Timeout after ${MAX_WAIT_MINUTES} minutes"
exit 1
```

### Advanced Multi-Stage Monitor

```bash
#!/bin/bash
# Multi-stage pipeline monitor with auto-progression

STAGES=("BUILD" "TEST" "DEPLOY")
CURRENT_STAGE=0
MAX_STAGE_TIME=1800  # 30 minutes per stage

monitor_and_progress() {
  local stage=$1
  local start_time=$(date +%s)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Stage: $stage"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  while true; do
    elapsed=$(($(date +%s) - start_time))

    if [ $elapsed -gt $MAX_STAGE_TIME ]; then
      echo "⏱️ Stage timeout after ${MAX_STAGE_TIME}s"
      return 1
    fi

    status=$(get_stage_status "$stage")

    echo "[$(date +'%H:%M:%S')] $stage status: $status (${elapsed}s)"

    case $status in
      "COMPLETE")
        echo "✅ $stage complete"
        return 0
        ;;

      "FAILED")
        echo "❌ $stage failed"
        return 1
        ;;

      *)
        sleep 30
        ;;
    esac
  done
}

# Main loop
for stage in "${STAGES[@]}"; do
  if monitor_and_progress "$stage"; then
    echo "Immediately proceeding to next stage..."
    # NO WAITING - auto-trigger next stage
    trigger_next_stage
  else
    echo "Pipeline halted at stage: $stage"
    exit 1
  fi
done

echo "🎉 All stages completed successfully!"
```

### Example Prompts

#### Example 1: CI/CD Pipeline Monitor

**Scenario**: Monitor GitLab build, then auto-deploy when complete

**Script**:
```bash
#!/bin/bash

PIPELINE_ID="12345"
DEPLOYMENT_ENV="production"

echo "Monitoring GitLab pipeline $PIPELINE_ID..."

while true; do
  STATE=$(glab pipeline status | grep "state:" | awk '{print $3}')

  echo "[$(date +'%H:%M:%S')] Pipeline state: $STATE"

  case $STATE in
    "success")
      echo "✅ Build succeeded!"
      echo "Automatically deploying to $DEPLOYMENT_ENV..."

      # Trigger deployment WITHOUT user confirmation
      ./deploy.sh $DEPLOYMENT_ENV

      if [ $? -eq 0 ]; then
        echo "🎉 Deployment complete!"
        exit 0
      else
        echo "❌ Deployment failed"
        exit 1
      fi
      ;;

    "failed")
      echo "❌ Build failed. Analyzing logs..."

      # Automatically fetch and analyze logs
      glab pipeline ci trace | tail -100 > /tmp/build-failure.log

      cat <<EOF | claude -p --dangerously-skip-permissions
The build failed. Analyze these logs and suggest fixes:

$(cat /tmp/build-failure.log)

Create a fix commit and push to trigger rebuild.
EOF
      exit 1
      ;;

    *)
      sleep 30
      ;;
  esac
done
```

**Example Output**:
```
[14:23:10] Pipeline state: running
[14:23:40] Pipeline state: running
[14:24:10] Pipeline state: success
✅ Build succeeded!
Automatically deploying to production...
Deployment triggered: deployment-12345
[14:25:30] Deployment complete!
🎉 Deployment complete!
```

#### Example 2: EMR Cluster Monitor with Auto-Analysis

**Scenario**: Monitor multiple EMR clusters, auto-analyze failures

**Script**:
```bash
#!/bin/bash

CLUSTER_IDS=("j-ABC123" "j-DEF456" "j-GHI789")
CHECK_INTERVAL=60

declare -A cluster_states

while true; do
  all_complete=true

  for cluster_id in "${CLUSTER_IDS[@]}"; do
    if [ "${cluster_states[$cluster_id]}" == "DONE" ]; then
      continue
    fi

    state=$(aws emr describe-cluster --cluster-id "$cluster_id" \
      | jq -r '.Cluster.Status.State')

    echo "[$cluster_id] $state"

    case $state in
      "TERMINATED")
        echo "✅ $cluster_id succeeded"
        cluster_states[$cluster_id]="DONE"

        # Auto-verify output
        ./verify-output.sh "$cluster_id"
        ;;

      "TERMINATED_WITH_ERRORS")
        echo "❌ $cluster_id failed - AUTO-ANALYZING"
        cluster_states[$cluster_id]="DONE"

        # Automatically fetch and analyze failure
        ./fetch-emr-logs.sh "$cluster_id" > /tmp/${cluster_id}-logs.txt

        cat <<EOF | claude -p --dangerously-skip-permissions
EMR cluster $cluster_id failed. Analyze logs and determine root cause:

$(cat /tmp/${cluster_id}-logs.txt)

If it's a fixable code issue, apply the fix and create a file:
.fix_applied_${cluster_id}
EOF

        # If fix applied, relaunch cluster automatically
        if [ -f .fix_applied_${cluster_id} ]; then
          echo "Fix applied. Relaunching $cluster_id..."
          new_cluster=$(./relaunch-cluster.sh)
          CLUSTER_IDS+=("$new_cluster")
        fi
        ;;

      *)
        all_complete=false
        ;;
    esac
  done

  if $all_complete; then
    echo "🎉 All clusters complete!"
    exit 0
  fi

  sleep $CHECK_INTERVAL
done
```

#### Example 3: Test Suite Monitor with Auto-Fix

**Script**:
```bash
#!/bin/bash

MAX_FIX_ATTEMPTS=5
ATTEMPT=1

while [ $ATTEMPT -le $MAX_FIX_ATTEMPTS ]; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Run #$ATTEMPT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  npm test > /tmp/test-results.txt 2>&1
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All tests pass!"
    exit 0
  fi

  echo "❌ Tests failed. Auto-analyzing and fixing..."

  cat <<EOF | claude -p --dangerously-skip-permissions
Test run $ATTEMPT/$MAX_FIX_ATTEMPTS failed.

Test output:
$(cat /tmp/test-results.txt)

Analyze the failures, apply fixes, and create a file:
.fixes_applied_attempt_${ATTEMPT}

Do not wait for user approval. Fix and proceed.
EOF

  # Wait for Claude to apply fixes
  while [ ! -f .fixes_applied_attempt_${ATTEMPT} ]; do
    sleep 5
  done

  echo "Fixes applied. Rerunning tests..."
  ((ATTEMPT++))
  sleep 10
done

echo "⚠️ Tests still failing after $MAX_FIX_ATTEMPTS attempts"
exit 1
```

### Pros & Cons

**Pros**:
- Event-driven (efficient, not polling constantly)
- Natural integration with external systems
- Can trigger complex workflows
- Works well with TTS for notifications

**Cons**:
- Requires knowledge of system APIs
- Need error handling for API failures
- Can miss events if polling interval too long

### When to Use

- CI/CD pipeline automation
- Cloud infrastructure monitoring (AWS, GCP, Azure)
- Any workflow triggered by external system state changes

---

## Pattern 4: Claude Headless Mode

### Overview

Built-in Claude Code flag for non-interactive execution. Simplest pattern but least flexible.

### Basic Usage

```bash
# Single command
echo "Fix all TypeScript errors" | claude -p --dangerously-skip-permissions

# With heredoc
claude -p --dangerously-skip-permissions <<EOF
Analyze the codebase and:
1. Fix all lint errors
2. Update outdated dependencies
3. Run tests to verify
EOF
```

### Sequential Task Execution

```bash
#!/bin/bash

TASKS=(
  "Fix all ESLint errors in src/"
  "Update all dependencies to latest"
  "Run npm test and fix any failures"
  "Update README with new API docs"
)

for task in "${TASKS[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Task: $task"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo "$task" | claude -p --dangerously-skip-permissions

  if [ $? -ne 0 ]; then
    echo "❌ Task failed: $task"
    exit 1
  fi

  echo "✅ Task complete"
  sleep 10
done

echo "🎉 All tasks complete!"
```

### Example Prompts

#### Example 1: Batch Documentation Generation

**Script**:
```bash
#!/bin/bash

find src/ -name "*.ts" | while read file; do
  echo "Documenting $file..."

  claude -p --dangerously-skip-permissions <<EOF
Add comprehensive JSDoc comments to this file: $file

Requirements:
- Document all exported functions
- Include @param, @returns, @throws
- Add examples for complex functions

Do not ask for confirmation. Apply the changes.
EOF

  echo "✅ $file documented"
  sleep 5
done
```

#### Example 2: Database Schema Migration

**Script**:
```bash
#!/bin/bash

MIGRATIONS=$(ls migrations/*.sql | sort)

for migration in $MIGRATIONS; do
  echo "Applying migration: $migration"

  claude -p --dangerously-skip-permissions <<EOF
Apply this database migration: $migration

1. Review the SQL for syntax errors
2. Run: psql -d mydb -f $migration
3. Verify migration: psql -d mydb -c "SELECT version FROM schema_versions"
4. If it fails, rollback and report the error

Do not wait for approval. Execute immediately.
EOF

  if [ ! -f ".migration_$(basename $migration)_complete" ]; then
    echo "❌ Migration failed: $migration"
    exit 1
  fi
done

echo "✅ All migrations applied"
```

#### Example 3: Code Quality Enforcement

**Script**:
```bash
#!/bin/bash

echo "Running code quality pipeline..."

# Stage 1: Linting
claude -p --dangerously-skip-permissions <<EOF
Fix all ESLint errors:
1. Run: npm run lint
2. Fix all errors automatically where possible
3. Report any that need manual review

Create .lint_complete when done.
EOF

# Wait for completion
while [ ! -f .lint_complete ]; do sleep 5; done

# Stage 2: Type checking
claude -p --dangerously-skip-permissions <<EOF
Fix all TypeScript errors:
1. Run: npm run typecheck
2. Fix all type errors
3. Ensure no 'any' types remain

Create .types_complete when done.
EOF

while [ ! -f .types_complete ]; do sleep 5; done

# Stage 3: Testing
claude -p --dangerously-skip-permissions <<EOF
Ensure 100% test coverage:
1. Run: npm test -- --coverage
2. Write tests for any uncovered code
3. Achieve 100% coverage

Create .tests_complete when done.
EOF

while [ ! -f .tests_complete ]; do sleep 5; done

echo "✅ Code quality pipeline complete!"
```

### Pros & Cons

**Pros**:
- Built-in (no installation needed)
- Simple for linear task sequences
- Good for CI/CD integration
- No external dependencies

**Cons**:
- No iteration control (runs once)
- Can't handle "retry until success" scenarios
- Limited state management
- No auto-progression between stages

### When to Use

- CI/CD pre-commit hooks
- Simple batch processing tasks
- One-time migration scripts
- When tasks are independent (don't depend on previous results)

---

## Pattern 5: Autonomous Supervision Skill

### Overview

A Claude Code skill file that provides explicit instructions for maintaining autonomous execution. Works by reminding Claude to check iteration progress and avoid stopping prematurely.

### Skill File Location

```
~/.claude/skills/autonomous-task-supervision.md
```

### How to Use

**Method 1: Explicit Invocation**
```
User: "Use the autonomous-task-supervision skill to monitor
these builds and launch tests when complete."
```

**Method 2: Automatic Activation**
The skill automatically activates when the user says:
- "be autonomous"
- "be proactive"
- "don't stop"
- "monitor actively"
- "work overnight"

### Example Prompts

#### Example 1: Multi-Stage Build Pipeline

**User Prompt**:
```
Build the project, run tests, and deploy to staging.
Use autonomous-task-supervision skill.
```

**Claude's Response (with skill)**:
```
Multi-stage pipeline detected. Creating task plan:

Stage 1/3: BUILD
Stage 2/3: TEST
Stage 3/3: DEPLOY

Stage 1/3: Starting build...
[runs build]
Build complete. Stage 1/3 done.

Immediately proceeding to Stage 2/3: Running tests...
[runs tests]
Tests complete (23/25 passed). Stage 2/3 done.

Immediately proceeding to Stage 3/3: Deploying to staging...
[deploys]
Deployment complete. Stage 3/3 done.

✅ All stages completed successfully!
```

#### Example 2: Overnight EMR Job Monitoring

**User Prompt**:
```
Monitor these 10 EMR clusters overnight. If any fail,
analyze logs and relaunch with fixes. Be autonomous.
```

**Claude's Response (with skill)**:
```
Long-running monitoring task detected.
Target duration: 8 hours (overnight)
Check interval: 30 minutes = 16 iterations

Creating monitoring plan:
- Iteration 1-16: Check cluster status every 30min
- On failure: Auto-analyze logs + apply fixes + relaunch
- On success: Verify output data

Iteration 1/16: Checking 10 clusters... [22:00]
Status: All running
Next check in 30 minutes.

Iteration 2/16: Checking 10 clusters... [22:30]
Status: Cluster j-XYZ failed
IMMEDIATELY analyzing failure...
[analyzes logs]
Root cause: Executor OOM
Applying fix: Increase executor memory 18GB → 20GB
Relaunching cluster j-XYZ with fix...
New cluster: j-ABC launched
Continuing monitoring...

Iteration 3/16: Checking 11 clusters... [23:00]
[continues through all 16 iterations automatically]

Iteration 16/16: Checking clusters... [06:00]
✅ All 10 clusters succeeded!
Verifying output data...
✅ Data validation passed!

Overnight monitoring complete. All jobs successful.
```

#### Example 3: Iterative Optimization

**User Prompt**:
```
Optimize the database queries in src/. Run benchmarks after
each change. Continue until queries are <100ms. Be proactive.
```

**Claude's Response (with skill)**:
```
Iterative optimization task detected.
Target: All queries <100ms
Max iterations: 10

Iteration 1/10:
- Analyzing queries in src/
- Found 5 slow queries (avg: 450ms)
- Optimizing: Added index on users.email
- Running benchmarks...
- Results: avg 320ms (improvement: 130ms)
- Target not met. Continuing...

Iteration 2/10:
- Optimizing: Added index on orders.user_id
- Running benchmarks...
- Results: avg 180ms (improvement: 140ms)
- Target not met. Continuing...

Iteration 3/10:
- Optimizing: Rewrote N+1 query to use JOIN
- Running benchmarks...
- Results: avg 75ms (improvement: 105ms)
- ✅ Target met! (75ms < 100ms)

Optimization complete in 3 iterations.
Final performance: 75ms average (6x improvement)
```

#### Example 4: Research → Implement → Test Pipeline

**User Prompt**:
```
Research best practices for rate limiting APIs, implement it
in our Express server, and write comprehensive tests.
Don't stop until tests are at 100% coverage.
```

**Claude's Response (with skill)**:
```
Multi-stage pipeline: Research → Implement → Test
Target: 100% test coverage

Stage 1/3: RESEARCH
Researching API rate limiting best practices...
- Analyzed 15 articles
- Compared 4 popular libraries
- Recommendation: express-rate-limit with Redis
Stage 1/3 complete. Findings documented.

Immediately proceeding to Stage 2/3: IMPLEMENTATION

Stage 2/3: IMPLEMENTATION
Implementing rate limiting...
- Installed express-rate-limit@6.8.0
- Configured Redis store
- Added middleware to app.ts
- Added per-route limits
Implementation complete.

Immediately proceeding to Stage 3/3: TESTING

Stage 3/3: TESTING (Target: 100% coverage)

Test Iteration 1/5:
- Written 8 test cases
- Running: npm test -- --coverage
- Coverage: 72%
- Writing additional tests...

Test Iteration 2/5:
- Written 5 more test cases
- Running: npm test -- --coverage
- Coverage: 89%
- Identifying uncovered edge cases...

Test Iteration 3/5:
- Written 3 edge case tests
- Running: npm test -- --coverage
- Coverage: 97%
- Adding tests for error paths...

Test Iteration 4/5:
- Written 2 error path tests
- Running: npm test -- --coverage
- Coverage: 100%
- ✅ Target achieved!

Stage 3/3 complete.

🎉 Entire pipeline complete:
- Research: ✅
- Implementation: ✅
- Testing: ✅ (100% coverage)
```

### Pros & Cons

**Pros**:
- Zero installation (just a skill file)
- Works within normal Claude sessions
- Reminds Claude of iteration counting
- Integrates naturally with conversation flow

**Cons**:
- Requires Claude to "remember" to follow skill
- Can still stop if Claude strongly thinks task is done
- No external enforcement mechanism
- Effectiveness varies by task complexity

### When to Use

- Mixed task types (research + code + tests)
- When you want natural conversation flow
- Tasks that benefit from Claude's reasoning
- When external tools (monitoring scripts) aren't appropriate

---

## Combining Patterns

### Pattern Combo 1: Monitoring Script + Headless Mode

**Scenario**: Monitor build, then trigger multiple deployments

```bash
#!/bin/bash

# Stage 1: Monitor build (Pattern 3)
echo "Stage 1: Monitoring build..."

while true; do
  STATE=$(glab pipeline status | grep "state:" | awk '{print $3}')

  if [ "$STATE" = "success" ]; then
    echo "✅ Build complete. Proceeding to deployments..."
    break
  elif [ "$STATE" = "failed" ]; then
    echo "❌ Build failed"
    exit 1
  fi

  sleep 30
done

# Stage 2: Parallel deployments (Pattern 4)
echo "Stage 2: Deploying to all environments..."

ENVS=("dev" "staging" "prod")

for env in "${ENVS[@]}"; do
  (
    claude -p --dangerously-skip-permissions <<EOF
Deploy to $env environment:
1. Run: ./deploy.sh $env
2. Verify: curl https://$env.example.com/health
3. Create .deploy_${env}_complete on success
EOF
  ) &
done

# Wait for all deployments
wait

echo "✅ All deployments complete!"
```

### Pattern Combo 2: Shell Loop + Skill-Based

**Scenario**: Multi-day refactoring project

```bash
#!/bin/bash

DAY_COUNT=5
TARGET_FILES=150

for day in $(seq 1 $DAY_COUNT); do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Day $day/$DAY_COUNT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cat <<EOF | claude -p --dangerously-skip-permissions
Day $day/$DAY_COUNT of refactoring project.

Use autonomous-task-supervision skill.

Goal: Refactor $((TARGET_FILES / DAY_COUNT)) files today.

Steps:
1. Find next batch of files needing refactoring
2. Apply refactoring patterns
3. Run tests after each file
4. Fix any test failures
5. Update progress tracker

Do not stop until today's quota is met.
Create .day_${day}_complete when done.
EOF

  # Wait for day's work to complete
  while [ ! -f .day_${day}_complete ]; do
    echo "  Checking progress..."
    sleep 300  # Check every 5 minutes
  done

  echo "✅ Day $day complete!"
  sleep 60
done

echo "🎉 5-day refactoring project complete!"
```

### Pattern Combo 3: Continuous Claude + Monitoring Script

**Scenario**: Code changes with external validation

```bash
#!/bin/bash

# Terminal 1: Run continuous claude for code changes
continuous-claude "Implement feature X. Run after each change: npm test" &
CLAUDE_PID=$!

# Terminal 2: Monitor for success condition
while kill -0 $CLAUDE_PID 2>/dev/null; do
  if npm test 2>/dev/null && grep -q "100% coverage" coverage/summary.txt; then
    echo "✅ Success condition met! Stopping Claude..."
    kill $CLAUDE_PID

    # Auto-deploy
    echo "Automatically deploying..."
    ./deploy.sh production
    exit 0
  fi

  sleep 30
done
```

---

## Production Case Study: Kryo Serialization Bug Fix

### Background

Real production scenario: Fixing Kryo serialization errors in EMR Spark jobs. Required testing 5 different serialization configurations across multiple hours of data.

### Challenge

Multi-stage process:
1. Wait for GitLab build (10-15 minutes)
2. Launch 5 test clusters in parallel (different configs)
3. Monitor all 5 clusters (30-40 minutes each)
4. Analyze results and update documentation

**Problem**: Claude would launch Test 1, then stop and wait for user confirmation.

### Solution: Combined Pattern Approach

```bash
#!/bin/bash
# autonomous-kryo-test-pipeline.sh

set -e

PIPELINE_ID=$(git log -1 --format=%H | xargs -I {} glab pipeline list --sha {} -n 1 | grep -oP '\d+')
STAGE="BUILD"
MAX_ITERATIONS=40
ITERATION=1

# Pattern 3: Monitoring Script with State Machine
while [ $ITERATION -le $MAX_ITERATIONS ]; do
  echo "[$ITERATION/$MAX_ITERATIONS] Stage: $STAGE"

  case $STAGE in
    "BUILD")
      BUILD_STATE=$(glab pipeline status | grep "state:" | awk '{print $3}')

      if [ "$BUILD_STATE" = "success" ]; then
        echo "✅ BUILD complete. Proceeding to LAUNCH_TESTS..."
        [ ! -f ~/.tts_paused ] && say -v "Ava (Premium)" "Build complete. Launching tests." &
        STAGE="LAUNCH_TESTS"
        continue
      elif [ "$BUILD_STATE" = "failed" ]; then
        echo "❌ BUILD failed"
        exit 1
      fi
      ;;

    "LAUNCH_TESTS")
      echo "Launching 5 Kryo tests in parallel..."

      # Test configurations
      USE_LATEST_JAR=true HOUR=14 SPARK_SERIALIZER=java ./run-indexing.sh ... &
      USE_LATEST_JAR=true HOUR=15 SPARK_SERIALIZER=kryo KRYO_BUFFER_SIZE=128m ./run-indexing.sh ... &
      USE_LATEST_JAR=true HOUR=16 SPARK_SERIALIZER=kryo SPARK_CLOSURE_SERIALIZER=org.apache.spark.serializer.JavaSerializer ./run-indexing.sh ... &
      USE_LATEST_JAR=true HOUR=17 SPARK_SERIALIZER=kryo KRYO_REGISTRATOR=com.traffic.util.TrafficKryoRegistrator ./run-indexing.sh ... &
      USE_LATEST_JAR=true HOUR=18 SPARK_SERIALIZER=java ./run-indexing.sh ... &

      wait  # Wait for all launches

      echo "✅ LAUNCH_TESTS complete. Proceeding to MONITOR_TESTS..."
      [ ! -f ~/.tts_paused ] && say -v "Ava (Premium)" "All tests launched. Monitoring." &
      STAGE="MONITOR_TESTS"
      MAX_ITERATIONS=120  # Extend for monitoring
      ITERATION=1
      continue
      ;;

    "MONITOR_TESTS")
      # Check all cluster statuses
      COMPLETED=0
      FAILED=0
      RUNNING=0

      for cluster_id in "${CLUSTER_IDS[@]}"; do
        STATUS=$(aws emr describe-cluster --cluster-id "$cluster_id" | jq -r '.Cluster.Status.State')

        case $STATUS in
          "TERMINATED") ((COMPLETED++)) ;;
          "TERMINATED_WITH_ERRORS") ((FAILED++)) ;;
          *) ((RUNNING++)) ;;
        esac
      done

      echo "  Status: $COMPLETED completed, $FAILED failed, $RUNNING running"

      if [ $RUNNING -eq 0 ]; then
        echo "✅ MONITOR_TESTS complete"
        echo "🎉 ENTIRE PIPELINE COMPLETE"
        [ ! -f ~/.tts_paused ] && say -v "Ava (Premium)" "Pipeline complete. $COMPLETED successful." &
        exit 0
      fi
      ;;
  esac

  sleep 30
  ((ITERATION++))
done

echo "⚠️ Max iterations reached"
exit 1
```

### Results

- **Before**: 3 manual interventions needed (launch tests, check status, analyze)
- **After**: Full automation from commit to results
- **Time saved**: ~45 minutes of active monitoring
- **Success**: All 5 tests completed autonomously

### Key Learnings

1. **Iteration limits are critical** - Without them, monitoring can run indefinitely
2. **TTS integration helps** - Voice announcements for overnight awareness
3. **State machines work well** - Clear stages prevent confusion
4. **Auto-progression is key** - No waiting between stages

---

## Best Practices

### 1. Always Use Iteration Counters

**Bad**:
```bash
while true; do
  check_status
  sleep 30
done
```

**Good**:
```bash
MAX_ITERATIONS=100
for i in $(seq 1 $MAX_ITERATIONS); do
  echo "Iteration $i/$MAX_ITERATIONS"
  check_status
  sleep 30
done
```

### 2. Make Stages Explicit

**Bad**:
```
Claude: "Build complete."
[stops]
```

**Good**:
```
Claude: "Stage 1/3 complete: BUILD
Immediately proceeding to Stage 2/3: TEST"
[continues]
```

### 3. Log Everything

```bash
LOG_FILE="task-$(date +%Y%m%d-%H%M%S).log"

{
  echo "Started: $(date)"
  echo "Stage: $STAGE"
  echo "Iteration: $ITERATION"
  run_task
  echo "Completed: $(date)"
} | tee -a "$LOG_FILE"
```

### 4. Handle Failures Gracefully

```bash
if ! run_command; then
  echo "❌ Command failed at iteration $i"
  echo "Last known state: $CURRENT_STATE"
  echo "See logs: $LOG_FILE"
  exit 1
fi
```

### 5. Use TTS for Long-Running Tasks

```bash
[ ! -f ~/.tts_paused ] && say -v "Ava (Premium)" "Stage complete" &
```

### 6. Test Your Scripts

```bash
# Dry run mode
DRY_RUN=true ./autonomous-script.sh

# In script:
if [ "$DRY_RUN" = "true" ]; then
  echo "[DRY RUN] Would run: $COMMAND"
else
  $COMMAND
fi
```

### 7. Set Reasonable Timeouts

```bash
# Per-stage timeout
MAX_STAGE_TIME=1800  # 30 minutes

# Overall timeout
MAX_TOTAL_TIME=14400  # 4 hours
```

### 8. Create Completion Markers

```bash
# In Claude's code:
echo "COMPLETE" > .stage_build_complete

# In monitoring script:
if [ -f .stage_build_complete ]; then
  proceed_to_next_stage
fi
```

### 9. Use Structured Output

```bash
# JSON logging for parsing
{
  "timestamp": "2025-11-19T14:23:10Z",
  "stage": "BUILD",
  "iteration": 5,
  "status": "SUCCESS"
}
```

### 10. Document Your Patterns

```bash
# At top of script:
# Pattern: Monitoring Script with State Machine (Pattern 3)
# Purpose: Auto-progress from BUILD → TEST → DEPLOY
# Max duration: 2 hours
# Dependencies: glab, aws cli, jq
```

---

## Conclusion

Autonomous Claude execution is achievable with the right patterns. The key principles:

1. **Force iteration counting** - Don't let Claude decide when to stop
2. **Make stages explicit** - Clear progress indicators
3. **Auto-progression** - No waiting between stages
4. **Structured logging** - Track everything
5. **Reasonable timeouts** - Prevent infinite loops

Choose the pattern that fits your use case:

- **Simple code iterations** → Continuous Claude
- **Custom workflows** → Shell Loop
- **External systems** → Monitoring Scripts
- **CI/CD pipelines** → Headless Mode
- **Mixed tasks** → Supervision Skill

Or combine them for complex scenarios.

With these patterns, Claude can work autonomously for hours on multi-stage tasks without premature stopping.

---

## Appendix: Quick Reference

### Pattern Selection Decision Tree

```
Is this a pure code iteration task?
├─ YES → Use Continuous Claude
└─ NO → Do you need to monitor external systems?
    ├─ YES → Use Monitoring Scripts
    └─ NO → Do you need complex state management?
        ├─ YES → Use Shell Loop with State Machine
        └─ NO → Is this a one-time batch task?
            ├─ YES → Use Headless Mode
            └─ NO → Use Supervision Skill
```

### Common Pitfalls

1. **No iteration limit** → Infinite loops
2. **Unclear stages** → Claude stops prematurely
3. **No logging** → Can't debug failures
4. **No timeouts** → Tasks run forever
5. **Manual progression** → Breaks autonomy
6. **No error handling** → Silent failures
7. **Tight polling** → Rate limiting issues
8. **No TTS** → Miss overnight failures

### Essential Snippets

**Iteration Loop**:
```bash
for i in {1..50}; do
  echo "Iteration $i/50"
  # your code
done
```

**State Machine**:
```bash
case $STATE in
  "A") STATE="B" ;;
  "B") STATE="C" ;;
  "C") exit 0 ;;
esac
```

**Completion Marker**:
```bash
echo "DONE" > .stage_complete
```

**TTS Notification**:
```bash
say -v "Ava (Premium)" "Stage complete" &
```

**Timeout**:
```bash
timeout 1800 ./long-running-command.sh
```

---

**Document Version**: 1.0
**Last Updated**: 2025-11-19
**Feedback**: <your-email@example.com>
