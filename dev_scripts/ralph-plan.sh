#!/bin/zsh
# =============================================================================
# RALPH PLAN - Spec-to-Tasks Compiler
# =============================================================================
# Reads specification file and existing plan.json, then updates plan.json with
# new/changed tasks while preserving completed task status.
#
# This is the ONLY script that can structurally modify plan.json.
# Ralph (the loop script) can only flip `passes` from false to true.
#
# Usage: ./ralph-plan.sh [--claude|--codex|--copilot]
#        ./ralph-plan.sh --claude              # Update plan using Claude
#        ./ralph-plan.sh --codex               # Update plan using Codex
#        ./ralph-plan.sh --copilot             # Update plan using Copilot CLI
#        ./ralph-plan.sh                       # Default: use Claude
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION
# =============================================================================

PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Input files
SPEC_FILE="${SPEC_FILE:-$PROJECT_ROOT/SPECIFICATION_V4.md}"
PLAN_FILE="${PLAN_FILE:-$PROJECT_ROOT/plan.json}"

# Prompt file
PROMPT_FILE="${PROMPT_FILE:-$PROJECT_ROOT/dev_scripts/RALPH_PLAN_PROMPT.md}"

# Backup before modification
BACKUP_ENABLED="${BACKUP_ENABLED:-true}"

# =============================================================================
# TOOL-SPECIFIC CONFIGURATIONS
# =============================================================================

# Claude Code (https://github.com/anthropics/claude-code)
# Install: npm install -g @anthropic-ai/claude-code OR brew install --cask claude-code
CLAUDE_CMD="claude"
CLAUDE_ARGS="--dangerously-skip-permissions"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-opus-4-5-20250514}"  # Default: Claude Opus 4.5

# OpenAI Codex CLI (https://github.com/openai/codex)
# Install: npm install -g @openai/codex OR brew install --cask codex
CODEX_CMD="codex"
CODEX_ARGS="--full-auto"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.2-codex}"  # Default: GPT-5.2 (best for coding)

# GitHub Copilot CLI (https://github.com/github/copilot-cli)
# Install: brew install copilot-cli OR npm install -g @github/copilot
COPILOT_CMD="copilot"
COPILOT_ARGS="--allow-all-tools"
COPILOT_MODEL="${COPILOT_MODEL:-claude-opus-4.5}"  # Empty = Claude Opus 4.5 (default)

# =============================================================================
# COLOR OUTPUT
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo "${CYAN}=============================================================================${NC}"
    echo "${CYAN}  RALPH PLAN - Spec-to-Tasks Compiler${NC}"
    echo "${CYAN}=============================================================================${NC}"
    echo ""
}

show_usage() {
    echo "${CYAN}Usage:${NC} ./ralph-plan.sh [--<tool>]"
    echo ""
    echo "${CYAN}Arguments:${NC}"
    echo "  --claude      Use Claude Code (default)"
    echo "  --codex       Use OpenAI Codex CLI"
    echo "  --copilot     Use GitHub Copilot CLI"
    echo ""
    echo "${CYAN}Environment Variables:${NC}"
    echo "  PROJECT_ROOT    Project directory (default: git root)"
    echo "  SPEC_FILE       Path to specification file (default: SPECIFICATION_V4.md)"
    echo "  PLAN_FILE       Path to plan.json (default: plan.json)"
    echo "  BACKUP_ENABLED  Create backup before modifying (default: true)"
    echo ""
    echo "${CYAN}Examples:${NC}"
    echo "  ./ralph-plan.sh                    # Update plan with Claude"
    echo "  ./ralph-plan.sh --copilot          # Update plan with Copilot CLI"
    echo "  SPEC_FILE=./PRD.md ./ralph-plan.sh # Use custom spec file"
    echo ""
}

check_tool() {
    local tool=$1
    local cmd=$2
    
    if ! command -v ${cmd%% *} &> /dev/null; then
        echo "${RED}Error:${NC} $tool CLI not found. Please install it first."
        exit 1
    fi
}

