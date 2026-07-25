# PokeMap Hub Phase 8 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans and superpowers:test-driven-development
> task-by-task, then superpowers:verification-before-completion before any
> completion claim.

**Goal:** Certify PokeMap Hub as a generic, offline-capable player product with
a second neutral game, destructive-lifecycle coverage, crash recovery,
performance gates and a reproducible macOS release pipeline.

**Architecture:** Product certification lives in a standalone
`tool/pokemap_product_certification` package so the authoring application and
the Hub keep their production dependency boundary. The harness may compose
`map_editor`, `map_distribution`, `pokemap_hub` and `map_runtime` only in
tests. The Hub becomes a real macOS application, while Apple signing,
notarization and cold-install verification remain gated release operations
that never embed credentials in the repository.

**Tech Stack:** Dart 3, Flutter, deterministic `.pokemapgame` ZIP v1,
`map_editor` export, `pokemap_hub` installer/saves/library/session contracts,
Flutter macOS, Xcode signing tools, GitHub Actions.

**Relevant audit lots:** HUB-080, HUB-081, HUB-082, HUB-083 and HUB-084.
**Relevant mechanics lot:** FG-185 remains `PARTIAL / NO-GO` unless the
generic certification receipt contains all required executed evidence.

---

## Task 1: Certify a second neutral mini-game

**Objective:** Prove the product is not coupled to Selbrume, the development
host or an author workspace.

**Files:**

- Create: `tool/pokemap_product_certification/pubspec.yaml`
- Create:
  `tool/pokemap_product_certification/lib/pokemap_product_certification.dart`
- Create:
  `tool/pokemap_product_certification/lib/src/neutral_game_fixture.dart`
- Create:
  `tool/pokemap_product_certification/test/neutral_game_package_test.dart`

**Tests:**

- Build a valid neutral author workspace and release profile.
- Export and reopen a deterministic `.pokemapgame`.
- Remove the author workspace before installation.
- Assert the exported package and installed tree contain no Selbrume,
  workspace, save, cache, debug or secret material.

**DONE:** The same generic export and inspector contracts certify an unrelated
neutral game with a stable explicit `gameId`.

**Risks:** A fixture that bypasses author export or runtime project validation
would be false evidence.

**Dependencies:** Phase 7 generic export and Phase 1 package inspector.

## Task 2: Execute the complete offline player journey

**Objective:** Certify Export → install → New Game → combat → save → Continue
→ game completion without source workspace or network.

**Files:**

- Create:
  `tool/pokemap_product_certification/lib/src/product_certification_harness.dart`
- Create:
  `tool/pokemap_product_certification/lib/src/product_certification_receipt.dart`
- Create:
  `tool/pokemap_product_certification/test/offline_player_journey_test.dart`

**Tests:**

- Install with `GamePackageInstaller` and verify the promoted tree.
- Launch from the installed package through the real session runtime.
- Exercise a real battle request and record its executed evidence.
- Write an atomic game-scoped save, unload the first session and Continue from
  the persisted slot.
- Emit `GameCompleted`, verify the completed save state and return cleanly.
- Deny or detect network use for the whole test.

**DONE:** A redacted machine-readable receipt records every executed step,
package/tree hashes and source/network isolation.

**Risks:** Debug-only hooks must only drive public runtime behavior and must
not replace the actual installer, save store or session runtime.

**Dependencies:** HUB-080, Phase 2 saves, Phase 3 installer, Phase 4 shell,
Phase 6 battle/session presentation.

## Task 3: Certify update, migration, rollback and uninstall

**Objective:** Prove release lifecycle operations never destroy the last
working game version or valid save.

**Files:**

- Create:
  `tool/pokemap_product_certification/test/release_lifecycle_test.dart`

**Tests:**

- Install neutral game v1, create a scoped save and update to v2.
- Run save preparation/migration on a copy.
- Roll back to v1 and restore the compatible save snapshot.
- Uninstall every game version while preserving the save directory.

**DONE:** The actual installer, maintenance service and save store pass the
full lifecycle in one integrated test.

**Risks:** Separate unit tests alone do not prove cross-service ordering.

**Dependencies:** HUB-081 and Phase 3 maintenance services.

## Task 4: Add kill-safety and performance certification gates

**Objective:** Make crash recovery and large-library/catalog behavior
measurable and non-opaque.

**Files:**

- Create:
  `tool/pokemap_product_certification/lib/src/certification_budgets.dart`
