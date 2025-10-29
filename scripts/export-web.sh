#!/bin/bash

# Web export script for Neon Invaders
# Exports the game to a web-compatible format using LÖVE's web export

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default output directory
OUTPUT_DIR="web-build"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [-o|--output DIRECTORY]"
      echo "Export Neon Invaders to web format"
      echo ""
      echo "Options:"
      echo "  -o, --output DIR    Output directory (default: web-build)"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${YELLOW}Exporting Neon Invaders to web format...${NC}"

# Check if LÖVE is available
if ! command -v love &> /dev/null; then
    echo -e "${RED}Error: LÖVE 11.5 is not installed or not in PATH${NC}"
    echo "Please install LÖVE from https://love2d.org/"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Export the game
echo "Exporting to $OUTPUT_DIR..."
love . --fused --export-type=web --output="$OUTPUT_DIR"

# Check if export was successful
if [ ! -f "$OUTPUT_DIR/index.html" ]; then
    echo -e "${RED}Error: Export failed - index.html not found${NC}"
    exit 1
fi

# Create a simple README for the web build
cat > "$OUTPUT_DIR/README.md" << EOF
# Neon Invaders - Web Build

This is the web export of Neon Invaders.

## How to Run

1. Serve this directory with a web server:
   - Python 3: \`python -m http.server 8000\`
   - Node.js: \`npx serve\`
   - Or use any static file server

2. Open your browser and navigate to:
   \`http://localhost:8000\`

## Controls

- **Arrow Keys** or **WASD**: Move ship
- **Space**: Fire bullets
- **P**: Pause game
- **Escape**: Return to menu

## Notes

- Works best in modern browsers (Chrome, Firefox, Safari, Edge)
- Touch controls are supported on mobile devices
- Game data is saved in browser's local storage

Generated on: $(date)
EOF

echo -e "${GREEN}✓ Export completed successfully!${NC}"
echo ""
echo -e "${YELLOW}To run the game:${NC}"
echo "1. cd $OUTPUT_DIR"
echo "2. python -m http.server 8000"
echo "3. Open http://localhost:8000 in your browser"
echo ""
echo -e "${YELLOW}Or use the existing serve script:${NC}"
echo "bash scripts/serve-web.py $OUTPUT_DIR"