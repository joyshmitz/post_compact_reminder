#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

# Suppress logs to keep captured output clean
QUIET=true

echo "Testing add_hook_to_settings..."

SETTINGS_FILE="$SETTINGS_DIR/settings.json"
HOOK_PATH="/path/to/claude-post-compact-reminder"

if ! command -v python3 &>/dev/null; then
    echo "python3 not found, skipping settings tests"
    log_test SKIP "python3 required"
    cleanup_test_env
    exit 0
fi
HAS_PYTHON="true"

# Test 1: Add to new file
rm -f "$SETTINGS_FILE"
RESULT=$(add_hook_to_settings "$SETTINGS_FILE" "$HOOK_PATH" "false")
assert_equals "added" "$RESULT" "Should report added"
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test PASS "Hook added to new file"
else
    log_test FAIL "Hook NOT added to new file"
fi

# Test 2: Idempotency (add again)
RESULT=$(add_hook_to_settings "$SETTINGS_FILE" "$HOOK_PATH" "false")
assert_equals "exists" "$RESULT" "Should report exists"

# Test 3: Add to existing settings with other keys
echo '{"theme": "dark"}' > "$SETTINGS_FILE"
RESULT=$(add_hook_to_settings "$SETTINGS_FILE" "$HOOK_PATH" "false")
assert_equals "added" "$RESULT" "Should report added"
# Check if theme is preserved
if grep -q '"theme": "dark"' "$SETTINGS_FILE"; then
    log_test PASS "Preserved existing keys"
else
    log_test FAIL "Lost existing keys"
fi

# Test 4: Dry run
echo '{}' > "$SETTINGS_FILE"
RESULT=$(add_hook_to_settings "$SETTINGS_FILE" "$HOOK_PATH" "true")
assert_equals "" "$RESULT" "Dry run should output nothing to stdout"
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test FAIL "Dry run modified file"
else
    log_test PASS "Dry run did not modify file"
fi

cleanup_test_env
print_test_summary
