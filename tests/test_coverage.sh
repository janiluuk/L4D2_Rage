#!/bin/bash
# L4D2 Rage Edition - Test Coverage Analysis
# Analyzes code coverage and identifies untested areas

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
echo -e "${BLUE}Test Coverage Analysis${NC}"
echo -e "${BLUE}========================================${NC}\n"

# ===================================================================
# Code Coverage Metrics
# ===================================================================

echo -e "${YELLOW}=== Code Coverage Metrics ===${NC}\n"

# Count total plugins
TOTAL_PLUGINS=$(find sourcemod/scripting -maxdepth 1 -name "rage*.sp" -type f | wc -l)
echo -e "${BLUE}Total Rage plugins: $TOTAL_PLUGINS${NC}"

# Count plugins with tests
TESTED_PLUGINS=0
for plugin in sourcemod/scripting/rage*.sp; do
    if [ -f "$plugin" ]; then
        plugin_name=$(basename "$plugin" .sp)
        # Check if plugin is referenced in tests
        if grep -q "$plugin_name\|$(basename "$plugin")" tests/*.sh 2>/dev/null; then
            TESTED_PLUGINS=$((TESTED_PLUGINS + 1))
        fi
    fi
done
echo -e "${BLUE}Plugins with test coverage: $TESTED_PLUGINS${NC}"

COVERAGE_PERCENT=$((TESTED_PLUGINS * 100 / TOTAL_PLUGINS))
if [ $COVERAGE_PERCENT -ge 80 ]; then
    echo -e "${GREEN}Coverage: ${COVERAGE_PERCENT}%${NC}"
elif [ $COVERAGE_PERCENT -ge 50 ]; then
    echo -e "${YELLOW}Coverage: ${COVERAGE_PERCENT}%${NC}"
else
    echo -e "${RED}Coverage: ${COVERAGE_PERCENT}%${NC}"
fi

# ===================================================================
# Function Coverage
# ===================================================================

echo -e "\n${YELLOW}=== Function Coverage ===${NC}\n"

# Count public functions
TOTAL_PUBLIC=$(grep -r "^public\|^Action\|^void.*public" sourcemod/scripting/rage*.sp 2>/dev/null | wc -l)
echo -e "${BLUE}Total public functions: $TOTAL_PUBLIC${NC}"

# Count functions with tests (approximate - check for function names in tests)
TESTED_FUNCTIONS=0
# This is a simplified check - in reality would need more sophisticated analysis
echo -e "${BLUE}Functions with test coverage: ~${TESTED_FUNCTIONS} (manual review needed)${NC}"

# ===================================================================
# Critical Path Coverage
# ===================================================================

echo -e "\n${YELLOW}=== Critical Path Coverage ===${NC}\n"

CRITICAL_PATHS=(
    "OnClientDisconnect cleanup"
    "Timer management"
    "Entity reference cleanup"
    "Skill activation"
    "Menu interactions"
    "Class selection"
    "Equipment pickup"
)

for path in "${CRITICAL_PATHS[@]}"; do
    # Check if path is tested
    if grep -qi "$path" tests/*.sh 2>/dev/null || grep -qi "${path// /}" tests/*.sh 2>/dev/null; then
        echo -e "${GREEN}  ✓ $path${NC}"
    else
        echo -e "${YELLOW}  ⚠ $path (needs testing)${NC}"
    fi
done

# ===================================================================
# Plugin-Specific Coverage
# ===================================================================

echo -e "\n${YELLOW}=== Plugin-Specific Coverage ===${NC}\n"

PLUGINS=(
    "rage_survivor"
    "rage_survivor_menu"
    "rage_multiple_equipment"
    "rage_survivor_plugin_grenades"
    "rage_survivor_plugin_missile"
    "rage_survivor_plugin_airstrike"
    "rage_survivor_plugin_multiturret"
    "rage_survivor_plugin_berzerk"
    "rage_survivor_plugin_deadringer"
    "rage_survivor_plugin_healingorb"
    "rage_survivor_plugin_satellite"
)

for plugin in "${PLUGINS[@]}"; do
    if [ -f "sourcemod/scripting/${plugin}.sp" ]; then
        # Check if plugin has test coverage
        if grep -q "$plugin" tests/*.sh 2>/dev/null; then
            echo -e "${GREEN}  ✓ $plugin${NC}"
        else
            echo -e "${YELLOW}  ⚠ $plugin (needs test coverage)${NC}"
        fi
    fi
done

# ===================================================================
# Missing Test Areas
# ===================================================================

echo -e "\n${YELLOW}=== Missing Test Areas ===${NC}\n"

MISSING_AREAS=()

# Check for timer cleanup tests
if ! grep -q "Timer.*cleanup\|KillTimer.*disconnect" tests/*.sh 2>/dev/null; then
    MISSING_AREAS+=("Timer cleanup on disconnect")
fi

# Check for entity cleanup tests
if ! grep -q "Entity.*cleanup\|RemoveItemAttach.*disconnect" tests/*.sh 2>/dev/null; then
    MISSING_AREAS+=("Entity cleanup on disconnect")
fi

# Check for skill interaction tests
if ! grep -q "Skill.*interaction\|skill.*combination" tests/*.sh 2>/dev/null; then
    MISSING_AREAS+=("Skill interaction tests")
fi

# Check for menu state tests
if ! grep -q "Menu.*state\|menu.*persistence" tests/*.sh 2>/dev/null; then
    MISSING_AREAS+=("Menu state persistence")
fi

# Check for error handling tests
if ! grep -q "Error.*handling\|null.*check\|validation" tests/*.sh 2>/dev/null; then
    MISSING_AREAS+=("Error handling and validation")
fi

# Check for performance tests
if [ ! -f "tests/test_performance.sh" ]; then
    MISSING_AREAS+=("Performance tests")
fi

# Check for integration tests
if [ ! -f "tests/test_integration_detailed.sh" ]; then
    MISSING_AREAS+=("Detailed integration tests")
fi

if [ ${#MISSING_AREAS[@]} -eq 0 ]; then
    echo -e "${GREEN}  All critical areas have test coverage${NC}"
else
    for area in "${MISSING_AREAS[@]}"; do
        echo -e "${YELLOW}  ⚠ $area${NC}"
    done
fi

# ===================================================================
# Recommendations
# ===================================================================

echo -e "\n${YELLOW}=== Recommendations ===${NC}\n"

echo -e "${BLUE}1. Add unit tests for individual functions${NC}"
echo -e "${BLUE}2. Add integration tests for plugin interactions${NC}"
echo -e "${BLUE}3. Add performance benchmarks${NC}"
echo -e "${BLUE}4. Add stress tests (rapid connect/disconnect)${NC}"
echo -e "${BLUE}5. Add edge case tests (null values, invalid inputs)${NC}"
echo -e "${BLUE}6. Add regression tests for fixed bugs${NC}"

echo -e "\n${BLUE}========================================${NC}"

