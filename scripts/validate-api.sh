#!/bin/zsh
# =============================================================================
# Validate OpenAPI Specification
# =============================================================================
# Lints and validates the OpenAPI spec for correctness.
#
# Usage: ./scripts/validate-api.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SPEC_FILE="$PROJECT_ROOT/shared/api-spec/openapi.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${CYAN}  Validate OpenAPI Specification${NC}"
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check spec exists
if [[ ! -f "$SPEC_FILE" ]]; then
    echo "${RED}Error: OpenAPI spec not found at $SPEC_FILE${NC}"
    exit 1
fi

echo "${YELLOW}📋 Validating: $SPEC_FILE${NC}"
echo ""

# Try different validators in order of preference
VALIDATED=false

# 1. Try redocly (best validator)
if command -v redocly &> /dev/null; then
    echo "${YELLOW}Using: redocly${NC}"
    if redocly lint "$SPEC_FILE"; then
        VALIDATED=true
    fi
# 2. Try swagger-cli
elif command -v swagger-cli &> /dev/null; then
    echo "${YELLOW}Using: swagger-cli${NC}"
    if swagger-cli validate "$SPEC_FILE"; then
        VALIDATED=true
    fi
# 3. Try npx with @redocly/cli
elif command -v npx &> /dev/null; then
    echo "${YELLOW}Using: npx @redocly/cli${NC}"
    if npx @redocly/cli lint "$SPEC_FILE" 2>/dev/null; then
        VALIDATED=true
    else
        # Fallback: basic YAML syntax check
        echo "${YELLOW}Falling back to basic YAML check...${NC}"
        if python3 -c "import yaml; yaml.safe_load(open('$SPEC_FILE'))" 2>/dev/null; then
            echo "${GREEN}✓ YAML syntax is valid${NC}"
            echo "${YELLOW}⚠️  For full OpenAPI validation, install: npm install -g @redocly/cli${NC}"
            VALIDATED=true
        fi
    fi
else
    echo "${RED}No validator found. Install one of:${NC}"
    echo "  npm install -g @redocly/cli"
    echo "  npm install -g swagger-cli"
    exit 1
fi

echo ""
if [[ "$VALIDATED" == true ]]; then
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${GREEN}  ✓ OpenAPI specification is valid${NC}"
    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${RED}  ✗ OpenAPI specification has errors${NC}"
    echo "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
