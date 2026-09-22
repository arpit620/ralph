#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--tool amp|claude|codex|antigravity] [--model MODEL] [--effort EFFORT] [max_iterations]

set -e

# Parse arguments
TOOL="amp"  # Default to amp for backwards compatibility
MODEL=""
EFFORT=""
MAX_ITERATIONS=10

usage() {
  cat <<EOF
Usage: $0 [options] [max_iterations]

Options:
  --tool TOOL             amp, claude, codex, or antigravity (default: amp)
  --model MODEL           Model name passed to the selected CLI
  --effort EFFORT         Reasoning effort passed to the selected CLI
  --max-iterations N      Maximum number of iterations (default: 10)
  -h, --help              Show this help

The iteration count may also be supplied as a positional argument for
backwards compatibility.
EOF
}

require_value() {
  if [[ $# -lt 2 || -z "$2" ]]; then
    echo "Error: $1 requires a value." >&2
    usage >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      require_value "--tool" "$2"
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    --model)
      require_value "--model" "$2"
      MODEL="$2"
      shift 2
      ;;
    --model=*)
      MODEL="${1#*=}"
      [[ -n "$MODEL" ]] || { echo "Error: --model requires a value." >&2; exit 1; }
      shift
      ;;
    --effort)
      require_value "--effort" "$2"
      EFFORT="$2"
      shift 2
      ;;
    --effort=*)
      EFFORT="${1#*=}"
      [[ -n "$EFFORT" ]] || { echo "Error: --effort requires a value." >&2; exit 1; }
      shift
      ;;
    --max-iterations)
      require_value "--max-iterations" "$2"
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --max-iterations=*)
      MAX_ITERATIONS="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      else
        echo "Error: Unknown argument '$1'." >&2
        usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" && "$TOOL" != "codex" && "$TOOL" != "antigravity" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp', 'claude', 'codex', or 'antigravity'."
  exit 1
fi

if ! [[ "$MAX_ITERATIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: max iterations must be a positive integer, got '$MAX_ITERATIONS'." >&2
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    
    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"
    
    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph - Tool: $TOOL - Model: ${MODEL:-default} - Effort: ${EFFORT:-default} - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Run the selected tool with the ralph prompt
  case "$TOOL" in
    amp)
      # Amp accepts model and effort overrides in execute mode.
      CLI_ARGS=(--dangerously-allow-all)
      [[ -n "$MODEL" ]] && CLI_ARGS+=(--model "$MODEL")
      [[ -n "$EFFORT" ]] && CLI_ARGS+=(--effort "$EFFORT")
      OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | amp "${CLI_ARGS[@]}" 2>&1 | tee /dev/stderr) || true
      ;;
    claude)
      # Claude Code: use --dangerously-skip-permissions for autonomous operation, --print for output.
      CLI_ARGS=(--dangerously-skip-permissions --print)
      [[ -n "$MODEL" ]] && CLI_ARGS+=(--model "$MODEL")
      [[ -n "$EFFORT" ]] && CLI_ARGS+=(--effort "$EFFORT")
      OUTPUT=$(claude "${CLI_ARGS[@]}" < "$SCRIPT_DIR/CLAUDE.md" 2>&1 | tee /dev/stderr) || true
      ;;
    codex)
      # Codex emits progress/tool events during exec. Capture the final response
      # with --output-last-message so the terminal stays as concise as Claude's
      # --print mode, while retaining diagnostics for failed runs.
      CLI_ARGS=(exec --dangerously-bypass-approvals-and-sandbox)
      [[ -n "$MODEL" ]] && CLI_ARGS+=(--model "$MODEL")
      [[ -n "$EFFORT" ]] && CLI_ARGS+=(--config "model_reasoning_effort=\"$EFFORT\"")
      CODEX_OUTPUT_FILE=$(mktemp)
      CODEX_ERROR_FILE=$(mktemp)
      if codex "${CLI_ARGS[@]}" -o "$CODEX_OUTPUT_FILE" - < "$SCRIPT_DIR/CODEX.md" \
        > /dev/null 2> "$CODEX_ERROR_FILE"; then
        OUTPUT=$(cat "$CODEX_OUTPUT_FILE")
      else
        CODEX_STATUS=$?
        OUTPUT=$(cat "$CODEX_OUTPUT_FILE" 2>/dev/null || true)
        echo "Codex exited with status $CODEX_STATUS." >&2
        if [[ -s "$CODEX_ERROR_FILE" ]]; then
          tail -n 20 "$CODEX_ERROR_FILE" >&2
        fi
      fi
      rm -f "$CODEX_OUTPUT_FILE" "$CODEX_ERROR_FILE"
      if [[ -n "$OUTPUT" ]]; then
        printf '%s\n' "$OUTPUT"
      fi
      ;;
    antigravity)
      # Google's Antigravity CLI is installed as `agy` and uses print mode for automation.
      CLI_ARGS=(-p "$(cat "$SCRIPT_DIR/GEMINI.md")" --dangerously-skip-permissions)
      [[ -n "$MODEL" ]] && CLI_ARGS+=(--model "$MODEL")
      [[ -n "$EFFORT" ]] && CLI_ARGS+=(--effort "$EFFORT")
      OUTPUT=$(agy "${CLI_ARGS[@]}" 2>&1 | tee /dev/stderr) || true
      ;;
  esac
  
  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi
  
  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
