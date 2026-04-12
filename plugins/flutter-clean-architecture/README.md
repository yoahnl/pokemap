# Flutter Clean Architecture Plugin

This repo-local plugin gives Codex a focused skill for building Flutter applications with strict clean architecture boundaries.

## Included

- `skills/flutter-clean-architecture/SKILL.md`
  - Opinionated guidance for feature-first Flutter apps
  - Dependency-direction guardrails
  - Default tooling and testing expectations
- `references/flutter-clean-architecture-blueprint.md`
  - A compact blueprint the skill can point to while scaffolding features

## Current State

- The plugin is scaffolded locally at `plugins/flutter-clean-architecture/`.
- Publishing metadata in `.codex-plugin/plugin.json` is still marked with `TODO` placeholders where it would be risky to invent owner or URL details.
- No marketplace entry has been created yet.

## Next Step If You Want It Discoverable In Codex UI

Create a repo-local marketplace entry:

```bash
python3 /Users/karim/.codex/skills/.system/plugin-creator/scripts/create_basic_plugin.py flutter-clean-architecture \
  --path /Users/karim/Project/pokemonProject/plugins \
  --marketplace-path /Users/karim/Project/pokemonProject/.agents/plugins/marketplace.json \
  --with-marketplace
```

If you want, I can do that next and also polish the remaining manifest metadata.
