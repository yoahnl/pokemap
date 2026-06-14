# Evidence Pack — NS-SCENES-V1-129

Verdict : **NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0 : DONE**.

## Gate 0

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all: <vide>
git diff --stat: <vide>
git diff --name-only: <vide>
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
af8be4ac update selbrume
d864d502 NS-SCENES-V1-128 — Cinematic Timeline Zoom Controller V0
9e6d5c6e NS-SCENES-V1-127 — Cinematic Emote Playback State Read Model V0
bf27192e NS-SCENES-V1-126 — Cinematic Emote Core Model Asset Catalog V0
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
```

## Règles lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
```

`codex_rules.md` est absent ; `codex_rule.md` est le fichier de règles disponible.

## Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/pubspec.yaml
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Fichiers créés

```text
packages/map_editor/assets/cinematics/emotes/emotions.png
packages/map_editor/assets/cinematics/emotes/emotions2.png
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_129_evidence_pack.md
```

## Preuve assets racine conservés et copies officielles

```bash
ls -lh emotions.png emotions2.png packages/map_editor/assets/cinematics/emotes/emotions.png packages/map_editor/assets/cinematics/emotes/emotions2.png
```

```text
-rw-r--r--@ 1 karim  staff   849B Jun 14 12:59 emotions.png
-rw-r--r--@ 1 karim  staff   1.9K Jun 14 12:59 emotions2.png
-rw-r--r--@ 1 karim  staff   849B Jun 14 12:59 packages/map_editor/assets/cinematics/emotes/emotions.png
-rw-r--r--@ 1 karim  staff   1.9K Jun 14 12:59 packages/map_editor/assets/cinematics/emotes/emotions2.png
```

```bash
file emotions.png emotions2.png packages/map_editor/assets/cinematics/emotes/emotions.png packages/map_editor/assets/cinematics/emotes/emotions2.png
```

```text
emotions.png:                                               PNG image data, 128 x 48, 8-bit colormap, non-interlaced
emotions2.png:                                              PNG image data, 128 x 48, 8-bit colormap, non-interlaced
packages/map_editor/assets/cinematics/emotes/emotions.png:  PNG image data, 128 x 48, 8-bit colormap, non-interlaced
packages/map_editor/assets/cinematics/emotes/emotions2.png: PNG image data, 128 x 48, 8-bit colormap, non-interlaced
```

```bash
shasum -a 256 emotions.png emotions2.png packages/map_editor/assets/cinematics/emotes/emotions.png packages/map_editor/assets/cinematics/emotes/emotions2.png
```

```text
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  emotions2.png
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  packages/map_editor/assets/cinematics/emotes/emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  packages/map_editor/assets/cinematics/emotes/emotions2.png
```

## Pubspec modifié

```diff
 flutter:
   uses-material-design: true
+  assets:
+    - assets/cinematics/emotes/emotions.png
+    - assets/cinematics/emotes/emotions2.png
```

