# ClaudeFlow Examples

Real-world examples of autonomous task execution.

## Example 1: Test Coverage Improvement

**Goal**: Improve test coverage from 45% to 80%

```bash
# Create task
claudeflow create improve_coverage "Increase test coverage to 80%"
```

**Interactive setup**:
```
Stages: 4
Stage 1: Scan codebase and identify untested modules
Stage 2: Write unit tests for each module
Stage 3: Run coverage reports and verify > 80%
Stage 4: Clean up and verify all tests pass
Validation: npm run test:coverage
TaskFlow: COV-001
Max iterations: 25
```

```bash
# Start
claudeflow start improve_coverage 25
```

**Execution trace**:
```
Iteration 1: Scans code, finds 15 untested files
Iteration 2: Writes tests for utils/parser.js
Iteration 3: Writes tests for utils/validator.js
...
Iteration 12: Coverage at 62%, continues
...
Iteration 18: Coverage at 81%
Iteration 19: Final validation, all tests pass
✅ COMPLETE
```

**Results**:
- 15 new test files created
- Coverage: 45% → 81%
- All tests passing
- Documented in TaskFlow COV-001

---

## Example 2: Systematic Refactoring

**Goal**: Refactor auth module to use interface pattern

```bash
claudeflow create refactor_auth "Refactor auth to use interfaces"
```

**Setup**:
```
Stages: 5
Stage 1: Extract IAuthProvider interface
Stage 2: Extract ISessionStore interface
Stage 3: Update LocalAuth implementation
Stage 4: Update OAuthProvider implementation
Stage 5: Update all imports and tests
Validation: npm test && npm run type-check
TaskFlow: REF-001
Max iterations: 20
```

**Execution trace**:
```
Iteration 1: Creates src/auth/interfaces/IAuthProvider.ts
Iteration 2: Defines interface methods (login, logout, refresh)
Iteration 3: Starts ISessionStore, discovers circular dependency
Iteration 4: Fixes circular dep by proper interface extraction
Iteration 5: Updates LocalAuth to implement IAuthProvider
Iteration 6: Updates OAuthProvider, hits type errors
Iteration 7: Fixes type errors in OAuthProvider
Iteration 8: Updates tests for LocalAuth
Iteration 9: Updates tests for OAuthProvider
Iteration 10: Final validation, all pass
✅ COMPLETE
```

**Context highlights**:
```markdown
## Iteration 3 - ISessionStore (Attempt 1)
Issues: Circular dependency detected
Next: Need to restructure interface hierarchy

## Iteration 4 - Fix Circular Dependency
Actions: Created proper interface hierarchy
Next: Now safe to update implementations
```

---

## Example 3: Migration Task

**Goal**: Convert 30 JavaScript files to TypeScript

```bash
claudeflow create js_to_ts "Migrate JS files to TypeScript"
```

**Setup**:
```
Stages: 4
Stage 1: Rename all .js to .ts
Stage 2: Add type annotations (5 files per iteration)
Stage 3: Fix all type errors
Stage 4: Update imports and verify build
Validation: npm run type-check
Max iterations: 50
```

**Execution pattern**:
```
Iteration 1: Renames src/utils/parser.js → .ts
Iteration 2: Renames src/utils/validator.js → .ts
...
Iteration 6: All files renamed, moves to stage 2
Iteration 7: Adds types to parser.ts, validator.ts, formatter.ts
Iteration 8: Adds types to logger.ts, config.ts
...
Iteration 20: All files annotated, 127 type errors found
Iteration 21-40: Fixes type errors systematically
Iteration 41: Type check passes!
Iteration 42: Updates all imports
Iteration 43: Verifies build
✅ COMPLETE
```

---

## Example 4: Dependency Upgrade

**Goal**: Upgrade React 17 → React 18, fix breaking changes

```bash
claudeflow create react18_upgrade "Upgrade to React 18"
```

**Setup**:
```
Stages: 5
Stage 1: Update package.json dependencies
Stage 2: Update ReactDOM.render to createRoot
Stage 3: Fix breaking changes in components
Stage 4: Update tests
Stage 5: Verify build and all tests pass
Validation: npm test && npm run build
TaskFlow: UPG-001
Max iterations: 30
```

