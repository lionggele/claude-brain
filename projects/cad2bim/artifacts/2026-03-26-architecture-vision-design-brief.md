# CAD2BIM: Architecture, Vision & Design Brief
Date: 2026-03-26
Status: Active
Audience: Project Manager, Solution Architect, Senior Fullstack Engineer, UI/UX Designer

---

# Executive Summary (1 Page)

## The Problem
Structural engineers manually redraw CAD floor plans in Revit to create BIM models. This takes **8-40 hours per drawing** and is error-prone. There is no polished, web-native tool that automates this conversion with visual confidence feedback.

## The Solution
CAD2BIM uses AI-powered detection to automatically identify structural elements (walls, columns, grids, doors, windows) from CAD drawings and generate IFC files (open BIM format) for import into Revit, ArchiCAD, and Navisworks.

## Current State (POC v1 — Live)
- Upload DXF/DWG -> automated 8-stage detection pipeline
- 2D review with entity overlay + confidence scores
- 3D IFC viewer with click-to-select element inspection
- IFC file generation and download
- **332 elements detected** in a real production drawing with 77% average confidence

## Market Opportunity
- **No competitor** offers an interactive, web-native CAD-to-BIM conversion tool with visual confidence display
- Existing tools (DDC, CADBIMconverter) are CLI/pipeline focused — no interactive review
- Target: AEC firms doing 50+ BIM conversions/year (estimated 5,000+ firms globally)

## v2 Vision: "From Detection to Correction"
Enable users to **review, correct, and refine** detection results before generating BIM. Key additions: auto-review based on confidence, side-by-side comparison view, multi-format export.

## Resource Ask
- 1 Senior Fullstack Engineer (full-time, 17+ weeks)
- 1 UI/UX Designer (part-time, 4-6 weeks front-loaded)
- 1 Backend Engineer (50% allocation for entity editing APIs)

## Target Timeline
- **v2-alpha** (P0 features): 4-5 weeks from start
- **v2-beta** (P0 + P1 phase 1): 10-12 weeks from start
- **v2-GA** (P0 + P1 complete): 16-18 weeks from start

---

# Glossary

| Term | Plain English |
|------|--------------|
| **IFC** | Industry Foundation Classes — open file format for BIM models. Can be imported into Revit, ArchiCAD, Navisworks |
| **DXF/DWG** | AutoCAD drawing file formats — the input files users upload |
| **RVT** | Revit project file — native Autodesk format (requires APS license to generate) |
| **BIM** | Building Information Modeling — 3D model with metadata about building elements |
| **IR** | Intermediate Representation — our internal data format that holds detected elements, their confidence scores, and relationships. Think of it as the "brain" of the detection results |
| **APS** | Autodesk Platform Services — Autodesk's cloud API (required for RVT export) |
| **BCF** | BIM Collaboration Format — standard format for sharing review comments with 3D camera positions |
| **WebGL/WASM** | Browser technologies for 3D rendering (WebGL) and high-performance computation (WASM). Enable the 3D viewer without plugins |
| **Celery** | Background task queue — runs long processing jobs (detection, IFC generation) without blocking the web server |
| **WebSocket** | Real-time browser-server connection — enables instant updates instead of polling every 2 seconds |
| **Confidence score** | 0-100% probability that a detected element is correctly classified (e.g., "this is a wall with 77% confidence") |

---

# Part 1: Technical Architecture Overview
*For: Senior Fullstack Engineer*

## System Summary

CAD2BIM is a web application that converts CAD drawings (DXF/DWG) into BIM models (IFC/RVT). Users upload a CAD file, the backend runs a multi-stage pipeline (sanitize -> extract -> normalize -> detect -> enrich -> preview -> review -> generate), and the frontend visualizes results at each stage.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | React | 19.x |
| Router | TanStack Router | 1.142.x (file-based) |
| Server State | TanStack Query | 5.90.x |
| Forms | React Hook Form + Zod | 7.68 / 3.24 |
| UI Components | shadcn/ui (Radix UI) | Latest |
| Styling | Tailwind CSS | 4.1.x |
| 2D Canvas | Konva + react-konva | 10.2 / 19.2 |
| 3D Viewer | @thatopen/components | 3.3.x |
| Build | Vite | 7.3.x |
| Package Manager | Bun | 1.3.x (workspace) |
| Lint/Format | Biome | 2.3.x |
| Testing | Vitest + Testing Library + Playwright | 4.1 / 16.3 / 1.57 |

## Architecture Diagram

```
Browser
  |
  +-- TanStack Router (11 routes, file-based)
  |     |-- Public: /login, /signup, /recover-password, /reset-password
  |     |-- Protected (_layout): /, /cad2bim, /cad2bim/$jobId, /cad2bim/history
  |     |-- Admin: /admin, /items, /settings
  |
  +-- TanStack Query (server state)
  |     |-- jobKeys factory: status, preview, ir, intelligence, validation, history
  |     |-- Auto-polling: 2s for active jobs, 5s for history
  |     |-- Global error handler: 401/403 -> logout
  |
  +-- Components
  |     |-- CAD2BIM/ (16 domain components)
  |     |     |-- FileUploadDialog -> create job -> upload -> start pipeline
  |     |     |-- JobStatusCard -> progress bar + state machine display
  |     |     |-- CanvasViewer -> 2D Konva canvas (entities on preview image)
  |     |     |-- IFCViewer -> 3D @thatopen viewer (click-to-select)
  |     |     |-- ElementInspectorPanel -> confidence, evidence, properties
  |     |     |-- ReviewApprovalPanel -> approve/reject workflow
  |     |     |-- ConfidenceFilter -> slider + type toggles
  |     |     |-- GenerateBIMTab -> IFC generation + 3D preview
  |     |     |-- IntelligencePanel, AgentReasoningPanel, ValidationPanel
  |     |     |-- NormalizationTab, JobHistoryCard, JobHistoryFilters
  |     |     |-- DetectionConfidence, EntityDetailsModal
  |     |
  |     |-- ui/ (27 shadcn components)
  |     |-- Common/ (ErrorComponent, NotFound, DataTable, Logo)
  |     |-- Admin/, Items/, UserSettings/, Sidebar/
  |
  +-- API Client
  |     |-- Generated: LoginService, UsersService, ItemsService (from OpenAPI)
  |     |-- Manual: JobsService (custom, TODO: migrate to generated)
  |     |-- Auth: JWT in localStorage, OpenAPI.TOKEN async resolver
  |
  +-- Hooks
        |-- use-jobs.ts: 6 queries + 5 mutations + 1 workflow
        |-- use-ifc-data.ts: IR -> inspector lookup (memoized)
        |-- useAuth.ts: login, signup, logout, current user
```

