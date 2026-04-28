# Lot 90 — Runtime Surface Flame Renderer V0

## 1. Résumé exécutif honnête
Lot 90 consomme les instructions runtime Surface du Lot 89 et dessine maintenant les vraies tiles Surface dans `MapLayersComponent`.

Implémenté :
- rendu des `SurfaceLayer` visibles dans le background pass ;
- appel à `resolveSurfaceRuntimeRenderInstructions(...)` ;
- passage de `elapsedMs: (_animElapsed * 1000).toInt()` ;
- récupération de `RuntimeTilesetImage` par `instruction.tilesetId` ;
- calcul `sourceRect` depuis `instruction.sourceX/sourceY/sourceTileWidth/sourceTileHeight` ;
- calcul destination depuis `instruction.x/y` et `bundle.cellWidth/cellHeight` ;
- dessin via `RuntimeTilesetImage.drawImageRect(...)` ;
- respect de `layer.opacity` ;
- skip sans crash pour image manquante, source hors image, layer invisible/opacité zéro.

Non implémenté volontairement : gameplay surf, tall grass encounters, collision Surface, migration legacy, nouvelle clock runtime, changement JSON, Surface Studio/Surface Painter.

## 2. Périmètre
Modifié uniquement :
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Créé :
- `packages/map_runtime/test/surface/surface_runtime_renderer_test.dart`
- ce rapport.

Aucun changement dans `map_core`, `map_editor`, `map_gameplay`, `map_battle`.

## 3. Gate 0 — status initial
Gate 0 capturé après commit du Lot 89 et avant toute modification Lot 90.

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
da2b244d feat(map_runtime): add surface runtime resolver
32fbb0b5 feat(map_editor): improve surface mapping editor
d5561df7 feat(map_editor): edit surface role animation mapping
935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
```

Changements préexistants : aucun.

## 4. Audit MapLayersComponent
Commandes d’audit lancées :

```bash
rg -n "SurfaceRuntimeRenderInstruction|resolveSurfaceRuntimeRenderInstructions|collectSurfaceRuntimeTilesetIds|SurfaceLayer|MapLayer.surface" packages/map_runtime packages/map_core
rg -n "_paintPathLayer|_paintTerrainLayer|_paintTileLayer|MapLayersComponent|renderPass|_animElapsed|drawImageRect|RuntimeTilesetImage" packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src
rg -n "map_layers_component_render_pass_test|RuntimeTilesetImage|containsSourceRect|drawImageRect|surface_runtime" packages/map_runtime/test packages/map_runtime/lib
```

Constats :
- `MapLayersComponent.render` peint déjà le background pass en trois séquences : terrain, path, tile, puis entities et overlay collision optionnel.
- Le foreground pass peint uniquement les tile layers de foreground puis entities de foreground.
- `_animElapsed` est déjà incrémenté dans `update(dt)` et utilisé pour les animations existantes.
- Les tile/path/terrain paths utilisent déjà `RuntimeTilesetImage.containsSourceRect` et `RuntimeTilesetImage.drawImageRect`.

## 5. Audit RuntimeTilesetImage / drawImageRect
`RuntimeTilesetImage` fournit :
- `containsSourceRect(ui.Rect)` pour éviter les sources invalides ;
- `drawImageRect(ui.Canvas, ui.Rect sourceRect, ui.Rect destinationRect, ui.Paint)` qui découpe si nécessaire via les chunks internes.

Donc le renderer Surface n’a pas besoin de charger d’image ni de connaître les chunks ; il reçoit un `RuntimeTilesetImage` déjà chargé via le pipeline Lot 89.

## 6. Architecture retenue
Choix retenu : méthode privée bornée `_paintSurfaceLayer(Canvas, SurfaceLayer)` dans `MapLayersComponent`.

Raisons :
- le rendu dépend de `bundle`, `tileImagesByTilesetId`, `_animElapsed`, `cellWidth/cellHeight` déjà présents dans le composant ;
- créer une architecture séparée serait plus lourd que nécessaire pour V0 ;
- les tests pixel valident le comportement sans mock complexe.

## 7. Ordre de rendu choisi
Ordre background final :

```text
terrain
→ path
→ surface
→ tile
→ entities
→ collision overlay éventuel
```

Les surfaces sont donc au-dessus du sol/path de base, mais sous les tile layers décoratifs/buildings et sous les entités. Aucun rendu Surface en foreground pass V0.

## 8. Implémentation Surface renderer
`_paintSurfaceLayer` :
- résout les instructions via le resolver runtime Lot 89 ;
- construit un `Paint` pixel-art (`isAntiAlias=false`, `FilterQuality.none`) ;
- applique `Colors.white.withValues(alpha: layer.opacity.clamp(0.0, 1.0))` ;
- skip si `instructions.isEmpty`, alpha zéro, image manquante, source rect hors image ;
- dessine via `RuntimeTilesetImage.drawImageRect`.

## 9. Animation via _animElapsed
Le renderer passe :

```dart
elapsedMs: (_animElapsed * 1000).toInt()
```

Aucune nouvelle clock runtime n’a été créée. Le test `uses _animElapsed to render the current Surface animation frame` appelle `component.update(0.1)` et vérifie que la deuxième frame est dessinée.

## 10. Fallbacks
- `SurfaceLayer.isVisible == false` : pas dessiné via le filtre `visible` et le resolver.
- `SurfaceLayer.opacity <= 0` : pas dessiné.
- Image manquante : skip.
- Source rect hors image : skip.
- Catalogue incomplet : le resolver retourne zéro instruction ou skippe les instructions invalides.
- Aucun fallback debug jaune runtime : volontaire, pour éviter des artefacts de production.

## 11. Tests lancés
### TDD rouge initial
```text
cd packages/map_runtime && flutter test test/surface/surface_runtime_renderer_test.dart
Résultat attendu : échec avant implémentation.
Échecs clés :
Expected: [255, 0, 0, 255]
Actual: [0, 0, 0, 0]
Expected: [0, 0, 255, 255]
Actual: [0, 0, 0, 0]
```

### Tests finaux
```text
cd packages/map_runtime && flutter test test/surface/surface_runtime_renderer_test.dart
00:01 +5: All tests passed!