## Code généré — helper créé

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart`

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

class CinematicEmotePreviewOverlay extends StatefulWidget {
  const CinematicEmotePreviewOverlay({
    super.key,
    required this.playbackFrame,
    required this.mapWidth,
    required this.mapHeight,
    required this.compact,
    this.atlasImagesById,
  });

  final CinematicPreviewPlaybackFrame playbackFrame;
  final int mapWidth;
  final int mapHeight;
  final bool compact;
  final Map<String, ui.Image?>? atlasImagesById;

  @override
  State<CinematicEmotePreviewOverlay> createState() =>
      _CinematicEmotePreviewOverlayState();
}

class _CinematicEmotePreviewOverlayState
    extends State<CinematicEmotePreviewOverlay> {
  AssetBundle? _bundle;
  String _atlasSignature = '';
  Future<Map<String, ui.Image?>>? _atlasImagesFuture;

  @override
  Widget build(BuildContext context) {
    if (widget.playbackFrame.activeEmotes.isEmpty ||
        widget.mapWidth <= 0 ||
        widget.mapHeight <= 0) {
      return const SizedBox.shrink();
    }

    final providedImages = widget.atlasImagesById;
    if (providedImages != null) {
      return _CinematicEmotePreviewOverlayStack(
        playbackFrame: widget.playbackFrame,
        mapWidth: widget.mapWidth,
        mapHeight: widget.mapHeight,
        compact: widget.compact,
        atlasImagesById: providedImages,
      );
    }

    final bundle = DefaultAssetBundle.of(context);
    final atlasesById = _activeAtlasesById(widget.playbackFrame.activeEmotes);
    final signature = _atlasSignatureFor(atlasesById.keys);
    if (_bundle != bundle || _atlasSignature != signature) {
      _bundle = bundle;
      _atlasSignature = signature;
      _atlasImagesFuture = _loadAtlasImages(
        bundle: bundle,
        atlasesById: atlasesById,
      );
    }

    return FutureBuilder<Map<String, ui.Image?>>(
      future: _atlasImagesFuture,
      builder: (context, snapshot) {
        return _CinematicEmotePreviewOverlayStack(
          playbackFrame: widget.playbackFrame,
          mapWidth: widget.mapWidth,
          mapHeight: widget.mapHeight,
          compact: widget.compact,
          atlasImagesById: snapshot.data ?? const {},
        );
      },
    );
  }
}

class _CinematicEmotePreviewOverlayStack extends StatelessWidget {
  const _CinematicEmotePreviewOverlayStack({
    required this.playbackFrame,
    required this.mapWidth,
    required this.mapHeight,
    required this.compact,
    required this.atlasImagesById,
  });

  final CinematicPreviewPlaybackFrame playbackFrame;
  final int mapWidth;
  final int mapHeight;
  final bool compact;
  final Map<String, ui.Image?> atlasImagesById;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty) {
            return const SizedBox.shrink();
          }
          final transform = CinematicMapBackdropViewportTransform.fill(
            viewportSize: size,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
          );
          if (!transform.isUsable) {
            return const SizedBox.shrink();
          }

          final emotes = _visibleEmotes(
            playbackFrame: playbackFrame,
            transform: transform,
            compact: compact,
            atlasImagesById: atlasImagesById,
          );
          if (emotes.isEmpty) {
            return const SizedBox.shrink();
          }

          return Stack(
            key: const ValueKey('cinematic-builder-emote-preview-overlay'),
            clipBehavior: Clip.none,
            children: [
              for (final emote in emotes)
                Positioned(
                  left: emote.bounds.left,
                  top: emote.bounds.top,
                  width: emote.bounds.width,
                  height: emote.bounds.height,
                  child: SizedBox(
                    key: ValueKey(
                      'cinematic-builder-emote-preview-step-${emote.state.activeStepId}',
                    ),
                    width: emote.bounds.width,
                    height: emote.bounds.height,
                    child: emote.image == null || emote.entry == null
                        ? _CinematicEmoteFallback(
                            label: emote.state.emoteLabel,
                            size: emote.bounds.width,
                          )
                        : CustomPaint(
                            key: ValueKey(
                              'cinematic-builder-emote-preview-actor-${emote.state.actorId}',
                            ),
                            painter: _CinematicEmoteSpritePainter(
                              image: emote.image!,
                              frame: emote.entry!.frame,
                              fallbackTextColor: colors.textPrimary,
                              fallbackBackgroundColor: colors.surfaceSubtle,
                              fallbackBorderColor: colors.controlBorder,
                            ),
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CinematicEmoteFallback extends StatelessWidget {
  const _CinematicEmoteFallback({
    required this.label,
    required this.size,
  });

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.controlBorder),
        borderRadius: BorderRadius.circular(math.max(4, size * 0.18)),
      ),
      child: Center(
        child: Text(
          '?',
          semanticsLabel: label ?? 'Émotion',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: math.max(11, size * 0.52),
            height: 1,
          ),
        ),
      ),
    );
  }
}

final class _VisibleCinematicEmote {
  const _VisibleCinematicEmote({
    required this.state,
    required this.bounds,
    required this.entry,
    required this.image,
  });

  final CinematicActorEmotePlaybackState state;
  final Rect bounds;
  final CinematicEmoteCatalogEntry? entry;
  final ui.Image? image;
}

List<_VisibleCinematicEmote> _visibleEmotes({
  required CinematicPreviewPlaybackFrame playbackFrame,
  required CinematicMapBackdropViewportTransform transform,
  required bool compact,
  required Map<String, ui.Image?> atlasImagesById,
}) {
  final cellWidth = transform.frame.width / transform.mapWidth;
  final cellHeight = transform.frame.height / transform.mapHeight;
  final emoteSize = math.min(
    compact ? 28.0 : 34.0,
    math.max(22.0, math.min(cellWidth, cellHeight) * 0.92),
  );
  final actorHeadOffset = math.max(
    compact ? 22.0 : 28.0,
    cellHeight * 1.25,
  );
  final verticalGap = compact ? 4.0 : 6.0;
  final result = <_VisibleCinematicEmote>[];

  for (final state in playbackFrame.activeEmotes) {
    final actorId = state.actorId?.trim();
    if (actorId == null || actorId.isEmpty) {
      continue;
    }
    final pose = playbackFrame.actorPoseById(actorId);
    if (pose == null || !pose.hasPosition) {
      continue;
    }

    final entry = state.emoteId == null
        ? null
        : cinematicEmoteCatalogEntryById(state.emoteId);
    final atlas = entry == null ? null : cinematicEmoteAtlasById(entry.atlasId);
    final image = atlas == null ? null : atlasImagesById[atlas.id];
    final anchor = transform.tileToPreview(pose.x!, pose.y!);
    final left = (anchor.dx - emoteSize / 2)
        .clamp(transform.frame.left, transform.frame.right - emoteSize)
        .toDouble();
    final top = (anchor.dy - actorHeadOffset - emoteSize - verticalGap)
        .clamp(transform.frame.top, transform.frame.bottom - emoteSize)
        .toDouble();
    result.add(
      _VisibleCinematicEmote(
        state: state,
        bounds: Rect.fromLTWH(left, top, emoteSize, emoteSize),
        entry: entry,
        image: image,
      ),
    );
  }

  return result;
}

Map<String, CinematicEmoteAtlas> _activeAtlasesById(
  Iterable<CinematicActorEmotePlaybackState> activeEmotes,
) {
  final atlasesById = <String, CinematicEmoteAtlas>{};
  for (final state in activeEmotes) {
    final entry = state.emoteId == null
        ? null
        : cinematicEmoteCatalogEntryById(state.emoteId);
    if (entry == null) {
      continue;
    }
    final atlas = cinematicEmoteAtlasById(entry.atlasId);
    if (atlas != null) {
      atlasesById[atlas.id] = atlas;
    }
  }
  return atlasesById;
}

String _atlasSignatureFor(Iterable<String> atlasIds) {
  final ids = atlasIds.toList(growable: false)..sort();
  return ids.join('|');
}

Future<Map<String, ui.Image?>> _loadAtlasImages({
  required AssetBundle bundle,
  required Map<String, CinematicEmoteAtlas> atlasesById,
}) async {
  final imagesById = <String, ui.Image?>{};
  for (final entry in atlasesById.entries) {
    imagesById[entry.key] = await _loadAtlasImage(bundle, entry.value.assetKey);
  }
  return imagesById;
}

Future<ui.Image?> _loadAtlasImage(AssetBundle bundle, String assetKey) async {
  try {
    final data = await bundle.load(assetKey);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

class _CinematicEmoteSpritePainter extends CustomPainter {
  const _CinematicEmoteSpritePainter({
    required this.image,
    required this.frame,
    required this.fallbackTextColor,
    required this.fallbackBackgroundColor,
    required this.fallbackBorderColor,
  });

  final ui.Image image;
  final CinematicEmoteFrameRect frame;
  final Color fallbackTextColor;
  final Color fallbackBackgroundColor;
  final Color fallbackBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final source = Rect.fromLTWH(
      frame.x.toDouble(),
      frame.y.toDouble(),
      frame.width.toDouble(),
      frame.height.toDouble(),
    );
    if (source.left < 0 ||
        source.top < 0 ||
        source.right > image.width ||
        source.bottom > image.height ||
        size.isEmpty) {
      final rect = Offset.zero & size;
      final radius = Radius.circular(math.max(4, size.shortestSide * 0.18));
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = fallbackBackgroundColor,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.5), radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = fallbackBorderColor,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: fallbackTextColor,
            fontWeight: FontWeight.w900,
            fontSize: math.max(11, size.shortestSide * 0.52),
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, rect.center - painter.size.center(Offset.zero));
      return;
    }

    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _CinematicEmoteSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frame != frame ||
        oldDelegate.fallbackTextColor != fallbackTextColor ||
        oldDelegate.fallbackBackgroundColor != fallbackBackgroundColor ||
        oldDelegate.fallbackBorderColor != fallbackBorderColor;
  }
}
```

