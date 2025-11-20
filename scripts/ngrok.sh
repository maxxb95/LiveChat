#!/bin/bash

# ngrok setup script for Everchron Chat
# Exposes frontend only - Vite proxy handles backend routing

set -e

echo "Starting ngrok for Everchron Chat..."
echo "Note: Only frontend is exposed. Backend is accessible via Vite proxy."

# Create temporary ngrok config for frontend tunnel only
TMP_CONFIG=$(mktemp)
AUTHTOKEN=35gQmgsdw9i6iJUlrPmFnkOO4jo_7XYYLdfGtUyV8CzoMpyaR

cat > "$TMP_CONFIG" <<EOF
version: "2"
authtoken: $AUTHTOKEN
tunnels:
  frontend:
    addr: 5173
    proto: http
EOF

# Start ngrok with frontend tunnel
echo "Starting tunnel (frontend:5173)..."
ngrok start --config "$TMP_CONFIG" --all > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!

echo "Waiting for tunnel to initialize..."
sleep 5

# Get URL from ngrok API
echo "Getting tunnel URL..."

FRONTEND_URL=""

# Try to get URL using different methods
# Method 1: Use jq if available
if command -v jq &> /dev/null; then
    FRONTEND_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | select(.name=="frontend") | .public_url' 2>/dev/null | grep https | head -1 || echo "")
fi

# Method 2: Use python if jq not available
if [ -z "$FRONTEND_URL" ] && command -v python3 &> /dev/null; then
    FRONTEND_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for tunnel in data.get('tunnels', []):
        if 'frontend' in tunnel.get('name', '').lower() and 'https' in tunnel.get('public_url', ''):
            print(tunnel['public_url'])
            break
except:
    pass
" 2>/dev/null || echo "")
fi

# Method 3: Fallback - get first HTTPS URL
if [ -z "$FRONTEND_URL" ]; then
    FRONTEND_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -oP '"public_url":"https://[^"]*"' | cut -d'"' -f4 | head -1 || echo "")
fi

if [ -z "$FRONTEND_URL" ]; then
    echo ""
    echo "⚠️  Could not auto-detect URL. Please check manually:"
    echo "   ngrok dashboard: http://localhost:4040"
    echo ""
    echo "🛑 Press Ctrl+C to stop tunnel"
    rm -f "$TMP_CONFIG"
    wait $NGROK_PID
    exit 1
fi

echo ""
echo "✅ Tunnel ready!"
echo ""
echo "🔗 Frontend URL: $FRONTEND_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 SHARE THIS URL:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   $FRONTEND_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 The frontend automatically proxies API requests to the backend"
echo "📝 Note: On first visit, ngrok-free domains show a warning page - click 'Visit Site'"
echo ""
echo "📊 ngrok dashboard: http://localhost:4040"
echo "🛑 Press Ctrl+C to stop tunnel"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Stopping ngrok tunnels..."
    kill $NGROK_PID 2>/dev/null || true
    rm -f "$TMP_CONFIG"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Keep running
wait $NGROK_PID



