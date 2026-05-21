# Shadow Lot 21 — Runtime Static Placed Element Shadow Host Integration V0

## 1. Résumé du lot

Shadow-21 branche les ombres statiques placées dans `PlayableMapGame` en préparant des sources runtime depuis les `MapPlacedElement` réels, leurs `ProjectElementEntry.shadow`, leurs `MapPlacedElement.shadowOverride`, puis le `ProjectShadowCatalog` du projet.

La collection statique `groundStatic` est fusionnée avec la collection acteur `actorContact` de Shadow-19 dans le provider background. Le provider externe Shadow-18 reste prioritaire. Le foreground ne reçoit pas de provider Shadow. `MapLayersComponent` reste un simple consommateur de collection et n’a pas été modifié.

Fichiers non suivis préexistants hors lot au démarrage :

```text
reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
reports/collision/collision_system_audit_v0.md
```

Ces fichiers n’ont pas été modifiés, supprimés, déplacés ou formatés par Shadow-21.

## 2. Design retenu

Le design retenu garde la logique Shadow dans `packages/map_runtime/lib/src/shadow/` :

- `runtime_static_placed_element_shadow_sources.dart` prépare des `RuntimeStaticPlacedElementShadowSource` depuis un `RuntimeMapBundle`.
- `runtime_shadow_collection_merge.dart` fusionne des `ShadowRuntimeInstructionCollection` sans tri, culling ou déduplication.
- `PlayableMapGame` collecte seulement le contexte runtime minimal, appelle les helpers Shadow, cache les collections statiques par map et sert un provider scoped par map.

La génération d’instructions reste déléguée au builder Shadow-20 :

```text
buildRuntimeStaticPlacedElementShadowCollectionForBundle(...)
→ buildRuntimeStaticPlacedElementShadowCollection(...)
→ resolveShadowConfig(...)
→ resolver statique Shadow-14
```

`PlayableMapGame` n’appelle pas directement les resolvers bas niveau.

## 3. Fichiers créés

```text
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
reports/shadows/shadow_lot_21_runtime_static_placed_element_shadow_host_integration.md
```

## 4. Fichiers modifiés

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
```

## 5. Fichiers non modifiés explicitement

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
```

## 6. API / flags runtime ajoutés

API helper ajoutée :

```dart
ShadowRuntimeInstructionCollection mergeShadowRuntimeInstructionCollections(
  Iterable<ShadowRuntimeInstructionCollection> collections,
)

List<RuntimeStaticPlacedElementShadowSource>
    buildRuntimeStaticPlacedElementShadowSources({
  required RuntimeMapBundle bundle,
})

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
  required RuntimeMapBundle bundle,
})
```

Flag ajouté à `PlayableMapGame` :

```dart
enableStaticPlacedElementShadows = true
```

Le flag contrôle uniquement la génération interne des ombres statiques. Il ne bloque jamais un `shadowCollectionProvider` externe fourni au constructeur.

## 7. Formule de métriques static placed element retenue

La formule est alignée sur le rendu local de `MapLayersComponent` :

```text
worldLeft = placed.pos.x * bundle.cellWidth
worldTop = placed.pos.y * bundle.cellHeight
visualWidth = firstFrame.source.width * bundle.cellWidth
visualHeight = firstFrame.source.height * bundle.cellHeight
```

Raison : chaque `MapLayersComponent` est positionné par Flame pour sa map. Les coordonnées des ombres passées au renderer doivent donc rester locales au composant background de cette map. Ajouter l’origine monde de la map dans les métriques causerait un double offset sur les maps connectées.

V0 utilise la première frame visuelle de l’élément, comme référence de taille stable. Les animations d’éléments ne changent pas encore les métriques Shadow par frame.

## 8. Préparation des sources statiques

`buildRuntimeStaticPlacedElementShadowSources(...)` :

- indexe les `ProjectElementEntry` par id ;
- filtre les `TileLayer` visibles avec `opacity > 0` ;
- parcourt les `MapPlacedElement` dans l’ordre de la map ;
- ignore les placements dont la layer n’est pas visible ;
- ignore les placements dont l’entrée élément est absente ;
- ignore les éléments sans frame visuelle exploitable ;
- lit `ProjectElementEntry.shadow` et `MapPlacedElement.shadowOverride` ;
- construit les métriques statiques locales ;
- retourne une liste immuable de sources.

La résolution effective des configs et overrides reste dans le builder Shadow-20.

## 9. Fusion static + actor

`mergeShadowRuntimeInstructionCollections(...)` concatène les instructions dans l’ordre des collections reçues.

Dans `PlayableMapGame`, l’ordre choisi est :

```text
static placed element shadows
actor contact shadows
```

La collection finale conserve ensuite les groupes :

```text
groundStatic
actorContact
```

Aucun tri, culling ou déduplication n’est ajouté.

## 10. Scoping par map active / map connectée

Règles appliquées :

```text
background de map active
→ static shadows de la map active + actor shadows

background de map connectée
→ static shadows de cette map uniquement

foreground
→ aucun provider Shadow
```

