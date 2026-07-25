# PokeMap Hub — Phase 8 Product Certification Report

Date: 2026-07-25
Branch: `main`
Initial HEAD: `9d03e6377ce2f99430e28365411e7c1defd856ea`
Scope: HUB-080 through HUB-084
Related mechanics lot: FG-185

## Executive verdict

**Phase 8 remains `NO-GO` for public release.**

This implementation adds a useful certification boundary, a second neutral
project, installed New Game/save/Continue evidence, 100-game and 2,000-catalog
guards, a real macOS application runner, a Release build, and fail-closed Apple
distribution gates.

It does not convert missing product contracts into false evidence. The
following blockers remain:

1. no authored no-code `Terminer le jeu` command is connected to
   `GameCompleted`;
2. save migration/update/rollback has no durable cross-service transaction,
   abort and crash recovery;
3. the desktop public player has no supervised child-process adapter required
   by ADR-0002;
4. the neutral fixture does not yet contain a player-driven combat and authored
   ending;
5. performance timings have not been calibrated as P95 on an approved pinned
   CI reference runner;
6. this workstation has no `Developer ID Application` identity, so the local
   Release build is ad hoc, not notarized, not stapled, and rejected by
   Gatekeeper.

FG-185 consequently remains `PARTIAL / NO-GO`; this report is not the missing
five-evidence release receipt.

## Audit initial

The repository was clean for tracked files at
`9d03e6377ce2f99430e28365411e7c1defd856ea`. Seventy-three pre-existing
untracked files were present, including the Hub audit, audit screenshots,
Selbrume walkthrough evidence, Narrative Studio reports, and a dynamic-shop
test. They were not edited, staged, deleted or moved.

Technical baseline:

- `apps/pokemap_hub` had no `lib/main.dart` or platform runner;
- no `.github/workflows` directory existed;
- only the in-process session factory existed;
- completion was still explicitly documented as a future narrative adapter;
- update save preparation stored only a rollback-availability boolean;
- the Phase 7 export test had one stale secret assertion;
- local toolchain was Flutter `3.46.0-0.3.pre`, framework revision
  `677d472756f83c14371dd8cc624387065f3d32a7`, Dart 3.13 beta, Xcode 27 beta;
- zero `Developer ID Application` identities were available.

## Independent passes

### Audit / Architecture

Verdict: `NO-GO`.

The architecture pass identified the authored completion command, durable save
update transaction, supervised desktop child and real application composition
as prerequisites. It specifically rejected any test that manually calls
`emitCompletion()` as proof of the authored final journey.

### Tests

Verdict: `NO-GO`, with reusable foundations.

The tests pass confirmed strong installer, atomic save, runtime and combat
foundations. It also found:

- the neutral Phase 7 fixtures were not complete mini-games;
- the full Hub suite could time out when the 25–28 second subprocess kill test
  ran in parallel under its 30-second per-test timeout;
- the same kill test passed in isolation;
- the targeted editor export group had one stale assertion, repaired in this
  change.

### Build / Validation

Verdict: `NO-GO` for signed distribution.

No Developer ID identity, notarization credentials, notarized artifact or cold
Mac/VM were available. The pass supplied the required structural and
fail-closed gates; they are now represented in code and CI.

### Implementation

The root implementation deliberately stopped at enforceable evidence:

- generic export/install/runtime smoke from an erased author workspace;
- installed New Game, atomic save, teardown and Continue;
- deterministic redacted receipt contract;
- library/catalog reference guards;
- a real macOS runner and production composition for library/import/smoke;
- Hardened Runtime, UTI/document declaration, native Finder-open forwarding
  and least-privilege release entitlements;
- a pinned CI Flutter revision and secret-isolated tagged release job;
- a verifier that mounts the DMG and requires its embedded app to pass Developer
  ID, runtime, entitlement, accepted notarization, stapling, Gatekeeper,
  artifact digest/size, bundle version/architectures and cold-install receipt
  checks;
- a hash comparison between the neutral package used by the release job and
  the artifact-bound cold-install receipt.

## Lot status

| Lot | Status | Fresh evidence | Remaining blocker |
|---|---|---|---|
| HUB-080 | `PARTIAL` | Neutral author project exports, source is erased, package installs and runtime map loads from the installed tree. | No real battle/story/ending in the neutral fixture. |
| HUB-081 | `PARTIAL / BLOCKED` | Export → install → New Game → atomic save → teardown → Continue works without source package/workspace. | No player-driven combat and no authored completion command. |
| HUB-082 | `PARTIAL / BLOCKED` | Existing install/update/repair/rollback/uninstall and save tests pass serially. Production composition refuses updates fail-closed. | No durable save-update batch transaction or cross-service kill recovery. |
| HUB-083 | `PARTIAL` | 100-game library round-trip, 2,000 JSON catalogue export/reopen, installer kill tests and save kill matrix pass serially. | No child player, no approved P95 baseline, no full 100-package nightly installation. |
| HUB-084 | `PARTIAL / BLOCKED` | Universal Release app builds; bundle/UTI/runtime/entitlements and release gates are tested. | Ad hoc signature, Gatekeeper rejection, no notarization/stapling/cold install. |

