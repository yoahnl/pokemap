# map_player_ui

Reusable Flutter presentation package for the PokeMap player experience.

It owns:

- semantic light/dark/high-contrast themes;
- player surfaces, panels, buttons, badges, empty and progress states;
- French and English player localization;
- validated audio, display, motion, haptic, and input-hint preferences;
- declarative title, pause, loading, result, credits, and error surfaces.
- accessible battle HUD/commands, dialogue, notifications, and post-battle
  progression driven by immutable `map_runtime` snapshots;
- injected, preference-aware feedback and bounded presentation preloading.

It does not import `map_editor`, `pokemap_hub`, authored widgets, or developer
host code. It may consume the public presentation contracts from `map_runtime`;
the inverse dependency is forbidden. The Hub adapts the active session into
these data-only views.

Run validation from this directory:

```bash
flutter test
flutter analyze
```
