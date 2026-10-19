#!/usr/bin/env bash
set -e

# Ensure metadata.json exists
if [ ! -f "metadata.json" ]; then
    echo "Error: metadata.json not found in current directory."
    exit 1
fi

# Extract the plugin ID from metadata.json
PLUGIN_ID=$(grep -o '"Id": *"[^"]*"' metadata.json | head -n 1 | cut -d'"' -f4)

if [ -z "$PLUGIN_ID" ]; then
    echo "Error: Could not determine plugin ID from metadata.json."
    exit 1
fi

OUTPUT_NAME="${PLUGIN_ID}.plasmoid"

echo "Packaging Plasma applet: $PLUGIN_ID..."

# Remove old package if it exists
if [ -f "$OUTPUT_NAME" ]; then
    rm "$OUTPUT_NAME"
fi

# Create the zip-based plasmoid archive (excluding git and script files)
zip -r "$OUTPUT_NAME" metadata.json contents/ -x "*.git*" -x "package.sh" -x "README.md" -x ".gitignore"

echo "Successfully created: $OUTPUT_NAME"
