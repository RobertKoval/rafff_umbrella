#!/bin/zsh
# =============================================================================
# Setup Git Hooks for Ralph Quality Gates
# =============================================================================
# Installs pre-commit hook that prevents commits if quality checks fail.
# Run this once: ./dev_scripts/setup-hooks.sh
# =============================================================================

set -e

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "Setting up git hooks..."

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'HOOK_EOF'
#!/bin/zsh
# =============================================================================
# Pre-commit Hook - Quality Gates
# =============================================================================
# Prevents commits if any quality check fails.
# NO BYPASS ALLOWED - fix the issues.
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${YELLOW}  Pre-commit Quality Gates${NC}"
echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track failures
FAILED=0

# 1. Type checking
echo "📝 Running type-check..."
if npm run type-check > /dev/null 2>&1; then
    echo "${GREEN}  ✓ Type check passed${NC}"
else
    echo "${RED}  ✗ Type check FAILED${NC}"
    echo "    Run: npm run type-check"
    FAILED=1
fi

# 2. Linting
echo "🔍 Running lint..."
if npm run lint > /dev/null 2>&1; then
    echo "${GREEN}  ✓ Lint passed${NC}"
else
    echo "${RED}  ✗ Lint FAILED${NC}"
    echo "    Run: npm run lint"
    FAILED=1
fi

# 3. Unit tests
echo "🧪 Running tests..."
if npm run test:unit > /dev/null 2>&1; then
    echo "${GREEN}  ✓ Tests passed${NC}"
else
    echo "${RED}  ✗ Tests FAILED${NC}"
    echo "    Run: npm run test:unit"
    FAILED=1
fi

# 4. Dead code detection (knip)
if [[ -f "knip.json" ]] || grep -q '"knip"' package.json 2>/dev/null; then
    echo "🧹 Checking for dead code (knip)..."
    if npx knip --no-progress > /dev/null 2>&1; then
        echo "${GREEN}  ✓ No dead code detected${NC}"
    else
        echo "${RED}  ✗ Dead code detected${NC}"
        echo "    Run: npx knip"
        FAILED=1
    fi
fi

# 5. Mutation testing on staged files (only for changed src files, excluding exempt patterns)
# Exempt patterns: *.constants.ts, *.mock.ts, *.mocks.ts, *.fixture.ts, *.fixtures.ts, seed.ts
STAGED_SRC_FILES=$(git diff --cached --name-only --diff-filter=ACM | \
    grep -E '^src/.*\.(ts|tsx)$' | \
    grep -v '\.test\.' | \
    grep -v '\.spec\.' | \
    grep -v '\.constants\.' | \
    grep -v '\.mock\.' | \
    grep -v '\.mocks\.' | \
    grep -v '\.fixture\.' | \
    grep -v '\.fixtures\.' | \
    grep -v 'seed\.ts$' | \
    grep -v '/seed/' || true)
if [[ -n "$STAGED_SRC_FILES" ]]; then
    echo "🧬 Running mutation tests on changed files..."
    echo "   (Exempt: *.constants.ts, *.mock.ts, *.fixture.ts, seed.ts)"
    MUTATE_PATTERN=$(echo "$STAGED_SRC_FILES" | tr '\n' ',' | sed 's/,$//')
    
    # Run mutation testing and check for 95%+ score
    MUTATION_OUTPUT=$(npm run test:mutation -- --mutate="{$MUTATE_PATTERN}" 2>&1 || true)
    
    # Extract mutation score percentage
    MUTATION_SCORE=$(echo "$MUTATION_OUTPUT" | grep -oE '[0-9]+\.[0-9]+% mutation score' | grep -oE '[0-9]+\.[0-9]+' | head -1)
    
    if [[ -n "$MUTATION_SCORE" ]]; then
        # Compare score (zsh floating point comparison)
        if (( $(echo "$MUTATION_SCORE >= 95.0" | bc -l) )); then
            echo "${GREEN}  ✓ Mutation score: ${MUTATION_SCORE}% (≥95% required)${NC}"
        else
            echo "${RED}  ✗ Mutation score: ${MUTATION_SCORE}% (≥95% required)${NC}"
            echo "    Improve tests to kill more mutants"
            echo "    Run: npm run test:mutation -- --mutate=\"{$MUTATE_PATTERN}\""
            FAILED=1
        fi
    else
        # If no score found, check if there were any mutations
        if echo "$MUTATION_OUTPUT" | grep -q "No mutants"; then
            echo "${GREEN}  ✓ No mutations to test${NC}"
        else
            echo "${YELLOW}  ⚠ Could not determine mutation score${NC}"
            echo "    Run manually: npm run test:mutation -- --mutate=\"{$MUTATE_PATTERN}\""
        fi
    fi
else
    echo "🧬 Mutation tests: No source files staged"
fi

echo ""

if [[ $FAILED -eq 1 ]]; then
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${RED}  COMMIT BLOCKED - Fix the issues above${NC}"
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    exit 1
fi

echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GREEN}  All checks passed - commit allowed${NC}"
echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

exit 0
HOOK_EOF

# Make hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed at: $HOOKS_DIR/pre-commit"
echo ""
echo "The hook will run before each commit and check:"
echo "  • Type checking (npm run type-check)"
echo "  • Linting (npm run lint)"
echo "  • Unit tests (npm run test:unit)"
echo "  • Dead code detection (npx knip)"
echo "  • Mutation testing ≥95% on changed files"
echo ""
echo "NO BYPASS ALLOWED - fix issues before committing."
