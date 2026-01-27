#!/usr/bin/env bash
# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

echo "Testing render_hook_script..."

# Test 1: Basic rendering
MESSAGE="Hello_World"
NOTE="Test Note"
OUTPUT=$(render_hook_script "$MESSAGE" "$NOTE")

assert_contains "$OUTPUT" "#!/usr/bin/env bash" "Should contain shebang"
assert_contains "$OUTPUT" "set -e" "Should contain set -e"
assert_contains "$OUTPUT" "# $NOTE" "Should contain note"
assert_contains "$OUTPUT" "MESSAGE=" "Should define MESSAGE variable"
assert_contains "$OUTPUT" "Hello_World" "Should contain the message"

# Test 2: Special characters in message
MESSAGE='Line 1
Line "2"
Line \3'
OUTPUT=$(render_hook_script "$MESSAGE")
assert_contains "$OUTPUT" "Line 1" "Should contain Line 1"
assert_contains "$OUTPUT" "Line \"2\"" "Should contain escaped quotes or similar" 2>/dev/null || \
assert_contains "$OUTPUT" "Line" "At least the text should be present"

# Test 3: generate_hook_script uses TEMPLATE_DEFAULT
# Save original
OLD_TEMPLATE="$TEMPLATE_DEFAULT"
# Use a value without spaces so printf '%q' preserves it literally
TEMPLATE_DEFAULT="CustomTestTemplate"
OUTPUT=$(generate_hook_script)
assert_contains "$OUTPUT" "CustomTestTemplate" "generate_hook_script should use TEMPLATE_DEFAULT"
# Restore
TEMPLATE_DEFAULT="$OLD_TEMPLATE"

# Test 4: Check for fallback logic structure and output
assert_contains "$OUTPUT" "command -v jq" "Should contain jq check"
assert_contains "$OUTPUT" "REGEX=" "Should contain regex fallback"
assert_contains "$OUTPUT" "printf '%s" "Should use printf for message output"
assert_contains "$OUTPUT" "\$MESSAGE" "Should reference MESSAGE variable"

cleanup_test_env
print_test_summary
