#!/bin/zsh
# =============================================================================
# RALPH WIGGUM - Autonomous Coding Agent Loop
# =============================================================================
# Runs a coding agent in an infinite loop for autonomous development.
# Inspired by: https://ghuntley.com/ralph/
#              https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
#
# Usage: ./ralph.sh <iterations> --<tool>
#        ./ralph.sh 30 --claude      # Run 30 iterations with Claude Code
#        ./ralph.sh 10 --codex       # Run 10 iterations with OpenAI Codex
#        ./ralph.sh 5 --copilot      # Run 5 iterations with GitHub Copilot CLI
#        ./ralph.sh 0 --claude       # Run indefinitely with Claude
# =============================================================================

set -e

# =============================================================================
# CONFIGURATION - Adjust these settings for each tool
# =============================================================================

# Project root (auto-detected or set manually)
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Prompt file location
PROMPT_FILE="${PROMPT_FILE:-$PROJECT_ROOT/dev_scripts/RALPH_PROMPT.md}"

# Progress file for tracking agent work
PROGRESS_FILE="${PROGRESS_FILE:-$PROJECT_ROOT/ralph-progress.txt}"

# Logs directory for tool-specific logs
LOGS_DIR="${LOGS_DIR:-$PROJECT_ROOT/logs}"

# Delay between iterations (seconds) - prevents rate limiting
ITERATION_DELAY="${ITERATION_DELAY:-5}"

# Auto-commit after each iteration (disabled by default - agent should commit manually)
AUTO_COMMIT="${AUTO_COMMIT:-false}"

# Notification command (optional) - called when loop completes
NOTIFY_CMD="${NOTIFY_CMD:-}"  # e.g., "terminal-notifier -message" on macOS

# =============================================================================
# TOOL-SPECIFIC CONFIGURATIONS
# =============================================================================

# Claude Code (https://github.com/anthropics/claude-code)
# Install: npm install -g @anthropic-ai/claude-code OR brew install --cask claude-code
CLAUDE_CMD="claude"
CLAUDE_ARGS='--dangerously-skip-permissions --print'  # Skip permission prompts and use non-interactive print mode
CLAUDE_MODEL="${CLAUDE_MODEL:-opus}"  # Default: Claude Opus 4.5

# OpenAI Codex CLI (https://github.com/openai/codex)
# Install: npm install -g @openai/codex OR brew install --cask codex
CODEX_CMD="codex"
CODEX_ARGS="--dangerously-bypass-approvals-and-sandbox"    # Full autonomous mode (requires exec subcommand)
CODEX_MODEL="${CODEX_MODEL:-gpt-5.2-codex}"                      # Default: GPT-5.2 Codex (best for coding)

# GitHub Copilot CLI (https://github.com/github/copilot-cli)
# Install: brew install copilot-cli OR npm install -g @github/copilot
# Default model is Claude Sonnet 4.5, available: Claude Sonnet 4, GPT-5
COPILOT_CMD="copilot"
COPILOT_ARGS="--allow-all-tools --enable-all-github-mcp-tools"  # Auto-approve all tools for automation
COPILOT_MODEL="${COPILOT_MODEL:-claude-opus-4.5}"  # Empty = Claude Opus 4.5 (default)

# =============================================================================
# COLOR OUTPUT
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_header() {
    echo ""
    echo "${CYAN}=============================================================================${NC}"
    echo "${CYAN}  RALPH WIGGUM - Autonomous Coding Agent${NC}"
    echo "${CYAN}=============================================================================${NC}"
    echo ""
}

print_iteration() {
    local current=$1
    local total=$2
    local tool=$3
    
    echo ""
    echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [[ "$total" == "0" || "$total" == "∞" ]]; then
        echo "${YELLOW}  Iteration #$current (infinite mode) | Tool: $tool${NC}"
    else
        echo "${YELLOW}  Iteration $current of $total | Tool: $tool${NC}"
    fi
    echo "${YELLOW}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

log_progress() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$PROGRESS_FILE"
}

show_usage() {
    echo "${CYAN}Usage:${NC} ./ralph.sh <iterations> --<tool>"
    echo ""
    echo "${CYAN}Arguments:${NC}"
    echo "  iterations    Number of iterations (0 for infinite)"
    echo "  --claude      Use Claude Code"
    echo "  --codex       Use OpenAI Codex CLI"
    echo "  --copilot     Use GitHub Copilot CLI"
    echo ""
    echo "${CYAN}Examples:${NC}"
    echo "  ./ralph.sh 30 --claude     # Run 30 iterations with Claude"
    echo "  ./ralph.sh 0 --claude      # Run indefinitely with Claude"
    echo "  ./ralph.sh 10 --codex      # Run 10 iterations with Codex"
    echo ""
    echo "${CYAN}Environment Variables:${NC}"
    echo "  PROJECT_ROOT      Project directory (default: git root)"
    echo "  PROMPT_FILE       Path to prompt file (default: dev_scripts/RALPH_PROMPT.md)"
    echo "  PROGRESS_FILE     Path to progress log (default: ralph-progress.txt)"
    echo "  ITERATION_DELAY   Seconds between iterations (default: 5)"
    echo "  CLAUDE_MODEL      Claude model to use"
    echo "  CODEX_MODEL       Codex model to use"
    echo ""
    echo "${CYAN}Git Hooks:${NC}"
    echo "  Run ./dev_scripts/setup-hooks.sh to install pre-commit quality gates"
    echo ""
}

