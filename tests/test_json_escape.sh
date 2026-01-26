#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

echo "Testing json_escape..."

# Test 1: Plain text
INPUT="Hello World"
EXPECTED="Hello World"
ACTUAL=$(json_escape "$INPUT")
assert_equals "$EXPECTED" "$ACTUAL" "Plain text should not change"

# Test 2: Double quotes
INPUT='Hello "World"'
EXPECTED='Hello \"World\"'
ACTUAL=$(json_escape "$INPUT")
assert_equals "$EXPECTED" "$ACTUAL" "Double quotes should be escaped"

# Test 3: Backslashes
INPUT='C:\\Windows\\System32'
EXPECTED='C:\\\\Windows\\\\System32'
ACTUAL=$(json_escape "$INPUT")
assert_equals "$EXPECTED" "$ACTUAL" "Backslashes should be escaped"

# Test 4: Newlines and Tabs
INPUT=$'Line 1\nLine 2\tTabbed'
EXPECTED='Line 1\nLine 2\tTabbed'
ACTUAL=$(json_escape "$INPUT")
assert_equals "$EXPECTED" "$ACTUAL" "Newlines and tabs should be escaped"

# Test 5: Combined
INPUT=$'Key: "Value"\nPath: C:\\Temp'
EXPECTED='Key: \"Value\"\nPath: C:\\Temp'
ACTUAL=$(json_escape "$INPUT")
assert_equals "$EXPECTED" "$ACTUAL" "Combined special characters should be escaped"

# Test 6: Empty string
INPUT=""
EXPECTED=""
ACTUAL=$(json_escape "$INPUT")
assert_equals "$EXPECTED" "$ACTUAL" "Empty string should remain empty"

cleanup_test_env
print_test_summary
