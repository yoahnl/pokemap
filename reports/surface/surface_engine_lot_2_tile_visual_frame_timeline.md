# Surface Engine - Lot 2 - Tile Visual Frame Timeline V1

Date: 2026-04-26

## 1. Resume executif

Le Lot 2 ajoute une primitive pure dans `map_core` pour resoudre une `TilesetVisualFrame` a partir:

- d'une liste de frames;
- d'un temps ecoule en millisecondes;
- d'un mode de lecture;
- d'un multiplicateur de vitesse.

La nouvelle API est volontairement petite:

- `TileVisualFrameTimelinePlaybackMode`;
- `TileVisualFrameTimelineResolution`;
- `resolveTileVisualFrameTimeline`.

Elle vit dans:

- `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart`

Elle est exportee par:

- `packages/map_core/lib/map_core.dart`

Ce lot ne branche pas cette primitive au runtime, a l'editeur, au gameplay, aux paths legacy, ni a `RuntimePathAutotileSet`. Il prepare seulement une brique pure et testee pour les prochains lots Surface Engine.

La semantique temporelle ne reinvente pas les animations existantes. La primitive reutilise:

- `normalizeElementFrameDurationsMs`;
- `resolvePlacedElementAnimationFrameIndex`;
- `resolvePlacedElementAnimationOneShotFrame`;
- `defaultPlacedElementAnimationFrameDurationMs`.

Ainsi, les timelines de tiles conservent la politique actuelle:

- duree positive conservee;
- duree `null`, nulle ou negative normalisee a `200 ms`;
- `speed <= 0` traite comme `1.0`;
- loop forward avec modulo;
- one-shot qui se bloque sur la derniere frame et signale `completed`.

## 2. Fichiers consultes

### Instructions et rapports precedents

- `AGENTS.md`
- `reports/analysis/surface_engine_initial_audit.md`
- `reports/analysis/surface_engine_lot_1_autotile_characterization.md`

### Production map_core

- `packages/map_core/lib/src/operations/map_placed_element_animation.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/validation/validators.dart`

### Tests map_core

- `packages/map_core/test/placed_element_animation_test.dart`
- `packages/map_core/test/placed_element_animation_one_shot_test.dart`
- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`

### Runtime consulte en lecture seulement

- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`
- `packages/map_runtime/test/runtime_path_autotile_animation_test.dart`
- `packages/map_runtime/test/runtime_path_animation_trigger_playback_test.dart`
- `packages/map_runtime/test/placed_element_animation_runtime_test.dart`

## 3. Fichiers crees

- `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart`
- `packages/map_core/test/tile_visual_frame_timeline_test.dart`
- `reports/analysis/surface_engine_lot_2_tile_visual_frame_timeline.md`

## 4. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

Modification unique dans ce fichier:

```dart
export 'src/operations/tile_visual_frame_timeline.dart';
```

Aucun autre fichier de production existant n'a ete modifie.

## 5. API ajoutee

### `TileVisualFrameTimelinePlaybackMode`

```dart
enum TileVisualFrameTimelinePlaybackMode {
  staticFrame,
  loop,
  oneShot,
}
```

Semantique:

- `staticFrame`: retourne toujours la premiere frame si elle existe.
- `loop`: lit les frames en boucle forward.
- `oneShot`: lit les frames une seule fois, puis reste sur la derniere frame.

La primitive V1 n'ajoute pas `pingPong`, `randomStart`, `startOffsetMs` ou trigger state. Ces concepts existent deja pour les elements places, mais ils ne sont pas necessaires pour ce lot.

### `TileVisualFrameTimelineResolution`

```dart
class TileVisualFrameTimelineResolution {
  const TileVisualFrameTimelineResolution({
    required this.frame,
    required this.frameIndex,
    required this.completed,
  });

  final TilesetVisualFrame? frame;
  final int frameIndex;
  final bool completed;
}
```

Semantique:

- `frame`: la frame selectionnee, ou `null` si la liste est vide.
- `frameIndex`: l'index dans la liste d'origine, ou `0` si la liste est vide.
- `completed`: indique si la timeline est terminee.

Choix documente pour `completed`:

- liste vide: `true`;
- `staticFrame`: `true`, meme avec plusieurs frames, car ce mode ne joue pas une animation;
- `loop`: `false` si au moins une frame existe, car une boucle ne se termine pas;
- `oneShot`: suit `resolvePlacedElementAnimationOneShotFrame`.

### `resolveTileVisualFrameTimeline`

Signature:

```dart
TileVisualFrameTimelineResolution resolveTileVisualFrameTimeline({
  required List<TilesetVisualFrame> frames,
  required double elapsedMs,
  required TileVisualFrameTimelinePlaybackMode mode,
  double speed = 1.0,
})
```

Proprietes importantes:

- API pure;
- pas de Flutter;
- pas de Flame;
- pas d'IO;
- ne mute pas la liste recue;
- retourne l'objet `TilesetVisualFrame` exact de la liste d'entree;
- preserve `tilesetId`, `source` et `durationMs`;
- reutilise la normalisation de durees actuelle;
- reutilise les resolvers d'animation existants.

## 6. Cas testes

Le nouveau fichier `tile_visual_frame_timeline_test.dart` contient 16 tests.

### Liste vide

1. `staticFrame` avec liste vide:
   - `frame == null`;
   - `frameIndex == 0`;
   - `completed == true`.
2. `loop` avec liste vide:
   - `frame == null`;
   - `frameIndex == 0`;
   - `completed == true`.
3. `oneShot` avec liste vide:
   - `frame == null`;
   - `frameIndex == 0`;
   - `completed == true`.

### Une seule frame

4. `staticFrame` retourne la frame unique, index `0`, `completed == true`.
5. `loop` retourne la frame unique, index `0`, `completed == false`.
6. `oneShot` retourne la frame unique, index `0`, `completed == true`.

### Static avec plusieurs frames

7. `staticFrame` retourne toujours la premiere frame:
   - ignore `elapsedMs`;
   - ignore `speed`;
   - `completed == true`.

### Loop avec deux frames de meme duree

8. Deux frames de `100 ms`:
   - `elapsedMs: 0 -> frame 0`;
   - `elapsedMs: 99 -> frame 0`;
   - `elapsedMs: 100 -> frame 1`;
   - `elapsedMs: 199 -> frame 1`;
   - `elapsedMs: 200 -> frame 0`.

### Loop avec durees differentes

9. Frames de `50 ms`, `150 ms`, `300 ms`:
   - `0 -> frame 0`;
   - `49 -> frame 0`;
   - `50 -> frame 1`;
   - `199 -> frame 1`;
   - `200 -> frame 2`;
   - `499 -> frame 2`;
   - `500 -> frame 0`.

### One-shot

10. Trois frames de `100 ms`:
   - debut `0 ms -> frame 0, completed false`;
   - milieu `150 ms -> frame 1, completed false`;
   - derniere frame `299 ms -> frame 2, completed false`;
   - fin exacte `300 ms -> frame 2, completed true`;
   - apres fin `999 ms -> frame 2, completed true`.

### Durees invalides

11. Durees `0`, `-10`, `null`:
   - normalisees a `defaultPlacedElementAnimationFrameDurationMs`;
   - la constante actuelle est verifiee a `200`;
   - les frontieres `199`, `200`, `399`, `400`, `599`, `600` prouvent la normalisation.

### Speed

12. `speed <= 0`:
   - compare le loop avec `resolvePlacedElementAnimationFrameIndex`;
   - compare le one-shot avec `resolvePlacedElementAnimationOneShotFrame`;
   - documente que la logique existante ramene le speed a `1.0`.

### Preservation de la frame

13. Une frame avec:
   - `tilesetId: water_fx_tileset`;
   - `source: TilesetSourceRect(x: 7, y: 9, width: 2, height: 3)`;
   - `durationMs: 120`;

   est retournee comme le meme objet et conserve toutes ses donnees.

### Liste non mutee

14. La fonction ne modifie pas la liste `frames` recue.

### Coherence avec les helpers existants

15. Le loop retourne les memes index que `resolvePlacedElementAnimationFrameIndex`.
16. Le one-shot retourne les memes index et le meme `completed` que `resolvePlacedElementAnimationOneShotFrame`.

## 7. Ce que cette primitive prepare pour Surface Engine

Cette primitive isole une responsabilite precise: resoudre la frame temporelle a afficher.

Elle prepare:

- les paths legacy animes;
- les terrains animes;
- les futures surfaces eau/lave/glace;
- les hautes herbes avec animation locale one-shot;
- les previews editeur de surfaces;
- les atlas animes type colonnes de variantes / lignes de frames.

La Surface Engine aura besoin d'autres briques:

- resolver d'autotile;
- mapping de roles;
- layout atlas;
- contrat gameplay;
- rendu runtime;
- caches et culling.

Mais aucune de ces responsabilites n'appartient a ce lot. La timeline V1 reste volontairement une primitive pure de temps -> frame.

## 8. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas:

- cree de modele `Surface`;
- cree de `SurfaceEngine`;
- modifie `ProjectManifest`;
- modifie des modeles Freezed/JSON;
- lance `build_runner`;
- modifie `map_runtime`;
- modifie `map_editor`;
- modifie `map_gameplay`;
- modifie `MapLayersComponent`;
- modifie `RuntimePathAutotileSet`;
- modifie `map_terrain_autotile.dart`;
- branche la nouvelle primitive aux paths existants;
- change le comportement runtime existant;
- ajoute `pingPong`, `randomStart` ou `startOffsetMs`;
- corrige la dette existante du test complet `map_core`.

## 9. Commandes lancees

### TDD rouge

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
```

Resultat attendu avant implementation:

```text
Failed to load "test/tile_visual_frame_timeline_test.dart"
Error: Type 'TileVisualFrameTimelineResolution' not found.
Error: Type 'TileVisualFrameTimelinePlaybackMode' not found.
Error: Method not found: 'resolveTileVisualFrameTimeline'.
Some tests failed.
```

Ce rouge prouve que le nouveau test cible bien l'API absente.

### Format

Commande:

```bash
/opt/homebrew/bin/dart format \
  packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart \
  packages/map_core/lib/map_core.dart \
  packages/map_core/test/tile_visual_frame_timeline_test.dart
```

Resultat:

```text
Formatted packages/map_core/test/tile_visual_frame_timeline_test.dart
Formatted 3 files (1 changed) in 0.01 seconds.
```

### Test cible Lot 2

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
```

Resultat:

```text
+16: All tests passed!
```

### Test cible Lot 1

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
```

Resultat:

```text
+21: All tests passed!
```

### Analyse cible

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/tile_visual_frame_timeline.dart \
  test/tile_visual_frame_timeline_test.dart
```

Resultat:

```text
Analyzing tile_visual_frame_timeline.dart, tile_visual_frame_timeline_test.dart...
No issues found!
```

### Test complet map_core

Commande:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Resultat:

```text
+167 -1: Some tests failed.
```

Echec:

```text
test/legacy_editor_json_compat_collision_test.dart:
legacy collision profile compat unknown legacy keys do not prevent manifest parsing [E]
type 'List<int>' is not a subtype of type 'Map<String, dynamic>' in type cast
package:map_core/src/models/element_collision_profile.g.dart 46:33
```

Cet echec est la dette existante deja documentee au Lot 1. Il n'est pas lie a la nouvelle primitive de timeline.

## 10. Resultats des tests

Resultats verifies:

- `test/tile_visual_frame_timeline_test.dart`: passe avec `+16`.
- `test/map_terrain_autotile_characterization_test.dart`: passe avec `+21`.
- analyse cible des nouveaux fichiers: `No issues found!`.
- test complet `map_core`: echoue avec `+167 -1`.

Le test complet echoue sur la dette connue:

```text
test/legacy_editor_json_compat_collision_test.dart
type 'List<int>' is not a subtype of type 'Map<String, dynamic>' in type cast
```

Cette dette n'est pas corrigee dans ce lot.

## 11. Points de vigilance

### `completed` est une semantique nouvelle pour le mode static et loop

Les helpers existants exposent `completed` seulement pour le one-shot. La nouvelle API doit donc choisir une valeur pour les autres modes.

Choix V1:

- static: `completed == true`;
- loop non vide: `completed == false`;
- vide: `completed == true`.

Ce choix est documente dans le code, les tests et ce rapport.

### Les durees invalides sont acceptees par la primitive

Le validator projet rejette les `durationMs <= 0` quand elles sont presentes. Pourtant, les resolvers runtime actuels normalisent deja les valeurs invalides par securite. La nouvelle primitive conserve cette tolerance pour rester compatible avec la semantique existante.