## Architecture decisions implemented

- `tool/pokemap_product_certification` is a test-only composition package. It
  may depend on editor, distribution, Hub and runtime without introducing
  `pokemap_hub → map_editor`.
- `apps/pokemap_hub` remains the product composition root.
- `MacOSHubComposition` uses the actual library, hostile inspector, installer,
  runtime load smoke, activity reader, preferences and file picker.
- macOS Finder open events are buffered by `AppDelegate`, then forwarded over
  a narrow method channel only after Dart reports that the import handler is
  ready.
- Public update is disabled by throwing before save preparation until a
  durable migration transaction exists. The previous installed release is
  preserved.
- The certification receipt requires exactly one entry for every Phase 8 gate,
  rejects incomplete evidence, requires a command/result digest for every
  passed entry, and redacts absolute paths and broader secret markers.
- Apple release credentials are referenced only through protected environment
  secrets in the tag-only job. They are never committed.

## Files changed

### Product runner and release pipeline

- `.github/workflows/pokemap_hub_product_certification.yml`
- `apps/pokemap_hub/.gitignore`
- `apps/pokemap_hub/.metadata`
- `apps/pokemap_hub/lib/main.dart`
- `apps/pokemap_hub/lib/src/platform/macos_hub_composition.dart`
- `apps/pokemap_hub/pubspec.yaml`
- `apps/pokemap_hub/pubspec.lock`
- `apps/pokemap_hub/macos/.gitignore`
- `apps/pokemap_hub/macos/ExportOptions-DeveloperID.plist`
- `apps/pokemap_hub/macos/Flutter/Flutter-Debug.xcconfig`
- `apps/pokemap_hub/macos/Flutter/Flutter-Release.xcconfig`
- `apps/pokemap_hub/macos/Flutter/GeneratedPluginRegistrant.swift`
- `apps/pokemap_hub/macos/Runner.xcodeproj/project.pbxproj`
- `apps/pokemap_hub/macos/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `apps/pokemap_hub/macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme`
- `apps/pokemap_hub/macos/Runner.xcworkspace/contents.xcworkspacedata`
- `apps/pokemap_hub/macos/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist`
- `apps/pokemap_hub/macos/Runner/AppDelegate.swift`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png`
- `apps/pokemap_hub/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png`
- `apps/pokemap_hub/macos/Runner/Base.lproj/MainMenu.xib`
- `apps/pokemap_hub/macos/Runner/Configs/AppInfo.xcconfig`
- `apps/pokemap_hub/macos/Runner/Configs/Debug.xcconfig`
- `apps/pokemap_hub/macos/Runner/Configs/Release.xcconfig`
- `apps/pokemap_hub/macos/Runner/Configs/Warnings.xcconfig`
- `apps/pokemap_hub/macos/Runner/DebugProfile.entitlements`
- `apps/pokemap_hub/macos/Runner/Info.plist`
- `apps/pokemap_hub/macos/Runner/MainFlutterWindow.swift`
- `apps/pokemap_hub/macos/Runner/Release.entitlements`
- `apps/pokemap_hub/macos/RunnerTests/RunnerTests.swift`
- `apps/pokemap_hub/test/platform/macos_distribution_contract_test.dart`
- `apps/pokemap_hub/test/release/macos_release_gate_test.dart`
- `apps/pokemap_hub/tool/release/macos_certification_receipt.schema.json`
- `apps/pokemap_hub/tool/release/verify_macos_distribution.dart`

The `macos/` runner and icon sizes are the standard Flutter-generated scaffold,
then reviewed and modified for PokeMap identifiers, target macOS 12, Hardened
Runtime, UTI/document association and release entitlements. Binary icon
contents are generated scaffold assets; no author/game asset was embedded.

### Cross-package certification harness

