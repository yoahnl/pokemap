# PokeMap Hub Phase 5 Implementation Plan

> **Source of truth:** `reports/product/pokemap_hub_player_application_audit_2026-07-24.md`
>
> **Lots:** HUB-050, HUB-051, HUB-052, HUB-053, HUB-054

**Goal:** Deliver the first player-facing PokeMap Hub UI on top of the stable
distribution, save, library, and player-shell contracts from Phases 1–4.

**Architecture:** Add a reusable Flutter-only `map_player_ui` package for
player design tokens, localization, focus, title, and pause surfaces. Keep
Hub-specific library and installation models in `apps/pokemap_hub`; adapt them
to UI view data there. `map_runtime` remains independent from
`map_player_ui`, and `examples/playable_runtime_host` remains unchanged.

**Tech stack:** Dart, Flutter Material, `ChangeNotifier`, widget tests,
filesystem-backed JSON preferences.

---

## Task 1: HUB-050 — Player UI foundations

**Files:**

- Create: `packages/map_player_ui/pubspec.yaml`
- Create: `packages/map_player_ui/analysis_options.yaml`
- Create: `packages/map_player_ui/lib/map_player_ui.dart`
- Create: `packages/map_player_ui/lib/src/theme/pokemap_player_theme.dart`
- Create: `packages/map_player_ui/lib/src/foundation/player_components.dart`
- Test: `packages/map_player_ui/test/pokemap_player_theme_test.dart`

**Steps:**

1. Write widget tests for light/dark semantic tokens, focus visibility,
   disabled explanations, and minimum touch target size.
2. Run the tests and confirm they fail because the package API is absent.
3. Add semantic colors, typography, spacing, radii, motion, focus, surfaces,
   buttons, badges, empty states, and progress components.
4. Run focused tests and `flutter analyze`.

**DONE:** Player surfaces use only semantic theme values, keyboard focus is
visible, selection is not color-only, and controls meet the 48 px target.

## Task 2: HUB-054 — Localization, accessibility, and preferences

**Files:**

- Create: `packages/map_player_ui/lib/src/localization/player_localizations.dart`
- Create: `packages/map_player_ui/lib/src/preferences/player_preferences.dart`
- Create: `apps/pokemap_hub/lib/src/ui/preferences/hub_preferences_store.dart`
- Test: `packages/map_player_ui/test/player_localizations_test.dart`
- Test: `apps/pokemap_hub/test/ui/hub_preferences_store_test.dart`

**Steps:**

1. Write failing tests for French/English labels, locale fallback, text scale,
   reduced motion, high contrast, audio, and haptics.
2. Add immutable player preferences and a two-locale delegate.
3. Add an atomic, versioned JSON preference store under Application Support.
4. Verify corrupt settings fall back safely without exposing file paths.

**DONE:** Preferences survive restart, defaults are safe, and the app exposes
French and English with accessible semantics and scale limits.

## Task 3: HUB-051/HUB-052 — Hub home, library, and game detail

**Files:**

- Create: `apps/pokemap_hub/lib/pokemap_hub_ui.dart`
- Create: `apps/pokemap_hub/lib/src/ui/hub_dashboard_controller.dart`
- Create: `apps/pokemap_hub/lib/src/ui/hub_app.dart`
- Create: `apps/pokemap_hub/lib/src/ui/hub_shell.dart`
- Create: `apps/pokemap_hub/lib/src/ui/hub_game_views.dart`
- Test: `apps/pokemap_hub/test/ui/hub_dashboard_controller_test.dart`
- Test: `apps/pokemap_hub/test/ui/hub_shell_test.dart`

**Steps:**

1. Write failing controller tests for empty, ready, search, selection,
   installation progress, diagnostics, refresh, and resume metadata.
2. Write failing widget tests for guided empty state, recent games, responsive
   library grid, game detail actions, and disabled action explanations.
3. Implement immutable Hub snapshots and injected action ports.
4. Implement responsive desktop navigation and compact bottom navigation using
   `LayoutBuilder`, with bounded content widths and focus traversal.
5. Verify no developer-only vocabulary or controls appear.

**DONE:** The Hub can render empty and populated libraries, expose import and
maintenance actions, show a game detail, and work at desktop/mobile widths.

## Task 4: HUB-053 — Title and pause player shell

**Files:**

- Create: `packages/map_player_ui/lib/src/player/player_title_screen.dart`
- Create: `packages/map_player_ui/lib/src/player/player_pause_menu.dart`
- Create: `packages/map_player_ui/lib/src/player/player_session_surfaces.dart`
- Create: `apps/pokemap_hub/lib/src/ui/player/hub_player_shell_view.dart`
- Test: `packages/map_player_ui/test/player_title_screen_test.dart`
- Test: `packages/map_player_ui/test/player_pause_menu_test.dart`
- Test: `apps/pokemap_hub/test/ui/hub_player_shell_view_test.dart`

**Steps:**

1. Write failing tests for title action availability, branded presentation,
   keyboard activation, pause layout, and the absence of global Shop/Center/PC.
2. Implement view-data-driven title, pause, loading, result, credits, and
   recoverable error surfaces.
3. Adapt `PlayerShellSnapshot` to those surfaces in the Hub package.
4. Verify lifecycle and session commands remain owned by Phase 4 controllers.

**DONE:** Title and pause surfaces work with keyboard/touch, use explicit
capability availability, and return cleanly to title or Hub.

## Task 5: Verification and commit

**Files:**

- Modify: `apps/pokemap_hub/pubspec.yaml`
- Modify: `apps/pokemap_hub/lib/pokemap_hub_player.dart`
- Modify: `apps/pokemap_hub/test/architecture/hub_architecture_boundary_test.dart`

**Steps:**

1. Format only Phase 5 files.
2. Run `flutter test` and `flutter analyze` in `packages/map_player_ui`.
3. Run targeted UI, architecture, Phase 4 player, and full tests in
   `apps/pokemap_hub`, then `flutter analyze`.
4. Prove `map_runtime` does not depend on `map_player_ui` and the developer
   host was not changed.
5. Review the diff for security, accessibility, responsive layout, and
   accidental user-file overlap.
6. Stage only the reviewed Phase 5 files and commit once.

**DONE:** All focused verification is fresh and green, the working tree still
contains every pre-existing untracked user file, and one Phase 5 commit exists.
