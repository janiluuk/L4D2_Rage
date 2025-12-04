#!/bin/bash
# L4D2 Rage Edition - Bug Detection Tests
# Detects common SourceMod plugin bugs

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
echo -e "${BLUE}Bug Detection Tests${NC}"
echo -e "${BLUE}========================================${NC}\n"

ISSUES_FOUND=0
WARNINGS=0

# Function to report an issue
report_issue() {
    local severity="$1"
    local plugin="$2"
    local issue="$3"
    
    if [ "$severity" = "ERROR" ]; then
        echo -e "${RED}  ✗ ERROR: $plugin - $issue${NC}"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    else
        echo -e "${YELLOW}  ⚠ WARNING: $plugin - $issue${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# ===================================================================
# Timer Leak Detection
# ===================================================================

echo -e "${YELLOW}=== Timer Leak Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for timer arrays
    if grep -q "Handle.*\[MAXPLAYERS\|Handle.*Timer.*\[" "$plugin"; then
        # Check if OnClientDisconnect cleans them up
        if grep -q "OnClientDisconnect\|OnClientDisconnect_Post" "$plugin"; then
            # Check if KillTimer is called in disconnect handler
            if ! grep -A 30 "OnClientDisconnect" "$plugin" | grep -q "KillTimer"; then
                # Check if it's a repeating timer that doesn't need cleanup
                if ! grep -q "TIMER_REPEAT" "$plugin"; then
                    report_issue "WARNING" "$plugin_name" "Timer array may not be cleaned up on disconnect"
                fi
            fi
        else
            report_issue "WARNING" "$plugin_name" "Has timer arrays but no OnClientDisconnect handler"
        fi
    fi
done

# ===================================================================
# Entity Reference Leak Detection
# ===================================================================

echo -e "\n${YELLOW}=== Entity Reference Leak Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for entity arrays
    if grep -q "\[MAXPLAYERS.*\]\[.*\]\|\[2048" "$plugin"; then
        # Check if OnClientDisconnect cleans them up
        if grep -q "OnClientDisconnect\|OnClientDisconnect_Post" "$plugin"; then
            # Check if arrays are reset in disconnect handler
            if ! grep -A 30 "OnClientDisconnect" "$plugin" | grep -qE "= 0\|= -1\|= INVALID\|RemoveItemAttach\|AcceptEntityInput.*kill"; then
                report_issue "WARNING" "$plugin_name" "Entity array may not be cleaned up on disconnect"
            fi
        else
            report_issue "WARNING" "$plugin_name" "Has entity arrays but no OnClientDisconnect handler"
        fi
    fi
done

# ===================================================================
# Null Pointer Detection
# ===================================================================

echo -e "\n${YELLOW}=== Null Pointer Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for array access without bounds checking
    if grep -qE "\[client\]|\[entity\]" "$plugin"; then
        # Check if validation is done before access
        if ! grep -qE "IsValidClient|IsValidEntity|IsValidSurvivor|client > 0|client <= MaxClients" "$plugin"; then
            # This is a warning, not an error, as validation might be in called functions
            if [ "$plugin_name" != "rage_survivor" ]; then
                report_issue "WARNING" "$plugin_name" "May access arrays without explicit validation (check manually)"
            fi
        fi
    fi
done

# ===================================================================
# Handle Leak Detection
# ===================================================================

echo -e "\n${YELLOW}=== Handle Leak Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for Handle creation
    if grep -q "CreateTimer\|CreateConVar\|CreateArray\|CreateTrie" "$plugin"; then
        # Check if OnPluginEnd or OnMapEnd cleans them up
        if ! grep -q "OnPluginEnd\|OnMapEnd" "$plugin"; then
            # Check if handles are stored in arrays (client-specific, auto-cleaned)
            if ! grep -q "Handle.*\[MAXPLAYERS" "$plugin"; then
                report_issue "WARNING" "$plugin_name" "Creates handles but may not clean them up (check OnPluginEnd)"
            fi
        fi
    fi
done

# ===================================================================
# Array Bounds Detection
# ===================================================================

echo -e "\n${YELLOW}=== Array Bounds Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for potential array out-of-bounds
    if grep -qE "\[2048\+1\]|\[MAXPLAYERS\+1\]" "$plugin"; then
        # Check if loops properly bound
        if grep -qE "for.*i.*<=.*2048|for.*i.*<=.*MaxClients" "$plugin"; then
            if ! grep -qE "i < 2048|i <= 2048|i < MaxClients|i <= MaxClients" "$plugin"; then
                report_issue "WARNING" "$plugin_name" "Loop may exceed array bounds (check manually)"
            fi
        fi
    fi
done

# ===================================================================
# Memory Leak Detection (StringMap, ArrayList)
# ===================================================================

echo -e "\n${YELLOW}=== Memory Leak Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for StringMap/ArrayList creation
    if grep -q "new StringMap\|new ArrayList\|CreateArray\|CreateTrie" "$plugin"; then
        # Check if they're cleaned up
        if ! grep -q "delete\|CloseHandle" "$plugin"; then
            report_issue "WARNING" "$plugin_name" "Creates StringMap/ArrayList but may not delete them"
        fi
    fi
done

# ===================================================================
# SDKHook Leak Detection
# ===================================================================

echo -e "\n${YELLOW}=== SDKHook Leak Detection ===${NC}\n"

for plugin in sourcemod/scripting/rage*.sp; do
    if [ ! -f "$plugin" ]; then
        continue
    fi
    
    plugin_name=$(basename "$plugin" .sp)
    
    # Check for SDKHook usage
    if grep -q "SDKHook" "$plugin"; then
        # Check if SDKUnhook is called
        if ! grep -q "SDKUnhook" "$plugin"; then
            report_issue "WARNING" "$plugin_name" "Uses SDKHook but may not unhook (check OnClientDisconnect)"
        fi
    fi
done

# ===================================================================
# Summary
# ===================================================================

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Bug Detection Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${RED}Errors Found: $ISSUES_FOUND${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${BLUE}Total Issues: $((ISSUES_FOUND + WARNINGS))${NC}\n"

if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}No issues detected!${NC}"
    exit 0
elif [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${YELLOW}Only warnings found - review recommended${NC}"
    exit 0
else
    echo -e "${RED}Errors found - review required${NC}"
    exit 1
fi