- Create:
  `tool/pokemap_product_certification/test/performance_budget_test.dart`
- Create:
  `tool/pokemap_product_certification/test/certification_receipt_test.dart`
- Create:
  `tool/pokemap_product_certification/README.md`

**Tests:**

- Load and sort a library containing 100 installed games within an explicit
  reference budget.
- Export and inspect a neutral project with a 2,000-entry species catalogue
  with staged progress/evidence and no opaque loading interval.
- Re-run existing subprocess kill tests for installer promotion and atomic
  save recovery in the product certification workflow.
- Validate that receipts reject absolute paths, usernames, credentials and
  other machine-specific or secret values.

**DONE:** Named budgets, reference environment and kill-test commands are
versioned; failures are actionable and receipts remain redacted.

**Risks:** Wall-clock assertions can be flaky; budgets must be conservative,
measured on a declared reference runner and never presented as universal P95
data from a single local run.

**Dependencies:** HUB-082 plus existing Phase 2/3 crash fixtures.

## Task 5: Make `pokemap_hub` a distributable macOS application

**Objective:** Produce a real Release application with `.pokemapgame` document
association and release-safe platform settings.

**Files:**

- Create: `apps/pokemap_hub/lib/main.dart`
- Create/modify: `apps/pokemap_hub/macos/**`
- Modify: `apps/pokemap_hub/pubspec.yaml`
- Create:
  `apps/pokemap_hub/test/platform/macos_distribution_contract_test.dart`

**Tests:**

- Assert generic bundle/product identifiers and version/build metadata.
- Assert `CFBundleDocumentTypes` and an exported PokeMap game UTI.
- Assert Release Hardened Runtime and release-safe entitlements.
- Launch/build the Flutter macOS target without the development host.

**DONE:** `flutter build macos --release` produces `PokeMap Hub.app`, and the
bundle contract is structurally valid.

**Risks:** App scaffolding can create broad generated churn; generated files
must be reviewed and no personal signing identity/team may be committed.

**Dependencies:** Phase 5 Hub UI and Phase 4 session composition.

## Task 6: Add reproducible signing, notarization and cold-install gates

**Objective:** Automate the operations required for public macOS distribution
without weakening security or storing credentials.

**Files:**

- Create:
  `apps/pokemap_hub/tool/release/verify_macos_distribution.dart`
- Create:
  `apps/pokemap_hub/tool/release/macos_certification_receipt.schema.json`
- Create:
  `apps/pokemap_hub/macos/ExportOptions-DeveloperID.plist`
- Create: `.github/workflows/pokemap_hub_product_certification.yml`
- Create:
  `apps/pokemap_hub/test/release/macos_release_gate_test.dart`

**Tests:**

- Fail closed when Developer ID, Hardened Runtime, signature, notarization,
  stapling, Gatekeeper or receipt evidence is absent.
- Run public tests/analyzers/build without secrets.
- Restrict secret-backed signing/notarization to protected release tags.
- Validate a redacted receipt after notarized artifact cold install and
  relaunch with the repository absent.

**DONE:** The release pipeline is executable and fail-closed. HUB-084 is only
`DONE` after a real Developer ID-signed, notarized, stapled, Gatekeeper-
accepted artifact passes cold installation and relaunch.

**Risks:** This workstation currently has no `Developer ID Application`
identity; repository implementation cannot manufacture Apple credentials.

**Dependencies:** HUB-080 through HUB-083, approved Apple identifiers,
Developer Program credentials and a clean macOS release runner.

## Task 7: Final verification, report and commit

**Files:**

- Create:
  `reports/product/pokemap_hub/phase_8/product_certification_report_2026-07-25.md`

**Checks:**

- Format only Phase 8 Dart files.
- Run focused tests first, then full tests/analyzers for every touched package.
- Run existing Hub installer/save kill tests explicitly.
- Run the macOS Release build and structural distribution gate.
- Run `git diff --check`, inspect the complete diff and scan for secrets,
  machine paths, Selbrume coupling and developer-host imports.
- Record initial/final Git state, exact commands/results, limitations and the
  independent Audit, Tests, Build and Critique verdicts.
- Stage only Phase 8 files and create one intentional commit.

**DONE:** The implemented scaffold is committed with each lot truthfully
reported as `PARTIAL` or `BLOCKED`. No HUB-080…084 closure is claimed until
the missing player journey, transaction, child-process, performance and
external Apple evidence all exist.
