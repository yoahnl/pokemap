# Lot 89 — Runtime Surface Tileset Collection + Resolver V0

## 1. Résumé exécutif honnête
Lot 89 ajoute la première brique runtime Surface sans dessiner dans Flame.

Implémenté :
- collecte runtime des tilesets Surface nécessaires depuis les `SurfaceLayer` placés ;
- scan de toutes les frames des animations référencées par les presets placés ;
- resolver runtime pur `SurfaceLayer -> SurfaceRuntimeRenderInstruction` ;
- fallback par skip sans crash pour références incomplètes ;
- intégration de la collecte dans `collectAllRuntimeTilesetIds` ;
- commentaire no-op explicite dans `MapLayersComponent`, sans rendu.

Non implémenté volontairement : rendu Flame, `drawImageRect`, `SpriteBatch`, clock runtime, gameplay surf/tall grass, migration legacy.

Verdict : lot validable comme fondation pour le Lot 90. Le rendu réel reste à faire.

## 2. Périmètre
Modifié uniquement dans `packages/map_runtime` et création du rapport sous `reports/surface`.

Aucun changement `map_core`, `map_editor`, `map_gameplay`, `map_battle`, JSON, `ProjectManifest`, runtime renderer Flame.

## 3. Gate 0 — status initial
Commandes lancées avant modification depuis `/Users/karim/Project/pokemonProject` :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
# no output, clean

git diff --stat
# no output

git log --oneline -n 10
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
```

Changements préexistants : aucun.

## 4. Audit runtime tilesets
Audits obligatoires lancés :

```bash
rg -n "SurfaceLayer|surfacePresetId|MapLayer.surface|runtime_manifest_tilesets|tileset|tilesets|ProjectTilesetEntry|ProjectManifest|MapLayer" packages/map_runtime packages/map_core packages/map_gameplay packages/map_editor
rg -n "resolveSurfaceVariantRoleForPlacement|SurfaceTilePreviewInstruction|surface_tile_preview|SurfaceLayer|SurfaceCellPlacement" packages/map_core packages/map_editor packages/map_runtime
rg -n "MapLayersComponent|TileLayer|TerrainLayer|PathLayer|Flame|SpriteBatch|drawImage|Image|images|load" packages/map_runtime packages/map_gameplay
```

Constats :
- `loadRuntimeMapBundle` charge manifest + map, appelle `collectAllRuntimeTilesetIds`, puis résout les chemins absolus via `manifest.tilesets`.
- `collectAllRuntimeTilesetIds` agrégeait déjà map/tile layers, terrain/path presets, éléments, personnages.
- `SurfaceLayer` était explicitement ignoré dans `runtime_manifest_tilesets.dart`.
- `RuntimeMapBundle.tilesetAbsolutePathsById` est ensuite utilisé par `RuntimeMapGame` / `PlayableMapGame` pour charger les images.
- Le bon point d’insertion pour les surfaces est donc la collecte de tilesets, pas `MapLayersComponent`.

## 5. Audit SurfaceLayer runtime no-op actuel
`MapLayersComponent` ne rend pas les `SurfaceLayer` ; il possède seulement un commentaire de tolérance no-op. Le lot conserve ce comportement : aucun composant Flame Surface, aucun `drawImageRect`, aucune image chargée spécifiquement dans ce composant.

## 6. Architecture retenue
Trois helpers runtime-only :
- `surface_runtime_tileset_collector.dart` : collecte de `tilesetId` à partir des placements Surface et du catalogue.
- `surface_runtime_render_instruction.dart` : modèle pur d’instruction de rendu futur.
- `surface_runtime_resolver.dart` : résolution `placement -> rôle -> animation -> frame -> atlas -> instruction`.

Le resolver est pur : pas de Flame, pas d’image, pas de mutation, pas de persistance du rôle calculé.

## 7. Collecte tilesets Surface
Pipeline :

```text
MapData.layers.whereType<SurfaceLayer>()
→ placements surfacePresetId distincts
→ ProjectSurfaceCatalog.presets
→ variantAnimations refs
→ ProjectSurfaceCatalog.animations
→ toutes les frames
→ frame.tileRef.atlasId
→ ProjectSurfaceCatalog.atlases
→ atlas.tilesetId
```

Toutes les frames sont scannées, pas seulement la première. Les ids sont dédupliqués dans un `Set<String>`. Les références manquantes sont ignorées sans crash.

## 8. Resolver runtime Surface
Pipeline :

```text
SurfaceLayer placement
→ resolveSurfaceVariantRoleForPlacement(...)
→ ProjectSurfacePreset
→ animationId exact, sinon isolated, sinon première ref
→ ProjectSurfaceAnimation
→ frame à elapsedMs optionnel, défaut 0
→ ProjectSurfaceAtlas
→ SurfaceRuntimeRenderInstruction
```

`elapsedMs` existe déjà comme paramètre optionnel, mais aucun clock runtime n’est créé. Le Lot 90 pourra brancher une clock ou un renderer.

## 9. Fallbacks
- Preset manquant : skip.
- Animation manquante : skip.
- Atlas manquant : skip.
- Frame hors géométrie atlas : skip.
- SurfaceLayer invisible ou opacité <= 0 : resolver vide.
- Placement avec coordonnées négatives ou `surfacePresetId` vide : ignoré par le resolver.

Choix : ignorer les instructions non résolubles plutôt que créer des diagnostics runtime lourds. C’est volontairement V0.

## 10. Intégration no-op MapLayersComponent
`MapLayersComponent` reste sans rendu Surface. Le commentaire a été mis à jour pour indiquer que Lot 89 ne fait que du planning/résolution et que le rendu Flame est reporté.

## 11. Tests lancés
### TDD rouge initial
```text
flutter test test/surface/surface_runtime_tileset_collector_test.dart
Résultat attendu : échec de compilation, helper absent.
Erreur clé : Error when reading 'lib/src/surface/surface_runtime_tileset_collector.dart': No such file or directory

flutter test test/surface/surface_runtime_resolver_test.dart
Résultat attendu : échec de compilation, helper absent.
Erreur clé : Error when reading 'lib/src/surface/surface_runtime_resolver.dart': No such file or directory

flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
Résultat attendu : échec comportemental.
Erreur clé : Expected Set:['base-world', 'surface-water']; Actual Set:['base-world']
```

### Tests verts finaux
```text
cd packages/map_runtime && flutter test test/surface
00:01 +11: All tests passed!

cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
00:01 +1: All tests passed!

cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
00:01 +2: All tests passed!

cd packages/map_core && dart test test/surface_variant_role_resolver_test.dart
00:00 +7: All tests passed!

cd packages/map_core && dart test test/surface_layer_placements_test.dart
00:00 +14: All tests passed!
```

## 12. Analyse lancée
```text
cd packages/map_runtime && flutter analyze lib/src/surface/surface_runtime_render_instruction.dart lib/src/surface/surface_runtime_resolver.dart lib/src/surface/surface_runtime_tileset_collector.dart lib/src/application/runtime_manifest_tilesets.dart lib/src/presentation/flame/map_layers_component.dart test/surface/surface_runtime_tileset_collector_test.dart test/surface/surface_runtime_resolver_test.dart test/runtime_manifest_tilesets_surface_layer_test.dart
Analyzing 8 items...
No issues found! (ran in 1.7s)
```

Analyse globale optionnelle non lancée ; le lot est ciblé et l’analyse ciblée couvre tous les Dart créés/modifiés.

## 13. Résultats
- Les tilesets Surface placés sont collectés via `collectAllRuntimeTilesetIds`.
- Le collecteur Surface déduplique et scanne toutes les frames.
- Le resolver produit des instructions pures testables.
- Les rôles sont résolus avec le resolver `map_core` existant.
- Les surfaces différentes ne se connectent pas.
- Les catalogues incomplets ne crashent pas.
- Aucun rendu Flame n’a été ajouté.

## 14. Fichiers créés
```text
packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart
packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
packages/map_runtime/lib/src/surface/surface_runtime_tileset_collector.dart
packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
packages/map_runtime/test/surface/surface_runtime_tileset_collector_test.dart
reports/surface/surface_engine_lot_89_runtime_surface_tileset_collection_resolver.md
```

## 15. Fichiers modifiés
```text
packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
```

## 16. Fichiers supprimés
Aucun.

## 17. Evidence Pack
### Git status final
```text
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
?? packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart
?? packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
?? packages/map_runtime/lib/src/surface/surface_runtime_tileset_collector.dart
?? packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
?? packages/map_runtime/test/surface/surface_runtime_tileset_collector_test.dart
?? reports/surface/surface_engine_lot_89_runtime_surface_tileset_collection_resolver.md
```

### Diff stat final
```text
 .../src/application/runtime_manifest_tilesets.dart | 11 ++-
 .../presentation/flame/map_layers_component.dart   |  4 +-
 ...ntime_manifest_tilesets_surface_layer_test.dart | 88 ++++++++++++++++++++--
 3 files changed, 94 insertions(+), 9 deletions(-)
