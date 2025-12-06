# Class Skills Testing Guide

This document describes the comprehensive test suite for verifying that each class can access their deployment menu and use all assigned skills.

## Overview

The `rage_tests_class_skills.sp` plugin provides detailed tests for:
- Class assignment and verification
- Deployment menu access
- Skill registration and availability
- Skill configuration validation

## Test Commands

### Test All Classes
```
sm_test_class_all
```
Tests all 7 classes sequentially with delays between each test.

### Test Individual Classes
```
sm_test_class_soldier       - Test Soldier class
sm_test_class_athlete       - Test Athlete class
sm_test_class_medic         - Test Medic class
sm_test_class_saboteur      - Test Saboteur class
sm_test_class_commando      - Test Commando class
sm_test_class_engineer      - Test Engineer class
sm_test_class_brawler       - Test Brawler class
```

## Test Process

Each class test performs the following checks:

### 1. Class Assignment
- Sets the player to the specified class using `sm_class_set`
- Verifies the class was set correctly using `GetPlayerClassName` native

### 2. Deployment Menu Test
- Checks if deployment is configured for the class
- Attempts to open the deployment menu
- Verifies the deployment action command exists

### 3. Skill Testing
For each skill slot (Special, Secondary, Tertiary):
- Parses the skill configuration from `rage_class_skills.cfg`
- Checks if the skill is registered in the Rage system
- Validates skill parameters
- Reports skill availability

### 4. Test Summary
- Displays a summary of all configured skills for the class
- Shows test results for each component

## Class Skill Configurations

Based on `rage_class_skills.cfg`:

### Soldier
- **Special**: `skill:Satellite`
- **Secondary**: `command:Missile:1`
- **Tertiary**: `command:Missile:2`
- **Deploy**: `builtin:engineer_supply`

### Athlete
- **Special**: `command:Grenades:15`
- **Secondary**: `skill:Parachute`
- **Tertiary**: `skill:AthleteJump`
- **Deploy**: `builtin:medic_supply`

### Medic
- **Special**: `command:Grenades:11`
- **Secondary**: `skill:HealingOrb`
- **Tertiary**: `skill:UnVomit`
- **Deploy**: `builtin:medic_supply`

### Saboteur
- **Special**: `skill:cloak:1`
- **Secondary**: `skill:extended_sight`
- **Tertiary**: `skill:LethalWeapon`
- **Deploy**: `builtin:saboteur_mines`

### Commando
- **Special**: `skill:Berzerk`
- **Secondary**: `command:Missile:1`
- **Tertiary**: `command:Missile:2`
- **Deploy**: `builtin:engineer_supply`

### Engineer
- **Special**: `command:Grenades:7`
- **Secondary**: `skill:Multiturret`
- **Tertiary**: `none`
- **Deploy**: `builtin:engineer_supply`

### Brawler
- **Special**: `none`
- **Secondary**: `none`
- **Tertiary**: `none`
- **Deploy**: `none`

## Prerequisites

Before running tests:
1. You must be on the survivor team (team 2)
2. You must be alive
3. All skill plugins must be loaded
4. The `rage_survivor` core plugin must be loaded

## Running Tests

### In-Game
1. Join the survivor team
2. Ensure you're alive
3. Run the test command: `sm_test_class_all` or `sm_test_class_<classname>`
4. Review the test output in console

### Via RCON
```
rcon sm_test_class_all
```

### Compiling the Test Plugin
```bash
cd sourcemod/scripting
spcomp64 -iinclude -iinclude tests/rage_tests_class_skills.sp -oplugins/rage_tests_class_skills.smx
```

Or use the provided script:
```bash
./tests/test_class_skills.sh
```

## Test Output

The test output includes:
- ✓ PASS - Test passed
- ✗ FAIL - Test failed
- Configuration details for each skill
- Skill registration status
- Deployment menu availability

## Example Output

```
[Class Tests] ========================================
[Class Tests] Testing Saboteur Class (Index: 4)
[Class Tests] ========================================
[Class Tests] [1/5] Setting class to Saboteur...
[Class Tests] [2/5] Class Verification: ✓ PASS (Expected: saboteur, Got: Saboteur)
[Class Tests] [3/5] Testing Deployment Menu...
[Class Tests] Deployment Menu: ✓ Command executed (verify manually in-game)
[Class Tests] [4/5] Testing Class Skills...
[Class Tests] Special Skill (cloak): ✓ Registered
[Class Tests]   Skill ID: 5, Param: 1
[Class Tests] Secondary Skill (extended_sight): ✓ Registered
[Class Tests] Tertiary Skill (LethalWeapon): ✓ Registered
[Class Tests] [5/5] Test Summary for saboteur:
[Class Tests]   Special: skill:cloak:1
[Class Tests]   Secondary: skill:extended_sight
[Class Tests]   Tertiary: skill:LethalWeapon
[Class Tests]   Deploy: builtin:saboteur_mines
[Class Tests] ========================================
[Class Tests] saboteur class tests completed!
```

## Limitations

1. **Menu Verification**: The test cannot automatically verify if menus actually open. Manual in-game verification is required.

2. **Skill Activation**: The test checks if skills are registered but cannot automatically test skill activation. You must test skills manually in-game.

3. **Cooldown Testing**: Cooldown functionality is not tested automatically. Test cooldowns manually by using skills repeatedly.

4. **Command-Based Skills**: Skills that use `command:` format require the corresponding plugin to be loaded and may need additional verification.

## Troubleshooting

### Class Not Setting
- Ensure you're on survivor team
- Check that `rage_survivor` plugin is loaded
- Verify class index is valid (1-7)

### Skills Not Registered
- Ensure skill plugins are loaded
- Check that skills are registered in `OnPluginStart`
- Verify skill names match exactly (case-sensitive)

### Deployment Menu Not Opening
- Hold CTRL (IN_DUCK) while looking down
- Ensure you're on ground
- Check that deployment is configured for your class

## Integration with CI/CD

The test plugin can be integrated into automated testing pipelines:
1. Compile the test plugin
2. Load it on a test server
3. Use RCON to execute tests
4. Parse output for pass/fail status

## Future Enhancements

Potential improvements:
- Automatic skill activation testing
- Menu state verification
- Cooldown timer validation
- Visual effect verification
- Sound effect verification

