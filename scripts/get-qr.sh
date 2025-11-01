#!/usr/bin/env bash

# Neon Invaders QR Code Generator
# Generates QR code for mobile testing

echo "🚀 Neon Invaders Mobile QR Code Generator"
echo "=========================================="

# Get local IP address
IP=$(ip route get 1.1.1.1 | awk '{print $7}' | head -1)
if [ -z "$IP" ]; then
    IP="192.168.0.14"  # Fallback IP
fi

URL="http://$IP:8000"
echo "📱 Mobile URL: $URL"
echo ""

# Check if qrencode is installed
if command -v qrencode &> /dev/null; then
    echo "📲 QR Code (scan with phone camera):"
    echo ""
    # Generate QR code in terminal
    qrencode -t ANSI "$URL"
    echo ""
else
    echo "⚠️  qrencode not found. Install with:"
    echo "   Ubuntu/Debian: sudo apt install qrencode"
    echo "   macOS: brew install qrencode"
    echo ""
    echo "🌐 Or open this URL in your browser:"
    echo "   https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$(echo "$URL" | sed 's/+/%2B/g; s/\//%2F/g; s/:/%3A/g')"
    echo ""
fi

echo "💡 Instructions:"
echo "   1. Make sure phone and computer are on same WiFi"
echo "   2. Scan QR code or open URL manually"
echo "   3. Test mobile touch controls!"
echo ""

# Start HTTP server if not running
if ! pgrep -f "python.*http.server" > /dev/null; then
    echo "🌐 Starting HTTP server on port 8000..."
    cd "$(dirname "$0")/.."
    python3 -m http.server 8000 > /dev/null 2>&1 &
    SERVER_PID=$!
    echo "✅ Server started (PID: $SERVER_PID)"
    echo "🛑 Stop server with: kill $SERVER_PID"
else
    echo "✅ HTTP server already running"
fi

echo ""
echo "🎮 Game URL: $URL"