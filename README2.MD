# From your project root
mkdir -p scripts/ralph
cp /path/to/ralph/ralph.sh scripts/ralph/

# Copy the prompt templates used by the selected AI tool:
cp /path/to/ralph/prompt.md scripts/ralph/prompt.md    # Amp
cp /path/to/ralph/CLAUDE.md scripts/ralph/CLAUDE.md    # Claude Code
cp /path/to/ralph/CODEX.md scripts/ralph/CODEX.md      # Codex
cp /path/to/ralph/GEMINI.md scripts/ralph/GEMINI.md    # Antigravity

chmod +x scripts/ralph/ralph.sh

SKILL PATH: 
.agents/skills/<skill-name>/SKILL.md

cp -r skills/prd ~/.claude/skills/
cp -r skills/ralph ~/.claude/skills/


WORKFLOW: 
1. Load the prd skill and create a PRD for [your feature description]
2. Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
