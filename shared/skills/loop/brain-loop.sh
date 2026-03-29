#!/usr/bin/env bash
set -euo pipefail

#
# Ralph Loop — general-purpose iterative agent harness.
#
# Repeatedly runs an agent in a fresh context; each iteration does one chunk
# of work then exits.  The loop restarts the agent until you stop it (Ctrl+C),
# a max-iteration limit is hit, or no open tasks remain in IMPLEMENTATION_PLAN.md.
#
# Modes: plan, plan-work, build, autoresearch
#
# This script is the STABLE harness — the agent must never modify it at runtime.
# Prompts, templates, specs, and skills are fair game for the agent.
#

# --- Utility functions -------------------------------------------------------

open_tasks_remaining() {
  if [[ ! -f "IMPLEMENTATION_PLAN.md" ]]; then
    return 1
  fi

  if awk '
    BEGIN { in_tasks=0; open=0 }
    /^##[[:space:]]+Task List/ { in_tasks=1; next }
    /^##[[:space:]]+/ { if (in_tasks) exit }
    in_tasks && /^[[:space:]]*-[[:space:]]+\[[[:space:]]\]/ { open=1; exit }
    END { exit(open ? 0 : 1) }
  ' IMPLEMENTATION_PLAN.md; then
    return 0
  fi

  return 1
}

open_acceptance_remaining() {
  if [[ ! -f "IMPLEMENTATION_PLAN.md" ]]; then
    return 1
  fi

  if awk '
    BEGIN { in_acceptance=0; open=0 }
    /^##[[:space:]]+Acceptance Criteria/ { in_acceptance=1; next }
    /^##[[:space:]]+/ { if (in_acceptance) exit }
    in_acceptance && /^[[:space:]]*-[[:space:]]+\[[[:space:]]\]/ { open=1; exit }
    END { exit(open ? 0 : 1) }
  ' IMPLEMENTATION_PLAN.md; then
    return 0
  fi

  return 1
}

usage() {
  cat <<'EOF'
Usage:
  ./loop.sh [max_iterations]                          # build (live output, skip-perms)
  ./loop.sh auto [max_iterations]                     # build unattended (-p streaming)
  ./loop.sh plan [max_iterations]                     # interactive planning (asks clarification)
  ./loop.sh plan-work "scope..." [max_iterations]     # scoped interactive planning
  ./loop.sh autoresearch <target> [max_experiments]   # optimize a prompt with autoresearch

Autoresearch targets:
  ./loop.sh autoresearch plan                         # optimize PROMPT_plan.md
  ./loop.sh autoresearch build                        # optimize PROMPT_build.md
  ./loop.sh autoresearch plan-work                    # optimize PROMPT_plan_work.md
  ./loop.sh autoresearch ./path/to/prompt.md          # optimize any prompt file

Examples:
  ./loop.sh plan                     # create/update IMPLEMENTATION_PLAN.md (interactive)
  WORK_SCOPE="Add auth" ./loop.sh plan-work
  ./loop.sh 10                       # build 10 iters, live streaming output
  ./loop.sh auto 20                  # build 20 iters, fully unattended
  ./loop.sh autoresearch plan        # optimize PROMPT_plan.md using evals/plan.yaml
  ./loop.sh autoresearch build 15    # optimize PROMPT_build.md, max 15 experiments

Environment:
  RALPH_AGENT       Agent command (default: claude)
  RALPH_AGENT_ARGS  Extra args passed to agent (auto mode adds --dangerously-skip-permissions)
  WORK_SCOPE        Scope string for plan-work mode
  RALPH_MAX_AUTO    Safety cap for auto mode when no max given (default: 20)
EOF
}

# --- Parse CLI -----------------------------------------------------------

run_style="interactive"   # interactive | auto
mode="build"              # build | plan | plan-work | autoresearch
max_iterations=0
autoresearch_target=""

# First arg may be a run style or a mode.
case "${1:-}" in
  auto) run_style="auto"; shift || true ;;
  autoresearch) mode="autoresearch"; shift || true ;;
esac

case "${1:-}" in
  plan|plan-work) mode="$1"; shift || true ;;
esac

# Handle autoresearch target
if [[ "$mode" == "autoresearch" ]]; then
  if [[ "$#" -eq 0 ]]; then
    echo "ERROR: autoresearch requires a target (plan, build, plan-work, or a file path)." >&2
    usage
    exit 2
  fi
  autoresearch_target="$1"
  shift || true

  # Optional max experiments
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    max_iterations="$1"
    shift || true
  fi
