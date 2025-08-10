#!/usr/bin/env bash
set -euo pipefail

# Export the game to a web/ folder using a prebuilt love.js bundle.
# Usage:
#   bash scripts/export-web-lovejs.sh           # pack game.love and download love.js if missing
#   bash scripts/export-web-lovejs.sh --serve   # same, then serve at http://localhost:8080
#   LOVEJS_VERSION=11.4 bash scripts/export-web-lovejs.sh --refresh  # force re-download specific version
#   LOVEJS_ZIP_URL=... bash scripts/export-web-lovejs.sh             # override download URL

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
ROOT_DIR="${SCRIPT_DIR%/scripts}"
WEB_DIR="$ROOT_DIR/web"

mkdir -p "$WEB_DIR"

# 1) Package the repo into game.love, excluding non-game files
cd "$ROOT_DIR"
zip -9 -r game.love . \
  -x "android/*" \
  -x ".git/*" \
  -x ".github/*" \
  -x "**/node_modules/*" \
  -x "**/build/*" \
  -x "**/dist/*" \
  -x "web/*"

mv -f game.love "$WEB_DIR/game.love"

# 2) Ensure love.js bundle is present (use 2dengine/love.js repo ZIP)
REFRESH="${1:-}"
if [ "$REFRESH" = "--refresh" ] || [ ! -f "$WEB_DIR/index.html" ]; then
  LOVEJS_VERSION="${LOVEJS_VERSION:-11.4}"
  REPO_ZIP_URL="${LOVEJS_ZIP_URL:-https://github.com/2dengine/love.js/archive/refs/heads/master.zip}"

  TMP_DIR="$(mktemp -d)"
  echo "[love.js] Downloading ${REPO_ZIP_URL} ..."
  curl -L --fail "$REPO_ZIP_URL" -o "$TMP_DIR/lovejs.zip"

  echo "[love.js] Extracting ..."
  unzip -q -o "$TMP_DIR/lovejs.zip" -d "$TMP_DIR"

  # Find extracted root (love.js-master or love.js-main)
  EXTRACT_ROOT=""
  for d in "$TMP_DIR"/love.js-*; do
    if [ -d "$d" ]; then EXTRACT_ROOT="$d"; break; fi
  done
  if [ -z "$EXTRACT_ROOT" ]; then
    EXTRACT_ROOT="$TMP_DIR"
  fi

  # Copy key files to web/
  cp -a "$EXTRACT_ROOT"/* "$WEB_DIR/"
  rm -rf "$TMP_DIR"
  echo "[love.js] Bundle ready in $WEB_DIR"
fi

# 2b) Write a clean index.html that loads player.js from root (avoid repo's /play paths)
LOVEJS_VERSION="${LOVEJS_VERSION:-11.4}"
cat > "$WEB_DIR/index.html" <<EOF
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
    <style>
      html, body { margin: 0; height: 100%; background: #000; touch-action: none; }
      /* Ensure the canvas fills the viewport regardless of devicePixelRatio */
      canvas { display: block; width: 100vw; height: 100vh; max-width: 100vw; max-height: 100vh; image-rendering: pixelated; }
    </style>
    <title>Neon Invaders (love.js)</title>
  </head>
  <body style="margin:0;background:#000;">
    <!-- Add n=1 to reduce cache during iteration -->
    <script src="player.js?g=game.love&v=${LOVEJS_VERSION}&n=1"></script>
  </body>
</html>
EOF

# 3) Optionally serve
if [ "${2:-}" = "--serve" ] || [ "${1:-}" = "--serve" ] || [ "${SERVE:-}" = "1" ]; then
  echo "Serving on http://localhost:8080 (Ctrl+C to stop)"
  if [ -f "$ROOT_DIR/scripts/serve-web.py" ]; then
    python3 "$ROOT_DIR/scripts/serve-web.py" "$WEB_DIR" 8080
  else
    (cd "$WEB_DIR" && python3 -m http.server 8080)
  fi
fi
