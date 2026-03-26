# map_runtime

A read-only Flame viewer for maps produced with the RPG Map Editor format.

This package loads a `project.json` file, resolves tileset assets, and renders the map — tile layers, terrain layers, path layers, entity sprites and collision overlays — inside a Flame scene.

**It is not a gameplay engine.** There is no player movement, no active collisions, no warps, no interactions, no dialogues, no encounters, no save system. Those responsibilities belong to a separate future package.

---

## What it does

- Loads a `project.json` and a map by ID from disk
- Applies JSON migrations (shared with the editor via `map_core`)
- Validates the project and map data
- Resolves all required tileset images
- Renders inside Flame: tile, terrain (with stable variant seeding), path (autotile), entity sprites (animated, aspect-ratio preserving), collision overlays
- Animates entity frames using `ProjectElementEntry.frames`

## What it does NOT do

- Player or NPC movement
- Gameplay collisions
- Warp or trigger activation
- Dialogue execution
- Wild encounter triggering
- Inventory, progression, combat, saves

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

  runApp(MaterialApp(
    home: Scaffold(
      body: GameWidget(game: RuntimeMapGame(bundle: bundle)),
    ),
  ));
}
```

`loadRuntimeMapBundle` validates the project and map and resolves all required tileset paths.
`RuntimeMapGame` loads the tileset images and renders the map. Pass it to a `GameWidget`.

## Public API

| Symbol | Description |
|---|---|
| `loadRuntimeMapBundle({projectFilePath, mapId})` | Loads and validates a project + map from disk. Returns a `RuntimeMapBundle`. |
| `RuntimeMapBundle` | Holds the resolved `ProjectManifest`, `MapData`, and tileset paths. |
| `RuntimeMapGame` | A `FlameGame` that renders the map. Loads images internally in `onLoad()`. |

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

- **Read-only.** No gameplay logic of any kind.
- **Local filesystem only.** Uses `dart:io`; Flutter Web is not supported.
- **`map_core` is a local path dependency.** Before this package can be published to pub.dev, `map_core` must be published independently, and the `path:` dependency replaced with a version constraint.
- The camera fits the entire map in the available viewport. Camera controls (pan, zoom) are not provided.

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
        map_layers_component.dart
        runtime_path_autotile.dart
  example/                    ← desktop preview app
```