Les ombres statiques sont stockées par `mapId` dans `PlayableMapGame`. Les ombres acteur restent limitées à `_activeMapId`, afin d’éviter de dessiner plusieurs fois la même collection acteur sur les backgrounds de maps connectées.

## 11. Provider externe prioritaire

Si `shadowCollectionProvider` est fourni au constructeur de `PlayableMapGame` :

- il est transmis tel quel aux backgrounds ;
- aucune collection interne static n’est utilisée ;
- aucune collection interne actor n’est utilisée ;
- les flags internes ne bloquent pas ce provider.

Ce comportement est couvert par test avec `enableActorContactShadows: false` et `enableStaticPlacedElementShadows: false`.

## 12. Pourquoi MapLayersComponent reste inchangé

`MapLayersComponent` sait déjà consommer une `ShadowRuntimeInstructionCollection` depuis Shadow-17. Shadow-21 ne lui ajoute aucune connaissance de :

```text
ProjectShadowCatalog
ProjectElementEntry
MapPlacedElement
resolveShadowConfig
buildRuntimeStaticPlacedElementShadowCollection
acteurs runtime
```

Son rôle reste le rendu de collection déjà prête.

## 13. Pourquoi RuntimeMapGame reste passif

`RuntimeMapGame` ne possède pas le même host gameplay que `PlayableMapGame` pour collecter acteurs, maps connectées et runtime state. Shadow-21 le laisse passif : aucun provider interne n’est installé par défaut et aucun static shadow builder n’est appelé depuis `RuntimeMapGame`.

## 14. Tests ajoutés

Nouveaux tests :

```text
packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Test existant ajusté :

```text
packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
```

Couverture ajoutée :

- merge de collections vides ;
- merge static + actor ;
- ordre préservé ;
- pas de déduplication ;
- opacity 0 conservée ;
- fixture avec `ProjectShadowCatalog` non vide, `ProjectElementEntry.shadow` actif et `MapPlacedElement` réel ;
- pixel visible après rendu background ;
- catalog vide / profil manquant ;
- élément sans config shadow ;
- override disabled ;
- override custom ;
- provider externe prioritaire ;
- flags static/actor indépendants ;
- active map static + actor ;
- connected map static seulement ;
- foreground sans provider ;
- `RuntimeMapGame` passif.

## 15. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
dart format lib/src/shadow/runtime_shadow_collection_merge.dart lib/src/shadow/runtime_static_placed_element_shadow_sources.dart lib/src/presentation/flame/playable_map_game.dart test/shadow/runtime_shadow_collection_merge_test.dart test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
flutter test test/shadow/runtime_shadow_collection_merge_test.dart
flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
flutter test test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
flutter test test/shadow
flutter analyze lib/src/shadow lib/src/presentation/flame/map_layers_component.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/runtime_map_game.dart test/shadow
flutter test
dart test test/shadow
rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
rg -n "resolveShadowConfig|resolveStaticPlacedElementShadow|resolveActorContactShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
rg -n "ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|buildRuntimeStaticPlacedElementShadowCollection" lib/src/presentation/flame lib/src/shadow test/shadow
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart | rg -n "ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|resolveShadowConfig|resolveStaticPlacedElementShadow|buildRuntimeStaticPlacedElementShadowCollection"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/src/shadow | rg -n "resolveShadowConfig|resolveStaticPlacedElementShadow|resolveActorContactShadow"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
git diff --check
git diff --stat
git diff --name-status
```

## 16. Résultats complets des tests ciblés

### `flutter test test/shadow/runtime_shadow_collection_merge_test.dart`

```text
00:00 +0: mergeShadowRuntimeInstructionCollections merges empty collections into an empty collection
00:00 +1: mergeShadowRuntimeInstructionCollections preserves collection order and instruction order without sorting
00:00 +2: mergeShadowRuntimeInstructionCollections does not deduplicate and retains opacity zero instructions
00:00 +3: mergeShadowRuntimeInstructionCollections exposes immutable lists through the collection contract
00:00 +4: All tests passed!
```

### `flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart`

```text
00:00 +0: runtime static placed element shadow host integration PlayableMapGame builds static shadows for configured placed elements
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +1: runtime static placed element shadow host integration static shadow is visible in the background render when configured
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +2: runtime static placed element shadow host integration empty catalog or missing profile creates no static shadow
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +3: runtime static placed element shadow host integration element without shadow config creates no static shadow
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +4: runtime static placed element shadow host integration disabled placed override creates no static shadow
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +5: runtime static placed element shadow host integration custom placed override modifies the static shadow instruction
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +6: runtime static placed element shadow host integration internal static and actor shadows are merged for the active map
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +7: runtime static placed element shadow host integration static and actor flags affect only their internal collections
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +8: runtime static placed element shadow host integration external provider remains priority even when internal flags are off
[runtime] Map loaded: static-shadow-test, spawn at (0, 0)
00:00 +9: runtime static placed element shadow host integration connected map background receives static shadows but no actor shadows
[runtime] Map loaded: active-static-map, spawn at (0, 0)
[connection] loaded map=connected-static-map origin=(4, 0)
00:00 +10: runtime static placed element shadow host integration RuntimeMapGame remains passive for static placed element shadows
00:00 +11: All tests passed!
```

