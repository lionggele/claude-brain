# Eval Guide

How to write eval criteria that actually improve your prompts instead of giving you false confidence.

---

## The golden rule

Every eval must be a yes/no question. Not a scale. Not a vibe check. Binary.

Why: Scales compound variability. If you have 4 evals scored 1-7, your total score has massive variance across runs. Binary evals give you a reliable signal.

---

## Good evals vs bad evals

### Text/copy skills (newsletters, tweets, emails, landing pages)

**Bad evals:**
- "Is the writing good?" (too vague)
- "Rate the engagement potential 1-10" (scale = unreliable)
- "Does it sound like a human?" (subjective, inconsistent)

**Good evals:**
- "Does the output contain zero phrases from this banned list: [game-changer, here's the kicker, the best part, level up]?" (binary, specific)
- "Does the opening sentence reference a specific time, place, or sensory detail?" (binary, checkable)
- "Is the output between 150-400 words?" (binary, measurable)
- "Does it end with a specific CTA that tells the reader exactly what to do next?" (binary, structural)

### Visual/design skills (diagrams, images, slides)

**Bad evals:**
- "Does it look professional?" (subjective)
- "Rate the visual quality 1-5" (scale)

**Good evals:**
- "Is all text in the image legible with no truncated or overlapping words?" (binary, specific)
- "Does the color palette use only soft/pastel tones?" (binary, checkable)
- "Is the layout linear — left-to-right or top-to-bottom?" (binary, structural)

### Code/technical skills

**Bad evals:**
- "Is the code clean?" (subjective)
- "Does it follow best practices?" (vague)

**Good evals:**
- "Does the code run without errors?" (binary, testable)
- "Does the output contain zero TODO or placeholder comments?" (binary, greppable)
- "Are all function and variable names descriptive (no single-letter names except loop counters)?" (binary, checkable)
- "Does the code include error handling for all external calls?" (binary, structural)

### Planning/document skills

**Bad evals:**
- "Is it comprehensive?" (compared to what?)

**Good evals:**
- "Does the document contain all required sections: [list them]?" (binary, structural)
- "Is every claim backed by a specific number, date, or source?" (binary, checkable)
- "Does the plan have between 3-7 checkbox tasks?" (binary, countable)

---

## Common mistakes

### 1. Too many evals
More than 6 and the prompt starts gaming them. Pick the 3-6 checks that matter most.

### 2. Too narrow/rigid
"Must contain exactly 3 bullet points" creates weird, stilted output. Check for qualities, not arbitrary constraints.

### 3. Overlapping evals
If eval 1 and eval 4 test the same thing, you're double-counting. Each eval should test something distinct.

### 4. Unmeasurable by an agent
"Would a human find this engaging?" — an agent can't reliably answer this. Translate subjective qualities into observable signals.

---

## The 3-question test

Before finalizing an eval:

1. **Could two different agents score the same output and agree?** If not, too subjective.
2. **Could a prompt game this eval without actually improving?** If yes, too narrow.
3. **Does this eval test something the user actually cares about?** If not, drop it.

---

## Template

```yaml
evals:
  - name: "Short name"
    question: "Yes/no question about the output"
    pass: "What yes looks like — one sentence, specific"
    fail: "What triggers no — one sentence, specific"
```
