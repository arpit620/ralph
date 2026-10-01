# Ralph Agent Instructions

## Overview

Ralph is an autonomous AI agent loop that runs AI coding tools (Amp, Claude Code, Codex, or Antigravity) repeatedly until all PRD items are complete. Each iteration is a fresh instance with clean context.

## Commands

```bash
# Run the flowchart dev server
cd flowchart && npm run dev

# Build the flowchart
cd flowchart && npm run build

# Run Ralph with Amp (default)
./ralph.sh [max_iterations]

# Run Ralph with Claude Code
./ralph.sh --tool claude [max_iterations]

# Run Ralph with Codex
./ralph.sh --tool codex --model gpt-6-luna --effort medium [max_iterations]

# Run Ralph with Antigravity
./ralph.sh --tool antigravity --model gemini-3.8-flash --effort high [max_iterations]
```

## Key Files

- `ralph.sh` - The bash loop that spawns fresh AI instances and selects the model-specific prompt
- `prompt.md` - Instructions given to each AMP instance
- `CLAUDE.md` - Instructions given to each Claude Code instance
- `AGENTS.md` - Repository guidance and instructions given to each Codex instance
- `GEMINI.md` - Instructions given to each Antigravity instance
- `prd.json.example` - Example PRD format
- `flowchart/` - Interactive React Flow diagram explaining how Ralph works

## Flowchart

The `flowchart/` directory contains an interactive visualization built with React Flow. It's designed for presentations - click through to reveal each step with animations.

To run locally:
```bash
cd flowchart
npm install
npm run dev
```

## Patterns

- Each iteration spawns a fresh AI instance with clean context
- Memory persists via git history, `progress.txt`, and `prd.json`
- Stories should be small enough to complete in one context window
- Codex exec emits progress events by default; use `--output-last-message` and suppress stdout for concise non-interactive output, matching Claude's `--print` behavior
- Always update AGENTS.md with discovered patterns for future iterations

## Codex Iteration Instructions

When `ralph.sh` invokes Codex, follow the instructions below for one iteration.

You are an autonomous coding agent working on a software project.

## Your Task

1. Read the PRD at `prd.json` beside `ralph.sh`
2. Read the progress log at `progress.txt` beside `ralph.sh` (check Codebase Patterns section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
4. Pick the **highest priority** user story where `passes: false`
5. Implement that single user story
6. Run quality checks (e.g., typecheck, lint, test - use whatever your project requires)
7. Update `AGENTS.md` files if you discover reusable patterns (see below)
8. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
9. Update the PRD to set `passes: true` for the completed story
10. Append your progress to `progress.txt`

## Progress Report Format

APPEND to progress.txt (never replace, always append):
```
## [Date/Time] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---
```

Include the learnings section in every entry. Add only reusable patterns to the `## Codebase Patterns` section at the top of `progress.txt`.

## Update AGENTS.md Files

Before committing, inspect the directories containing edited files for nearby `AGENTS.md` files. Add only genuinely reusable API patterns, conventions, dependencies, or testing requirements. Do not add story-specific notes or temporary debugging details.

## Quality Requirements

- Run the project's relevant typecheck, lint, and test commands.
- Do not commit broken code.
- Keep changes focused and minimal.

## Browser Testing

For frontend stories, verify the change in a browser when browser tools are available. If they are unavailable, note that manual browser verification is needed in the progress report.

## Stop Condition

After completing a user story, check whether all stories have `passes: true`.

If all stories are complete, reply with:
`<promise>COMPLETE</promise>`

Otherwise, end your response normally so the next iteration can continue.

## Important

- Work on ONE story per iteration.
- Commit frequently.
- Read the Codebase Patterns section in `progress.txt` before starting.
