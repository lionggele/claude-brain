---
name: capture-learning
description: Detect when the user corrects Claude and offer to save the learning to memory. Triggers on corrections like "no don't", "use X instead", "that's wrong", or confirmed good approaches.
---

# Capture Learning

When you detect the user is correcting your approach:

1. Acknowledge the correction briefly
2. Ask: "Should I save this as a learning? (It will apply to future sessions)"
3. If yes, determine the active role from the CLAUDE.md imports
4. Run: `bash ~/.claude/brain/scripts/capture-learning.sh --role <role> "<concise rule>. Why: <reason>"`
5. Confirm it was saved

## Detection Patterns
- "no, don't do that" -> save what NOT to do
- "use X instead of Y" -> save the preference
- "that's wrong because..." -> save the reasoning
- "always do X" / "never do Y" -> save the rule
- User accepts an unusual approach without pushback -> save what worked (positive learning)

## Format
Save as: `- **[YYYY-MM-DD]** <concise rule>. Why: <reason>`

## Examples
- `- **[2026-03-19]** Use execute_values for batch inserts, not row-by-row. Why: 11x faster through SSH tunnel.`
- `- **[2026-03-19]** Strip NUL bytes from all text before PostgreSQL insert. Why: PostgreSQL text fields reject \x00.`