### `flutter test test/shadow/runtime_actor_contact_shadow_host_integration_test.dart`

```text
00:00 +9: All tests passed!
```

### `flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart`

```text
00:00 +20: All tests passed!
```

## 17. Ligne finale exacte des tests globaux

### `flutter test test/shadow`

```text
00:02 +199: All tests passed!
```

### `flutter analyze lib/src/shadow lib/src/presentation/flame/map_layers_component.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/runtime_map_game.dart test/shadow`

```text
No issues found! (ran in 2.2s)
```

### `flutter test`

```text
00:16 +1120: All tests passed!
```

### `dart test test/shadow` dans `packages/map_core`

```text
00:00 +152: All tests passed!
```

## 18. Résultats des scans anti-dérive

### `find .. -name AGENTS.md -print`

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `../pokemonProject/AGENTS.md` s’applique au repo courant.

### Scan composants

Commande :

```bash
rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
```

Résultat : aucune occurrence de `ShadowLayerComponent` et aucun nouveau composant Shadow. Les occurrences `extends .*Component` correspondent aux composants Flame existants :

```text
lib/src/presentation/flame/map_layers_component.dart:35:class MapLayersComponent extends PositionComponent
lib/src/presentation/flame/player_component.dart:18:class PlayerComponent extends PositionComponent
lib/src/presentation/flame/overworld_actor_component.dart:8:class OverworldActorComponent extends PositionComponent
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:26:class PlacedElementOcclusionPatchComponent extends PositionComponent
```

La sortie complète contenait aussi les composants battle/overlay existants, sans ajout Shadow-21.

### Scan resolvers

Commande :

```bash
rg -n "resolveShadowConfig|resolveStaticPlacedElementShadow|resolveActorContactShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
```

Résultat :

```text
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:91:ShadowRuntimeRenderInstruction? resolveActorContactShadowRuntimeInstruction(
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:118:    resolveActorContactShadowRuntimeInstructions(
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:123:    final instruction = resolveActorContactShadowRuntimeInstruction(input);
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:103:    resolveStaticPlacedElementShadowRuntimeInstruction(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:131:    resolveStaticPlacedElementShadowRuntimeInstructions(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:137:        resolveStaticPlacedElementShadowRuntimeInstruction(input);
lib/src/shadow/runtime_actor_contact_shadow_collection.dart:86:    instructions: resolveActorContactShadowRuntimeInstructions(inputs),
lib/src/shadow/shadow_runtime_instruction_collection.dart:110:ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:58:    final resolution = resolveShadowConfig(
lib/src/shadow/runtime_static_placed_element_shadow_collection.dart:75:    instructions: resolveStaticPlacedElementShadowRuntimeInstructions(inputs),
```

Ces occurrences sont dans les resolvers ou builders Shadow dédiés, pas dans `MapLayersComponent`, `RuntimeMapGame` ou la logique directe de `PlayableMapGame`.

### Scan renderer/blur

Commande :

```bash
rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
```

Résultat : occurrences préexistantes de `drawImageRect` dans des composants de rendu non Shadow, notamment `map_layers_component.dart`, `overworld_actor_component.dart`, `placed_element_occlusion_patch_component.dart` et composants battle. Aucun ajout Shadow-21 ne contient `drawAtlas`, `saveLayer`, `ImageFilter`, `blurRadius`, `runtimeBlur`, `customShadowSprite`, `WorldLightState`, `ShadowLightProfile`, `zOrder` ou `zIndex`.

### Scan diff-only MapLayersComponent

Commande :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart \
  | rg -n "ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|resolveShadowConfig|resolveStaticPlacedElementShadow|buildRuntimeStaticPlacedElementShadowCollection"
```

Résultat :

```text

```

### Scan diff-only PlayableMapGame + shadow

Commande :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/src/shadow \
  | rg -n "resolveShadowConfig|resolveStaticPlacedElementShadow|resolveActorContactShadow"
```

Résultat :

```text

```

Les nouveaux helpers appellent le builder Shadow-20, pas les resolvers bas niveau depuis `PlayableMapGame`.

### Scan diff-only renderer/blur

Commande :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow \
  | rg -n "drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
```

Résultat :

```text

```

### `git diff --check`

```text

```

## 19. git status initial

```text
?? reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
?? reports/collision/collision_system_audit_v0.md
```

## 20. git status final

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
?? packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
?? packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
?? packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart
?? packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
?? reports/collision/collision_lot_2_source_of_truth_implementation_plan.md
?? reports/collision/collision_system_audit_v0.md
?? reports/shadows/shadow_lot_21_runtime_static_placed_element_shadow_host_integration.md
```

## 21. git diff --stat

Tracked diff stat :

```text
 .../src/presentation/flame/playable_map_game.dart  | 65 +++++++++++++++++-----
 ...actor_contact_shadow_host_integration_test.dart |  1 +
 2 files changed, 53 insertions(+), 13 deletions(-)
```

Stats des nouveaux fichiers Shadow-21 :

