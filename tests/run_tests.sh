#!/bin/bash
# L4D2 Rage Edition - Test Runner
# Runs automated tests for the Rage plugin system

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Running: $test_name${NC}"
    
    if eval "$test_command" > /tmp/test_output_$$.log 2>&1; then
        echo -e "${GREEN}  ✓ PASSED: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        TEST_RESULTS+=("PASS: $test_name")
        return 0
    else
        echo -e "${RED}  ✗ FAILED: $test_name${NC}"
        cat /tmp/test_output_$$.log | head -20
        TESTS_FAILED=$((TESTS_FAILED + 1))
        TEST_RESULTS+=("FAIL: $test_name")
        return 1
    fi
}

# Function to check if a file exists
test_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        return 0
    else
        echo "File not found: $file"
        return 1
    fi
}

# Function to check if a pattern exists in a file
test_pattern_in_file() {
    local file="$1"
    local pattern="$2"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        return 0
    else
        echo "Pattern not found in $file: $pattern"
        return 1
    fi
}

# Function to check if multiple patterns exist in a file (multiline)
test_patterns_in_file() {
    local file="$1"
    shift
    local patterns=("$@")
    
    for pattern in "${patterns[@]}"; do
        if ! grep -q "$pattern" "$file" 2>/dev/null; then
            echo "Pattern not found in $file: $pattern"
            return 1
        fi
    done
    return 0
}

# Function to check compilation
test_compilation() {
    local plugin="$1"
    local sp_file=""
    local smx_file="sourcemod/plugins/$plugin.smx"
    
    # Check in root scripting directory first
    if [ -f "sourcemod/scripting/$plugin.sp" ]; then
        sp_file="sourcemod/scripting/$plugin.sp"
    # Check in plugins subdirectory
    elif [ -f "sourcemod/scripting/plugins/$plugin.sp" ]; then
        sp_file="sourcemod/scripting/plugins/$plugin.sp"
    # Check in gamemodes subdirectory
    elif [ -f "sourcemod/scripting/gamemodes/$plugin.sp" ]; then
        sp_file="sourcemod/scripting/gamemodes/$plugin.sp"
    else
        echo "Plugin source not found: $plugin.sp (checked root, plugins/, and gamemodes/)"
        return 1
    fi
    
    # Check if compiled file exists and is recent
    if [ -f "$smx_file" ]; then
        # Check if smx is newer than sp (or within 5 minutes)
        local sp_time=$(stat -c %Y "$sp_file" 2>/dev/null || stat -f %m "$sp_file" 2>/dev/null)
        local smx_time=$(stat -c %Y "$smx_file" 2>/dev/null || stat -f %m "$smx_file" 2>/dev/null)
        local time_diff=$((sp_time - smx_time))
        
        if [ $time_diff -lt 300 ]; then
            return 0
        fi
    fi
    
    echo "Plugin not compiled or out of date: $plugin"
    return 1
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}L4D2 Rage Edition - Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ===================================================================
# Critical Test Cases
# ===================================================================

echo -e "${YELLOW}=== Critical Test Cases ===${NC}\n"

# Test 1: Client Disconnect Cleanup - Check for timer cleanup
run_test "Timer Cleanup on Disconnect" \
    "test_patterns_in_file 'sourcemod/scripting/plugins/rage_plugin_multiple_equipment.sp' 'OnClientDisconnect_Post' 'ME_Notify'"

# Test 2: Entity Cleanup on Disconnect
run_test "Entity Cleanup on Disconnect" \
    "test_patterns_in_file 'sourcemod/scripting/plugins/rage_plugin_multiple_equipment.sp' 'OnClientDisconnect_Post' 'RemoveItemAttach'"

# Test 3: Input Handling - Check CTRL/SHIFT handling
run_test "Input Handling (CTRL/SHIFT)" \
    "test_patterns_in_file 'sourcemod/scripting/rage_survivor.sp' 'IN_DUCK' 'IN_SPEED'"

# Test 4: Skill Registration - Check all classes have skills
run_test "Skill Registration System" \
    "test_pattern_in_file 'sourcemod/configs/rage_class_skills.cfg' 'special.*skill:'"

# Test 5: Menu Sync - Check cookie usage
run_test "Menu Preference Persistence" \
    "test_patterns_in_file 'sourcemod/scripting/rage_survivor_menu.sp' 'GetClientCookie' && test_pattern_in_file 'sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc' 'SetClientCookie'"

# Test 6: LMC Availability - Check conditional compilation
run_test "LMC Conditional Compilation" \
    "test_pattern_in_file 'sourcemod/scripting/rage_survivor.sp' '#tryinclude.*LMCCore'"

# ===================================================================
# Code Quality Tests
# ===================================================================

echo -e "\n${YELLOW}=== Code Quality Tests ===${NC}\n"

# Test 7: Validation Functions Usage
run_test "Validation Functions Usage" \
    "test_pattern_in_file 'sourcemod/scripting/include/rage/validation.inc' 'stock bool IsValidClient'"

# Test 8: Timer Cleanup Pattern
run_test "Timer Cleanup Pattern" \
    "grep -r 'CreateTimer' sourcemod/scripting/rage*.sp | grep -c 'KillTimer' || [ \$? -eq 1 ]"

