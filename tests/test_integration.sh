#!/bin/bash
# L4D2 Rage Edition - Integration Test Script
# Tests integration between plugins and systems

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
echo -e "${BLUE}Integration Tests${NC}"
echo -e "${BLUE}========================================${NC}\n"

FAILED=0

# Test 1: All classes have at least 2 skills
echo -e "${YELLOW}Testing: All classes have skills...${NC}"
CLASSES=("soldier" "athlete" "medic" "saboteur" "commando" "engineer" "brawler")

for class in "${CLASSES[@]}"; do
    skill_count=$(grep -A 10 "\"$class\"" sourcemod/configs/rage_class_skills.cfg 2>/dev/null | grep -c "skill:\|command:" 2>/dev/null | tr -d '[:space:]' || echo "0")
    
    # Ensure we have a valid integer
    skill_count=$((skill_count + 0))
    
    if [ "$class" = "brawler" ]; then
        # Brawler intentionally has no skills
        if [ "$skill_count" -eq 0 ]; then
            echo -e "${GREEN}  ✓ $class: No skills (as intended)${NC}"
        else
            echo -e "${RED}  ✗ $class: Has skills but should have none${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        if [ "$skill_count" -ge 2 ]; then
            echo -e "${GREEN}  ✓ $class: $skill_count skills${NC}"
        else
            echo -e "${RED}  ✗ $class: Only $skill_count skill(s) (expected at least 2)${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi
done

# Test 2: Skill registration system
echo -e "\n${YELLOW}Testing: Skill registration system...${NC}"
if grep -q "RegisterRageSkill\|OnSpecialSkillUsed" sourcemod/scripting/rage_survivor.sp; then
    echo -e "${GREEN}  ✓ Skill registration system found${NC}"
else
    echo -e "${RED}  ✗ Skill registration system not found${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 3: Menu system integration
echo -e "\n${YELLOW}Testing: Menu system integration...${NC}"
if grep -q "rage_menu_base\|ExtraMenu" sourcemod/scripting/rage_survivor_menu.sp; then
    echo -e "${GREEN}  ✓ Menu system integrated${NC}"
else
    echo -e "${RED}  ✗ Menu system not integrated${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 4: Admin menu integration
echo -e "\n${YELLOW}Testing: Admin menu integration...${NC}"
if grep -q "Menu_AdminMenu\|sm_adm" sourcemod/scripting/rage_survivor_menu.sp; then
    echo -e "${GREEN}  ✓ Admin menu integrated${NC}"
else
    echo -e "${RED}  ✗ Admin menu not integrated${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 5: Multiple Equipment integration
echo -e "\n${YELLOW}Testing: Multiple Equipment integration...${NC}"
if grep -q "MultiEquip\|rage_multiequip" sourcemod/scripting/rage_survivor_menu.sp; then
    echo -e "${GREEN}  ✓ Multiple Equipment integrated${NC}"
else
    echo -e "${RED}  ✗ Multiple Equipment not integrated${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 6: Cookie system for preferences
echo -e "\n${YELLOW}Testing: Preference persistence (cookies)...${NC}"
COOKIE_COUNT=$(grep -r "RegClientCookie\|SetClientCookie\|GetClientCookie" sourcemod/scripting/rage*.sp 2>/dev/null | wc -l)
if [ "$COOKIE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Cookie system in use ($COOKIE_COUNT references)${NC}"
else
    echo -e "${YELLOW}  ⚠ Cookie system not found${NC}"
fi

# Test 7: Validation functions usage
echo -e "\n${YELLOW}Testing: Validation functions usage...${NC}"
VALIDATION_INCLUDES=$(grep -r "#include.*rage/validation" sourcemod/scripting/rage*.sp 2>/dev/null | wc -l)
if [ "$VALIDATION_INCLUDES" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Validation functions included ($VALIDATION_INCLUDES plugins)${NC}"
else
    echo -e "${YELLOW}  ⚠ Validation functions not widely used${NC}"
fi

# Test 8: Effects system usage
echo -e "\n${YELLOW}Testing: Effects system usage...${NC}"
EFFECTS_INCLUDES=$(grep -r "#include.*rage/effects" sourcemod/scripting/rage*.sp 2>/dev/null | wc -l)
if [ "$EFFECTS_INCLUDES" -gt 0 ]; then
    echo -e "${GREEN}  ✓ Effects system included ($EFFECTS_INCLUDES plugins)${NC}"
else
    echo -e "${YELLOW}  ⚠ Effects system not widely used${NC}"
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Integration Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All integration tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILED integration test(s) failed${NC}"
    exit 1
fi

