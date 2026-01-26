#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

# Save original PATH
ORIG_PATH="$PATH"

# Test detect_dependencies
echo "Testing detect_dependencies..."

# Setup mock bin
mkdir -p "$TEST_TEMP_DIR/bin"
export PATH="$TEST_TEMP_DIR/bin:$ORIG_PATH" # Keep system path for basic tools like rm, touch, but prioritize mock bin? 
# No, if we want to simulate absence, we must NOT include system path where jq/python might be.
# But we need ls, cp, etc. 
# Best to create a restricted path.
# Copy needed binaries to temp bin? No, that's heavy.
# Instead, define a function `command` that filters? No, see previous thought.

# Alternative: We can temporarily rename the real jq/python if they exist? No, unsafe.

# Let's rely on the fact that `detect_dependencies` uses `command -v`.
# We can define a function `command` inside this test script.
# Sourced functions override builtins in bash.

function command() {
    if [[ "$1" == "-v" ]]; then
        if [[ "$2" == "jq" ]]; then
            [[ -e "$TEST_TEMP_DIR/bin/jq" ]] && return 0 || return 1
        elif [[ "$2" == "python3" ]]; then
             [[ -e "$TEST_TEMP_DIR/bin/python3" ]] && return 0 || return 1
        elif [[ "$2" == "apt-get" ]]; then
             [[ -e "$TEST_TEMP_DIR/bin/apt-get" ]] && return 0 || return 1
        elif [[ "$2" == "brew" ]]; then
             [[ -e "$TEST_TEMP_DIR/bin/brew" ]] && return 0 || return 1
        else
            # For other things, try the real command?
            # But 'command -v' is the check.
            builtin command -v "$2" >/dev/null 2>&1
        fi
    else
        builtin command "$@"
    fi
}

# Now we can control existence via files in TEST_TEMP_DIR/bin

# Case 1: jq exists, python3 missing
touch "$TEST_TEMP_DIR/bin/jq"
rm -f "$TEST_TEMP_DIR/bin/python3"

detect_dependencies
assert_equals "true" "$HAS_JQ" "HAS_JQ should be true when jq exists"
assert_equals "false" "$HAS_PYTHON" "HAS_PYTHON should be false when python3 missing"

# Case 2: Both exist
touch "$TEST_TEMP_DIR/bin/python3"

detect_dependencies
assert_equals "true" "$HAS_JQ" "HAS_JQ should be true"
assert_equals "true" "$HAS_PYTHON" "HAS_PYTHON should be true"


# Test detect_package_manager
echo "Testing detect_package_manager..."

# Mock apt-get
touch "$TEST_TEMP_DIR/bin/apt-get"
rm -f "$TEST_TEMP_DIR/bin/brew"
assert_equals "apt" "$(detect_package_manager)" "Should detect apt"

# Mock brew
rm -f "$TEST_TEMP_DIR/bin/apt-get"
touch "$TEST_TEMP_DIR/bin/brew"
assert_equals "brew" "$(detect_package_manager)" "Should detect brew"


# Test check_dependencies
echo "Testing check_dependencies..."

# Setup: missing dependencies
rm -f "$TEST_TEMP_DIR/bin/jq"
rm -f "$TEST_TEMP_DIR/bin/python3"
HAS_JQ="false"
HAS_PYTHON="false"

# Case: allow_install=false (simulate dry run or skip deps)
if check_dependencies "false" >/dev/null; then
    log_test PASS "check_dependencies returns 0 when allow_install=false"
else
    log_test FAIL "check_dependencies returned non-zero when allow_install=false"
fi

# Case: allow_install=true, but no package manager found
rm -f "$TEST_TEMP_DIR/bin/apt-get"
rm -f "$TEST_TEMP_DIR/bin/brew"
# Note: we also need to ensure dnf, yum, pacman are not found.
# Since we mocked `command`, and we haven't created files for them, `command -v` should fail for them.

if check_dependencies "true" >/dev/null 2>&1; then
    log_test FAIL "check_dependencies should fail when no pkg manager found"
else
    log_test PASS "check_dependencies failed as expected (no pkg manager)"
fi

# Restore PATH
export PATH="$ORIG_PATH"
# Unset function? 
unset -f command

cleanup_test_env
print_test_summary
