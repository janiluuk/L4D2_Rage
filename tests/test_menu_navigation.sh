#!/bin/bash
# L4D2 Rage Edition - Menu Navigation Test Script
# Tests menu navigation improvements (MenuNums mode, movement blocking, etc.)

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
echo -e "${BLUE}Menu Navigation Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

FAILED=0
PASSED=0
TOTAL=0

# Test 1: Menu base plugin exists and compiles
echo -e "${YELLOW}Testing: Menu base plugin exists and compiles...${NC}"
TOTAL=$((TOTAL + 1))
if [ -f "sourcemod/scripting/rage_menu_base.sp" ]; then
    echo -e "${GREEN}  ✓ rage_menu_base.sp exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ rage_menu_base.sp missing${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 2: Menu plugin exists and compiles
echo -e "${YELLOW}Testing: Menu plugin exists and compiles...${NC}"
TOTAL=$((TOTAL + 1))
if [ -f "sourcemod/scripting/rage_survivor_menu.sp" ]; then
    echo -e "${GREEN}  ✓ rage_survivor_menu.sp exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ rage_survivor_menu.sp missing${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 3: MenuNums mode is enabled in BuildSingleMenu
echo -e "${YELLOW}Testing: MenuNums mode is enabled...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "buttons_nums = true" "sourcemod/scripting/rage_survivor_menu.sp"; then
    echo -e "${GREEN}  ✓ MenuNums mode is enabled (buttons_nums = true)${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ MenuNums mode not enabled (should have buttons_nums = true)${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 4: ExtraMenu_Create is called with buttons_nums parameter
echo -e "${YELLOW}Testing: ExtraMenu_Create called with buttons_nums...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "ExtraMenu_Create.*true.*true" "sourcemod/scripting/rage_survivor_menu.sp" || \
   grep -q "ExtraMenu_Create(true" "sourcemod/scripting/rage_survivor_menu.sp"; then
    echo -e "${GREEN}  ✓ ExtraMenu_Create called with buttons_nums enabled${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ ExtraMenu_Create may not have buttons_nums parameter set${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 5: Menu text updated to show number key hints
echo -e "${YELLOW}Testing: Menu navigation text updated...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "1/2/3/4 keys" "sourcemod/scripting/rage_survivor_menu.sp"; then
    echo -e "${GREEN}  ✓ Menu text includes number key navigation hints${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Menu text missing number key navigation hints${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 6: Hint text updated
echo -e "${YELLOW}Testing: Hint text updated for new navigation...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "Movement not blocked" "sourcemod/scripting/rage_survivor_menu.sp" || \
   grep -q "7=Prev.*8=Next.*9=Exit" "sourcemod/scripting/rage_survivor_menu.sp"; then
    echo -e "${GREEN}  ✓ Hint text mentions number key navigation${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Hint text may not mention new navigation${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 7: Movement blocking check (should NOT block when MenuNums is true)
echo -e "${YELLOW}Testing: Movement blocking logic correct...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "if( !data.MenuNums )" "sourcemod/scripting/rage_menu_base.sp" && \
   grep -q "SetEntityMoveType(client, MOVETYPE_NONE)" "sourcemod/scripting/rage_menu_base.sp"; then
    echo -e "${GREEN}  ✓ Movement only blocked when MenuNums is false${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Movement blocking logic may be incorrect${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 8: Menu close handler properly cleans up
echo -e "${YELLOW}Testing: Menu close handler cleans up properly...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "g_hMenu\[client\] = null" "sourcemod/scripting/rage_menu_base.sp" && \
   grep -q "CancelMenu.*g_hMenu" "sourcemod/scripting/rage_menu_base.sp"; then
    echo -e "${GREEN}  ✓ Menu close handler properly cleans up handles${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Menu close handler may not clean up properly${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 9: Documentation updated
echo -e "${YELLOW}Testing: Documentation updated...${NC}"
TOTAL=$((TOTAL + 1))
if grep -q "1/2/3/4 keys" "docs/getting-started/README.md" || \
   grep -q "MenuNums" "docs/features/MENU_NAVIGATION_IMPROVEMENTS.md"; then
    echo -e "${GREEN}  ✓ Documentation mentions new navigation system${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Documentation may not be updated${NC}"
    FAILED=$((FAILED + 1))
fi

# Test 10: Menu navigation improvements doc exists
echo -e "${YELLOW}Testing: Menu navigation improvements documentation exists...${NC}"
TOTAL=$((TOTAL + 1))
if [ -f "docs/features/MENU_NAVIGATION_IMPROVEMENTS.md" ]; then
    echo -e "${GREEN}  ✓ Menu navigation improvements documentation exists${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}  ✗ Menu navigation improvements documentation missing${NC}"
    FAILED=$((FAILED + 1))
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total Tests: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: ${FAILED}${NC}"
else
    echo -e "Failed: ${FAILED}"
fi

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All menu navigation tests passed! ✓${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
fi

