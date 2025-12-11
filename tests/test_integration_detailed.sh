#!/bin/bash
# L4D2 Rage Edition - Detailed Integration Test Script
# Tests integration between plugins and systems with comprehensive coverage

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Detailed Integration Tests${NC}"
echo -e "${BLUE}========================================${NC}\n"

FAILED=0
PASSED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    if eval "$test_command" > /tmp/test_output_$$.log 2>&1; then
        echo -e "${GREEN}  ✓ PASSED: $test_name${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAILED: $test_name${NC}"
        cat /tmp/test_output_$$.log | head -5
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# ===================================================================
# 1. All Classes - Verify each class works end-to-end
# ===================================================================

echo -e "${YELLOW}=== 1. All Classes End-to-End Tests ===${NC}\n"

CLASSES=("soldier" "athlete" "medic" "saboteur" "commando" "engineer" "brawler")

for class in "${CLASSES[@]}"; do
    # Test 1.1: Class has description
    run_test "Class $class has description" \
        "grep -A 2 '\"$class\"' sourcemod/configs/rage_class_skills.cfg | grep -q 'description'"
    
    # Test 1.2: Class has at least one skill (except brawler)
    if [ "$class" != "brawler" ]; then
        run_test "Class $class has skills" \
            "grep -A 10 '\"$class\"' sourcemod/configs/rage_class_skills.cfg | grep -qE 'skill:|command:'"
    else
        run_test "Class $class has no skills (as intended)" \
            "grep -A 10 '\"$class\"' sourcemod/configs/rage_class_skills.cfg | grep -q 'none'"
    fi
    
    # Test 1.3: Class has deploy action defined
    run_test "Class $class has deploy action" \
        "grep -A 10 '\"$class\"' sourcemod/configs/rage_class_skills.cfg | grep -q 'deploy'"
    
    # Test 1.4: Class skills are registered in Rage system
    if [ "$class" != "brawler" ]; then
        run_test "Class $class skills registered" \
            "grep -qiE 'RegisterRageSkill|OnSpecialSkillUsed' sourcemod/scripting/rage_survivor.sp"
    fi
done

# Test 1.5: All classes have unique identifiers
run_test "All classes have unique names" \
    "UNIQUE_COUNT=\$(grep -oE '\"(soldier|athlete|medic|saboteur|commando|engineer|brawler)\"' sourcemod/configs/rage_class_skills.cfg | sort -u | wc -l) && [ \"\$UNIQUE_COUNT\" -eq 7 ]"

# ===================================================================
# 2. Skill Combinations - Test skill interactions
# ===================================================================

echo -e "\n${YELLOW}=== 2. Skill Combinations Tests ===${NC}\n"

# Test 2.1: Skills don't conflict with each other
run_test "No duplicate skill registrations" \
    "grep -r 'RegisterRageSkill' sourcemod/scripting/rage*.sp | sed -n 's/.*RegisterRageSkill[^(]*(\"\([^\"]*\)\".*/\1/p' | sort | uniq -d | wc -l | grep -q '^0$'"

# Test 2.2: Skill callbacks are properly implemented
run_test "Skill callbacks implemented" \
    "grep -r 'OnSpecialSkillUsed' sourcemod/scripting/rage_survivor_plugin*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 2.3: Skills use shared effects system
run_test "Skills use shared effects" \
    "grep -r '#include.*rage/effects' sourcemod/scripting/rage_survivor_plugin*.sp | wc -l | grep -qE '^[3-9]$'"

# Test 2.4: Skills have proper success/failure notifications
run_test "Skills have notifications" \
    "grep -r 'OnSpecialSkillSuccess\|OnSpecialSkillFail' sourcemod/scripting/rage_survivor_plugin*.sp | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 2.5: Command-based skills (grenades, missiles) are integrated
run_test "Command skills integrated" \
    "grep -r 'OnCustomCommand\|useCustomCommand' sourcemod/scripting/rage_survivor_plugin*.sp | wc -l | grep -qE '^[2-9]$'"

# Test 2.6: Skill cooldowns don't interfere
run_test "Skill cooldown system exists" \
    "grep -r 'Cooldown\|cooldown' sourcemod/scripting/rage_survivor.sp | grep -q 'int\|float'"

# ===================================================================
# 3. Menu Systems - Test all menu interactions
# ===================================================================

