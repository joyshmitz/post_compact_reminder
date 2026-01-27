#!/usr/bin/env bash
# shellcheck disable=SC1091
# Test runner for post-compact-reminder

set -u

# Source helper for shared colors if needed, though mostly individual tests use it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

TEST_FILES=()
FAILURES=0

# Parse args
if [[ "$#" -gt 0 ]]; then
    for arg in "$@"; do
        if [[ -f "$arg" ]]; then
            TEST_FILES+=("$arg")
        elif [[ -f "tests/$arg" ]]; then
            TEST_FILES+=("tests/$arg")
        else
             echo "Test file not found: $arg"
             exit 1
        fi
    done
else
    # Discover all tests
    # Note: Using simpler finding logic compatible with strict shell environments
    for f in tests/test_*.sh; do
        [ -e "$f" ] || continue
        TEST_FILES+=("$f")
    done
fi

echo "Running ${#TEST_FILES[@]} test files..."
echo ""

for test_file in "${TEST_FILES[@]}"; do
    echo "=================================================="
    echo "Running: $test_file"
    echo "=================================================="
    
    # Run the test in a subshell
    if bash "$test_file"; then
        echo -e "${GREEN}PASS${NC} $test_file"
    else
        echo -e "${RED}FAIL${NC} $test_file"
        FAILURES=$((FAILURES + 1))
    fi
    echo ""
done

echo "------------------------------------------------"
if [[ "$FAILURES" -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$FAILURES test file(s) failed.${NC}"
    exit 1
fi
