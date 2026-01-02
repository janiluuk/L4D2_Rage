#!/bin/bash
# Test suite for refactored plugin code
# Validates that refactored plugins maintain functionality

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Refactored Plugins Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Test 1: Verify new base include exists and has expected content
echo -e "${BLUE}Test 1: Verify skill_plugin_base.inc exists${NC}"
if [ -f "sourcemod/scripting/include/rage/skill_plugin_base.inc" ]; then
    if grep -q "RAGE_SKILL_PLUGIN_GLOBALS" "sourcemod/scripting/include/rage/skill_plugin_base.inc"; then
        echo -e "${GREEN}  ✓ PASSED: skill_plugin_base.inc exists with macros${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: skill_plugin_base.inc missing expected macros${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}  ✗ FAILED: skill_plugin_base.inc not found${NC}"
    ((TESTS_FAILED++))
fi

# Test 2: Verify refactored unvomit plugin has improved structure
echo -e "\n${BLUE}Test 2: Verify unvomit plugin refactoring${NC}"
if [ -f "sourcemod/scripting/rage_survivor_plugin_unvomit.sp" ]; then
    # Check for use of IsValidSurvivor helper
    if grep -q "IsValidSurvivor" "sourcemod/scripting/rage_survivor_plugin_unvomit.sp"; then
        echo -e "${GREEN}  ✓ PASSED: Uses IsValidSurvivor helper${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: Doesn't use IsValidSurvivor helper${NC}"
        ((TESTS_FAILED++))
    fi
    
    # Check for VOMIT_DURATION constant
    if grep -q "VOMIT_DURATION" "sourcemod/scripting/rage_survivor_plugin_unvomit.sp"; then
        echo -e "${GREEN}  ✓ PASSED: Uses VOMIT_DURATION constant${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: Missing VOMIT_DURATION constant${NC}"
        ((TESTS_FAILED++))
    fi
    
    # Check for improved comments/documentation
    if grep -q "@param" "sourcemod/scripting/rage_survivor_plugin_unvomit.sp"; then
        echo -e "${GREEN}  ✓ PASSED: Has function documentation${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: Missing function documentation${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}  ✗ FAILED: unvomit plugin not found${NC}"
    ((TESTS_FAILED+=3))
fi

# Test 3: Verify blink plugin refactoring
echo -e "\n${BLUE}Test 3: Verify blink plugin refactoring${NC}"
if [ -f "sourcemod/scripting/rage_survivor_plugin_blink.sp" ]; then
    # Check for use of IsValidSurvivor in the file (separated checks are OK)
    if grep -q "IsValidSurvivor" "sourcemod/scripting/rage_survivor_plugin_blink.sp"; then
        echo -e "${GREEN}  ✓ PASSED: Uses IsValidSurvivor helper${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: Doesn't use IsValidSurvivor helper${NC}"
        ((TESTS_FAILED++))
    fi
    
    # Check for improved code organization (function documentation)
    if grep -q "@param client" "sourcemod/scripting/rage_survivor_plugin_blink.sp"; then
        echo -e "${GREEN}  ✓ PASSED: Has improved documentation${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: Missing improved documentation${NC}"
        ((TESTS_FAILED++))
    fi
    
    # Check for simplified TraceFilter
    if grep -A 3 "TraceFilter_Blink" "sourcemod/scripting/rage_survivor_plugin_blink.sp" | grep -q "return.*&&"; then
        echo -e "${GREEN}  ✓ PASSED: Has simplified TraceFilter${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: TraceFilter not simplified${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${RED}  ✗ FAILED: blink plugin not found${NC}"
    ((TESTS_FAILED+=3))
fi

# Test 4: Check that all rage plugin files exist
echo -e "\n${BLUE}Test 4: Verify core plugin files exist${NC}"
CORE_PLUGINS=(
    "rage_survivor.sp"
    "rage_survivor_menu.sp"
    "rage_menu_base.sp"
    "rage_menu_admin.sp"
)

for plugin in "${CORE_PLUGINS[@]}"; do
    if [ -f "sourcemod/scripting/$plugin" ]; then
        echo -e "${GREEN}  ✓ PASSED: $plugin exists${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: $plugin not found${NC}"
        ((TESTS_FAILED++))
    fi
done

# Test 5: Verify include directory structure
echo -e "\n${BLUE}Test 5: Verify include directory structure${NC}"
REQUIRED_INCLUDES=(
    "rage/validation.inc"
    "rage/skills.inc"
    "rage/common.inc"
    "rage/effects.inc"
    "rage/skill_plugin_base.inc"
)

for inc in "${REQUIRED_INCLUDES[@]}"; do
    if [ -f "sourcemod/scripting/include/$inc" ]; then
        echo -e "${GREEN}  ✓ PASSED: $inc exists${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}  ✗ FAILED: $inc not found${NC}"
        ((TESTS_FAILED++))
    fi
done

# Test 6: Check for code quality improvements
echo -e "\n${BLUE}Test 6: Code quality checks${NC}"

# Check that plugins use consistent formatting
SKILL_PLUGINS=($(find sourcemod/scripting -name "rage_survivor_plugin_*.sp" -type f))
CONSISTENT=0
TOTAL_CHECKED=0
for plugin in "${SKILL_PLUGINS[@]}"; do
    # Check for proper semicolon usage
    if head -5 "$plugin" | grep -q "#pragma semicolon 1"; then
        ((CONSISTENT++))
    fi
    ((TOTAL_CHECKED++))
done

# Need at least 50% consistency
THRESHOLD=$((TOTAL_CHECKED / 2))
if [ $CONSISTENT -ge $THRESHOLD ]; then
    echo -e "${GREEN}  ✓ PASSED: $CONSISTENT/$TOTAL_CHECKED plugins use consistent pragma directives${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}  ✗ FAILED: Only $CONSISTENT/$TOTAL_CHECKED plugins use consistent pragma directives${NC}"
    ((TESTS_FAILED++))
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}\n"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo -e "Total Tests:  $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All refactoring tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some refactoring tests failed.${NC}"
    exit 1
fi