```

Note : `git diff --stat` ne liste pas les nouveaux fichiers non trackés. Ils sont listés dans `Git status final` et `Fichiers créés`.

### Fichiers temporaires
```text
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
# no output
```

### Whitespace check
```text
git diff --check
# no output
```

## 18. Périmètre explicitement non touché
- `map_editor` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- `map_core` non modifié.
- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- Codecs Surface non modifiés.
- Aucun renderer Flame créé.
- Aucune animation clock runtime créée.
- Aucun gameplay surf/tallGrass créé.
- Aucune migration legacy.
- Aucun changement JSON.

## 19. Contenu complet des fichiers modifiés/créés/supprimés
Le rapport lui-même est exclu de cette section pour éviter une récursion infinie. Tous les autres fichiers créés ou modifiés par le lot sont inclus en entier ci-dessous.

#### `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`

````dart
import 'package:map_core/map_core.dart';

import '../surface/surface_runtime_tileset_collector.dart';
import 'runtime_character_refs.dart';

Map<TerrainType, ProjectTerrainPreset> runtimeTerrainPresetsByType(
  ProjectManifest manifest,
) {
  final sorted = List<ProjectTerrainPreset>.from(manifest.terrainPresets)
    ..sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) {
        return c;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  final out = <TerrainType, ProjectTerrainPreset>{};
  for (final p in sorted) {
    out.putIfAbsent(p.terrainType, () => p);
  }
  return out;
}

Set<String> collectTilesetIdsReferencedOnMap(MapData map) {
  final ids = <String>{};
  void add(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isNotEmpty) {
      ids.add(t);
    }
  }

  add(map.tilesetId);
  for (final layer in map.layers) {
    layer.when(
      tile: (id, name, tilesetId, isVisible, opacity, tiles) => add(tilesetId),
      collision: (id, name, isVisible, opacity, collisions) {},
      terrain: (id, name, isVisible, opacity, terrains) {},
      path: (id, name, isVisible, opacity, presetId, cells, properties,
          animationMode, animationTriggers) {},
      // Surface layers are no-op in runtime V0; a later runtime Surface lot
      // will resolve placed preset ids into catalog atlas/tileset references.
      surface: (id, name, isVisible, opacity, placements, properties) {},
      object: (id, name, isVisible, opacity) {},
    );
  }
  return ids;
}

void addTerrainAndPathPresetTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final terrainByType = runtimeTerrainPresetsByType(manifest);
  for (final layer in map.layers) {
    layer.when(
      tile: (id, name, tilesetId, isVisible, opacity, tiles) {},
      collision: (id, name, isVisible, opacity, collisions) {},
      terrain: (id, name, isVisible, opacity, terrains) {
        for (final t in terrains) {
          if (t == TerrainType.none) {
            continue;
          }
          final preset = terrainByType[t];
          if (preset == null) {
            continue;
          }
          final presetTilesetId = preset.tilesetId.trim();
          if (presetTilesetId.isNotEmpty) {
            ids.add(presetTilesetId);
          }
          for (final variant in preset.variants) {
            for (final frame in variant.frames) {
              final overrideTilesetId = frame.tilesetId.trim();
              if (overrideTilesetId.isNotEmpty) {
                ids.add(overrideTilesetId);
              }
            }
          }
        }
      },
      path: (id, name, isVisible, opacity, presetId, cells, properties,
          animationMode, animationTriggers) {
        final pid = presetId.trim();
        if (pid.isEmpty) {
          return;
        }
        for (final p in manifest.pathPresets) {
          if (p.id == pid) {
            final presetTilesetId = p.tilesetId.trim();
            if (presetTilesetId.isNotEmpty) {
              ids.add(presetTilesetId);
            }
            for (final mapping in p.variants) {
              for (final frame in mapping.frames) {
                final overrideTilesetId = frame.tilesetId.trim();
                if (overrideTilesetId.isNotEmpty) {
                  ids.add(overrideTilesetId);
                }
              }
            }
            return;
          }
        }
      },
      // Surface render work stays out of this file, but Lot 89 now collects the
      // atlas tilesets used by placed Surface presets below.
      surface: (id, name, isVisible, opacity, placements, properties) {},
      object: (id, name, isVisible, opacity) {},
    );
  }
}

void addEntityVisualTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final elementById = {for (final e in manifest.elements) e.id: e};
  for (final entity in map.entities) {
    final elementId = entity.resolvedProjectElementIdForEditor?.trim();
    if (elementId == null || elementId.isEmpty) continue;
    final entry = elementById[elementId];
    if (entry == null || entry.frames.isEmpty) continue;
    for (final frame in entry.frames) {
      final tid = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tid.isNotEmpty) ids.add(tid);
    }
  }
}

void addCharacterTilesetIds(
  Set<String> ids,
  MapData map,
  ProjectManifest manifest,
) {
  final charById = {for (final c in manifest.characters) c.id: c};
  final playerCharId = manifest.settings.defaultPlayerCharacterId?.trim();
  if (playerCharId != null && playerCharId.isNotEmpty) {
    final tid = charById[playerCharId]?.tilesetId.trim() ?? '';
    if (tid.isNotEmpty) ids.add(tid);
  }
  for (final entity in map.entities) {
    if (entity.kind != MapEntityKind.npc) continue;
    final charId = resolveNpcCharacterId(entity, manifest);
    if (charId == null || charId.isEmpty) continue;
    final tid = charById[charId]?.tilesetId.trim() ?? '';
    if (tid.isNotEmpty) ids.add(tid);
  }
}

Set<String> collectAllRuntimeTilesetIds(MapData map, ProjectManifest manifest) {
  final ids = collectTilesetIdsReferencedOnMap(map);
  addTerrainAndPathPresetTilesetIds(ids, map, manifest);
  ids.addAll(
    collectSurfaceRuntimeTilesetIds(
      map: map,
      catalog: manifest.surfaceCatalog,
    ),
  );
  addEntityVisualTilesetIds(ids, map, manifest);
  addCharacterTilesetIds(ids, map, manifest);
  return ids;
}

````

#### `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_character_refs.dart';
import '../../application/runtime_manifest_tilesets.dart';
import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import 'runtime_path_autotile.dart';

const int _kEntityFrameDurationFallbackMs = 200;

enum MapLayerRenderPass {
  background,
  foreground,
}

@visibleForTesting
bool shouldRenderProjectElementEntityInForegroundPass(
  MapEntity entity, {
  required MapLayerRenderPass renderPass,
}) {
  final renderInForeground = entity.shouldRenderProjectElementInForeground;
  return switch (renderPass) {
    MapLayerRenderPass.background => !renderInForeground,
    MapLayerRenderPass.foreground => renderInForeground,
  };
}

class MapLayersComponent extends PositionComponent {
  MapLayersComponent({
    required this.bundle,
    required this.tileImagesByTilesetId,
    this.renderPass = MapLayerRenderPass.background,
    this.showCollisionOverlay = false,
    this.npcMapPresencePredicate,
  })  : _terrainPresetsByType = runtimeTerrainPresetsByType(bundle.manifest),
        _pathAutotileByPresetId = {
          for (final p in bundle.manifest.pathPresets)
            p.id: RuntimePathAutotileSet.fromPreset(p),
        },
        _pathRulesByLayerId = _buildPathRulesByLayerId(bundle),
        _foregroundTileCellIndicesByLayerId =
            _buildForegroundTileCellIndicesByLayerId(bundle),
        _animatedPlacedCellsByLayerId =
            _buildAnimatedPlacedCellsByLayerId(bundle),
        super(
          anchor: Anchor.topLeft,
          position: Vector2.zero(),
          size: Vector2(
            bundle.map.size.width * bundle.cellWidth,
            bundle.map.size.height * bundle.cellHeight,
          ),
        ) {
    _animatedInstanceById = _buildAnimatedPlacedInstanceById(
      _animatedPlacedCellsByLayerId,
    );
  }

  final RuntimeMapBundle bundle;
  final Map<String, RuntimeTilesetImage> tileImagesByTilesetId;
  final MapLayerRenderPass renderPass;
  bool showCollisionOverlay;

  /// Si non null, les PNJ pour lesquels ce filtre retourne `false` ne sont pas
  /// peints (sprites « élément projet » sans personnage dédié).
  NpcMapPresencePredicate? npcMapPresencePredicate;
  final Map<TerrainType, ProjectTerrainPreset> _terrainPresetsByType;
  final Map<String, RuntimePathAutotileSet> _pathAutotileByPresetId;
  final Map<String, List<_PathRuleSpec>> _pathRulesByLayerId;
  final Map<String, Set<int>> _foregroundTileCellIndicesByLayerId;
  final Map<String, Map<int, _AnimatedPlacedCell>>
      _animatedPlacedCellsByLayerId;
  late final Map<String, _AnimatedPlacedInstanceSpec> _animatedInstanceById;
  final Map<String, bool> _animationEnabledOverrideByInstanceId =
      <String, bool>{};
  final Map<String, _ActiveOneShotAnimation> _activeOneShotByInstanceId =
      <String, _ActiveOneShotAnimation>{};
  final Map<_PathRuleKey, _ActivePathRuleOneShot> _activePathRuleOneShotByKey =
      <_PathRuleKey, _ActivePathRuleOneShot>{};
  final Map<_PathRuleKey, double> _activePathRuleLoopStartedAtMsByKey =
      <_PathRuleKey, double>{};
  final Map<_PathRuleCellKey, _ActivePathRuleOneShot>
      _activePathRuleCellOneShotByKey =
      <_PathRuleCellKey, _ActivePathRuleOneShot>{};
  final Map<_PathRuleCellKey, double> _activePathRuleCellLoopStartedAtMsByKey =
      <_PathRuleCellKey, double>{};

  late final Map<String, ProjectElementEntry> _elementById = {
    for (final e in bundle.manifest.elements) e.id: e,
  };

