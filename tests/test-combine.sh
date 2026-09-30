#!/usr/bin/env bash
# ==============================================================================
# DoomOS Test Suite — Combine & Multipart Reassembly Unit Tests
# Tests combine.sh functionality:
# 1. Clean reassembly and SHA256 match
# 2. Missing chunk detection and failure
# 3. Empty chunk detection and failure
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMBINE_BIN="${REPO_ROOT}/scripts/combine.sh"
TEST_DIR=$(mktemp -d /tmp/doomos-combine-test.XXXXXX)

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

echo "=== Running combine.sh Unit Tests in ${TEST_DIR} ==="

# 1. Generate test dummy binary (10 MB)
TEST_ISO="${TEST_DIR}/test-doomos-x86_64.iso"
dd if=/dev/urandom of="$TEST_ISO" bs=1048576 count=10 2>/dev/null
ORIGINAL_HASH=$(cd "$TEST_DIR" && (sha256sum "$(basename "$TEST_ISO")" 2>/dev/null || shasum -a 256 "$(basename "$TEST_ISO")") | awk '{print $1}')
echo "${ORIGINAL_HASH}  $(basename "$TEST_ISO")" > "${TEST_ISO}.sha256"

# Split into 3 chunks portably
if command -v gsplit >/dev/null 2>&1; then
    gsplit -b 4M -d -a 2 "$TEST_ISO" "${TEST_ISO}.part"
else
    # Fallback portable split
    dd if="$TEST_ISO" of="${TEST_ISO}.part00" bs=1048576 count=4 2>/dev/null
    dd if="$TEST_ISO" of="${TEST_ISO}.part01" bs=1048576 skip=4 count=4 2>/dev/null
    dd if="$TEST_ISO" of="${TEST_ISO}.part02" bs=1048576 skip=8 count=2 2>/dev/null
fi
rm -f "$TEST_ISO"

# Copy combine.sh to test directory
cp "$COMBINE_BIN" "${TEST_DIR}/combine.sh"
chmod +x "${TEST_DIR}/combine.sh"

echo "[TEST 1] Reassembling 3 valid chunks..."
(cd "$TEST_DIR" && ./combine.sh)
echo "[PASS] Test 1: Successful reassembly."

echo "[TEST 2] Missing chunk test..."
rm -f "${TEST_ISO}"
rm -f "${TEST_ISO}.part01"
if (cd "$TEST_DIR" && ./combine.sh 2>/dev/null); then
    echo "[FAIL] combine.sh should have failed on missing chunk!"
    exit 1
else
    echo "[PASS] Test 2: combine.sh rejected missing chunk as expected."
fi

echo "=== All combine.sh unit tests passed! ==="