fi

# plan-work needs WORK_SCOPE
if [[ "$mode" == "plan-work" ]]; then
  if [[ "${WORK_SCOPE:-}" == "" ]]; then
    if [[ "$#" -eq 0 ]]; then
      echo "ERROR: plan-work requires WORK_SCOPE (env var or args)." >&2
      usage
      exit 2
    fi
    args=("$@")
    argc="${#args[@]}"
    last_idx=$((argc - 1))
    last_val="${args[$last_idx]}"
    if [[ "$last_val" =~ ^[0-9]+$ ]]; then
      max_iterations="$last_val"
      unset 'args[$last_idx]'
    fi
    export WORK_SCOPE="${args[*]}"
  fi
elif [[ "$mode" == "build" ]]; then
  if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
    max_iterations="$1"
    shift || true
  fi
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  usage
  exit 0
fi

# --- Agent setup ---------------------------------------------------------

agent="${RALPH_AGENT:-claude}"
agent_args="${RALPH_AGENT_ARGS:-}"

# brain-loop: no default skip-permissions. Use RALPH_AGENT_ARGS env var to customize.
# For auto/unattended mode, the auto block below still adds skip-permissions.

# Auto mode: ensure skip-permissions and enforce safety cap.
if [[ "$run_style" == "auto" ]]; then
  if [[ "$agent" != "claude" ]]; then
    echo "ERROR: auto mode is only supported with claude." >&2
    exit 2
  fi
  if [[ "$agent_args" != *"--dangerously-skip-permissions"* ]]; then
    agent_args="$agent_args --dangerously-skip-permissions"
  fi
  if [[ "$max_iterations" -eq 0 ]]; then
    max_iterations="${RALPH_MAX_AUTO:-20}"
    echo "Auto mode safety: defaulting to $max_iterations max iterations."
  fi
fi

# Plan modes default to a single iteration (one planning session).
if [[ "$mode" != "build" && "$mode" != "autoresearch" && "$max_iterations" -eq 0 ]]; then
  max_iterations=1
fi

# Autoresearch defaults to a single long session (the agent loops internally).
if [[ "$mode" == "autoresearch" && "$max_iterations" -eq 0 ]]; then
  max_iterations=1
fi

# --- Prompt file ---------------------------------------------------------

prompt_file=""

resolve_autoresearch_target() {
  local target="$1"
  local target_prompt=""
  local target_evals=""
  local target_name=""

  case "$target" in
    plan)
      target_prompt="PROMPT_plan.md"
      target_evals="evals/plan.yaml"
      target_name="plan"
      ;;
    build)
      target_prompt="PROMPT_build.md"
      target_evals="evals/build.yaml"
      target_name="build"
      ;;
    plan-work)
      target_prompt="PROMPT_plan_work.md"
      target_evals="evals/plan-work.yaml"
      target_name="plan-work"
      ;;
    *)
      # Custom file path
      if [[ ! -f "$target" ]]; then
        echo "ERROR: Target file not found: $target" >&2
        exit 2
      fi
      target_prompt="$target"
      # Try to find matching eval file
      local base
      base="$(basename "$target" .md)"
      target_evals="evals/${base}.yaml"
      target_name="$base"
      ;;
  esac

  if [[ ! -f "$target_prompt" ]]; then
    echo "ERROR: Target prompt not found: $target_prompt" >&2
    exit 2
  fi

  # Export for use in prompt construction
  export _AR_TARGET_PROMPT="$target_prompt"
  export _AR_TARGET_EVALS="$target_evals"
  export _AR_TARGET_NAME="$target_name"
  export _AR_MAX_EXPERIMENTS="$max_iterations"
}

case "$mode" in
  autoresearch)
    resolve_autoresearch_target "$autoresearch_target"
    prompt_file="PROMPT_autoresearch.md"
    # If no local PROMPT_autoresearch.md, use the one from the skill
    if [[ ! -f "$prompt_file" ]]; then
      _skill_dir="$(cd "$(dirname "$0")" && pwd)"
      if [[ -f "$_skill_dir/templates/PROMPT_autoresearch.md" ]]; then
        prompt_file="$_skill_dir/templates/PROMPT_autoresearch.md"
      else
        echo "ERROR: Missing PROMPT_autoresearch.md (not found locally or in skill directory)" >&2
        exit 2
      fi
    fi
    ;;
  plan-work)
    prompt_file="PROMPT_plan_work.md"
    if [[ "${WORK_SCOPE:-}" == "" ]]; then
      echo "ERROR: plan-work requires WORK_SCOPE (env var or extra args)." >&2
      usage
      exit 2
    fi
    ;;
  plan)  prompt_file="PROMPT_plan.md" ;;
  build) prompt_file="PROMPT_build.md" ;;
  *)
    echo "ERROR: Unknown mode: $mode" >&2
    usage
    exit 2
    ;;
