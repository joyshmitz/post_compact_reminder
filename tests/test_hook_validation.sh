#!/usr/bin/env bash
# shellcheck disable=SC1091
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

echo "Testing test_hook..."

# Create a valid hook script
VALID_HOOK="$TEST_TEMP_DIR/valid_hook.sh"
cat << 'EOF' > "$VALID_HOOK"
#!/bin/bash
# Simulate reading input to avoid broken pipe if test_hook writes to stdin
cat > /dev/null
echo "Reminder"
EOF
chmod +x "$VALID_HOOK"

# Test 1: Valid hook
if test_hook "$VALID_HOOK"; then
    log_test PASS "test_hook passed for valid hook"
else
    log_test FAIL "test_hook failed for valid hook"
fi

# Create invalid hook (no output)
INVALID_HOOK="$TEST_TEMP_DIR/invalid_hook.sh"
cat << 'EOF' > "$INVALID_HOOK"
#!/bin/bash
cat > /dev/null
# No output
EOF
chmod +x "$INVALID_HOOK"

# Test 2: Invalid hook
if test_hook "$INVALID_HOOK"; then
    log_test FAIL "test_hook passed for invalid hook (no output)"
else
    log_test PASS "test_hook failed for invalid hook (no output)"
fi

# Test 3: Non-existent hook
if test_hook "$TEST_TEMP_DIR/nonexistent.sh"; then
    log_test FAIL "test_hook passed for non-existent hook"
else
    log_test PASS "test_hook failed for non-existent hook"
fi

cleanup_test_env
print_test_summary
