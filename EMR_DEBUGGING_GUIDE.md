# Debugging Spark Jobs on EMR

This guide documents the process for debugging Spark job failures on AWS EMR clusters.

## Quick Reference

**Key Principle**: Container logs contain the actual error. Step stderr only shows generic "Shutdown hook" messages.

## Error Types

### 1. Generic Error (Not Useful)
**Location**: Step stderr (`s3://.../steps/{STEP_ID}/stderr.gz`)
**Message**: `"Shutdown hook called before final status was reported"`
**Problem**: This is a symptom, not the root cause. The JVM crashed before logging the actual error.

### 2. Actual Error (What You Need)
**Location**: Container logs (`s3://aws-logs-.../containers/{APP_ID}/container_xxx_000001/stderr.gz`)
**Contains**: Actual exception stack traces, schema errors, missing dependencies, etc.

## Container Log Retrieval Process

### Step 1: Extract Application ID

```bash
# From step stderr
CLUSTER_ID="j-XXXXX"
STEP_ID="s-XXXXX"

# Download step stderr
aws s3 cp "s3://here-predictive-artifacts/predictive-analysis-24/output/$CLUSTER_ID/steps/$STEP_ID/stderr.gz" "/tmp/$CLUSTER_ID-stderr.gz"
gunzip -f "/tmp/$CLUSTER_ID-stderr.gz"

# Extract application ID
APP_ID=$(grep -oP 'application_\d+_\d+' "/tmp/$CLUSTER_ID-stderr" | head -1)
echo "Application ID: $APP_ID"
```

### Step 2: Wait for Log Upload

**IMPORTANT**: Container logs are uploaded to S3 AFTER cluster termination, not during execution.

- **Fast failures** (< 5 min): Wait 5-10 minutes after failure
- **Normal runs**: Logs available within 2-3 minutes of termination
- **Check timing**: If cluster just failed, wait before attempting download

### Step 3: List Container Logs

```bash
# Check if container logs are available
aws s3 ls "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/$CLUSTER_ID/containers/$APP_ID/" --recursive

# Expected output:
# .../container_{APP_ID}_000001/stderr.gz  (ApplicationMaster - MOST IMPORTANT)
# .../container_{APP_ID}_000001/stdout.gz
# .../container_{APP_ID}_000002/stderr.gz  (Executor 1)
# .../container_{APP_ID}_000003/stderr.gz  (Executor 2)
# ...
```

### Step 4: Download ApplicationMaster Logs

The ApplicationMaster container (`_000001`) contains driver errors and initialization failures.

```bash
# Download AM stderr (contains actual error)
aws s3 cp "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/$CLUSTER_ID/containers/$APP_ID/ip-10-72-*/container_${APP_ID}_000001/stderr.gz" "/tmp/am-stderr.gz"

# Decompress
gunzip -f /tmp/am-stderr.gz

# View error
cat /tmp/am-stderr

# Search for exceptions
grep -i "exception\|error\|failed" /tmp/am-stderr | head -20
```

### Step 5: Download Executor Logs (If Needed)

If the error occurs during data processing (not initialization), check executor logs.

```bash
# List all executor containers
aws s3 ls "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/$CLUSTER_ID/containers/$APP_ID/" --recursive | grep stderr

# Download specific executor
aws s3 cp "s3://aws-logs-.../container_${APP_ID}_000002/stderr.gz" /tmp/executor-1-stderr.gz
gunzip -f /tmp/executor-1-stderr.gz
cat /tmp/executor-1-stderr
```

## Common Errors and Solutions

### Schema Mismatch
**Error in Container Logs**:
```
org.apache.spark.sql.AnalysisException: [INSERT_COLUMN_ARITY_MISMATCH.TOO_MANY_DATA_COLUMNS]
Cannot write to `catalog`.`database`.`table`, the reason is too many data columns
```

**Solution**: Add `.select()` transformation to match table schema before write.

### Missing Dependencies
**Error**:
```
java.lang.ClassNotFoundException: org.apache.iceberg.spark.SparkCatalog
```

**Solution**: Verify Iceberg JARs are in EMR classpath, check `spark.jars.packages` configuration.

### Glue Catalog Authentication
**Error**:
```
AccessDeniedException: User is not authorized to perform: glue:GetTable
```