## Data Flow: Upload to 3D Preview

```
1. FileUploadDialog
   -> useCreateJob() -> POST /api/v1/jobs
   -> useUploadFile() -> PUT presigned URL
   -> useStartJob() -> POST /api/v1/jobs/{id}/start
   -> navigate to /cad2bim/$jobId

2. JobDetail (cad2bim.$jobId.tsx)
   -> useJobStatus(jobId) polls every 2s
   -> State machine: UPLOADED -> SANITIZING -> ... -> COMPLETED
   -> Progress bar updates in real-time

3. Review Tab (when DETECTED+)
   -> useJobPreview(jobId) -> preview image + detected entities
   -> CanvasViewer renders 2D overlay
   -> ReviewApprovalPanel allows approve/reject

4. Generate BIM Tab (when REVIEWED+)
   -> Click "Generate IFC" -> JobsService.startIfcGeneration()
   -> Parent page (cad2bim.$jobId.tsx) owns useJobStatus polling
   -> Polls until IFC_GENERATED -> COMPLETED, passes ifcUrl as prop
   -> GenerateBIMTab receives ifcUrl, renders IFCViewer (lazy-loaded)
   -> IFCViewer loads IFC via @thatopen/components
   -> Click element -> Highlighter selects -> read Name property
   -> Match Name to IR nodeId -> ElementInspectorPanel shows details
```

## Key Architecture Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| State management | TanStack Query only (no Redux/Zustand) | Server state is the source of truth; polling handles real-time |
| IFC viewer | @thatopen/components | MIT license, active, built-in selection. Replaced deprecated web-ifc-viewer |
| Code splitting | React.lazy() for IFCViewer + CanvasViewer | ~5MB 3D libs loaded on-demand, route chunk ~79KB (approx, as of March 2026) |
| API client | Hybrid (generated + manual JobsService) | OpenAPI spec out of sync; manual service for job endpoints |
| Auth | JWT in localStorage | Simple, works for POC. No refresh tokens yet |
| CORS | Nginx proxy (/api/) + Vite dev proxy | Same-origin requests, no CORS headers needed |

## Technical Debt

| Item | Severity | Impact |
|------|----------|--------|
| Manual JobsService not generated from OpenAPI | Medium | Types can drift from backend |
| No refresh token flow | Medium | Token expires, user must re-login |
| No E2E tests for CAD2BIM flow | High | Core feature untested end-to-end |
| Job state arrays duplicated in 4+ places | Low | Maintenance burden |
| CanvasViewer.tsx at ~710 lines | Low | Should extract entity rendering |
| No WebSocket for real-time updates | Low | Polling at 2s/3s/5s intervals is adequate for current user base |
| Large IFC files (>50MB) may crash browser | Medium | WebGL/WASM memory limits; need file size validation |
| JWT in localStorage vulnerable to XSS | Medium | Must upgrade to httpOnly cookies before collaboration features |
| No upload rate limiting | Medium | Malicious user could queue hundreds of jobs |
| IFC URL validation too permissive | Low | Allows any *.amazonaws.com — should restrict to specific bucket |
| Three.js caret range (^0.183) could break @thatopen | Low | Pin to exact version matching peer dependency |

---

# Part 2: Product Vision - Next Iteration
*For: Product + Engineering alignment*

## Current State (POC v1)

**What works today:**
- Upload DXF/DWG -> multi-stage processing pipeline
- 2D preview with detected entities overlaid on image
- Review & approve detected elements
- Generate IFC file with walls, columns, grids, doors, windows
- 3D IFC viewer with click-to-select and element inspection
- Confidence filtering by type and threshold
- Job history with status tracking

