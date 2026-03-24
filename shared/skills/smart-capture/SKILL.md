---
name: brain-smart-capture
description: Detect user corrections and save them as confidence-scored learnings that evolve over time. Replaces basic capture-learning with an instinct-like system where repeated corrections auto-promote into permanent rules. Triggers on corrections like "no don't", "use X instead", "that's wrong", or confirmed good approaches.
---

# Smart Capture (Confidence-Scored Learning)

When you detect the user correcting your approach, capture it as a scored learning.

## Detection Patterns

- "no, don't do that" -> save what NOT to do
- "use X instead of Y" -> save the preference
- "that's wrong because..." -> save the reasoning
- "always do X" / "never do Y" -> save the rule
- User accepts an unusual approach without pushback -> positive learning
- Same correction appears again -> INCREASE confidence

## Confidence Levels

```
[0.1-0.3] tentative  - Seen once, might be situational
[0.4-0.6] growing    - Seen 2-3 times, likely a real pattern
[0.7-0.8] confident  - Seen 4+ times, consistent preference
[0.9-1.0] rule       - Auto-promote to role CLAUDE.md rules
```

## Capture Format

Save to corrections.md with this format:

```
- [0.3 tentative] Use batch inserts for >100 rows. Why: perf. (seen 1x, 2026-03-24)
- [0.7 confident] Always use execute_values not executemany. Why: 10x faster. (seen 4x, last: 2026-03-24)
- [0.9 rule] Strip NUL bytes before PostgreSQL insert. Why: crashes text fields. (seen 8x, last: 2026-03-24)
```

## Workflow

### When a NEW correction is detected:

1. Acknowledge briefly
2. Check if a similar learning already exists in corrections.md
3. If exists: bump the confidence by 0.15 and update "seen Nx" count
4. If new: add with confidence 0.3 (tentative)
5. Run the capture script:

```bash
bash ~/.claude/brain/scripts/smart-capture.sh \
  --role <role> \
  --confidence 0.3 \
  --seen 1 \
  "<concise rule>. Why: <reason>"
```

### When confidence reaches 0.9 (auto-promote):

1. Notify the user: "This learning has been confirmed 6+ times. Promoting to permanent rule."
2. Add the rule to the role's CLAUDE.md under `## Auto-Promoted Rules`
3. Remove it from corrections.md (it's now a rule, not a learning)

```bash
bash ~/.claude/brain/scripts/smart-capture.sh \
  --role backend \
  --promote \
  "Always use execute_values for batch inserts"
```

## Reading Learnings

When starting a session, read both:
1. `~/.claude/brain/shared/memory/corrections.md` (global)
2. `~/.claude/brain/roles/<active-role>/memory/corrections.md` (role-specific)

Prioritize high-confidence learnings (0.7+) in your behavior.

## Examples of Confidence Evolution

```
Session 1: User says "use logging, not print"
  -> [0.3 tentative] Use logging module, not print(). (seen 1x)

Session 3: User says "I told you, no print statements"
  -> [0.45 growing] Use logging module, not print(). (seen 2x)

Session 5: User corrects print() again
  -> [0.6 growing] Use logging module, not print(). (seen 3x)

Session 8: Same correction
  -> [0.75 confident] Use logging module, not print(). (seen 4x)

Session 12: Same again
  -> [0.9 rule] PROMOTED -> Added to CLAUDE.md rules
```

## Key Principle

The correction matters more than the mistake. If the user corrects you, the learning is real even if you don't fully understand why yet. Save it at tentative and let repetition validate it.
