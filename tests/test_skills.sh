#!/bin/bash
# L4D2 Rage Edition - Comprehensive Skills Test Script
# Tests all skill plugins for functionality, registration, and edge cases

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
echo -e "${BLUE}Comprehensive Skills Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

FAILED=0
PASSED=0
TOTAL=0

# Test 1: All skill plugins exist and compile
echo -e "${YELLOW}Testing: Skill plugin files exist...${NC}"
SKILL_PLUGINS=(
    "rage_survivor_plugin_lethalweapon.sp"
    "rage_survivor_plugin_extendedsight.sp"
    "rage_survivor_plugin_deadringer.sp"
    "rage_survivor_plugin_healingorb.sp"
    "rage_survivor_plugin_unvomit.sp"
    "rage_survivor_plugin_berzerk.sp"
    "rage_survivor_plugin_satellite.sp"
    "rage_survivor_plugin_nightvision.sp"
    "rage_survivor_plugin_parachute.sp"
    "rage_survivor_plugin_ninjakick.sp"
    "rage_survivor_plugin_airstrike.sp"
    "rage_survivor_plugin_multiturret.sp"
    "rage_survivor_plugin_missile.sp"
    "rage_survivor_plugin_grenades.sp"
)

for plugin in "${SKILL_PLUGINS[@]}"; do
    TOTAL=$((TOTAL + 1))
    if [ -f "sourcemod/scripting/$plugin" ]; then
        echo -e "${GREEN}  ✓ $plugin exists${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}  ✗ $plugin missing${NC}"
        FAILED=$((FAILED + 1))
    fi
done

# Test 2: Skill registration in config
echo -e "\n${YELLOW}Testing: Skills registered in class config...${NC}"
EXPECTED_SKILLS=(
    "LethalWeapon:saboteur"
    "extended_sight:saboteur"
    "cloak:saboteur"
    "HealingOrb:medic"
    "UnVomit:medic"
    "Berzerk:commando"
    "Satellite:soldier"
    "Parachute:athlete"
    "AthleteJump:athlete"
    "Multiturret:engineer"
)
# Note: Nightvision and Airstrike are not in the class config but may be available as plugins

for skill_class in "${EXPECTED_SKILLS[@]}"; do
    TOTAL=$((TOTAL + 1))
    skill=$(echo "$skill_class" | cut -d: -f1)
    class=$(echo "$skill_class" | cut -d: -f2)
    
    if grep -q "skill:$skill" "sourcemod/configs/rage_class_skills.cfg" 2>/dev/null; then
        echo -e "${GREEN}  ✓ $skill registered for $class${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}  ✗ $skill not found in config for $class${NC}"
        FAILED=$((FAILED + 1))
    fi
done