  double _animElapsed = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _animElapsed += dt;
    _pruneCompletedPathRuleOneShots();
  }

  void setPlacedElementAnimationEnabledOverride({
    required String instanceId,
    required bool enabled,
  }) {
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    _animationEnabledOverrideByInstanceId[trimmedId] = enabled;
  }

  bool playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return false;
    }
    final spec = _animatedInstanceById[trimmedId];
    if (spec == null || spec.frameDurationsMs.length < 2) {
      return false;
    }
    _activeOneShotByInstanceId[trimmedId] = _ActiveOneShotAnimation(
      startedAtMs: _animElapsed * 1000,
      frameDurationsMs: spec.frameDurationsMs,
      speed: spec.speed,
    );
    return true;
  }

  bool triggerPathAnimationRule({
    required String layerId,
    required String ruleId,
    required PathAnimationPlaybackMode mode,
    PathAnimationActivationScope scope =
        PathAnimationActivationScope.wholeLayer,
    int cellX = 0,
    int cellY = 0,
  }) {
    final trimmedLayerId = layerId.trim();
    final trimmedRuleId = ruleId.trim();
    if (trimmedLayerId.isEmpty || trimmedRuleId.isEmpty) {
      return false;
    }
    final key = _PathRuleKey(layerId: trimmedLayerId, ruleId: trimmedRuleId);
    final spec = _resolvePathRuleSpec(key);
    if (spec == null || !spec.hasAnimatedFrames) {
      return false;
    }
    if (scope == PathAnimationActivationScope.cellOnly) {
      final cellKey = _PathRuleCellKey(
          layerId: trimmedLayerId, ruleId: trimmedRuleId, x: cellX, y: cellY);
      switch (mode) {
        case PathAnimationPlaybackMode.playOnce:
          final existing = _activePathRuleCellOneShotByKey[cellKey];
          if (existing != null && !_isPathRuleOneShotCompleted(existing)) {
            return false;
          }
          _activePathRuleCellOneShotByKey[cellKey] = _ActivePathRuleOneShot(
            startedAtMs: _animElapsed * 1000,
            durationMs: spec.oneShotDurationMs,
          );
          return true;
        case PathAnimationPlaybackMode.restartOnTrigger:
          _activePathRuleCellOneShotByKey[cellKey] = _ActivePathRuleOneShot(
            startedAtMs: _animElapsed * 1000,
            durationMs: spec.oneShotDurationMs,
          );
          return true;
        case PathAnimationPlaybackMode.loopWhileActive:
          return false;
      }
    }
    switch (mode) {
      case PathAnimationPlaybackMode.playOnce:
        final existing = _activePathRuleOneShotByKey[key];
        if (existing != null && !_isPathRuleOneShotCompleted(existing)) {
          return false;
        }
        _activePathRuleOneShotByKey[key] = _ActivePathRuleOneShot(
          startedAtMs: _animElapsed * 1000,
          durationMs: spec.oneShotDurationMs,
        );
        return true;
      case PathAnimationPlaybackMode.restartOnTrigger:
        _activePathRuleOneShotByKey[key] = _ActivePathRuleOneShot(
          startedAtMs: _animElapsed * 1000,
          durationMs: spec.oneShotDurationMs,
        );
        return true;
      case PathAnimationPlaybackMode.loopWhileActive:
        return false;
    }
  }

  bool setPathAnimationRuleActive({
    required String layerId,
    required String ruleId,
    required bool active,
    PathAnimationActivationScope scope =
        PathAnimationActivationScope.wholeLayer,
    int cellX = 0,
    int cellY = 0,
  }) {
    final trimmedLayerId = layerId.trim();
    final trimmedRuleId = ruleId.trim();
    if (trimmedLayerId.isEmpty || trimmedRuleId.isEmpty) {
      return false;
    }
    final key = _PathRuleKey(layerId: trimmedLayerId, ruleId: trimmedRuleId);
    final spec = _resolvePathRuleSpec(key);
    if (spec == null || !spec.hasAnimatedFrames) {
      return false;
    }
    if (spec.rule.mode != PathAnimationPlaybackMode.loopWhileActive) {
      return false;
    }
    if (scope == PathAnimationActivationScope.cellOnly) {
      final cellKey = _PathRuleCellKey(
          layerId: trimmedLayerId, ruleId: trimmedRuleId, x: cellX, y: cellY);
      if (active) {
        _activePathRuleCellLoopStartedAtMsByKey.putIfAbsent(
            cellKey, () => _animElapsed * 1000);
      } else {
        _activePathRuleCellLoopStartedAtMsByKey.remove(cellKey);
      }
      return true;
    }
    if (active) {
      _activePathRuleLoopStartedAtMsByKey.putIfAbsent(
        key,
        () => _animElapsed * 1000,
      );
    } else {
      _activePathRuleLoopStartedAtMsByKey.remove(key);
    }
    return true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final visible = bundle.map.layers.where((l) => l.isVisible).toList();
    // Lot 89 resolves Surface placements for loading/render planning only.
    // Actual Flame drawing is intentionally deferred to the Surface renderer lot.
    if (renderPass == MapLayerRenderPass.foreground) {
      for (var i = visible.length - 1; i >= 0; i--) {
        visible[i].whenOrNull(
          tile: (id, name, tilesetId, v, o, tiles) => _paintTileLayer(
            canvas,
            layerId: id,
            layerName: name,
            tilesetId: tilesetId,
            tiles: tiles,
            opacity: o,
          ),
        );
      }
      _paintEntities(canvas);
      return;
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        terrain: (id, name, v, o, terrains) =>
            _paintTerrainLayer(canvas, terrains, o),
      );
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        path: (id, name, v, o, presetId, cells, properties, animationMode,
                animationTriggers) =>
            _paintPathLayer(canvas, id, presetId, cells, o),
      );
    }
    for (var i = visible.length - 1; i >= 0; i--) {
      visible[i].whenOrNull(
        tile: (id, name, tilesetId, v, o, tiles) => _paintTileLayer(
          canvas,
          layerId: id,
          layerName: name,
          tilesetId: tilesetId,
          tiles: tiles,
          opacity: o,
        ),
      );
    }
    _paintEntities(canvas);
    if (showCollisionOverlay) {
      for (var i = visible.length - 1; i >= 0; i--) {
        visible[i].whenOrNull(
          collision: (id, name, v, o, collisions) =>
              _paintCollisionLayer(canvas, collisions, o),
        );
      }
      _paintPlacedElementsCollisionOverlay(canvas);
    }
  }

  void _paintEntities(Canvas canvas) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final elapsedMs = (_animElapsed * 1000).toInt();
    for (final entity in bundle.map.entities) {
      // On garde deux passes explicites :
      // - background: rendu normal des entités élément-projet ;
      // - foreground: props explicitement forcés devant le décor.
      //
      // Cela permet de poser un petit objet sur une table sans transformer ce
      // composant en système de z-index générique.
      if (!shouldRenderProjectElementEntityInForegroundPass(
        entity,
        renderPass: renderPass,
      )) {
        continue;
      }
      if (entity.kind == MapEntityKind.npc) {
        final presence = npcMapPresencePredicate;
        if (presence != null && !presence(bundle.map.id, entity)) {
          continue;
        }
        final charId = resolveNpcCharacterId(entity, bundle.manifest);
        if (charId != null && charId.isNotEmpty) continue;
      }
      final elementId = entity.resolvedProjectElementIdForEditor?.trim();
      if (elementId == null || elementId.isEmpty) continue;
      final entry = _elementById[elementId];
      if (entry == null || entry.frames.isEmpty) continue;
      final frame = _pickEntityFrame(entry.frames, elapsedMs);
      final tilesetId = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tilesetId.isEmpty) continue;
      final image = tileImagesByTilesetId[tilesetId];
      if (image == null) continue;
      final src = frame.source;
      final srcW = (src.width <= 0 ? 1 : src.width) * tw;
      final srcH = (src.height <= 0 ? 1 : src.height) * th;
      final srcRect = Rect.fromLTWH(
        (src.x * tw).toDouble(),
        (src.y * th).toDouble(),
        srcW.toDouble(),
        srcH.toDouble(),
      );
      if (!image.containsSourceRect(srcRect)) {
        continue;
      }
      final bounds = Rect.fromLTWH(
        entity.pos.x * cw,
        entity.pos.y * ch,
        entity.size.width * cw,
        entity.size.height * ch,
      );
      _paintEntityFrame(canvas, image, srcRect, bounds);
    }
  }

  void _paintEntityFrame(
    Canvas canvas,
    RuntimeTilesetImage image,
    Rect src,
    Rect bounds,
  ) {
    if (src.width <= 0 || src.height <= 0) return;
    final srcAr = src.width / src.height;
    final bAr = bounds.width / bounds.height;
    final Rect dst;
    if (srcAr > bAr) {
      final w = bounds.width;
      final h = w / srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    } else {
      final h = bounds.height;
      final w = h * srcAr;
      dst = Rect.fromCenter(center: bounds.center, width: w, height: h);
    }
    image.drawImageRect(
      canvas,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  TilesetVisualFrame _pickEntityFrame(
    List<TilesetVisualFrame> frames,
    int elapsedMs,
  ) {
    if (frames.length == 1) return frames.first;
    var total = 0;
    for (final f in frames) {
      final d = f.durationMs;
      total += (d == null || d <= 0) ? _kEntityFrameDurationFallbackMs : d;
    }
    if (total <= 0) return frames.first;
    var t = elapsedMs % total;
    for (final f in frames) {
      final d = f.durationMs;
      final dur = (d == null || d <= 0) ? _kEntityFrameDurationFallbackMs : d;
      if (t < dur) return f;
      t -= dur;
    }
    return frames.last;
  }

  void _paintTileLayer(
    Canvas canvas, {
    required String layerId,
    required String layerName,
    required String? tilesetId,
    required List<int> tiles,
    required double opacity,
  }) {
    final explicitForeground = _isExplicitForegroundTileLayer(
      layerId: layerId,
      layerName: layerName,
    );
    final foregroundCells = _foregroundTileCellIndicesByLayerId[layerId];
    final shouldRenderThisLayer = switch (renderPass) {
      MapLayerRenderPass.background => !explicitForeground ||
          (foregroundCells != null && foregroundCells.isNotEmpty),
      MapLayerRenderPass.foreground => explicitForeground ||
          (foregroundCells != null && foregroundCells.isNotEmpty),
    };
    if (!shouldRenderThisLayer) {
      return;
    }
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    final h = map.size.height;
    final resolvedId = _resolveTilesetId(map, tilesetId);
    if (resolvedId == null) {
      return;
    }
    final image = tileImagesByTilesetId[resolvedId];
    if (image == null || tw <= 0 || th <= 0) {
      return;
    }
    final cols = image.width ~/ tw;
    if (cols <= 0) {
      return;
    }
    final paint = Paint()..isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    if (opacity < 1) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }
    final animatedCells = _animatedPlacedCellsByLayerId[layerId];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= tiles.length) {
          continue;
        }
        final tileId = tiles[idx];
        if (tileId <= 0) {
          continue;
        }
        final isForegroundCell = foregroundCells?.contains(idx) ?? false;
        final shouldDrawCell = switch (renderPass) {
          MapLayerRenderPass.background =>
            explicitForeground ? false : !isForegroundCell,
          MapLayerRenderPass.foreground =>
            explicitForeground || isForegroundCell,
        };
        if (!shouldDrawCell) {
          continue;
        }
        if (animatedCells != null) {
          final animatedCell = animatedCells[idx];
          if (animatedCell != null) {
            final drewAnimated = _paintAnimatedPlacedCell(
              canvas,
              animatedCell: animatedCell,
              x: x,
              y: y,
              dstWidth: cw,
              dstHeight: ch,
              paint: paint,
            );
            if (drewAnimated) {
              continue;
            }
          }
        }
        final sourceIndex = tileId - 1;
        final col = sourceIndex % cols;
        final row = sourceIndex ~/ cols;
        final sx = col * tw;
        final sy = row * th;
        final src = Rect.fromLTWH(
          sx.toDouble(),
          sy.toDouble(),
          tw.toDouble(),
          th.toDouble(),
        );
        if (!image.containsSourceRect(src)) {
          continue;
        }
        final dst = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        image.drawImageRect(canvas, src, dst, paint);
      }
    }
  }

  bool _isExplicitForegroundTileLayer({
    required String layerId,
    required String layerName,
  }) {
    final id = layerId.trim().toLowerCase();
    final name = layerName.trim().toLowerCase();
    const markers = <String>{
      'foreground',
      'fg',
      'above',
      'overlay',
      'front',
      'roof',
      'toit',
    };
    bool containsMarker(String value) {
      for (final marker in markers) {
        if (value == marker ||
            value.startsWith('${marker}_') ||
            value.endsWith('_$marker') ||
            value.contains('_${marker}_')) {
          return true;
        }
      }
      return false;
    }

    return containsMarker(id) || containsMarker(name);
  }

  static Map<String, Set<int>> _buildForegroundTileCellIndicesByLayerId(
    RuntimeMapBundle bundle,
  ) {
    final map = bundle.map;
    final tileLayerById = <String, TileLayer>{
      for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
    };
    if (tileLayerById.isEmpty || map.placedElements.isEmpty) {
      return const <String, Set<int>>{};
    }
    final elementById = {
      for (final entry in bundle.manifest.elements) entry.id: entry,
    };
    final out = <String, Set<int>>{};
    final mapW = map.size.width;
    final mapH = map.size.height;

    for (final instance in map.placedElements) {
      final layer = tileLayerById[instance.layerId];
      if (layer == null) {
        continue;
      }
      final entry = elementById[instance.elementId];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final source = entry.frames.primaryFrame.source;
      final width = source.width <= 0 ? 1 : source.width;
      final height = source.height <= 0 ? 1 : source.height;
      if (width <= 1 && height <= 1) {
        continue;
      }
      final collisionCells = entry.collisionProfile?.cells;
      if (collisionCells == null || collisionCells.isEmpty) {
        continue;
      }
      final collisionSet = <int>{
        for (final c in collisionCells) c.y * width + c.x,
      };
      final layerMask = out.putIfAbsent(layer.id, () => <int>{});
      for (var ly = 0; ly < height; ly++) {
        for (var lx = 0; lx < width; lx++) {
          final localIndex = ly * width + lx;
          if (collisionSet.contains(localIndex)) {
            continue;
          }
          final x = instance.pos.x + lx;
          final y = instance.pos.y + ly;
          if (x < 0 || y < 0 || x >= mapW || y >= mapH) {
            continue;
          }
          final globalIndex = y * mapW + x;
          if (globalIndex >= layer.tiles.length ||
              layer.tiles[globalIndex] <= 0) {
            continue;
          }
          layerMask.add(globalIndex);
        }
      }
    }

    return out;
  }

  static Map<String, Map<int, _AnimatedPlacedCell>>
      _buildAnimatedPlacedCellsByLayerId(
    RuntimeMapBundle bundle,
  ) {
    final map = bundle.map;
    final tileLayerById = <String, TileLayer>{
      for (final layer in map.layers.whereType<TileLayer>()) layer.id: layer,
    };
    if (tileLayerById.isEmpty || map.placedElements.isEmpty) {
      return const <String, Map<int, _AnimatedPlacedCell>>{};
    }
    final elementById = {
      for (final entry in bundle.manifest.elements) entry.id: entry,
    };
    final out = <String, Map<int, _AnimatedPlacedCell>>{};
    final mapW = map.size.width;
    final mapH = map.size.height;
    for (final instance in map.placedElements) {
      final layer = tileLayerById[instance.layerId];
      if (layer == null) {
        continue;
      }
      final entry = elementById[instance.elementId];
      if (entry == null || entry.frames.length < 2) {
        continue;
      }
      final animation = instance.animation ?? const MapPlacedElementAnimation();
      final frames = <_RuntimeAnimationFrame>[];
      for (final frame in entry.frames) {
        final source = frame.source;
        if (source.width <= 0 || source.height <= 0) {
          continue;
        }
        final tilesetId = frame.tilesetId.trim().isNotEmpty
            ? frame.tilesetId.trim()
            : entry.tilesetId.trim();
        if (tilesetId.isEmpty) {
          continue;
        }
        frames.add(
          _RuntimeAnimationFrame(
            tilesetId: tilesetId,
            source: source,
            durationMs: frame.durationMs,
          ),
        );
      }
      if (frames.length < 2) {
        continue;
      }
      final frameDurationsMs = normalizeElementFrameDurationsMs(
        frames.map((frame) => frame.durationMs).toList(growable: false),
      );
      final baseSource = frames.first.source;
      final width = baseSource.width <= 0 ? 1 : baseSource.width;
      final height = baseSource.height <= 0 ? 1 : baseSource.height;
      final seed = stableHash32(instance.id);
      final layerCells =
          out.putIfAbsent(instance.layerId, () => <int, _AnimatedPlacedCell>{});
      for (var ly = 0; ly < height; ly++) {
        for (var lx = 0; lx < width; lx++) {
          final x = instance.pos.x + lx;
          final y = instance.pos.y + ly;
          if (x < 0 || y < 0 || x >= mapW || y >= mapH) {
            continue;
          }
          final index = y * mapW + x;
          if (index >= layer.tiles.length || layer.tiles[index] <= 0) {
            continue;
          }
          layerCells[index] = _AnimatedPlacedCell(
            instanceId: instance.id,
            localX: lx,
            localY: ly,
            frames: frames,
            frameDurationsMs: frameDurationsMs,
            animation: animation,
            deterministicSeed: seed,
          );
        }
      }
    }
    return out;
  }

  static Map<String, _AnimatedPlacedInstanceSpec>
      _buildAnimatedPlacedInstanceById(
    Map<String, Map<int, _AnimatedPlacedCell>> cellsByLayerId,
  ) {
    final out = <String, _AnimatedPlacedInstanceSpec>{};
    for (final cellsByIndex in cellsByLayerId.values) {
      for (final cell in cellsByIndex.values) {
        out.putIfAbsent(
          cell.instanceId,
          () => _AnimatedPlacedInstanceSpec(
            frameDurationsMs: cell.frameDurationsMs,
            speed: cell.animation.speed <= 0 ? 1.0 : cell.animation.speed,
          ),
        );
      }
    }
    return out;
  }

  static Map<String, List<_PathRuleSpec>> _buildPathRulesByLayerId(
    RuntimeMapBundle bundle,
  ) {
    final pathPresetById = {
      for (final preset in bundle.manifest.pathPresets) preset.id: preset,
    };
    final out = <String, List<_PathRuleSpec>>{};
    for (final layer in bundle.map.layers.whereType<PathLayer>()) {
      if (layer.animationTriggers.isEmpty) {
        continue;
      }
      final preset = pathPresetById[layer.presetId.trim()];
      final hasAnimatedFrames =
          preset != null && _pathPresetHasAnimatedFrames(preset);
      final oneShotDurationMs =
          preset != null ? _pathPresetMaxOneShotDurationMs(preset) : 0;
      final specs = <_PathRuleSpec>[];
      for (var index = 0; index < layer.animationTriggers.length; index++) {
        final rule = layer.animationTriggers[index];
        if (!rule.enabled) {
          continue;
        }
        final ruleId = resolvePathAnimationTriggerRuleId(
          rule,
          index: index,
        );
        specs.add(
          _PathRuleSpec(
            ruleId: ruleId,
            rule: rule,
            scope: rule.scope,
            hasAnimatedFrames: hasAnimatedFrames,
            oneShotDurationMs: oneShotDurationMs,
          ),
        );
      }
      if (specs.isEmpty) {
        continue;
      }
      out[layer.id] = specs;
    }
    return out;
  }

  static bool _pathPresetHasAnimatedFrames(ProjectPathPreset preset) {
    for (final mapping in preset.variants) {
      if (mapping.frames.length >= 2) {
        return true;
      }
    }
    return false;
  }

  static int _pathPresetMaxOneShotDurationMs(ProjectPathPreset preset) {
    var maxDurationMs = 0;
    for (final mapping in preset.variants) {
      if (mapping.frames.length < 2) {
        continue;
      }
      final durations = normalizeElementFrameDurationsMs(
        mapping.frames.map((frame) => frame.durationMs).toList(growable: false),
      );
      var total = 0;
      for (final duration in durations) {
        total += duration;
      }
      if (total > maxDurationMs) {
        maxDurationMs = total;
      }
    }
    if (maxDurationMs <= 0) {
      return defaultPlacedElementAnimationFrameDurationMs;
    }
    return maxDurationMs;
  }

  bool _paintAnimatedPlacedCell(
    Canvas canvas, {
    required _AnimatedPlacedCell animatedCell,
    required int x,
    required int y,
    required double dstWidth,
    required double dstHeight,
    required Paint paint,
  }) {
    final oneShot = _activeOneShotByInstanceId[animatedCell.instanceId];
    int frameIndex;
    if (oneShot != null) {
      final resolution = resolvePlacedElementAnimationOneShotFrame(
        frameDurationsMs: oneShot.frameDurationsMs,
        elapsedMs: (_animElapsed * 1000) - oneShot.startedAtMs,
        speed: oneShot.speed,
      );
      frameIndex = resolution.frameIndex;
      if (resolution.completed) {
        _activeOneShotByInstanceId.remove(animatedCell.instanceId);
      }
    } else {
      final enabledOverride =
          _animationEnabledOverrideByInstanceId[animatedCell.instanceId];
      final effectiveAnimation = enabledOverride == null
          ? animatedCell.animation
          : animatedCell.animation.copyWith(enabled: enabledOverride);
      frameIndex = resolvePlacedElementAnimationFrameIndex(
        frameDurationsMs: animatedCell.frameDurationsMs,
        elapsedMs: _animElapsed * 1000,
        animation: effectiveAnimation,
        deterministicSeed: animatedCell.deterministicSeed,
      );
    }
    if (frameIndex < 0 || frameIndex >= animatedCell.frames.length) {
      return false;
    }
    final frame = animatedCell.frames[frameIndex];
    final image = tileImagesByTilesetId[frame.tilesetId];
    if (image == null) {
      return false;
    }
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    if (tw <= 0 || th <= 0) {
      return false;
    }
    if (animatedCell.localX < 0 ||
        animatedCell.localY < 0 ||
        animatedCell.localX >= frame.source.width ||
        animatedCell.localY >= frame.source.height) {
      return false;
    }
    final sx = (frame.source.x + animatedCell.localX) * tw;
    final sy = (frame.source.y + animatedCell.localY) * th;
    final src = Rect.fromLTWH(
      sx.toDouble(),
      sy.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    if (!image.containsSourceRect(src)) {
      return false;
    }
    final dst = Rect.fromLTWH(x * dstWidth, y * dstHeight, dstWidth, dstHeight);
    image.drawImageRect(canvas, src, dst, paint);
    return true;
  }

  void _paintCollisionLayer(
    Canvas canvas,
    List<bool> collisions,
    double opacity,
  ) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final w = bundle.map.size.width;
    final h = bundle.map.size.height;
    final paint = Paint()..color = Color.fromRGBO(255, 153, 0, 0.30 * opacity);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= collisions.length || !collisions[idx]) {
          continue;
        }
        canvas.drawRect(Rect.fromLTWH(x * cw, y * ch, cw, ch), paint);
      }
    }
  }

  void _paintPlacedElementsCollisionOverlay(Canvas canvas) {
    final w = bundle.map.size.width;
    final h = bundle.map.size.height;
    if (w <= 0 || h <= 0) {
      return;
    }
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final paint = Paint()..color = const Color.fromRGBO(255, 153, 0, 0.30);
    final elementById = _elementById;
    final tileWidth = bundle.manifest.settings.tileWidth;
    final tileHeight = bundle.manifest.settings.tileHeight;
    final pixelScaleX = tileWidth > 0 ? cw / tileWidth : 1.0;
    final pixelScaleY = tileHeight > 0 ? ch / tileHeight : 1.0;
    final mapWidthPx = w * cw;
    final mapHeightPx = h * ch;
    for (final instance in bundle.map.placedElements) {
      if (!instance.applyCollision) {
        continue;
      }
      final element = elementById[instance.elementId];
      final profile = element?.collisionProfile;
      if (profile == null) {
        continue;
      }
      final worldLeftPx = instance.pos.x * cw;
      final worldTopPx = instance.pos.y * ch;
      // Overlay debug : masque **collision** (blocage), pas l’occlusion.
      final collisionMask = profile.collisionMask;
      if (collisionMask != null) {
        List<bool> maskPixels;
        try {
          maskPixels = ElementCollisionMaskCodec.decodePackedBits(
            widthPx: collisionMask.widthPx,
            heightPx: collisionMask.heightPx,
            dataBase64: collisionMask.dataBase64,
          );
        } catch (_) {
          continue;
        }
        for (var py = 0; py < collisionMask.heightPx; py++) {
          for (var px = 0; px < collisionMask.widthPx; px++) {
            final idx = py * collisionMask.widthPx + px;
            if (idx < 0 || idx >= maskPixels.length || !maskPixels[idx]) {
              continue;
            }
            final dx = worldLeftPx + px * pixelScaleX;
            final dy = worldTopPx + py * pixelScaleY;
            if (dx + pixelScaleX <= 0 ||
                dy + pixelScaleY <= 0 ||
                dx >= mapWidthPx ||
                dy >= mapHeightPx) {
              continue;
            }
            canvas.drawRect(
              Rect.fromLTWH(dx, dy, pixelScaleX, pixelScaleY),
              paint,
            );
          }
        }
        continue;
      }

      // Fallback legacy: profils sans masque collision pixel.
      for (final local in profile.cells) {
        final x = instance.pos.x + local.x;
        final y = instance.pos.y + local.y;
        if (x < 0 || y < 0 || x >= w || y >= h) {
          continue;
        }
        canvas.drawRect(Rect.fromLTWH(x * cw, y * ch, cw, ch), paint);
      }
    }
  }

  void _paintTerrainLayer(
    Canvas canvas,
    List<TerrainType> terrains,
    double opacity,
  ) {
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    final h = map.size.height;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= terrains.length) {
          continue;
        }
        final terrain = terrains[idx];
        if (terrain == TerrainType.none) {
          continue;
        }
        final cell = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        final drawn = _paintTerrainPresetCell(
          canvas,
          terrain,
          x: x,
          y: y,
          tw: tw,
          th: th,
          cell: cell,
          alpha: opacity,
        );
        if (drawn) {
          continue;
        }
        final fillColor = _terrainFillColor(terrain);
        final borderColor = _terrainBorderColor(terrain);
        canvas.drawRect(
          cell,
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  bool _paintTerrainPresetCell(
    Canvas canvas,
    TerrainType terrain, {
    required int x,
    required int y,
    required int tw,
    required int th,
    required Rect cell,
    required double alpha,
  }) {
    final preset = _terrainPresetsByType[terrain];
    if (preset == null || preset.variants.isEmpty) {
      return false;
    }
    final resolved = _resolveTerrainPresetFrame(
      preset: preset,
      x: x,
      y: y,
      elapsedMs: _animElapsed * 1000,
    );
    if (resolved == null) {
      return false;
    }
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tileImagesByTilesetId[tilesetId];
    if (tilesetImage == null || tw <= 0 || th <= 0) {
      return false;
    }
    final sourceRect = resolved.source;
    final width = sourceRect.width <= 0 ? 1 : sourceRect.width;
    final height = sourceRect.height <= 0 ? 1 : sourceRect.height;
    final cellSeed = _stableCellSeed(
      x: x,
      y: y,
      salt: sourceRect.x * 73856093 + sourceRect.y * 19349663,
    );
    final tileIndex = cellSeed % (width * height);
    final offsetX = tileIndex % width;
    final offsetY = tileIndex ~/ width;
    final sourceX = (sourceRect.x + offsetX) * tw;
    final sourceY = (sourceRect.y + offsetY) * th;
    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    if (!tilesetImage.containsSourceRect(srcRect)) {
      return false;
    }
    tilesetImage.drawImageRect(
      canvas,
      srcRect,
      cell,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }

  _ResolvedTerrainFrame? _resolveTerrainPresetFrame({
    required ProjectTerrainPreset preset,
    required int x,
    required int y,
    required double elapsedMs,
  }) {
    final variants = preset.variants;
    if (variants.isEmpty) {
      return null;
    }
    var totalWeight = 0;
    for (final variant in variants) {
      totalWeight += variant.weight <= 0 ? 1 : variant.weight;
    }
    if (totalWeight <= 0) {
      return null;
    }
    final seed = _stableCellSeed(x: x, y: y, salt: preset.id.hashCode);
    var selectedWeight = seed % totalWeight;
    TerrainPresetVariant chosen = variants.first;
    for (final variant in variants) {
      final weight = variant.weight <= 0 ? 1 : variant.weight;
      if (selectedWeight < weight) {
        chosen = variant;
        break;
      }
      selectedWeight -= weight;
    }
    if (chosen.frames.isEmpty) {
      return null;
    }
    final frameIndex = resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: normalizeElementFrameDurationsMs(
        chosen.frames.map((frame) => frame.durationMs).toList(growable: false),
      ),
      elapsedMs: elapsedMs,
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
      ),
    );
    final resolvedFrame =
        chosen.frames[frameIndex.clamp(0, chosen.frames.length - 1)];
    final frameTilesetId = resolvedFrame.tilesetId.trim();
    final resolvedTilesetId =
        frameTilesetId.isNotEmpty ? frameTilesetId : preset.tilesetId.trim();
    if (resolvedTilesetId.isEmpty) {
      return null;
    }
    return _ResolvedTerrainFrame(
      tilesetId: resolvedTilesetId,
      source: resolvedFrame.source,
    );
  }

  int _stableCellSeed({
    required int x,
    required int y,
    required int salt,
  }) {
    final raw = ((x + 1) * 73856093) ^ ((y + 1) * 19349663) ^ salt;
    return raw & 0x7fffffff;
  }

  _PathLayerPlayback _resolvePathLayerPlayback({
    required String layerId,
    required String presetId,
  }) {
    // Check if the layer has alwaysActive mode
    final layer = bundle.map.layers.firstWhere(
      (l) => l.id == layerId,
      orElse: () => throw StateError('Layer not found: $layerId'),
    );

    if (layer is PathLayer &&
        layer.animationMode == PathAnimationMode.alwaysActive) {
      // Always active mode: loop animation continuously
      return const _PathLayerPlayback.alwaysLoop();
    }

    final allRules = _pathRulesByLayerId[layerId];
    if (allRules == null || allRules.isEmpty) {
      return const _PathLayerPlayback.staticFrame();
    }
    final wholeLayerRules = allRules
        .where((r) => r.scope == PathAnimationActivationScope.wholeLayer)
        .toList(growable: false);
    if (wholeLayerRules.isEmpty) {
      // Only cellOnly rules → layer stays static, cells animate individually.
      return const _PathLayerPlayback.staticFrame();
    }
    var hasActiveLoop = false;
    double? activeLoopStartedAtMs;
    for (final rule in wholeLayerRules) {
      final key = _PathRuleKey(layerId: layerId, ruleId: rule.ruleId);
      final oneShot = _activePathRuleOneShotByKey[key];
      if (oneShot != null) {
        if (_isPathRuleOneShotCompleted(oneShot)) {
          _activePathRuleOneShotByKey.remove(key);
        } else {
          return _PathLayerPlayback.oneShot(startedAtMs: oneShot.startedAtMs);
        }
      }
      final loopStartedAtMs = _activePathRuleLoopStartedAtMsByKey[key];
      if (loopStartedAtMs != null && !hasActiveLoop) {
        hasActiveLoop = true;
        activeLoopStartedAtMs = loopStartedAtMs;
      }
    }
    if (hasActiveLoop && activeLoopStartedAtMs != null) {
      return _PathLayerPlayback.loopFrom(startedAtMs: activeLoopStartedAtMs);
    }
    return const _PathLayerPlayback.staticFrame();
  }

  _PathLayerPlayback _resolvePathCellPlayback({
    required String layerId,
    required int x,
    required int y,
  }) {
    final rules = _pathRulesByLayerId[layerId];
    if (rules == null) return const _PathLayerPlayback.staticFrame();
    for (final rule in rules) {
      if (rule.scope != PathAnimationActivationScope.cellOnly) continue;
      final cellKey =
          _PathRuleCellKey(layerId: layerId, ruleId: rule.ruleId, x: x, y: y);
      final oneShot = _activePathRuleCellOneShotByKey[cellKey];
      if (oneShot != null) {
        if (_isPathRuleOneShotCompleted(oneShot)) {
          _activePathRuleCellOneShotByKey.remove(cellKey);
        } else {
          return _PathLayerPlayback.oneShot(startedAtMs: oneShot.startedAtMs);
        }
      }
      final loopStartedAtMs = _activePathRuleCellLoopStartedAtMsByKey[cellKey];
      if (loopStartedAtMs != null) {
        return _PathLayerPlayback.loopFrom(startedAtMs: loopStartedAtMs);
      }
    }
    return const _PathLayerPlayback.staticFrame();
  }

  bool _isPathRuleOneShotCompleted(_ActivePathRuleOneShot state) {
    final elapsed = (_animElapsed * 1000) - state.startedAtMs;
    return elapsed >= state.durationMs;
  }

  _PathRuleSpec? _resolvePathRuleSpec(_PathRuleKey key) {
    final rules = _pathRulesByLayerId[key.layerId];
    if (rules == null || rules.isEmpty) {
      return null;
    }
    for (final spec in rules) {
      if (spec.ruleId == key.ruleId) {
        return spec;
      }
    }
    return null;
  }

  void _pruneCompletedPathRuleOneShots() {
    if (_activePathRuleOneShotByKey.isEmpty) {
      return;
    }
    final completedKeys = <_PathRuleKey>[];
    for (final entry in _activePathRuleOneShotByKey.entries) {
      if (_isPathRuleOneShotCompleted(entry.value)) {
        completedKeys.add(entry.key);
      }
    }
    for (final key in completedKeys) {
      _activePathRuleOneShotByKey.remove(key);
    }
  }

  _ResolvedPathVariantFrame? _resolvePathVariantFrame({
    required RuntimePathAutotileSet autotileSet,
    required _PathLayerPlayback playback,
    required TerrainPathVariant variant,
    required double elapsedMs,
  }) {
    switch (playback.kind) {
      case _PathLayerPlaybackKind.alwaysLoop:
        final frame = autotileSet.frameForVariantAt(
          variant,
          elapsedMs: elapsedMs,
        );
        if (frame == null) {
          return null;
        }
        final tilesetId = autotileSet.resolvedTilesetId(
          frame,
        );
        return _ResolvedPathVariantFrame(
          source: frame.source,
          tilesetId: tilesetId,
        );
      case _PathLayerPlaybackKind.staticFrame:
        final frame = autotileSet.frameForVariantStatic(variant);
        if (frame == null) {
          return null;
        }
        final tilesetId = autotileSet.resolvedTilesetId(
          frame,
        );
        return _ResolvedPathVariantFrame(
          source: frame.source,
          tilesetId: tilesetId,
        );
      case _PathLayerPlaybackKind.loopFrom:
        final localElapsed = elapsedMs - playback.startedAtMs;
        final frame = autotileSet.frameForVariantAt(
          variant,
          elapsedMs: localElapsed,
        );
        if (frame == null) {
          return null;
        }
        final tilesetId = autotileSet.resolvedTilesetId(
          frame,
        );
        return _ResolvedPathVariantFrame(
          source: frame.source,
          tilesetId: tilesetId,
        );
      case _PathLayerPlaybackKind.oneShot:
        final localElapsed = elapsedMs - playback.startedAtMs;
        final frame = autotileSet.frameForVariantOneShot(
          variant,
          elapsedMs: localElapsed,
        );
        if (frame == null) {
          return null;
        }
        final tilesetId = autotileSet.resolvedTilesetId(
          frame,
        );
        return _ResolvedPathVariantFrame(
          source: frame.source,
          tilesetId: tilesetId,
        );
    }
  }

  void _paintPathLayer(
    Canvas canvas,
    String layerId,
    String presetId,
    List<bool> cells,
    double opacity,
  ) {
    final map = bundle.map;
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final tw = bundle.manifest.settings.tileWidth;
    final th = bundle.manifest.settings.tileHeight;
    final w = map.size.width;
    final h = map.size.height;
    final pid = presetId.trim();
    final autotileSet = pid.isEmpty ? null : _pathAutotileByPresetId[pid];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (idx >= cells.length || !cells[idx]) {
          continue;
        }
        final cell = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        final drawn = autotileSet != null &&
            _paintPathLayerCell(
              canvas,
              layerId: layerId,
              presetId: pid,
              autotileSet: autotileSet,
              cells: cells,
              x: x,
              y: y,
              tw: tw,
              th: th,
              cell: cell,
              alpha: opacity,
            );
        if (drawn) {
          continue;
        }
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.teal
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          cell,
          Paint()
            ..color = Colors.tealAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  bool _paintPathLayerCell(
    Canvas canvas, {
    required String layerId,
    required String presetId,
    required RuntimePathAutotileSet autotileSet,
    required List<bool> cells,
    required int x,
    required int y,
    required int tw,
    required int th,
    required Rect cell,
    required double alpha,
  }) {
    if (tw <= 0 || th <= 0) {
      return false;
    }
    final variant = resolvePathVariantAt(
      cells: cells,
      mapSize: bundle.map.size,
      pos: GridPos(x: x, y: y),
    );
    final cellPlayback = _resolvePathCellPlayback(layerId: layerId, x: x, y: y);
    final playback = cellPlayback.kind != _PathLayerPlaybackKind.staticFrame
        ? cellPlayback
        : _resolvePathLayerPlayback(layerId: layerId, presetId: presetId);
    return _paintAutotileVariantCell(
      canvas,
      autotileSet: autotileSet,
      playback: playback,
      variant: variant,
      tw: tw,
      th: th,
      dstRect: cell,
      alpha: alpha,
      elapsedMs: _animElapsed * 1000,
    );
  }

  bool _paintAutotileVariantCell(
    Canvas canvas, {
    required RuntimePathAutotileSet autotileSet,
    required _PathLayerPlayback playback,
    required TerrainPathVariant variant,
    required int tw,
    required int th,
    required Rect dstRect,
    required double alpha,
    required double elapsedMs,
  }) {
    final resolved = _resolvePathVariantFrame(
      autotileSet: autotileSet,
      playback: playback,
      variant: variant,
      elapsedMs: elapsedMs,
    );
    if (resolved == null) {
      return false;
    }
    final source = resolved.source;
    final tilesetId = resolved.tilesetId.trim();
    if (tilesetId.isEmpty) {
      return false;
    }
    final tilesetImage = tileImagesByTilesetId[tilesetId];
    if (tilesetImage == null) {
      return false;
    }
    final sourceX = source.x * tw;
    final sourceY = source.y * th;
    final srcRect = Rect.fromLTWH(
      sourceX.toDouble(),
      sourceY.toDouble(),
      tw.toDouble(),
      th.toDouble(),
    );
    if (!tilesetImage.containsSourceRect(srcRect)) {
      return false;
    }
    tilesetImage.drawImageRect(
      canvas,
      srcRect,
      dstRect,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none
        ..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
    return true;
  }
}

class _RuntimeAnimationFrame {
  const _RuntimeAnimationFrame({
    required this.tilesetId,
    required this.source,
    required this.durationMs,
  });

  final String tilesetId;
  final TilesetSourceRect source;
  final int? durationMs;
}

class _ResolvedTerrainFrame {
  const _ResolvedTerrainFrame({
    required this.tilesetId,
    required this.source,
  });

  final String tilesetId;
  final TilesetSourceRect source;
}

class _AnimatedPlacedCell {
  const _AnimatedPlacedCell({
    required this.instanceId,
    required this.localX,
    required this.localY,
    required this.frames,
    required this.frameDurationsMs,
    required this.animation,
    required this.deterministicSeed,
  });

  final String instanceId;
  final int localX;
  final int localY;
  final List<_RuntimeAnimationFrame> frames;
  final List<int> frameDurationsMs;
  final MapPlacedElementAnimation animation;
  final int deterministicSeed;
}

class _AnimatedPlacedInstanceSpec {
  const _AnimatedPlacedInstanceSpec({
    required this.frameDurationsMs,
    required this.speed,
  });

  final List<int> frameDurationsMs;
  final double speed;
}

class _ActiveOneShotAnimation {
  const _ActiveOneShotAnimation({
    required this.startedAtMs,
    required this.frameDurationsMs,
    required this.speed,
  });

  final double startedAtMs;
  final List<int> frameDurationsMs;
  final double speed;
}

class _PathRuleKey {
  const _PathRuleKey({
    required this.layerId,
    required this.ruleId,
  });

  final String layerId;
  final String ruleId;

  @override
  bool operator ==(Object other) {
    return other is _PathRuleKey &&
        other.layerId == layerId &&
        other.ruleId == ruleId;
  }

  @override
  int get hashCode => Object.hash(layerId, ruleId);
}

class _ActivePathRuleOneShot {
  const _ActivePathRuleOneShot({
    required this.startedAtMs,
    required this.durationMs,
  });

  final double startedAtMs;
  final int durationMs;
}

class _PathRuleSpec {
  const _PathRuleSpec({
    required this.ruleId,
    required this.rule,
    required this.scope,
    required this.hasAnimatedFrames,
    required this.oneShotDurationMs,
  });

  final String ruleId;
  final PathAnimationTriggerRule rule;
  final PathAnimationActivationScope scope;
  final bool hasAnimatedFrames;
  final int oneShotDurationMs;
}

class _PathRuleCellKey {
  const _PathRuleCellKey({
    required this.layerId,
    required this.ruleId,
    required this.x,
    required this.y,
  });

  final String layerId;
  final String ruleId;
  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is _PathRuleCellKey &&
      other.layerId == layerId &&
      other.ruleId == ruleId &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(layerId, ruleId, x, y);
}

enum _PathLayerPlaybackKind {
  alwaysLoop,
  staticFrame,
  loopFrom,
  oneShot,
}

class _PathLayerPlayback {
  const _PathLayerPlayback._({
    required this.kind,
    required this.startedAtMs,
  });

  const _PathLayerPlayback.alwaysLoop()
      : this._(
          kind: _PathLayerPlaybackKind.alwaysLoop,
          startedAtMs: 0,
        );

  const _PathLayerPlayback.staticFrame()
      : this._(
          kind: _PathLayerPlaybackKind.staticFrame,
          startedAtMs: 0,
        );

  const _PathLayerPlayback.loopFrom({
    required double startedAtMs,
  }) : this._(
          kind: _PathLayerPlaybackKind.loopFrom,
          startedAtMs: startedAtMs,
        );

  const _PathLayerPlayback.oneShot({
    required double startedAtMs,
  }) : this._(
          kind: _PathLayerPlaybackKind.oneShot,
          startedAtMs: startedAtMs,
        );

  final _PathLayerPlaybackKind kind;
  final double startedAtMs;
}

class _ResolvedPathVariantFrame {
  const _ResolvedPathVariantFrame({
    required this.source,
    required this.tilesetId,
  });

  final TilesetSourceRect source;
  final String tilesetId;
}

String? _resolveTilesetId(MapData map, String? layerTilesetId) {
  final fromLayer = layerTilesetId?.trim() ?? '';
  if (fromLayer.isNotEmpty) {
    return fromLayer;
  }
  final fallback = map.tilesetId.trim();
  return fallback.isNotEmpty ? fallback : null;
}

Color _terrainFillColor(TerrainType terrain) {
  return switch (terrain) {
    TerrainType.none => Colors.transparent,
    TerrainType.grass => Colors.lightGreenAccent,
    TerrainType.dirt => const Color(0xFFA46E3D),
    TerrainType.sand => Colors.amberAccent,
    TerrainType.rock => Colors.blueGrey,
    TerrainType.stone => Colors.grey,
    TerrainType.indoor => const Color(0xFFD8C3A5),
  };
}

Color _terrainBorderColor(TerrainType terrain) {
  return switch (terrain) {
    TerrainType.grass => Colors.green.shade900,
    TerrainType.dirt => const Color(0xFF6D4524),
    TerrainType.sand => Colors.orange.shade900,
    TerrainType.rock => Colors.blueGrey.shade900,
    TerrainType.stone => Colors.grey.shade800,
    TerrainType.indoor => const Color(0xFF8D6E63),
    TerrainType.none => Colors.transparent,
  };
}

````

#### `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';

void main() {
  group('runtime manifest tileset collection with SurfaceLayer', () {
    test('collects Surface atlas tilesets through the runtime manifest path',
        () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        tilesetId: 'base-world',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(
            id: 'surfaces',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
            ],
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Surface Runtime',
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'base-world',
            name: 'Base World',
            relativePath: 'tilesets/base.png',
          ),
          ProjectTilesetEntry(
            id: 'surface-water',
            name: 'Surface Water',
            relativePath: 'tilesets/water.png',
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(
          atlases: [_atlas(id: 'water-atlas', tilesetId: 'surface-water')],
          animations: [
            _animation(
              id: 'water-isolated',
              frames: [_frame(atlasId: 'water-atlas')],
            ),
          ],
          presets: [_preset(id: 'water', animationId: 'water-isolated')],
        ),
      );

      expect(collectAllRuntimeTilesetIds(map, manifest), {
        'base-world',
        'surface-water',
      });
    });
  });
}

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 4, rows: 4),
    ),
  );
}