cd packages/map_runtime && flutter test test/surface
00:01 +16: All tests passed!

cd packages/map_runtime && flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
00:01 +1: All tests passed!

cd packages/map_runtime && flutter test test/map_layers_component_render_pass_test.dart
00:01 +2: All tests passed!
```

## 12. Résultats
- Surface visible dessinée en background pass : oui, test pixel rouge.
- Animation via `_animElapsed` : oui, test pixel bleu après `update(0.1)`.
- Foreground pass ne rend pas SurfaceLayer : oui, pixel transparent.
- Missing image et source rect invalide : skip sans crash.
- Invisible/opacité zéro : skip.
- Tests Lot 89 non régressés : `test/surface` et `runtime_manifest_tilesets_surface_layer_test` verts.

## 13. Fichiers créés
```text
packages/map_runtime/test/surface/surface_runtime_renderer_test.dart
reports/surface/surface_engine_lot_90_runtime_surface_flame_renderer.md
```

## 14. Fichiers modifiés
```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
```

## 15. Fichiers supprimés
Aucun.

## 16. Evidence Pack
### Analyse ciblée
```text
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/map_layers_component.dart test/surface/surface_runtime_renderer_test.dart
Analyzing 2 items...
No issues found! (ran in 1.3s)
```

### Notes commandes
Le Lot 90 n’a utilisé aucune commande Git d’écriture après son Gate 0. Le commit réalisé en début de tour concernait explicitement le Lot 89, autorisé par l’utilisateur avant l’entrée dans le Gate 0 du Lot 90.

## 17. Git status final
```text
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
?? packages/map_runtime/test/surface/surface_runtime_renderer_test.dart
?? reports/surface/surface_engine_lot_90_runtime_surface_flame_renderer.md
```

### Diff stat final
```text
 .../presentation/flame/map_layers_component.dart   | 54 +++++++++++++++++++++-
 1 file changed, 52 insertions(+), 2 deletions(-)
