# Lot 88 — Surface Editor Animated Preview V0

## Résumé exécutif

Le Lot 88 anime la preview Surface dans l'éditeur sans toucher au runtime.

Le pipeline Lot 87 reste intact, mais le choix de frame passe de `timeline.frames.first` à une frame courante cyclique selon `elapsedMs`. Le canvas réutilise le timer éditeur existant de `MapCanvas` (110 ms, annulé dans `dispose`) au lieu d'introduire une nouvelle horloge.

## Périmètre

Inclus :

- helper editor-only `resolveSurfaceAnimationFrameAtElapsedMs(...)`;
- `elapsedMs` propagé dans `SurfaceTilePreviewResolver`, `paintSurfaceLayerAtlasTilePreview(...)` et `MapGridPainter`;
- déclenchement du repaint editor quand une Surface placée référence une animation multi-frame;
- chargement cache étendu aux tilesets référencés par toutes les frames Surface;
- tests ciblés Surface preview, painter canvas et non-régression Surface Painter / Surface Studio.

Exclus :

- runtime Flame;
- clock runtime;
- renderer runtime Surface;
- changement JSON;
- changement `map_core`;
- refonte Surface Studio.

## Gate 0 — Status initial avant modification

Commande exécutée depuis la racine avant toute modification :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<empty>

git diff --stat
<empty>

git log --oneline -n 10
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
```

Changements préexistants : aucun.

## Audit preview Surface Lot 87

Fichiers audités :

- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

Constat : `resolveSurfaceTilePreviewInstruction(...)` résolvait bien `surfacePresetId -> preset -> role -> animation -> atlas`, mais utilisait toujours `animation.timeline.frames.first`. Le fallback debug était déjà conservé par `paintSurfaceLayerAtlasTilePreview(...)` quand une instruction ou image était absente.

## Audit timelines Surface

Fichiers audités :

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/test/project_surface_animation_test.dart`
- `packages/map_core/test/project_surface_animation_json_codec_test.dart`
- tests Surface Studio contenant `SurfaceAnimationTimeline` / `SurfaceAnimationFrame`

Constat :

- `SurfaceAnimationFrame.durationMs` est strictement positif.
- `SurfaceAnimationTimeline.frames` est non vide et immuable.
- `SurfaceAnimationTimeline.totalDurationMs` est la somme des durées.
- Le modèle ne contient aucune horloge ni frame courante, ce qui confirme que Lot 88 peut rester côté `map_editor`.

## Audit repaint / clock editor

Fichiers audités :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart`

Constat :

- `MapCanvas` avait déjà `_entityEditorAnimTimer`, un `Timer.periodic(const Duration(milliseconds: 110), ...)`.
- Le timer est annulé dans `dispose`.
- `MapGridPainter.shouldRepaint` compare déjà `editorEntityAnimationMs`.
- Les animations entity/terrain/path utilisent déjà ce temps editor.

Décision : réutiliser ce timer editor, et démarrer le tick si une Surface placée référence une animation multi-frame.

## Décision frame resolver

Ajout d'un helper editor-only :

```dart
SurfaceAnimationFrame resolveSurfaceAnimationFrameAtElapsedMs({
  required SurfaceAnimationTimeline timeline,
  required int elapsedMs,
})
```

Règle :

- timeline cyclique;
- `elapsedMs < 0` normalisé à `0`;
- `elapsedMs == 0` conserve la première frame;
- les bornes respectent les durées cumulées;
- pas de persistance de rôle ou de frame calculée.

## Décision clock editor

Aucun nouveau timer autonome n'a été créé.

Le canvas utilise le timer existant :

- tick : 110 ms;
- `setState` incrémente `editorEntityAnimationMs`;
- timer arrêté si aucune animation editor n'est nécessaire;
- timer annulé dans `dispose`.

Le helper `surfaceTilePreviewNeedsAnimation(...)` est volontairement conservateur : si une Surface visible placée référence au moins une animation multi-frame du preset, le canvas tick. Cela évite de figer l'eau pendant que le rôle change selon les voisins.

## Implémentation resolver temporel

Fichier créé :

- `packages/map_editor/lib/src/features/surface_painter/surface_animation_frame_resolver.dart`

Contenu :

```dart
import 'package:map_core/map_core.dart';

