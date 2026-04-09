# Memory Wiki

## How It Works

This is a three-stage context loading system for AI agents.

```
Agent Config (CLAUDE.md, etc.)
        |
        v
   context.md
        |
        v
    index.md  -->  topic files (only as needed)
```

### 1. Agent-Specific Config

Each AI tool has its own config file (e.g. `~/.claude/CLAUDE.md`) that acts as the entrypoint. Its only job is to point the agent to `context.md` as a mandatory first step.

### 2. context.md

Defines global rules and key definitions (like what "memory wiki" means). Forces the agent to read `index.md` next.

### 3. index.md

A compact index of all context files organized by topic. The agent reads only the files relevant to the current task, keeping context usage minimal.

Topic files live alongside `index.md` (general conventions) or in subdirectories (project/desk-specific knowledge).
