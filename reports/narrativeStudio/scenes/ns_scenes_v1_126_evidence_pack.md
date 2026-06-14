# NS-SCENES-V1-126 — Evidence Pack

## Verdict

```text
NS-SCENES-V1-126 : DONE.
Emote Core Model / Asset Catalog : implémenté.
actorEmote existant : réutilisé.
Catalogue V0 : présent et testé.
actorId / emoteId : stockés/lus.
Diagnostics : présents.
JSON backward-compatible : oui.
UI / renderer : non démarrés.
Runtime / Flame / GameState : non touchés.
map_editor : non modifié.
Assets racine : non déplacés, non copiés.
pubspec : non modifié.
Screenshot / Visual Gate : absents.
V1-127 : recommandé, non démarré.
```

## Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
7806431f NS-SCENES-V1-125 — Cinematic Emote Assets Reaction Bubble Prep Contract V0
c5329014 NS-SCENES-V1-124 — Cinematic Camera Preview Playback UI V0
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7 feat: cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
```

État dirty initial : `git status --short --untracked-files=all` était vide. `selbrume/project.json` n’était pas dirty au Gate 0.

`git diff --stat` initial :

```text
Sortie : <vide>
```

`git diff --name-only` initial :

```text
Sortie : <vide>
```

## Règles lues

Commande :

```bash
ls -lh AGENTS.md agent_rules.md codex_rule.md codex_rules.md skills/README.md skills/using-superpowers/SKILL.md skills/test-driven-development/SKILL.md skills/verification-before-completion/SKILL.md skills/writing-plans/SKILL.md 2>&1
```

Sortie :

```text
ls: codex_rules.md: No such file or directory
-rw-r--r--@ 1 karim  staff    12K Jun  8 23:08 AGENTS.md
-rw-r--r--@ 1 karim  staff   5.2K May  1 04:05 agent_rules.md
-rw-r--r--  1 karim  staff   4.6K Apr 22 16:49 codex_rule.md
-rw-r--r--@ 1 karim  staff   4.4K May 22 19:00 skills/README.md
-rw-r--r--  1 karim  staff   9.6K Apr 28 11:22 skills/test-driven-development/SKILL.md
-rw-r--r--  1 karim  staff   5.3K Apr 28 11:22 skills/using-superpowers/SKILL.md
-rw-r--r--  1 karim  staff   4.1K Apr 28 11:22 skills/verification-before-completion/SKILL.md
-rw-r--r--  1 karim  staff   5.9K Apr 28 11:22 skills/writing-plans/SKILL.md
```

Verdict règles :

- `AGENTS.md` lu.
- `agent_rules.md` lu.
- `codex_rule.md` lu.
- `codex_rules.md` absent.
- Skills demandés lus.
- Conflit documenté : V1-126 interdit les commentaires de code ; `codex_rule.md` demande des commentaires. La règle directe V1-126 a été suivie.

## Fichiers lus

Rapports récents :

- `reports/narrativeStudio/scenes/ns_scenes_v1_125_cinematic_emote_assets_reaction_bubble_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_125_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Rapports acteurs/sprites/stage :

- `reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_92_cinematic_actor_display_preview_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_100_cinematic_spatial_authoring_stage_points_prep_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_101_cinematic_stage_point_core_model_v0.md`

Code et tests :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers créés

- `packages/map_core/lib/src/models/cinematic_emote_catalog.dart`
- `packages/map_core/test/cinematic_emote_catalog_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_126_cinematic_emote_core_model_asset_catalog_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_126_evidence_pack.md`

## Preuves assets

Commande :

```bash
ls -lh /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png && file /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png && shasum -a 256 /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png && sips -g pixelWidth -g pixelHeight /Users/karim/Project/pokemonProject/emotions.png /Users/karim/Project/pokemonProject/emotions2.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   849B Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions.png
-rw-r--r--@ 1 karim  staff   1.9K Jun 14 12:59 /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png:  PNG image data, 128 x 48, 8-bit colormap, non-interlaced
/Users/karim/Project/pokemonProject/emotions2.png: PNG image data, 128 x 48, 8-bit colormap, non-interlaced
09b9627648f16012042610ec159b95167e84559c6b4ae0fef09eb834d283ac9f  /Users/karim/Project/pokemonProject/emotions.png
f337639b596d145b306d3300b5f8144bc9387f329fd9fda743accfccb03643b0  /Users/karim/Project/pokemonProject/emotions2.png
/Users/karim/Project/pokemonProject/emotions.png
  pixelWidth: 128
  pixelHeight: 48
/Users/karim/Project/pokemonProject/emotions2.png
  pixelWidth: 128
  pixelHeight: 48
```

## Contenu complet du catalogue

