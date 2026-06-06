# NS-SCENES-V1-86 — Evidence Pack

## 1. Lot

Lot : `NS-SCENES-V1-86 — Cinematic Map Backdrop Visual Composition Polish V0`.

Demande : Karim a demandé ce lot avant de continuer vers les acteurs, avec autorisation d'utiliser sub-agents et manipulation/screenshot via Codex.

## 2. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git status --short --untracked-files=all
<aucune sortie>

git diff --stat
<aucune sortie>

git diff --name-only
<aucune sortie>

git log --oneline -n 1
c730bef3 feat(narrative): auto-commit changes
```

## 3. Sub-agents

Pass A — UX/Layout :

```text
La map V1-85 paraissait trop petite car la zone preview donnait trop de poids aux badges, au chrome et a la timeline.
Recommandation : viewport map >= 220 px sur le plus petit cote, meta/legende hors surface map, timeline preservee.
```

Pass B — Visual Primitive Density :

```text
Le fit proportionnel etait sain. Le probleme venait des insets fixes, de la grille trop presente et de primitives trop fines.
Recommandation : inset adaptatif, grille sous seuil, chemins/ancres renforces.
```

Pass C — Renderer / Design System :

```text
Garder le mini CustomPainter editor-only ; ne pas reutiliser MapCanvas/runtime.
Toutes les couleurs doivent venir de tokens/design-system.
```

Pass D — Tests / Anti-scope :

```text
Ajouter une key sur le vrai viewport fit map, tester taille/ratio/legende, transports disabled et Visual Gate.
Scanner runtime, actors, playback, fake map, hardcoded colors et image IA.
```

Pass E — Product :

```text
Divergence : recommandait Actor Display selon l'ancienne roadmap.
Arbitrage : demande Karim + prompt V1-86 priment ; Actor Display devient V1-87.
```

## 4. Code généré — Builder sizing

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`.

```dart
final timelineHeight = _builderTimelineHeight(
  constraints.maxHeight,
  hasBackdrop: widget.backdropPreviewModel != null,
);
final previewHeight = math.max(
  0.0,
  constraints.maxHeight - _builderTimelineGap - timelineHeight,
);
```

```dart
const _builderTimelineGap = 12.0;
const _builderPreviewMinHeight = 220.0;
const _builderPreviewMaxHeight = 420.0;
const _builderTimelineMinHeight = 500.0;
const _builderTimelineMaxHeight = 680.0;
const _builderTimelinePreferredShare = 0.62;
const _builderBackdropPreviewMinHeight = 400.0;
const _builderBackdropPreviewMaxHeight = 450.0;
const _builderBackdropTimelineMinHeight = 420.0;
const _builderBackdropTimelineMaxHeight = 620.0;
const _builderBackdropTimelinePreferredShare = 0.52;

double _builderTimelineHeight(
  double availableHeight, {
  required bool hasBackdrop,
}) {
  if (availableHeight <= 0) {
    return 0;
  }
  final previewMinHeight =
      hasBackdrop ? _builderBackdropPreviewMinHeight : _builderPreviewMinHeight;
  final previewMaxHeight =
      hasBackdrop ? _builderBackdropPreviewMaxHeight : _builderPreviewMaxHeight;
  final timelineMinHeight = hasBackdrop
      ? _builderBackdropTimelineMinHeight
      : _builderTimelineMinHeight;
  final timelineMaxHeight = hasBackdrop
      ? _builderBackdropTimelineMaxHeight
      : _builderTimelineMaxHeight;
  final timelinePreferredShare = hasBackdrop
      ? _builderBackdropTimelinePreferredShare
      : _builderTimelinePreferredShare;
  final maxTimeline = math.min(
    timelineMaxHeight,
    math.max(
      0.0,
      availableHeight - _builderTimelineGap - previewMinHeight,
    ),
  );
  final minTimeline = math.min(timelineMinHeight, maxTimeline);
  final preferredHeight = math.max(
    availableHeight * timelinePreferredShare,
    availableHeight - _builderTimelineGap - previewMaxHeight,
  );
  return preferredHeight.clamp(minTimeline, maxTimeline).toDouble();
}
```

