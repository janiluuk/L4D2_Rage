# Testing

This section covers the test suite for L4D2 Rage Edition.

## Test Suites

### [Skill Testing](TESTING_SKILLS.md)
Comprehensive tests for all skill plugins, verifying functionality and integration.

### [Class Skills Testing](TESTING_CLASS_SKILLS.md)
Tests for class deployment menus and skill configuration/registration.

### [Test Scripts](test-scripts.md)
Overview of automated test scripts and how to run them.

## Running Tests

### Automated Test Suite
Run all tests via the build script:

```bash
./build.sh
```

This automatically runs:
- Skill functionality tests
- Class skills tests
- Bug detection tests
- Code coverage analysis
- Integration tests
- Performance tests

### Individual Test Scripts
Located in `tests/` directory:

- `test_skills.sh` - Skill functionality tests
- `test_class_skills.sh` - Class skills tests
- `test_bugs.sh` - Bug detection
- `test_coverage.sh` - Code coverage
- `test_integration.sh` - Integration tests
- `test_integration_detailed.sh` - Detailed integration tests
- `test_performance.sh` - Performance and memory leak tests

### Manual Testing
In-game test commands (admin only):

- `sm_test_all_skills` - Run all skill tests
- `sm_test_deadsight` - Test extended sight
- `sm_test_healingorb` - Test healing orb
- `sm_test_lethalweapon` - Test lethal weapon
- And more... (see test plugin for full list)

## Test Coverage

The test suite covers:
- ✅ Plugin loading and registration
- ✅ Skill activation and cooldowns
- ✅ Class assignment and menus
- ✅ Deployment actions
- ✅ Memory leak detection
- ✅ Performance optimization checks
- ✅ Integration between systems

## Related Documentation

- [Development Guidelines](../development/agent-guidelines.md)
- [Plugin Integration](../development/plugin-integration.md)