```dart
import 'package:meta/meta.dart' show immutable;

const cinematicEmoteDefaultReactionsAtlasId = 'defaultReactions';
const cinematicEmoteNeutralBubblesAtlasId = 'neutralBubbles';
const cinematicEmoteDefaultReactionsAssetKey =
    'assets/cinematics/emotes/emotions.png';
const cinematicEmoteNeutralBubblesAssetKey =
    'assets/cinematics/emotes/emotions2.png';
const cinematicDefaultActorEmoteId = 'exclamation';

@immutable
final class CinematicEmoteAtlas {
  const CinematicEmoteAtlas({
    required this.id,
    required this.label,
    required this.assetKey,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
  });

  final String id;
  final String label;
  final String assetKey;
  final int width;
  final int height;
  final int frameWidth;
  final int frameHeight;
}

@immutable
final class CinematicEmoteFrameRect {
  const CinematicEmoteFrameRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  bool fitsInside(CinematicEmoteAtlas atlas) {
    return x >= 0 &&
        y >= 0 &&
        width > 0 &&
        height > 0 &&
        x + width <= atlas.width &&
        y + height <= atlas.height;
  }
}

@immutable
final class CinematicEmoteCatalogEntry {
  const CinematicEmoteCatalogEntry({
    required this.id,
    required this.label,
    required this.description,
    required this.atlasId,
    required this.frame,
  });

  final String id;
  final String label;
  final String description;
  final String atlasId;
  final CinematicEmoteFrameRect frame;
}

const cinematicEmoteAtlases = <CinematicEmoteAtlas>[
  CinematicEmoteAtlas(
    id: cinematicEmoteDefaultReactionsAtlasId,
    label: 'Réactions',
    assetKey: cinematicEmoteDefaultReactionsAssetKey,
    width: 128,
    height: 48,
    frameWidth: 16,
    frameHeight: 16,
  ),
  CinematicEmoteAtlas(
    id: cinematicEmoteNeutralBubblesAtlasId,
    label: 'Bulles neutres',
    assetKey: cinematicEmoteNeutralBubblesAssetKey,
    width: 128,
    height: 48,
    frameWidth: 16,
    frameHeight: 16,
  ),
];

const cinematicEmoteCatalog = <CinematicEmoteCatalogEntry>[
  CinematicEmoteCatalogEntry(
    id: cinematicDefaultActorEmoteId,
    label: 'Surprise',
    description: 'Réaction forte ou découverte soudaine.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'alert',
    label: 'Alerte',
    description: 'Attention immédiate.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 16, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'anger',
    label: 'Colère',
    description: 'Agacement ou colère courte.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'thought',
    label: 'Pensée',
    description: 'Pensée ou réflexion.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 0, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'question',
    label: 'Question',
    description: 'Interrogation courte.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'music',
    label: 'Musique',
    description: 'Chant, joie ou note musicale.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'idea',
    label: 'Idée',
    description: 'Compréhension ou idée soudaine.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 48, y: 16, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'heart',
    label: 'Coeur',
    description: 'Affection ou joie douce.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 32, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'sweat',
    label: 'Gêne',
    description: 'Malaise, peur légère ou embarras.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 64, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'silence',
    label: 'Silence',
    description: 'Hésitation ou silence.',
    atlasId: cinematicEmoteDefaultReactionsAtlasId,
    frame: CinematicEmoteFrameRect(x: 96, y: 32, width: 16, height: 16),
  ),
  CinematicEmoteCatalogEntry(
    id: 'neutral',
    label: 'Bulle neutre',
    description: 'Bulle neutre ou fallback.',
    atlasId: cinematicEmoteNeutralBubblesAtlasId,
    frame: CinematicEmoteFrameRect(x: 0, y: 0, width: 16, height: 16),
  ),
];

CinematicEmoteAtlas? cinematicEmoteAtlasById(String? atlasId) {
  final id = atlasId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final atlas in cinematicEmoteAtlases) {
    if (atlas.id == id) {
      return atlas;
    }
  }
  return null;
}

CinematicEmoteCatalogEntry? cinematicEmoteCatalogEntryById(String? emoteId) {
  final id = emoteId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final entry in cinematicEmoteCatalog) {
    if (entry.id == id) {
      return entry;
    }
  }
  return null;
}

bool isCinematicEmoteIdKnown(String? emoteId) {
  return cinematicEmoteCatalogEntryById(emoteId) != null;
}
```

