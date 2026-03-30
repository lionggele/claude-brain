# Spike: CAD2BIM Architecture Divergence & Phase A Completion Strategy
Date: 2026-03-28
Status: Decided

## Question
The v1.5 consolidated plan describes architecture X, but the codebase implements architecture Y. Should we align the plan to the code, the code to the plan, or chart a new path? Plus: what blocks Phase A, which frontend to target, and how do sprint tasks fit the roadmap?

## Decision 1: Keep PlanGenerator + PlanExecutor (Don't Revert to Code Generation)

### Option A: Revert to plan (Programmer agent generates Python code)
- How: Build RestrictedPython sandbox, Programmer agent, Reviewer agent, LangGraph state machine
- Pros: Matches the v1.5 consolidated plan exactly
- Cons: 3-4 weeks of work to build what was explicitly designed OUT. Code generation is non-deterministic. Sandbox is a security surface. LangGraph adds complexity.
- Risk: Code generation success rate is 40-60% on first attempt (plan's own estimate)

### Option B: Keep current architecture (PlanGenerator + PlanExecutor)
- How: Update the plan to reflect what's built. IR -> deterministic PlanGenerator -> typed PlanExecutor -> IFC
- Pros: Already working. Deterministic output. No sandbox needed. Inspectable plans. Actually matches Phase D vision arrived early.
- Cons: Less flexible than code generation for edge cases. Plan needs rewriting.
- Risk: May need code generation later for truly novel element types (mitigated by tool factory in Phase E)

### Option C: Hybrid (deterministic plan + LLM fallback for unknown elements)
- How: Keep current path as primary. Add optional LLM code-gen for elements the plan schema can't express.
- Pros: Best of both. Deterministic for 95% of cases, flexible for 5%.
- Cons: More complex. Defers the 5% problem.

**Decision: Option B** -- Keep current architecture. The codebase leapfrogged from Phase A to Phase D architecture. This is better, not worse. Update the plan.

**Revisit if:** IFC defect rate > 15% after processing 50+ drawings, or encounter element types that can't be expressed as plan operations.

## Decision 2: Redefine Phase A as "Mostly Complete, Close Gaps"

### What Phase A required (plan)
- Benchmark corpus (20 files, annotated) -- NOT DONE
- F1 measurement -- NOT DONE
- IfcTester/IDS validation -- STUBBED
- Source classification (Tier A/B/C) -- PARTIAL (Tier B only)
- ODA integration -- DONE
- 15 tool functions -- 7 primitives (different architecture)
- LangGraph pipeline -- NOT DONE (not needed)
- End-to-end test on 20 files -- NOT DONE

### What's actually built (beyond Phase A)
- Canonical IR with evidence + provenance (Phase D item)
- Deterministic plan executor (Phase D item)
- Interpreter agent with ReAct tools (Phase A+)
- Drawing intelligence (not in original plan)
- Feature flags for gradual rollout
- Proven on real architectural DWG (75 walls, 33 columns, 3 doors, 7 windows)

**Decision:** Redefine phases based on reality. Phase A is 80% complete. Remaining gaps are measurement infrastructure, not pipeline functionality. Close the gaps, don't re-build what works.

**Remaining Phase A gaps (priority order):**
1. IfcTester integration (Governance Rule #3) -- 2-3 days
2. Source classification runtime (Governance Rule #2) -- 2 days
3. Normalizer completion (unit auto-detection, origin shift) -- 3-5 days
4. Benchmark corpus assembly (20 files, annotated) -- 1-2 weeks
5. F1 measurement tooling -- 2-3 days

## Decision 3: Continue with OLD Frontend, Plan Gradual Migration

### Option A: Switch to new frontend client now
- Pros: Better workspace UX, cleaner component architecture
- Cons: Missing admin, agent reasoning, validation panels. Not wired into monorepo. Would delay product work by 2+ weeks.

### Option B: Continue with old frontend, migrate incrementally
- Pros: Everything works today. Can ship features immediately. Migrate components one at a time.
- Cons: Old frontend has technical debt (tab-based vs workspace layout)

### Option C: Dual frontend (old for admin, new for workspace)
- Pros: Best UX for each use case
- Cons: Two codebases to maintain. Confusing for users.

**Decision: Option B** -- Continue with old frontend. The new client is a design exploration, not production-ready. Backport the best UX ideas (workspace layout, ReviewBar, bulk approve) into the existing frontend.

**Revisit if:** Starting fresh frontend sprint with >2 week budget.

## Decision 4: Sprint Tasks = "Product Polish" Track (Parallel with Backend Hardening)

The sprint task lists (solo + team) describe:
- Sprint 0: Rebrand + demo polish (1 week)
- Sprint 1: Auto-review + comparison view (2 weeks)
- Sprint 2: Export + onboarding + color-by-confidence (2 weeks)
- Sprint 3: Element editing phase 1 (2 weeks)

These map to Phase C (make it a product) in the consolidated plan, NOT Phase A gaps.

**Decision:** The consolidated plan should have TWO parallel tracks:
1. **Backend Hardening** -- Close Phase A gaps (IfcTester, source classification, normalizer, benchmark)
2. **Product Polish** -- Sprint 0-3 frontend work (rebrand, auto-review, export, editing)

These can run in parallel because they're independent.

## Consequences
- The consolidated plan reflects actual architecture, not aspirational v1.5 plan
- Phase A is redefined with realistic scope
- Frontend work targets the existing codebase
- Sprint tasks are integrated as a parallel product track
- The master-plan-v2.md remains as long-term vision (Phase D/E)
