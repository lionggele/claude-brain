# Project: CAD2BIM
Last updated: 2026-03-28

## Stack
- Backend: Python 3.11+ / FastAPI / Celery + Redis / PostgreSQL
- Frontend: React 19 / TanStack Router + Query / Konva.js (2D) / ThatOpen (3D IFC)
- CAD: ODA File Converter (DWG->DXF) / ezdxf / R-tree + KDTree
- AI: Anthropic Claude Sonnet (Interpreter Agent) / Vertex AI
- BIM: IfcOpenShell 0.8+ (IFC generation) / IfcTester (IDS validation)

## Architecture (as of 2026-03-28)
Governed semantic compiler with plan-driven authoring kernel:
```
DWG -> ODA -> DXF -> Normalize -> Detect (5 services) -> Build IR
  -> [optional] Agent Enrichment (Claude) -> PlanGenerator -> PlanExecutor -> IFC
```
Feature flags: USE_CANONICAL_IR, USE_AUTHORING_KERNEL, USE_DRAWING_INTELLIGENCE, AGENT_ENABLED

## Key Decisions
- 2026-03-28: Keep PlanGenerator + PlanExecutor over code generation (spike decision)
- 2026-03-28: Phase A redefined as 80% complete, focus on measurement gaps
- 2026-03-28: Continue with existing frontend (not new submodule client)
- 2026-03-25: 4-stage sequential pipeline (metadata -> spatial -> domain rules -> LLM)
- 2026-03-25: Agent is specialist for ambiguous 10%, not generalist

## Active Work
- Task queue: docs/superpowers/tasks/TRACKER.md
- Track 1: Backend hardening (IfcTester, source classification, normalizer, benchmarks)
- Track 2: Product polish (rebrand, auto-review, export, editing)

## Task Runner
- Run next task: `bash ~/.claude/brain/scripts/run-task.sh`
- Auto mode: `bash ~/.claude/brain/scripts/run-task.sh --auto`
- Task files: `docs/superpowers/tasks/T*.md`
- Tracker: `docs/superpowers/tasks/TRACKER.md`

## Gotchas
- Two frontends exist: `frontend/` (running app) and `cad2bim-frontend-client/` (submodule, not wired in)
- Feature flags default to False -- enable in .env for new pipeline
- files.py upload/download routes still lack CurrentUser authentication
- Normalizer doesn't auto-detect units (assumes mm)
- IfcTester IDS validation is stubbed (_validate_ids_stub)