**What's missing for production:**
1. No batch processing (one file at a time)
2. No element editing (can't correct wrong detections)
3. No version comparison (can't compare before/after)
4. No collaboration (single user, no sharing)
5. No export to Revit directly (IFC only, RVT requires APS)
6. No undo/redo in review
7. No notification system (must poll for status)

## Vision: Next Iteration (v2)

### Theme: "From Detection to Correction"

The POC proves the detection pipeline works. The next iteration should focus on **letting users correct and refine** the detection results before generating BIM.

### Priority Features

#### P0: Must Have (high ROI, feasible now)
1. **Confidence-Based Auto-Review**
   - High confidence (>85%) -> auto-approve
   - Medium (50-85%) -> flag for review
   - Low (<50%) -> highlight as "needs attention"
   - Reduce manual review work by 60%+
   - *Effort: ~3-5 days. Data already exists in IR nodes.*

2. **Comparison View**
   - Side-by-side: original CAD vs detected elements
   - Overlay mode: toggle detected entities on/off
   - Diff view: show what changed between runs
   - *Effort: ~1 week. Data exists (preview image + entities). Mostly layout work.*

3. **Export Options**
   - IFC4 (current), IFC2x3 (legacy compatibility)
   - CSV/JSON element list
   - PDF report with detection summary
   - *Effort: ~1 week. Backend-focused, low frontend effort.*

#### P1: Should Have (higher effort, phased)
4. **Element Editing in 2D Canvas (Phase 1: Reclassify + Delete)**
   - Click entity -> change type via dropdown, delete with X
   - No geometry editing yet (no drag handles)
   - *Effort: ~1-2 weeks. Requires new PATCH/DELETE backend endpoints + IR mutation.*
   - *RISK: Backend must support IR mutation and re-generation. This is the hardest backend work.*

5. **Batch Upload**
   - Upload multiple DWG files at once
   - Queue processing, parallel where possible
   - Batch job history view
   - *Effort: ~1-2 weeks.*

6. **Real-time Processing Updates (WebSocket)**
   - WebSocket connection for job state changes
   - Replace 2s polling with instant updates
   - *Effort: ~2 weeks. Requires WS endpoint, reconnection logic, TanStack Query integration.*
   - *NOTE: 2s polling is adequate for current user base. This is an optimization, not a blocker.*

#### P2: Nice to Have
7. **Element Editing Phase 2 (Geometry Editing)**
   - Drag handles on walls/grids to adjust position
   - Draw tool: add new entity manually
   - Undo/redo stack
   - *Effort: 3-4 weeks. Essentially a mini-CAD editor. Requires custom Konva transformer.*

8. **Collaboration**
   - Share job with team members
   - Comments on specific elements
   - *PREREQUISITE: Auth must be upgraded to httpOnly cookies with refresh tokens before this.*

9. **Template System + Analytics Dashboard**
   - Save detection rules per drawing type
   - Detection accuracy trends, processing time charts
   - *Effort: ~2-3 weeks. Needs lightweight charting lib (lazy-loaded, <500KB).*

## Technical Architecture for v2

### New Components Needed

| Component | Purpose | Complexity |
|-----------|---------|------------|
| `ElementEditor` | In-canvas editing with drag handles | High |
| `ComparisonView` | Side-by-side/overlay/diff modes | Medium |
| `BatchUploader` | Multi-file upload queue | Medium |
| `WebSocketProvider` | Real-time state updates | Medium |
| `ExportDialog` | Multi-format export options | Low |
| `NotificationCenter` | Toast + persistent notifications | Low |
| `AnalyticsDashboard` | Charts (Recharts/Chart.js) | Medium |

### Backend API Additions Needed

| Endpoint | Purpose | Effort | Risk |
|----------|---------|--------|------|
| `PATCH /jobs/{id}/entities/{entity_id}` | Edit entity type/geometry | High | Must mutate IR and propagate to IFC re-generation |
| `POST /jobs/{id}/entities` | Add new entity | High | Same IR mutation complexity |
| `DELETE /jobs/{id}/entities/{entity_id}` | Remove entity | Medium | Simpler than edit, but still needs IR update |
| `POST /jobs/{id}/batch` | Batch upload/process | Medium | Queue management, parallel Celery tasks |
| `GET /jobs/{id}/diff` | Comparison data | Low | Read-only, diff existing data |
| `WS /ws/jobs/{id}` | Real-time status updates | Medium | FastAPI WebSocket, auth handshake, reconnection |
| `POST /jobs/{id}/export` | Multi-format export | Low-Medium | IFC2x3 via ifcopenshell, CSV trivial, PDF via reportlab |

**Critical backend risk:** Entity editing (PATCH/POST/DELETE) requires an IR mutation system. Currently the IR is a read-only JSON blob stored on the job. Editing requires: (1) deserialize IR, (2) apply edit, (3) re-serialize, (4) optionally re-generate IFC. This is the hardest backend work in v2.

### Recommended Library Stack for v2

| Category | Current | Recommended for v2 | Size (gzip) | Rationale |
|----------|---------|-------------------|-------------|-----------|
| 2D Canvas | react-konva (Konva) | **Fabric.js** | ~90KB | Built-in drag handles, selection, resize, rotate. Eliminates weeks of building custom interaction from scratch. Konva requires manual implementation. |
| 3D Viewer | @thatopen/components | **Keep @thatopen** | ~920KB (lazy) | Working now with click-to-select. No need to change. |
| Charts | (none) | **Recharts** | ~42KB | Largest React charting community. Tree-shakable. Bar/pie/line for BIM analytics dashboard. |
| PDF Reports | (none) | **@react-pdf/renderer** | ~80KB | Declarative JSX-based reports. Professional BIM reports with element schedules, confidence summaries, embedded floor plan images. |
| File Upload | (custom dialog) | **react-dropzone** (now) / **react-uploady** (batch) | 4KB / 20KB | Drop zone for POC. Upgrade to react-uploady for production batch upload with progress tracking. |
| UI Foundation | shadcn/ui | **Keep shadcn/ui** | Already in stack | No AEC-specific React design system worth switching to. Build AEC-specific components on top. |

**Note on Fabric.js migration:** This is a P1 task tied to Element Editing. The current Konva-based CanvasViewer works for read-only 2D preview and review. Fabric.js should only be introduced when we build the editing feature — not before. Don't carry two canvas libraries simultaneously.

**Bundle budget:** Each new library must be lazy-loaded. Target: <500KB gzip per route chunk. The charts and PDF libraries should only load when the user visits Analytics or triggers Export.

### User Stories & Acceptance Criteria

#### P0.1: Confidence-Based Auto-Review
**User Story:** As a structural engineer, I want high-confidence elements auto-approved so I only review elements the AI is unsure about.
**Acceptance Criteria:**
- [ ] Elements with confidence >85% are auto-approved (shown with green badge)
- [ ] Elements 50-85% are flagged "Needs Review" (shown with yellow badge)
- [ ] Elements <50% are flagged "Needs Attention" (shown with red badge)
- [ ] "Approve All High-Confidence" button approves all >85% elements in one click
- [ ] Review progress shows "X of Y elements reviewed"
- [ ] Baseline metric: measure current time-to-approve vs. with auto-review

#### P0.2: Comparison View
**User Story:** As a BIM manager, I want to compare the original CAD drawing with detected elements side-by-side so I can visually verify detection quality.
**Acceptance Criteria:**
- [ ] Side-by-side layout: original CAD image (left) vs detected elements overlay (right)
- [ ] Toggle mode: detected entities on/off on the original image
- [ ] Entity count summary shown for both views
- [ ] Works with existing preview image and detected_entities data

#### P0.3: Export Options
**User Story:** As a structural engineer, I want to export detection results in multiple formats so I can share them with my team and import into different tools.
**Acceptance Criteria:**
- [ ] IFC4 export (current — already works)
- [ ] CSV export: element_id, type, confidence, coordinates, properties
- [ ] JSON export: full IR data dump
- [ ] PDF report: summary page + element schedule table + floor plan image with overlays
- [ ] Download button with format selection dropdown

#### P1.4: Element Editing (Phase 1)
**User Story:** As a structural engineer, I want to correct detection errors by changing element types or removing false detections, so the generated BIM model is accurate.
**Acceptance Criteria:**
- [ ] Click element -> dropdown to change type (wall, column, grid, door, window)
- [ ] Click element -> delete button removes it from detection results
- [ ] Changes persist to backend via PATCH/DELETE API
- [ ] IR is updated; re-generation uses corrected data
- [ ] Undo last action button

### Dependency Graph

```
                    ┌──────────────┐
                    │   DESIGN     │
                    │  Wireframes  │
                    │  (4-6 weeks) │
                    └──────┬───────┘
                           │ informs
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌──────────┐    ┌──────────┐    ┌──────────┐
   │ P0.1     │    │ P0.2     │    │ P0.3     │
   │ Auto-    │    │ Compare  │    │ Export   │
   │ Review   │    │ View     │    │ Options  │
   │ (FE+BE)  │    │ (FE only)│    │ (BE+FE) │
   │ 5 days   │    │ 5 days   │    │ 5 days   │
   └──────────┘    └──────────┘    └──────────┘
        │                               │
        │ P0 all complete               │
        ▼                               ▼
   ┌──────────┐                  ┌──────────┐
   │ P1.4     │◄─── BLOCKS ────│ OpenAPI  │
   │ Element  │                  │ Sync     │
   │ Editing  │                  │ (BE, 3d) │
   │ (FE+BE)  │                  └──────────┘
   │ 2 weeks  │
   └──────────┘
        │
        ▼
   ┌──────────┐    ┌──────────┐
   │ P1.5     │    │ P1.6     │
   │ Batch    │    │ WebSocket│
   │ Upload   │    │ (FE+BE)  │
   │ 2 weeks  │    │ 2 weeks  │
   └──────────┘    └──────────┘
        │
        ▼
   ┌──────────┐    ┌──────────┐
   │ P2.7     │    │ P2.8     │◄── BLOCKS ── Auth upgrade (httpOnly cookies)
   │ Geometry │    │ Collab   │
   │ Editing  │    │          │
   │ 4 weeks  │    │          │
   └──────────┘    └──────────┘

PARALLEL WORKSTREAMS:
  - P0.1, P0.2, P0.3 can ALL run in parallel (no dependencies between them)
  - Design work must START 1 sprint ahead of engineering for P0.2, P1.4
  - Backend engineer can work on P0.3 export + OpenAPI sync while FE does P0.1 + P0.2
```

**Critical path:** Design -> P0 (3 weeks) -> OpenAPI sync (3 days) -> P1.4 Element Editing (2 weeks) -> P2.7 Geometry Editing (4 weeks)

### Sprint Plan (2-week sprints)

| Sprint | Duration | FE Engineer | BE Engineer | Designer | Milestone |
|--------|----------|-------------|-------------|----------|-----------|
| **0** | Weeks 1-2 | Bug fixes from v1, prep | OpenAPI spec sync | Wireframes for P0.2 + P0.3 | Design kickoff |
| **1** | Weeks 3-4 | P0.1 Auto-Review (FE) + P0.2 Comparison View | P0.3 Export (CSV/JSON/PDF backend) | Wireframes for P1.4 Element Editor | -- |
| **2** | Weeks 5-6 | P0.3 Export (FE) + polish | P0.1 Auto-Review (BE threshold logic) | Interaction spec for Element Editor | **v2-alpha: P0 complete** |
| **3** | Weeks 7-8 | P1.4 Element Editing (FE: reclassify + delete) | P1.4 Element Editing (BE: PATCH/DELETE endpoints, IR mutation) | Wireframes for batch upload | -- |
| **4** | Weeks 9-10 | P1.4 integration testing + P1.5 Batch Upload (FE) | P1.5 Batch Upload (BE: queue, parallel Celery) | Responsive layouts | **v2-beta: P0 + P1 phase 1** |
| **5** | Weeks 11-12 | P1.6 WebSocket (FE) + polish | P1.6 WebSocket (BE) + auth hardening | -- | -- |
| **6-8** | Weeks 13-18 | P2.7 Geometry Editing (Fabric.js migration) | P2.8 Collaboration (if auth ready) | Analytics dashboard wireframes | **v2-GA** |

**Buffer:** Add 30% to all estimates. Real timeline: ~20-23 weeks with buffer.

### Risk Matrix (Business Terms)

| Risk | Likelihood | Business Impact | Mitigation | Owner |
|------|-----------|-----------------|------------|-------|
| IR mutation system takes longer than 2 weeks | High | Delays Element Editing (core v2 differentiator) by 2-4 weeks | Spike first (2 days). If >3 weeks, simplify to type-change only (no geometry) | BE Lead |
| Large files (>50MB) crash browser | Medium | Users with complex drawings can't use the tool. Support tickets. | Add file size validation + warning. Investigate streaming loader. | FE Lead |
| JWT token stolen via XSS | Low | Full account compromise. Blocks collaboration feature. | Upgrade to httpOnly cookies before collaboration ships (3-5 days) | BE Lead |
| Designer unavailable for 4-6 weeks | Medium | All P1+ features delayed (no wireframes). | Start P0 with simple layouts (comparison view is straightforward). Hire contract designer. | PM |
| @thatopen/components library issues | Medium | 3D viewer bugs. StrictMode errors in dev. | Already have fallback (element list selection works). Monitor library releases. | FE Lead |
| Backend engineer not allocated 50% | High | P0.3 Export and P1.4 Entity Editing blocked | Shift backend tasks right. FE can mock APIs temporarily. | PM |

### Success Metrics (KPIs)

| Metric | Baseline (v1) | Target (v2) | How to Measure |
|--------|--------------|-------------|----------------|
| Time to approve all elements | ~15 min (manual, all 332) | <5 min (with auto-review) | Time from entering Review tab to clicking Approve |
| User corrections per job | Unknown | Track: avg corrections per job | Count PATCH/DELETE API calls per job |
| Detection accuracy | 77% avg confidence | 85%+ (with user feedback loop) | Avg confidence after corrections |
| Time to first IFC | ~3 min (upload to download) | <2 min (with WebSocket) | End-to-end timing |
| File formats exported | 1 (IFC4 only) | 4 (IFC4, IFC2x3, CSV, PDF) | Feature availability |
| Onboarding completion | Unknown | 80% of new users complete sample project | Checklist completion tracking |

---

# Part 3: Design Brief
*For: UI/UX Designer*

## App Context

CAD2BIM helps structural engineers convert 2D CAD floor plans into 3D BIM models. The user uploads a DWG file, the system detects walls/columns/grids/doors, and generates an IFC file that can be imported into Revit or ArchiCAD.

## Current UI Overview

**11 screens, 5 key workflows:**

1. **Upload** -> File dialog with drag-and-drop
2. **Pipeline Monitor** -> 18-state progress bar with tab navigation
3. **2D Review** -> Canvas overlay with entity list sidebar
4. **3D Preview** -> WebGL viewer with inspector panel
5. **Job History** -> Card grid with status filters

## User Personas

### Primary: Structural Engineer (Alex, 32)
- Uses AutoCAD daily, knows DWG/DXF well
- Needs to convert floor plans to BIM for coordination
- Frustrated by manual redrawing in Revit
- Wants: fast, accurate, minimal manual correction
- Tech comfort: Medium (uses specialized CAD tools, not a developer)

### Secondary: BIM Manager (Sarah, 38)
- Manages BIM standards for the firm
- Reviews model quality before coordination
- Needs: batch processing, quality metrics, export options
- Tech comfort: High (power user of multiple tools)

## Design Priorities

### 1. Simplify the Pipeline View
**Problem:** 18 states in the pipeline is overwhelming. Users don't care about SANITIZING vs SANITIZED.
**Ask:** Design a simplified 4-step progress indicator:
- Upload -> Processing -> Review -> Done
- Show sub-steps only on hover/expand
- Animate transitions between steps

### 2. Redesign the Review Experience
**Problem:** The Review tab has a 2D canvas on the left and nothing interactive on the right until they approve.
**Ask:** Design an interactive review workflow:
- Split view: 2D preview (left) + element list (right)
- Click entity in list -> highlight on canvas (and vice versa)
- Inline editing: change type via dropdown, delete with X button
- Batch actions: "Approve all high-confidence" button
- Progress indicator: "42 of 332 elements reviewed"

### 3. Unify 2D and 3D Views
**Problem:** 2D canvas (Review tab) and 3D viewer (Generate BIM tab) are separate tabs. Users can't easily compare.
**Ask:** Design a unified viewer with:
- Toggle: 2D / 3D / Split view
- Same element selection works in both views
- Inspector panel stays consistent across views
- Confidence heat map overlay option

**TECHNICAL CONSTRAINT:** The 3D IFC viewer requires an IFC file which is only available AFTER the user clicks "Generate IFC" (post-review). The unified viewer must show 3D as disabled/empty until generation completes. Default to tabbed view; split 2D+3D has GPU contention on low-end machines. Element sync between 2D and 3D is best-effort (matched by element name, not pixel-perfect).

### 4. Improve the Job History Page
**Problem:** Currently a flat grid of cards. No way to organize or search.
**Ask:** Design a better history experience:
- Table view option (not just cards)
- Search by filename
- Folder/project grouping
- Bulk actions (delete, re-process, export)
- Status timeline for each job

### 5. Design an Element Editor
**Problem:** Users can't correct detection errors. If a wall is detected as a column, they have to regenerate.
**Ask:** Design editing tools for the 2D canvas:
- Select tool: click to select entity
- Edit tool: drag handles to adjust geometry
- Type tool: change entity classification
- Draw tool: add new entity manually
- Toolbar at top of canvas (like a simple drawing app)
- Undo/redo buttons

### 6. Mobile/Tablet Consideration
**Problem:** Engineers sometimes review on iPads at job sites.
**Ask:** Ensure these work on tablet:
- Job status monitoring (read-only)
- Element list review (approve/reject)
- 3D viewer (touch gestures for rotate/zoom)
- NOT needed on mobile: file upload, element editing

## Design System Notes

**Current system:** shadcn/ui (Radix primitives + Tailwind)
- Consistent button styles (outline, default, destructive)
- Card-based layouts
- Dark mode supported
- Color palette: blue primary, status colors (green/yellow/red)

**Please maintain:**
- shadcn/ui component patterns (don't introduce new component library)
- Tailwind utility classes for all HTML/DOM elements
- Dark mode compatibility (uses `next-themes` with `dark:` Tailwind variants)
- Existing color semantics (green=high confidence, yellow=medium, red=low)

**CRITICAL: Canvas & 3D rendering constraints:**
- The 2D canvas (Konva) renders to `<canvas>` — NOT HTML. Text is bitmap, no CSS, no accessibility on canvas content. Toolbar/panel chrome uses Tailwind, but canvas internals are pixel-level.
- The 3D viewer (WebGL/@thatopen) also renders to `<canvas>`. You cannot overlay HTML inside it — overlays must be absolutely positioned on top.
- Undo/redo for canvas editing must be built from scratch (Konva has no built-in history stack).
- Performance degrades past ~5000 shapes on canvas. Complex CAD drawings may hit this.
- Touch events on Konva work but multi-touch (pinch-to-zoom) requires explicit configuration.
- Each new visualization library (charts, PDF export) must be lazy-loaded. Target: <500KB per route chunk.

**Free to redesign:**
- Layout proportions and spacing
- Information hierarchy
- Navigation patterns (sidebar vs top nav)
- Data density (current UI is sparse)
- Iconography (currently uses Lucide icons)

## Key Screens to Redesign (Priority Order)

1. **Job Detail Page** (most complex, most used)
   - Current: 5 tabs, each with different layout
   - Goal: Unified experience, reduce tab-switching

2. **Review + Inspector** (core workflow)
   - Current: Separate 2D and 3D views
   - Goal: Unified viewer with editing

3. **Job History** (entry point)
   - Current: Simple card grid
   - Goal: Searchable, filterable, project-grouped

4. **Upload Flow** (first impression)
   - Current: Dialog modal
   - Goal: Drag-and-drop zone with batch support

5. **Dashboard** (currently bare)
   - Current: Just "Hi, username"
   - Goal: Recent jobs, processing stats, quick upload

## Deliverables Expected

1. **Wireframes** for the 5 key screens above
2. **Component audit** of existing shadcn/ui components (what to keep/extend/replace)
3. **Interaction spec** for element editing in the canvas
4. **Mobile/tablet responsive** layouts for read-only views
5. **Design tokens** update if new colors/spacing needed

## Reference Applications

For inspiration, look at:
- **Speckle** (speckle.systems) — BIM model viewer with element selection, filtering, computational bucketing
- **BIMcollab** — BIM collaboration, issue management with 3D-pinned comments
- **Bluebeam Revu** — PDF/CAD review with markup tools
- **Trimble Connect** — Multiple hierarchy views (spatial, system, assembly)
- **Figma** — Canvas editing UX (selection, drag, toolbar), branch-based reviews
- **Linear** — Clean project management UI (for job history inspiration)
- **GitHub PR reviews** — Three-state review (approve, request changes, comment)

---

# Part 4: BIM/AEC UX Best Practices & Research Findings
*For: UI/UX Designer + Senior Engineer — research-backed recommendations*

## Market Gap: CAD2BIM Opportunity

There is NO polished web application for interactive CAD-to-BIM conversion with visual confidence display. Existing tools (DDC, CADBIMconverter) are pipeline/CLI focused. CAD2BIM can be first-to-market with an interactive, visual, web-native conversion experience.

## Top 10 Actionable UX Recommendations

### 1. Dedicated Filter Panel (Left Sidebar)
**Pattern source:** Speckle's advanced filtering
- Full-height left panel for filters (separate from model tree)
- Multi-property filtering: "show me all doors on Level 1 with confidence < 70%"
- Operators: is, is not, is set, is between, greater than, less than
- Filters apply instantly with visual feedback in the viewport
- "Add as filter" shortcut directly from the inspector panel

### 2. Color-by-Confidence as First-Class Feature
**Pattern source:** Speckle's computational bucketing
- Color every 3D element by its confidence score using a gradient colormap
- **Use viridis or blue-orange palette** (colorblind-safe, perceptually uniform)
- **Never rely on red-green alone** — 8% of males are red-green colorblind
- Elements grouped into range-based bins, each rendered as a distinct color
- Makes spatial distribution of detection quality immediately visible
- Pair every color with a numeric badge on hover

### 3. Three-Tier Dashboard with Progressive Disclosure
**Pattern source:** Engineering dashboard research (reduces cognitive load ~37%)

| Tier | Content | Interaction |
|------|---------|-------------|
| Level 1 (Top) | 3-5 KPI cards: total elements, avg confidence, conversion status | Always visible |
| Level 2 (Middle) | Category breakdown: walls, columns, doors, grids by confidence band | Expandable sections |
| Level 3 (Detail) | Individual element properties, raw IR data, export | On-demand panel |

- Use card-based layout with strategic whitespace
- Most critical data at top, drill-down below

### 4. Multiple Hierarchy Views
**Pattern source:** Trimble Connect organizer
- **Spatial view:** Project > Building > Storey > Space > Element
- **By type:** IfcWall, IfcColumn, IfcDoor, IfcGrid (grouped)
- **By confidence:** High (>85%), Medium (50-85%), Low (<50%)
- Switchable via tabs at the top of the tree panel
- Single entity can appear in multiple views simultaneously

### 5. Three-State Review Workflow
**Pattern source:** GitHub PR reviews + BIMcollab issues

| Action | Effect | Use When |
|--------|--------|----------|
| **Approve** | Marks elements as accepted, enables IFC generation | High confidence, correct classification |
| **Request Changes** | Blocks progress, creates a review task | Wrong type, needs editing |
| **Comment** | Adds note without changing status | Questions, observations |

- Comments pinned to specific 3D elements (not just global)
- Each comment carries camera position + visible elements (BCF-like viewpoint)
- Reviewer is teleported to exact 3D location when viewing a comment

### 6. Confidence Threshold Slider (Key Differentiator)
**Pattern source:** Object detection UX (YOLO confidence thresholding)
- Interactive slider controlling minimum confidence for displayed elements
- **Already implemented** in CAD2BIM — enhance with:
  - Histogram showing confidence distribution above the slider
  - Count of elements at each confidence level
  - "Quick set" buttons: Show All, High Only, Needs Review

### 7. Element Isolation in 3D Viewer
**Pattern source:** xeokit, Speckle, all major BIM viewers

| Mode | Behavior | Use Case |
|------|----------|----------|
| **X-ray** | Selected opaque, rest transparent | Inspect element in context |
| **Isolate** | Selected visible, rest hidden | Focus on one element |
| **Ghost** | Selected opaque, rest wireframe | See structure through walls |
| **Section** | Clip plane slices model | Reveal internal structure |

- Right-click context menu on any element: Isolate, Hide, X-ray, Zoom to
- Toggle in toolbar: Select / X-ray / Section modes

### 8. Pre-loaded Sample Project for Onboarding
**Pattern source:** Figma, Notion, Speckle
- Ship with a sample building DWG with pre-detected elements
- Interactive empty state: "Try our sample project" + "Upload your DWG"
- 3-5 contextual tooltips on first visit (NOT a modal tour)
- Checklist widget: "Upload first file", "Explore 3D viewer", "Filter by type", "Export IFC"
- Goal: user sees detected elements in 3D within 30 seconds of landing

### 9. Accessibility by Default
**Pattern source:** Carbon Design System, WCAG guidelines
- **Color + text**: Every color-coded element also has a text/number label
- **Colorblind mode toggle**: Switch from viridis to high-contrast patterns
- **Keyboard navigation**: Tab through element list, Enter to select, Escape to deselect
- **Screen reader**: Announce selected element type and confidence
- **Test with**: Color Quest or Coblis colorblind simulator

### 10. Smart Issues (BIMcollab Pattern)
**Pattern source:** BIMcollab issue management
- Each review issue carries: element reference, camera position, visible elements, description, assignee, status
- Prevents duplicate issue reports (system checks if an issue already exists for that element)
- Issue status flow: Open > In Progress > Resolved > Closed
- Kanban board view for tracking all review items
- *This is a P2 feature but design for it now — the comment/review data model should support it*

## Standard BIM Viewer Layout (Adopt This)

```
+------------------+--------------------------------+------------------+
| Left Panel       |        Center Viewport         | Right Panel      |
| (Collapsible)    |                                | (Collapsible)    |
|                  |                                |                  |
| Model Tree       |   3D/2D Viewer                 | Inspector        |
| - Spatial view   |   [Toolbar: Select/X-ray/      | - Element type   |
| - By type        |    Section/Measure/Reset]       | - Confidence %   |
| - By confidence  |                                | - Evidence       |
|                  |   [Model renders here]          | - Properties     |
| Filters          |                                | - Relationships  |
| - Confidence     |                                | - Provenance     |
| - Element type   |                                |                  |
| - Layer          |   [Status bar: coordinates,    | Review Actions   |
| - Detection      |    element count, FPS]          | - Approve        |
|   method         |                                | - Request Change |
|                  |                                | - Comment        |
+------------------+--------------------------------+------------------+
| Bottom Bar: Job status, pipeline progress, notifications            |
+---------------------------------------------------------------------+
```

## Color Palette Recommendations

| Use | Current | Recommended | Why |
|-----|---------|-------------|-----|
| High confidence | Green (#22c55e) | **Blue (#3b82f6)** or keep green with text label | Colorblind-accessible with text pairing |
| Medium confidence | Yellow (#eab308) | **Amber (#f59e0b)** | Better contrast in dark mode |
| Low confidence | Red (#ef4444) | **Orange-red (#f97316)** with pattern | Avoid pure red — pair with striped pattern for colorblind |
| Selected element | Blue (#3b82f6) | **Keep blue** | Works in both light/dark mode |
| 3D confidence heatmap | (none) | **Viridis palette** (yellow-teal-blue) | Perceptually uniform, colorblind-safe |
| Element types | Current per-type colors | **Keep but add icons** | Color + icon = two channels |

## Source-to-Implementation Mapping

This table maps each research source's strength to a **specific technical implementation** in our stack.

### Speckle (3D Viewer + Filtering + Color Bucketing)

| What Speckle Does | What We Take | How We Implement It | Effort | Sprint |
|-------------------|-------------|-------------------|--------|--------|
| Model tree auto-scrolls to selected element | Left panel element list syncs with 3D selection | In `GenerateBIMTab`: when `selectedNodeId` changes, scroll the element list to that item using `scrollIntoView()` | 2 hours | Sprint 1 |
| "Add as filter" from property panel | Quick-filter button in `ElementInspectorPanel` | Add a "Filter by this type" button next to element type. Calls `onVisibleTypesChange` on `ConfidenceFilter` | 4 hours | Sprint 1 |
| Computational bucketing: color elements by numeric property | Color-by-confidence on 3D model | In `IFCViewer`: after loading, iterate `fragments.list`, read each element's Name -> look up confidence from IR -> apply `Highlighter` material with viridis color mapped to confidence. Use `THREE.Color.lerpColors()` for gradient. | 1-2 days | Sprint 2 |
| Multi-property filter panel | Dedicated filter sidebar component | New component `<FilterPanel>`: uses existing `ConfidenceFilterState` + adds layer filter, detection method filter. Each filter is a shadcn/ui `<Select>`. Filters compose with AND logic. | 3 days | Sprint 2 |

### Trimble Connect (Hierarchy + Organization)

| What Trimble Does | What We Take | How We Implement It | Effort | Sprint |
|-------------------|-------------|-------------------|--------|--------|
| Multiple simultaneous hierarchies (spatial, assembly, system) | Three tree views: by type, by confidence, by layer | New component `<ElementTree>` with tabs. Data source: `allElements` from `useIFCData`. Group by `elementType` (tab 1), by confidence band (tab 2), by `provenance.source_layers[0]` (tab 3). Use shadcn `<Tabs>` + recursive `<Collapsible>`. | 2-3 days | Sprint 2 |
| Organizer service for custom groupings | User-defined groupings (future) | Backend: new `organizer` field on job metadata. Frontend: drag elements into groups. **P2 — design for it in data model, don't build yet.** | -- | P2 |

### BIMcollab (Issue Management + BCF Viewpoints)

| What BIMcollab Does | What We Take | How We Implement It | Effort | Sprint |
|--------------------|-------------|-------------------|--------|--------|
| Issues pinned to 3D locations with camera position | Review comments carry camera state | Extend the review data model: each comment stores `{ elementId, cameraPosition: {x,y,z}, cameraTarget: {x,y,z}, visibleElements: string[] }`. On click, restore camera via `world.camera.controls.setLookAt(...)`. | 3-4 days | Sprint 3 |
| Duplicate issue prevention | Check if element already has a review comment | Before creating a comment, query existing comments for same `elementId`. Show "This element already has a comment" warning. | 4 hours | Sprint 3 |
| Issue status flow: Open > In Progress > Resolved > Closed | Review item status tracking | New `ReviewItem` type: `{ id, elementId, status: 'open'|'in_progress'|'resolved'|'closed', comment, assignee }`. Backend: CRUD API. Frontend: kanban board using existing card components. **P2 — design data model now.** | -- | P2 |

### GitHub PR Reviews (Three-State Review)

| What GitHub Does | What We Take | How We Implement It | Effort | Sprint |
|-----------------|-------------|-------------------|--------|--------|
| Approve / Request Changes / Comment | Three review actions per element | Modify `ReviewApprovalPanel`: replace single "Approve All" with per-element actions. Each entity in the list gets a dropdown: Approve (green check), Request Change (yellow flag), Comment (blue speech bubble). Bulk action: "Approve all high-confidence". | 2-3 days | Sprint 1 |
| Review summary submitted as batch | Batch submit all review decisions | Add "Submit Review" button that sends all decisions in one API call: `POST /jobs/{id}/review { decisions: [{entityId, action, comment}] }`. Backend processes as batch. | 1-2 days | Sprint 1 |

### Figma (Onboarding + Canvas Editing)

| What Figma Does | What We Take | How We Implement It | Effort | Sprint |
|----------------|-------------|-------------------|--------|--------|
| Animated onboarding tooltips | 3-5 contextual tooltips on first visit | Use `@radix-ui/react-tooltip` (already in stack via shadcn). Track `hasSeenOnboarding` in localStorage. Show tooltips on: (1) Upload button, (2) 3D viewer, (3) Confidence slider, (4) Element list, (5) Export button. Auto-dismiss after interaction. | 1 day | Sprint 2 |
| Pre-loaded sample project | Sample DWG with pre-detected elements | Bundle a small sample DWG + pre-computed detection results (IR JSON + preview image) in `public/sample/`. On empty state, show "Try our sample" button that navigates to `/cad2bim/sample` with pre-loaded data (no backend processing needed). | 1 day | Sprint 2 |
| Object selection + transform handles in canvas | Element editing with Fabric.js | When building P1.4: replace Konva with Fabric.js for the edit mode. Fabric.js `object:selected` event -> show type dropdown. `object:modified` event -> send PATCH to backend. Fabric.js built-in handles for resize/rotate. | 2 weeks | Sprint 3-4 |

### Carbon Design System (Accessibility)

| What Carbon Does | What We Take | How We Implement It | Effort | Sprint |
|-----------------|-------------|-------------------|--------|--------|
| Status indicator pattern (color + icon + text) | Triple-channel confidence display | Every confidence badge shows: (1) colored dot, (2) label text ("High"/"Medium"/"Low"), (3) percentage number. Already partially done in `ElementInspectorPanel` — extend to element list and 3D overlay. | 4 hours | Sprint 1 |
| Colorblind-safe palette | Viridis palette for heatmaps | Use `d3-scale-chromatic` viridis interpolator (tree-shakable, ~2KB). Map confidence 0-1 to viridis color. Add toggle in settings: "Colorblind mode" that switches to high-contrast patterns (striped/dotted fills on canvas). | 1 day | Sprint 2 |

### xeokit (3D Viewer Modes)

| What xeokit Does | What We Take | How We Implement It | Effort | Sprint |
|-----------------|-------------|-------------------|--------|--------|
| X-ray mode (selected opaque, rest transparent) | Element isolation in @thatopen viewer | `@thatopen/components-front` `Highlighter` already supports custom materials. Add an "X-ray" button: set all non-selected elements to `MeshBasicMaterial({ opacity: 0.1, transparent: true })`. Reset on deselect. | 1 day | Sprint 2 |
| Section planes | Clipping plane in 3D viewer | `@thatopen/components` has a `Clipper` component. Setup: `components.get(OBF.Clipper)`, add a "Section" button to toolbar. Click to place section plane, drag to move. | 2-3 days | Sprint 4+ |
| Measurement tools | Point-to-point distance | `@thatopen/components` has built-in `LengthMeasurement`. Add a "Measure" button to toolbar. Click two points -> shows distance. **P2 feature.** | -- | P2 |

## Total Effort Summary from Research Sources

| Source | Features Adopted | Total Effort | Priority |
|--------|-----------------|-------------|----------|
| **Speckle** | Auto-scroll, quick filter, color bucketing, filter panel | ~5 days | P0-P1 |
| **GitHub PR** | Three-state review, batch submit | ~4 days | P0 |
| **Figma** | Onboarding tooltips, sample project, canvas editing | 2 days (onboarding) + 2 weeks (editing) | P0 (onboarding), P1 (editing) |
| **Carbon** | Triple-channel indicators, viridis palette | ~1.5 days | P0 |
| **Trimble** | Multi-hierarchy tree views | ~3 days | P1 |
| **BIMcollab** | Pinned comments with camera, issue tracking | ~4 days (comments) + P2 (kanban) | P1 (comments), P2 (kanban) |
| **xeokit** | X-ray mode, section planes, measurements | 1 day (X-ray) + 3 days (section) + P2 (measure) | P1 (X-ray), P2 (section, measure) |

**Total incremental effort from research: ~20 days (4 weeks)** spread across Sprints 1-4, integrated into existing feature work.

## Research Sources (Full List)

- Speckle: Redesigned 3D viewer, advanced filtering, computational bucketing
- Trimble Connect: Model hierarchies, organizer service
- BIMcollab: Issue management, BCF viewpoints, measurement tools
- Autodesk ACC: Unified platform, 3D-pinned issues
- DataDrivenConstruction: AI element classification pipelines
- Engineering Dashboard Patterns: Progressive disclosure, card-based layout
- Carbon Design System: Status indicator patterns, accessibility
- GitHub: PR review model (approve/request changes/comment)
- Figma: Branch reviews, animated onboarding, Design Review Notes
- WCAG / Colorblind-safe palettes: Viridis, blue-orange sequential
- xeokit: BIM viewer modes (X-ray, section, measurement)
- WCAG / Colorblind-safe palettes: Viridis, blue-orange sequential