### `speed <= 0` reste tolerant

Le validator des animations placees rejette les speeds non positifs dans certaines donnees validees. Mais les helpers de resolution traitent `speed <= 0` comme `1.0`. La timeline V1 conserve ce comportement.

### Pas de branchement runtime dans ce lot

`RuntimePathAutotileSet` pourrait utiliser cette primitive plus tard, mais ce lot ne le modifie pas pour eviter tout changement comportemental.

### Pas de ping-pong en V1

`MapPlacedElementAnimationMode` sait faire `pingPong`, mais le prompt demande seulement static, loop et one-shot. L'ajouter maintenant serait une extension hors scope.

## 12. Autocritique finale

Le lot est volontairement minimal et respecte le perimetre. Le plus gros choix de design est la valeur `completed` pour `staticFrame` et `loop`; elle n'existait pas directement dans les helpers actuels. La decision retenue est simple:

- static est immediatement complete;
- loop ne complete jamais quand elle contient une frame;
- one-shot delegue au helper existant.

Limites:

- la primitive ne fournit pas encore de total duration public;
- elle ne donne pas le temps restant;
- elle ne sait pas resoudre un layout atlas colonne/ligne;
- elle ne gere pas de groupe de synchronisation;
- elle ne remplace pas encore les usages runtime/editor existants.

Ces limites sont intentionnelles pour garder le Lot 2 petit, pur et reversible.

## 13. Ce que le prompt semble discutable ou incomplet

### `completed` pour static avec plusieurs frames etait ouvert

Le prompt autorisait `false` ou une valeur documentee. Le choix `true` est coherent avec le fait que static n'est pas une lecture temporelle, mais ce n'etait pas impose.

### La primitive expose une classe simple non-Freezed

Le repo utilise beaucoup Freezed pour les modeles persistants. Ici, une classe Dart simple est preferable car la resolution n'est pas un modele JSON et le prompt interdit les modeles Freezed/JSON et `build_runner`.

### Les durees invalides sont a la fois rejetees et normalisees selon les couches

Le validator rejette les durees invalides dans les manifests valides, mais les helpers de runtime les normalisent. Ce n'est pas contradictoire: la normalisation est une defense runtime, pas une autorisation d'authoring.

### Le test complet map_core a une dette connue

Le prompt anticipe l'echec complet du package sur une dette collision legacy. Le lot ne doit pas la corriger, mais cela veut dire que la verification globale restera partiellement rouge tant que cette dette existe.

## 14. Auto-review independante

### Est-ce que le lot est reste strictement limite a une primitive de timeline?

Oui. La production ajoute uniquement `tile_visual_frame_timeline.dart` et son export.

### Est-ce qu'aucun modele Surface n'a ete cree?

Oui. Aucun type `Surface`, `SurfaceEngine`, ou modele de manifest surface n'a ete ajoute.

### Est-ce qu'aucun fichier runtime/editor/gameplay n'a ete modifie?

Oui. Les fichiers `map_runtime`, `map_editor` et `map_gameplay` ont ete consultes en lecture seulement.

### Est-ce que `RuntimePathAutotileSet` est reste intact?

Oui. `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart` n'a pas ete modifie.

### Est-ce que la nouvelle primitive reutilise ou respecte la semantique existante?

Oui. Elle reutilise les helpers existants de `map_placed_element_animation.dart` pour les durees, le loop, le one-shot et le fallback de speed.

### Est-ce que les cas obligatoires sont couverts?

Oui. Les tests couvrent liste vide, frame unique, static multi-frame, loop equal durations, loop uneven durations, one-shot, durees invalides/null, preservation de frame, non-mutation et coherence avec les helpers existants.

### Est-ce que les commandes Git interdites n'ont pas ete utilisees?

Oui. Aucune commande Git d'ecriture n'a ete utilisee. Les commandes Git utilisees sont des commandes de lecture.

### Est-ce que le rapport est assez detaille?

Oui. Il documente l'audit, l'API, les tests, les choix, les non-objectifs, les commandes, les resultats, les vigilances et l'auto-review.

### Est-ce que quelque chose du prompt etait ambigu ou discutable?

Oui. La valeur `completed` pour `staticFrame` avec plusieurs frames etait volontairement ouverte. Le choix `true` est documente.
