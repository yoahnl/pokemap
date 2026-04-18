# map_runtime

A Flame-based runtime for maps produced with the RPG Map Editor format.

This package loads a `project.json` file, resolves tileset assets, and renders the map — tile layers, terrain layers, path layers, entity sprites and collision overlays — inside a Flame scene. It also provides `PlayableMapGame`, a playable game loop with keyboard-driven player movement, collision detection, warp transitions, entity interaction, wild encounter triggering, trainer battle start requests, battle overlay handoff, and narrow battle outcome write-back.

---

## What it does

- Loads a `project.json` and a map by ID from disk
- Applies JSON migrations (shared with the editor via `map_core`)
- Validates the project and map data
- Resolves all required tileset images
- Renders inside Flame: tile, terrain (with stable variant seeding), path (autotile), entity sprites (animated, aspect-ratio preserving), collision overlays
- Animates entity frames using `ProjectElementEntry.frames`
- Provides a real runtime battle handoff to `map_battle` for the currently supported singles slice
- Triggers real wild encounters and trainer battles in `PlayableMapGame`
- Applies narrow runtime write-back for the supported battle slice:
  - party HP updates
  - trainer defeated flags
  - minimal wild capture
  - whiteout-lite

## What it does NOT do

- Dialogue execution (text is shown as a 2-second overlay, not a full dialogue system)
- Full standalone RPG systems outside the currently supported slice
- Full inventory/progression UX or broad combat persistence beyond the narrow battle write-back above
- Full Showdown-like battle mechanics, requests, targeting, or persistence

## Requirements

- Flutter `>=3.10.0`
- Dart `>=3.0.0`
- [`flame`](https://pub.dev/packages/flame) `^1.36.0`
- [`map_core`](https://git.yoahn.me/yoahn/pokemonProject) (local path dependency — see note below)

The package reads map files from the **local filesystem** (`dart:io`). It targets desktop and mobile platforms. It does not support Flutter Web.

## Usage

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

void main() async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: '/path/to/project.json',
    mapId: 'my_map',
  );

  // Read-only viewer
  runApp(MaterialApp(
    home: Scaffold(
      body: GameWidget(game: RuntimeMapGame(bundle: bundle)),
    ),
  ));

  // Or: playable game (arrows/WASD to move, E/Space to interact)
  runApp(MaterialApp(
    home: Scaffold(
      body: GameWidget(
        game: PlayableMapGame(
          bundle: bundle,
          projectFilePath: '/path/to/project.json',
        ),
      ),
    ),
  ));
}
```

`loadRuntimeMapBundle` validates the project and map and resolves all required tileset paths.
`RuntimeMapGame` loads the tileset images and renders the map as a read-only viewer.
`PlayableMapGame` adds keyboard movement, collision, warps, entity interaction, battle triggering, battle overlay handoff, and narrow outcome write-back for the currently supported battle slice.

## Public API

| Symbol | Description |
|---|---|
| `loadRuntimeMapBundle({projectFilePath, mapId})` | Loads and validates a project + map from disk. Returns a `RuntimeMapBundle`. |
| `RuntimeMapBundle` | Holds the resolved `ProjectManifest`, `MapData`, and tileset paths. |
| `RuntimeMapGame` | A `FlameGame` that renders the map (read-only). |
| `PlayableMapGame` | A `FlameGame` with player movement (arrows/WASD), collision, warp transitions, entity interaction (E/Space), battle triggering, and narrow battle outcome write-back for the supported slice. |

All other types and functions in this package are internal.

## Exceptions

Thrown by `loadRuntimeMapBundle`, from `map_core`:

| Exception | When |
|---|---|
| `ProjectLoadException` | `project.json` not found or invalid |
| `MapLoadException` | Map file not found, map ID unknown, or invalid map data |
| `AssetNotFoundException` | A required tileset file is missing from disk |
| `ValidationException` | Project or map data fails schema validation |

## Limitations

- **`PlayableMapGame` is keyboard-only.** No gamepad, touch, or on-screen controls.
- **Local filesystem only.** Uses `dart:io`; Flutter Web is not supported.
- **`map_core` is a local path dependency.** Before this package can be published to pub.dev, `map_core` must be published independently, and the `path:` dependency replaced with a version constraint.
- The camera fits the entire map in the available viewport. Camera controls (pan, zoom) are not provided.
- Battle support in this package is intentionally bounded to the currently supported `map_battle` slice; unsupported move or mechanic families still fail or are filtered explicitly rather than being simulated loosely.

## Project structure

```
packages/map_runtime/
  lib/
    map_runtime.dart          ← public barrel (3 exports)
    src/
      application/
        load_runtime_map_bundle.dart
        runtime_map_bundle.dart
        runtime_manifest_tilesets.dart
      infrastructure/
        tile_image_loader.dart
      presentation/flame/
        runtime_map_game.dart
        playable_map_game.dart
        player_component.dart
        map_layers_component.dart
        runtime_path_autotile.dart
  example/                    ← desktop preview app
```
