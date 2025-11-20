---
name: spark-optimization
description: Expert guidance for debugging Apache Spark/EMR job failures and optimizing performance. Use when debugging Spark failures, analyzing performance bottlenecks, investigating memory/OOM issues, optimizing partition strategies, migrating to Iceberg, or reducing EMR costs. Based on 30+ iterations of production optimization (ITER20-27, ICE-01 through ICE-11). Specializes in container log analysis, writer explosion detection, S2 spatial partitioning, and cost optimization.
---

# Spark Job Optimization & Debugging Expert

## Skill Metadata

**Name:** spark-optimization
**Purpose:** Expert guidance for debugging Apache Spark/EMR job failures and optimizing performance
**Knowledge Base:** 30+ iterations of production Spark optimization (ITER20-27, ICE-01 through ICE-11)
**Specialty:** Container log analysis, writer explosion detection, spatial partitioning, Iceberg migration

## When to Invoke This Skill

Use this skill when you need help with:
- Debugging Spark job failures on EMR or locally
- Analyzing performance bottlenecks in Spark jobs
- Investigating memory issues, OOM errors, or GC thrashing
- Optimizing partition strategies for large-scale writes
- Understanding container logs and error messages
- Migrating from Parquet to Iceberg table format
- Cost optimization for EMR workloads
- Configuring Spark for S3 writes
- Resolving catalog configuration conflicts

## Core Principles (Learned from 30+ Iterations)

1. **"Container logs contain truth, not step stderr"** - Generic shutdown messages hide actual errors
2. **"Profile first, optimize second"** - 11 config iterations = 0% improvement, 1 profiling iteration = 35% improvement
3. **"Architecture > Configuration"** - Some problems can't be solved with config tweaks
4. **"Test at production scale early"** - Small-scale success (10 files) ≠ large-scale success (60 files)

---

# QUICK DIAGNOSTIC DECISION TREE

## Start Here: What's Your Issue?

### 1. Job Failed - Need to Debug
→ Go to **Container Log Debugging Workflow** (Section A)

### 2. Job Succeeds but Takes Too Long
→ Go to **Performance Bottleneck Analysis** (Section B)

### 3. Job Hangs with High GC or Memory Issues
→ Go to **Writer Explosion Detection** (Section C)

### 4. Configuration Not Taking Effect
→ Go to **Configuration Precedence Issues** (Section D)

### 5. Want to Reduce Costs
→ Go to **Cost Optimization Strategies** (Section E)

### 6. Migrating to Iceberg
→ Go to **Iceberg Migration Guide** (Section F)

---

# SECTION A: Container Log Debugging Workflow

## The Critical Truth About Spark Errors

**IMPORTANT:** Step stderr shows generic "Shutdown hook" messages. The ACTUAL error is in container logs.

### Container Log Retrieval Process

```bash
# Step 1: Get Application ID from step stderr
APP_ID=$(grep -oP 'application_\d+_\d+' /tmp/{cluster-id}-stderr | head -1)
echo "Application ID: $APP_ID"

# Step 2: WAIT 5-10 MINUTES for container logs to upload to S3
# This is CRITICAL - logs aren't available immediately after failure

# Step 3: Check container logs path
aws s3 ls "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/{CLUSTER_ID}/containers/${APP_ID}/" --recursive

# Step 4: Download ApplicationMaster container stderr (contains actual error)
# Look for container ending in _000001 (this is the ApplicationMaster)
aws s3 cp "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/{CLUSTER_ID}/containers/${APP_ID}/container_${APP_ID}_000001/stderr.gz" /tmp/container-stderr.gz

# Step 5: Extract and read
gunzip /tmp/container-stderr.gz
cat /tmp/container-stderr
```

### Alternative Log Locations

If container logs aren't available:

```bash
# Node manager logs
aws s3 ls "s3://aws-logs-957633371688-us-east-1/elasticmapreduce/{CLUSTER_ID}/node/" --recursive

# Cluster-level logs
aws s3 ls "s3://here-predictive-artifacts/predictive-analysis-24/output/{CLUSTER_ID}/" --recursive
```

## Common Error Signatures in Container Logs

### Schema Mismatch
```
INSERT_COLUMN_ARITY_MISMATCH
Required table schema has N columns, but data has M columns
```
**Solution:** Check DataFrame schema vs table schema. Fix column selection.

### Missing Dependencies
```
ClassNotFoundException: org.apache.iceberg.aws.glue.GlueCatalog
ClassNotFoundException: software.amazon.awssdk.services.sts.model.Tag
```
**Solution:** Add dependency to pom.xml with correct scope (not `provided` if needed in fat JAR)

### Catalog Configuration Conflict
```
IllegalArgumentException: Cannot create catalog - both type and catalog-impl set
```
**Solution:** Remove application-level catalog config. Let EMR cluster config handle it.

### HDFS/S3 Location Conflict
```
Database LocationUri: hdfs://...
Iceberg warehouse: s3://...
```
**Solution:** Create dedicated database with S3 location from the start

