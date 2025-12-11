# Test Scripts Overview

This directory contains comprehensive test scripts for the L4D2 Rage Edition plugin system.

## Test Execution

All tests are automatically run when executing:
```bash
./build.sh
```

Or directly:
```bash
./tests/run_tests.sh
```

## Test Scripts

### 1. `test_skills.sh`
**Purpose:** Comprehensive skills functionality tests
- Tests all skill plugins for existence and compilation
- Verifies skill registration in class config
- Checks cooldown notification system integration
- Validates skill plugin includes and registration patterns
- Tests skill activation handlers and cleanup

### 2. `test_class_skills.sh`
**Purpose:** Class skills and deployment menu tests
- Compiles the `rage_tests_class_skills.sp` test plugin
- Tests deployment menu access for each class
- Validates skill assignments per class
- Verifies skill registration and availability

**Note:** This script compiles the test plugin but requires in-game execution via:
- `sm_test_class_all` - Test all classes
- `sm_test_class_<classname>` - Test individual classes

### 3. `test_bugs.sh`
**Purpose:** Bug detection and prevention
- Detects common SourceMod plugin bugs
- Checks for timer leaks
- Validates entity cleanup
- Verifies error handling patterns
- Checks for memory leaks

### 4. `test_coverage.sh`
**Purpose:** Code coverage analysis
- Analyzes test coverage across plugins
- Identifies untested areas
- Reports coverage metrics
- Suggests areas for additional testing

### 5. `test_integration.sh`
**Purpose:** Basic integration tests
- Tests plugin interactions
- Validates system integration
- Checks cross-plugin dependencies

### 6. `test_integration_detailed.sh`
**Purpose:** Detailed integration tests
- Comprehensive integration testing
- Tests complex plugin interactions
- Validates system-wide functionality
- Checks edge cases and error scenarios

### 7. `test_performance.sh`
**Purpose:** Performance and memory tests
- Checks for timer leaks
- Validates memory management
- Tests performance patterns
- Identifies potential bottlenecks

## Test Execution Order

Tests are executed in the following order:

1. **test_skills.sh** - Skills functionality (foundation)
2. **test_class_skills.sh** - Class-specific tests (depends on skills)
3. **test_bugs.sh** - Bug detection (code quality)
4. **test_coverage.sh** - Coverage analysis (metrics)
5. **test_integration.sh** - Basic integration (simple cases)
6. **test_integration_detailed.sh** - Detailed integration (complex cases)
7. **test_performance.sh** - Performance tests (optimization)

## Test Results

Test results are displayed in the console with:
- ✓ **GREEN** - Test passed
- ✗ **RED** - Test failed
- ⚠ **YELLOW** - Test skipped or warning

## Exit Codes

- **0** - All tests passed
- **1** - One or more tests failed

## Adding New Tests

To add a new test script:

1. Create the script in `tests/` directory
2. Make it executable: `chmod +x tests/your_test.sh`
3. Add it to the `TEST_SCRIPTS` array in `run_tests.sh`
4. Follow the existing test script patterns for consistency

## Test Plugin Compilation

Test plugins (`.sp` files in `sourcemod/scripting/tests/`) are compiled automatically during the build process. They are placed in `sourcemod/plugins/` for in-game execution.

## In-Game Testing

Some tests require in-game execution:
- Class skills tests (`rage_tests_class_skills.smx`)
- Comprehensive skills tests (`rage_tests_skills_comprehensive.smx`)

Use RCON or in-game commands to execute these tests:
```bash
rcon sm_test_class_all
rcon sm_test_all_skills
```

## Continuous Integration

The test suite is designed to run in CI/CD pipelines:
- All tests are non-interactive
- Exit codes indicate success/failure
- Output is formatted for easy parsing
- Tests can be run in parallel (with proper isolation)

