#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Source the installer (main won't run)
source "$SCRIPT_DIR/../install-post-compact-reminder.sh"

setup_test_env

# Test 1: Standard banner output
echo "Testing print_banner (standard)..."
QUIET=false
NO_UNICODE=false
# Reset colors to default (in case they were cleared)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
NC='\033[0m'

OUTPUT=$(print_banner)
assert_contains "$OUTPUT" "post-compact-reminder" "Banner should contain project name"
assert_contains "$OUTPUT" "v$VERSION" "Banner should contain version"
# ANSI codes for Cyan (0;36m) should be present by default
assert_contains "$OUTPUT" "[0;36m" "Banner should contain ANSI color codes"

# Test 2: Quiet mode
echo "Testing print_banner (quiet)..."
QUIET=true
OUTPUT=$(print_banner)
assert_equals "" "$OUTPUT" "Banner should be empty when QUIET=true"

# Test 3: No color
echo "Testing print_banner (no color)..."
QUIET=false
# We need to call apply_no_color to set the variables that print_banner uses
apply_no_color
OUTPUT=$(print_banner)
assert_contains "$OUTPUT" "post-compact-reminder" "Banner should still contain text"
# Should NOT contain ANSI codes
if echo "$OUTPUT" | grep -q "\[0;36m"; then
    log_test FAIL "Banner should not contain ANSI codes in no-color mode"
else
    log_test PASS "Banner contained no ANSI codes in no-color mode"
fi

cleanup_test_env
print_test_summary