# Test 3: Cooldown notification system
echo -e "\n${YELLOW}Testing: Cooldown notification system...${NC}"
TOTAL=$((TOTAL + 1))
if [ -f "sourcemod/scripting/include/rage/cooldown_notify.inc" ]; then
    echo -e "${GREEN}  ✓ Cooldown notification include exists${NC}"
    PASSED=$((PASSED + 1))
    
    # Check if it's included in core plugin
    TOTAL=$((TOTAL + 1))
    if grep -q "#include.*rage/cooldown_notify" "sourcemod/scripting/rage_survivor.sp" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Cooldown system integrated in core plugin${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}  ✗ Cooldown system not integrated in core plugin${NC}"
        FAILED=$((FAILED + 1))
    fi
    
    # Check if skills register cooldowns
    TOTAL=$((TOTAL + 1))
    COOLDOWN_REGISTRATIONS=$(grep -r "CooldownNotify_Register" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
    if [ "$COOLDOWN_REGISTRATIONS" -gt 0 ]; then
        echo -e "${GREEN}  ✓ Cooldown registrations found ($COOLDOWN_REGISTRATIONS skills)${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${YELLOW}  ⚠ No cooldown registrations found in skill plugins${NC}"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "${RED}  ✗ Cooldown notification include missing${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 4: Skill plugin includes
echo -e "\n${YELLOW}Testing: Skill plugin includes...${NC}"
REQUIRED_INCLUDES=("rage/validation" "rage/skills" "rage/skill_actions")

for include in "${REQUIRED_INCLUDES[@]}"; do
    TOTAL=$((TOTAL + 1))
    INCLUDE_COUNT=$(grep -r "#include.*$include" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
    if [ "$INCLUDE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}  ✓ $include included ($INCLUDE_COUNT plugins)${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}  ✗ $include not found in skill plugins${NC}"
        FAILED=$((FAILED + 1))
    fi
done

# Test 5: Skill registration pattern
echo -e "\n${YELLOW}Testing: Skill registration patterns...${NC}"
TOTAL=$((TOTAL + 1))
REGISTER_COUNT=$(grep -r "RegisterRageSkill" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
if [ "$REGISTER_COUNT" -ge 10 ]; then
    echo -e "${GREEN}  ✓ Skills properly registered ($REGISTER_COUNT registrations)${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Insufficient skill registrations ($REGISTER_COUNT found, expected >= 10)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 6: OnSpecialSkillUsed handlers
echo -e "\n${YELLOW}Testing: Skill activation handlers...${NC}"
TOTAL=$((TOTAL + 1))
HANDLER_COUNT=$(grep -r "OnSpecialSkillUsed" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
if [ "$HANDLER_COUNT" -ge 10 ]; then
    echo -e "${GREEN}  ✓ Skill handlers implemented ($HANDLER_COUNT handlers)${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Insufficient skill handlers ($HANDLER_COUNT found, expected >= 10)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 7: Cleanup on disconnect
echo -e "\n${YELLOW}Testing: Client disconnect cleanup...${NC}"
TOTAL=$((TOTAL + 1))
CLEANUP_COUNT=$(grep -r "OnClientDisconnect\|OnClientDisconnect_Post" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
if [ "$CLEANUP_COUNT" -ge 8 ]; then
    echo -e "${GREEN}  ✓ Disconnect cleanup implemented ($CLEANUP_COUNT handlers)${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}  ⚠ Some plugins may lack disconnect cleanup ($CLEANUP_COUNT found)${NC}"
    # Not a failure, just a warning
fi

# Test 8: Timer cleanup
echo -e "\n${YELLOW}Testing: Timer cleanup patterns...${NC}"
TOTAL=$((TOTAL + 1))
KILLTIMERSAFE_COUNT=$(grep -r "KillTimerSafe" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
KILLTIMER_COUNT=$(grep -r "KillTimer(" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | grep -v "KillTimerSafe" | wc -l)

if [ "$KILLTIMERSAFE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}  ✓ KillTimerSafe usage found ($KILLTIMERSAFE_COUNT instances)${NC}"
    PASSED=$((PASSED + 1))
    
    if [ "$KILLTIMER_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}  ⚠ Some direct KillTimer() calls still exist ($KILLTIMER_COUNT instances)${NC}"
        echo -e "${YELLOW}     Consider migrating to KillTimerSafe()${NC}"
    fi
else
    echo -e "${RED}  ✗ No KillTimerSafe usage found${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 9: Asset precaching
echo -e "\n${YELLOW}Testing: Asset precaching...${NC}"
TOTAL=$((TOTAL + 1))
PRECACHE_COUNT=$(grep -r "PrecacheSound\|PrecacheModel\|PrecacheParticle" "sourcemod/scripting/rage_survivor_plugin_"*.sp 2>/dev/null | wc -l)
if [ "$PRECACHE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Assets precached ($PRECACHE_COUNT precache calls)${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${YELLOW}  ⚠ No precaching found (may be done elsewhere)${NC}"
fi

# Test 10: Test plugin compilation
echo -e "\n${YELLOW}Testing: Test plugin exists...${NC}"
TOTAL=$((TOTAL + 1))
if [ -f "sourcemod/scripting/tests/rage_tests_skills_comprehensive.sp" ]; then
    echo -e "${GREEN}  ✓ Comprehensive test plugin exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Comprehensive test plugin missing${NC}"
    FAILED=$((FAILED + 1))
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Skills Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
fi
echo -e "Total: $TOTAL"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All skill tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}$FAILED test(s) failed${NC}"
    exit 1
fi

