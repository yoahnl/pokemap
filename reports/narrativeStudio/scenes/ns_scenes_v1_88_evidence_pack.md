# NS-SCENES-V1-88 — Evidence Pack

Date : 2026-06-06

## 1. Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject
```

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
(aucune sortie)
```

```text
git diff --stat
(aucune sortie)
```

```text
git diff --name-only
(aucune sortie)
```

```text
git log --oneline -n 15
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance readiness drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
```

## 2. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/ccb0bdbc-97a9-4ec8-8aca-146f784cd6d7/pasted-text.txt
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_87_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_86_evidence_pack.md
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
packages/map_editor/lib/src/application/notifiers/editor_notifier.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
packages/map_runtime/lib/map_runtime.dart
```

## 3. Subagents / passes specialisees

Subagent A — MapData / TileLayer :

```text
Utiliser MapData.size/layers/tilesetId/placedElements.
Rendre seulement TileLayer visible V0 : tileId > 0, index y * width + x, tileId 1-based.
Tileset par layer.tilesetId puis fallback MapData.tilesetId.
Exclure CollisionLayer, ObjectLayer direct, entities, events, triggers, warps, gameplayZones.
Prevoir instructions bitmap : layerId, zOrder, tilesetId, sourceRect, destinationRect, opacity, diagnostics.
```

Subagent B — asset registry :

```text
Creer un registry/cache editor-only, hors build/paint.
Sortie : CinematicResolvedTilesetAsset avec ui.Image, tileWidth/tileHeight, columns/rows, status et diagnostic.
Gerer missing entry, missing file, invalid tile size, empty image, decodeFailed.
Reutiliser transparentColor via helper existant.
```

Subagent C — renderer :

```text
Créer un CustomPainter cinematic dedie.
Ne pas importer MapCanvas, MapGridPainter, Flame ou runtime.
Fit proportionnel V1-86, clip dans le frame, drawImageRect, grille optionnelle, border tokenise par palette.
```

Subagent D — tests / Visual Gate :

```text
Ajouter RED sur rendu bitmap quand image tileset disponible.
Ajouter fallback si asset indisponible.
Ajouter test de plan : uniquement TileLayer visible.
Ajouter Visual Gate sous dart-define NS_SCENES_V1_88_CAPTURE_CINEMATIC_MAP_BACKDROP_REAL_TILE_RENDERER.
```

Subagent E — UX :

```text
Remplacer le wording qui vend une preview future par un statut statique honnete.
Libelles retenus : Carte du projet (statique), Tiles reelles affichees, Decor seul, Sans acteurs, Sans lecture, Fallback structurel.
```

## 4. RED

Commande :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders real tile map backdrop when tileset image is available'
```

Sortie utile :

```text
test/cinematic_builder_workspace_test.dart:12:8: Error: Error when reading 'lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart': No such file or directory
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';
       ^
test/cinematic_builder_workspace_test.dart:8509:3: Error: Type 'CinematicMapBackdropTileRenderPlan' not found.
  CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan,
  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_builder_workspace_test.dart:311:22: Error: Undefined name 'CinematicResolvedTilesetAsset'.
        'lab_tiles': CinematicResolvedTilesetAsset.available(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_builder_workspace_test.dart:299:28: Error: Method not found: 'buildCinematicMapBackdropTileRenderPlan'.
    final tileRenderPlan = buildCinematicMapBackdropTileRenderPlan(
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_builder_workspace_test.dart:8539:15: Error: No named parameter with the name 'backdropTileRenderPlan'.
              backdropTileRenderPlan: backdropTileRenderPlan,
              ^^^^^^^^^^^^^^^^^^^^^^
lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:234:9: Context: Found this candidate, but the arguments don't match.
  const CinematicBuilderWorkspace({
        ^^^^^^^^^^^^^^^^^^^^^^^^^
Some tests failed.
```

Conclusion RED : le test demandait bien les nouveaux contrats et l'integration Builder avant implementation.

## 5. Code genere

### 5.1 `cinematic_map_backdrop_tile_render_plan.dart`

