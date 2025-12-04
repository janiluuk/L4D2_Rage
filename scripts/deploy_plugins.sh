
#!/bin/bash

# L4D2 Rage Edition - Plugin Deployment Script
# Deploys plugins and reloads them via RCON

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

# Load environment variables from .env file if it exists
if [ -f "$ROOT_DIR/.env" ]; then
    # Export variables from .env file (ignore comments and empty lines)
    set -a
    source "$ROOT_DIR/.env"
    set +a
fi

# RCON settings (with defaults if not in .env)
RCON_HOST="${RCON_HOST:-vifi.ee}"
RCON_PORT="${RCON_PORT:-27022}"
RCON_PASSWORD="${RCON_PASSWORD:-}"

# Validate required variables
if [ -z "$RCON_PASSWORD" ]; then
    echo -e "${RED}Error: RCON_PASSWORD not set${NC}"
    echo -e "${YELLOW}Please set RCON_PASSWORD in .env file or environment variable${NC}"
    echo -e "${YELLOW}Example .env file:${NC}"
    echo -e "  RCON_HOST=vifi.ee"
    echo -e "  RCON_PORT=27022"
    echo -e "  RCON_PASSWORD=your_password_here"
    exit 1
fi

# Paths (relative to root directory)
PLUGINS_DIR="sourcemod/plugins"

# Check if plugins directory exists
if [ ! -d "$PLUGINS_DIR" ]; then
    echo -e "${RED}Error: $PLUGINS_DIR directory not found!${NC}"
    exit 1
fi