check_tool() {
    local tool=$1
    local cmd=$2
    
    if ! command -v ${cmd%% *} &> /dev/null; then
        echo "${RED}Error:${NC} $tool CLI not found. Please install it first."
        echo ""
        case $tool in
            "claude")
                echo "Install Claude Code: npm install -g @anthropic-ai/claude-code"
                ;;
            "codex")
                echo "Install Codex CLI: npm install -g @openai/codex"
                ;;
            "copilot")
                echo "Install GitHub Copilot CLI:"
                echo "  brew install copilot-cli"
                echo "  OR: npm install -g @github/copilot"
                ;;
        esac
        exit 1
    fi
}

check_prompt_file() {
    if [[ ! -f "$PROMPT_FILE" ]]; then
        echo "${YELLOW}Warning:${NC} Prompt file not found at $PROMPT_FILE"
    fi
}

notify() {
    local message=$1
    if [[ -n "$NOTIFY_CMD" ]]; then
        eval "$NOTIFY_CMD '$message'" 2>/dev/null || true
    fi
    
    # macOS notification fallback
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"$message\" with title \"Ralph Wiggum\"" 2>/dev/null || true
    fi
}

# =============================================================================
# TOOL-SPECIFIC RUN FUNCTIONS
# =============================================================================

# Temp file for capturing output while showing it live
OUTPUT_FILE=""

cleanup_output_file() {
    [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]] && rm -f "$OUTPUT_FILE"
}

trap cleanup_output_file EXIT

run_claude() {
    OUTPUT_FILE=$(mktemp)
    local prompt_content
    prompt_content=$(cat "$PROMPT_FILE")
    local logfile="$LOGS_DIR/ralph.claude.log"

    local args=()
    [[ -n "$CLAUDE_MODEL" ]] && args+=(--model "$CLAUDE_MODEL")
    # Add any extra args from CLAUDE_ARGS
    [[ -n "$CLAUDE_ARGS" ]] && args+=("${(z)CLAUDE_ARGS}")
    
    local full_cmd="$CLAUDE_CMD ${args[*]} <prompt>"
    echo "${BLUE}▶ Running:${NC} $full_cmd"
    echo ""
    
    # Log timestamp and command to persistent logfile
    {
        echo ""
        echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Iteration start ==="
        echo "Command: $full_cmd"
        echo "---"
    } >> "$logfile"
    
    # Run Claude - stream output live to terminal AND append to logfile
    # Using stdbuf to disable buffering so output streams in real-time
    stdbuf -oL -eL "$CLAUDE_CMD" "${args[@]}" "$prompt_content" 2>&1 | tee -a "$logfile" | tee "$OUTPUT_FILE"
}

run_codex() {
    OUTPUT_FILE=$(mktemp)
    local prompt_content
    prompt_content=$(cat "$PROMPT_FILE")
    local logfile="$LOGS_DIR/ralph.codex.log"
    
    local args=()
    [[ -n "$CODEX_MODEL" ]] && args+=(--model "$CODEX_MODEL")
    [[ -n "$CODEX_ARGS" ]] && args+=("${(z)CODEX_ARGS}")
    
    local full_cmd="$CODEX_CMD exec - ${args[*]} <prompt>"
    echo "${BLUE}▶ Running:${NC} $full_cmd"
    echo ""
    
    # Log timestamp and command to persistent logfile
    {
        echo ""
        echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Iteration start ==="
        echo "Command: $full_cmd"
        echo "---"
    } >> "$logfile"
    
    # Run Codex non-interactively using 'exec' subcommand
    # Input is piped via stdin to '-' argument; stream to terminal + logfile
    echo "$prompt_content" | stdbuf -oL -eL "$CODEX_CMD" exec - "${args[@]}" 2>&1 | tee -a "$logfile" | tee "$OUTPUT_FILE"
}

