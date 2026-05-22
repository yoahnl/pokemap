# Skills Index

This file helps agents choose the right local skill before they open the full `SKILL.md`. It is an index, not a replacement for the skill files.

When a skill seems relevant, read the matching `skills/<skill-name>/SKILL.md` before using it. Do not rely on memory.

## Priority Rules

Follow instructions in this order:

1. Direct user request.
2. Nearest applicable `AGENTS.md`.
3. Root `AGENTS.md`.
4. The selected skill's `SKILL.md`.
5. Supporting templates, prompts, and references inside the skill folder.

If instructions conflict, use the stricter safe rule and report the conflict.

## Available Skills

| Skill | Use when | Notes |
|---|---|---|
| `using-superpowers` | Starting a task or deciding whether a skill applies. | Entry point for skill discipline. Use it as a routing guard, not as busywork. |
| `brainstorming` | Exploring a new feature, behavior change, product idea, or design before implementation. | Useful before UI/product/gameplay design. Requires approval before implementation when applicable. |
| `writing-plans` | Turning an approved design/spec into an implementation plan. | Plans should be concrete, testable, and free of placeholders. |
| `executing-plans` | Executing a written implementation plan inline or in a separate session. | Follow the plan, verify each step, stop on blockers. |
| `subagent-driven-development` | Executing an implementation plan with independent tasks and subagent review loops. | Use fresh context per task; review spec compliance before code quality. |
| `dispatching-parallel-agents` | Investigating multiple independent failures or domains in parallel. | Use for investigation/review, not conflicting parallel implementation. |
| `systematic-debugging` | Handling bugs, failing tests, analyzer failures, parser/serializer failures, or unexpected behavior. | Find root cause before patching. No pile-on fixes. |
| `test-driven-development` | Adding new behavior or fixing bugs where a focused failing test is feasible. | Red -> Green -> Refactor. Keep scope small. |
| `verification-before-completion` | Before saying work is done. | Requires fresh evidence, not confidence. |
| `requesting-code-review` | After substantial work, before merge, or before moving to the next risky lot. | Provide focused context, requirements, and git range when available. |
| `receiving-code-review` | Processing review feedback. | Verify feedback technically before implementing it. Avoid performative agreement. |
| `finishing-a-development-branch` | Wrapping up verified work and choosing merge/PR/cleanup options. | Never perform Git write operations unless the user explicitly asked. |
| `using-git-worktrees` | Creating or using isolated worktrees. | In PokeMap, use only with explicit user permission because root `AGENTS.md` forbids silent worktree changes. |
| `writing-skills` | Creating, editing, or validating skills. | Use when changing this directory or adding new skills. |

## PokeMap-Specific Guidance

For gameplay mechanics, always pair skills with the canonical roadmap:

```text
pokemap_roadmap_mecaniques_fangame.md
```

Identify the relevant `FG-*` lot before implementation and report whether the lot remains `TODO`, `PARTIAL`, `BLOCKED`, or can be proposed as `DONE` with fresh proof.

For visual/editor/runtime work, choose skills based on the task type:

| Task type | Start with | Also consider |
|---|---|---|
| Surface/Path/Environment/Shadow feature design | `brainstorming` | `writing-plans` |
| Runtime or editor implementation lot | `writing-plans` or `executing-plans` | `verification-before-completion`, `requesting-code-review` |
| Broken tests or regressions | `systematic-debugging` | `test-driven-development` |
| Large multi-lot implementation | `subagent-driven-development` | `requesting-code-review` |
| Final status/lot closure | `verification-before-completion` | `requesting-code-review` |

## Practical Usage Pattern

1. Read the task and identify the smallest relevant scope.
2. Check this index.
3. Open the selected `SKILL.md`.
4. Apply the skill only as far as it helps produce scoped, verified work.
5. Report the skill used only when it is useful evidence or the skill explicitly requires it.

## Maintenance

Update this index when:

- a new skill folder is added;
- a skill is renamed or removed;
- a skill's purpose changes materially;
- `AGENTS.md` changes the priority or safety rules around skills.

Do not duplicate full `SKILL.md` content here. Keep this file short enough to skim.