```dart
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

enum CinematicResolvedTilesetAssetStatus {
  available,
  missingTilesetEntry,
  missingFile,
  decodeFailed,
  invalidTileSize,
  emptyImage,
}

enum CinematicMapBackdropTileDiagnosticSeverity {
  info,
  warning,
  error,
}

final class CinematicMapBackdropTileDiagnostic {
  const CinematicMapBackdropTileDiagnostic({
    required this.code,
    required this.message,
    required this.severity,
    this.layerId,
    this.tilesetId,
  });

  final String code;
  final String message;
  final CinematicMapBackdropTileDiagnosticSeverity severity;
  final String? layerId;
  final String? tilesetId;
}

final class CinematicResolvedTilesetAsset {
  const CinematicResolvedTilesetAsset._({
    required this.tilesetId,
    required this.status,
    required this.diagnosticMessage,
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
  });

  factory CinematicResolvedTilesetAsset.available({
    required String tilesetId,
    required ui.Image image,
    required int tileWidth,
    required int tileHeight,
  }) {
    if (tileWidth <= 0 || tileHeight <= 0) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.invalidTileSize,
        message: 'Taille de tuile invalide pour le tileset $tilesetId.',
      );
    }
    if (image.width <= 0 || image.height <= 0) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.emptyImage,
        message: 'Image de tileset vide pour $tilesetId.',
      );
    }
    final columns = image.width ~/ tileWidth;
    final rows = image.height ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.invalidTileSize,
        message: 'Le tileset $tilesetId ne contient aucune tuile complete.',
      );
    }
    return CinematicResolvedTilesetAsset._(
      tilesetId: tilesetId,
      status: CinematicResolvedTilesetAssetStatus.available,
      diagnosticMessage: null,
      image: image,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columns: columns,
      rows: rows,
    );
  }

  factory CinematicResolvedTilesetAsset.diagnostic({
    required String tilesetId,
    required CinematicResolvedTilesetAssetStatus status,
    required String message,
  }) {
    return CinematicResolvedTilesetAsset._(
      tilesetId: tilesetId,
      status: status,
      diagnosticMessage: message,
      image: null,
      tileWidth: 0,
      tileHeight: 0,
      columns: 0,
      rows: 0,
    );
  }

  final String tilesetId;
  final CinematicResolvedTilesetAssetStatus status;
  final String? diagnosticMessage;
  final ui.Image? image;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final int rows;

  bool get isAvailable =>
      status == CinematicResolvedTilesetAssetStatus.available && image != null;
}

final class CinematicMapBackdropBitmapInstruction {
  const CinematicMapBackdropBitmapInstruction({
    required this.id,
    required this.layerId,
    required this.layerLabel,
    required this.layerKind,
    required this.zOrder,
    required this.tilesetId,
    required this.sourceRect,
    required this.destinationRect,
    required this.opacity,
    required this.tileId,
  });

  final String id;
  final String layerId;
  final String layerLabel;
  final CinematicMapBackdropLayerKind layerKind;
  final int zOrder;
  final String tilesetId;
  final ui.Rect sourceRect;
  final ui.Rect destinationRect;
  final double opacity;
  final int tileId;
}

final class CinematicMapBackdropTileRenderPlan {
  const CinematicMapBackdropTileRenderPlan({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesets,
    required this.instructions,
    required this.diagnostics,
  });

  final int mapWidth;
  final int mapHeight;
  final int tileWidth;
  final int tileHeight;
  final Map<String, CinematicResolvedTilesetAsset> tilesets;
  final List<CinematicMapBackdropBitmapInstruction> instructions;
  final List<CinematicMapBackdropTileDiagnostic> diagnostics;

  bool get hasBitmapInstructions => instructions.isNotEmpty;
  double get pixelWidth => mapWidth * tileWidth.toDouble();
  double get pixelHeight => mapHeight * tileHeight.toDouble();
}

CinematicMapBackdropTileRenderPlan buildCinematicMapBackdropTileRenderPlan({
  required MapData mapData,
  required ProjectManifest manifest,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
}) {
  final tileWidth = manifest.settings.tileWidth;
  final tileHeight = manifest.settings.tileHeight;
  final diagnostics = <CinematicMapBackdropTileDiagnostic>[];
  final instructions = <CinematicMapBackdropBitmapInstruction>[];
  final manifestTilesetIds = {
    for (final tileset in manifest.tilesets) tileset.id.trim(),
  }..remove('');

  if (tileWidth <= 0 || tileHeight <= 0) {
    diagnostics.add(
      const CinematicMapBackdropTileDiagnostic(
        code: 'invalidTileSize',
        message: 'Taille de tuile du projet invalide.',
        severity: CinematicMapBackdropTileDiagnosticSeverity.error,
      ),
    );
    return CinematicMapBackdropTileRenderPlan(
      mapWidth: mapData.size.width,
      mapHeight: mapData.size.height,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tilesets: tilesets,
      instructions: const <CinematicMapBackdropBitmapInstruction>[],
      diagnostics: diagnostics,
    );
  }

  var zOrder = 0;
  for (final layer in mapData.layers) {
    if (layer is! TileLayer) {
      continue;
    }
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }

    final tilesetId = (layer.tilesetId ?? mapData.tilesetId).trim();
    if (tilesetId.isEmpty) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: 'missingTilesetId',
          message: 'Le calque ${layer.name} n’a pas de tileset.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
        ),
      );
      continue;
    }

    if (!manifestTilesetIds.contains(tilesetId)) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: 'missingTilesetEntry',
          message: 'Tileset $tilesetId absent du manifeste.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
          tilesetId: tilesetId,
        ),
      );
      continue;
    }

    final tileset = tilesets[tilesetId];
    if (tileset == null || !tileset.isAvailable) {
      diagnostics.add(
        CinematicMapBackdropTileDiagnostic(
          code: tileset?.status.name ?? 'missingResolvedTileset',
          message: tileset?.diagnosticMessage ??
              'Image de tileset indisponible pour $tilesetId.',
          severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
          layerId: layer.id,
          tilesetId: tilesetId,
        ),
      );
      continue;
    }

    final image = tileset.image!;
    for (var y = 0; y < mapData.size.height; y += 1) {
      final rowStart = y * mapData.size.width;
      for (var x = 0; x < mapData.size.width; x += 1) {
        final tileIndex = rowStart + x;
        if (tileIndex >= layer.tiles.length) {
          continue;
        }
        final tileId = layer.tiles[tileIndex];
        if (tileId <= 0) {
          continue;
        }

        final sourceIndex = tileId - 1;
        final sourceX = (sourceIndex % tileset.columns) * tileWidth;
        final sourceY = (sourceIndex ~/ tileset.columns) * tileHeight;
        if (sourceX + tileWidth > image.width ||
            sourceY + tileHeight > image.height) {
          diagnostics.add(
            CinematicMapBackdropTileDiagnostic(
              code: 'sourceRectOutOfBounds',
              message: 'Tuile $tileId hors atlas pour $tilesetId.',
              severity: CinematicMapBackdropTileDiagnosticSeverity.warning,
              layerId: layer.id,
              tilesetId: tilesetId,
            ),
          );
          continue;
        }

        instructions.add(
          CinematicMapBackdropBitmapInstruction(
            id: '${layer.id}:$tileIndex',
            layerId: layer.id,
            layerLabel: layer.name,
            layerKind: CinematicMapBackdropLayerKind.tile,
            zOrder: zOrder,
            tilesetId: tilesetId,
            sourceRect: ui.Rect.fromLTWH(
              sourceX.toDouble(),
              sourceY.toDouble(),
              tileWidth.toDouble(),
              tileHeight.toDouble(),
            ),
            destinationRect: ui.Rect.fromLTWH(
              x * tileWidth.toDouble(),
              y * tileHeight.toDouble(),
              tileWidth.toDouble(),
              tileHeight.toDouble(),
            ),
            opacity: layer.opacity.clamp(0.0, 1.0).toDouble(),
            tileId: tileId,
          ),
        );
        zOrder += 1;
      }
    }
  }

  instructions.sort((a, b) => a.zOrder.compareTo(b.zOrder));
  return CinematicMapBackdropTileRenderPlan(
    mapWidth: mapData.size.width,
    mapHeight: mapData.size.height,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    tilesets: Map<String, CinematicResolvedTilesetAsset>.unmodifiable(tilesets),
    instructions:
        List<CinematicMapBackdropBitmapInstruction>.unmodifiable(instructions),
    diagnostics:
        List<CinematicMapBackdropTileDiagnostic>.unmodifiable(diagnostics),
  );
}
```

