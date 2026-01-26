#!/usr/bin/env bash
# Shared test helper library for post-compact-reminder

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Temp directory (initialized in setup_test_env; declared here so cleanup_test_env
# does not trigger an unbound-variable error under set -u if the EXIT trap fires
# before setup_test_env finishes).
TEST_TEMP_DIR=""

# Config
TAP_OUTPUT=false

# -----------------------------------------------------------------------------
# Setup / Teardown
# -----------------------------------------------------------------------------

setup_test_env() {
    # Disable errexit inherited from the sourced installer so that
    # failed assertions do not abort the test script immediately.
    set +e

    # Ensure cleanup runs even on unexpected exit
    trap cleanup_test_env EXIT

    # Create a unique temp directory for this test run
    TEST_TEMP_DIR=$(mktemp -d -t pcr-test-XXXXXX)

    # Mock HOME and other environments
    export HOME="$TEST_TEMP_DIR/home"
    export HOOK_DIR="$TEST_TEMP_DIR/home/.local/bin"
    export SETTINGS_DIR="$TEST_TEMP_DIR/home/.claude"
    export TMPDIR="$TEST_TEMP_DIR/tmp"

    mkdir -p "$HOME" "$HOOK_DIR" "$SETTINGS_DIR" "$TMPDIR"

    # Mock settings.json
    echo '{}' > "$SETTINGS_DIR/settings.json"
}

cleanup_test_env() {
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# -----------------------------------------------------------------------------
# Reporting
# -----------------------------------------------------------------------------

log_test() {
    local status="$1"
    local message="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    case "$status" in
        PASS)
            TESTS_PASSED=$((TESTS_PASSED + 1))
            if [[ "$TAP_OUTPUT" == "true" ]]; then
                echo "ok $TESTS_RUN - $message"
            else
                echo -e "${GREEN}[PASS]${NC} $message"
            fi
            ;;
        FAIL)
            TESTS_FAILED=$((TESTS_FAILED + 1))
            if [[ "$TAP_OUTPUT" == "true" ]]; then
                echo "not ok $TESTS_RUN - $message"
            else
                echo -e "${RED}[FAIL]${NC} $message"
            fi
            ;;
        SKIP)
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            if [[ "$TAP_OUTPUT" == "true" ]]; then
                echo "ok $TESTS_RUN - $message # SKIP"
            else
                echo -e "${YELLOW}[SKIP]${NC} $message"
            fi
            ;;
    esac
}

print_test_summary() {
    echo ""
    echo "------------------------------------------------"
    echo "Test Summary"
    echo "------------------------------------------------"
    echo -e "Total:  $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
    
    if [[ "$TESTS_FAILED" -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# -----------------------------------------------------------------------------
# Assertions
# -----------------------------------------------------------------------------

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Expected '$expected', got '$actual'}"
    
    if [[ "$expected" == "$actual" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message"
        echo -e "  ${RED}Expected:${NC} [$expected]"
        echo -e "  ${RED}Actual:${NC}   [$actual]"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain '$needle'}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message"
        echo -e "  ${RED}Haystack:${NC} ...${haystack:0:50}..."
        echo -e "  ${RED}Needle:${NC}   $needle"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    if [[ -f "$file" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Exit code should be $expected}"
    
    if [[ "$expected" -eq "$actual" ]]; then
        log_test PASS "$message"
        return 0
    else
        log_test FAIL "$message"
        echo -e "  ${RED}Expected:${NC} $expected"
        echo -e "  ${RED}Actual:${NC}   $actual"
        return 1
    fi
}