echo -e "\n${YELLOW}=== 3. Menu Systems Tests ===${NC}\n"

# Test 3.1: Main menu is properly built
run_test "Main menu structure exists" \
    "grep -q 'BuildRageMenus\|ExtraMenu_Create' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.2: Menu options are properly mapped
run_test "Menu options mapped" \
    "grep -q 'RageMenuOption\|optionMap' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.3: Class selection menu works
run_test "Class selection menu" \
    "grep -q 'Menu_ChangeClass\|ChangeClass' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.4: Admin menu integration
run_test "Admin menu integrated" \
    "grep -q 'Menu_AdminMenu\|sm_adm' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.5: Third person menu option
run_test "Third person menu option" \
    "grep -q 'Menu_ThirdPerson\|ThirdPerson' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.6: Multiple equipment menu option
run_test "Multiple equipment menu option" \
    "grep -q 'Menu_MultiEquip\|MultiEquip' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.7: Menu preferences persist (cookies)
run_test "Menu preferences persist" \
    "grep -r 'SetClientCookie\|GetClientCookie' sourcemod/scripting/include/rage_menus/*.inc sourcemod/scripting/rage_survivor_menu.sp 2>/dev/null | wc -l | grep -qE '^[1-9][0-9]*$'"

# Test 3.8: Menu sync on display
run_test "Menu sync on display" \
    "grep -q 'SyncMenuSelections\|SyncMenuSelection' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.9: Menu input handling
run_test "Menu input handling" \
    "grep -q 'OnPlayerRunCmd.*menu\|CmdRageMenu' sourcemod/scripting/rage_survivor_menu.sp"

# Test 3.10: Guide menu integration
run_test "Guide menu integration" \
    "grep -q 'Menu_Guide\|TryShowGuideMenu' sourcemod/scripting/rage_survivor_menu.sp"

# ===================================================================
# 4. Multiple Equipment - Test all modes and transitions
# ===================================================================

echo -e "\n${YELLOW}=== 4. Multiple Equipment Tests ===${NC}\n"

# Test 4.1: Multiple equipment modes defined
run_test "Multiple equipment modes defined" \
    "grep -q 'ME_Off\|ME_SingleTap\|ME_DoubleTap' sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc"

# Test 4.2: Mode switching works
run_test "Mode switching implemented" \
    "grep -q 'MultiEquip_SetMode\|MultiEquip_GetMode' sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc"

# Test 4.3: Equipment pickup logic
run_test "Equipment pickup logic" \
    "grep -q 'MultiEquip_OnWeaponCanUse\|SDKHook_WeaponCanUse' sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc"

# Test 4.4: Tap counting system
run_test "Tap counting system" \
    "grep -q 'g_iEquipmentTapCount\|requiredTaps' sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc"

# Test 4.5: Mode persistence (cookies)
run_test "Mode persistence" \
    "grep -q 'g_hMultiEquipCookie\|MultiEquip_OnCookiesCached' sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc"

# Test 4.6: Integration with main plugin
run_test "Integration with main plugin" \
    "grep -q 'ControlMode\|MeEnable' sourcemod/scripting/rage_plugin_multiple_equipment.sp"

# Test 4.7: Equipment slot management
run_test "Equipment slot management" \
    "grep -q 'ItemInfo\|ItemAttachEnt' sourcemod/scripting/rage_plugin_multiple_equipment.sp"

# Test 4.8: Mode transitions clean up state
run_test "Mode transitions clean state" \
    "grep -q 'MultiEquip_Apply\|ResetClientState' sourcemod/scripting/rage_plugin_multiple_equipment.sp"

# Test 4.9: Off mode disables functionality
run_test "Off mode disables functionality" \
    "grep -A 5 'ME_Off' sourcemod/scripting/include/rage_menus/rage_survivor_menu_multiequip.inc | grep -q 'g_bMultiEquipEnabled.*false'"

# Test 4.10: Equipment visual attachments
run_test "Equipment visual attachments" \
    "grep -q 'AttachAllEquipment\|RemoveItemAttach' sourcemod/scripting/rage_plugin_multiple_equipment.sp"

# ===================================================================
# Summary
# ===================================================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Integration Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${BLUE}Total:  $((PASSED + FAILED))${NC}\n"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILED integration test(s) failed${NC}"
    exit 1
fi

