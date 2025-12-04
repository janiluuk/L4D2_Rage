#!/bin/bash
# RCON Connection Diagnostic Script

RCON_HOST="${1:-vifi.ee}"
RCON_PORT="${2:-27022}"
RCON_PASSWORD="${3:-annikkikyllikki}"

echo "=== RCON Connection Diagnostics ==="
echo "Host: $RCON_HOST"
echo "Port: $RCON_PORT"
echo "Password: ${RCON_PASSWORD:0:3}***"
echo ""

# Test 1: Basic network connectivity
echo "[1/5] Testing network connectivity..."
if command -v nc &> /dev/null; then
    if nc -z -w 3 "$RCON_HOST" "$RCON_PORT" 2>/dev/null; then
        echo "✓ Port $RCON_PORT is open and reachable"
    else
        echo "✗ Cannot reach $RCON_HOST:$RCON_PORT"
        echo "  - Check if server is running"
        echo "  - Check firewall rules"
        echo "  - Verify port number"
        exit 1
    fi
elif command -v timeout &> /dev/null && command -v bash &> /dev/null; then
    if timeout 3 bash -c "echo > /dev/tcp/$RCON_HOST/$RCON_PORT" 2>/dev/null; then
        echo "✓ Port $RCON_PORT is open and reachable"
    else
        echo "✗ Cannot reach $RCON_HOST:$RCON_PORT"
        exit 1
    fi
else
    echo "⚠ Cannot test connectivity (nc/timeout not available)"
fi

# Test 2: DNS resolution
echo ""
echo "[2/5] Testing DNS resolution..."
if host "$RCON_HOST" &>/dev/null || getent hosts "$RCON_HOST" &>/dev/null; then
    echo "✓ DNS resolution successful"
else
    echo "✗ DNS resolution failed"
    exit 1
fi

# Test 3: Python availability
echo ""
echo "[3/5] Testing Python availability..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "✓ Python found: $PYTHON_VERSION"
else
    echo "✗ Python 3 not found"
    exit 1
fi

# Test 4: RCON helper script
echo ""
echo "[4/5] Testing RCON helper script..."
if [ -f "./rcon_helper.py" ]; then
    echo "✓ rcon_helper.py found"
    if python3 -c "import socket, struct, sys" 2>/dev/null; then
        echo "✓ Required Python modules available"
    else
        echo "✗ Missing required Python modules"
        exit 1
    fi
else
    echo "✗ rcon_helper.py not found"
    exit 1
fi

# Test 5: Actual RCON connection
echo ""
echo "[5/5] Testing RCON authentication..."
OUTPUT=$(python3 ./rcon_helper.py "$RCON_HOST" "$RCON_PORT" "$RCON_PASSWORD" "echo RCON_TEST" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ] && ! echo "$OUTPUT" | grep -qi "error\|timeout\|failed"; then
    echo "✓ RCON authentication successful"
    echo "  Response: $OUTPUT"
    echo ""
    echo "=== All tests passed! ==="
    exit 0
else
    echo "✗ RCON authentication failed"
    echo "  Error: $OUTPUT"
    echo ""
    echo "=== Troubleshooting ==="
    echo "Common issues:"
    echo "  1. RCON not enabled on server"
    echo "     → Add 'rcon_password $RCON_PASSWORD' to server.cfg"
    echo "     → Or start server with: +rcon_password $RCON_PASSWORD"
    echo ""
    echo "  2. Wrong password"
    echo "     → Verify password matches server configuration"
    echo ""
    echo "  3. Server not running"
    echo "     → Check if server process is active"
    echo ""
    echo "  4. Port blocked"
    echo "     → Check firewall rules"
    echo "     → Verify port $RCON_PORT is open"
    exit 1
fi