- `tool/pokemap_product_certification/README.md`
- `tool/pokemap_product_certification/pubspec.lock`
- `tool/pokemap_product_certification/pubspec.yaml`
- `tool/pokemap_product_certification/lib/pokemap_product_certification.dart`
- `tool/pokemap_product_certification/lib/src/certification_budgets.dart`
- `tool/pokemap_product_certification/lib/src/neutral_certification_game_fixture.dart`
- `tool/pokemap_product_certification/lib/src/product_certification_receipt.dart`
- `tool/pokemap_product_certification/test/certification_budgets_test.dart`
- `tool/pokemap_product_certification/test/build_neutral_package_artifact_test.dart`
- `tool/pokemap_product_certification/test/library_catalog_stress_test.dart`
- `tool/pokemap_product_certification/test/neutral_game_package_test.dart`
- `tool/pokemap_product_certification/test/offline_save_continue_test.dart`
- `tool/pokemap_product_certification/test/product_certification_receipt_test.dart`

### Baseline and documentation

- `packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart`
  — changed only the stale expected secret to the current fixture value.
- `docs/superpowers/plans/2026-07-25-pokemap-hub-phase-8.md`
- `reports/product/pokemap_hub/phase_8/product_certification_report_2026-07-25.md`

The complete text of every created source/configuration file is the content of
the listed tracked file; no generated excerpt or hidden patch is used. Binary
assets are limited to the seven generated app-icon PNG files listed above.

## Precise changed zones

- `pubspec.yaml`: version/build number plus direct `file_picker` and
  `path_provider`.
- `main.dart`: async bootstrap with safe startup error and ownership disposal.
- `macos_hub_composition.dart`: support root, compatibility contract, real
  installer, disk-space probe, runtime smoke, inbox, preferences, manual
  package picker and Finder package-open bridge.
- `Info.plist`: `CFBundleDocumentTypes` and
  `UTExportedTypeDeclarations` for `app.pokemap.game-package`.
- `AppInfo.xcconfig`: `PokeMap Hub`, `app.pokemap.hub`.
- `project.pbxproj`: macOS 12 minimum and Release Hardened Runtime.
- `Release.entitlements`: sandbox plus user-selected read-only files, no
  network entitlement.
- CI workflow: exact Flutter revision; all transitive source paths; PR verify
  job without secrets; tagged protected release job for inside-out Developer
  ID signing, entitlement verification, notarization, network-denied
  cold-install/relaunch and final verifier execution.
- release verifier/schema: mounts the DMG, verifies its embedded app, compares
  both artifact and neutral-package hashes, checks release entitlements and has
  no bypass flag.
- neutral fixture: explicit stable ID, launchable v2 map, author-only secrets
  and saves that must be projected out.
- editor test: one expectation string only.

## Fresh commands and exact results

### TDD red checks

- certification receipt/budget tests initially failed because the package
  library did not exist.
- neutral package test initially failed because
  `NeutralCertificationGameFixture` did not exist.
- macOS distribution contract tests initially failed all 3 assertions because
  the generated runner still had demo identifiers/no runtime/main.
- macOS release gate tests initially failed all 3 cases because verifier,
  workflow and schema were absent.
- stress test initially failed because catalogue helpers were absent, then once
  because the receipt filename did not match the library codec contract.

### Certification harness

```text
cd tool/pokemap_product_certification
flutter test
→ +9, All tests passed

flutter analyze
→ No issues found
```

Workloads executed by the suite:

- library save/reopen with 100 independent game IDs;
- export/reopen with 2,000 species JSON files;
- neutral source export, source deletion, real installer smoke;
- installed New Game, atomic save, unload and Continue under a network-denying
  `HttpOverrides` zone;
- canonical/redacted/fail-closed receipt codec with passed-evidence command and
  result-digest requirements;
- release-gate neutral-package artifact production under the Flutter runner.

The current 5 s / 30 s / 2 s constants are reference guards, not a validated
P95 claim.

### Hub

```text
cd apps/pokemap_hub
flutter test --concurrency=1
→ +109, All tests passed, 1m02s

flutter analyze
→ No issues found

flutter test \
  test/release/macos_release_gate_test.dart \
  test/platform/macos_distribution_contract_test.dart
→ +7, All tests passed
```

The suite was intentionally serialized because the subprocess save kill matrix
has a 30-second timeout and was observed by the Tests pass to be flaky when run
concurrently. In this fresh serial run its kill case completed around 25
seconds.

### Editor export baseline

```text
cd packages/map_editor
flutter test \
  test/game_export/generic_release_gate_test.dart \
  test/game_export/game_package_export_service_test.dart \
  test/game_export/runtime_project_projection_builder_test.dart
→ +7, All tests passed

flutter analyze
→ No issues found
```

### macOS Release build

First attempt:

```text
flutter build macos --release
→ BUILD FAILED
→ Xcode 27 supports deployment targets 12.0–27.0.x; generated target was 10.15
```

After changing all generated project targets to macOS 12:

```text
flutter build macos --release
→ success
→ PokeMap Hub.app, 67.6 MB
```

Fresh structural/signature results:

