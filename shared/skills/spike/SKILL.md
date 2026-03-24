---
name: brain-spike
description: Run a time-boxed research spike to evaluate options, compare approaches, and produce a decision document. Use when facing architectural decisions, technology choices, or unknown problem spaces before committing to implementation.
---

# Spike (Time-boxed Research)

When the user faces a decision with multiple valid approaches:

## Step 1: Frame the Spike

```
QUESTION: What specific decision needs to be made?
TIME BOX: 15-30 minutes of research (not days)
OPTIONS: 2-4 concrete alternatives to evaluate
CRITERIA: What matters? (performance, cost, complexity, team familiarity)
```

Ask the user to confirm these before researching.

## Step 2: Research Each Option

For each option, gather:

1. **How it works** (1-2 sentences)
2. **Pros** (3-5 bullet points)
3. **Cons** (3-5 bullet points)
4. **Effort estimate** (hours/days)
5. **Risk** (what could go wrong)

Use web search, documentation, and codebase analysis. Do NOT guess.

## Step 3: Build Comparison Matrix

```markdown
| Criteria (weight) | Option A | Option B | Option C |
|---|---|---|---|
| Performance (high) | Good | Best | Medium |
| Implementation effort (high) | 2 days | 5 days | 1 day |
| Team familiarity (medium) | High | Low | Medium |
| Maintenance burden (medium) | Low | High | Low |
| Vendor lock-in (low) | None | AWS-specific | None |
```

## Step 4: Make a Recommendation

State clearly:
- **Recommended**: Option X
- **Why**: 1-2 sentences explaining the trade-off
- **When to reconsider**: Under what conditions should we revisit this

## Step 5: Save as Artifact

Save the decision document for future sessions:

```bash
DATE=$(date +%Y-%m-%d)
PROJECT=$(basename "$(pwd)")
ARTIFACTS_DIR="$HOME/.claude/brain/projects/$PROJECT/artifacts"
mkdir -p "$ARTIFACTS_DIR"
```

Save to: `~/.claude/brain/projects/<project>/artifacts/YYYY-MM-DD-<topic>.md`

### Decision Document Template

```markdown
# Spike: <Topic>
Date: YYYY-MM-DD
Status: Decided

## Question
<What decision needed to be made?>

## Options Considered
### Option A: <name>
- How: ...
- Pros: ...
- Cons: ...

### Option B: <name>
- How: ...
- Pros: ...
- Cons: ...

## Decision
<Which option and why>

## Consequences
- <What follows from this decision>
- <What we're giving up>

## Revisit If
- <Conditions that would make us reconsider>
```

## When to Spike

- New database technology
- Build vs buy decision
- Framework selection
- Architecture pattern (monolith vs microservices)
- Cloud service selection (which queue, which cache)
- AI model selection (which embedding model, which LLM)

## When NOT to Spike

- You already know the answer
- The decision is easily reversible
- The cost of experimentation is low (just try it)