esac

if [[ ! -f "$prompt_file" ]]; then
  echo "ERROR: Missing $prompt_file" >&2
  exit 2
fi

# --- Harness self-protection ---------------------------------------------

_harness_file="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
_harness_checksum="$(shasum -a 256 "$_harness_file" | awk '{print $1}')"
_harness_backup="$(mktemp)"
cp "$_harness_file" "$_harness_backup"
trap 'rm -f "$_harness_backup"' EXIT

# --- Run loop ------------------------------------------------------------

run_agent() {
  local prompt
  prompt="$(cat "$prompt_file")"

  # brain-loop: inject active role instructions
  local brain_dir="$HOME/.claude/brain"
  local claude_md="$brain_dir/CLAUDE.md"
  if [[ -f "$claude_md" ]]; then
    local role_import
    role_import="$(grep '@roles/' "$claude_md" | head -1 | sed 's/@//' | tr -d ' ')"
    if [[ -n "$role_import" && -f "$brain_dir/$role_import" ]]; then
      local role_content
      role_content="$(cat "$brain_dir/$role_import")"
      prompt="${role_content}"$'\n\n'"${prompt}"
    fi
  fi

  # Variable substitution for dynamic prompts
  if [[ "$mode" == "plan-work" ]]; then
    prompt="${prompt//'${WORK_SCOPE}'/${WORK_SCOPE}}"
  fi
  if [[ "$mode" == "autoresearch" ]]; then
    prompt="${prompt//'${AR_TARGET_PROMPT}'/${_AR_TARGET_PROMPT}}"
    prompt="${prompt//'${AR_TARGET_NAME}'/${_AR_TARGET_NAME}}"
    prompt="${prompt//'${AR_MAX_EXPERIMENTS}'/${_AR_MAX_EXPERIMENTS}}"

    # Inline eval definitions if the file exists
    local eval_content="(no eval file found — you must define evals interactively)"
    if [[ -f "${_AR_TARGET_EVALS}" ]]; then
      eval_content="$(cat "${_AR_TARGET_EVALS}")"
    fi
    prompt="${prompt//'${AR_EVAL_DEFINITIONS}'/${eval_content}}"
  fi

  # Plan modes run interactively (TUI) so the agent can ask clarification questions
  # and the user can answer them in real time.
  # Build and autoresearch modes use -p (streaming print) for live output without user interaction.
  if [[ "$mode" == "plan" || "$mode" == "plan-work" ]]; then
    # shellcheck disable=SC2086
    "$agent" $agent_args "$prompt"
  else
    # shellcheck disable=SC2086
    if [[ "$agent_args" == *"-p"* ]]; then
      "$agent" $agent_args "$prompt"
    else
      "$agent" $agent_args -p "$prompt"
    fi
  fi
}

iter=1
while true; do
  if [[ "$max_iterations" -gt 0 && "$iter" -gt "$max_iterations" ]]; then
    echo "Reached max iterations ($max_iterations). Exiting."
    exit 0
  fi

  echo "=== ralph: mode=$mode style=$run_style iter=$iter max=${max_iterations:-0} ==="

  run_agent

  # Harness integrity check.
  _current_checksum="$(shasum -a 256 "$_harness_file" | awk '{print $1}')"
  if [[ "$_current_checksum" != "$_harness_checksum" ]]; then
    echo "WARNING: Agent modified loop.sh — restoring from backup." >&2
    cp "$_harness_backup" "$_harness_file"
    chmod +x "$_harness_file"
  fi

  if [[ "$mode" == "build" ]]; then
    if ! open_tasks_remaining && ! open_acceptance_remaining; then
      echo "No open tasks or acceptance criteria in IMPLEMENTATION_PLAN.md. Exiting."
      exit 0
    fi
  fi

  iter=$((iter + 1))
done