## Contenu complet du test catalogue

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('V1-126 cinematic emote catalog', () {
    test('exposes stable no-code entries', () {
      expect(cinematicEmoteCatalog, hasLength(greaterThanOrEqualTo(6)));
      expect(
          cinematicEmoteCatalog.map((entry) => entry.id),
          containsAll([
            cinematicDefaultActorEmoteId,
            'question',
            'heart',
            'anger',
            'music',
            'thought',
            'neutral',
          ]));

      final ids = cinematicEmoteCatalog.map((entry) => entry.id).toSet();
      expect(ids, hasLength(cinematicEmoteCatalog.length));
      expect(cinematicEmoteCatalog.every((entry) => entry.label.isNotEmpty),
          isTrue);
      expect(
        cinematicEmoteCatalog.any((entry) => entry.label == 'Surprise'),
        isTrue,
      );
      expect(
        cinematicEmoteCatalog.every(
          (entry) => !entry.id.contains(' ') && !entry.id.contains('é'),
        ),
        isTrue,
      );
    });

    test('keeps frame rects inside candidate atlases', () {
      for (final entry in cinematicEmoteCatalog) {
        final atlas = cinematicEmoteAtlasById(entry.atlasId);
        expect(atlas, isNotNull, reason: entry.id);
        expect(entry.frame.width, 16, reason: entry.id);
        expect(entry.frame.height, 16, reason: entry.id);
        expect(entry.frame.fitsInside(atlas!), isTrue, reason: entry.id);
        expect(atlas.assetKey, isNot(startsWith('/Users/')));
        expect(atlas.assetKey, startsWith('assets/cinematics/emotes/'));
      }
    });

    test('can find entries and fails safely for unknown ids', () {
      final entry = cinematicEmoteCatalogEntryById('question');
      expect(entry, isNotNull);
      expect(entry!.label, 'Question');

      expect(cinematicEmoteCatalogEntryById('missing_emote'), isNull);
      expect(cinematicEmoteCatalogEntryById('  '), isNull);
      expect(isCinematicEmoteIdKnown('heart'), isTrue);
      expect(isCinematicEmoteIdKnown('unknown'), isFalse);
    });
  });
}
```

## Hunks pertinents

Authoring :

```diff
+import '../models/cinematic_emote_catalog.dart';
+final class CinematicTimelineActorEmoteStepResult { ... }
+const cinematicTimelineActorEmoteBlockMetadataValue = 'actorEmote';
+const cinematicTimelineActorEmoteEmoteIdMetadataKey = 'actor.emoteId';
+const cinematicTimelineDefaultActorEmoteDurationMs = 800;
+CinematicTimelineActorEmoteStepResult addCinematicTimelineActorEmoteStep(...)
+CinematicTimelineStepUpdateResult updateCinematicTimelineActorEmoteStep(...)
+bool isCinematicTimelineActorEmoteStep(CinematicTimelineStep step)
+String? cinematicTimelineActorEmoteActorIdOf(CinematicTimelineStep step)
+String? cinematicTimelineActorEmoteEmoteIdOf(CinematicTimelineStep step)
+CinematicTimelineStep _buildActorEmoteStep(...)
+String _actorEmoteLabel(...)
+CinematicEmoteCatalogEntry _requireEmoteEntry(String emoteId)
```

Diagnostics :

```diff
+import '../models/cinematic_emote_catalog.dart';
+cinematicActorEmoteMissingActorRef,
+cinematicActorEmoteUnknownActorRef,
+cinematicActorEmoteMissingEmoteRef,
+cinematicActorEmoteUnknownEmoteRef,
+cinematicActorEmoteInvalidDuration,
+void _diagnoseActorEmoteStep(...)
```

Playback boundary :

```diff
+test('V1-126 actorEmote remains unsupported until emote playback state', () { ... });
```

Export :

```diff
+export 'src/models/cinematic_emote_catalog.dart';
```

## Tests RED exacts

Commande :

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart
```

Signal RED :

```text
Failed to load "test/cinematic_emote_catalog_test.dart":
Error: Undefined name 'cinematicEmoteCatalog'.
Error: Undefined name 'cinematicDefaultActorEmoteId'.
Error: Method not found: 'cinematicEmoteAtlasById'.
Error: Method not found: 'cinematicEmoteCatalogEntryById'.
Error: Method not found: 'isCinematicEmoteIdKnown'.

Failed to load "test/cinematic_authoring_operations_test.dart":
Error: Method not found: 'addCinematicTimelineActorEmoteStep'.
Error: Method not found: 'cinematicTimelineActorEmoteEmoteIdOf'.
Error: Method not found: 'isCinematicTimelineActorEmoteStep'.
Error: Method not found: 'updateCinematicTimelineActorEmoteStep'.
Error: Undefined name 'cinematicTimelineDefaultActorEmoteDurationMs'.
Error: Undefined name 'cinematicTimelineActorEmoteBlockMetadataValue'.
Error: Undefined name 'cinematicTimelineActorEmoteEmoteIdMetadataKey'.

Failed to load "test/cinematic_diagnostics_test.dart":
Member not found: 'cinematicActorEmoteMissingActorRef'
Member not found: 'cinematicActorEmoteMissingEmoteRef'
Member not found: 'cinematicActorEmoteUnknownActorRef'
Member not found: 'cinematicActorEmoteUnknownEmoteRef'
Member not found: 'cinematicActorEmoteInvalidDuration'
```

