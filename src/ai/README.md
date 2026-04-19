# Dotfiles AI Context

## How It Works

```
GLOBAL.md --> languages/ + tasks/ --> wiki/ (on-prompt)
```

### GLOBAL.md

Read at start of every conversation. Contains:

- Definitions (wiki, dotfiles wiki)
- Wiki maintenance rules
- Core rules (prioritize, avoid, patterns, practices)

### languages/

Language-specific conventions. Read when working in that language.

- python.md
- typescript.md
- cpp.md

### tasks/

Task-specific guidance. Read when doing that task.

- testing.md
- code_reviews.md
- communication.md
- cli.md
- playwright.md

### wiki/

Business context (projects, desks, trading). Use grep to search.

- desks/
- projects/
- trading/

Read only when I mention a specific project, desk, or trading topic.

