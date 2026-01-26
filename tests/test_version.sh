#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

echo "Testing get_installed_version..."

# Test 1: Valid script with version
SCRIPT_V1="$TEST_TEMP_DIR/script_v1.sh"
echo '#!/bin/bash' > "$SCRIPT_V1"
echo '# Version: 1.0.0' >> "$SCRIPT_V1"
chmod +x "$SCRIPT_V1"

VERSION_FOUND=$(get_installed_version "$SCRIPT_V1")
assert_equals "1.0.0" "$VERSION_FOUND" "Should extract version 1.0.0"

# Test 2: Script without version
SCRIPT_NO_VER="$TEST_TEMP_DIR/script_no_ver.sh"
echo '#!/bin/bash' > "$SCRIPT_NO_VER"
chmod +x "$SCRIPT_NO_VER"

VERSION_FOUND=$(get_installed_version "$SCRIPT_NO_VER")
assert_equals "" "$VERSION_FOUND" "Should return empty string for missing version"

# Test 3: Non-existent file
VERSION_FOUND=$(get_installed_version "$TEST_TEMP_DIR/missing.sh")
assert_equals "" "$VERSION_FOUND" "Should return empty string for missing file"

echo "Testing do_changelog..."

# Capture output of do_changelog
OUTPUT=$(do_changelog)
assert_contains "$OUTPUT" "v1.2.0" "Changelog should contain v1.2.0"
assert_contains "$OUTPUT" "v1.1.0" "Changelog should contain v1.1.0"
assert_contains "$OUTPUT" "v1.0.0" "Changelog should contain v1.0.0"
# Check for descriptions
assert_contains "$OUTPUT" "Added --message" "Changelog should contain descriptions"

cleanup_test_env
print_test_summary
