# PokeMap Hub Phase 7 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow an author to configure, export, reopen, certify and hand a
generic data-only `.pokemapgame` package to PokeMap Hub without distributing
the author workspace or any secret.

**Architecture:** `map_core` owns the compiled dialogue data contract,
`map_distribution` owns the cross-application install-request contract,
`map_editor` owns author metadata, runtime projection, export and no-code UI,
and `pokemap_hub` owns inbox consumption and installation. The editor and Hub
never depend on each other; their only shared types remain pure Dart contracts.

**Tech Stack:** Dart 3, Flutter, `map_core`, `map_distribution`, deterministic
ZIP v1, canonical JSON, `dart:io`, package-scoped tests.

---

## Task 1: Compile author dialogues into data-only runtime documents

**Files:**

- Create:
  `packages/map_core/lib/src/dialogue/runtime_dialogue_document.dart`
- Create:
  `packages/map_core/lib/src/dialogue/yarn_dialogue_compiler.dart`
- Modify: `packages/map_core/lib/map_core.dart`
- Create:
  `packages/map_core/test/runtime_dialogue_document_test.dart`
- Modify:
  `packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart`
- Modify:
  `packages/map_runtime/lib/src/application/load_dialogue_content.dart`
- Create:
  `packages/map_runtime/test/compiled_dialogue_runtime_test.dart`

- [x] Write codec/compiler tests for lines, jumps, choices, outcomes, strict
      decoding and deterministic JSON.
- [x] Run the new `map_core` test and observe missing contract/compiler errors.
- [x] Implement immutable runtime dialogue nodes/steps/choices and a strict
      version-1 JSON codec plus the existing supported Yarn subset compiler.
- [x] Delegate the legacy runtime Yarn parser to that compiler and load
      compiled `.json` dialogue documents without changing session semantics.
- [x] Run focused core/runtime tests and keep the legacy dialogue parser tests
      green.

## Task 2: Define the safe editor-to-Hub install handoff

**Files:**

- Create:
  `packages/map_distribution/lib/src/game_package_install_request.dart`
- Modify: `packages/map_distribution/lib/map_distribution.dart`
- Create:
  `packages/map_distribution/test/game_package_install_request_test.dart`

- [x] Write failing tests for canonical round-trip, relative package filename,
      SHA-256, request ID, UTC timestamp, unknown fields and traversal.
- [x] Implement the version-1 immutable request and strict canonical codec.
- [x] Run the focused test and the complete `map_distribution` suite.

## Task 3: Build and certify a clean author-workspace projection

**Files:**

- Modify: `packages/map_editor/pubspec.yaml`
- Create:
  `packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart`
- Create:
  `packages/map_editor/lib/src/features/game_export/infrastructure/game_package_export_profile_store.dart`
- Create:
  `packages/map_editor/lib/src/features/game_export/application/runtime_project_projection_builder.dart`
- Create:
  `packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart`
- Create:
  `packages/map_editor/lib/src/features/game_export/infrastructure/hub_install_request_publisher.dart`
- Create:
  `packages/map_editor/lib/game_export.dart`
- Modify:
  `packages/map_distribution/lib/src/game_package_content_validator.dart`
- Create:
  `packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart`
- Create:
  `packages/map_editor/test/game_export/game_package_export_service_test.dart`
- Create:
  `packages/map_editor/test/game_export/hub_install_request_publisher_test.dart`
- Modify:
  `packages/map_distribution/test/game_package_builder_test.dart`

- [x] Write failing tests proving stable author identity, atomic profile
      persistence, `mistralApiKey` removal, secret-key scrub, Yarn compilation,
      legacy dialogue-reference rewrite, author/debug/save exclusion, branding,
      legal files, media under project data, deterministic export, reopen and
      inspection certification.
- [x] Implement strict export metadata validation without deriving `gameId`
      from title or folder.