```text
 .../lib/src/shadow/runtime_shadow_collection_merge.dart      | 12 ++++++++++++
 1 file changed, 12 insertions(+)

 ...ntime_static_placed_element_shadow_sources.dart | 73 ++++++++++++++++++++++
 1 file changed, 73 insertions(+)

 .../runtime_shadow_collection_merge_test.dart      | 85 ++++++++++++++++++++++
 1 file changed, 85 insertions(+)

 ...laced_element_shadow_host_integration_test.dart | 471 +++++++++++++++++++++
 1 file changed, 471 insertions(+)
```

## 22. Non-objectifs respectés

- Aucun profil Shadow créé.
- Aucun profil Shadow exposé dans le dropdown éditeur.
- Aucun fichier `map_editor` modifié.
- Aucun `MapLayersComponent` modifié.
- Aucun `RuntimeMapGame` modifié.
- Aucun `PlayerComponent` modifié.
- Aucun `OverworldActorComponent` modifié.
- Aucun `PlacedElementOcclusionPatchComponent` modifié.
- Aucun nouveau Flame Component.
- Aucun `ShadowLayerComponent`.
- Aucun `zOrder` / `zIndex`.
- Aucun système de priorité Flame.
- Aucun blur.
- Aucun atlas ou sprite custom d’ombre.
- Aucun time-of-day.
- Aucun `WorldLightState`.
- Aucun `ShadowLightProfile`.
- Aucun tri, culling ou déduplication.
- Aucun changement dans `map_core`, `map_editor`, `map_gameplay` ou `map_battle`.

## 23. Limite volontaire / fausse attente évitée

Shadow-21 does not create or expose Shadow profiles in the editor. It only renders static placed element shadows at runtime when the project already contains a valid ProjectShadowCatalog and element/placement shadow configuration.

Concrètement, l’écran éditeur qui affiche `Aucun profil Shadow disponible` reste attendu si le projet a un catalogue Shadow vide. Shadow-21 rend les ombres statiques visibles côté runtime uniquement si les données existent déjà.

## 24. Risques / réserves

- Les métriques statiques V0 utilisent la première frame visuelle de l’élément. Les changements de frame qui modifient réellement l’emprise visuelle ne recalculent pas encore l’ombre par frame.
- Le filtre de visibilité s’aligne sur les layers visibles et `opacity > 0`, mais ne crée pas encore de diagnostic runtime pour expliquer pourquoi une source est ignorée.
- Les static shadows sont recalculées au montage d’une map et lors du refresh de bundle lié à `setAnimationEnabled` sur la map active. Les mutations runtime futures qui changeraient `shadowOverride` ou la géométrie nécessiteront un point de refresh explicite.
- Le test pixel vérifie la présence d’un alpha au centre d’une ombre, pas un rendu visuel complet.

## 25. Auto-review finale

- Ai-je branché les static placed element shadows dans le host ? oui.
- Ai-je laissé `MapLayersComponent` sans logique static shadow ? oui.
- Ai-je gardé `RuntimeMapGame` passif ? oui.
- Ai-je préservé le provider externe prioritaire ? oui.
- Ai-je évité les duplications sur plusieurs background layers ? oui.
- Ai-je limité les actor shadows à l’active map ? oui.
- Ai-je permis les static shadows sur les maps connectées ? oui.
- Ai-je appelé `resolveShadowConfig` directement dans `PlayableMapGame` ? non.
- Ai-je créé un nouveau Flame Component ? non.
- Ai-je ajouté un `zOrder` / `zIndex` ? non.
- Ai-je ajouté du blur / atlas / sprite custom ? non.
- Ai-je touché à `map_core` / `map_editor` / `map_gameplay` / `map_battle` ? non.
- Ai-je documenté les limites sur les éléments statiques dynamiquement modifiés ? oui.

## 26. Regard critique sur le prompt

Le prompt est clair sur la séparation renderer / provider / host. Le point le plus délicat est l’ambiguïté des coordonnées `world*` : dans le renderer elles sont “monde” au sens Shadow model, mais dans `MapLayersComponent` connecté, le `Canvas` est déjà local au composant positionné par Flame. Shadow-21 choisit donc des métriques locales au background map component pour éviter le double offset. Cette décision est testée par le cas connected map.

Le prompt demande aussi des preuves très complètes. Pour les fichiers de host existants, le format le plus vérifiable est le diff complet des sections modifiées, car il montre chaque ligne réellement touchée sans recopier l’intégralité de fichiers runtime sans rapport avec Shadow-21.

## 27. Contenu complet des fichiers créés/modifiés

### `packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart`

```dart
import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

ShadowRuntimeInstructionCollection mergeShadowRuntimeInstructionCollections(
  Iterable<ShadowRuntimeInstructionCollection> collections,
) {
  final instructions = <ShadowRuntimeRenderInstruction>[];
  for (final collection in collections) {
    instructions.addAll(collection.instructions);
  }
  return ShadowRuntimeInstructionCollection(instructions: instructions);
}
```

### `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart`