### FileCommitProtocol Corruption
```
KryoException: Cannot enter synchronized block because 'this.mutex' is null
Serialization trace: FileCommitProtocol$TaskCommitMessage
```
**Solution:** Don't switch SaveMode between batches. Use `SaveMode.Overwrite` + `partitionOverwriteMode=dynamic` for ALL batches

### OOM During Write
```
java.lang.OutOfMemoryError: Java heap space
at org.apache.spark.sql.execution.datasources.FileFormatWriter
```
**Solution:** Writer explosion detected. See Section C.

---

# SECTION B: Performance Bottleneck Analysis

## Step 1: Gather Performance Data

### Check Spark UI Metrics
- **Stage duration** - Which stage is slowest?
- **Task metrics** - Are tasks evenly distributed?
- **GC time** - Is GC > 10% of task time?
- **Shuffle read/write** - Excessive shuffling?

### Run JFR Profiling (Local Testing)

```bash
# Add JFR flags to local run
java -XX:StartFlightRecording=duration=300s,filename=/tmp/profile.jfr \
     -Xmx4g -cp target/classes \
     com.traffic.etl.TrafficMLParquetConverter

# Analyze with jfr tool or upload to profiling service
jfr print --events jdk.ExecutionSample /tmp/profile.jfr | less
```