**Execution**:
```
Iteration 1: Updates package.json
Iteration 2: Runs npm install
Iteration 3: Updates src/index.js with createRoot
Iteration 4: Scans for breaking changes, finds 8 components
Iteration 5-12: Fixes each component
Iteration 13: Updates test setup
Iteration 14-20: Updates failing tests
Iteration 21: All tests pass, build succeeds
✅ COMPLETE
```

---

## Example 5: Documentation Generation

**Goal**: Document all API endpoints with examples

```bash
claudeflow create api_docs "Document all API endpoints"
```

**Setup**:
```
Stages: 4
Stage 1: List all API routes
Stage 2: Add JSDoc comments to each route
Stage 3: Generate OpenAPI spec
Stage 4: Create usage examples in README
Validation: npm run docs:validate
Max iterations: 25
```

**Execution**:
```
Iteration 1: Scans routes/, finds 24 endpoints
Iteration 2-10: Adds JSDoc to each endpoint
Iteration 11: Generates OpenAPI spec
Iteration 12-18: Creates example for each endpoint
Iteration 19: Updates API README.md
Iteration 20: Validates docs
✅ COMPLETE
```

---

## Example 6: Lint & Format Cleanup

**Goal**: Fix all ESLint errors and format code

```bash
claudeflow create lint_cleanup "Fix all linting errors"
```

**Setup**:
```
Stages: 3
Stage 1: Fix auto-fixable errors
Stage 2: Fix remaining errors manually
Stage 3: Run prettier formatting
Validation: npm run lint && npm run format:check
Max iterations: 15
```

**Execution**:
```
Iteration 1: Runs eslint --fix, 150 → 45 errors
Iteration 2-8: Fixes errors batch by batch
Iteration 9: All lint errors fixed
Iteration 10: Runs prettier on all files
Iteration 11: Final validation
✅ COMPLETE
```

---

## Example 7: Performance Optimization

**Goal**: Optimize React component render performance

```bash
claudeflow create perf_opt "Optimize render performance"
```

**Setup**:
```
Stages: 5
Stage 1: Profile components with React DevTools
Stage 2: Add React.memo to expensive components
Stage 3: Optimize useEffect dependencies
Stage 4: Add useMemo/useCallback where needed
Stage 5: Verify performance improvement
Validation: npm run perf-test
TaskFlow: PERF-001
Max iterations: 20
```

**Execution**:
```
Iteration 1: Profiles app, identifies 5 problem components
Iteration 2-6: Adds React.memo to each component
Iteration 7: Tests, still seeing unnecessary renders
Iteration 8-12: Optimizes useEffect dependencies
Iteration 13-16: Adds useMemo/useCallback
Iteration 17: Re-profiles, sees 60% render reduction
Iteration 18: Final perf test passes
✅ COMPLETE
```

---

## Example 8: Database Migration

**Goal**: Migrate database schema with data migration

```bash
claudeflow create db_migration "Migrate user schema"
```

**Setup**:
```
Stages: 5
Stage 1: Create new migration file
Stage 2: Write schema changes
Stage 3: Create data migration script
Stage 4: Test on local DB
Stage 5: Generate rollback migration
Validation: npm run migrate:test
TaskFlow: DB-042
Max iterations: 15
```

**Execution**:
```
Iteration 1: Creates migrations/20251120_user_schema.sql
Iteration 2: Writes ADD COLUMN statements
Iteration 3: Creates data migration for existing users
Iteration 4: Tests on local DB, finds constraint issue
Iteration 5: Fixes constraint handling
Iteration 6: Re-tests, succeeds
Iteration 7: Creates rollback migration
Iteration 8: Tests rollback
✅ COMPLETE
```

---

## Example 9: CI/CD Pipeline Setup

**Goal**: Set up GitHub Actions CI/CD

```bash
claudeflow create setup_ci "Configure GitHub Actions CI"
```

**Setup**:
```
Stages: 4
Stage 1: Create workflow YAML
Stage 2: Configure test job
Stage 3: Configure build job
Stage 4: Configure deploy job
Validation: gh workflow view ci.yml
Max iterations: 20
```