```dart
import 'package:map_core/map_core.dart';

import '../application/runtime_map_bundle.dart';
import 'runtime_static_placed_element_shadow_collection.dart';
import 'shadow_runtime_instruction_collection.dart';
import 'static_placed_element_shadow_runtime_resolver.dart';

List<RuntimeStaticPlacedElementShadowSource>
    buildRuntimeStaticPlacedElementShadowSources({
  required RuntimeMapBundle bundle,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in bundle.manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in bundle.map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty ||
      visibleTileLayerById.isEmpty ||
      bundle.map.placedElements.isEmpty) {
    return const <RuntimeStaticPlacedElementShadowSource>[];
  }

  final sources = <RuntimeStaticPlacedElementShadowSource>[];
  final cellWidth = bundle.cellWidth;
  final cellHeight = bundle.cellHeight;
  for (final placed in bundle.map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final frame = element.frames.first;
    final source = frame.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : element.tilesetId.trim();
    if (tilesetId.isEmpty) {
      continue;
    }
    sources.add(
      RuntimeStaticPlacedElementShadowSource(
        id: placed.id,
        elementId: placed.elementId,
        elementShadow: element.shadow,
        placedOverride: placed.shadowOverride,
        metrics: StaticPlacedElementShadowRuntimeMetrics(
          worldLeft: placed.pos.x * cellWidth,
          worldTop: placed.pos.y * cellHeight,
          visualWidth: source.width * cellWidth,
          visualHeight: source.height * cellHeight,
        ),
      ),
    );
  }
  return List<RuntimeStaticPlacedElementShadowSource>.unmodifiable(sources);
}

ShadowRuntimeInstructionCollection
    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
  required RuntimeMapBundle bundle,
}) {
  return buildRuntimeStaticPlacedElementShadowCollection(
    catalog: bundle.manifest.shadowCatalog,
    sources: buildRuntimeStaticPlacedElementShadowSources(bundle: bundle),
  );
}
```

### `packages/map_runtime/test/shadow/runtime_shadow_collection_merge_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_shadow_collection_merge.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('mergeShadowRuntimeInstructionCollections', () {
    test('merges empty collections into an empty collection', () {
      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(),
        ShadowRuntimeInstructionCollection(),
      ]);

      expect(merged, ShadowRuntimeInstructionCollection());
    });

    test('preserves collection order and instruction order without sorting',
        () {
      final firstStatic = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 30,
      );
      final actor = _shadow(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 10,
      );
      final secondStatic = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 20,
      );

      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(instructions: [firstStatic]),
        ShadowRuntimeInstructionCollection(instructions: [actor, secondStatic]),
      ]);

      expect(merged.instructions, [firstStatic, actor, secondStatic]);
      expect(merged.groundStatic, [firstStatic, secondStatic]);
      expect(merged.actorContact, [actor]);
    });

    test('does not deduplicate and retains opacity zero instructions', () {
      final duplicate = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0,
      );

      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(instructions: [duplicate]),
        ShadowRuntimeInstructionCollection(instructions: [duplicate]),
      ]);

      expect(merged.instructions, [duplicate, duplicate]);
      expect(merged.groundStatic, [duplicate, duplicate]);
    });

    test('exposes immutable lists through the collection contract', () {
      final merged = mergeShadowRuntimeInstructionCollections([
        ShadowRuntimeInstructionCollection(instructions: [_shadow()]),
      ]);

      expect(
        () => merged.instructions.add(_shadow()),
        throwsUnsupportedError,
      );
    });
  });
}