## Hunks produits principaux

```diff
+                                  playbackFrame: playbackFrame,
```

```diff
+                                        if (playbackFrame != null)
+                                          CinematicEmotePreviewOverlay(
+                                            playbackFrame: playbackFrame!,
+                                            mapWidth: plan.mapWidth,
+                                            mapHeight: plan.mapHeight,
+                                            compact: compact,
+                                          ),
```

## Tests RED exacts

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
```

```text
test/cinematic_builder_workspace_test.dart:14:8: Error: Error when reading 'lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart': No such file or directory
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart';
       ^
test/cinematic_builder_workspace_test.dart:526:22: Error: Method not found: 'CinematicEmotePreviewOverlay'.
test/cinematic_builder_workspace_test.dart:556:22: Error: Method not found: 'CinematicEmotePreviewOverlay'.
Some tests failed.
```

Deuxième RED utile :

```text
Expected: exactly one matching candidate
Actual: Found 2 widgets with key [<'cinematic-builder-emote-preview-step-step_emote'>]
```

Cause : insertion doublée dans la branche bitmap. Correction : une occurrence par branche renderer.

## Tests GREEN exacts

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-129"
```

```text
00:04 +4: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-128"
```

```text
00:04 +4: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

```text
00:04 +7: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
```

```text
00:03 +5: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
```

```text
00:06 +9: All tests passed!
```

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

```text
00:07 +26: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart
```

```text
00:00 +3: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