check_spec_file() {
    if [[ ! -f "$SPEC_FILE" ]]; then
        echo "${RED}Error:${NC} Specification file not found at $SPEC_FILE"
        echo "Set SPEC_FILE environment variable to point to your spec."
        exit 1
    fi
}

check_prompt_file() {
    if [[ ! -f "$PROMPT_FILE" ]]; then
        echo "${RED}Error:${NC} Prompt file not found at $PROMPT_FILE"
        echo "Please ensure RALPH_PLAN_PROMPT.md exists in dev_scripts/"
        exit 1
    fi
}

init_plan_file() {
    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "${YELLOW}Creating new plan.json...${NC}"
        echo "[]" > "$PLAN_FILE"
    fi
}

backup_plan() {
    if [[ "$BACKUP_ENABLED" == "true" && -f "$PLAN_FILE" ]]; then
        local backup_file="${PLAN_FILE}.backup.$(date '+%Y%m%d_%H%M%S')"
        cp "$PLAN_FILE" "$backup_file"
        echo "${BLUE}Backup created:${NC} $backup_file"
    fi
}

validate_json() {
    local file=$1
    if ! jq empty "$file" 2>/dev/null; then
        echo "${RED}Error:${NC} Invalid JSON in $file"
        return 1
    fi
    return 0
}

build_prompt() {
    local prompt_template=$(cat "$PROMPT_FILE")
    local spec_content=$(cat "$SPEC_FILE")
    local plan_content=$(cat "$PLAN_FILE")
    
    # Replace placeholders in prompt
    local full_prompt="$prompt_template"
    full_prompt="${full_prompt//\{\{SPEC_CONTENT\}\}/$spec_content}"
    full_prompt="${full_prompt//\{\{PLAN_CONTENT\}\}/$plan_content}"
    full_prompt="${full_prompt//\{\{PLAN_FILE\}\}/$PLAN_FILE}"
    
    echo "$full_prompt"
}

# =============================================================================
# TOOL-SPECIFIC RUN FUNCTIONS
# =============================================================================

# Temp file for capturing output while showing it live
OUTPUT_FILE=""

cleanup_temp_files() {
    [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]] && rm -f "$OUTPUT_FILE"
}

trap cleanup_temp_files EXIT

run_claude() {
    local prompt=$1
    OUTPUT_FILE=$(mktemp)
    
    local args=()
    [[ -n "$CLAUDE_MODEL" ]] && args+=(--model "$CLAUDE_MODEL")
    [[ -n "$CLAUDE_ARGS" ]] && args+=("${(z)CLAUDE_ARGS}")
    
    echo "${BLUE}▶ Running:${NC} $CLAUDE_CMD ${args[*]} -p <prompt>"
    echo ""
    
    # Run Claude - pass prompt as -p argument, show output live with tee
    "$CLAUDE_CMD" "${args[@]}" -p "$prompt" 2>&1 | tee "$OUTPUT_FILE"
}

run_codex() {
    local prompt=$1
    OUTPUT_FILE=$(mktemp)
    
    local args=()
    [[ -n "$CODEX_MODEL" ]] && args+=(--model "$CODEX_MODEL")
    [[ -n "$CODEX_ARGS" ]] && args+=("${(z)CODEX_ARGS}")
    
    echo "${BLUE}▶ Running:${NC} $CODEX_CMD ${args[*]} <prompt>"
    echo ""
    
    # Run Codex - pass prompt as positional argument, show output live with tee
    "$CODEX_CMD" "${args[@]}" "$prompt" 2>&1 | tee "$OUTPUT_FILE"
}