ShadowRuntimeRenderInstruction _shadow({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 0,
  double opacity = 1,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: 0,
    width: 16,
    height: 8,
    opacity: opacity,
  );
}
```

### `packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime static placed element shadow host integration', () {
    test('PlayableMapGame builds static shadows for configured placed elements',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);
      final collection = background.shadowCollectionProvider!()!;

      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);
      expect(collection.groundStatic.single.renderPass,
          ShadowRenderPass.groundStatic);
    });

    test('static shadow is visible in the background render when configured',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final instruction =
          background.shadowCollectionProvider!()!.groundStatic.single;
      final image = await _render(background, width: 160, height: 160);
      final centerX = (instruction.worldLeft + instruction.width / 2).round();
      final centerY = (instruction.worldTop + instruction.height / 2).round();

      expect((await pixelAt(image, centerX, centerY))[3], greaterThan(0));
    });

    test('empty catalog or missing profile creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(shadowCatalog: const ProjectShadowCatalog.empty()),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('element without shadow config creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(elementShadow: null),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('disabled placed override creates no static shadow', () async {
      final game = PlayableMapGame(
        bundle: _bundle(
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!();

      expect(collection, isNull);
    });

    test('custom placed override modifies the static shadow instruction',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(
          placedOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 8,
            scaleX: 2,
            opacity: 0.2,
          ),
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final instruction = _backgroundLayer(game)
          .shadowCollectionProvider!()!
          .groundStatic
          .single;

      expect(instruction.width, closeTo(96, 0.0001));
      expect(instruction.worldLeft, closeTo(24, 0.0001));
      expect(instruction.opacity, 0.2);
    });

    test('internal static and actor shadows are merged for the active map',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!()!;

      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, hasLength(1));
      expect(collection.instructions.first.renderPass,
          ShadowRenderPass.groundStatic);
      expect(collection.instructions.last.renderPass,
          ShadowRenderPass.actorContact);
    });

    test('static and actor flags affect only their internal collections',
        () async {
      final staticOnly = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );
      staticOnly.onGameResize(Vector2(160, 160));
      await staticOnly.onLoad();
      staticOnly.update(0);

      final actorOnly = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableStaticPlacedElementShadows: false,
      );
      actorOnly.onGameResize(Vector2(160, 160));
      await actorOnly.onLoad();
      actorOnly.update(0);

      final disabled = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );
      disabled.onGameResize(Vector2(160, 160));
      await disabled.onLoad();
      disabled.update(0);

      expect(
        _backgroundLayer(staticOnly).shadowCollectionProvider!()!.groundStatic,
        hasLength(1),
      );
      expect(
        _backgroundLayer(staticOnly).shadowCollectionProvider!()!.actorContact,
        isEmpty,
      );
      expect(
        _backgroundLayer(actorOnly).shadowCollectionProvider!()!.groundStatic,
        isEmpty,
      );
      expect(
        _backgroundLayer(actorOnly).shadowCollectionProvider!()!.actorContact,
        hasLength(1),
      );
      expect(_backgroundLayer(disabled).shadowCollectionProvider, isNull);
    });

    test('external provider remains priority even when internal flags are off',
        () async {
      ShadowRuntimeInstructionCollection? provider() {
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: 'FF0000'),
          ],
        );
      }

      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        shadowCollectionProvider: provider,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );

      game.onGameResize(Vector2(64, 64));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(
          background.shadowCollectionProvider!()!.groundStatic, hasLength(1));
    });

    test(
        'connected map background receives static shadows but no actor shadows',
        () async {
      final connected = _bundle(mapId: 'connected-static-map');
      final game = PlayableMapGame(
        bundle: _bundle(
          mapId: 'active-static-map',
          connectionTargetMapId: 'connected-static-map',
        ),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        runtimeMapBundleLoader: ({required projectFilePath, required mapId}) {
          expect(mapId, 'connected-static-map');
          return Future.value(connected);
        },
      );

      game.onGameResize(Vector2(320, 160));
      await game.onLoad();
      await _pumpUntil(
          game, () => game.debugIsMapLoaded('connected-static-map'));
      game.update(0);
      final activeProvider =
          game.debugShadowCollectionProviderForMap('active-static-map')!;
      final connectedProvider =
          game.debugShadowCollectionProviderForMap('connected-static-map')!;

      expect(activeProvider()!.groundStatic, hasLength(1));
      expect(activeProvider()!.actorContact, hasLength(1));
      expect(connectedProvider()!.groundStatic, hasLength(1));
      expect(connectedProvider()!.actorContact, isEmpty);
    });

    test('RuntimeMapGame remains passive for static placed element shadows',
        () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });
  });
}

RuntimeMapBundle _bundle({
  String mapId = 'static-shadow-test',
  ProjectShadowCatalog? shadowCatalog,
  Object? elementShadow = _defaultElementShadow,
  MapPlacedElementShadowOverride? placedOverride,
  String? connectionTargetMapId,
}) {
  final tileLayer = List<int>.filled(16, 0);
  final connections = <MapConnection>[
    if (connectionTargetMapId != null)
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: connectionTargetMapId,
      ),
  ];
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Static Shadow Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      elements: [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'props',
          categoryId: 'nature',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
            ),
          ],
          shadow: identical(elementShadow, _defaultElementShadow)
              ? ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'soft-tree',
                )
              : elementShadow as ProjectElementShadowConfig?,
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
      shadowCatalog: shadowCatalog ?? _shadowCatalog(),
    ),
    map: MapData(
      id: mapId,
      name: mapId,
      size: const GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'Decor',
          tilesetId: 'base',
          tiles: tileLayer,
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'tree-1',
          layerId: 'decor',
          elementId: 'tree',
          pos: const GridPos(x: 1, y: 1),
          shadowOverride: placedOverride,
        ),
      ],
      entities: const [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      connections: connections,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-static-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const Object _defaultElementShadow = Object();

ProjectShadowCatalog _shadowCatalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'soft-tree',
        name: 'Soft Tree',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
      ),
    ],
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

MapLayersComponent _backgroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
}

MapLayersComponent _foregroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );
}

