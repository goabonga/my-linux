#!/bin/bash
# LFS 12.2 - Download all source packages and patches
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== Downloading LFS $LFS_VERSION source packages ==="

mkdir -pv "$LFS_SOURCES"
chmod -v a+wt "$LFS_SOURCES"

# Download all source tarballs
echo "Downloading packages..."
wget --input-file="$SCRIPT_DIR/../sources/wget-list" \
     --continue \
     --directory-prefix="$LFS_SOURCES" \
     --no-verbose \
     --tries=3 \
     --timeout=30 || true

# Download patches
echo "Downloading patches..."
wget --input-file="$SCRIPT_DIR/../sources/patches-list" \
     --continue \
     --directory-prefix="$LFS_SOURCES" \
     --no-verbose \
     --tries=3 \
     --timeout=30 || true

# Verify downloads
echo "Verifying downloads..."
EXPECTED=$(wc -l < "$SCRIPT_DIR/../sources/wget-list")
ACTUAL=$(find "$LFS_SOURCES" -maxdepth 1 -type f | wc -l)
echo "Expected: $EXPECTED files, Downloaded: $ACTUAL files"

if [ "$ACTUAL" -lt "$EXPECTED" ]; then
    echo "WARNING: Some downloads may have failed. Check the output above."
    echo "Retrying failed downloads..."
    wget --input-file="$SCRIPT_DIR/../sources/wget-list" \
         --continue \
         --directory-prefix="$LFS_SOURCES" \
         --no-verbose \
         --tries=5 \
         --timeout=60 || true
fi

echo "=== Source download complete ==="
ls "$LFS_SOURCES" | wc -l
echo "files downloaded to $LFS_SOURCES"