run_copilot() {
    local prompt=$1
    OUTPUT_FILE=$(mktemp)
    
    local args=()
    [[ -n "$COPILOT_MODEL" ]] && args+=(--model "$COPILOT_MODEL")
    [[ -n "$COPILOT_ARGS" ]] && args+=("${(z)COPILOT_ARGS}")
    
    echo "${BLUE}▶ Running:${NC} $COPILOT_CMD ${args[*]} -p <prompt>"
    echo ""
    
    # Run Copilot - pass prompt as -p argument, show output live with tee
    "$COPILOT_CMD" "${args[@]}" -p "$prompt" 2>&1 | tee "$OUTPUT_FILE"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    local tool="claude"
    local run_func="run_claude"
    
    # Parse arguments
    case "${1:-}" in
        --claude)
            tool="claude"
            run_func="run_claude"
            ;;
        --codex)
            tool="codex"
            run_func="run_codex"
            ;;
        --copilot)
            tool="copilot"
            run_func="run_copilot"
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        "")
            # Default to claude
            tool="claude"
            run_func="run_claude"
            ;;
        *)
            echo "${RED}Error:${NC} Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # Setup
    print_header
    cd "$PROJECT_ROOT"
    
    # Check prerequisites
    case $tool in
        claude) check_tool "claude" "$CLAUDE_CMD" ;;
        codex) check_tool "codex" "$CODEX_CMD" ;;
        copilot) check_tool "copilot" "$COPILOT_CMD" ;;
    esac
    
    check_spec_file
    check_prompt_file
    init_plan_file
    
    echo "${GREEN}Configuration:${NC}"
    echo "  Project Root:  $PROJECT_ROOT"
    echo "  Spec File:     $SPEC_FILE"
    echo "  Plan File:     $PLAN_FILE"
    echo "  Tool:          $tool"
    echo ""
    
    # Validate existing plan
    if ! validate_json "$PLAN_FILE"; then
        echo "${RED}Existing plan.json is invalid. Creating fresh plan.${NC}"
        echo "[]" > "$PLAN_FILE"
    fi
    
    # Show current status
    local total_tasks=$(jq 'length' "$PLAN_FILE")
    local completed_tasks=$(jq '[.[] | select(.passes == true)] | length' "$PLAN_FILE")
    local pending_tasks=$((total_tasks - completed_tasks))
    
    echo "${BLUE}Current plan status:${NC}"
    echo "  Total tasks:     $total_tasks"
    echo "  Completed:       $completed_tasks"
    echo "  Pending:         $pending_tasks"
    echo ""
    
    # Backup before modification
    backup_plan
    
    # Build and run prompt
    echo "${YELLOW}Analyzing spec and updating plan...${NC}"
    echo ""
    
    local prompt=$(build_prompt)
    
    if ! $run_func "$prompt"; then
        echo "${RED}Error:${NC} Failed to run $tool"
        exit 1
    fi
    
    # Validate updated plan
    echo ""
    if validate_json "$PLAN_FILE"; then
        local new_total=$(jq 'length' "$PLAN_FILE")
        local new_completed=$(jq '[.[] | select(.passes == true)] | length' "$PLAN_FILE")
        local new_pending=$((new_total - new_completed))
        
        echo ""
        echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "${GREEN}  Plan updated successfully!${NC}"
        echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "${BLUE}Updated plan status:${NC}"
        echo "  Total tasks:     $new_total (was $total_tasks)"
        echo "  Completed:       $new_completed"
        echo "  Pending:         $new_pending"
        echo ""
        
        # Show task diff
        local added=$((new_total - total_tasks))
        if [[ $added -gt 0 ]]; then
            echo "${GREEN}  + $added new task(s) added${NC}"
        elif [[ $added -lt 0 ]]; then
            echo "${YELLOW}  - $((-added)) task(s) removed${NC}"
        fi
    else
        echo "${RED}Error:${NC} Plan file is invalid after update!"
        echo "Restoring from backup..."
        local latest_backup=$(ls -t "${PLAN_FILE}.backup."* 2>/dev/null | head -1)
        if [[ -n "$latest_backup" ]]; then
            cp "$latest_backup" "$PLAN_FILE"
            echo "${GREEN}Restored from:${NC} $latest_backup"
        fi
        exit 1
    fi
}

# Run main function
main "$@"