- [x] Implement a bounded filesystem projector that rejects symlinks, includes
      only allowlisted JSON/media, compiles dialogues, rewrites the copied
      manifest, removes explicit secret fields and never mutates the source.
- [x] Build with `GamePackageBuilder`, reopen with `GamePackageInspector`,
      compare identity/tree/package receipts, and write exports atomically.
- [x] Publish install requests by copying immutable package bytes into an
      injected inbox, flushing, hashing, promoting the package first and the
      request last.
- [x] Run focused distribution/editor tests.

## Task 4: Add the no-code editor export surface and generic CLI

**Files:**

- Create:
  `packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart`
- Create:
  `packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart`
- Modify:
  `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- Modify:
  `packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart`
- Create: `packages/map_editor/tool/export_pokemap_game.dart`
- Create:
  `packages/map_editor/test/game_export/game_package_export_controller_test.dart`
- Create:
  `packages/map_editor/test/game_export/game_package_export_dialog_test.dart`
- Create:
  `packages/map_editor/test/game_export/generic_release_gate_test.dart`

- [x] Write failing controller/widget tests for profile loading, validation,
      export, direct Hub handoff, progress, error recovery, focus and disabled
      states using only PokeMap design-system primitives.
- [x] Implement the controller state machine and responsive modal form for
      identity, version, author, locales, branding and legal metadata.
- [x] Add an enabled “Exporter le jeu” toolbar action only when a project root
      is open; expose separate Export and Install-in-Hub actions.
- [x] Add a generic headless CLI accepting `--project`, `--profile`,
      `--output` and optional `--hub-inbox`, with no Selbrume/default-project
      assumption.
- [x] Prove two unrelated neutral projects export through the same gate.

## Task 5: Consume direct-install requests in the Hub

**Files:**

- Create:
  `apps/pokemap_hub/lib/src/install/editor_export_install_inbox.dart`
- Modify: `apps/pokemap_hub/lib/pokemap_hub.dart`
- Modify:
  `apps/pokemap_hub/lib/src/ui/hub_dashboard_controller.dart`
- Create:
  `apps/pokemap_hub/test/install/editor_export_install_inbox_test.dart`
- Modify:
  `apps/pokemap_hub/test/ui/hub_dashboard_controller_test.dart`

- [x] Write failing tests for safe request discovery, digest verification,
      `localExport` installation, success cleanup, failure preservation,
      deterministic ordering and controller startup consumption.
- [x] Implement bounded request scanning with no absolute path trust; verify
      the package digest before invoking the existing hostile installer.
- [x] Delete only a successfully consumed request/package pair and keep failed
      requests for diagnosis/retry.
- [x] Let the dashboard optionally consume pending exports before its library
      reload and expose failures through safe diagnostics.
- [x] Run focused Hub tests.

## Task 6: Architecture, validation and commit

**Files:**

- Modify:
  `apps/pokemap_hub/test/architecture/hub_architecture_boundary_test.dart`
- Modify: `packages/map_distribution/README.md`
- Modify: `packages/map_editor/README.md`

- [x] Add architecture gates forbidding editor/Hub dependency cycles and
      production references to the developer host.
- [x] Format only Phase 7 files.
- [x] Run complete tests and analyzers for `map_core`, `map_distribution`,
      `map_editor`, `map_runtime` and `pokemap_hub`, recording any pre-existing
      unrelated failures honestly.
- [x] Run `git diff --check`, inspect secrets/raw paths, verify the developer
      host and `map_battle` are untouched, and preserve all pre-existing
      untracked files.
- [x] Stage only Phase 7 files for one intentional commit.

**DONE:** A neutral author project can persist no-code release metadata,
compile a clean runtime projection, produce a deterministic inspected
`.pokemapgame`, queue it for the Hub, and have the Hub install it through the
existing atomic installer. FG-185 remains `PARTIAL / NO-GO` until its separate
five-evidence execution receipt exists.