ProjectSurfaceAnimation _animation({
  required String id,
  required List<SurfaceAnimationFrame> frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
}

SurfaceAnimationFrame _frame({required String atlasId}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: atlasId, column: 0, row: 0),
    durationMs: 100,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required String animationId,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: animationId,
        ),
      ],
    ),
  );
}

````

#### `packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart`

````dart
import 'package:map_core/map_core.dart';

/// Pure runtime draw plan for one placed Surface cell.
///
/// Lot 89 deliberately stops at this data object: it carries enough catalog and
/// atlas coordinates for a future Flame renderer, but it does not load images
/// and does not draw.
final class SurfaceRuntimeRenderInstruction {
  const SurfaceRuntimeRenderInstruction({
    required this.x,
    required this.y,
    required this.surfacePresetId,
    required this.resolvedRole,
    required this.animationId,
    required this.atlasId,
    required this.tilesetId,
    required this.sourceColumn,
    required this.sourceRow,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
  });

  final int x;
  final int y;
  final String surfacePresetId;
  final SurfaceVariantRole resolvedRole;
  final String animationId;
  final String atlasId;
  final String tilesetId;
  final int sourceColumn;
  final int sourceRow;
  final int sourceTileWidth;
  final int sourceTileHeight;

  int get sourceX => sourceColumn * sourceTileWidth;

