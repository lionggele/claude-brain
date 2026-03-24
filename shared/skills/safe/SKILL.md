---
name: brain-safe
description: Safety mode. Hooks auto-block destructive commands (rm -rf, DROP TABLE, force push). Freeze restricts edits to one directory during debugging.
---

# Safe Mode

Safety hooks are auto-enabled on every role activation. No action needed.

## Freeze (restrict edits to a directory)

When user says "freeze to <dir>":
```bash
echo "$(cd "<dir>" && pwd)" > ~/.claude/brain/.local/freeze-dir.txt
```

When user says "unfreeze":
```bash
rm ~/.claude/brain/.local/freeze-dir.txt
```

## What careful blocks

rm -rf, DROP TABLE/DATABASE, git push --force, git reset --hard, git checkout ., git clean -f, git branch -D, kubectl delete, docker prune, chmod 777.

Safe exceptions (always allowed): node_modules, __pycache__, dist/, build/, .venv, htmlcov.