```text
plutil -lint macos/Runner/Info.plist
→ OK

plutil -extract ... "PokeMap Hub.app/Contents/Info.plist"
→ bundle ID: app.pokemap.hub
→ version/build: 0.1.0 / 1
→ exported UTI: app.pokemap.game-package
→ document extension: pokemapgame

lipo -archs ".../PokeMap Hub"
→ x86_64 arm64

codesign --verify --deep --strict --verbose=2 ".../PokeMap Hub.app"
→ valid on disk; satisfies its Designated Requirement

codesign -dv --verbose=4
→ Identifier=app.pokemap.hub
→ Signature=adhoc
→ TeamIdentifier=not set
→ flags include adhoc,runtime

codesign -d --entitlements :-
→ app sandbox: true
→ user-selected files read-only: true
→ get-task-allow absent
→ network client/server absent

spctl --assess --type execute --verbose=4
→ rejected
```

The build emitted Swift concurrency warnings from the third-party
`audioplayers_darwin 6.5.0` package and the standard Flutter run-script output
warning. They did not fail the build but must be revisited on the final pinned
stable toolchain.

### Hygiene

```text
git diff --check
→ no output
```

The path/secret scan found only negative test strings and existing architecture
guards. No private key, token value, local author path, Selbrume dependency or
developer-host production import was added.

Final hygiene also passed:

```text
ruby YAML.load_file(workflow)
→ workflow YAML: OK

plutil -lint Info.plist Release.entitlements ExportOptions-DeveloperID.plist
→ all OK

git diff --check
→ no output
```

The six files matched by the conservative path/coupling scan are the plan and
report prose, the neutral fixture's explicit non-Selbrume comment, and
pre-existing negative architecture/README assertions. Manual inspection found
no credential or production coupling.

## Known limitations and risks

1. `MacOSHubComposition` currently wires library/import/smoke, but Continue,
   New Game and maintenance UI callbacks are intentionally not yet wired to a
   production session surface.
2. `.pokemapgame` cold/warm Finder events are now forwarded to Dart, but this
   path has structural/build evidence only; a signed cold-install UI run must
   still prove the player-facing import result.
3. Updates are unavailable in this composition until save transactions are
   made durable.
4. No child-process desktop isolation, IPC framing, heartbeat watchdog or crash
   marker exists.
5. The neutral fixture validates installed runtime and saves, not a player
   battle/ending.
6. The CI workflow is implemented but has not executed on GitHub in this
   change; its notarized gate therefore remains unproven.
7. Signing credentials and notarization are external state. A passing YAML
   structure test cannot replace a protected tag run and cold-install receipt.
8. The standard Flutter app icon remains placeholder-quality product branding.
9. macOS 12 minimum was selected because the installed Xcode 27 no longer
   supports 10.15; public compatibility policy still needs product approval.
10. The release build is universal but not reproducible bit-for-bit once secure
    timestamps and Apple notarization tickets are introduced.
11. The certification receipt now binds passed entries to a command and result
    digest, but it is not a remote attestation system; protected-runner
    provenance remains an operational release-control concern.
12. The 100-game and 2,000-file tests are conservative contract/reference
    guards. They do not exercise a full 100-package dashboard workload or
    establish cold/warm P95 distributions.

## Self-critique

This change is valuable infrastructure, not a Phase 8 closure. The strongest
choice was keeping the gate red instead of manufacturing a completion event,
rollback callback or notarization claim. The final independent critique also
correctly identified that the app composition currently wires import but not
Continue/New Game/maintenance/session mounting; the neutral fixture is only a
map and spawn; lifecycle evidence is not integrated; and no desktop child
protocol exists. The security/proof issues that were safely local to this lot
were corrected: extracted-file secret inspection, wider receipt redaction,
evidence digests, Finder open forwarding, dependency-complete CI paths,
tracked tool lockfile, entitlement-preserving signing checks, DMG mounting and
neutral-package hash comparison.

The weakest point remains breadth: a runner, harness and CI were added while
three production contracts remain upstream. Future work should be split into
small prerequisite lots:

1. authored game-completion command and post-commit runtime bridge;
2. save update batch transaction with commit/abort/recovery;
3. supervised same-binary child-player protocol;
4. real neutral mini-game and thin public-input E2E;
5. measured CI baselines;
6. Developer ID/notarization/cold-install release execution.

No roadmap status is changed automatically by this report.

## Git state before commit

Tracked modifications are limited to the Hub pubspec/lock and the one editor
test expectation. All other implementation files above are new. The 73
pre-existing untracked user artifacts remain present and untouched. Staging
must include only the Phase 8 files listed in this report plus the ignored plan
file forced explicitly; it must not include the audit source or pre-existing
evidence.