# Function to send RCON command
send_rcon() {
    local command="$1"
    local output=""

    output=$(scp ./sourcemod/plugins/*  "$RCON_HOST":/root/l4d2-docker/l4d2/addons/sourcemod/plugins/)
    echo "$output"
    # Try different RCON tools in order of preference
    if command -v rcon-cli &> /dev/null; then
        output=$(rcon-cli -a "${RCON_HOST}:${RCON_PORT}" -p "$RCON_PASSWORD" "$command" 2>&1)
        echo "$output"
        return $?
    elif command -v rcon &> /dev/null; then
        output=$(rcon -a "${RCON_HOST}:${RCON_PORT}" -p "$RCON_PASSWORD" "$command" 2>&1)
        echo "$output"
        return $?
    elif [ -f "$ROOT_DIR/scripts/rcon_helper.py" ]; then
        output=$(python3 "$ROOT_DIR/scripts/rcon_helper.py" "$RCON_HOST" "$RCON_PORT" "$RCON_PASSWORD" "$command" 2>&1)
        echo "$output"
        return $?
    else
        echo -e "${RED}Error: No RCON tool available.${NC}"
        echo -e "${YELLOW}Please install one of:${NC}"
        echo -e "  - rcon-cli (npm install -g rcon-cli)"
        echo -e "  - rcon (various packages)"
        echo -e "  - Or ensure Python 3 is available for rcon_helper.py"
        return 1
    fi
}

# Deploy plugins (copy to server if needed)
echo -e "${BLUE}Deploying plugins...${NC}"
if [ -n "$1" ] && [ "$1" != "local" ]; then
    # Remote deployment
    echo -e "${BLUE}Copying plugins to remote server...${NC}"
    scp ./sourcemod/plugins/* "$1":/root/l4d2-docker/l4d2/addons/sourcemod/plugins
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to copy plugins${NC}"
        exit 1
    fi
    echo -e "${GREEN}Plugins copied successfully${NC}"
fi

# Connect via RCON and refresh plugins
echo -e "\n${BLUE}Connecting to RCON server (${RCON_HOST}:${RCON_PORT})...${NC}"

# Test basic connectivity first
echo -e "${BLUE}Testing server connectivity...${NC}"
if command -v nc &> /dev/null; then
    if ! nc -z -w 3 "$RCON_HOST" "$RCON_PORT" 2>/dev/null; then
        echo -e "${RED}Error: Cannot reach ${RCON_HOST}:${RCON_PORT}${NC}"
        echo -e "${YELLOW}Network connectivity test failed. Check:${NC}"
        echo -e "  - Server is running"
        echo -e "  - Port ${RCON_PORT} is open and accessible"
        echo -e "  - Firewall allows connections to ${RCON_HOST}:${RCON_PORT}"
        exit 1
    fi
    echo -e "${GREEN}Server is reachable${NC}"
elif command -v timeout &> /dev/null && command -v bash &> /dev/null; then
    # Fallback: try to connect with timeout
    if ! timeout 3 bash -c "echo > /dev/tcp/$RCON_HOST/$RCON_PORT" 2>/dev/null; then
        echo -e "${YELLOW}Warning: Cannot verify connectivity (nc not available)${NC}"
    fi
else
    echo -e "${YELLOW}Warning: Cannot verify connectivity (nc/timeout not available)${NC}"
fi

# Test RCON connection
echo -e "${BLUE}Testing RCON authentication...${NC}"
TEST_OUTPUT=$(send_rcon "echo RCON_TEST" 2>&1)
TEST_EXIT=$?

# Check for actual RCON errors (not server log messages)
# RCON errors would be things like "Error:", "timeout", "failed" in stderr from the helper
# Server log messages are normal and don't indicate RCON failure
if [ $TEST_EXIT -ne 0 ]; then
    # Check if the error is from our RCON helper (starts with "Error:")
    if echo "$TEST_OUTPUT" | grep -q "^Error:"; then
        echo -e "${RED}Error: Could not authenticate with RCON server at ${RCON_HOST}:${RCON_PORT}${NC}"
        echo -e "${YELLOW}Error details: $TEST_OUTPUT${NC}"
        echo -e "${YELLOW}Make sure:${NC}"
        echo -e "  - Server is running"
        echo -e "  - RCON is enabled (set rcon_password in server.cfg or command line)"
        echo -e "  - Port ${RCON_PORT} is accessible"
        echo -e "  - Password is correct (current: ${RCON_PASSWORD:0:3}***)"
        exit 1
    fi
fi

# If we got here, RCON is working (server logs are normal)
echo -e "${GREEN}RCON authentication successful${NC}\n"

# Refresh plugin list
echo -e "${BLUE}Refreshing plugin list...${NC}"
REFRESH_OUTPUT=$(send_rcon "sm plugins refresh" 2>&1)
REFRESH_EXIT=$?
if [ $REFRESH_EXIT -eq 0 ]; then
    if echo "$REFRESH_OUTPUT" | grep -qi "error\|timeout\|failed"; then
        echo -e "${YELLOW}Warning: Refresh may have failed${NC}"
        echo -e "${YELLOW}Output: $REFRESH_OUTPUT${NC}"
    else
        echo -e "${GREEN}Plugin list refreshed${NC}"
    fi
else
    echo -e "${YELLOW}Warning: Plugin refresh command failed (exit code: $REFRESH_EXIT)${NC}"
    if [ -n "$REFRESH_OUTPUT" ]; then
        echo -e "${YELLOW}Output: $REFRESH_OUTPUT${NC}"
    fi
fi

# Wait a moment for refresh to complete
sleep 2

# Get plugin list and check for failures
echo -e "\n${BLUE}Checking plugin status...${NC}"
PLUGIN_LIST=$(send_rcon "sm plugins list" 2>&1)
PLUGIN_LIST_EXIT=$?

if [ $PLUGIN_LIST_EXIT -ne 0 ]; then
    echo -e "${RED}Error: Could not retrieve plugin list (exit code: $PLUGIN_LIST_EXIT)${NC}"
    if [ -n "$PLUGIN_LIST" ]; then
        echo -e "${YELLOW}Error output: $PLUGIN_LIST${NC}"
    fi
    echo -e "${YELLOW}This might indicate an RCON connection issue.${NC}"
    exit 1
fi

# Check if we got a valid plugin list (should contain "[SM] Listing" or plugin numbers)
if [ -z "$PLUGIN_LIST" ]; then
    echo -e "${RED}Error: Empty plugin list response${NC}"
    exit 1
fi

# Check for actual RCON errors (not server log messages)
if echo "$PLUGIN_LIST" | grep -qi "^Error:"; then
    echo -e "${RED}Error: RCON error when retrieving plugin list${NC}"
    echo -e "${YELLOW}Error: $PLUGIN_LIST${NC}"
    exit 1
fi

# Valid plugin list should contain "[SM] Listing" or plugin entries
if ! echo "$PLUGIN_LIST" | grep -qi "\[SM\] Listing\|^[0-9]"; then
    echo -e "${YELLOW}Warning: Plugin list may be incomplete or in unexpected format${NC}"
fi

# Parse plugin list for failures
FAILED_PLUGINS=()
while IFS= read -r line; do
    # Look for lines indicating plugin failures
    # SourceMod plugin list format: "[NN] <status> <name>.smx"
    if echo "$line" | grep -qiE "(failed|error|unload|disabled|bad load)" && echo "$line" | grep -qiE "\.smx"; then
        # Extract plugin name from line
        plugin_name=$(echo "$line" | grep -oE "[a-zA-Z0-9_]+\.smx" | head -1)
        if [ -n "$plugin_name" ]; then
            FAILED_PLUGINS+=("$plugin_name")
        fi
    fi
done <<< "$PLUGIN_LIST"

# Display plugin list (formatted)
echo -e "\n${BLUE}Plugin Status:${NC}"
if [ -n "$PLUGIN_LIST" ]; then
    echo "$PLUGIN_LIST" | while IFS= read -r line; do
        if echo "$line" | grep -qiE "(failed|error|unload|disabled|bad load)"; then
            echo -e "${RED}$line${NC}"
        elif echo "$line" | grep -qiE "\.smx"; then
            echo -e "${GREEN}$line${NC}"
        else
            echo "$line"
        fi
    done
else
    echo -e "${YELLOW}Could not retrieve plugin list${NC}"
fi

# Report failures
echo -e "\n${BLUE}========================================${NC}"
if [ ${#FAILED_PLUGINS[@]} -eq 0 ]; then
    echo -e "${GREEN}All plugins loaded successfully!${NC}"
else
    echo -e "${RED}Failed plugins detected:${NC}"
    for plugin in "${FAILED_PLUGINS[@]}"; do
        echo -e "  ${RED}✗${NC} $plugin"
    done
    echo -e "\n${YELLOW}Check server logs for details${NC}"
    exit 1
fi
echo -e "${BLUE}========================================${NC}"