/// Resolves the editor preview frame for a Surface animation timeline.
///
/// Surface timelines are authored as cyclic loops. The editor preview only
/// needs a deterministic frame at a given elapsed time; it does not own runtime
/// clocks or persist any calculated animation state.
SurfaceAnimationFrame resolveSurfaceAnimationFrameAtElapsedMs({
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
```

## Implémentation preview animée editor

Modifications principales :

- `resolveSurfaceTilePreviewInstruction(...)` accepte `elapsedMs = 0`.
- La frame est résolue via `resolveSurfaceAnimationFrameAtElapsedMs(...)`.
- `paintSurfaceLayerAtlasTilePreview(...)` accepte et transmet `elapsedMs`.
- `MapGridPainter` transmet `editorEntityAnimationMs`.
- `collectSurfaceTilePreviewTilesetIds(...)` parcourt toutes les frames, pas seulement la première, afin que le cache editor puisse charger les tilesets nécessaires aux frames animées.
- `MapCanvas` utilise `surfaceTilePreviewNeedsAnimation(...)` pour démarrer le timer quand une Surface placée est animée.

## Fallbacks

Fallback inchangé :

- preset absent;
- animation absente;
- atlas absent;
- tileset non chargé;
- image absente;
- sourceRect hors image;
- layer invisible ou opacité nulle.

Dans ces cas, l'overlay debug Lot 86 reste visible. Une surface peinte ne devient donc pas invisible à cause d'une résolution incomplète.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_painter/surface_animation_frame_resolver.dart`
- `packages/map_editor/test/surface_painter/surface_animation_frame_resolver_test.dart`
- `reports/surface/surface_engine_lot_88_surface_editor_animated_preview.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart`
- `packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart`

## Fichiers supprimés

Aucun.

## Tests lancés

```text
cd packages/map_core && dart test test/surface_variant_role_resolver_test.dart
00:00 +7: All tests passed!

cd packages/map_core && dart test test/surface_layer_placements_test.dart
00:00 +14: All tests passed!

cd packages/map_editor && flutter test test/surface_painter/surface_animation_frame_resolver_test.dart
00:01 +4: All tests passed!

cd packages/map_editor && flutter test test/surface_painter/surface_tile_preview_resolver_test.dart
00:00 +10: All tests passed!

cd packages/map_editor && flutter test test/surface_painter/surface_layer_static_preview_test.dart
00:00 +8: All tests passed!

cd packages/map_editor && flutter test test/map_grid_painter_test.dart
00:01 +6: All tests passed!

cd packages/map_editor && flutter test test/surface_painter
00:03 +42: All tests passed!

cd packages/map_editor && flutter test test/map_selection_controller_test.dart
00:01 +5: All tests passed!

cd packages/map_editor && flutter test test/surface_studio
00:15 +392: All tests passed!
```

## Analyse lancée

Analyse ciblée :

```text
cd packages/map_editor && flutter analyze \
  lib/src/features/surface_painter/surface_animation_frame_resolver.dart \
  lib/src/features/surface_painter/surface_tile_preview_resolver.dart \
  lib/src/features/surface_painter/surface_layer_static_preview.dart \
  lib/src/ui/canvas/map_canvas.dart \
  lib/src/ui/canvas/map_canvas/map_grid_painter.dart \
  test/surface_painter/surface_animation_frame_resolver_test.dart \
  test/surface_painter/surface_tile_preview_resolver_test.dart \
  test/surface_painter/surface_layer_static_preview_test.dart \
  test/map_grid_painter_test.dart

Analyzing 9 items...
No issues found! (ran in 1.6s)
```

Analyse globale optionnelle :

```text
cd packages/map_editor && flutter analyze lib test
417 issues found. (ran in 1.8s)
```

Dette globale observée dans des fichiers non modifiés par le lot, notamment :

- `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`
- plusieurs tests Pokedex / trainer / project legacy avec `ProjectManifest.surfaceCatalog` manquant.

Les fichiers Lot 88 sont couverts par l'analyse ciblée clean.

## Résultats

- Preview Surface animée côté éditeur : oui.
- Timeline cyclique respectée : oui.
- `elapsedMs = 0` conserve la frame statique précédente : oui.
- `drawImageRect` reste utilisé quand l'image est disponible : oui.
- Fallback debug conservé : oui.
- Runtime inchangé : oui.

## Evidence Pack

Tests RED observés avant implémentation :

```text
flutter test test/surface_painter/surface_animation_frame_resolver_test.dart
Error when reading 'lib/src/features/surface_painter/surface_animation_frame_resolver.dart': No such file or directory
Method not found: 'resolveSurfaceAnimationFrameAtElapsedMs'.

flutter test test/surface_painter/surface_tile_preview_resolver_test.dart
Error: No named parameter with the name 'elapsedMs'.

flutter test test/map_grid_painter_test.dart --plain-name "paints SurfaceLayer atlas tile from current editor elapsed time"
Expected: a value less than <40>
Actual: <255>
```

Fichiers audités :

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/test/project_surface_animation_test.dart`
- `packages/map_core/test/project_surface_animation_json_codec_test.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/entity_editor_element_visual.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart`
- `packages/map_editor/test/surface_painter/**`
- `packages/map_editor/test/map_grid_painter_test.dart`

Pipeline animation final :

```text
SurfaceLayer placement
-> surfacePresetId
-> ProjectSurfacePreset
-> SurfaceVariantRole résolu
-> animationId
-> ProjectSurfaceAnimation.timeline
-> resolveSurfaceAnimationFrameAtElapsedMs(timeline, elapsedMs)
-> SurfaceAtlasTileRef courant
-> ProjectSurfaceAtlas
-> sourceRect courant
-> drawImageRect(...)
```

Clock/repaint :

```text
MapCanvas._entityEditorAnimTimer
-> tick 110 ms
-> _editorEntityAnimationMs
-> MapGridPainter.editorEntityAnimationMs
-> paintSurfaceLayerAtlasTilePreview(elapsedMs)
-> resolveSurfaceTilePreviewInstruction(elapsedMs)
```

Fallbacks :

```text
resolveSurfaceTilePreviewInstruction(...) == null
ou image/sourceRect invalide
-> _paintSurfaceDebugCell(...)
```

## Git status final

Status final attendu après création du rapport :

```text
 M packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_animation_frame_resolver.dart
?? packages/map_editor/test/surface_painter/surface_animation_frame_resolver_test.dart
?? reports/surface/surface_engine_lot_88_surface_editor_animated_preview.md
```

Diff stat final (`git diff --stat`, hors fichiers non trackés) :

```text
 .../surface_layer_static_preview.dart              |   2 +
 .../surface_tile_preview_resolver.dart             |  74 +++++--
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  13 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |   1 +
 .../map_editor/test/map_grid_painter_test.dart     |  73 +++++++
 .../surface_layer_static_preview_test.dart         |  54 +++++
 .../surface_tile_preview_resolver_test.dart        | 218 ++++++++++++++++++++-
 7 files changed, 422 insertions(+), 13 deletions(-)
```

## Changements préexistants

Aucun changement préexistant au Gate 0.

## Changements du Lot 88

Tous les fichiers du status final appartiennent au Lot 88.

## Périmètre explicitement non touché

- ProjectManifest non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- codecs Surface non modifiés.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- Aucun renderer runtime Surface créé.
- Aucun resolver runtime Surface créé.
- Aucune animation clock runtime créée.
- Aucune migration legacy codée.
- Aucun provider/repository/service Surface créé.
- Aucune refonte Surface Studio.
- `Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

Commande finale :

```text
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Résultat : aucune sortie.

Commande :

```text
git diff --check
```

Résultat : aucune sortie, exit code 0.

## Vérification mojibake

Les fichiers Dart modifiés/créés restent en ASCII. Le rapport contient du français accentué volontairement.

## Auto-review

- Est-ce que la preview Surface éditeur est animée ? Oui.
- Est-ce que seule la preview editor est animée ? Oui.
- Est-ce que le runtime est inchangé ? Oui.
- Est-ce qu'une frame resolver existe ? Oui.
- Est-ce que les durées de frames sont respectées ? Oui.
- Est-ce que la timeline boucle ? Oui.
- Est-ce que `elapsedMs = 0` conserve le comportement statique ? Oui.
- Est-ce que la preview utilise toujours `drawImageRect` ? Oui.
- Est-ce que le fallback debug reste disponible ? Oui.
- Est-ce que l'absence de preset/animation/atlas/image ne crashe pas ? Oui.
- Est-ce que terrain/path/tile rendering ne régresse pas ? Oui, couvert par `map_grid_painter_test`.
- Est-ce que Surface Painter fonctionne toujours ? Oui, `flutter test test/surface_painter` passe.
- Est-ce que Surface Studio fonctionne toujours ? Oui, `flutter test test/surface_studio` passe.
- Est-ce que `map_runtime` est modifié ? Non.
- Est-ce qu'un renderer runtime est créé ? Non.
- Est-ce qu'une animation clock runtime est créée ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les analyses ciblées passent ? Oui.
- Est-ce qu'un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu'un fichier hors périmètre a été modifié ? Non.
- Est-ce qu'un 88-bis est nécessaire ? Non. La preview editor animée est livrée, avec fallback et sans runtime.

## Critique du prompt

- Le prompt demande un clock editor dédié possible, mais le code avait déjà un timer canvas proprement disposé; le réutiliser réduit le risque.
- Le nom existant `editorEntityAnimationMs` reste un peu trop spécifique maintenant qu'il anime aussi les surfaces, mais le renommer aurait agrandi le diff sans gain produit immédiat.
- La détection d'animation est volontairement conservatrice : elle démarre le repaint si un preset placé référence une animation multi-frame, même si le rôle courant n'est pas celui-là. C'est acceptable pour un editor preview V0 et évite les freezes lors de changements de voisinage.