  int get sourceY => sourceRow * sourceTileHeight;
}

````

#### `packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart`

````dart
import 'package:map_core/map_core.dart';

import 'surface_runtime_render_instruction.dart';

/// Resolves Surface placements into pure runtime render instructions.
///
/// This is the runtime counterpart of the editor preview resolver, minus any
/// image cache or Flame dependency. Missing catalog references are skipped so a
/// partially-authored project can still load the rest of the map.
List<SurfaceRuntimeRenderInstruction> resolveSurfaceRuntimeRenderInstructions({
  required SurfaceLayer layer,
  required ProjectSurfaceCatalog catalog,
  int elapsedMs = 0,
}) {
  if (!layer.isVisible || layer.opacity <= 0) {
    return const <SurfaceRuntimeRenderInstruction>[];
  }

  final placements = _runtimeResolvablePlacements(layer.placements);
  if (placements.isEmpty) {
    return const <SurfaceRuntimeRenderInstruction>[];
  }

  final instructions = <SurfaceRuntimeRenderInstruction>[];
  for (final placement in placements) {
    final presetId = placement.surfacePresetId.trim();
    final preset = catalog.presetById(presetId);
    if (preset == null) {
      continue;
    }

    final role = resolveSurfaceVariantRoleForPlacement(
      placements: placements,
      x: placement.x,
      y: placement.y,
      surfacePresetId: presetId,
    );
    final animationId = _resolveAnimationId(preset, role);
    if (animationId == null) {
      continue;
    }

    final animation = catalog.animationById(animationId);
    if (animation == null) {
      continue;
    }

    final frame = _resolveSurfaceAnimationFrameAtElapsedMs(
      timeline: animation.timeline,
      elapsedMs: elapsedMs,
    );
    final atlasId = frame.tileRef.atlasId.trim();
    final atlas = catalog.atlasById(atlasId);
    if (atlas == null || !frame.tileRef.isInside(atlas.geometry)) {
      continue;
    }

    final tilesetId = atlas.tilesetId.trim();
    if (tilesetId.isEmpty) {
      continue;
    }

    instructions.add(
      SurfaceRuntimeRenderInstruction(
        x: placement.x,
        y: placement.y,
        surfacePresetId: presetId,
        resolvedRole: role,
        animationId: animationId,
        atlasId: atlas.id,
        tilesetId: tilesetId,
        sourceColumn: frame.tileRef.column,
        sourceRow: frame.tileRef.row,
        sourceTileWidth: atlas.geometry.tileSize.width,
        sourceTileHeight: atlas.geometry.tileSize.height,
      ),
    );
  }

  return List<SurfaceRuntimeRenderInstruction>.unmodifiable(instructions);
}