## 5. Code généré — Panel layout

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`.

```dart
class _BackdropVisualPrimitiveMap extends StatelessWidget {
  const _BackdropVisualPrimitiveMap({
    required this.model,
    required this.primitives,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final mapTone = PokeMapTone.map.resolve(context);
    final terrainTone = PokeMapTone.success.resolve(context);
    final pathTone = PokeMapTone.warning.resolve(context);
    final surfaceTone = PokeMapTone.info.resolve(context);
    final objectTone = PokeMapTone.cinematic.resolve(context);
    final environmentTone = PokeMapTone.narrative.resolve(context);
    final palette = CinematicMapBackdropPrimitivePalette(
      background: colors.controlSurface,
      border: colors.controlBorder,
      grid: colors.borderSubtle,
      tile: mapTone.icon,
      terrain: terrainTone.icon,
      path: pathTone.icon,
      surface: surfaceTone.icon,
      object: objectTone.icon,
      environment: environmentTone.icon,
      summary: colors.textMuted,
    );
    final layerCounts = _primitiveLayerCounts(primitives);
    final mapWidth = model.mapWidth ?? _maxPrimitiveX(primitives);
    final mapHeight = model.mapHeight ?? _maxPrimitiveY(primitives);
    if (!compact) {
      return Row(
        key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _BackdropPrimitiveCanvas(
              mapWidth: mapWidth,
              mapHeight: mapHeight,
              primitives: primitives,
              palette: palette,
              compact: compact,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 330,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackdropMetaBar(
                  model: model,
                  primitiveCount: primitives.length,
                  compact: compact,
                ),
                const Spacer(),
                _BackdropPrimitiveLegend(
                  entries: layerCounts,
                  compact: compact,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropMetaBar(
          model: model,
          primitiveCount: primitives.length,
          compact: compact,
        ),
        SizedBox(height: compact ? 6 : 8),
        Expanded(
          child: _BackdropPrimitiveCanvas(
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            primitives: primitives,
            palette: palette,
            compact: compact,
          ),
        ),
        SizedBox(height: compact ? 5 : 7),
        _BackdropPrimitiveLegend(entries: layerCounts, compact: compact),
      ],
    );
  }
}
```

## 6. Code généré — Viewport mesurable

```dart
class _BackdropPrimitiveCanvas extends StatelessWidget {
  const _BackdropPrimitiveCanvas({
    required this.mapWidth,
    required this.mapHeight,
    required this.primitives,
    required this.palette,
    required this.compact,
  });

  final int mapWidth;
  final int mapHeight;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final CinematicMapBackdropPrimitivePalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.controlBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              constraints.maxWidth / mapWidth,
              constraints.maxHeight / mapHeight,
            );
            final viewportWidth = mapWidth * scale;
            final viewportHeight = mapHeight * scale;
            return Center(
              child: SizedBox(
                key: const ValueKey(
                  'cinematic-builder-map-backdrop-visual-viewport',
                ),
                width: viewportWidth,
                height: viewportHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(
                    painter: CinematicMapBackdropVisualPrimitivesPainter(
                      mapWidth: mapWidth,
                      mapHeight: mapHeight,
                      primitives: primitives,
                      palette: palette,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## 7. Code généré — Meta pills et légende

```dart
class _BackdropMetaPill extends StatelessWidget {
  const _BackdropMetaPill({
    required this.label,
    this.tone,
  });

  final String label;
  final PokeMapTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final resolvedTone = tone?.resolve(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedTone?.soft ?? colors.surfaceBase,
        border: Border.all(
          color: resolvedTone?.border ?? colors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: resolvedTone?.text ?? colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}
```

```dart
class _BackdropPrimitiveLegend extends StatelessWidget {
  const _BackdropPrimitiveLegend({
    required this.entries,
    required this.compact,
  });

  final List<(String, int, CinematicMapBackdropLayerKind)> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Wrap(
      key: const ValueKey('cinematic-builder-map-backdrop-legend'),
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final entry in entries.take(compact ? 3 : 5))
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceBase.withValues(alpha: 0.78),
              border: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                '${entry.$1} · ${entry.$2} · ${_layerKindLabel(entry.$3)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
```

## 8. Code généré — Painter

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart`.

```dart
void _paintGrid(Canvas canvas, Rect frame) {
  final cellWidth = frame.width / mapWidth;
  final cellHeight = frame.height / mapHeight;
  final cellSize = math.min(cellWidth, cellHeight);
  final grid = Paint()
    ..color = palette.grid
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6;
  final majorGrid = Paint()
    ..color = palette.border.withValues(alpha: 0.38)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  if (cellSize >= 7) {
    for (var x = 1; x < mapWidth; x++) {
      final dx = frame.left + x * cellWidth;
      canvas.drawLine(
        Offset(dx, frame.top),
        Offset(dx, frame.bottom),
        x % 5 == 0 ? majorGrid : grid,
      );
    }
    for (var y = 1; y < mapHeight; y++) {
      final dy = frame.top + y * cellHeight;
      canvas.drawLine(
        Offset(frame.left, dy),
        Offset(frame.right, dy),
        y % 5 == 0 ? majorGrid : grid,
      );
    }
  }
}
```

```dart
void _paintPrimitive(
  Canvas canvas,
  Rect frame,
  CinematicMapBackdropVisualPrimitive primitive,
) {
  final rect = _primitiveRect(frame, primitive);
  final opacity = primitive.opacity.clamp(0.16, 1.0).toDouble();
  final baseColor = _colorFor(primitive.kind);
  final fillPaint = Paint()
    ..color = baseColor.withValues(alpha: _fillAlpha(primitive.kind) * opacity)
    ..style = PaintingStyle.fill;
  final strokePaint = Paint()
    ..color = baseColor.withValues(alpha: _strokeAlpha(primitive.kind) * opacity)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.min(2.2, math.max(0.8, rect.shortestSide * 0.08));

  switch (primitive.kind) {
    case CinematicMapBackdropVisualPrimitiveKind.objectAnchor:
    case CinematicMapBackdropVisualPrimitiveKind.environmentAnchor:
      final halo = rect.deflate(math.min(rect.width, rect.height) * 0.08);
      final core = rect.deflate(math.min(rect.width, rect.height) * 0.28);
      canvas
        ..drawOval(
          halo,
          Paint()
            ..color = baseColor.withValues(alpha: 0.2 * opacity)
            ..style = PaintingStyle.fill,
        )
        ..drawOval(core, fillPaint)
        ..drawOval(core, strokePaint);
    case CinematicMapBackdropVisualPrimitiveKind.layerSummary:
    case CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer:
      final summaryPaint = Paint()
        ..color = _colorFor(primitive.kind).withValues(alpha: 0.16 * opacity)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, summaryPaint);
      final outlinePaint = Paint()
        ..color = _colorFor(primitive.kind).withValues(alpha: 0.5 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(rect.deflate(1), outlinePaint);
    case CinematicMapBackdropVisualPrimitiveKind.terrainCell:
    case CinematicMapBackdropVisualPrimitiveKind.surfaceCell:
      final inset = _cellInset(rect);
      final cellRect = rect.deflate(inset);
      canvas
        ..drawRect(cellRect, fillPaint)
        ..drawRect(cellRect, strokePaint);
    case CinematicMapBackdropVisualPrimitiveKind.tileCell:
      canvas.drawRect(rect.deflate(_cellInset(rect)), fillPaint);
    case CinematicMapBackdropVisualPrimitiveKind.pathCell:
      final inset = _cellInset(rect);
      final ribbonRect = rect.deflate(inset).deflate(rect.shortestSide * 0.14);
      final radius = Radius.circular(math.max(1, ribbonRect.shortestSide * 0.2));
      canvas
        ..drawRRect(RRect.fromRectAndRadius(ribbonRect, radius), fillPaint)
        ..drawRRect(RRect.fromRectAndRadius(ribbonRect, radius), strokePaint);
  }
}
```

## 9. Code généré — Tests

```dart
final mapViewportSize = tester.getSize(
  find.byKey(
    const ValueKey('cinematic-builder-map-backdrop-visual-viewport'),
  ),
);
final legendSize = tester.getSize(
  find.byKey(const ValueKey('cinematic-builder-map-backdrop-legend')),
);
expect(mapViewportSize.shortestSide, greaterThanOrEqualTo(220));
expect(mapViewportSize.aspectRatio, closeTo(12 / 10, 0.08));
expect(legendSize.height, lessThan(mapViewportSize.height * 0.35));
expect(find.text('Aperçu spatial structurel'), findsOneWidget);
expect(find.text('6 primitive(s) spatiale(s)'), findsOneWidget);
expect(find.text('Ground · 4 · tile'), findsOneWidget);
expect(find.text('Main path · 2 · path'), findsOneWidget);
expect(find.text('Collision'), findsNothing);
expect(find.text('Couche collision'), findsNothing);
expect(find.text('Professor Oak'), findsNothing);
```

```dart
final screenshotFile = File(
  '../../reports/narrativeStudio/scenes/screenshots/'
  'ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png',
);
screenshotFile.parent.createSync(recursive: true);
await expectLater(
  find.byKey(const ValueKey('cinematic-builder-workspace')),
  matchesGoldenFile(screenshotFile.absolute.path),
);
```

## 10. RED / GREEN

RED initial :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
Exit 1
Found 0 widgets with key [<'cinematic-builder-map-backdrop-visual-viewport'>].
```

RED intermédiaire :

```text
Même test
Exit 1
viewport shortest side trop petit : 14.0, puis 158.0 pendant l'itération.
```

GREEN ciblé :

```text
dart format test/cinematic_builder_workspace_test.dart
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
+1 All tests passed!
```

Mesure debug temporaire retirée avant final :

```text
preview=Size(672.0, 420.0)
panel=Size(646.0, 394.0)
meta=Size(330.0, 103.0)
viewport=Size(272.0, 226.7)
legend=Size(330.0, 40.0)
```

## 11. Commandes finales

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_86_CAPTURE_CINEMATIC_MAP_BACKDROP_VISUAL_COMPOSITION=true --reporter=compact test/cinematic_builder_workspace_test.dart
+151 All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
+19 All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
+151 All tests passed!
```

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
+15 All tests passed!
```

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
No issues found! (ran in 1.3s)
```

## 12. Vérifications larges

```text
cd packages/map_editor && flutter test --reporter=compact
+2191 -18 Some tests failed.
```

Exemples visibles hors V1-86 :

```text
Golden "../../../reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png":
Pixel test failed, 0.61%, 7671px diff detected.
```

```text
pokemon_sdk_move_catalog_converter_test.dart
Compile/analyze failures around PokemonMoveStatus / PokemonMoveAimedTarget.
```

```text
cd packages/map_editor && flutter analyze
344 issues found. (ran in 2.7s)
```

Premières erreurs globales :

```text
undefined_named_parameter dbSymbol
undefined_named_parameter battleEngineAimedTarget
undefined_named_parameter battleEngineMethod
undefined_named_parameter effectChance
undefined_named_parameter studioFlags
undefined_named_parameter battleStageMods
undefined_named_parameter moveStatuses
undefined_named_parameter psdkStudioMoveId
undefined_class PokemonMoveAimedTarget
undefined_class PokemonMoveFlags
undefined_method fetchPokemonSdkStudioProjectPayload
```

Conclusion : dette globale hors lot, non modifiée par V1-86.

## 13. Screenshot

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png
-rw-r--r--  1 karim  staff   246K Jun  6 16:00 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png
```

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.png
0656ae62d62379dc9e8d9db154e3290c25d66f9dc6cd6b2e71c4547ac5e7661d
```

Inspection visuelle : effectuée via `view_image`.

## 14. Anti-scope

Diff package/runtime :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<aucune sortie>
```

Scan diff ajouté :

```text
git diff -U0 -- <fichiers V1-86> | rg -n "^[+].*(Color\\(0x|Colors\\.|package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime|startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|PlayerComponent|OverworldActorComponent|CharacterSprite|ActorSprite|renderActor|drawActor|actorRenderer|sprite actor|gpt-image-2|image_generation|generate image|AI image|image model|fakeMap|fakeTile|mockTile|hardcoded.*map|Selbrume|bourg_selbrume|port_brisants|lysa|mael|maël)"
<aucune sortie>
```

Scans source complets sur fichiers modifiés :

```text
seek/scrub : hits uniquement dans des assertions anti-scope existantes.
CharacterAnimation : hits dans fixtures/tests existants et helper actor appearance existant.
stageContext.mapId : hits dans tests qui vérifient l'absence de ce champ.
Color(0x)/Colors : hits préexistants dans cinematic_builder_workspace.dart ; le diff V1-86 n'en ajoute aucun.
```

## 15. Roadmaps

Modifiées :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Changements :

```text
V1-86 ajouté en DONE.
Actor Display repoussé en V1-87.
Demande Karim documentée.
```

## 16. Git

Git write interdit et respecté : aucun `git add`, `git commit`, `git reset`, `git checkout`, `git stash`, `git push`.

Statut final attendu après ce lot : fichiers modifiés + nouveaux rapports/screenshot, non stagés.
