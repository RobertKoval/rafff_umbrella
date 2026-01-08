#!/bin/zsh
# =============================================================================
# Sync Submodules
# =============================================================================
# Pulls latest commits from all submodule origins and optionally
# updates umbrella refs.
#
# Usage: ./scripts/sync-submodules.sh [--commit]
#        --commit: Also commit updated refs to umbrella
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

AUTO_COMMIT=false
if [[ "$1" == "--commit" ]]; then
    AUTO_COMMIT=true
fi

echo ""
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${CYAN}  Sync Submodules${NC}"
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd "$PROJECT_ROOT"

# Pull latest umbrella
echo "${YELLOW}📥 Pulling umbrella...${NC}"
git pull || true

# Update submodules to their latest remote commits
echo "${YELLOW}📥 Updating submodules to latest remote...${NC}"
git submodule update --remote --merge

# Show status
echo ""
echo "${YELLOW}📋 Submodule status:${NC}"
git submodule status

# Check if there are changes to commit
if [[ -n $(git status --porcelain) ]]; then
    echo ""
    echo "${YELLOW}⚠️  Submodule refs have changed${NC}"
    
    if [[ "$AUTO_COMMIT" == true ]]; then
        echo "${YELLOW}📝 Committing updated refs...${NC}"
        git add raff_backend raff_iOS
        git commit -m "chore: sync submodule refs"
        echo "${GREEN}✓ Refs committed${NC}"
    else
        echo "   Run with --commit to auto-commit, or manually:"
        echo "   git add raff_backend raff_iOS"
        echo "   git commit -m 'chore: sync submodule refs'"
    fi
else
    echo ""
    echo "${GREEN}✓ All submodules up to date${NC}"
fi

echo ""
