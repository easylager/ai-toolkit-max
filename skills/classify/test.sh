#!/bin/bash
# Test the expanded classify skill on various task types

set -e

cd "$(dirname "$0")"

echo "================================"
echo "Testing Classify Strategy Output"
echo "================================"
echo ""

# Simple task
echo "Test 1: Simple Task (Typo Fix)"
echo "Task: Fix the typo in line 42 of README.md where \"reccomend\" should be \"recommend\""
echo ""
echo "Run:"
echo "  /ai-toolkit-max:classify"
echo "Then paste the task description above."
echo ""
read -p "Press Enter when done..."
echo ""

# Medium task
echo "Test 2: Medium Task (Add Logging)"
echo "Task: Add structured logging to the error handler middleware in the API server."
echo "We need to log error type, status code, and request ID for debugging."
echo ""
echo "Run:"
echo "  /ai-toolkit-max:classify"
echo "Then paste the task description above."
echo ""
read -p "Press Enter when done..."
echo ""

# Complex task
echo "Test 3: Complex Task (Auth Refactor)"
echo "Task: Refactor the authentication system from session-based to JWT tokens."
echo "This affects login flow, token refresh, logout, and all API endpoints that require auth."
echo "Need to maintain backwards compatibility during migration."
echo ""
echo "Run:"
echo "  /ai-toolkit-max:classify"
echo "Then paste the task description above."
echo ""
read -p "Press Enter when done..."
echo ""

echo "================================"
echo "Verification Checklist"
echo "================================"
echo ""
echo "For each test case, verify:"
echo "  ☐ strategy.state_required matches expectation"
echo "  ☐ strategy.research_required matches expectation"
echo "  ☐ research_areas are conceptual hints, not invented file/class names"
echo "  ☐ verification_level reflects actual risk"
echo "  ☐ workflow chain is minimal but sufficient"
echo ""
echo "See test-cases.md for expected outputs."
