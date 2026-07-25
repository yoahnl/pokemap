# PokeMap Hub Phase 6 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Replace the official player product’s provisional combat, dialogue,
notification, and post-battle presentation with one accessible Flutter
presentation path while preserving Flame for the scene and `map_battle` for
rules.

**Architecture:** `map_runtime` remains the authority for immutable snapshots,
command validation, battle/dialogue state, and Flame scene rendering.
`map_player_ui` depends on the public runtime presentation contracts and owns
the themed Flutter widgets. `apps/pokemap_hub` binds a `PlayableMapGame` to
those widgets and injects audio/haptic/image ports. The existing Flame widgets
remain temporary developer-host fallbacks; `map_runtime` never depends on
`map_player_ui`.

**Tech Stack:** Dart, Flutter, Flame, `ValueListenable`, immutable presentation
snapshots, widget tests, runtime contract tests.

---

## Task 1: HUB-060 — Canonical battle presentation and command authority

**Files:**

- Modify:
  `packages/map_runtime/lib/src/presentation/flutter/battle_command_overlay_snapshot.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Modify: `packages/map_runtime/lib/map_runtime.dart`
- Test:
  `packages/map_runtime/test/battle_presentation_command_contract_test.dart`

- [x] Add snapshot revision, presentation phase, forced-replacement metadata,
      target/selection semantics, and a closed command union.
- [x] Write a failing test proving stale revisions, disabled entries, and
      invalid back commands are rejected.
- [x] Add one `dispatchBattlePresentationCommand` entry point on
      `PlayableMapGame`; keep old methods as compatibility shims only.
- [x] Prove forced replacement exposes selectable honest reserve indexes and
      cannot navigate back.

**DONE:** Official UI commands enter the runtime through one guarded dispatch
method, the snapshot is the only command truth, and `FG-052` has runtime proof.

## Task 2: HUB-061/HUB-062 — Themed battle HUD and subflows

**Files:**

- Modify: `packages/map_player_ui/pubspec.yaml`
- Create:
  `packages/map_player_ui/lib/src/battle/player_battle_overlay.dart`
- Modify: `packages/map_player_ui/lib/map_player_ui.dart`
- Test: `packages/map_player_ui/test/player_battle_overlay_test.dart`

- [x] Write failing widget tests for portrait, landscape, desktop, 48 px
      targets, focus, semantics, reduced motion, HP/status, PP/type, bag,
      medicine target, party, and forced replacement.
- [x] Render Flame-owned scene rectangles with semantic player tokens only.
- [x] Dispatch the closed runtime command union and reject local gameplay
      mutation.
- [x] Keep unavailable choices visible with player-safe explanations.

**DONE:** HUD, commands, bag, team, medicine target, statuses and forced switch
are responsive and accessible without debug vocabulary.

## Task 3: HUB-064 — Dialogue and notification Flutter contracts

**Files:**

- Create:
  `packages/map_runtime/lib/src/presentation/flutter/dialogue_presentation_snapshot.dart`
- Create:
  `packages/map_runtime/lib/src/presentation/flutter/runtime_notification_snapshot.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Create:
  `packages/map_player_ui/lib/src/dialogue/player_dialogue_overlay.dart`
- Create:
  `packages/map_player_ui/lib/src/feedback/player_notification_overlay.dart`
- Test:
  `packages/map_runtime/test/dialogue_presentation_contract_test.dart`
- Test: `packages/map_player_ui/test/player_dialogue_overlay_test.dart`

- [x] Write failing contract tests for speaker/body parsing, reveal/advance,
      choice selection, stale command rejection, and notification expiry.
- [x] Publish dialogue and notification snapshots through bounded
      `ValueListenable`s while retaining the Flame fallback.
- [x] Render speaker, optional portrait, text, choices, progress hint,
      keyboard/gamepad/touch actions, text scale and semantics in Flutter.

**DONE:** The official player can disable the fixed Flame dialogue canvas and
use one accessible Flutter overlay without changing narrative rules.

## Task 4: HUB-063/HUB-064 — Result and post-battle progression

**Files:**

- Create:
  `packages/map_runtime/lib/src/presentation/flutter/post_battle_presentation_snapshot.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/post_battle_progression_overlay_component.dart`
- Modify:
  `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Create:
  `packages/map_player_ui/lib/src/battle/player_post_battle_overlay.dart`
- Test:
  `packages/map_runtime/test/post_battle_presentation_contract_test.dart`
- Test:
  `packages/map_player_ui/test/player_post_battle_overlay_test.dart`

- [x] Write failing tests for ordered result messages, move/evolution
      decisions, disabled invalid decisions, completion, and failure.
- [x] Publish immutable post-battle snapshots from the existing transactional
      coordinator; do not duplicate reward rules.
- [x] Render victory/defeat/capture, XP, level, move, evolution and authored
      rewards with accessible choice controls.

**DONE:** Every critical post-battle change remains ordered, acknowledged and
transactional through Flutter.

## Task 5: HUB-065 — Feedback, reduced motion and preloading

**Files:**

- Create:
  `packages/map_player_ui/lib/src/feedback/player_feedback_controller.dart`
- Create:
  `packages/map_player_ui/lib/src/foundation/player_asset_preloader.dart`
- Create:
  `apps/pokemap_hub/lib/src/ui/player/hub_runtime_presentation.dart`
- Modify: `apps/pokemap_hub/lib/pokemap_hub_ui.dart`
- Test:
  `packages/map_player_ui/test/player_feedback_controller_test.dart`
- Test:
  `apps/pokemap_hub/test/ui/hub_runtime_presentation_test.dart`

- [x] Write failing tests for event deduplication, volume projection, haptic
      opt-out, reduced-motion duration, preload deduplication and asset limits.
- [x] Add injected audio/haptic ports with no network or engine dependency.
- [x] Bind battle, dialogue, notification and post-battle listenables over the
      Flame game surface and preload only referenced local UI assets.
- [x] Force the official Hub path to Flutter presentation while leaving the
      developer host fallback untouched.

**DONE:** Feedback respects preferences, assets are bounded/preloaded, and the
official Hub has one composition widget for all runtime presentation.

## Task 6: Architecture, regression and commit

**Verification targets:**

- Existing:
  `apps/pokemap_hub/test/architecture/hub_architecture_boundary_test.dart`
- Existing: `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

- [x] Format only Phase 6 files.
- [x] Run `flutter test` and `flutter analyze` in `packages/map_player_ui`.
- [x] Run focused presentation tests, the battle smoke, full `flutter test`,
      and `flutter analyze` in `packages/map_runtime`.
- [x] Run full `flutter test` and `flutter analyze` in `apps/pokemap_hub`.
- [x] Prove `map_runtime` has no `map_player_ui` dependency and
      `examples/playable_runtime_host` has no tracked change.
- [x] Review secrets, raw paths, focus, semantics, reduced motion, lifecycle,
      stale commands and pre-existing untracked-file preservation.
- [x] Stage only Phase 6 files and create one commit.

**DONE:** Phase 6 tests and analyzers are freshly green, the architecture gate
passes, the pre-existing Selbrume regression failures from the product audit
remain documented, no user file is staged, and one Phase 6 commit exists.