## Tests GREEN exacts

Commande :

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_preview_playback_plan_test.dart
```

Sortie finale :

```text
00:00 +147: All tests passed!
```

## Sorties exactes des tests map_core ciblés

Commande :

```bash
dart test --reporter=compact test/cinematic_emote_catalog_test.dart
```

Sortie finale :

```text
00:00 +3: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale :

```text
00:00 +18: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
```

Sortie finale :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie finale :

```text
00:00 +27: All tests passed!
```

## Sortie exacte du test complet map_core

Commande :

```bash
dart test --reporter=compact > /tmp/ns_v1_126_map_core_test.log && tr '\r' '\n' < /tmp/ns_v1_126_map_core_test.log | sed '/^$/d' | tail -n 1
```

Sortie :

```text
00:06 +2511: All tests passed!
```

## Sortie exacte de dart analyze

Commande :

```bash
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## Sorties exactes des régressions map_editor ciblées

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Sortie finale :

```text
00:06 +7: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
```

Sortie finale :

```text
00:05 +5: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie finale :

```text
00:07 +26: All tests passed!
```

## Justification de non-build

Build non lancé : aucun fichier `packages/map_editor`, `packages/map_runtime`, `examples`, asset produit ou `pubspec.yaml` n’a été modifié. Les régressions Flutter ciblées confirment que le Builder compile encore avec le modèle core.

## Checks anti-scope

Commande demandée :

```bash
git diff --unified=0 | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\\.Image|rootBundle|decodeImage|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|V1-127" || true
```

Résultat : sortie non vide uniquement à cause des mentions documentaires `V1-127` dans les roadmaps/rapports, exigées par le prompt. Pour lever cette contradiction, le même contrôle a été lancé sur le diff code/scopes produit.

Commande code-scoped :

```bash
git diff --unified=0 -- packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml | rg -n "package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|BuildContext|Widget|ImageProvider|ui\\.Image|rootBundle|decodeImage|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|V1-127" || true
```

Sortie :

```text
Sortie : <vide>
```

Commandes :

```bash
git diff --name-only -- packages/map_editor
git diff --name-only -- assets emotions.png emotions2.png pubspec.yaml packages/map_editor/pubspec.yaml packages/map_runtime/pubspec.yaml
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume emotions.png emotions2.png pubspec.yaml
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_126*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_127*' -print
```

Sortie :

```text
Sortie : <vide>
```

## Passes / sub-agents

Sub-agents externes non lancés : le périmètre était localisé et vérifiable avec passes internes.

Verdicts :

- Pass Audit/Architecture : PASS, `actorEmote` existe comme kind mais sans modèle métier complet.
- Pass TDD : PASS, tests RED observés avant implémentation.
- Pass Implementation : PASS, catalogue + authoring + diagnostics ajoutés dans `map_core`.
- Pass Validation : PASS, tests ciblés, suite complète `map_core`, `dart analyze` et régressions `map_editor` passent.
- Pass Anti-scope : PASS côté code ; contradiction documentaire `V1-127` expliquée.
- Pass Critique finale : PASS avec risques restants documentés.

## Confirmations finales

- Aucun `map_editor` modifié.
- Aucun runtime modifié.
- Aucun gameplay/battle/example modifié.
- Aucun asset déplacé ou copié.
- Aucun asset racine modifié.
- Aucun `pubspec.yaml` modifié.
- Aucun screenshot créé.
- V1-127 recommandé mais non démarré.

## git diff --check / stat / name-only / status final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../authoring/cinematic_authoring_operations.dart  | 208 ++++++++++++++-
 .../lib/src/diagnostics/cinematic_diagnostics.dart | 105 +++++++-
 .../test/cinematic_authoring_operations_test.dart  | 228 ++++++++++++++--
 .../map_core/test/cinematic_diagnostics_test.dart  | 293 +++++++++++++++++----
 .../test/cinematic_preview_playback_plan_test.dart |  46 ++++
 .../scenes/road_map_scene_builder_authoring.md     |  57 ++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  65 +++--
 8 files changed, 875 insertions(+), 128 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les nouveaux fichiers V1-126 apparaissent dans `git status --short --untracked-files=all`.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_core/test/cinematic_preview_playback_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/models/cinematic_emote_catalog.dart
?? packages/map_core/test/cinematic_emote_catalog_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_126_cinematic_emote_core_model_asset_catalog_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_126_evidence_pack.md
```