Future<ui.Image> _render(
  MapLayersComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() condition,
) async {
  for (var i = 0; i < 20; i += 1) {
    if (condition()) {
      return;
    }
    game.update(0);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not met');
}

ShadowRuntimeRenderInstruction _shadow({
  String colorHexRgb = '000000',
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: colorHexRgb,
  );
}
```

### Sections modifiées de `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Diff complet des lignes modifiées par Shadow-21 :

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 86e65ec0..062fc86d 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -60,6 +60,8 @@ import '../../application/trainer_battle_request.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
 import '../../infrastructure/tile_image_loader.dart';
 import '../../shadow/runtime_actor_contact_shadow_collection.dart';
+import '../../shadow/runtime_shadow_collection_merge.dart';
+import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
 import '../../shadow/shadow_runtime_collection_provider.dart';
 import '../../shadow/shadow_runtime_instruction_collection.dart';
 import 'battle_bag_menu_model.dart';
@@ -125,6 +127,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
     this.shadowCollectionProvider,
     this.enableActorContactShadows = true,
+    this.enableStaticPlacedElementShadows = true,
   })  : _bundle = bundle,
         _gameState = normalizeLoadedGameState(
           saveData == null
@@ -158,6 +161,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   final List<RuntimeCutsceneAsset> runtimeCutscenes;
   final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
   final bool enableActorContactShadows;
+  final bool enableStaticPlacedElementShadows;
   RuntimeMapBundle _bundle;
   GameState _gameState;
   late GameplayWorldState _world;
@@ -181,6 +185,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   final List<OverworldActorComponent> _npcActors = [];
   final ShadowRuntimeCollectionController _actorShadowCollectionController =
       ShadowRuntimeCollectionController();
+  final Map<String, ShadowRuntimeInstructionCollection>
+      _staticShadowCollectionByMapId =
+      <String, ShadowRuntimeInstructionCollection>{};
   final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
   final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
   final RuntimeDialogueSessionLoader _dialogueSessionLoader;
@@ -1633,20 +1640,32 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     if (externalProvider != null) {
       return externalProvider;
     }
-    if (!enableActorContactShadows) {
+    if (!enableActorContactShadows && !enableStaticPlacedElementShadows) {
       return null;
     }
-    return () => _provideActorContactShadowCollectionForMap(mapId);
+    return () => _provideShadowCollectionForMap(mapId);
   }
 
-  ShadowRuntimeInstructionCollection?
-      _provideActorContactShadowCollectionForMap(
+  ShadowRuntimeInstructionCollection? _provideShadowCollectionForMap(
     String mapId,
   ) {
-    if (mapId != _activeMapId) {
+    final collections = <ShadowRuntimeInstructionCollection>[];
+    if (enableStaticPlacedElementShadows) {
+      final staticCollection = _staticShadowCollectionByMapId[mapId];
+      if (staticCollection != null && staticCollection.isNotEmpty) {
+        collections.add(staticCollection);
+      }
+    }
+    if (enableActorContactShadows && mapId == _activeMapId) {
+      final actorCollection = _actorShadowCollectionController.provide();
+      if (actorCollection != null && actorCollection.isNotEmpty) {
+        collections.add(actorCollection);
+      }
+    }
+    if (collections.isEmpty) {
       return null;
     }
-    return _actorShadowCollectionController.provide();
+    return mergeShadowRuntimeInstructionCollections(collections);
   }
 
   void _refreshActorContactShadowCollection() {
@@ -1663,25 +1682,42 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     );
   }
 
+  void _refreshStaticPlacedElementShadowCollection(RuntimeMapBundle bundle) {
+    if (shadowCollectionProvider != null || !enableStaticPlacedElementShadows) {
+      _staticShadowCollectionByMapId.remove(bundle.map.id);
+      return;
+    }
+    final collection = buildRuntimeStaticPlacedElementShadowCollectionForBundle(
+      bundle: bundle,
+    );
+    if (collection.isEmpty) {
+      _staticShadowCollectionByMapId.remove(bundle.map.id);
+      return;
+    }
+    _staticShadowCollectionByMapId[bundle.map.id] = collection;
+  }
+
   List<RuntimeActorContactShadowSource> _actorContactShadowSources() {
+    final activeMap = _loadedMapsById[_activeMapId];
+    final activeMapOrigin =
+        activeMap == null ? Vector2.zero() : _originPixelsOf(activeMap);
     final sources = <RuntimeActorContactShadowSource>[
       RuntimeActorContactShadowSource(
         id: 'player',
-        footWorldX: _player.footPoint.x,
-        footWorldY: _player.footPoint.y,
+        footWorldX: _player.footPoint.x - activeMapOrigin.x,
+        footWorldY: _player.footPoint.y - activeMapOrigin.y,
         visualWidth: _player.visualSize.x,
         visualHeight: _player.visualSize.y,
         isVisible: _player.parent != null,
       ),
     ];
-    final active = _loadedMapsById[_activeMapId];
-    if (active != null) {
-      for (final actor in active.npcActors) {
+    if (activeMap != null) {
+      for (final actor in activeMap.npcActors) {
         sources.add(
           RuntimeActorContactShadowSource(
             id: actor.character.id,
-            footWorldX: actor.position.x + actor.size.x / 2,
-            footWorldY: actor.depthSortY,
+            footWorldX: actor.position.x + actor.size.x / 2 - activeMapOrigin.x,
+            footWorldY: actor.depthSortY - activeMapOrigin.y,
             visualWidth: actor.size.x,
             visualHeight: actor.size.y,
             isVisible: actor.parent != null && actor.isGameplayPresent,
@@ -5025,6 +5061,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
           npcActors: activeLoaded.npcActors,
           npcActorByEntityId: activeLoaded.npcActorByEntityId,
         );
+        _refreshStaticPlacedElementShadowCollection(_bundle);
       }
       debugPrint(
         '[placed_behavior] setAnimationEnabled applied instance=$instanceId enabled=$enabled',
@@ -6464,6 +6501,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       actor.removeFromParent();
       _npcActors.remove(actor);
     }
+    _staticShadowCollectionByMapId.remove(mapId);
   }
 
   Future<_LoadedPlayableMap> _mountLoadedMap({
@@ -6555,6 +6593,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       npcActorByEntityId: npcActorByEntityId,
     );
     _loadedMapsById[bundle.map.id] = loaded;
+    _refreshStaticPlacedElementShadowCollection(bundle);
     _applyNpcVisibilityToLoadedMap(loaded);
     return loaded;
   }
```

### Section modifiée de `packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart`

```diff
diff --git a/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart b/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
index 5aebc3ce..fcbdb499 100644
--- a/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
@@ -152,6 +152,7 @@ void main() {
         projectFilePath: '/tmp/project.json',
         runtimeTilesetImageLoader: _emptyImageLoader,
         enableActorContactShadows: false,
+        enableStaticPlacedElementShadows: false,
       );
 
       game.onGameResize(Vector2(96, 96));
```

Le présent fichier est le rapport Shadow-21 créé par le lot.

## 28. Diffs complets ou équivalents /dev/null pour fichiers créés

### `packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart`

```diff
diff --git a/packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart b/packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
new file mode 100644
index 00000000..d9688702
--- /dev/null
+++ b/packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
@@ -0,0 +1,12 @@
+import 'shadow_runtime_instruction_collection.dart';
+import 'shadow_runtime_render_instruction.dart';
+
+ShadowRuntimeInstructionCollection mergeShadowRuntimeInstructionCollections(
+  Iterable<ShadowRuntimeInstructionCollection> collections,
+) {
+  final instructions = <ShadowRuntimeRenderInstruction>[];
+  for (final collection in collections) {
+    instructions.addAll(collection.instructions);
+  }
+  return ShadowRuntimeInstructionCollection(instructions: instructions);
+}
```

### `packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart`

```diff
diff --git a/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
new file mode 100644
index 00000000..bc2da17f
--- /dev/null
+++ b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
@@ -0,0 +1,73 @@
+import 'package:map_core/map_core.dart';
+
+import '../application/runtime_map_bundle.dart';
+import 'runtime_static_placed_element_shadow_collection.dart';
+import 'shadow_runtime_instruction_collection.dart';
+import 'static_placed_element_shadow_runtime_resolver.dart';
+
+List<RuntimeStaticPlacedElementShadowSource>
+    buildRuntimeStaticPlacedElementShadowSources({
+  required RuntimeMapBundle bundle,
+}) {
+  final elementById = <String, ProjectElementEntry>{
+    for (final element in bundle.manifest.elements) element.id: element,
+  };
+  final visibleTileLayerById = <String, TileLayer>{
+    for (final layer in bundle.map.layers.whereType<TileLayer>())
+      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
+  };
+  if (elementById.isEmpty ||
+      visibleTileLayerById.isEmpty ||
+      bundle.map.placedElements.isEmpty) {
+    return const <RuntimeStaticPlacedElementShadowSource>[];
+  }
+
+  final sources = <RuntimeStaticPlacedElementShadowSource>[];
+  final cellWidth = bundle.cellWidth;
+  final cellHeight = bundle.cellHeight;
+  for (final placed in bundle.map.placedElements) {
+    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
+      continue;
+    }
+    final element = elementById[placed.elementId.trim()];
+    if (element == null || element.frames.isEmpty) {
+      continue;
+    }
+    final frame = element.frames.first;
+    final source = frame.source;
+    if (source.width <= 0 || source.height <= 0) {
+      continue;
+    }
+    final tilesetId = frame.tilesetId.trim().isNotEmpty
+        ? frame.tilesetId.trim()
+        : element.tilesetId.trim();
+    if (tilesetId.isEmpty) {
+      continue;
+    }
+    sources.add(
+      RuntimeStaticPlacedElementShadowSource(
+        id: placed.id,
+        elementId: placed.elementId,
+        elementShadow: element.shadow,
+        placedOverride: placed.shadowOverride,
+        metrics: StaticPlacedElementShadowRuntimeMetrics(
+          worldLeft: placed.pos.x * cellWidth,
+          worldTop: placed.pos.y * cellHeight,
+          visualWidth: source.width * cellWidth,
+          visualHeight: source.height * cellHeight,
+        ),
+      ),
+    );
+  }
+  return List<RuntimeStaticPlacedElementShadowSource>.unmodifiable(sources);
+}
+
+ShadowRuntimeInstructionCollection
+    buildRuntimeStaticPlacedElementShadowCollectionForBundle({
+  required RuntimeMapBundle bundle,
+}) {
+  return buildRuntimeStaticPlacedElementShadowCollection(
+    catalog: bundle.manifest.shadowCatalog,
+    sources: buildRuntimeStaticPlacedElementShadowSources(bundle: bundle),
+  );
+}
```

Les deux nouveaux tests ont leur contenu complet au §27. Leurs diff `/dev/null` est équivalent à ces blocs complets, car ce sont des fichiers nouveaux.

