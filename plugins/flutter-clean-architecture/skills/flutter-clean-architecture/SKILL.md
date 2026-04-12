---
name: flutter-clean-architecture
description: Design and implement Flutter applications with strict clean architecture, feature-first structure, enforceable dependency direction, and strong testing defaults.
---

# Flutter Clean Architecture

## Overview

Use this skill when the user wants a new Flutter app, a new feature, or a refactor that should follow strict clean architecture instead of ad hoc folder organization.

Optimize for maintainability, testability, and low coupling. Prefer small vertical slices, explicit boundaries, and code that is easy to reason about six months later.

## Use This Skill When

- the user wants to scaffold a Flutter app or package with a clean architecture
- a Flutter codebase needs stricter layering or feature boundaries
- a feature should be added without leaking API, persistence, or UI concerns across layers
- the user wants a pragmatic but opinionated default stack for serious Flutter work

## Default Stack

- Flutter and Dart stable
- Feature-first folders under `lib/features/`
- Riverpod for state management and dependency injection unless the repo already standardizes on another approach
- `go_router` for routing when routing is part of the task
- `freezed` and `json_serializable` for immutable models and DTOs when code generation is already acceptable in the repo
- Repository contracts in domain, implementations in data

Preserve the repo's existing state management, routing, or dependency injection choices if they are already established and the user did not ask for a migration.

## Non-Negotiable Rules

1. Keep dependency direction strict.
   - `presentation` may depend on `domain`.
   - `data` may depend on `domain`.
   - `domain` must depend on nothing from `presentation`, `data`, or Flutter UI packages.
2. Keep business rules out of widgets.
   - Widgets render state and dispatch intents.
   - Controllers, not widgets, coordinate use cases.
3. Keep external concerns in `data`.
   - HTTP clients, database code, cache adapters, and platform APIs stay in `data`.
   - DTOs and mappers stay in `data`.
4. Keep domain pure.
   - Domain entities and use cases should be plain Dart whenever possible.
   - Avoid Flutter imports in `domain`.
5. Create shared code only when it is genuinely cross-feature.
   - Do not turn `core/` into a dumping ground.
   - If a utility is only used by one feature, keep it inside that feature.
6. Favor constructor injection or provider composition.
   - Avoid hidden global state and service locators unless the repo already relies on them.

## Preferred Folder Shape

```text
lib/
  app/
    bootstrap/
    router/
    theme/
  core/
    error/
    network/
    storage/
    utils/
  features/
    feature_name/
      data/
        datasources/
        dto/
        mappers/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        controllers/
        pages/
        widgets/
```

For a simple app, do not create every subfolder on day one. Start with the minimum set required for the feature and grow deliberately.

See `../../references/flutter-clean-architecture-blueprint.md` for the full blueprint.

## Delivery Workflow

When using this skill, follow this sequence:

1. Inspect the current repo before generating structure.
   - Read the nearest `pubspec.yaml`, `README.md`, and local conventions.
   - Keep existing package boundaries intact.
2. Decide whether the task is app bootstrap, new feature, or refactor.
3. Define the domain contract first.
   - Add entities, repository interfaces, and use cases before data implementations.
4. Implement data adapters next.
   - Add DTOs, mappers, datasources, and repository implementations.
5. Build presentation last.
   - Add controllers, screens, and widgets that depend on use cases rather than concrete data sources.
6. Add tests close to the behavior you changed.
   - Domain tests first.
   - Controller or widget tests where UI behavior matters.
7. Regenerate code only when annotations or codegen-backed models change.

## Generation Guardrails

- Keep files small and single-purpose.
- Name things by intent, not framework trivia.
- Avoid placeholder methods that throw unless the task explicitly asks for stubs.
- Prefer one feature completed end-to-end over broad shallow scaffolding.
- When a choice is already obvious from the repo, do not ask the user to restate it.
- When a major architecture choice is truly ambiguous, ask one focused question instead of many small ones.

## Testing Expectations

- Add unit tests for use cases and domain services.
- Test repository implementations when mapping or error translation is non-trivial.
- Add widget or controller tests for important presentation flows.
- Prefer fast tests over broad integration coverage unless the user explicitly asks for end-to-end wiring.

## Anti-Patterns

- Calling APIs directly from widgets
- Importing `data` classes into `presentation` when a domain type should cross the boundary
- Letting `core/` accumulate feature-specific logic
- Creating giant repository interfaces that bundle unrelated use cases
- Sharing one controller across multiple unrelated screens
- Mixing serialization logic into domain entities

## Output Style

When completing a task with this skill:

- explain the architecture decisions briefly and concretely
- call out any boundary compromises clearly
- mention code generation commands when needed
- prefer targeted tests over broad repo-wide commands
