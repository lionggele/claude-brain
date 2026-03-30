# Spike: Phase B Implementation Strategy
Date: 2026-03-29
Status: Decided

## Question
How to implement Phase B (rule-based improvements + ML infrastructure) for CAD2BIM detection pipeline?

## Current Detection Gaps (from audit)

### Critical gaps addressable by rule-based improvements:
1. **No wall adjacency graph** -- walls detected individually, no topology (T-junctions, L-corners, crosses)
2. **Door-window ambiguity** -- 700-1200mm range exclusion bug (gaps excluded from windows even when door score < 0.3)
3. **No per-entity confidence** -- walls/grids/columns have binary detection, no quality score
4. **Single-line walls missed** -- only parallel pair detection, no centerline-only walls
5. **Column false positives** -- all circles treated as columns (annotation circles, swing arcs)
6. **No curved wall detection** -- arcs ignored entirely

### Gaps requiring ML:
7. **Semantic labeling at scale** -- rule-based can't label 50K primitives efficiently
8. **Generalization** -- rules break on non-standard conventions
9. **Novel element types** -- stairs, ramps, MEP not detectable by rules

## Options Considered

### Option A: Rule-Based First, Then ML (RECOMMENDED)
- Phase B1 (2-3 weeks): Wall adjacency graph, door-window fix, per-entity confidence, column filtering
- Phase B2 (3-4 weeks): SymPoint setup, DXF→point cloud converter, training, inference API
- How: NetworkX wall graph → topology-enhanced door/window detection → confidence scoring → ML as evidence layer
- Pros: Immediate F1 improvement without GPU cost, ML has better ground truth to learn from, can measure rule-based baseline before ML
- Cons: ML delayed by 2-3 weeks
- Effort: ~5-7 weeks total

### Option B: ML First
- Straight to SymPoint training and inference
- Pros: ML will eventually be better than rules
- Cons: Need GPU ($2-3/hr), FloorPlanCAD is Chinese residential (may not generalize), rules still needed as fallback, no topology information from ML
- Risk: ML doesn't beat rules on our drawings, wasted 3-4 weeks

### Option C: Hybrid Simultaneous
- Run rule-based improvements AND ML setup in parallel
- Pros: Fastest total timeline
- Cons: Need 2 parallel workstreams, integration complexity, rules may conflict with ML labels
- Effort: Same calendar time but 2x concurrent work

## Decision
**Option A: Rule-Based First, Then ML**

### Phase B1: Rule-Based Improvements (2-3 weeks)
1. **Wall adjacency graph via NetworkX** -- T-junctions, L-corners, cross intersections
2. **Fix door-window ambiguity** -- only exclude gaps with door_score >= 0.3
3. **Per-entity confidence scoring** -- multi-signal confidence for all element types
4. **Column filtering** -- radius bounds, proximity to grid intersections, exclude arcs
5. **Improved polyline handling** -- vertex artifact removal
6. **Single-line wall detection** -- detect walls drawn as centerlines with thickness annotation

### Phase B2: ML Infrastructure (3-4 weeks)
1. **SymPoint reproduction** -- Clone nicehuster/SymPoint, reproduce FloorPlanCAD results
2. **DXF→point cloud converter** -- Convert DXF entities to SymPoint input format
3. **Fine-tune on benchmark corpus** -- Use our 50-file annotated corpus
4. **Inference API** -- TorchServe or simple FastAPI endpoint
5. **IR integration** -- ML labels merged as additional evidence on IR nodes
6. **A/B test** -- Compare rule-based vs ML vs combined on benchmark

### SymPoint Technical Requirements
- **Repo:** github.com/nicehuster/SymPoint (MIT license)
- **Training:** Single A100 GPU (~$2-3/hr cloud, ~8-12 hrs = $16-36)
- **Dataset:** FloorPlanCAD (primary), our benchmark corpus (fine-tune)
- **Input:** Point cloud from DXF (x,y coordinates + features)
- **Output:** Per-primitive semantic label + confidence score
- **PQ target:** 83.3% on FloorPlanCAD, 70%+ on our drawings
- **Inference:** ~1-3 seconds per drawing (GPU), 10-30 seconds (CPU)
- **Serving:** TorchServe or Triton for production, simple HTTP for POC

### Integration Architecture
```
Detection Pipeline (Phase B):
  DXF → Normalizer → [Rule-Based Detection] → IR (partial, rule-based evidence)
                    → [ML Detection]         → ML labels (per-primitive)
                    → [Evidence Merger]       → IR (combined evidence)
                    → [Agent Enrichment]      → IR (final)
```

ML labels don't replace rule-based -- they ADD evidence. The IR merger uses confidence-weighted fusion:
- Rule says "wall" (0.7) + ML says "wall" (0.85) → combined confidence higher
- Rule says "wall" (0.7) + ML says "not wall" (0.1) → flagged for review
- ML says "door" (0.9) + Rule didn't detect → ML-only detection added with moderate confidence

## Consequences
- Rule-based F1 improves immediately (wall adjacency is the biggest single improvement)
- ML infrastructure deferred 2-3 weeks but benefits from better ground truth
- GPU cost is modest (~$20-40 for initial training)
- No dependency on external ML infrastructure for Phase B1

## Revisit If
- Rule-based F1 reaches 75%+ without ML (may deprioritize ML)
- SymPoint doesn't reproduce on FloorPlanCAD (evaluate VectorGraphNET instead)
- GPU access is blocked (use VectorGraphNET which is lighter)