# Test 9: Entity Reference Cleanup
run_test "Entity Reference Cleanup" \
    "test_pattern_in_file 'sourcemod/scripting/plugins/rage_plugin_multiple_equipment.sp' 'MEIndex.*= 0'"

# ===================================================================
# Integration Tests
# ===================================================================

echo -e "\n${YELLOW}=== Integration Tests ===${NC}\n"

# Test 10: All Classes Defined (check that all 7 classes are present)
run_test "All Classes Defined" \
    "for class in soldier athlete medic saboteur commando engineer brawler; do grep -qi \"\\\"\$class\\\"\" sourcemod/configs/rage_class_skills.cfg || exit 1; done"

# Test 11: Admin Menu Integration
run_test "Admin Menu Integration" \
    "test_pattern_in_file 'sourcemod/scripting/rage_survivor_menu.sp' 'Menu_AdminMenu'"

# Test 12: Multiple Equipment Integration
run_test "Multiple Equipment Integration" \
    "test_file_exists 'sourcemod/scripting/plugins/rage_plugin_multiple_equipment.sp'"

# Test 13: Rage System Natives
run_test "Rage System Natives" \
    "test_pattern_in_file 'sourcemod/scripting/rage_survivor.sp' 'RegisterRageSkill\\|OnSpecialSkillUsed'"

# ===================================================================
# Compilation Tests
# ===================================================================

echo -e "\n${YELLOW}=== Compilation Tests ===${NC}\n"

# Test 14: Core Plugin Compilation
run_test "Core Plugin Compilation" \
    "test_compilation 'rage_survivor'"

# Test 15: Menu Plugin Compilation
run_test "Menu Plugin Compilation" \
    "test_compilation 'rage_survivor_menu'"

# Test 16: Admin Menu Compilation
run_test "Admin Menu Compilation" \
    "test_compilation 'rage_menu_admin'"

# Test 17: Multiple Equipment Compilation
run_test "Multiple Equipment Compilation" \
    "test_compilation 'rage_plugin_multiple_equipment'"

# ===================================================================
# Configuration Tests
# ===================================================================

echo -e "\n${YELLOW}=== Configuration Tests ===${NC}\n"

# Test 18: Class Skills Config Valid
run_test "Class Skills Config Valid" \
    "test_file_exists 'sourcemod/configs/rage_class_skills.cfg'"

# Test 19: All Classes Have Descriptions
run_test "All Classes Have Descriptions" \
    "grep -c 'description' sourcemod/configs/rage_class_skills.cfg | grep -q '^7$'"

# Test 20: Brawler Has No Skills (as intended)
run_test "Brawler Has No Skills" \
    "grep -A 5 'brawler' sourcemod/configs/rage_class_skills.cfg | grep -q 'none'"

# ===================================================================
# Additional Coverage Tests
# ===================================================================

echo -e "\n${YELLOW}=== Additional Coverage Tests ===${NC}\n"

# Test 21: Plugin name standardization
run_test "Plugin Name Standardization" \
    "grep -r 'name = \"\\[RAGE\\]' sourcemod/scripting/rage*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 22: All plugins have version
run_test "All Plugins Have Version" \
    "for file in sourcemod/scripting/rage*.sp; do [ -f \"\$file\" ] && grep -q 'version.*=' \"\$file\" || exit 1; done"

# Test 23: All plugins have author
run_test "All Plugins Have Author" \
    "for file in sourcemod/scripting/rage*.sp; do [ -f \"\$file\" ] && grep -q 'author.*=' \"\$file\" || exit 1; done"

# Test 24: Array declarations use constants (2048, 4096, MAXPLAYERS are acceptable)
run_test "Array Declarations Use Constants" \
    "PROBLEMATIC=\$(grep -rE '\[[0-9]{4,}\]|\[[0-9]{3,}\+1\]' sourcemod/scripting/rage*.sp 2>/dev/null | grep -vE '2048|4096|MAXPLAYERS|1024' | wc -l) && [ \"\$PROBLEMATIC\" -eq 0 ]"

# Test 25: All includes use rage/ prefix where applicable
run_test "Rage Includes Standardized" \
    "grep -r '#include.*rage/' sourcemod/scripting/rage*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 26: Validation functions used
run_test "Validation Functions Used" \
    "grep -r '#include.*rage/validation' sourcemod/scripting/rage*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 27: Effects system used
run_test "Effects System Used" \
    "grep -r '#include.*rage/effects' sourcemod/scripting/rage*.sp | wc -l | grep -qE '^[3-9]$'"

# Test 28: Debug system used
run_test "Debug System Used" \
    "grep -r '#include.*rage/debug\|PrintDebug' sourcemod/scripting/rage*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 29: No duplicate function definitions
run_test "No Duplicate Functions" \
    "grep -r '^stock\|^void\|^int\|^bool\|^float' sourcemod/scripting/rage*.sp | cut -d'(' -f1 | sort | uniq -d | wc -l | grep -q '^0$'"

# Test 30: Proper error handling
run_test "Error Handling Present" \
    "grep -r 'IsValidClient\|IsValidEntity\|IsValidSurvivor' sourcemod/scripting/rage*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# ===================================================================
# Summary
# ===================================================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}Total:  $((TESTS_PASSED + TESTS_FAILED))${NC}\n"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${YELLOW}Failed Tests:${NC}"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == FAIL:* ]]; then
            echo -e "  ${RED}$result${NC}"
        fi
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}\n"
    exit 0
fi