### 5.2 `cinematic_map_backdrop_tile_renderer.dart`

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'cinematic_map_backdrop_tile_render_plan.dart';

final class CinematicMapBackdropTileRenderPalette {
  const CinematicMapBackdropTileRenderPalette({
    required this.background,
    required this.border,
    required this.grid,
  });

  final Color background;
  final Color border;
  final Color grid;
}

class CinematicMapBackdropTileRenderPainter extends CustomPainter {
  const CinematicMapBackdropTileRenderPainter({
    required this.plan,
    required this.palette,
  });

  final CinematicMapBackdropTileRenderPlan plan;
  final CinematicMapBackdropTileRenderPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty ||
        plan.mapWidth <= 0 ||
        plan.mapHeight <= 0 ||
        plan.pixelWidth <= 0 ||
        plan.pixelHeight <= 0) {
      return;
    }

    final frame = _fittedMapRect(size);
    canvas.save();
    canvas.clipRect(frame);
    canvas.drawRect(
      frame,
      Paint()
        ..color = palette.background
        ..style = PaintingStyle.fill,
    );

    for (final instruction in plan.instructions) {
      final tileset = plan.tilesets[instruction.tilesetId];
      final image = tileset?.image;
      if (image == null) {
        continue;
      }
      final paint = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false;
      final opacity = instruction.opacity.clamp(0.0, 1.0).toDouble();
      if (opacity < 1) {
        paint.colorFilter = ColorFilter.mode(
          Color.fromRGBO(255, 255, 255, opacity),
          BlendMode.modulate,
        );
      }
      canvas.drawImageRect(
        image,
        instruction.sourceRect,
        _destinationRect(frame, instruction.destinationRect),
        paint,
      );
    }

    _paintGrid(canvas, frame);
    canvas.drawRect(
      frame.deflate(0.5),
      Paint()
        ..color = palette.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  Rect _fittedMapRect(Size size) {
    final horizontalScale = size.width / plan.pixelWidth;
    final verticalScale = size.height / plan.pixelHeight;
    final scale = math.min(horizontalScale, verticalScale);
    final width = plan.pixelWidth * scale;
    final height = plan.pixelHeight * scale;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  Rect _destinationRect(Rect frame, Rect destinationRect) {
    final scaleX = frame.width / plan.pixelWidth;
    final scaleY = frame.height / plan.pixelHeight;
    return Rect.fromLTWH(
      frame.left + destinationRect.left * scaleX,
      frame.top + destinationRect.top * scaleY,
      destinationRect.width * scaleX,
      destinationRect.height * scaleY,
    );
  }

  void _paintGrid(Canvas canvas, Rect frame) {
    final cellWidth = frame.width / plan.mapWidth;
    final cellHeight = frame.height / plan.mapHeight;
    if (math.min(cellWidth, cellHeight) < 10) {
      return;
    }
    final gridPaint = Paint()
      ..color = palette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (var x = 1; x < plan.mapWidth; x += 1) {
      final dx = frame.left + x * cellWidth;
      canvas.drawLine(
          Offset(dx, frame.top), Offset(dx, frame.bottom), gridPaint);
    }
    for (var y = 1; y < plan.mapHeight; y += 1) {
      final dy = frame.top + y * cellHeight;
      canvas.drawLine(
          Offset(frame.left, dy), Offset(frame.right, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CinematicMapBackdropTileRenderPainter oldDelegate) {
    return oldDelegate.plan != plan || oldDelegate.palette != palette;
  }
}
```

### 5.3 `cinematic_tileset_asset_registry.dart`

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import '../../../application/services/tileset_transparent_color_processor.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';

final class CinematicTilesetAssetRegistry {
  CinematicTilesetAssetRegistry();

  final Map<String, Future<CinematicResolvedTilesetAsset>> _cache = {};

  Future<CinematicResolvedTilesetAsset> resolve({
    required ProjectTilesetEntry? tileset,
    required String? absolutePath,
    required int tileWidth,
    required int tileHeight,
  }) {
    final tilesetId = tileset?.id.trim() ?? '';
    if (tileset == null || tilesetId.isEmpty) {
      return Future.value(
        CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.missingTilesetEntry,
          message: 'Entrée tileset absente du manifeste.',
        ),
      );
    }
    if (tileWidth <= 0 || tileHeight <= 0) {
      return Future.value(
        CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.invalidTileSize,
          message: 'Taille de tuile invalide pour le tileset $tilesetId.',
        ),
      );
    }
    final path = absolutePath?.trim();
    if (path == null || path.isEmpty) {
      return Future.value(
        CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.missingFile,
          message: 'Image de tileset introuvable pour $tilesetId.',
        ),
      );
    }

    final key =
        '$tilesetId|$path|$tileWidth|$tileHeight|${tileset.transparentColor?.toHexRgb() ?? ''}';
    return _cache.putIfAbsent(
      key,
      () => _load(
        tileset: tileset,
        absolutePath: path,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
    );
  }

  void invalidateTileset(String tilesetId) {
    final prefix = '${tilesetId.trim()}|';
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() {
    _cache.clear();
  }

  Future<CinematicResolvedTilesetAsset> _load({
    required ProjectTilesetEntry tileset,
    required String absolutePath,
    required int tileWidth,
    required int tileHeight,
  }) async {
    final tilesetId = tileset.id.trim();
    try {
      final file = File(absolutePath);
      if (!await file.exists()) {
        return CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.missingFile,
          message: 'Image de tileset introuvable pour $tilesetId.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return CinematicResolvedTilesetAsset.diagnostic(
          tilesetId: tilesetId,
          status: CinematicResolvedTilesetAssetStatus.emptyImage,
          message: 'Image de tileset vide pour $tilesetId.',
        );
      }
      var displayBytes = bytes;
      final transparentColor = tileset.transparentColor;
      if (transparentColor != null) {
        try {
          displayBytes = applyTilesetTransparentColorToPngBytes(
            imageBytes: bytes,
            transparentColor: transparentColor,
          );
        } catch (_) {
          displayBytes = bytes;
        }
      }
      final codec = await ui.instantiateImageCodec(displayBytes);
      final frame = await codec.getNextFrame();
      return CinematicResolvedTilesetAsset.available(
        tilesetId: tilesetId,
        image: frame.image,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      );
    } catch (_) {
      return CinematicResolvedTilesetAsset.diagnostic(
        tilesetId: tilesetId,
        status: CinematicResolvedTilesetAssetStatus.decodeFailed,
        message: 'Image de tileset illisible pour $tilesetId.',
      );
    }
  }
}
```

## 6. Verification GREEN

```text
cd packages/map_editor && dart format lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Formatted 8 files (3 changed) in 0.19 seconds.
```

```text
cd packages/map_editor && dart format test/cinematic_builder_workspace_test.dart
Formatted 1 file (0 changed) in 0.05 seconds.
```

```text
cd packages/map_editor && dart format lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart test/cinematic_builder_workspace_test.dart
Formatted test/cinematic_builder_workspace_test.dart
Formatted 2 files (1 changed) in 0.06 seconds.
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders real tile map backdrop when tileset image is available'
00:03 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'falls back to structural backdrop when tileset image is unavailable'
00:02 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'builds bitmap instructions only from visible tile layers'
00:03 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
00:02 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'does not start preview playback'
00:02 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart --plain-name 'wires loaded stage map snapshot into static backdrop preview'
00:03 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_88_CAPTURE_CINEMATIC_MAP_BACKDROP_REAL_TILE_RENDERER=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-88 cinematic map backdrop real tile renderer when requested'
00:03 +1: All tests passed!
```

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 8 items...
No issues found! (ran in 1.6s)
```

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Suites completes :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:23 +155: All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:05 +15: All tests passed!
```

Analyse globale editor :

```text
cd packages/map_editor && flutter analyze
344 issues found. (ran in 3.2s)
```

Erreurs bloquantes hors scope V1-88 :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7
The named parameter 'dbSymbol' isn't defined.

lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3
Undefined class 'PokemonMoveAimedTarget'.

lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10
The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository'.
```

## 7. Visual Gate

```text
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
-rw-r--r--  1 karim  staff  252999 Jun  6 20:00 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
407468fb38996324c12d024c0f3fc93419181bc3fa30612457edfac24f694089  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
```

Inspection visuelle via Codex computer use : image 1663x926, Builder Cinematic, preview statique bitmap visible, timeline conservee, inspecteur visible, badges statiques, aucun acteur rendu.

## 8. Anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
(aucune sortie)
```

```text
rg -n "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|MapLayersComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime" <fichiers V1-88>
(aucune sortie)
```

```text
rg -n "MapCanvas\\(|MapGridPainter\\(" <fichiers V1-88>
(aucune sortie)
```

```text
rg -n "fakeMap|fakeTile|mockTile|hardcoded.*map|Selbrume|bourg_selbrume|port_brisants|lysa|mael|maël" <code produit V1-88>
(aucune sortie)
```

```text
git diff -U0 -- <fichiers UI V1-88> | rg "^\\+.*(Color\\(0x|Colors\\.)"
(aucune sortie)
```

I/O image detectee :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:80:      final file = File(absolutePath);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:88:      final bytes = await file.readAsBytes();
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:108:      final codec = await ui.instantiateImageCodec(displayBytes);
```

Interpretation : I/O limitee au registre asset editor-only, pas dans le painter, pas dans `build()`.

Hits attendus non-produit :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:4100:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:4101:    expect(find.text('scrub'), findsNothing);
```

Interpretation : assertions de test qui verifient l'absence de seek/scrub.

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:8623:    if (animation.state == CharacterAnimationState.idle &&
```

Interpretation : ligne existante de validation Character Library, pas un renderer acteur V1-88.

## 9. Auto-review

Ce qui est conforme au prompt :

- renderer statique editor-only/read-only ;
- plan de rendu base sur `MapData` + manifest + tilesets resolus ;
- images resolues hors paint/build ;
- fallback structurel visible ;
- proportions V1-86 preservees via Visual Gate 1663x926 ;
- aucun runtime/Flame/playback/acteur ;
- rapports et roadmaps mis a jour ;
- code genere inclus dans ce pack.

Risques restants :

- wiring parent vers le registre asset non cable dans ce lot ;
- V0 limite aux `TileLayer` ;
- opacite appliquee par le painter et verifiee au niveau du plan, sans test pixel direct ;
- sampling pixel direct abandonne car `RenderRepaintBoundary.toImage` a bloque dans l'environnement de test.

Decision de statut : `NS-SCENES-V1-88` peut etre marque `DONE` avec ces limites declarees.

## 10. Git final

```text
git diff --check
(aucune sortie)
```

```text
git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |  14 +-
 .../cinematic_map_backdrop_preview_panel.dart      | 199 +++++++--
 .../cinematics/cinematics_library_workspace.dart   |  35 ++
 .../test/cinematic_builder_workspace_test.dart     | 465 ++++++++++++++++++++-
 .../test/cinematics_library_workspace_test.dart    |   6 +-
 .../scenes/road_map_scene_builder_authoring.md     |  20 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  24 +-
 7 files changed, 707 insertions(+), 56 deletions(-)
```

Note : `git diff --stat` n'inclut pas les fichiers non suivis.

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_88_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.png
```
