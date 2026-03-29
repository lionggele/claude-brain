# Agent Notes

This repo uses the Ralph loop (`loop.sh` + `PROMPT_*.md`) to iterate on changes safely.

## Repo Map
<!-- List key directories and what they contain -->

## Common Commands

### Ralph Loop
- Plan: `./loop.sh plan`
- Scoped plan: `WORK_SCOPE="Add X" ./loop.sh plan-work`
- Build (default): `./loop.sh [max]`
- Build unattended: `./loop.sh auto [max]`
- Autoresearch: `./loop.sh autoresearch plan`

### Project
<!-- Install / run / test / lint / build commands go here -->

## Conventions
<!-- Branching, commit style, file layout expectations -->

## Skills
- See `skills/README.md` (if present)

## Specs
- Product/architecture specs live in `specs/` (source of truth for product/behavior/architecture).
- Only required when work touches product, behavior, or architecture.
