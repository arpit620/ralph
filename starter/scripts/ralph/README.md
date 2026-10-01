## 1. Create a PRD
```
Load the prd skill and create a PRD for [your feature description]
```

## 2. Convert PRD to Ralph format
```
Load the ralph skill and convert tasks/prd-[feature-name].md to prd.json
```

## 3. Run Ralph

```bash
# Using Codex
./scripts/ralph/ralph.sh --tool codex [max_iterations]

# Using Google Antigravity CLI
./scripts/ralph/ralph.sh --tool antigravity [max_iterations]


# Codex: pass a model identifier supported by your Codex installation
./scripts/ralph/ralph.sh --tool codex --model gpt-6-luna --effort medium 10

# Antigravity: use a model slug shown by `agy models`
./scripts/ralph/ralph.sh --tool antigravity --model gemini-3.5-flash-medium 10
```

To enable Codex fast service tier, add `--fast`:

```bash
./scripts/ralph/ralph.sh --tool codex --model gpt-5.6-sol --fast 10
```

`--fast` defaults to false and is only supported with `--tool codex`. It passes `--config 'service_tier="fast"'` to Codex.
