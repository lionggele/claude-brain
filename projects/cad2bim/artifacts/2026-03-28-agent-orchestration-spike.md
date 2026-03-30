# Spike: Agent Orchestration — Retry Loop vs LangGraph vs Single-Pass
Date: 2026-03-28
Status: Decided

## Question
Should CAD2BIM add agent retry/validation feedback loops? The master plan v2 describes a triple validation loop, but the current pipeline is single-pass (no retry on quality failures).

## Options Considered

### Option A: Simple Retry Loop (RECOMMENDED)
- How: After IFC generation, validate. If issues, feed validation errors back to InterpreterAgent as augmented context. Re-enrich IR. Max 2 retries.
- Pros: 3-5 days work, catches 40-50% of failures, reuses existing agent code, falls back safely to original IR
- Cons: Not a full state machine, limited to single-agent reasoning

### Option B: Full LangGraph Migration
- How: Replace Celery task chain with LangGraph state machine. Multiple agents (Interpreter, Reviewer). Full message history.
- Pros: Scales to multi-agent, state persistence, industry-standard pattern (used in excelQ already)
- Cons: 2-3 weeks, rewrites working pipeline, overkill for one agent doing one thing

### Option C: Keep Single-Pass (Defer)
- How: No changes. Ship Phase A as-is, add retry in Phase B.
- Pros: Zero effort, no risk of breaking working pipeline
- Cons: IFC quality issues go undetected until human review, no metrics on agent performance

## Decision
**Option A: Simple Retry Loop** -- Added as task T16 in the task queue.

The pattern:
```
IR → Agent Enrichment → PlanGenerator → PlanExecutor → IFC
                                                        ↓
                                                   Validate IFC
                                                   ↓           ↓
                                              PASS: deliver   FAIL: feed errors
                                                              back to Agent (max 2x)
```

## Consequences
- T16 task added to backend hardening track
- Validation results stored in job metadata (visible in frontend later)
- Agent attempt metrics tracked (attempts, tool_calls, validation_results)
- No LangGraph dependency added
- Foundation for Phase B multi-agent if needed

## Revisit If
- >30% of drawings need 3+ retry attempts after processing 50+ real drawings
- Need to add a second agent type (e.g., Reviewer agent for code quality)
- LangGraph becomes a project dependency for other reasons
