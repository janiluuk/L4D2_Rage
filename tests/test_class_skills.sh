#!/bin/bash

# Test script for Rage Class Skills
# Tests deployment menus and skills for each class

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTING_DIR="$PROJECT_ROOT/sourcemod/scripting"
PLUGINS_DIR="$PROJECT_ROOT/sourcemod/plugins"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Rage Class Skills Test Runner"
echo "=========================================="
echo ""

# Check if spcomp64 is available
if ! command -v spcomp64 &> /dev/null; then
    echo -e "${RED}Error: spcomp64 not found. Please install SourceMod compiler.${NC}"
    exit 1
fi

# Compile the test plugin
echo -e "${YELLOW}Compiling test plugin...${NC}"
cd "$SCRIPTING_DIR"

TEST_PLUGIN="tests/rage_tests_class_skills.sp"
if [ ! -f "$TEST_PLUGIN" ]; then
    echo -e "${RED}Error: Test plugin not found: $TEST_PLUGIN${NC}"
    exit 1
fi

# Compile with include paths
spcomp64 -iinclude -i"$SCRIPTING_DIR/include" "$TEST_PLUGIN" -o"$PLUGINS_DIR/rage_tests_class_skills.smx"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Test plugin compiled successfully${NC}"
else
    echo -e "${RED}✗ Test plugin compilation failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test Plugin Compiled"
echo "=========================================="
echo ""
echo "To run tests in-game, use these commands:"
echo ""
echo "  sm_test_class_all          - Test all classes"
echo "  sm_test_class_soldier       - Test Soldier class"
echo "  sm_test_class_athlete       - Test Athlete class"
echo "  sm_test_class_medic         - Test Medic class"
echo "  sm_test_class_saboteur      - Test Saboteur class"
echo "  sm_test_class_commando      - Test Commando class"
echo "  sm_test_class_engineer      - Test Engineer class"
echo "  sm_test_class_brawler       - Test Brawler class"
echo ""
echo "Or via RCON:"
echo "  rcon sm_test_class_all"
echo ""
echo "Note: Tests require:"
echo "  - You to be on the survivor team"
echo "  - You to be alive"
echo "  - All skill plugins to be loaded"
echo ""

