#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

echo "Testing check_settings_has_hook..."

SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Check if python3 is available in the test environment (real python)
if ! command -v python3 &>/dev/null; then
    echo "python3 not found, skipping settings tests"
    log_test SKIP "python3 required for settings tests"
    cleanup_test_env
    exit 0
fi
HAS_PYTHON="true"

# Test 1: Empty settings file
echo '{}' > "$SETTINGS_FILE"
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test FAIL "Should return 1 for empty settings"
else
    log_test PASS "Returns 1 for empty settings"
fi

# Test 2: No hooks key
echo '{"theme": "light"}' > "$SETTINGS_FILE"
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test FAIL "Should return 1 for settings without hooks"
else
    log_test PASS "Returns 1 for settings without hooks"
fi

# Test 3: SessionStart but no hooks
echo '{"hooks": {"SessionStart": []}}' > "$SETTINGS_FILE"
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test FAIL "Should return 1 for empty SessionStart"
else
    log_test PASS "Returns 1 for empty SessionStart"
fi

# Test 4: SessionStart with other hooks but not ours
cat << 'EOF' > "$SETTINGS_FILE"
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {"type": "command", "command": "other-script"}
        ]
      }
    ]
  }
}
EOF
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test FAIL "Should return 1 when our hook is missing"
else
    log_test PASS "Returns 1 when our hook is missing"
fi

# Test 5: Correct hook entry
cat << 'EOF' > "$SETTINGS_FILE"
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {"type": "command", "command": "/path/to/claude-post-compact-reminder"}
        ]
      }
    ]
  }
}
EOF
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test PASS "Returns 0 when hook is present"
else
    log_test FAIL "Should return 0 when hook is present"
fi

# Test 6: Malformed JSON
echo '{ invalid json }' > "$SETTINGS_FILE"
if check_settings_has_hook "$SETTINGS_FILE"; then
    log_test FAIL "Should return 1 for malformed JSON"
else
    log_test PASS "Returns 1 for malformed JSON"
fi

cleanup_test_env
print_test_summary