List<SurfaceCellPlacement> _runtimeResolvablePlacements(
  Iterable<SurfaceCellPlacement> placements,
) {
  final out = <SurfaceCellPlacement>[
    for (final placement in placements)
      if (placement.x >= 0 &&
          placement.y >= 0 &&
          placement.surfacePresetId.trim().isNotEmpty)
        placement,
  ]..sort((a, b) {
      final yComparison = a.y.compareTo(b.y);
      if (yComparison != 0) return yComparison;
      final xComparison = a.x.compareTo(b.x);
      if (xComparison != 0) return xComparison;
      return a.surfacePresetId.compareTo(b.surfacePresetId);
    });
  return List<SurfaceCellPlacement>.unmodifiable(out);
}

String? _resolveAnimationId(
  ProjectSurfacePreset preset,
  SurfaceVariantRole resolvedRole,
) {
  final exact = preset.animationIdForRole(resolvedRole)?.trim();
  if (exact != null && exact.isNotEmpty) {
    return exact;
  }

  final isolated =
      preset.animationIdForRole(SurfaceVariantRole.isolated)?.trim();
  if (isolated != null && isolated.isNotEmpty) {
    return isolated;
  }

  for (final ref in preset.variantAnimations.refs) {
    final animationId = ref.animationId.trim();
    if (animationId.isNotEmpty) {
      return animationId;
    }
  }
  return null;
}

