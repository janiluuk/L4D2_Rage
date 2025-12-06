# Skills Testing Guide

This document describes the comprehensive test coverage for all RAGE skill plugins.

## Test Files

### 1. `rage_tests_skills.sp`
Basic skill tests with individual commands for each skill.

### 2. `rage_tests_skills_comprehensive.sp`
Comprehensive test suite with:
- Individual skill tests
- Skill registration tests
- Cooldown system tests
- Edge case and error handling tests
- Test result tracking and summary

### 3. `test_skills.sh`
Automated shell script that validates:
- Plugin file existence
- Skill registration in config
- Cooldown system integration
- Include patterns
- Cleanup patterns

## Running Tests

### In-Game Commands

All tests require admin privileges (ADMFLAG_ROOT):

```
sm_test_lethalweapon      - Test Lethal Weapon skill
sm_test_extendedsight     - Test Extended Sight skill
sm_test_deadringer        - Test Dead Ringer skill
sm_test_healingorb        - Test Healing Orb skill
sm_test_unvomit           - Test Unvomit skill
sm_test_berzerk           - Test Berzerk skill
sm_test_satellite         - Test Satellite skill
sm_test_nightvision       - Test Nightvision skill
sm_test_parachute         - Test Parachute skill
sm_test_ninjakick         - Test Ninja Kick skill
sm_test_airstrike         - Test Airstrike skill
sm_test_multiturret       - Test Multiturret skill
sm_test_all_skills        - Run all skill tests sequentially
sm_test_skill_registration - Test skill registration system
sm_test_cooldown_system    - Test cooldown notification system
sm_test_skill_edge_cases   - Test edge cases and error handling
sm_test_summary            - Show test summary
```

### Automated Tests

Run the shell script:
```bash
./tests/test_skills.sh
```

This will check:
- All skill plugin files exist
- Skills are registered in class config
- Cooldown system is integrated
- Proper includes are used
- Cleanup patterns are followed

## Test Coverage

### Per-Skill Tests

Each skill test checks:

1. **Plugin Loading**
   - Verifies plugin library exists
   - Checks if plugin is loaded

2. **Skill Registration**
   - Verifies skill is registered with Rage system
   - Checks skill name matches expected value

3. **Class Requirements**
   - Verifies player has correct class for skill
   - Tests class-specific restrictions

4. **Activation**
   - Tests skill activation
   - Verifies success/failure handling
   - Checks cooldown behavior

5. **Effects**
   - Visual verification notes
   - Health/state changes where applicable
   - Particle/sound effects

### System Tests

#### Skill Registration System
- All expected skills are registered
- Skills are assigned to correct classes
- No duplicate registrations

#### Cooldown Notification System
- Cooldown registration works
- Notifications trigger on cooldown end
- Sound plays correctly
- HUD/hint text displays

#### Edge Cases
- Invalid client indices rejected
- Dead players handled correctly
- Wrong class restrictions enforced
- Rapid activation handling
- Cooldown system with invalid clients

## Test Results

Tests track:
- **Tests Run**: Total number of test assertions
- **Tests Passed**: Successful assertions
- **Tests Failed**: Failed assertions

View summary with: `sm_test_summary`

## Expected Test Results

### All Skills Should:
- ✓ Load their plugin library
- ✓ Register with Rage system
- ✓ Activate when conditions are met
- ✓ Handle cooldowns properly
- ✓ Clean up on disconnect
- ✓ Use KillTimerSafe for timers

### Cooldown System Should:
- ✓ Register cooldowns when skills are used
- ✓ Play sound when cooldown ends
- ✓ Show hint text notification
- ✓ Clean up properly

## Manual Testing Checklist

For thorough testing, manually verify:

1. **Lethal Weapon**
   - [ ] Crouch with sniper rifle charges weapon
   - [ ] Charged shot creates explosion
   - [ ] Cooldown notification plays sound
   - [ ] Works only for Saboteur class

2. **Extended Sight**
   - [ ] Infected glow through walls
   - [ ] Cooldown prevents rapid use
   - [ ] Works only for Saboteur class

3. **Dead Ringer**
   - [ ] Player becomes invisible
   - [ ] Fake corpse spawns
   - [ ] Speed boost active
   - [ ] Works only for Saboteur class

4. **Healing Orb**
   - [ ] Orb spawns at crosshair
   - [ ] Heals nearby players
   - [ ] Cooldown notification works
   - [ ] Works only for Medic class

5. **Unvomit**
   - [ ] Clears boomer bile
   - [ ] Cooldown prevents spam
   - [ ] Works only for Medic class

6. **Berzerk**
   - [ ] Faster attack rate
   - [ ] Damage boost active
   - [ ] Fire shield appears
   - [ ] Works only for Commando class

7. **Satellite**
   - [ ] Orbital strike targets outdoor area
   - [ ] Explosion effects visible
   - [ ] Works for Soldier class

8. **Nightvision**
   - [ ] Screen brightness changes
   - [ ] Toggle on/off works
   - [ ] Works for Soldier class

9. **Parachute**
   - [ ] Activates when falling
   - [ ] Slows descent
   - [ ] Works only for Athlete class

10. **Ninja Kick**
    - [ ] Sprint + jump activates kick
    - [ ] Damages and knocks back enemies
    - [ ] Works only for Athlete class

11. **Airstrike**
    - [ ] Marker thrown correctly
    - [ ] F-18 airstrike appears
    - [ ] Works for Engineer class

12. **Multiturret**
    - [ ] Menu opens on activation
    - [ ] Turrets deploy correctly
    - [ ] Works only for Engineer class

## Troubleshooting

### Tests Fail to Run
- Ensure `rage_tests_enabled` ConVar is set to 1
- Check that you have ADMFLAG_ROOT permissions
- Verify test plugins are compiled and loaded

### Skills Not Found
- Check that skill plugins are compiled
- Verify plugins are in `plugins/` directory
- Check server logs for load errors

### Cooldown Notifications Not Working
- Verify `rage/cooldown_notify.inc` is included in core plugin
- Check that skills call `CooldownNotify_Register()`
- Ensure sound file exists: `level/startwam.wav`

### Class Restrictions Not Working
- Verify class config is correct
- Check that `OnPlayerClassChange` is called
- Ensure skill plugins check class properly

## Continuous Integration

The test suite can be integrated into CI/CD pipelines:

```bash
# Run automated tests
./tests/test_skills.sh

# Check exit code
if [ $? -eq 0 ]; then
    echo "All tests passed"
else
    echo "Some tests failed"
    exit 1
fi
```

## Contributing New Tests

When adding a new skill:

1. Add test command in `rage_tests_skills_comprehensive.sp`
2. Add skill to `g_SkillTests` array
3. Add skill to class config test in `test_skills.sh`
4. Update this documentation

Test structure:
```sourcepawn
public Action Command_TestNewSkill(int client, int args)
{
    // 1. Check plugin loaded
    // 2. Check skill registered
    // 3. Check class requirements
    // 4. Check player alive
    // 5. Test activation
    // 6. Verify effects
}
```