**Real Example - ITER22 Finding:**
- 7,511 CPU samples captured
- **36% of time** in AggregationIterator (wasteful first() calls)
- 20% in MutableProjection.apply
- 10% in UTF8String.copy
- Only 1.5% in GC (GC wasn't the problem!)

## Step 2: Identify Bottleneck Category

### CPU-Bound (High CPU, Low I/O Wait)
**Symptoms:**
- High CPU usage in Spark UI
- Tasks take long but don't shuffle much
- JFR shows time in business logic code

**Common Causes:**
- Inefficient aggregations (redundant first() calls)
- Unnecessary transformations
- Complex UDFs without optimization

**Solution Example - ITER22 Fix:**
```scala
// BEFORE: 26 aggregations, 22 redundant (36% CPU waste)
.groupBy($"row_id").agg(
  first($"linear_id"),    // Identical within group!
  first($"location_id"),  // Identical within group!
  // ... 20 more first() calls ...
  sort_array(collect_list($"link_data"))  // Only this needs aggregation
)

// AFTER: 4 aggregations, separate selection (35% faster)
val linkAggregates = withCoords
  .groupBy($"row_id")
  .agg(
    sort_array(collect_list($"link_data")),
    count($"link_id"),
    first($"start_lat"),
    first($"start_lon")
  )

val representativeRows = withCoords
  .withColumn("rn", row_number().over(Window.partitionBy($"row_id")))
  .filter($"rn" === 1)
  .select($"row_id", $"linear_id", /* all 22 fields */)

val optimized = representativeRows.join(linkAggregates, Seq("row_id"))
```
**Impact:** 154s → 100s locally (35% improvement)

### I/O-Bound (Long Waits, S3 Operations)
**Symptoms:**
- Tasks spend time in S3 list/write operations
- Low CPU but long stage duration
- Many small files being written

**Common Causes:**
- Partition overwrite mode = static (scans ALL partitions)
- High partition count with directory-based partitioning
- Small partition sizes

**Solution Example - ITER24-25 Fix:**
```scala
// CRITICAL: Set at DataFrame level, NOT session level (EMR overrides session)
finalDf.write
  .mode(SaveMode.Overwrite)
  .option("partitionOverwriteMode", "dynamic")  // Only scans affected partitions
  .partitionBy("table_id", "s2_cell_level_10", "year", "month")
  .parquet(outputPath)
```

**Impact:** 67+ min hang → 5 min completion (static mode scanned 396K files, dynamic scans ~60)

### Memory-Bound (GC Thrashing, OOM)
**Symptoms:**
- GC time > 30% of task time
- Tasks fail with OOM
- Job hangs with high memory usage

**Root Cause:** Usually writer explosion (see Section C)

---

# SECTION C: Writer Explosion Detection & Solutions

## What is Writer Explosion?

**Definition:** Resource exhaustion when Spark writes partitioned data with high-cardinality partition keys. Spark keeps ONE in-memory file writer per unique partition value.

## Mathematical Detection

```
Total Memory Required = P × M

Where:
  P = Unique partition values
  M = Memory per writer (~50 MB)
```

### Why 50 MB per Writer?
- **Output Buffer:** 128 MB target (parquet.block.size)
- **Column Encoders:** 1-5 MB per column
- **Compression Buffers:** 5-10 MB (Snappy/GZIP)
- **Metadata Structures:** 1-2 MB (min/max stats, bloom filters)
- **File Handle Overhead:** ~1 MB (OS descriptor, S3 multipart state)

### Safe Partition Limit Formula

```
Safe Partition Limit = Executor Memory / 50 MB

Examples:
  4 GB executor  = ~80 safe partitions
  8 GB executor  = ~160 safe partitions
  16 GB executor = ~320 safe partitions
```

### Real Example - ITER23 Failure

**Dataset:** 60 files, S2 spatial partitioning at level 10
**Unique S2 cells:** ~5,000
**Memory required:** 5,000 × 50 MB = **250 GB**
**Executor memory:** 8 GB
**Result:** Catastrophic failure (214 min, 0 output files, GC thrashing)

## Symptoms of Writer Explosion

- Job appears hung but GC logs show continuous activity
- `java.lang.OutOfMemoryError: Java heap space` at `FileFormatWriter`
- GC time > 90% of elapsed time
- S3 write timeouts
- Container killed by YARN for exceeding memory limits
- Stage shows progress but creates no output files

## Why Traditional Solutions Don't Work

### "Just add more memory"
- Cost scales 4× (16GB → 32GB executors)
- Partition count still grows with data scale
- Only delays the problem

### "Use fewer partitions"
- Defeats purpose of spatial partitioning for queries
- Sacrifices query performance (can't prune partitions)

### "Increase parquet.block.size"
- Doesn't reduce number of writers
- Only changes buffer size per writer
- Same memory problem

### "Use repartition() or coalesce()"
- Controls **files per partition**, not **partition count**
- Writer explosion is about partition cardinality, not file count

## Solutions Ranked by Effectiveness

### Solution 1: Micro-Batching (Short-term, Production-Ready)

**Strategy:** Split data into N batches at write time to limit concurrent partitions

```scala
import org.apache.spark.sql.functions.hash

// Add batch column
val MICRO_BATCH_SIZE = 6  // Adjust based on partition count
val batchedDf = df.withColumn("batch_num", hash($"row_id") % MICRO_BATCH_SIZE)

// Write batches with CONSISTENT SaveMode
val writeMode = SaveMode.Overwrite  // Use for ALL batches
val partitionMode = "dynamic"        // Only touches affected partitions

for (batchId <- 0 until MICRO_BATCH_SIZE) {
  println(s"Processing batch ${batchId + 1}/$MICRO_BATCH_SIZE")

  val batchDf = batchedDf.filter($"batch_num" === batchId).drop("batch_num")

  batchDf.write
    .mode(writeMode)  // CRITICAL: Same mode for all batches
    .option("partitionOverwriteMode", partitionMode)
    .partitionBy("table_id", "s2_cell_level_10", "year", "month")
    .parquet(outputPath)
}
```

**CRITICAL WARNING - ITER30 Discovery:**
Do NOT switch SaveMode between batches:
- ❌ Batch 1: Overwrite, Batch 2+: Append → Corrupts FileCommitProtocol
- ✅ All batches: Overwrite + dynamic partition mode → Works correctly

**Benefits:**
- Reduces memory: 250 GB → 42 GB (6 batches)
- Provides progress checkpoints
- Enables failure recovery (lose max 1 batch)
- Production-proven with 60 files

**Performance - ITER26-27:**
- Without batching: 60 files FAILED (214 min, 0 output)
- With batching (6 batches): 60 files SUCCEEDED in 30 min

### Solution 2: Apache Iceberg (Long-term, Architectural)

**Why Iceberg Eliminates Writer Explosion:**

**Traditional Parquet:**
```
Physical directories per partition:
s3://bucket/table_id=E0D01/s2_cell=abc123/part-001.parquet

Creates: 5,000 S2 cells = 5,000 writers
Memory: 5,000 × 50 MB = 250 GB
```

**Iceberg:**
```
Data files (no partition directories):
s3://bucket/data/00001-abc-file.parquet  (contains ALL s2_cell values)

Metadata files (track partitioning):
s3://bucket/metadata/snap-123-manifest.avro  (maps s2_cell → files)

Creates: ~20 writers per Spark task
Memory: 20 × 50 MB = 1 GB
```

**Key Insight - Hidden Partitioning:**
Iceberg stores partition information in metadata, not directory structure. One data file can contain records from multiple partitions.

**Query Performance:** Same partition pruning via metadata scanning (not directory listing)

**Implementation Status:**
- ICE-01 to ICE-11: Iceberg integration complete
- Local E2E testing: ✅ Passing
- EMR testing: In progress

**Example Code:**
```scala
// Iceberg write (no writer explosion)
df.writeTo(s"glue_catalog.trafficml_db.traffic_flow")
  .partitionedBy($"s2_cell_level_10")  // Logical, not physical
  .option("write.parquet.compression-codec", "snappy")
  .append()

// Query with partition pruning still works
spark.read
  .table("glue_catalog.trafficml_db.traffic_flow")
  .filter($"s2_cell_level_10".isin(cellsInBbox: _*))
```

### Solution 3: Reduce Partition Cardinality

**Strategy:** Use lower-resolution S2 cells or fewer partition dimensions

```scala
// BEFORE: Level 10 (5,000 cells globally)
.partitionBy("table_id", "s2_cell_level_10", "year", "month")

// AFTER: Level 8 (640 cells globally)
.partitionBy("table_id", "s2_cell_level_8", "year", "month")
```

**Trade-off:** Worse query selectivity (more files scanned per bbox)

**When to Use:** If query performance is less critical than write performance

---

# SECTION D: Configuration Precedence Issues

## The Configuration Hierarchy (Highest to Lowest)

```
1. DataFrame .option()              ← HIGHEST (always use this!)
2. spark-submit --conf
3. EMR spark-defaults.conf          ← Overrides session config
4. Session sparkConf.set()          ← LOWEST (often overridden)
```

## Real Example - ITER24 Failure

**Problem:** Set config at session level, had no effect on EMR

```scala
// ITER24: This didn't work on EMR (overridden by spark-defaults.conf)
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

df.write
  .mode(SaveMode.Overwrite)
  .partitionBy("table_id", "s2_cell_level_10", "year", "month")
  .parquet(outputPath)
```

**Solution:** Set at DataFrame level (highest precedence)

```scala
// ITER25: This works on EMR (overrides all other configs)
df.write
  .mode(SaveMode.Overwrite)
  .option("partitionOverwriteMode", "dynamic")  // DataFrame-level
  .partitionBy("table_id", "s2_cell_level_10", "year", "month")
  .parquet(outputPath)
```

## Critical Configurations

### Partition Overwrite Mode

```scala
// ALWAYS set at DataFrame level
.option("partitionOverwriteMode", "dynamic")

// "dynamic" = Only scans affected partitions (fast)
// "static"  = Scans ALL partitions in S3 (extremely slow)
```

**Impact:** 67+ min hang → 5 min (static scanned 396K files, dynamic scans ~60)

### S3 Write Optimizations

```scala
// Set these via spark-submit or session config (not DataFrame-level)
spark.conf.set("spark.hadoop.fs.s3a.fast.upload.buffer", "bytebuffer")
spark.conf.set("spark.hadoop.fs.s3a.multipart.size", "134217728")  // 128 MB
spark.conf.set("spark.sql.parquet.enableVectorizedReader", "true")
spark.conf.set("spark.sql.parquet.writer.max-padding", "8388608")
```

### Iceberg Catalog Configuration

**CRITICAL:** Don't set catalog config at both application AND cluster level

```scala
// ICE-05 Failure: Both type AND catalog-impl set
spark.conf.set("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
spark.conf.set("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")  // ❌
spark.conf.set("spark.sql.catalog.glue_catalog.type", "glue")  // ❌ Conflict!

// ICE-07 Solution: Let EMR deployment handle catalog config
// Remove application-level config entirely
// EMR spark-defaults.conf sets catalog config automatically
```

---

# SECTION E: Cost Optimization Strategies

## Performance-to-Cost Mapping

**EMR Cluster:** 32 × m5a.2xlarge instances = $2.56/hour

| Optimization | Runtime | Cost/Hour of Data | Monthly (24/7) | Savings |
|--------------|---------|-------------------|----------------|---------|
| Baseline (temporal) | 90-120 min | $3.84-$5.12 | $3,686/month | - |
| S2 Spatial (ITER21) | 30-40 min | $1.92-$2.56 | $1,843/month | 50% |
| S2 + Micro-batch (ITER26) | 25-35 min | $1.28-$1.92 | $1,382/month | 62% |
| Iceberg (projected) | 15-25 min | $0.85-$1.28 | $922/month | 75% |

**Annual Savings Potential:** $33,000+/year

## Cost Calculation Formula

```
Hourly Cost = Cluster Cost × (Job Duration / 60 min)

Monthly Cost (24/7 processing) = Hourly Cost × 720 hours

Cost per GB Processed = Hourly Cost / Data Volume
```

## Optimization ROI Analysis

### Inefficient Aggregation Fix (ITER22)
- **Effort:** 2 hours of code refactoring
- **Impact:** 35% performance improvement
- **Monthly Savings:** $644
- **ROI:** 322× in first month

### S2 Spatial Partitioning (ITER21)
- **Effort:** 4 hours of implementation + testing
- **Impact:** 3.7× performance improvement
- **Monthly Savings:** $1,843
- **ROI:** 461× in first month

### Micro-Batching (ITER26)
- **Effort:** 6 hours of implementation + testing
- **Impact:** Enabled 60-file scale (previously failed)
- **Monthly Savings:** $2,304
- **ROI:** 384× in first month

## Query Performance Cost Savings

**Before (Temporal Partitioning):**
- Bbox query scans 1,488 files (all time partitions)
- Query time: 5-30 seconds
- High S3 GET request costs

**After (S2 Spatial Partitioning):**
- Bbox query scans 10-20 files (spatial pruning)
- Query time: 0.1-0.5 seconds
- 74-150× fewer S3 requests

**S3 Cost Savings:**
- S3 GET requests: $0.0004 per 1,000 requests
- 1,000 queries/day × (1,488 files → 20 files) = 1,468,000 fewer requests/day
- Daily savings: $0.59
- Monthly savings: $17.70 (S3 GET costs alone)

---

# SECTION F: Iceberg Migration Guide

## Why Migrate to Iceberg?

### Problem with Traditional Parquet
1. **Writer Explosion:** High-cardinality partitions = OOM
2. **Slow Metadata Operations:** Directory listing for 5,000 partitions
3. **No ACID Guarantees:** Concurrent writes can corrupt data
4. **Schema Evolution Challenges:** Changing schema requires rewriting all data

### Iceberg Solutions
1. **Hidden Partitioning:** Metadata-driven, not directory-based → No writer explosion
2. **Fast Metadata:** Manifest files replace directory scans → 10-100× faster
3. **ACID Transactions:** Snapshot isolation for concurrent writes
4. **Schema Evolution:** Add/drop/rename columns without rewriting data

## Migration Checklist

### Step 1: Add Dependencies (pom.xml)

```xml
<dependency>
    <groupId>org.apache.iceberg</groupId>
    <artifactId>iceberg-spark-runtime-3.5_2.12</artifactId>
    <version>1.8.0</version>
</dependency>

<dependency>
    <groupId>org.apache.iceberg</groupId>
    <artifactId>iceberg-aws</artifactId>
    <version>1.8.0</version>
</dependency>

<!-- AWS STS required for Glue catalog -->
<dependency>
    <groupId>software.amazon.awssdk</groupId>
    <artifactId>sts</artifactId>
    <version>2.25.0</version>
</dependency>
```

### Step 2: Configure Catalog (EMR Deployment Only)

**IMPORTANT:** Don't configure in application code. Configure via EMR cluster settings.

```scala
// ICE-07: Let EMR deployment layer handle this
// configurations = List(
//   Classification(
//     classification = "spark-defaults",
//     properties = Some(Map(
//       "spark.sql.catalog.glue_catalog" -> "org.apache.iceberg.spark.SparkCatalog",
//       "spark.sql.catalog.glue_catalog.type" -> "glue"
//     ))
//   )
// )
```

### Step 3: Create Iceberg Database

**Problem (ICE-08):** Default database uses HDFS location
**Solution (ICE-09):** Create dedicated database with S3 warehouse

```sql
-- Create database with S3 location
CREATE DATABASE IF NOT EXISTS trafficml_db
LOCATION 's3://here-predictive-artifacts/predictive-analysis-24/iceberg-warehouse/trafficml';
```

### Step 4: Convert Write Code

```scala
// BEFORE: Parquet with partition explosion
df.write
  .mode(SaveMode.Overwrite)
  .option("partitionOverwriteMode", "dynamic")
  .partitionBy("table_id", "s2_cell_level_10", "year", "month")
  .parquet("s3://bucket/output/")

// AFTER: Iceberg with hidden partitioning
df.writeTo("glue_catalog.trafficml_db.traffic_flow")
  .partitionedBy($"s2_cell_level_10")  // Logical partitioning
  .option("write.parquet.compression-codec", "snappy")
  .createOrReplace()  // First time

// Subsequent writes
df.writeTo("glue_catalog.trafficml_db.traffic_flow")
  .partitionedBy($"s2_cell_level_10")
  .append()  // Or .overwritePartitions() for partition-level updates
```

### Step 5: Update Read Code

```scala
// BEFORE: Read Parquet
val df = spark.read.parquet("s3://bucket/output/")

// AFTER: Read Iceberg table
val df = spark.read.table("glue_catalog.trafficml_db.traffic_flow")

// Partition pruning still works automatically
val filtered = df.filter($"s2_cell_level_10".isin(cellsInBbox: _*))
```

### Step 6: E2E Testing

**Run local E2E test:**
```bash
./scripts/run-iceberg-e2e-test.sh
```

**Test validates:**
- Table creation with S2 spatial partitioning
- Sample data ingestion (TrafficML XML → Iceberg)
- Bounding box queries
- Geometry WKT validation
- S2 cell ID presence
- Data correctness (speed, confidence values)

**Expected output:** "All 11 tests passed" in < 15 seconds

### Step 7: Monitor First EMR Run

```bash
# Launch EMR job
mvn exec:java -Dexec.mainClass="com.traffic.emr.deployment.TrafficMLIcebergIndexing"

# Monitor progress
watch -n 10 'aws emr describe-step --cluster-id {CLUSTER_ID} --step-id {STEP_ID}'

# If failure, get container logs (wait 5-10 min after failure)
./scripts/fetch-emr-container-logs.sh {CLUSTER_ID} {APP_ID}
```

## Common Iceberg Issues

### Issue 1: Catalog Type Conflict (ICE-05)
```
IllegalArgumentException: Cannot create catalog - both type and catalog-impl set
```
**Solution:** Remove application-level catalog config. Single source of truth.

### Issue 2: HDFS Location Conflict (ICE-08, ICE-09)
```
Database LocationUri: hdfs://ip-XXX:8020/user/hive/warehouse/traffic_flow_db.db
```
**Solution:** Create new database with S3 location from the start

### Issue 3: Schema Mismatch (ICE-10, ICE-11)
```
INSERT_COLUMN_ARITY_MISMATCH
```
**Solution:** Normalize DataFrame schema to match table expectations

### Issue 4: Missing AWS STS Dependency
```
ClassNotFoundException: software.amazon.awssdk.services.sts.model.Tag
```
**Solution:** Add `awssdk:sts` dependency to pom.xml

---

# PERFORMANCE PROFILING TOOLKIT

## JFR (Java Flight Recorder) Profiling

### Local Profiling Setup

```bash
# Run with JFR enabled
java -XX:StartFlightRecording=duration=300s,filename=/tmp/spark-profile.jfr \
     -Xmx4g --add-opens=java.base/java.lang=ALL-UNNAMED \
     -cp target/classes \
     com.traffic.etl.TrafficMLParquetConverter

# Analyze CPU samples
jfr print --events jdk.ExecutionSample /tmp/spark-profile.jfr | head -100

# Check GC overhead
jfr print --events jdk.GCHeapSummary /tmp/spark-profile.jfr
```

### What to Look For

**CPU Hotspots:**
- High % in AggregationIterator → Check for redundant aggregations
- High % in UTF8String operations → String manipulation overhead
- High % in MutableProjection → Excessive transformations

**Memory Issues:**
- GC time > 30% of samples → Memory pressure (possible writer explosion)
- Large object allocations → Check buffer sizes

**Real Example (ITER22):**
```
36% in AggregationIterator.hasNext  ← Smoking gun!
20% in MutableProjection.apply
10% in UTF8String.copy
1.5% in GC (NOT the problem)
```

## Spark UI Analysis

### Stage-Level Metrics

**Check for:**
- Skewed task durations (data imbalance)
- High shuffle read/write (expensive joins/aggregations)
- GC time > 10% (memory pressure)
- Failed tasks (spot instance interruptions, OOM)

### SQL Tab Analysis

**Look at:**
- Number of files scanned (partition pruning effectiveness)
- Scan size vs output size (filter selectivity)
- Exchange operations (shuffle boundaries)

## CloudWatch Metrics (EMR)

```bash
# Get cluster metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticMapReduce \
  --metric-name MemoryAvailableMB \
  --dimensions Name=JobFlowId,Value={CLUSTER_ID} \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-01T01:00:00Z \
  --period 300 \
  --statistics Average
```

---

# SPATIAL PARTITIONING REFERENCE

## S2 Geometry Levels

| Level | Cell Size | Cells (Global) | Use Case |
|-------|-----------|----------------|----------|
| 6 | 156 km | 40 | Continental regions |
| 8 | 39 km | 640 | Large metro areas |
| 10 | 9.8 km | 10,000 | City-level partitioning |
| 12 | 2.4 km | 163,840 | Neighborhood-level |
| 14 | 610 m | 2.6 million | Street-level |

## Choosing S2 Level

**Rule of Thumb:**
```
Partition Count = (Dataset Coverage / Cell Area) × Replication Factor

Safe Limit = Executor Memory / 50 MB

Choose S2 level where: Partition Count < Safe Limit
```

**Example:**
- Dataset: Greater Los Angeles (10,000 km²)
- Level 10 cells: 9.8 km² each → ~1,020 cells
- Executor: 8 GB → Safe limit ~160 partitions
- **Problem!** 1,020 > 160 → Need micro-batching or Iceberg

**Recommendations:**
- **Level 8** (39 km): Safe for 8GB executors without batching
- **Level 10** (9.8 km): Requires micro-batching (6-10 batches) or Iceberg
- **Level 12** (2.4 km): Requires Iceberg (too many partitions for batching)

## S2 Partition Structure

```scala
// Traditional temporal partitioning
.partitionBy("table_id", "year", "month", "day", "hour")
// Result: 1,488 partitions per month (24 × 31 × 2 tables)
// Query bbox: Must scan ALL time partitions

// S2 spatial-first partitioning
.partitionBy("table_id", "s2_cell_level_10", "year", "month")
// Result: ~100-300 active S2 cells per hour
// Query bbox: Scan only 10-20 spatial cells → 74-150× fewer files
```

---

# E2E TESTING TEMPLATES

## Iceberg E2E Test Structure

```scala
class IcebergDataBrowserE2ESpec extends AnyFlatSpec with Matchers {

  "Iceberg spatial indexing pipeline" should "create table and ingest sample data" in {
    // Setup: Create test database
    spark.sql("""
      CREATE DATABASE IF NOT EXISTS test_trafficml_db
      LOCATION 's3://test-bucket/iceberg-warehouse/'
    """)

    // Ingest: Sample XML → Iceberg
    val sampleXmlPath = "src/test/resources/sample-trafficml/"
    TrafficMLParquetConverter.convertToIceberg(sampleXmlPath, "test_trafficml_db")

    // Validate: Table exists
    val tables = spark.sql("SHOW TABLES IN test_trafficml_db").collect()
    tables.map(_.getString(1)) should contain ("traffic_flow")
  }

  it should "support bounding box queries with partition pruning" in {
    // Query: Small bbox (1km × 1km)
    val bbox = BoundingBox(minLat = 37.7, maxLat = 37.71, minLon = -122.5, maxLon = -122.49)
    val cellIds = S2Utils.getCellsInBbox(bbox, level = 10)

    val results = spark.read
      .table("test_trafficml_db.traffic_flow")
      .filter($"s2_cell_level_10".isin(cellIds: _*))
      .collect()

    results.length should be > 0

    // Validate: All results within bbox
    results.foreach { row =>
      val lat = row.getAs[Double]("start_lat")
      val lon = row.getAs[Double]("start_lon")
      lat should (be >= bbox.minLat and be <= bbox.maxLat)
      lon should (be >= bbox.minLon and be <= bbox.maxLon)
    }
  }

  it should "preserve S2 cell IDs for spatial queries" in {
    val df = spark.read.table("test_trafficml_db.traffic_flow")

    // Validate: s2_cell_level_10 column present and non-null
    df.filter($"s2_cell_level_10".isNull).count() shouldBe 0

    // Validate: Distinct spatial cells exist
    val distinctCells = df.select($"s2_cell_level_10").distinct().count()
    distinctCells should be > 1L
  }
}
```

## Performance Benchmark Test

```scala
"S2 spatial partitioning" should "enable fast bbox queries" in {
  val bbox = BoundingBox(37.7, 37.8, -122.5, -122.4)  // 10km × 10km
  val cellIds = S2Utils.getCellsInBbox(bbox, level = 10)

  // Temporal partitioning (baseline)
  val temporalStart = System.currentTimeMillis()
  val temporalResults = spark.read
    .parquet("s3://bucket/temporal-partitioned/")
    .filter($"latitude".between(bbox.minLat, bbox.maxLat))
    .filter($"longitude".between(bbox.minLon, bbox.maxLon))
    .count()
  val temporalTime = System.currentTimeMillis() - temporalStart

  // S2 spatial partitioning
  val spatialStart = System.currentTimeMillis()
  val spatialResults = spark.read
    .parquet("s3://bucket/s2-partitioned/")
    .filter($"s2_cell_level_10".isin(cellIds: _*))
    .count()
  val spatialTime = System.currentTimeMillis() - spatialStart

  println(s"Temporal: ${temporalTime}ms, Spatial: ${spatialTime}ms")
  println(s"Speedup: ${temporalTime.toDouble / spatialTime}x")

  // Validate: S2 is at least 10× faster
  (temporalTime.toDouble / spatialTime) should be >= 10.0
}
```

---

# AUTOMATION SCRIPTS REFERENCE

## Available Scripts (in `/scripts` directory)

### Local Testing
```bash
# Quick single-file test
TABLE_ID=E0D01 FILE_LIMIT=1 ./scripts/run-local-parquet-converter.sh

# Iceberg E2E test
./scripts/run-iceberg-e2e-test.sh

# Performance profiling
./scripts/profile-bottleneck.sh
```

### EMR Deployment
```bash
# Launch cluster via Report Framework (ALWAYS use this, not raw aws CLI)
mvn exec:java -Dexec.mainClass="com.traffic.emr.deployment.TrafficMLPredictiveIndexing"

# Monitor job progress
./scripts/monitor-emr-job.sh {CLUSTER_ID} {STEP_ID}

# Fetch container logs after failure
./scripts/fetch-emr-logs.sh {CLUSTER_ID}
```

### Validation
```bash
# Validate S2 partition structure
./scripts/validate-s2-partitions.sh s3://bucket/output/

# Benchmark bbox query performance
./scripts/bbox-performance-test.sh
```

---

# TROUBLESHOOTING FLOWCHART

```
START: Job failed or performing poorly
  ↓
Q: Did job fail completely?
  ├─ YES → Get container logs (wait 5-10 min) → Identify error signature
  │         ├─ Schema mismatch → Fix DataFrame columns
  │         ├─ Missing dependency → Add to pom.xml
  │         ├─ Catalog conflict → Remove app-level config
  │         ├─ OOM → Check for writer explosion
  │         └─ Other → Search error in docs
  │
  └─ NO (job succeeded but slow)
       ↓
    Q: Is GC time > 30% in Spark UI?
       ├─ YES → Likely writer explosion
       │         ↓
       │      Calculate: Partitions × 50MB > Executor Memory?
       │         ├─ YES → Implement micro-batching or migrate to Iceberg
       │         └─ NO → Check for large object allocations
       │
       └─ NO → Profile with JFR
              ↓
           Q: Where is time spent?
              ├─ AggregationIterator → Look for redundant first() calls
              ├─ S3 operations → Check partition overwrite mode (static vs dynamic)
              ├─ Shuffle operations → Optimize join strategies
              └─ Business logic → Refactor inefficient transformations
```

---

# KEY METRICS TO TRACK

## Performance Metrics

- **Stage duration** - Which stages are bottlenecks?
- **Task time vs GC time** - GC > 30% indicates memory pressure
- **Files scanned** - Partition pruning effectiveness
- **Shuffle bytes** - Join/aggregation efficiency
- **Output files created** - Data distribution

## Cost Metrics

- **EMR cluster cost per hour** - Instance types × count × hourly rate
- **Job duration** - Minutes to process data
- **Cost per GB processed** - Cluster cost × duration / data volume
- **Monthly cost projection** - For 24/7 operation

## Optimization Impact Metrics

- **Performance improvement** - (Old time - New time) / Old time
- **Cost reduction** - (Old cost - New cost) / Old cost
- **Query speedup** - Files scanned old / files scanned new
- **ROI** - Monthly savings / hours invested

---

# EXAMPLE INTERACTIONS

## Example 1: Debugging OOM Error

**User:** "My Spark job is failing with OutOfMemoryError during write stage. What should I check?"

**Response:**
This sounds like writer explosion. Let's diagnose:

1. **Get container logs first** (step stderr won't show root cause):
```bash
APP_ID=$(grep -oP 'application_\d+_\d+' /tmp/{cluster-id}-stderr | head -1)
# Wait 5-10 min, then:
aws s3 cp "s3://aws-logs-.../containers/${APP_ID}/container_${APP_ID}_000001/stderr.gz" /tmp/container-stderr.gz
gunzip /tmp/container-stderr.gz
cat /tmp/container-stderr | grep -A 10 "OutOfMemoryError"
```

2. **Calculate partition count**:
```scala
// How many unique partition values do you have?
df.select($"partition_col1", $"partition_col2").distinct().count()
```

3. **Check if writer explosion**:
```
Safe Limit = Executor Memory / 50 MB
Example: 8 GB executor = ~160 safe partitions

If your distinct partitions > safe limit → Writer explosion confirmed
```

4. **Solutions**:
   - **Short-term**: Implement micro-batching (see Section C, Solution 1)
   - **Long-term**: Migrate to Iceberg (see Section F)

Want help implementing micro-batching?

## Example 2: Configuration Not Working

**User:** "I set `partitionOverwriteMode=dynamic` but my job still scans all partitions. Why?"

**Response:**
This is a configuration precedence issue. Where did you set it?

```scala
// ❌ This gets overridden on EMR:
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

// ✅ Set at DataFrame level (highest precedence):
df.write
  .mode(SaveMode.Overwrite)
  .option("partitionOverwriteMode", "dynamic")  // This works!
  .partitionBy("col1", "col2")
  .parquet(path)
```

Configuration hierarchy:
1. DataFrame `.option()` ← **Use this!**
2. spark-submit --conf
3. EMR spark-defaults.conf ← **Overrides session config**
4. Session `.conf.set()`

Always set critical write options at DataFrame level to avoid EMR overrides.

## Example 3: Performance Optimization

**User:** "My job takes 90 minutes to process 1 hour of data. How can I make it faster?"

**Response:**
Let's profile systematically:

1. **Run JFR profiling locally** (if dataset fits):
```bash
java -XX:StartFlightRecording=duration=300s,filename=/tmp/profile.jfr \
     -cp target/classes com.traffic.etl.YourMainClass
jfr print --events jdk.ExecutionSample /tmp/profile.jfr | head -50
```

2. **Check Spark UI** for:
   - GC time > 30% → Memory issue (writer explosion?)
   - High shuffle bytes → Expensive joins
   - Uneven task duration → Data skew

3. **Common bottlenecks**:
   - **Redundant aggregations**: Are you calling `first()` on columns that are identical within groups?
   - **Static partition mode**: Are you scanning all S3 partitions unnecessarily?
   - **Wrong partition strategy**: Are you partitioning by time when queries filter by space?

Share your JFR output or Spark UI screenshot and I'll help identify the specific bottleneck.

Based on 30+ optimization iterations, the most common issues are:
- Inefficient aggregations (35% speedup possible)
- Static partition mode (10-20× slowdown)
- Wrong partitioning strategy (3-4× slowdown)

---

# CRITICAL WARNINGS & BEST PRACTICES

## DO NOT Deploy Without These

### 1. Container Log Retrieval Process
**Always wait 5-10 minutes** after job failure before checking container logs. They upload asynchronously.

### 2. Micro-Batching for High-Cardinality Partitions
If partition count > 3,000, **you must use micro-batching or Iceberg**. Configuration alone won't solve writer explosion.

### 3. DataFrame-Level Configuration
**Never rely on session-level config** for critical write options on EMR. Always set at DataFrame level.

### 4. Consistent SaveMode in Batches
**Never switch SaveMode** between micro-batches. Use `SaveMode.Overwrite` + `partitionOverwriteMode=dynamic` for all batches.

### 5. Cloud Custodian Tag Compliance
**Always use EMRDeployment framework**, never raw `aws emr create-cluster`. Missing tags cause auto-termination.

## Profile Before Optimizing

**Real stats from ITER1-22:**
- Config iterations 1-11: 0% improvement
- Profiling iteration 22: 35% improvement

**Lesson:** Measure, don't guess.

## Test at Production Scale

**ITER21-23 example:**
- 1 file: ✅ Success (6 min)
- 10 files: ✅ Success (26 min)
- 60 files: ❌ Catastrophic failure (214 min, OOM)

**Lesson:** Small-scale success doesn't guarantee large-scale success.

## Architecture > Configuration

**ITER24-25 proved this:**
- ITER24: Changed config (session level) → No improvement
- ITER25: Changed config (DataFrame level) → No improvement
- ITER26: Changed architecture (micro-batching) → Success!

**Lesson:** Some problems require architectural changes, not config tweaks.

---

# REFERENCES TO PROJECT DOCUMENTATION

For deep dives, consult:
- **docs/IN_MEMORY_WRITER_EXPLOSION.md** - Detailed writer explosion analysis
- **docs/S2_PARTITIONING_PERFORMANCE_REPORT.md** - Spatial partitioning results
- **docs/ICEBERG_OPTIMIZATION_HISTORY.md** - Iceberg migration progress
- **docs/DEBUGGING_SPARK_EMR.md** - EMR debugging workflows
- **docs/ICEBERG_E2E_TESTING.md** - E2E test framework
- **CLAUDE.local.md** - Container log retrieval process

---

**END OF SPARK OPTIMIZATION & DEBUGGING SKILL**
