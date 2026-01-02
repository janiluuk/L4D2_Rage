# Code Refactoring Guide

This document describes the refactoring improvements made to L4D2 Rage Edition and provides guidelines for future code improvements.

## Table of Contents

- [Overview](#overview)
- [Refactoring Goals](#refactoring-goals)
- [New Base Utilities](#new-base-utilities)
- [Refactored Plugins](#refactored-plugins)
- [Code Quality Improvements](#code-quality-improvements)
- [Best Practices](#best-practices)
- [Testing Refactored Code](#testing-refactored-code)

---

## Overview

The L4D2 Rage Edition codebase consists of:
- **Core System:** rage_survivor.sp (4,073 lines)
- **Skill Plugins:** 30+ individual skill plugins (rage_survivor_plugin_*.sp)
- **Shared Utilities:** include/rage/*.inc files
- **Menu Systems:** rage_menu_*.sp files
- **Test Suite:** tests/*.sh scripts

### Refactoring Status

**Completed:**
- Created `rage/skill_plugin_base.inc` for common skill plugin patterns
- Refactored `rage_survivor_plugin_unvomit.sp` with improved structure
- Refactored `rage_survivor_plugin_blink.sp` with better documentation
- Added `test_refactored_plugins.sh` validation suite

**In Progress:**
- Remaining 28+ skill plugins
- Core system simplification
- Menu system consolidation

---

## Refactoring Goals

### 1. Reduce Code Duplication
**Problem:** Every skill plugin repeated ~100 lines of Rage system integration boilerplate.

**Solution:** Created `rage/skill_plugin_base.inc` with reusable macros and helper functions.

### 2. Replace Magic Numbers with Constants
**Problem:** Hardcoded values scattered throughout code (e.g., `20.0` for bile duration).

**Solution:** Define constants at file level:
```sourcepawn
#define VOMIT_DURATION 20.0  // Bile naturally expires after 20 seconds
#define WALL_PULLBACK_DISTANCE 10.0  // Distance to move away from walls
```

### 3. Improve Validation and Error Handling
**Problem:** Inconsistent client validation patterns.

**Solution:** Use helpers from `rage/validation.inc`:
```sourcepawn
// Before:
if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
    return;

// After:
if (!IsValidSurvivor(client, true))
    return;
```

### 4. Add Comprehensive Documentation
**Problem:** Many functions lacked documentation.

**Solution:** Add JSDoc-style comments:
```sourcepawn
/**
 * Clears vomit/bile effect from a survivor.
 * 
 * @param client      Client index
 * @param fromEvent   If true, message is suppressed (auto-clear)
 */
void ClearVomit(int client, bool fromEvent)
```

### 5. Improve Code Readability
**Problem:** Deep nesting, long functions, unclear intent.

**Solution:** 
- Early returns to reduce nesting
- Extract complex logic into helper functions
- Descriptive variable names
- Consistent formatting

---

## New Base Utilities

### rage/skill_plugin_base.inc

This new include file provides common patterns for skill plugins.

#### Macros

**RAGE_SKILL_PLUGIN_GLOBALS(skillName, classId)**
Defines standard globals for skill plugins:
```sourcepawn
RAGE_SKILL_PLUGIN_GLOBALS("Blink", 2)
// Expands to:
// int g_iClassID = -1;
// bool g_bRageAvailable = false;
// const int TARGET_CLASS = 2;
// bool g_bHasAbility[MAXPLAYERS+1] = {false, ...};
// const char SKILL_NAME[] = "Blink"
```

**RAGE_SKILL_PLUGIN_LOAD(libraryName)**
Implements standard AskPluginLoad2:
```sourcepawn
RAGE_SKILL_PLUGIN_LOAD("rage_survivor_blink")
```

**RAGE_SKILL_PLUGIN_CALLBACKS(skillName)**
Implements all Rage system callbacks in one macro:
```sourcepawn
RAGE_SKILL_PLUGIN_CALLBACKS("Blink")
// Implements:
// - OnAllPluginsLoaded
// - OnLibraryAdded
// - OnLibraryRemoved
// - Rage_OnPluginState
// - OnPlayerClassChange
```

#### Helper Functions

**Rage_CheckSkillCooldown(client, nextUse, skillName)**
Standard cooldown checking with user feedback:
```sourcepawn
if (!Rage_CheckSkillCooldown(client, g_fNextUse[client], PLUGIN_SKILL_NAME))
    return 0;  // Still on cooldown
```

**Rage_ValidateSkillUse(client, skillName, hasAbility)**
Validates all preconditions for skill use:
```sourcepawn
if (!Rage_ValidateSkillUse(client, PLUGIN_SKILL_NAME, g_bHasAbility[client]))
    return 0;
```

**Rage_ResetClientCooldowns(cooldownArray)**
Reset all client cooldowns (for OnMapStart):
```sourcepawn
public void OnMapStart()
{
    Rage_ResetClientCooldowns(g_fNextUse);
    // Precache models, etc.
}
```

**Rage_InitClientData(client, cooldownArray, hasAbility)**
Initialize client data on connection:
```sourcepawn
public void OnClientPutInServer(int client)
{
    Rage_InitClientData(client, g_fNextUse, g_bHasAbility);
}
```

---

## Refactored Plugins

### Example: rage_survivor_plugin_unvomit.sp

**Before Refactoring (230 lines):**
- Repeated boilerplate
- Magic number `20.0` for bile duration
- Manual client validation
- Minimal documentation

**After Refactoring (230 lines, but improved quality):**
- Uses `IsValidSurvivor` helper
- `VOMIT_DURATION` constant
- Comprehensive function documentation
- Better code organization
- `AutoExecConfig` for config management

**Key Changes:**

1. **Constants for Magic Numbers:**
```sourcepawn
#define VOMIT_DURATION 20.0  // Bile naturally expires after 20 seconds
```

2. **Validation Helpers:**
```sourcepawn
// Before:
if (!IsClientInGame(client) || GetClientTeam(client) != 2)
    return Plugin_Continue;

// After:
if (!IsValidSurvivor(client, false))
    return Plugin_Continue;
```

3. **Function Documentation:**
```sourcepawn
/**
 * Clears vomit/bile effect from a survivor.
 * 
 * @param client      Client index
 * @param fromEvent   If true, message is suppressed (auto-clear)
 */
void ClearVomit(int client, bool fromEvent)
```

4. **AutoExecConfig:**
```sourcepawn
public void OnPluginStart()
{
    g_hCooldown = CreateConVar(...);
    AutoExecConfig(true, "rage_unvomit");  // Auto-generates config file
    // ...
}
```

### Example: rage_survivor_plugin_blink.sp

**Improvements:**
- Better organized comments
- Simplified TraceFilter logic
- Comprehensive function documentation
- Consistent formatting

**Key Changes:**

1. **Simplified Logic:**
```sourcepawn
// Before:
public bool TraceFilter_Blink(int entity, int contentsMask, int client)
{
    if (entity == client)
        return false;
    if (entity > 0 && entity <= MaxClients)
        return false;
    return true;
}

// After:
public bool TraceFilter_Blink(int entity, int contentsMask, int client)
{
    return (entity != client && (entity <= 0 || entity > MaxClients));
}
```

2. **Better Documentation:**
```sourcepawn
/**
 * Performs the blink teleport for a client.
 * Calculates destination, validates position, and teleports the player.
 * 
 * @param client   Client index
 * @return         True if blink succeeded, false otherwise
 */
bool PerformBlink(int client)
```

---

## Code Quality Improvements

### 1. Consistent Formatting

**Standards:**
- Tabs for indentation (existing codebase standard)
- K&R brace style
- `#pragma semicolon 1` and `#pragma newdecls required`
- Blank lines between logical sections

### 2. Naming Conventions

**Variables:**
- `g_` prefix for globals
- `b` prefix for booleans (e.g., `g_bRageAvailable`)
- `i` prefix for integers (e.g., `g_iClassID`)
- `f` prefix for floats (e.g., `g_fNextUse`)
- `h` prefix for handles (e.g., `g_hCooldown`)
- Descriptive names that convey purpose

**Functions:**
- PascalCase for public/forward functions
- camelCase for stock/static functions
- Verb-first naming (e.g., `PerformBlink`, `ClearVomit`)

**Constants:**
- ALL_CAPS with underscores (e.g., `VOMIT_DURATION`)
- Descriptive names with units when applicable

### 3. Error Handling

**Pattern:**
1. Validate inputs at function entry
2. Early return on invalid state
3. Provide user feedback when appropriate
4. Log errors for debugging

```sourcepawn
public int OnSpecialSkillUsed(int client, int skill, int type)
{
    // Early validation
    if (!g_bRageAvailable || !g_cvarEnable.BoolValue)
        return 0;

    // Validate client
    if (!IsValidSurvivor(client, true) || !g_bHasAbility[client])
        return 0;

    // Check cooldown
    if (!Rage_CheckSkillCooldown(client, g_fNextUse[client], PLUGIN_SKILL_NAME))
        return 0;

    // Execute skill
    if (PerformSkill(client))
    {
        g_fNextUse[client] = GetGameTime() + g_cvarCooldown.FloatValue;
        return 1;
    }
    
    return 0;
}
```

### 4. Function Length

**Guidelines:**
- Keep functions focused on single responsibility
- Aim for <50 lines per function
- Extract complex logic into helper functions
- Use descriptive names for extracted functions

---

## Best Practices

### For New Skill Plugins

1. **Use the Base Include:**
```sourcepawn
#include <rage/skill_plugin_base>
```

2. **Consider Using Macros:**
If your plugin follows standard patterns, use the provided macros to reduce boilerplate.

3. **Define Constants:**
Replace magic numbers with named constants at the top of the file.

4. **Document Functions:**
Add JSDoc-style comments to all public functions and complex logic.

5. **Use Validation Helpers:**
Prefer helpers from `rage/validation.inc` over manual checks.

6. **Config Management:**
Use `AutoExecConfig()` to auto-generate config files.

### For Refactoring Existing Code

1. **Identify Patterns:**
Look for repeated code blocks that can be extracted.

2. **Extract Constants:**
Find magic numbers and replace with named constants.

3. **Simplify Validation:**
Replace complex client checks with validation helpers.

4. **Add Documentation:**
Document the intent and usage of functions.

5. **Test Thoroughly:**
Use the test suite to verify functionality after refactoring.

### General Guidelines

- **Minimal Changes:** Make the smallest changes necessary
- **Test Often:** Run tests after each refactoring step
- **Preserve Behavior:** Ensure functionality remains unchanged
- **Commit Frequently:** Small, focused commits are easier to review

---

## Testing Refactored Code

### Test Suite

Run the refactored plugins test suite:
```bash
./tests/test_refactored_plugins.sh
```

This validates:
- New base utilities exist
- Refactored plugins use new helpers
- Code quality improvements are present
- Core files are intact

### Manual Testing

1. **Compilation:** Verify plugins compile without errors
2. **In-Game Testing:** Test each refactored skill in-game
3. **Edge Cases:** Test with invalid inputs, edge conditions
4. **Performance:** Verify no performance regressions

### Integration Testing

Use existing test suites:
```bash
./tests/test_skills.sh          # Test individual skills
./tests/test_class_skills.sh    # Test class skill assignments
./tests/test_integration.sh     # Full integration tests
```

---

## Future Refactoring Opportunities

### High Priority

1. **Remaining Skill Plugins** - Apply same refactoring patterns to other skill plugins
2. **Core System (rage_survivor.sp)** - Break down long functions, extract utilities
3. **Menu Systems** - Consolidate duplicate menu code

### Medium Priority

1. **Common Effects** - Extract repeated visual/audio effects into `rage/effects.inc`
2. **Timer Management** - Consolidate timer handling patterns
3. **Config Loading** - Standardize configuration management

### Low Priority

1. **Legacy Code Cleanup** - Remove unused code and commented-out sections
2. **Performance Optimization** - Profile and optimize hot paths
3. **Code Style Consistency** - Ensure all files follow same style guide

---

## Tools and Resources

### Static Analysis

- **SourceMod Compiler Warnings:** Enable `-w305` for unused variable warnings
- **Test Suite:** Automated validation of code quality

### Documentation

- **This Guide:** Overview of refactoring improvements
- **rage/validation.inc:** Validation helper documentation
- **rage/skills.inc:** Skill registration helper documentation
- **rage/skill_plugin_base.inc:** Base utilities for skill plugins

### Examples

- **rage_survivor_plugin_unvomit.sp:** Example of magic number elimination and validation helpers
- **rage_survivor_plugin_blink.sp:** Example of documentation and code simplification

---

## Contributing

When contributing refactored code:

1. **Follow Patterns:** Use established patterns from refactored plugins
2. **Document Changes:** Add comments explaining non-obvious changes
3. **Test Thoroughly:** Run test suite before submitting
4. **Small PRs:** Keep pull requests focused on specific improvements
5. **Explain Why:** Include rationale for changes in PR description

---

**Last Updated:** 2026-01-02  
**Refactoring Lead:** L4D2 Rage Development Team
