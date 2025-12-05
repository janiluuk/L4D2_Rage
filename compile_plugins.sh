#!/bin/bash

# L4D2 Rage Edition - Plugin Compilation Script
# Automatically compiles all SourceMod plugins in sourcemod/scripting/

# Don't use set -e here - we want to continue compiling even if one plugin fails

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Paths
SCRIPTING_DIR="sourcemod/scripting"
PLUGINS_DIR="sourcemod/plugins"
INCLUDE_DIR="$SCRIPTING_DIR/include"

# Check if directories exist
if [ ! -d "$SCRIPTING_DIR" ]; then
    echo -e "${RED}Error: $SCRIPTING_DIR directory not found!${NC}"
    exit 1
fi

# Create plugins directory if it doesn't exist
mkdir -p "$PLUGINS_DIR"

# Find the compiler (prefer spcomp64, fall back to spcomp)
SPCOMP=""
if [ -f "$SCRIPTING_DIR/spcomp64" ] && [ -x "$SCRIPTING_DIR/spcomp64" ]; then
    SPCOMP="$SCRIPTING_DIR/spcomp64"
    echo -e "${BLUE}Using: spcomp64${NC}"
elif [ -f "$SCRIPTING_DIR/spcomp" ] && [ -x "$SCRIPTING_DIR/spcomp" ]; then
    SPCOMP="$SCRIPTING_DIR/spcomp"
    echo -e "${BLUE}Using: spcomp${NC}"
elif command -v spcomp64 &> /dev/null; then
    SPCOMP="spcomp64"
    echo -e "${BLUE}Using: system spcomp64${NC}"
elif command -v spcomp &> /dev/null; then
    SPCOMP="spcomp"
    echo -e "${BLUE}Using: system spcomp${NC}"
else
    echo -e "${RED}Error: No SourceMod compiler found!${NC}"
    echo -e "${YELLOW}Please ensure spcomp or spcomp64 is available in:${NC}"
    echo -e "  - $SCRIPTING_DIR/spcomp64"
    echo -e "  - $SCRIPTING_DIR/spcomp"
    echo -e "  - Or in your system PATH"
    exit 1
fi

# Build include paths
INCLUDES="-i $SCRIPTING_DIR/include"

# Check if SourceMod includes exist (optional, for better error messages)
if [ -d "$SCRIPTING_DIR/include" ]; then
    echo -e "${GREEN}Found include directory: $INCLUDE_DIR${NC}"
else
    echo -e "${YELLOW}Warning: Include directory not found at $INCLUDE_DIR${NC}"
fi

# Find all .sp files (main directory, gamemodes, and plugins subdirectories)
echo -e "\n${BLUE}Searching for plugin files...${NC}"
SP_FILES=($(find "$SCRIPTING_DIR" -maxdepth 1 -name "rage*.sp" -type f | sort))
GAMEMODE_FILES=($(find "$SCRIPTING_DIR/gamemodes" -maxdepth 1 -name "rage*.sp" -type f 2>/dev/null | sort))
PLUGIN_FILES=($(find "$SCRIPTING_DIR/plugins" -maxdepth 1 -name "rage*.sp" -type f 2>/dev/null | sort))
SP_FILES+=("${GAMEMODE_FILES[@]}")
SP_FILES+=("${PLUGIN_FILES[@]}")

if [ ${#SP_FILES[@]} -eq 0 ]; then
    echo -e "${RED}Error: No .sp files found in $SCRIPTING_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${#SP_FILES[@]} plugin file(s) to compile${NC}\n"

# Compilation statistics
SUCCESS=0
FAILED=0
FAILED_FILES=()

# Compile each plugin
for sp_file in "${SP_FILES[@]}"; do
    plugin_name=$(basename "$sp_file" .sp)
    output_file="$PLUGINS_DIR/$plugin_name.smx"
    
    echo -e "${BLUE}Compiling: ${NC}$plugin_name.sp"
    
    # Compile the plugin (capture output and exit code)
    if "$SPCOMP" $INCLUDES "$sp_file" -o "$output_file" &>/dev/null; then
        echo -e "${GREEN}  ✓ Success: $plugin_name.smx${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        EXIT_CODE=$?
        echo -e "${RED}  ✗ Failed: $plugin_name.sp (exit code: $EXIT_CODE)${NC}"
        FAILED=$((FAILED + 1))
        FAILED_FILES+=("$plugin_name.sp")
	"$SPCOMP" $INCLUDES "$sp_file" -o "$output_file"
    fi
    echo ""
done

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Compilation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Successful: $SUCCESS${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
    echo -e "\n${YELLOW}Failed files:${NC}"
    for file in "${FAILED_FILES[@]}"; do
        echo -e "  ${RED}✗${NC} $file"
    done
    COMPILE_EXIT=1
else
    echo -e "${GREEN}All plugins compiled successfully!${NC}"
    echo -e "\n${GREEN}Output directory: $PLUGINS_DIR${NC}"
    COMPILE_EXIT=0
fi

# Run tests if requested or if TEST environment variable is set
if [ "${RUN_TESTS:-1}" = "1" ] && [ -f "$ROOT_DIR/tests/run_tests.sh" ]; then
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Running Tests${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    if "$ROOT_DIR/tests/run_tests.sh"; then
        TEST_EXIT=0
    else
        TEST_EXIT=1
    fi
    
    # Run performance tests
    if [ -f "$ROOT_DIR/tests/test_performance.sh" ]; then
        echo ""
        "$ROOT_DIR/tests/test_performance.sh"
        PERF_EXIT=$?
    else
        PERF_EXIT=0
    fi
    
    # Run integration tests
    if [ -f "$ROOT_DIR/tests/test_integration.sh" ]; then
        echo ""
        "$ROOT_DIR/tests/test_integration.sh"
        INT_EXIT=$?
    else
        INT_EXIT=0
    fi
    
    # Run detailed integration tests
    if [ -f "$ROOT_DIR/tests/test_integration_detailed.sh" ]; then
        echo ""
        "$ROOT_DIR/tests/test_integration_detailed.sh"
        INT_DETAILED_EXIT=$?
    else
        INT_DETAILED_EXIT=0
    fi
    
    # Run coverage analysis
    if [ -f "$ROOT_DIR/tests/test_coverage.sh" ]; then
        echo ""
        "$ROOT_DIR/tests/test_coverage.sh"
        COV_EXIT=$?
    else
        COV_EXIT=0
    fi
    
    # Exit with error if any tests failed
    if [ $TEST_EXIT -ne 0 ] || [ $PERF_EXIT -ne 0 ] || [ $INT_EXIT -ne 0 ] || [ $INT_DETAILED_EXIT -ne 0 ]; then
        exit 1
    fi
fi

# Exit with compilation status
exit $COMPILE_EXIT