```

Note : `git diff --stat` ne liste pas les nouveaux fichiers non trackés. Ils sont listés dans le status final et les sections fichiers créés/modifiés.

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
- `map_core` non modifié.
- `map_editor` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- Codecs Surface non modifiés.
- Aucune migration legacy.
- Aucun gameplay surf.
- Aucun tall grass encounter.
- Aucune nouvelle clock runtime.
- Aucun changement JSON.

## 19. Contenu complet des fichiers modifiés/créés/supprimés
Le rapport lui-même est exclu pour éviter une récursion infinie. Tous les autres fichiers créés/modifiés par le Lot 90 sont inclus en entier ci-dessous.

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
import '../../surface/surface_runtime_resolver.dart';
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
      final layer = visible[i];
      if (layer is SurfaceLayer) {
        _paintSurfaceLayer(canvas, layer);
      }
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

  void _paintSurfaceLayer(Canvas canvas, SurfaceLayer layer) {
    final instructions = resolveSurfaceRuntimeRenderInstructions(
      layer: layer,
      catalog: bundle.manifest.surfaceCatalog,
      elapsedMs: (_animElapsed * 1000).toInt(),
    );
    if (instructions.isEmpty) {
      return;
    }

    final alpha = layer.opacity.clamp(0.0, 1.0);
    if (alpha <= 0) {
      return;
    }

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..color = Colors.white.withValues(alpha: alpha);
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    for (final instruction in instructions) {
      final image = tileImagesByTilesetId[instruction.tilesetId];
      if (image == null) {
        continue;
      }
      final src = Rect.fromLTWH(
        instruction.sourceX.toDouble(),
        instruction.sourceY.toDouble(),
        instruction.sourceTileWidth.toDouble(),
        instruction.sourceTileHeight.toDouble(),
      );
      if (!image.containsSourceRect(src)) {
        continue;
      }
      final dst = Rect.fromLTWH(
        instruction.x * cw,
        instruction.y * ch,
        cw,
        ch,
      );
      image.drawImageRect(canvas, src, dst, paint);
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

#### `packages/map_runtime/test/surface/surface_runtime_renderer_test.dart`

````dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent Surface runtime rendering', () {
    test('draws a visible SurfaceLayer in the background pass', () async {
      final component = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await _runtimeTilesetImage([
            const Color(0xFFFF0000),
            const Color(0xFF0000FF),
          ]),
        },
      );

      final image = await _renderComponent(component);

      expect(await _pixelAt(image, 16, 16), _rgba(255, 0, 0, 255));
    });

    test('uses _animElapsed to render the current Surface animation frame',
        () async {
      final component = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await _runtimeTilesetImage([
            const Color(0xFFFF0000),
            const Color(0xFF0000FF),
          ]),
        },
      )..update(0.1);

      final image = await _renderComponent(component);

      expect(await _pixelAt(image, 16, 16), _rgba(0, 0, 255, 255));
    });

    test('does not draw SurfaceLayer in the foreground pass', () async {
      final component = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await _runtimeTilesetImage([
            const Color(0xFFFF0000),
            const Color(0xFF0000FF),
          ]),
        },
        renderPass: MapLayerRenderPass.foreground,
      );

      final image = await _renderComponent(component);

      expect(await _pixelAt(image, 16, 16), _rgba(0, 0, 0, 0));
    });

    test('skips missing tileset images and invalid source rects without crash',
        () async {
      final missingImage = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: const {},
      );

      final missingImageFrame = await _renderComponent(missingImage);
      expect(await _pixelAt(missingImageFrame, 16, 16), _rgba(0, 0, 0, 0));

      final invalidSource = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'outside'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water':
              await _runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );

      final invalidSourceFrame = await _renderComponent(invalidSource);
      expect(await _pixelAt(invalidSourceFrame, 16, 16), _rgba(0, 0, 0, 0));
    });

    test('skips invisible SurfaceLayer and opacity zero SurfaceLayer',
        () async {
      final invisible = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            isVisible: false,
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water':
              await _runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );
      expect(
        await _pixelAt(await _renderComponent(invisible), 16, 16),
        _rgba(0, 0, 0, 0),
      );

      final transparent = MapLayersComponent(
        bundle: _bundle(
          layer: const SurfaceLayer(
            id: 'surface',
            name: 'Surfaces',
            opacity: 0,
            placements: [
              SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water':
              await _runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
      );
      expect(
        await _pixelAt(await _renderComponent(transparent), 16, 16),
        _rgba(0, 0, 0, 0),
      );
    });
  });
}

RuntimeMapBundle _bundle({required SurfaceLayer layer}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Surface Runtime',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'surface-water',
          name: 'Surface Water',
          relativePath: 'tilesets/water.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 32,
        tileHeight: 32,
        displayScale: 1,
      ),
      surfaceCatalog: ProjectSurfaceCatalog(
        atlases: [
          _atlas(
            id: 'water-atlas',
            tilesetId: 'surface-water',
            columns: 2,
          ),
        ],
        animations: [
          _animation(
            id: 'water-loop',
            frames: [
              _frame(atlasId: 'water-atlas', column: 0, durationMs: 100),
              _frame(atlasId: 'water-atlas', column: 1, durationMs: 100),
            ],
          ),
          _animation(
            id: 'outside-loop',
            frames: [
              _frame(atlasId: 'water-atlas', column: 3, durationMs: 100),
            ],
          ),
        ],
        presets: [
          _preset(id: 'water', animationId: 'water-loop'),
          _preset(id: 'outside', animationId: 'outside-loop'),
        ],
      ),
    ),
    map: MapData(
      id: 'route-1',
      name: 'Route 1',
      size: const GridSize(width: 1, height: 1),
      layers: [layer],
    ),
    projectRootDirectory: '/tmp/project',
    tilesetAbsolutePathsById: const {},
  );
}

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
  int columns = 1,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: columns, rows: 1),
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
  required int column,
  required int durationMs,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: atlasId, column: column, row: 0),
    durationMs: durationMs,
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

Future<RuntimeTilesetImage> _runtimeTilesetImage(List<Color> colors) async {
  final image = await _tilesetImage(colors);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(top: 0, height: 32, width: colors.length * 32),
    ],
    width: colors.length * 32,
    height: 32,
  );
}

Future<ui.Image> _tilesetImage(List<Color> colors) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < colors.length; i++) {
    canvas.drawRect(
      Rect.fromLTWH((i * 32).toDouble(), 0, 32, 32),
      Paint()..color = colors[i],
    );
  }
  return recorder.endRecording().toImage(colors.length * 32, 32);
}

Future<ui.Image> _renderComponent(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(32, 32);
}

Future<List<int>> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}

````


## 20. Limites restantes
- Pas de z-index Surface avancé : V0 place les surfaces entre path et tile layers.
- Pas de synchronisation Surface dédiée : `_animElapsed` suffit pour V0.
- Pas de test d’intégration complet `PlayableMapGame` avec un projet disque réel Surface ; les tests couvrent le composant de rendu directement.
- Pas de gameplay/collision Surface.

## 21. Auto-critique
- Le test pixel est robuste pour le renderer, mais il ne vérifie pas un runtime end-to-end chargé depuis fichiers projet. Ce serait utile quand un golden Surface runtime sera demandé.
- Le renderer est dans `MapLayersComponent`; c’est simple et borné, mais si Surface grossit beaucoup, un helper dédié deviendra préférable.
- Le rapport reste volumineux parce que `map_layers_component.dart` est un gros fichier inclus intégralement.

## 22. Regard critique sur le prompt
- Le prompt est bon sur le séquençage : utiliser le resolver Lot 89 avant tout renderer évite une implémentation ad hoc.
- L’exigence de contenu complet de gros fichiers rend le rapport plus lourd que nécessaire ; un diff complet ciblé serait plus lisible.
- Dire “pas de renderer séparé complexe” est utile : cela évite une architecture prématurée.

## 23. Auto-review obligatoire
- Est-ce que les surfaces sont dessinées dans le runtime Flame ? Oui.
- Est-ce que le renderer consomme `SurfaceRuntimeRenderInstruction` ? Oui, via `resolveSurfaceRuntimeRenderInstructions`.
- Est-ce que le renderer utilise `RuntimeTilesetImage.drawImageRect` ? Oui.
- Est-ce que `sourceRect` est calculé depuis `instruction.sourceX/sourceY` ? Oui.
- Est-ce que destination rect utilise `x/y + cellWidth/cellHeight` ? Oui.
- Est-ce que `layer.opacity` est respectée ? Oui.
- Est-ce que `elapsedMs` vient de `_animElapsed` ? Oui.
- Est-ce qu’une nouvelle clock runtime a été créée ? Non.
- Est-ce que les surfaces sont rendues uniquement en background pass ? Oui.
- Est-ce que missing image / invalid sourceRect ne crashe pas ? Oui.
- Est-ce que terrain/path/tile ne régressent pas ? Oui, tests ciblés verts.
- Est-ce que map_core est inchangé ? Oui.
- Est-ce que map_editor est inchangé ? Oui.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que l’analyse ciblée passe ? Oui.
- Est-ce qu’un Lot 90-bis est nécessaire ? Non pour le renderer V0 ; le prochain vrai lot serait plutôt un golden runtime Surface ou gameplay/collision selon priorité.
