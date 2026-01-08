#!/bin/bash
################################################################################
# Adobe Reader Download Script
# Description: Download Adobe Reader 9.5.0 installer
# Usage: ./download_adobe.sh
################################################################################

OUTPUT_FILE="AdobeReader_9.5.exe"

echo "Downloading Adobe Reader 9.5.0..."
echo

# Try multiple sources
DOWNLOADED=false

# Source 1: Internet Archive (most reliable)
if ! $DOWNLOADED; then
    echo "Trying Internet Archive..."
    if wget -q --show-progress \
        "https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe" \
        -O "$OUTPUT_FILE"; then
        DOWNLOADED=true
        echo "✓ Downloaded from Internet Archive"
    fi
fi

# Source 2: Alternative mirror
if ! $DOWNLOADED; then
    echo "Trying alternative source..."
    if wget -q --show-progress \
        "https://ardownload2.adobe.com/pub/adobe/reader/win/9.x/9.5.0/en_US/AdbeRdr950_en_US.exe" \
        -O "$OUTPUT_FILE"; then
        DOWNLOADED=true
        echo "✓ Downloaded from Adobe FTP"
    fi
fi

if ! $DOWNLOADED; then
    echo "✗ Failed to download Adobe Reader"
    echo
    echo "Please manually download from:"
    echo "  https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe"
    echo
    echo "And save to: $OUTPUT_FILE"
    exit 1
fi

# Verify file size (should be around 50MB)
FILE_SIZE=$(du -m "$OUTPUT_FILE" | cut -f1)
if [ "$FILE_SIZE" -lt 40 ]; then
    echo "✗ File seems incomplete (${FILE_SIZE}MB)"
    rm "$OUTPUT_FILE"
    exit 1
fi

echo
echo "✓ Download complete!"
echo "File: $OUTPUT_FILE"
echo "Size: ${FILE_SIZE}MB"
echo
