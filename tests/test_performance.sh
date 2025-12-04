#!/bin/bash
# L4D2 Rage Edition - Performance Test Script
# Tests for memory leaks and performance issues

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
echo -e "${BLUE}Performance Tests${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Test 1: Check for timer leaks (timers created but not cleaned up)
echo -e "${YELLOW}Checking for potential timer leaks...${NC}"
TIMER_LEAKS=0

# Check for CreateTimer without corresponding KillTimer in disconnect handlers
for file in sourcemod/scripting/rage*.sp; do
    if [ -f "$file" ]; then
        # Count CreateTimer calls
        create_count=$(grep -c "CreateTimer" "$file" 2>/dev/null || echo "0")
        # Count KillTimer in disconnect handlers
        kill_count=$(grep -A 50 "OnClientDisconnect" "$file" 2>/dev/null | grep -c "KillTimer" || echo "0")
        
        if [ "$create_count" -gt 0 ] && [ "$kill_count" -eq 0 ]; then
            # Check if there are any timers that should be cleaned up
            if grep -q "Handle.*Timer\|Handle.*\[MAXPLAYERS" "$file" 2>/dev/null; then
                echo -e "${YELLOW}  Warning: $file may have timer leaks (CreateTimer found but no KillTimer in disconnect)${NC}"
                TIMER_LEAKS=$((TIMER_LEAKS + 1))
            fi
        fi
    fi
done

if [ $TIMER_LEAKS -eq 0 ]; then
    echo -e "${GREEN}  ✓ No obvious timer leaks detected${NC}"
else
    echo -e "${RED}  ✗ Potential timer leaks in $TIMER_LEAKS file(s)${NC}"
fi

# Test 2: Check for entity reference leaks
echo -e "\n${YELLOW}Checking for potential entity reference leaks...${NC}"
ENTITY_LEAKS=0

for file in sourcemod/scripting/rage*.sp; do
    if [ -f "$file" ]; then
        # Check for entity arrays
        if grep -q "\[MAXPLAYERS.*\]\[.*\]" "$file" 2>/dev/null; then
            # Check if cleaned up in disconnect
            if ! grep -A 30 "OnClientDisconnect" "$file" 2>/dev/null | grep -q "= 0\|= -1\|RemoveItemAttach\|AcceptEntityInput.*kill"; then
                echo -e "${YELLOW}  Warning: $file may have entity reference leaks${NC}"
                ENTITY_LEAKS=$((ENTITY_LEAKS + 1))
            fi
        fi
    fi
done

if [ $ENTITY_LEAKS -eq 0 ]; then
    echo -e "${GREEN}  ✓ No obvious entity reference leaks detected${NC}"
else
    echo -e "${RED}  ✗ Potential entity leaks in $ENTITY_LEAKS file(s)${NC}"
fi

# Test 3: Check for OnGameFrame usage (performance concern)
echo -e "\n${YELLOW}Checking for OnGameFrame usage (performance sensitive)...${NC}"
ON_GAME_FRAME_COUNT=$(grep -r "OnGameFrame" sourcemod/scripting/rage*.sp 2>/dev/null | wc -l)

if [ "$ON_GAME_FRAME_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}  Found $ON_GAME_FRAME_COUNT OnGameFrame implementation(s)${NC}"
    echo -e "${YELLOW}  Note: OnGameFrame runs every frame - ensure it's optimized${NC}"
    
    for file in $(grep -l "OnGameFrame" sourcemod/scripting/rage*.sp 2>/dev/null); do
        # Check for frame skipping
        if grep -q "iFrameskip\|MAX_FRAMECHECK" "$file" 2>/dev/null; then
            echo -e "${GREEN}    ✓ $file uses frame skipping (good)${NC}"
        else
            echo -e "${YELLOW}    ⚠ $file may benefit from frame skipping${NC}"
        fi
    done
else
    echo -e "${GREEN}  ✓ No OnGameFrame implementations found${NC}"
fi

# Test 4: Check for large file sizes (maintenance concern)
echo -e "\n${YELLOW}Checking for large plugin files (maintenance concern)...${NC}"
LARGE_FILES=0

for file in sourcemod/scripting/rage*.sp; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        if [ "$lines" -gt 4000 ]; then
            echo -e "${YELLOW}  Warning: $file is large ($lines lines) - consider splitting${NC}"
            LARGE_FILES=$((LARGE_FILES + 1))
        fi
    fi
done

if [ $LARGE_FILES -eq 0 ]; then
    echo -e "${GREEN}  ✓ No excessively large files${NC}"
else
    echo -e "${YELLOW}  Found $LARGE_FILES large file(s) - consider refactoring${NC}"
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Performance Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"

TOTAL_ISSUES=$((TIMER_LEAKS + ENTITY_LEAKS))

if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}No critical performance issues detected${NC}"
    exit 0
else
    echo -e "${YELLOW}Found $TOTAL_ISSUES potential performance issue(s)${NC}"
    exit 1
fi

