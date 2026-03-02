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
# Alfred lets users set a custom sync folder (Preferences > Advanced > Set preferences folder).
# When set, workflows live at {syncfolder}/Alfred.alfredpreferences/workflows/ instead of the
# default ~/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/.
# We read this from Alfred's preferences plist, falling back to the default location.

ALFRED_PREFS=""
sync_folder=$(defaults read com.runningwithcrayons.Alfred-Preferences syncfolder 2>/dev/null || true)
if [ -n "$sync_folder" ]; then
  # Expand ~ to $HOME (defaults read returns literal ~)
  sync_folder="${sync_folder/#\~/$HOME}"
  candidate="${sync_folder}/Alfred.alfredpreferences/workflows"
  if [ -d "$candidate" ]; then
    ALFRED_PREFS="$candidate"
  fi
fi

# Fall back to default location
if [ -z "$ALFRED_PREFS" ]; then
  ALFRED_PREFS="$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows"
fi

# Alfred 5 may not pre-create the workflows/ directory. If the parent
# Alfred.alfredpreferences directory exists, create workflows/ automatically.
if [ ! -d "$ALFRED_PREFS" ]; then
  PREFS_PARENT="$(dirname "$ALFRED_PREFS")"
  if [ -d "$PREFS_PARENT" ]; then
    echo "Creating workflows directory at:"
    echo "  $ALFRED_PREFS"
    mkdir -p "$ALFRED_PREFS"
  else
    echo "Error: Alfred preferences directory not found."
    echo ""
    echo "Checked:"
    if [ -n "$sync_folder" ]; then
      echo "  ${sync_folder}/Alfred.alfredpreferences/workflows/"
    fi
    echo "  ~/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/"
    echo ""
    echo "Make sure Alfred 4 or 5 is installed and has been launched at least once."
    exit 1
  fi
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

# --- Try to reload the workflow in Alfred ---
osascript -e 'tell application id "com.runningwithcrayons.Alfred" to reload workflow "'"$BUNDLE_ID"'"' 2>/dev/null || true

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
echo "Images are automatically cleaned up after 7 days (configurable)."
echo ""
echo "If the workflow doesn't appear, restart Alfred."
