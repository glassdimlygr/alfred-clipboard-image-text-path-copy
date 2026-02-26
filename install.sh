#!/bin/bash
set -euo pipefail

# install.sh — Install the Clipboard Image to Path workflow for Alfred 4+
#
# Usage:
#   git clone https://github.com/glassdimly/alfred-clipboard-image-text-path-copy.git
#   cd alfred-clipboard-image-text-path-copy
#   ./install.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_ID="com.glassdimly.alfred.clipboard-image"

# --- Locate Alfred workflows directory ---
ALFRED_PREFS="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows"

if [ ! -d "$ALFRED_PREFS" ]; then
  echo "Error: Alfred workflows directory not found at:"
  echo "  $ALFRED_PREFS"
  echo ""
  echo "Make sure Alfred 4 or 5 is installed and has been launched at least once."
  exit 1
fi

# --- Check for existing installation ---
existing_dir=""
for d in "$ALFRED_PREFS"/user.workflow.*/; do
  [ -f "$d/info.plist" ] || continue
  bid=$(/usr/libexec/PlistBuddy -c "Print :bundleid" "$d/info.plist" 2>/dev/null || true)
  if [ "$bid" = "$BUNDLE_ID" ]; then
    existing_dir="$d"
    break
  fi
done

if [ -n "$existing_dir" ]; then
  WORKFLOW_DIR="$existing_dir"
  echo "Updating existing installation at:"
  echo "  $WORKFLOW_DIR"
else
  # Generate a new workflow UUID
  WORKFLOW_UUID=$(uuidgen)
  WORKFLOW_DIR="${ALFRED_PREFS}/user.workflow.${WORKFLOW_UUID}"
  mkdir -p "$WORKFLOW_DIR"
  echo "Installing to:"
  echo "  $WORKFLOW_DIR"
fi

# --- Copy workflow files ---
cp "$SCRIPT_DIR/info.plist" "$WORKFLOW_DIR/info.plist"
cp "$SCRIPT_DIR/script_filter.sh" "$WORKFLOW_DIR/script_filter.sh"
chmod +x "$WORKFLOW_DIR/script_filter.sh"

# Copy icon if present
if [ -f "$SCRIPT_DIR/icon.png" ]; then
  cp "$SCRIPT_DIR/icon.png" "$WORKFLOW_DIR/icon.png"
fi

# --- Create images directory ---
mkdir -p "$HOME/.config/alfred/clipboard-image/images"

# --- Verify ---
echo ""
echo "Installed successfully."
echo ""
echo "Usage:"
echo "  1. Copy an image to clipboard (screenshot, Lightshot, etc.)"
echo "  2. Open Alfred and type: img"
echo "  3. Select an image and press Enter"
echo "  4. The file path is now on your clipboard — paste it anywhere"
echo ""
echo "Saved images: ~/.config/alfred/clipboard-image/images/"
echo "Images older than 7 days are automatically cleaned up."
echo ""
echo "You may need to restart Alfred for the workflow to appear."