SurfaceAnimationFrame _resolveSurfaceAnimationFrameAtElapsedMs({
  required SurfaceAnimationTimeline timeline,
  required int elapsedMs,
}) {
  if (timeline.frames.length == 1) {
    return timeline.frames.single;
  }

  final normalizedElapsedMs = elapsedMs < 0 ? 0 : elapsedMs;
  final totalDurationMs = timeline.totalDurationMs;
  if (totalDurationMs <= 0) {
    return timeline.frames.first;
  }

  var t = normalizedElapsedMs % totalDurationMs;
  for (final frame in timeline.frames) {
    if (t < frame.durationMs) {
      return frame;
    }
    t -= frame.durationMs;
  }
  return timeline.frames.first;
}

````

#### `packages/map_runtime/lib/src/surface/surface_runtime_tileset_collector.dart`

````dart
import 'package:map_core/map_core.dart';

/// Collects Surface atlas tilesets required by placed Surface presets.
///
/// The collector scans every frame referenced by each placed preset. That is a
/// little broader than the Lot 89 resolver, but it keeps runtime loading ready
/// for animations that hop across multiple atlases or tilesets.
Set<String> collectSurfaceRuntimeTilesetIds({
  required MapData map,
  required ProjectSurfaceCatalog catalog,
}) {
  final presetIds = <String>{};
  for (final layer in map.layers.whereType<SurfaceLayer>()) {
    for (final placement in layer.placements) {
      final presetId = placement.surfacePresetId.trim();
      if (presetId.isNotEmpty) {
        presetIds.add(presetId);
      }
    }
  }
  if (presetIds.isEmpty) {
    return const <String>{};
  }

  final tilesetIds = <String>{};
  for (final presetId in presetIds) {
    final preset = catalog.presetById(presetId);
    if (preset == null) {
      continue;
    }
    for (final ref in preset.variantAnimations.refs) {
      final animation = catalog.animationById(ref.animationId.trim());
      if (animation == null) {
        continue;
      }
      for (final frame in animation.timeline.frames) {
        final atlas = catalog.atlasById(frame.tileRef.atlasId.trim());
        final tilesetId = atlas?.tilesetId.trim();
        if (tilesetId != null && tilesetId.isNotEmpty) {
          tilesetIds.add(tilesetId);
        }
      }
    }
  }

  return Set<String>.unmodifiable(tilesetIds);
}

````

#### `packages/map_runtime/test/surface/surface_runtime_resolver_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/surface/surface_runtime_resolver.dart';