run_copilot() {
    OUTPUT_FILE=$(mktemp)
    local prompt_content
    prompt_content=$(cat "$PROMPT_FILE")
    local logfile="$LOGS_DIR/ralph.copilot.log"
    
    local args=()
    [[ -n "$COPILOT_MODEL" ]] && args+=(--model "$COPILOT_MODEL")
    [[ -n "$COPILOT_ARGS" ]] && args+=("${(z)COPILOT_ARGS}")
    
    local full_cmd="$COPILOT_CMD ${args[*]} -p <prompt>"
    echo "${BLUE}▶ Running:${NC} $full_cmd"
    echo ""
    
    # Log timestamp and command to persistent logfile
    {
        echo ""
        echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Iteration start ==="
        echo "Command: $full_cmd"
        echo "---"
    } >> "$logfile"
    
    # Run Copilot - pass prompt as -p argument, stream to terminal + logfile
    stdbuf -oL -eL "$COPILOT_CMD" "${args[@]}" -p "$prompt_content" 2>&1 | tee -a "$logfile" | tee "$OUTPUT_FILE"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Parse arguments
    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi
    
    local iterations=$1
    local tool_flag=$2
    local tool=""
    local run_func=""
    
    # Determine which tool to use
    case $tool_flag in
        --claude)
            tool="claude"
            run_func="run_claude"
            check_tool "claude" "$CLAUDE_CMD"
            ;;
        --codex)
            tool="codex"
            run_func="run_codex"
            check_tool "codex" "$CODEX_CMD"
            ;;
        --copilot)
            tool="copilot"
            run_func="run_copilot"
            check_tool "copilot" "$COPILOT_CMD"
            ;;
        *)
            echo "${RED}Error:${NC} Unknown tool flag: $tool_flag"
            show_usage
            exit 1
            ;;
    esac
    
    # Validate iterations
    if ! [[ "$iterations" =~ ^[0-9]+$ ]]; then
        echo "${RED}Error:${NC} iterations must be a number"
        show_usage
        exit 1
    fi
    
    # Setup
    print_header
    check_prompt_file
    cd "$PROJECT_ROOT"
    
    # Create logs directory if it doesn't exist
    mkdir -p "$LOGS_DIR"
    
    local logfile="$LOGS_DIR/ralph.${tool}.log"
    
    echo "${GREEN}Configuration:${NC}"
    echo "  Project Root:    $PROJECT_ROOT"
    echo "  Prompt File:     $PROMPT_FILE"
    echo "  Progress File:   $PROGRESS_FILE"
    echo "  Logs Directory:  $LOGS_DIR"
    echo "  Tool Logfile:    $logfile"
    echo "  Tool:            $tool"
    echo "  Iterations:      ${iterations:-∞}"
    echo ""
    
    # Initialize progress file if it doesn't exist
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        echo "# Ralph Wiggum Progress Log" > "$PROGRESS_FILE"
        echo "# Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
        echo "" >> "$PROGRESS_FILE"
    fi
    
    log_progress "=== Ralph session started with $tool ==="
    
    # Main loop
    local i=1
    local display_total=$iterations
    [[ "$iterations" == "0" ]] && display_total="∞"
    
    while true; do
        # Check if we've reached the iteration limit (0 = infinite)
        if [[ "$iterations" != "0" && $i -gt $iterations ]]; then
            break
        fi
        
        print_iteration $i "$display_total" "$tool"
        log_progress "--- Iteration $i started ---"
        
        # Run the agent - output shows live, captured to OUTPUT_FILE for completion check
        local start_time=$(date +%s)
        local exit_code=0
        
        $run_func || exit_code=$?
        
        if [[ $exit_code -ne 0 ]]; then
            echo "${RED}Agent exited with error (code $exit_code). Continuing to next iteration...${NC}"
            log_progress "Iteration $i: Error occurred (exit code $exit_code)"
        fi
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_progress "Iteration $i completed in ${duration}s"
        
        # Check for completion marker in captured output
        if [[ -f "$OUTPUT_FILE" ]] && grep -q "<promise>COMPLETE</promise>" "$OUTPUT_FILE"; then
            echo ""
            echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "${GREEN}  ✓ Iteration $i completed successfully${NC}"
            echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            log_progress "Iteration $i: Task completed successfully"
            
            # Check if ALL tasks in plan.json are done (all passes: true)
            if [[ -f "$PROJECT_ROOT/plan.json" ]]; then
                local pending_tasks=$(grep -c '"passes": false' "$PROJECT_ROOT/plan.json" 2>/dev/null || echo "0")
                if [[ "$pending_tasks" == "0" ]]; then
                    echo ""
                    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo "${GREEN}  🎉 PRD COMPLETE! All tasks in plan.json are done!${NC}"
                    echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    log_progress "PRD COMPLETE - All tasks done after $i iterations"
                    notify "PRD complete after $i iterations!"
                    break
                else
                    echo "${BLUE}  📋 $pending_tasks tasks remaining in plan.json${NC}"
                fi
            fi
        else
            echo ""
            echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "${YELLOW}  ⚠ Iteration $i ended without completion marker${NC}"
            echo "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            log_progress "Iteration $i: No completion marker detected"
        fi
        
        # Increment counter
        ((i++))
        
        # Delay between iterations
        if [[ "$iterations" == "0" ]] || [[ $i -le $iterations ]]; then
            echo ""
            echo "${BLUE}Waiting ${ITERATION_DELAY}s before next iteration...${NC}"
            sleep "$ITERATION_DELAY"
        fi
    done
    
    # Completion
    log_progress "=== Ralph session completed: $i iterations ==="
    
    echo ""
    echo "${GREEN}=============================================================================${NC}"
    echo "${GREEN}  Ralph Wiggum completed $i iterations${NC}"
    echo "${GREEN}=============================================================================${NC}"
    echo ""
    
    notify "Ralph completed $i iterations"
}

# Run main function
main "$@"