**Execution**:
```
Iteration 1: Creates .github/workflows/ci.yml
Iteration 2: Adds Node.js setup and caching
Iteration 3: Configures test step with coverage
Iteration 4: Adds build step
Iteration 5: Tests workflow syntax
Iteration 6: Adds deploy to staging
Iteration 7: Tests complete workflow
✅ COMPLETE
```

---

## Example 10: Security Audit Fix

**Goal**: Fix all npm audit vulnerabilities

```bash
claudeflow create fix_vulns "Fix npm security vulnerabilities"
```

**Setup**:
```
Stages: 4
Stage 1: Run npm audit and analyze
Stage 2: Update vulnerable dependencies
Stage 3: Fix breaking changes from updates
Stage 4: Verify no vulnerabilities remain
Validation: npm audit --production
Max iterations: 25
```

**Execution**:
```
Iteration 1: Runs audit, finds 15 vulnerabilities
Iteration 2: Updates non-breaking packages
Iteration 3: Updates packages with breaking changes
Iteration 4-10: Fixes breaking changes in code
Iteration 11: Re-audits, 2 vulnerabilities remain
Iteration 12-14: Addresses remaining vulns
Iteration 15: Clean audit!
✅ COMPLETE
```

---

## Example 11: Parallel Multi-Task Execution

**Goal**: Run multiple independent tasks simultaneously

```bash
# Task 1: Add tests
claudeflow create add_tests "Add missing tests" &
# Stages: Identify gaps, write tests, verify coverage

# Task 2: Update docs
claudeflow create update_docs "Update documentation" &
# Stages: Audit docs, update outdated, add new sections

# Task 3: Fix type errors
claudeflow create fix_types "Fix TypeScript errors" &
# Stages: Run type-check, fix errors, verify

# Start all
claudeflow start add_tests 15 &
claudeflow start update_docs 10 &
claudeflow start fix_types 20 &

# Monitor
watch -n 5 'claudeflow list'
```

**Output**:
```
⏳ add_tests: Add missing tests (Stage 2/3)
⏳ update_docs: Update documentation (Stage 3/3)
✅ fix_types: Fix TypeScript errors (COMPLETE)
```

---

## Advanced: Custom State Updates

**Goal**: Task with complex state requirements

```bash
claudeflow create complex_task "Multi-phase deployment"
```

**Custom state fields** (edit JSON after creation):
```json
{
  "task_id": "complex_task",
  "stages": [...],
  "custom_state": {
    "deployed_environments": [],
    "rollback_points": [],
    "health_checks": {}
  },
  "validation_command": "./scripts/validate.sh",
  "next_action": "Deploy to dev environment"
}
```

Claude can read/update `custom_state` for complex tracking.

---

## Pattern Library

### Pattern: Iterative Until Threshold

```bash
# Keep iterating until metric reaches threshold
# Example: Coverage > 80%
# Validation checks metric each iteration
# Task completes when threshold met
```

### Pattern: Batch Processing

```bash
# Process large set of items
# Each iteration handles N items
# Track progress in state
# Continue until all processed
```

### Pattern: Retry with Backoff

```bash
# External dependency might fail
# Retry on validation failure
# Add delays between retries
# Record attempts in context
```

### Pattern: Checkpoint & Resume

```bash
# Long-running task
# Save checkpoints after each stage
# Can resume from any checkpoint
# Useful for overnight tasks
```

---

## Tips for Writing Tasks

### Good Stage Names
✅ "Extract IAuthProvider interface"
✅ "Update LocalAuth implementation"
✅ "Write tests for auth module"

❌ "Refactor code"
❌ "Fix stuff"
❌ "Make it better"

### Good Validation Commands
✅ `npm test`
✅ `npm run type-check`
✅ `./scripts/validate.sh`
✅ `npm run lint && npm test`

❌ `true` (too permissive)
❌ `echo "done"` (meaningless)

### Good Iteration Counts
- **Simple tasks**: 5-10 iterations
- **Medium tasks**: 10-20 iterations
- **Complex tasks**: 20-50 iterations
- **Overnight tasks**: 50-100 iterations

---

**Need more examples?** Check task files in `~/.claude/tasks/completed/` for real execution traces.