void main() {
  group('resolveSurfaceRuntimeRenderInstructions', () {
    test('resolves one isolated placement into a runtime instruction', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 4, y: 5, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas', column: 2, row: 1)],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
            },
          ),
        ],
      );

      final instructions = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(instruction.x, 4);
      expect(instruction.y, 5);
      expect(instruction.surfacePresetId, 'water');
      expect(instruction.resolvedRole, SurfaceVariantRole.isolated);
      expect(instruction.animationId, 'water-isolated');
      expect(instruction.atlasId, 'water-atlas');
      expect(instruction.tilesetId, 'water-tiles');
      expect(instruction.sourceColumn, 2);
      expect(instruction.sourceRow, 1);
      expect(instruction.sourceTileWidth, 32);
      expect(instruction.sourceTileHeight, 32);
      expect(instruction.sourceX, 64);
      expect(instruction.sourceY, 32);
    });

    test('uses same-preset neighbors to resolve the role', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas', column: 0)],
          ),
          _animation(
            id: 'water-horizontal',
            frames: [_frame(atlasId: 'water-atlas', column: 5)],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
              SurfaceVariantRole.horizontal: 'water-horizontal',
            },
          ),
        ],
      );

      final center = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      ).singleWhere((instruction) => instruction.x == 1);

      expect(center.resolvedRole, SurfaceVariantRole.horizontal);
      expect(center.animationId, 'water-horizontal');
      expect(center.sourceColumn, 5);
    });

    test('does not connect adjacent placements from different Surface presets',
        () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'lava'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'mud'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas')],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
            },
          ),
        ],
      );

      final instruction = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      ).single;

      expect(instruction.surfacePresetId, 'water');
      expect(instruction.resolvedRole, SurfaceVariantRole.isolated);
    });

    test('falls back to isolated animation when the resolved role is uncovered',
        () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas', column: 3)],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
            },
          ),
        ],
      );

      final center = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      ).singleWhere((instruction) => instruction.x == 1);

      expect(center.resolvedRole, SurfaceVariantRole.horizontal);
      expect(center.animationId, 'water-isolated');
      expect(center.sourceColumn, 3);
    });

    test('uses elapsedMs to select a frame without owning a runtime clock', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-loop',
            frames: [
              _frame(atlasId: 'water-atlas', column: 0, durationMs: 100),
              _frame(atlasId: 'water-atlas', column: 1, durationMs: 100),
            ],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-loop',
            },
          ),
        ],
      );

      final current = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
        elapsedMs: 100,
      ).single;

      expect(current.sourceColumn, 1);
    });

    test('skips unresolved preset animation atlas and out-of-atlas frames', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'missing-preset'),
          SurfaceCellPlacement(
              x: 1, y: 0, surfacePresetId: 'missing-animation'),
          SurfaceCellPlacement(x: 2, y: 0, surfacePresetId: 'missing-atlas'),
          SurfaceCellPlacement(x: 3, y: 0, surfacePresetId: 'outside-atlas'),
        ],
      );
      final catalog = _catalog(
        atlases: [
          _atlas(
            id: 'small-atlas',
            tilesetId: 'water-tiles',
            columns: 1,
            rows: 1,
          ),
        ],
        animations: [
          _animation(
            id: 'anim-with-missing-atlas',
            frames: [_frame(atlasId: 'missing-atlas')],
          ),
          _animation(
            id: 'anim-outside-atlas',
            frames: [_frame(atlasId: 'small-atlas', column: 2)],
          ),
        ],
        presets: [
          _preset(
            id: 'missing-animation',
            refs: {
              SurfaceVariantRole.isolated: 'does-not-exist',
            },
          ),
          _preset(
            id: 'missing-atlas',
            refs: {
              SurfaceVariantRole.isolated: 'anim-with-missing-atlas',
            },
          ),
          _preset(
            id: 'outside-atlas',
            refs: {
              SurfaceVariantRole.isolated: 'anim-outside-atlas',
            },
          ),
        ],
      );

      expect(
        resolveSurfaceRuntimeRenderInstructions(layer: layer, catalog: catalog),
        isEmpty,
      );
    });

    test('returns stable y/x/preset order and ignores hidden layers', () {
      const hiddenLayer = SurfaceLayer(
        id: 'hidden',
        name: 'Hidden',
        isVisible: false,
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        ],
      );
      expect(
        resolveSurfaceRuntimeRenderInstructions(
          layer: hiddenLayer,
          catalog: _simpleWaterCatalog(),
        ),
        isEmpty,
      );

      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
        ],
      );

      final keys = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: _simpleWaterCatalog(),
      ).map((instruction) => '${instruction.x}:${instruction.y}').toList();

      expect(keys, ['0:0', '1:0', '2:1']);
    });
  });
}

ProjectSurfaceCatalog _simpleWaterCatalog() {
  return _catalog(
    atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
    animations: [
      _animation(
        id: 'water-isolated',
        frames: [_frame(atlasId: 'water-atlas')],
      ),
    ],
    presets: [
      _preset(
        id: 'water',
        refs: {
          SurfaceVariantRole.isolated: 'water-isolated',
        },
      ),
    ],
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas> atlases = const [],
  List<ProjectSurfaceAnimation> animations = const [],
  List<ProjectSurfacePreset> presets = const [],
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases,
    animations: animations,
    presets: presets,
  );
}

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
  int columns = 8,
  int rows = 8,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
}

ProjectSurfaceAnimation _animation({
  required String id,
  required List<SurfaceAnimationFrame> frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
}

SurfaceAnimationFrame _frame({
  required String atlasId,
  int column = 0,
  int row = 0,
  int durationMs = 100,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required Map<SurfaceVariantRole, String> refs,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        for (final entry in refs.entries)
          SurfaceVariantAnimationRef(
            role: entry.key,
            animationId: entry.value,
          ),
      ],
    ),
  );
}

````

#### `packages/map_runtime/test/surface/surface_runtime_tileset_collector_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/surface/surface_runtime_tileset_collector.dart';

void main() {
  group('collectSurfaceRuntimeTilesetIds', () {
    test('collects the tileset used by a placed Surface preset', () {
      final map = _mapWithSurfacePlacements([
        const SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
      ]);
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas')],
          ),
        ],
        presets: [_preset(id: 'water', animationId: 'water-isolated')],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(map: map, catalog: catalog),
        {'water-tiles'},
      );
    });

    test('deduplicates tilesets while scanning every animation frame', () {
      final map = _mapWithSurfacePlacements([
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
      ]);
      final catalog = _catalog(
        atlases: [
          _atlas(id: 'atlas-a', tilesetId: 'shared-water-tiles'),
          _atlas(id: 'atlas-b', tilesetId: 'foam-tiles'),
          _atlas(id: 'atlas-c', tilesetId: 'shared-water-tiles'),
        ],
        animations: [
          _animation(
            id: 'water-loop',
            frames: [
              _frame(atlasId: 'atlas-a', column: 0),
              _frame(atlasId: 'atlas-b', column: 1),
              _frame(atlasId: 'atlas-c', column: 2),
            ],
          ),
        ],
        presets: [_preset(id: 'water', animationId: 'water-loop')],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(map: map, catalog: catalog),
        {'shared-water-tiles', 'foam-tiles'},
      );
    });

    test('ignores missing preset animation and atlas references without crash',
        () {
      final map = _mapWithSurfacePlacements([
        const SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'missing'),
        const SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'broken'),
        const SurfaceCellPlacement(x: 2, y: 0, surfacePresetId: 'no-atlas'),
      ]);
      final catalog = _catalog(
        animations: [
          _animation(
            id: 'anim-with-missing-atlas',
            frames: [_frame(atlasId: 'missing-atlas')],
          ),
        ],
        presets: [
          _preset(id: 'broken', animationId: 'missing-animation'),
          _preset(id: 'no-atlas', animationId: 'anim-with-missing-atlas'),
        ],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(map: map, catalog: catalog),
        isEmpty,
      );
    });

    test('ignores empty SurfaceLayer and non-Surface layers', () {
      const map = MapData(
        id: 'route-1',
        name: 'Route 1',
        tilesetId: 'base-world',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.surface(id: 'surface-empty', name: 'Surfaces'),
          MapLayer.terrain(
            id: 'terrain',
            name: 'Terrain',
            terrains: [TerrainType.grass],
          ),
          MapLayer.path(
            id: 'path',
            name: 'Path',
            presetId: 'road',
            cells: [true],
          ),
        ],
      );

      expect(
        collectSurfaceRuntimeTilesetIds(
            map: map, catalog: ProjectSurfaceCatalog()),
        isEmpty,
      );
    });
  });
}

MapData _mapWithSurfacePlacements(List<SurfaceCellPlacement> placements) {
  return MapData(
    id: 'route-1',
    name: 'Route 1',
    tilesetId: 'base-world',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.surface(
        id: 'surface',
        name: 'Surfaces',
        placements: placements,
      ),
    ],
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas> atlases = const [],
  List<ProjectSurfaceAnimation> animations = const [],
  List<ProjectSurfacePreset> presets = const [],
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases,
    animations: animations,
    presets: presets,
  );
}

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 8, rows: 8),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
}

ProjectSurfaceAnimation _animation({
  required String id,
  required List<SurfaceAnimationFrame> frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
}

SurfaceAnimationFrame _frame({
  required String atlasId,
  int column = 0,
  int row = 0,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: 100,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required String animationId,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: animationId,
        ),
      ],
    ),
  );
}

````


## 20. Limites restantes
- Pas de rendu Flame Surface : le Lot 90 devra consommer `SurfaceRuntimeRenderInstruction`.
- Pas de clock runtime Surface : `elapsedMs` est prêt, mais aucun tick global n’est branché.
- Pas de diagnostics structurés des références manquantes : les refs incomplètes sont simplement ignorées.
- Le resolver est V0 : il ne résout pas des variantes avancées au-delà du rôle produit par `map_core`.

## 21. Auto-critique
- Le choix de dupliquer une petite résolution temporelle côté runtime évite de toucher `map_core`, mais il faudra éviter une divergence future avec l’éditeur.
- Le collecteur scanne toutes les refs du preset placé, pas seulement les rôles réellement atteints sur la map. C’est volontaire pour charger toutes les frames, mais peut charger quelques textures non visibles dans un cas extrême.
- Le rapport est très lourd à cause de l’exigence de contenu complet, surtout `map_layers_component.dart`.

## 22. Regard critique sur le prompt
- Demander le contenu complet de gros fichiers modifiés rend les rapports difficiles à relire et gonfle le diff ; une preuve par diff ciblé serait souvent plus efficace.
- Le lot demande un resolver avec `elapsedMs` tout en interdisant la clock runtime : c’est cohérent, mais cela anticipe déjà un peu le Lot 90/91.
- Le périmètre est bon : commencer par collecte + instructions avant de dessiner est la bonne marche d’escalier.

## 23. Auto-review obligatoire
- Est-ce que map_runtime collecte les tilesets Surface nécessaires ? Oui.
- Est-ce que les tilesets sont dédupliqués ? Oui.
- Est-ce que toutes les frames sont prises en compte pour la collecte ? Oui.
- Est-ce qu’un resolver runtime Surface existe ? Oui.
- Est-ce que le resolver produit des instructions sans dessiner ? Oui.
- Est-ce que le rôle est résolu via les voisins même surfacePresetId ? Oui.
- Est-ce que les surfaces différentes ne se connectent pas ? Oui.
- Est-ce que les catalogues incomplets ne crashent pas ? Oui.
- Est-ce que Flame est inchangé côté rendu ? Oui.
- Est-ce que map_runtime reste sans renderer Surface ? Oui.
- Est-ce que Surface Painter reste non régressé si testé ? Non lancé, car `map_editor` et `map_core` exports n’ont pas été modifiés.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que l’analyse ciblée passe ? Oui.
- Est-ce qu’un Lot 89-bis est nécessaire ? Non pour cette fondation ; le prochain lot logique est le renderer runtime Surface.