**Solution**: Verify EMR IAM role has Glue permissions, check catalog ID.

### Table Not Found
**Error**:
```
org.apache.iceberg.exceptions.NoSuchTableException: Table does not exist
```

**Solution**: Verify table exists in Glue catalog, check database/table names.

### OOM During Initialization
**Error**:
```
java.lang.OutOfMemoryError: Java heap space
  at org.apache.iceberg.BaseMetastoreTableOperations.refresh
```

**Solution**: Increase driver memory (`spark.driver.memory`), reduce metadata file size.

## Automated Log Retrieval Script

```bash
#!/bin/bash
# Script: fetch-container-logs.sh

CLUSTER_ID="$1"
STEP_ID="$2"

if [ -z "$CLUSTER_ID" ] || [ -z "$STEP_ID" ]; then
  echo "Usage: $0 <cluster-id> <step-id>"
  exit 1
fi

echo "📥 Downloading step stderr..."
aws s3 cp "s3://here-predictive-artifacts/predictive-analysis-24/output/$CLUSTER_ID/steps/$STEP_ID/stderr.gz" "/tmp/$CLUSTER_ID-stderr.gz"
gunzip -f "/tmp/$CLUSTER_ID-stderr.gz"

echo "🔍 Extracting application ID..."
APP_ID=$(grep -oP 'application_\d+_\d+' "/tmp/$CLUSTER_ID-stderr" | head -1)

if [ -z "$APP_ID" ]; then
  echo "❌ No application ID found in stderr"
  exit 1
fi

echo "✅ Application ID: $APP_ID"
echo ""
echo "⏳ Waiting for container logs to upload (30 seconds)..."
sleep 30

echo "📋 Listing container logs..."
aws s3 ls "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/$CLUSTER_ID/containers/$APP_ID/" --recursive

echo ""
echo "📥 Downloading ApplicationMaster container logs..."
mkdir -p "/tmp/$CLUSTER_ID-logs"

aws s3 cp "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/$CLUSTER_ID/containers/$APP_ID/" "/tmp/$CLUSTER_ID-logs/" --recursive --exclude "*" --include "*/container_${APP_ID}_000001/*"

echo ""
echo "🔓 Decompressing logs..."
find "/tmp/$CLUSTER_ID-logs" -name "*.gz" -exec gunzip -f {} \;

echo ""
echo "✅ Logs saved to: /tmp/$CLUSTER_ID-logs/"
echo ""
echo "🔍 Searching for errors..."
find "/tmp/$CLUSTER_ID-logs" -name "stderr" -exec grep -i "exception\|error" {} \; | head -30
```

## Debugging Workflow

1. **Job fails** → Get cluster ID and step ID
2. **Download step stderr** → Extract application ID
3. **Wait 5-10 minutes** → Allow container logs to upload
4. **Download container logs** → Get actual error from AM stderr
5. **Analyze error** → Identify root cause (schema, dependency, config, etc.)
6. **Fix and commit** → Apply fix based on container log error
7. **Relaunch cluster** → Test fix

## Key Locations

### Step Logs (Generic Errors)
```
s3://here-predictive-artifacts/predictive-analysis-24/output/{CLUSTER_ID}/steps/{STEP_ID}/stderr.gz
```

### Container Logs (Actual Errors)
```
s3://aws-logs-957633371688-us-east-1/elasticmapreduce/{CLUSTER_ID}/containers/{APP_ID}/
```

### Node Logs
```
s3://aws-logs-957633371688-us-east-1/elasticmapreduce/{CLUSTER_ID}/node/
```

## Tips

- **Always wait** for container logs - they're not instant
- **Check AM container first** (`_000001`) - contains driver/initialization errors
- **Check executors** if error during data processing (tasks failing)
- **Use automation** - create scripts to fetch logs automatically
- **Save logs locally** - easier to grep/analyze than reading from S3
- **Check multiple retries** - YARN may retry AM multiple times, check all attempts

## See Also

- [EMR Troubleshooting Guide](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-troubleshoot.html)
- [Spark Application Logs](https://spark.apache.org/docs/latest/running-on-yarn.html#debugging-your-application)
- [AWS Glue Catalog Permissions](https://docs.aws.amazon.com/glue/latest/dg/glue-specifying-resource-arns.html)
