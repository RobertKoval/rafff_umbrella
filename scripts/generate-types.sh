#!/bin/zsh
# =============================================================================
# Generate Types from OpenAPI Spec
# =============================================================================
# Generates TypeScript types for backend and Swift types for iOS
# from the shared OpenAPI specification.
#
# Usage: ./scripts/generate-types.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SPEC_FILE="$PROJECT_ROOT/shared/api-spec/openapi.yaml"

# Output paths
BACKEND_TYPES="$PROJECT_ROOT/raff_backend/src/types/api.generated.ts"
IOS_TYPES="$PROJECT_ROOT/raff_iOS/Sources/API/Models.generated.swift"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${CYAN}  Generate Types from OpenAPI${NC}"
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check spec exists
if [[ ! -f "$SPEC_FILE" ]]; then
    echo "${RED}Error: OpenAPI spec not found at $SPEC_FILE${NC}"
    exit 1
fi

# =============================================================================
# TypeScript Generation (Backend)
# =============================================================================
echo "${YELLOW}📝 Generating TypeScript types...${NC}"

# Check if openapi-typescript is available
if ! command -v npx &> /dev/null; then
    echo "${RED}Error: npx not found. Install Node.js first.${NC}"
    exit 1
fi

# Create output directory if needed
mkdir -p "$(dirname "$BACKEND_TYPES")"

# Generate TypeScript types
# Using openapi-typescript: https://github.com/drwpow/openapi-typescript
npx openapi-typescript "$SPEC_FILE" -o "$BACKEND_TYPES" 2>/dev/null || {
    echo "${YELLOW}  Installing openapi-typescript...${NC}"
    npm install -g openapi-typescript
    npx openapi-typescript "$SPEC_FILE" -o "$BACKEND_TYPES"
}

echo "${GREEN}  ✓ TypeScript types generated: $BACKEND_TYPES${NC}"

# =============================================================================
# Swift Generation (iOS)
# =============================================================================
echo "${YELLOW}🍎 Generating Swift types...${NC}"

# Create output directory if needed
mkdir -p "$(dirname "$IOS_TYPES")"

# Check if CreateAPI is available (preferred Swift codegen tool)
if command -v create-api &> /dev/null; then
    create-api generate "$SPEC_FILE" --output "$(dirname "$IOS_TYPES")" --config-option module=RaffAPI
    echo "${GREEN}  ✓ Swift types generated: $IOS_TYPES${NC}"
elif command -v swift &> /dev/null; then
    # Try swift-openapi-generator if available as Swift package plugin
    echo "${YELLOW}  CreateAPI not found. Generating placeholder...${NC}"
    echo "${YELLOW}  Install CreateAPI: brew install createapi${NC}"
    
    # Generate placeholder Swift file
    cat > "$IOS_TYPES" << 'SWIFT_EOF'
// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
// Generated from: shared/api-spec/openapi.yaml
// Run ./scripts/generate-types.sh to regenerate
//
// TODO: Install CreateAPI for full Swift type generation
//       brew install createapi
// =============================================================================

import Foundation

// MARK: - Common

struct ErrorResponse: Codable {
    let error: String
    let message: String
}

struct HealthResponse: Codable {
    let status: HealthStatus
    let timestamp: Date
    let version: String?
    
    enum HealthStatus: String, Codable {
        case healthy
        case degraded
        case unhealthy
    }
}

// MARK: - Auth

struct RegisterRequest: Codable {
    let email: String
    let password: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let user: User
    let token: String
}

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let createdAt: Date
    let updatedAt: Date?
}
SWIFT_EOF
    echo "${GREEN}  ✓ Swift placeholder generated: $IOS_TYPES${NC}"
else
    echo "${RED}  ✗ Swift generation skipped (swift not found)${NC}"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GREEN}  Type generation complete!${NC}"
echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  TypeScript: $BACKEND_TYPES"
echo "  Swift:      $IOS_TYPES"
echo ""
echo "${YELLOW}Remember to commit generated files in submodules if changed.${NC}"