```text
00:00 +20: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
```

```text
00:00 +71: All tests passed!
```

```bash
dart test --reporter=compact test/cinematic_diagnostics_test.dart
```

```text
00:00 +55: All tests passed!
```

## Analyse

```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart lib/src/ui/canvas/cinematics/cinematic_emote_preview_overlay.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 6 items...
35 issues found. (ran in 1.7s)
Exit code 0 avec --no-fatal-infos.
```

```bash
dart analyze
```

```text
Analyzing map_core...
No issues found!
```

## Build macOS debug

```bash
flutter build macos --debug
```

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

```bash
flutter test --reporter=compact --update-goldens test/cinematic_builder_workspace_test.dart --name "captures V1-129" --dart-define=NS_SCENES_V1_129_CAPTURE_CINEMATIC_EMOTE_PREVIEW_PLAYBACK_UI=true
```

```text
00:04 +1: All tests passed!
```

Preuves fichier :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

```text
-rw-r--r--  1 karim  staff   233K Jun 14 20:25 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

```bash
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```bash
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

```text
ac71b1d68b1021acdc0225a05844bf43e66985473258ebc647f3ac817acd1ac4  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_129_cinematic_emote_preview_playback_ui_v0.png
```

## Anti-scope

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host selbrume
```

```text
<vide>
```

```bash
git diff --name-only -- emotions.png emotions2.png
```

```text
<vide>
```

```bash
git diff --unified=0 | rg -n "/Users/karim/Project/pokemonProject/emotions|/Users/karim/Project/pokemonProject/emotions2" || true
```

```text
<vide>
```

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_130*' -print
```

```text
<vide>
```

La recherche large `package:flame|GameState|...|V1-130` est non vide uniquement à cause des roadmaps/rapports qui recommandent V1-130 ou rappellent les non-objectifs. Le code produit modifié ne contient pas Flame, runtime, GameState, timer périodique ou chemin absolu racine.

## Roadmaps

```text
road_map_scenes.md: V1-129 DONE, prochain lot exact recommandé V1-130.
road_map_scene_builder_authoring.md: V1-129 DONE, prochain lot exact recommandé V1-130.
```

## Auto-critique

Le prompt demande que l’emote suive l’acteur pendant un actorMove. Le renderer V1-129 suit bien toute pose fournie par `frame.actorPoses`. Le test dédié injecte deux poses pour le prouver. Le scénario authoring actuel reste linéaire ; le chevauchement réel emote + actorMove dépendra du read model s’il évolue vers des pistes parallèles.

## Verdict final

```text
NS-SCENES-V1-129 : DONE.
Visual Gate : créée.
Roadmaps : V1-130 recommandé.
Aucun runtime/gameplay/battle/example/Selbrume modifié.
Assets racine conservés.
Aucun chemin absolu racine dans le code produit.
V1-130 non démarré.
```
