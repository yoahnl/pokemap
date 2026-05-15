# Shadow Lot 19 — Runtime Actor Contact Shadow Collection V0

## 1. Résumé du lot

Shadow-19 ajoute la première génération runtime effective d’instructions d’ombres acteur `actorContact`.

Le lot ajoute un builder pur qui transforme des sources acteur runtime en `ShadowRuntimeInstructionCollection`, via le resolver Shadow-13 existant. `PlayableMapGame` alimente ensuite un `ShadowRuntimeCollectionController` interne et transmet le provider effectif au `MapLayersComponent` background uniquement.

Le lot ne traite aucun élément statique, ne lit pas `ProjectShadowCatalog`, `ProjectElementEntry` ou `MapPlacedElement` pour produire des ombres, ne modifie pas `MapLayersComponent`, ne crée aucun nouveau Flame Component et ne touche pas `map_core`, `map_editor`, `map_gameplay` ou `map_battle`.

## 2. Design retenu

- Ajout d’un fichier runtime pur : `packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart`.
- Ajout d’un modèle runtime-only : `RuntimeActorContactShadowSource`.
- Ajout d’un default actor shadow V0 : `kDefaultRuntimeActorContactShadowConfig`.
- Ajout d’un builder : `buildRuntimeActorContactShadowCollection(...)`.
- `PlayableMapGame` possède un `ShadowRuntimeCollectionController` interne.
- Le `shadowCollectionProvider` externe Shadow-18 reste prioritaire.
- `enableActorContactShadows` ne désactive que la génération interne.
- Le provider interne est scoped par `mapId` et ne fournit une collection que pour `_activeMapId`.
- `RuntimeMapGame` reste passif.
- `MapLayersComponent` reste sans logique acteur.

## 3. Fichiers créés

- `packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart`
- `packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart`
- `packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart`
- `reports/shadows/shadow_lot_19_runtime_actor_contact_shadow_collection.md`

## 4. Fichiers modifiés

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

## 5. Fichiers non modifiés explicitement

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_core/**`
- `packages/map_editor/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`

## 6. API runtime ajoutée

```dart
const ResolvedShadowConfig kDefaultRuntimeActorContactShadowConfig

final class RuntimeActorContactShadowSource

ShadowRuntimeInstructionCollection buildRuntimeActorContactShadowCollection({
  required Iterable<RuntimeActorContactShadowSource> sources,
  ResolvedShadowConfig resolvedConfig =
      kDefaultRuntimeActorContactShadowConfig,
})
```

`PlayableMapGame` ajoute aussi :

```dart
final bool enableActorContactShadows;
```

et un seam de test :

```dart
ShadowRuntimeInstructionCollectionProvider?
    debugShadowCollectionProviderForMap(String mapId)
```

## 7. Default actor contact shadow config V0

Le default runtime interne est :

```dart
const ResolvedShadowConfig(
  shadowProfileId: 'runtime_actor_contact_default',
  mode: ShadowCasterMode.contactBlob,
  renderPass: ShadowRenderPass.actorContact,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 0.35,
  colorHexRgb: '000000',
  softnessMode: ShadowSoftnessMode.hardEdge,
)
```

Il ne lit pas `ProjectShadowCatalog`. C’est une heuristique V0 temporaire pour les acteurs runtime, en attendant un futur lot d’authoring acteur.

## 8. Formule de métriques acteur retenue

Audit confirmé :

- `PlayerComponent` utilise `Anchor.topLeft`.
- `PlayerComponent` expose déjà `footPoint`.
- `OverworldActorComponent` utilise `Anchor.topLeft`.
- `OverworldActorComponent.depthSortY` vaut `position.y + size.y`.

Formule joueur :

```text
footWorldX = _player.footPoint.x
footWorldY = _player.footPoint.y
visualWidth = _player.size.x
visualHeight = _player.size.y
isVisible = _player.parent != null
```

Formule PNJ :

```text
footWorldX = actor.position.x + actor.size.x / 2
footWorldY = actor.depthSortY
visualWidth = actor.size.x
visualHeight = actor.size.y
isVisible = actor.parent != null && actor.isGameplayPresent
```

`parent != null` est utilisé comme présence runtime dans ce seam, car les tests directs `onLoad` parentent les composants sans garantir `isMounted` au sens complet Flame. Cela garde le host testable sans modifier `PlayerComponent` ou `OverworldActorComponent`.

## 9. Câblage PlayableMapGame réalisé

`PlayableMapGame` :

- ajoute `enableActorContactShadows = true` par défaut ;
- garde `shadowCollectionProvider` externe prioritaire ;
- crée un `ShadowRuntimeCollectionController` interne ;
- rafraîchit la collection après `world.add(_player)` puis à chaque `update` après le depth ordering ;
- transmet au `MapLayersComponent` background un provider effectif ;
- laisse le foreground sans provider ;
- scope le provider interne par map id :

```text
provider externe présent -> provider externe
sinon enableActorContactShadows false -> null
sinon provider interne scoped par map id
```

Le provider interne retourne `null` quand le `MapLayersComponent` background n’appartient pas à `_activeMapId`, ce qui évite que plusieurs backgrounds de maps connectées dessinent la même collection acteur.

## 10. Pourquoi ce lot ne gère pas les éléments statiques

Shadow-19 se limite aux acteurs :

- il utilise `resolveActorContactShadowRuntimeInstructions(...)` ;
- il n’importe pas le resolver statique ;
- il ne lit pas `ProjectElementEntry.shadow` ;
- il ne lit pas `MapPlacedElement.shadowOverride` ;
- il n’appelle pas `resolveShadowConfig` ;
- il ne crée pas de collection d’éléments statiques.

Les éléments statiques restent pour un lot ultérieur.

## 11. Tests ajoutés

`runtime_actor_contact_shadow_collection_test.dart` couvre :

- default config V0 ;
- source visible ;
- source invisible ;
- ordre préservé ;
- absence de déduplication ;
- opacity 0 conservée ;
- config `none` ;
- config `groundStatic` rejetée par le resolver acteur ;
- métriques invalides rejetées ;
- égalité de valeur ;
- collection immuable.

`runtime_actor_contact_shadow_host_integration_test.dart` couvre :

- provider interne transmis au background ;
- foreground sans provider ;
- rendu pixel d’une ombre acteur joueur ;
- PNJ inclus ;
- provider externe prioritaire même avec `enableActorContactShadows=false` ;
- flag désactivant seulement l’interne ;
- provider interne scoped par map active ;
- collection différente entre deux updates ;
- `RuntimeMapGame` passif.

## 12. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
flutter test test/shadow/runtime_actor_contact_shadow_collection_test.dart test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
dart format lib/src/shadow/runtime_actor_contact_shadow_collection.dart lib/src/presentation/flame/playable_map_game.dart test/shadow/runtime_actor_contact_shadow_collection_test.dart test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
flutter test test/shadow/runtime_actor_contact_shadow_collection_test.dart test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
flutter test test/shadow
flutter analyze lib/src/shadow lib/src/presentation/flame/map_layers_component.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/runtime_map_game.dart test/shadow
flutter test
dart test test/shadow
rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
rg -n "resolveStaticPlacedElementShadow|StaticPlacedElementShadow" lib/src/presentation/flame lib/src/shadow
rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveStaticPlacedElementShadow|StaticPlacedElementShadow"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveShadowRuntimeInstruction|resolveActorContactShadow|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow | rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component"
git diff --check
git diff --stat
git status --short --untracked-files=all
git diff --name-status
```

## 13. Résultats complets des tests ciblés

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_actor_contact_shadow_collection_test.dart test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
```

Sortie utile complète :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection default actor contact config is an internal V0 contact blob
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection visible source creates one actorContact instruction
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection invisible source creates no instruction
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection multiple sources preserve order
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection equal sources are not deduplicated
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection opacity zero config still creates a retained instruction
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection none config creates no instruction
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection groundStatic config is rejected by the actor resolver
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection source rejects invalid runtime metrics
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection source has value equality
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart: runtime actor contact shadow collection returned collection exposes immutable lists
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration PlayableMapGame wires an internal provider to background only
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration internal provider draws an actor contact shadow under the player
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration NPC actors are included when present
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
[step_studio_trace] npc_mount_added map=shadow-actor-test entity=npc-one
[step_studio_trace] npc_presence_applied map=shadow-actor-test entity=npc-one present=true
[npc_patrol] read movement entity=npc-one pos=(2,1) size=1x1 mode=idle waypoints= loop=true pauseMs=0 stepMs=200
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration external provider stays priority when internal shadows are disabled
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration disabled internal shadows do not install an internal provider
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration internal provider is scoped to the active map background
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration internal provider can return a different collection after movement
[runtime] Map loaded: shadow-actor-test, spawn at (0, 0)
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart: runtime actor contact shadow host integration RuntimeMapGame remains passive for actor shadows
00:00 +19: All tests passed!
```

## 14. Ligne finale exacte des tests globaux

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final exact :

```text
00:01 +163: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame/map_layers_component.dart lib/src/presentation/flame/playable_map_game.dart lib/src/presentation/flame/runtime_map_game.dart test/shadow
```

Résultat exact :

```text
No issues found! (ran in 2.3s)
```

Commande :

```bash
cd packages/map_runtime && flutter test
```

Résultat final exact :

```text
00:18 +1084: All tests passed!
```

Commande optionnelle :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final exact :

```text
00:00 +152: All tests passed!
```

## 15. Résultats des scans anti-dérive

Commande :

```bash
cd packages/map_runtime
rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
```

Résultat :

```text
lib/src/presentation/flame/battle_scene_backdrop_component.dart:19:class BattleSceneBackdropComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:35:final class BattleFxLayerComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:670:final class _BattleScreenFlashComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:705:final class _BattleBarrierPulseComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:898:final class _BattleWeatherAmbientComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:960:final class _BattlePseudoWeatherAmbientComponent extends PositionComponent {
lib/src/presentation/flame/battle_command_panel_component.dart:83:class BattleCommandPanelComponent extends PositionComponent with DragCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:1848:class _BattleRootButtonComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:1942:class _BattleChoiceCardComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:2044:class _BattlePartyEntryComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:2179:class _BattleMedicineTargetEntryComponent extends PositionComponent
lib/src/presentation/flame/battle_command_panel_component.dart:2315:class _BattleBagEntryComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:2900:class _BattleUtilityButtonComponent extends PositionComponent
lib/src/presentation/flame/battle_sdk_particle_component.dart:6:final class BattleSdkParticleComponent extends PositionComponent {
lib/src/presentation/flame/player_component.dart:18:class PlayerComponent extends PositionComponent {
lib/src/presentation/flame/battle_scene_combatant_component.dart:12:class BattleSceneCombatantComponent extends PositionComponent {
lib/src/presentation/flame/battle_scene_hud_component.dart:16:class BattleSceneHudComponent extends PositionComponent {
lib/src/presentation/flame/battle_transition_overlay_component.dart:7:class BattleTransitionOverlayComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_sprite_component.dart:8:final class BattleFxSpriteComponent extends PositionComponent {
lib/src/presentation/flame/dialogue_overlay_component.dart:8:class DialogueOverlayComponent extends PositionComponent {
lib/src/presentation/flame/map_layers_component.dart:35:class MapLayersComponent extends PositionComponent {
lib/src/presentation/flame/warp_transition_overlay_component.dart:6:class WarpTransitionOverlayComponent extends PositionComponent {
lib/src/presentation/flame/overworld_actor_component.dart:8:class OverworldActorComponent extends PositionComponent {
lib/src/presentation/flame/battle_rmxp_animation_component.dart:53:final class BattleRmxpAnimationComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_sprite_sheet_component.dart:6:final class BattleFxSpriteSheetComponent extends PositionComponent {
lib/src/presentation/flame/battle_overlay_component.dart:421:class BattleOverlayComponent extends PositionComponent {
lib/src/presentation/flame/battle_debug_panel_component.dart:12:class BattleDebugPanelComponent extends PositionComponent {
lib/src/presentation/flame/encounter_overlay_component.dart:6:class EncounterOverlayComponent extends PositionComponent {
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:26:class PlacedElementOcclusionPatchComponent extends PositionComponent {
```

Interprétation : occurrences préexistantes dans la pile Flame. Aucun `ShadowLayerComponent` ni nouveau Component Shadow dans les diffs Shadow-19.

Commande :

```bash
rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
```

Résultat :

```text
lib/src/shadow/shadow_runtime_instruction_collection.dart:110:ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
lib/src/presentation/flame/runtime_path_autotile.dart:36:      animation: const MapPlacedElementAnimation(
lib/src/presentation/flame/runtime_path_autotile.dart:38:        mode: MapPlacedElementAnimationMode.loop,
lib/src/presentation/flame/runtime_path_autotile.dart:78:    required MapPlacedElementAnimation animation,
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:9:/// Une **zone d’occlusion** (toit / couronne) pour **un** [MapPlacedElement] :
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:61:  final MapPlacedElement instance;
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:62:  final ProjectElementEntry element;
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:67:    required MapPlacedElement instance,
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:68:    required ProjectElementEntry element,
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:81:    required ProjectElementEntry element,
lib/src/presentation/flame/playable_map_game.dart:1885:          result.trigger == MapPlacedElementTriggerType.onEnter ||
lib/src/presentation/flame/playable_map_game.dart:1886:              result.trigger == MapPlacedElementTriggerType.onExit ||
lib/src/presentation/flame/playable_map_game.dart:1887:              result.trigger == MapPlacedElementTriggerType.onNear;
lib/src/presentation/flame/playable_map_game.dart:4857:    required MapPlacedElement element,
lib/src/presentation/flame/playable_map_game.dart:4858:    required MapPlacedElementBehavior behavior,
lib/src/presentation/flame/playable_map_game.dart:4859:    required MapPlacedElementTriggerType trigger,
lib/src/presentation/flame/playable_map_game.dart:4892:      case MapPlacedElementEffectType.showMessage:
lib/src/presentation/flame/playable_map_game.dart:4903:      case MapPlacedElementEffectType.openDialogue:
lib/src/presentation/flame/playable_map_game.dart:4907:      case MapPlacedElementEffectType.setAnimationEnabled:
lib/src/presentation/flame/playable_map_game.dart:4933:      case MapPlacedElementEffectType.playAnimationOnce:
lib/src/presentation/flame/playable_map_game.dart:4988:      final updatedMap = setMapPlacedElementAnimationEnabled(
lib/src/presentation/flame/playable_map_game.dart:5663:    required MapPlacedElement element,
lib/src/presentation/flame/playable_map_game.dart:5664:    required MapPlacedElementBehavior behavior,
lib/src/presentation/flame/playable_map_game.dart:5665:    required MapPlacedElementTriggerType trigger,
lib/src/presentation/flame/playable_map_game.dart:5678:    MapPlacedElementBehavior behavior,
lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart:230:        animation: const MapPlacedElementAnimation(
lib/src/presentation/flame/path_pattern_runtime_render_resolution.dart:232:          mode: MapPlacedElementAnimationMode.loop,
lib/src/presentation/flame/map_layers_component.dart:98:  late final Map<String, ProjectElementEntry> _elementById = {
lib/src/presentation/flame/map_layers_component.dart:801:      final animation = instance.animation ?? const MapPlacedElementAnimation();
lib/src/presentation/flame/map_layers_component.dart:1254:      animation: const MapPlacedElementAnimation(
lib/src/presentation/flame/map_layers_component.dart:1256:        mode: MapPlacedElementAnimationMode.loop,
lib/src/presentation/flame/map_layers_component.dart:1613:  final MapPlacedElementAnimation animation;
```

Interprétation : occurrences préexistantes liées au runtime map/éléments, pas à Shadow-19. Les scans diff-only ci-dessous restent vides.

Commande :

```bash
rg -n "resolveStaticPlacedElementShadow|StaticPlacedElementShadow" lib/src/presentation/flame lib/src/shadow
```

Résultat :

```text
lib/src/shadow/shadow_runtime_render_instruction.dart:91:      RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:11:final class StaticPlacedElementShadowRuntimeMetrics {
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:12:  StaticPlacedElementShadowRuntimeMetrics({
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:44:      other is StaticPlacedElementShadowRuntimeMetrics &&
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:68:final class StaticPlacedElementShadowRuntimeInput {
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:69:  const StaticPlacedElementShadowRuntimeInput({
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:75:  final StaticPlacedElementShadowRuntimeMetrics metrics;
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:80:      other is StaticPlacedElementShadowRuntimeInput &&
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:92:  StaticPlacedElementShadowRuntimeMetrics metrics,
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:103:    resolveStaticPlacedElementShadowRuntimeInstruction(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:104:  StaticPlacedElementShadowRuntimeInput input,
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:131:    resolveStaticPlacedElementShadowRuntimeInstructions(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:132:  Iterable<StaticPlacedElementShadowRuntimeInput> inputs,
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:137:        resolveStaticPlacedElementShadowRuntimeInstruction(input);
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:148:      'StaticPlacedElementShadowRuntimeMetrics.$name must be finite',
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:157:      'StaticPlacedElementShadowRuntimeMetrics.$name must be greater than 0',
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:166:      'StaticPlacedElementShadowRuntimeMetrics.$name must be between 0 and 1',
lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:5:  futureStaticPlacedElementShadows,
lib/src/presentation/flame/shadow_runtime_render_order_contract.dart:18:  RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
```

Interprétation : occurrences préexistantes Shadow-14/Shadow-10. Shadow-19 ne les appelle pas dans `PlayableMapGame`.

Commande :

```bash
rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
```

Résultat :

```text
lib/src/presentation/flame/battle_scene_backdrop_component.dart:153:    canvas.drawImageRect(image, inputSubrect, outputSubrect, Paint());
lib/src/presentation/flame/battle_command_panel_component.dart:1791:  canvas.drawImageRect(
lib/src/presentation/flame/map_layers_component.dart:388:      image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:471:    image.drawImageRect(
lib/src/presentation/flame/map_layers_component.dart:599:        image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:677:      image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:1020:    image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:1218:    tilesetImage.drawImageRect(
lib/src/presentation/flame/map_layers_component.dart:1543:    tilesetImage.drawImageRect(
lib/src/presentation/flame/battle_rmxp_animation_component.dart:178:      canvas.drawImageRect(
lib/src/presentation/flame/battle_scene_combatant_component.dart:520:    canvas.drawImageRect(image, inputSubrect, outputSubrect, _spritePaint());
lib/src/presentation/flame/battle_scene_combatant_component.dart:564:    canvas.drawImageRect(
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:147:        canvas.drawImageRect(tileImage, src, dst, paint);
lib/src/presentation/flame/battle_fx_sprite_sheet_component.dart:138:    canvas.drawImageRect(
lib/src/presentation/flame/overworld_actor_component.dart:271:    image.drawImageRect(
```

Interprétation : occurrences préexistantes du renderer map/battle/actor. Shadow-19 n’ajoute aucun rendu image, blur, atlas, zOrder ou zIndex.

Diff-only :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveShadowConfig|ProjectShadowCatalog|ProjectElementEntry|MapPlacedElement|shadowOverride|elementShadow|collectShadowRuntimeInstructions"
```

Résultat :

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveStaticPlacedElementShadow|StaticPlacedElementShadow"
```

Résultat :

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
```

Résultat :

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveShadowRuntimeInstruction|resolveActorContactShadow|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent"
```

Résultat :

```text
aucune sortie
```

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow packages/map_runtime/test/shadow | rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component"
```

Résultat :

```text
aucune sortie
```

## 16. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune sortie
```

`find .. -name AGENTS.md -print` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

## 17. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart
?? packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart
?? packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
```

Après ajout du rapport, le fichier suivant est aussi créé par Shadow-19 :

```text
?? reports/shadows/shadow_lot_19_runtime_actor_contact_shadow_collection.md
```

## 18. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 .../src/presentation/flame/playable_map_game.dart  | 85 +++++++++++++++++++++-
 1 file changed, 84 insertions(+), 1 deletion(-)
```

Note : les fichiers créés restent non suivis et sont listés dans `git status final`.

Commande :

```bash
git diff --name-status
```

Résultat :

```text
M	packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Commande :

```bash
git diff --check
```

Résultat :

```text
aucune sortie
```

## 19. Non-objectifs respectés

- Aucune ombre statique générée.
- Aucun `ProjectShadowCatalog` lu.
- Aucun `ProjectElementEntry` lu pour produire une ombre.
- Aucun `MapPlacedElement` lu pour produire une ombre.
- Aucun `resolveShadowConfig` appelé.
- Aucun resolver statique appelé.
- Aucun `collectShadowRuntimeInstructions` appelé.
- Aucun culling ajouté.
- Aucun tri ajouté.
- Aucune déduplication ajoutée.
- Aucun `zOrder` ou `zIndex` ajouté.
- Aucun blur ajouté.
- Aucun atlas/sprite d’ombre ajouté.
- Aucun `ShadowLayerComponent` créé.
- Aucun nouveau Flame Component créé.
- `PlayerComponent` non modifié.
- `OverworldActorComponent` non modifié.
- `PlacedElementOcclusionPatchComponent` non modifié.
- `MapLayersComponent` non modifié.
- `RuntimeMapGame` non modifié.
- `map_core` non modifié.
- `map_editor` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.

## 20. Risques / réserves

- Le default actor shadow V0 est interne et non authorable. Un futur lot devra décider si les acteurs ont une configuration persistante.
- La formule PNJ utilise `position.x + size.x / 2` et `depthSortY`, ce qui colle à `Anchor.topLeft` et aux conventions actuelles. Une future refonte d’ancrage acteur devra revoir ce calcul.
- `parent != null` est utilisé pour le seam runtime/test direct. En runtime Flame complet, `isMounted` pourrait être réévalué si un besoin strict apparaît.
- Les ombres acteur sont activées par défaut dans `PlayableMapGame` en absence de provider externe. Le flag permet de couper uniquement cette génération interne.
- L’intégration visuelle réelle dépend encore des offsets et dimensions V0 du resolver Shadow-13.

## 21. Auto-review finale

- Ai-je généré uniquement des ombres `actorContact` ? Oui.
- Ai-je touché aux ombres statiques ? Non.
- Ai-je appelé `resolveShadowConfig` ? Non.
- Ai-je lu `ProjectShadowCatalog` / `ProjectElementEntry` / `MapPlacedElement` pour produire ces ombres ? Non.
- Ai-je modifié `PlayerComponent` / `OverworldActorComponent` ? Non.
- Ai-je créé un nouveau Flame Component ? Non.
- Ai-je laissé `MapLayersComponent` sans logique acteur ? Oui.
- Le provider externe Shadow-18 reste-t-il prioritaire ? Oui.
- Le foreground reste-t-il sans provider Shadow ? Oui.
- Le comportement reste-t-il testable sans image/atlas/blur ? Oui.

## 22. Regard critique sur le prompt

Le prompt impose à juste titre une preuve diff-only, car le runtime contient déjà beaucoup d’occurrences `MapPlacedElement`, `drawImageRect` et `Component` préexistantes. Les scans globaux seuls seraient ambigus; les scans diff-only lèvent l’ambiguïté.

La seule tension technique était la demande conceptuelle `actor.isMounted && actor.isGameplayPresent` pour les PNJ. L’audit des tests directs `PlayableMapGame.onLoad()` a montré que `parent != null` est le meilleur indicateur exploitable dans ce seam sans modifier les composants acteur. Le comportement reste strict sur `isGameplayPresent` pour les PNJ.

## 23. Contenu complet des fichiers créés/modifiés

### packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart

```dart
import 'package:map_core/map_core.dart';

import 'actor_contact_shadow_runtime_resolver.dart';
import 'shadow_runtime_instruction_collection.dart';

const ResolvedShadowConfig kDefaultRuntimeActorContactShadowConfig =
    ResolvedShadowConfig(
  shadowProfileId: 'runtime_actor_contact_default',
  mode: ShadowCasterMode.contactBlob,
  renderPass: ShadowRenderPass.actorContact,
  offsetX: 0,
  offsetY: 0,
  scaleX: 1,
  scaleY: 1,
  opacity: 0.35,
  colorHexRgb: '000000',
  softnessMode: ShadowSoftnessMode.hardEdge,
);

final class RuntimeActorContactShadowSource {
  RuntimeActorContactShadowSource({
    required this.id,
    required this.footWorldX,
    required this.footWorldY,
    required this.visualWidth,
    required this.visualHeight,
    this.isVisible = true,
  }) {
    _validateFinite(footWorldX, 'footWorldX');
    _validateFinite(footWorldY, 'footWorldY');
    _validatePositiveFinite(visualWidth, 'visualWidth');
    _validatePositiveFinite(visualHeight, 'visualHeight');
  }

  final String id;
  final double footWorldX;
  final double footWorldY;
  final double visualWidth;
  final double visualHeight;
  final bool isVisible;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimeActorContactShadowSource &&
          other.id == id &&
          other.footWorldX == footWorldX &&
          other.footWorldY == footWorldY &&
          other.visualWidth == visualWidth &&
          other.visualHeight == visualHeight &&
          other.isVisible == isVisible;

  @override
  int get hashCode => Object.hash(
        id,
        footWorldX,
        footWorldY,
        visualWidth,
        visualHeight,
        isVisible,
      );
}

ShadowRuntimeInstructionCollection buildRuntimeActorContactShadowCollection({
  required Iterable<RuntimeActorContactShadowSource> sources,
  ResolvedShadowConfig resolvedConfig = kDefaultRuntimeActorContactShadowConfig,
}) {
  final inputs = <ActorContactShadowRuntimeInput>[];
  for (final source in sources) {
    if (!source.isVisible) {
      continue;
    }
    inputs.add(
      ActorContactShadowRuntimeInput(
        resolvedConfig: resolvedConfig,
        metrics: ActorContactShadowRuntimeMetrics(
          footWorldX: source.footWorldX,
          footWorldY: source.footWorldY,
          visualWidth: source.visualWidth,
          visualHeight: source.visualHeight,
        ),
      ),
    );
  }
  return ShadowRuntimeInstructionCollection(
    instructions: resolveActorContactShadowRuntimeInstructions(inputs),
  );
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'RuntimeActorContactShadowSource.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'RuntimeActorContactShadowSource.$name must be greater than 0',
    );
  }
}
```

### packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_actor_contact_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('runtime actor contact shadow collection', () {
    test('default actor contact config is an internal V0 contact blob', () {
      expect(
        kDefaultRuntimeActorContactShadowConfig.shadowProfileId,
        'runtime_actor_contact_default',
      );
      expect(
        kDefaultRuntimeActorContactShadowConfig.mode,
        ShadowCasterMode.contactBlob,
      );
      expect(
        kDefaultRuntimeActorContactShadowConfig.renderPass,
        ShadowRenderPass.actorContact,
      );
      expect(kDefaultRuntimeActorContactShadowConfig.opacity, 0.35);
      expect(kDefaultRuntimeActorContactShadowConfig.colorHexRgb, '000000');
      expect(
        kDefaultRuntimeActorContactShadowConfig.softnessMode,
        ShadowSoftnessMode.hardEdge,
      );
    });

    test('visible source creates one actorContact instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, hasLength(1));
      final instruction = collection.actorContact.single;
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
      expect(instruction.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.opacity, 0.35);
      expect(instruction.colorHexRgb, '000000');
      expect(instruction.width, closeTo(19.2, 0.0001));
      expect(instruction.height, closeTo(8.64, 0.0001));
      expect(instruction.worldLeft, closeTo(90.4, 0.0001));
      expect(instruction.worldTop, closeTo(195.68, 0.0001));
    });

    test('invisible source creates no instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'hidden',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
            isVisible: false,
          ),
        ],
      );

      expect(collection, ShadowRuntimeInstructionCollection());
      expect(collection.actorContact, isEmpty);
    });

    test('multiple sources preserve order', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'first',
            footWorldX: 10,
            footWorldY: 20,
            visualWidth: 10,
            visualHeight: 10,
          ),
          RuntimeActorContactShadowSource(
            id: 'second',
            footWorldX: 30,
            footWorldY: 40,
            visualWidth: 10,
            visualHeight: 10,
          ),
        ],
      );

      expect(collection.actorContact, hasLength(2));
      expect(collection.actorContact[0].worldLeft, closeTo(7, 0.0001));
      expect(collection.actorContact[1].worldLeft, closeTo(27, 0.0001));
    });

    test('equal sources are not deduplicated', () {
      final source = RuntimeActorContactShadowSource(
        id: 'same',
        footWorldX: 10,
        footWorldY: 20,
        visualWidth: 10,
        visualHeight: 10,
      );

      final collection = buildRuntimeActorContactShadowCollection(
        sources: [source, source],
      );

      expect(collection.actorContact, hasLength(2));
      expect(collection.actorContact[0], collection.actorContact[1]);
    });

    test('opacity zero config still creates a retained instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        resolvedConfig: _resolvedConfig(opacity: 0),
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(collection.actorContact, hasLength(1));
      expect(collection.actorContact.single.opacity, 0);
    });

    test('none config creates no instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none),
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('groundStatic config is rejected by the actor resolver', () {
      expect(
        () => buildRuntimeActorContactShadowCollection(
          resolvedConfig: _resolvedConfig(
            renderPass: ShadowRenderPass.groundStatic,
          ),
          sources: [
            RuntimeActorContactShadowSource(
              id: 'player',
              footWorldX: 100,
              footWorldY: 200,
              visualWidth: 32,
              visualHeight: 48,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('source rejects invalid runtime metrics', () {
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: double.nan,
          footWorldY: 200,
          visualWidth: 32,
          visualHeight: 48,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: 100,
          footWorldY: double.infinity,
          visualWidth: 32,
          visualHeight: 48,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: 100,
          footWorldY: 200,
          visualWidth: 0,
          visualHeight: 48,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: 100,
          footWorldY: 200,
          visualWidth: 32,
          visualHeight: double.nan,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('source has value equality', () {
      final a = RuntimeActorContactShadowSource(
        id: 'same',
        footWorldX: 1,
        footWorldY: 2,
        visualWidth: 3,
        visualHeight: 4,
      );
      final b = RuntimeActorContactShadowSource(
        id: 'same',
        footWorldX: 1,
        footWorldY: 2,
        visualWidth: 3,
        visualHeight: 4,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('returned collection exposes immutable lists', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(
        () => collection.instructions.add(collection.instructions.single),
        throwsUnsupportedError,
      );
    });
  });
}

ResolvedShadowConfig _resolvedConfig({
  ShadowCasterMode mode = ShadowCasterMode.contactBlob,
  ShadowRenderPass renderPass = ShadowRenderPass.actorContact,
  double opacity = 0.35,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'runtime_actor_contact_test',
    mode: mode,
    renderPass: renderPass,
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 1,
    opacity: opacity,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}
```

### packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
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

  group('runtime actor contact shadow host integration', () {
    test('PlayableMapGame wires an internal provider to background only',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final layers = game.world.children.whereType<MapLayersComponent>();
      final background = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
      final foreground = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );

      expect(game.shadowCollectionProvider, isNull);
      expect(background.shadowCollectionProvider, isNotNull);
      expect(foreground.shadowCollectionProvider, isNull);
      expect(background.shadowCollectionProvider!(), isNotNull);
      expect(background.shadowCollectionProvider!()!.actorContact, isNotEmpty);
    });

    test('internal provider draws an actor contact shadow under the player',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final collection = background.shadowCollectionProvider!()!;
      final instruction = collection.actorContact.single;
      final image = await _render(background, width: 96, height: 96);
      final centerX = (instruction.worldLeft + instruction.width / 2).round();
      final centerY = (instruction.worldTop + instruction.height / 2).round();

      expect((await pixelAt(image, centerX, centerY))[3], greaterThan(0));
    });

    test('NPC actors are included when present', () async {
      final game = PlayableMapGame(
        bundle: _bundle(includeNpc: true),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final collection = background.shadowCollectionProvider!()!;

      expect(collection.actorContact, hasLength(2));
    });

    test('external provider stays priority when internal shadows are disabled',
        () async {
      var calls = 0;
      ShadowRuntimeInstructionCollection? provider() {
        calls += 1;
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
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final foreground =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.foreground,
              );
      final image = await _render(background, width: 96, height: 96);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(calls, 1);
      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('disabled internal shadows do not install an internal provider',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final background =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.background,
              );
      final foreground =
          game.world.children.whereType<MapLayersComponent>().singleWhere(
                (layer) => layer.renderPass == MapLayerRenderPass.foreground,
              );

      expect(background.shadowCollectionProvider, isNull);
      expect(foreground.shadowCollectionProvider, isNull);
    });

    test('internal provider is scoped to the active map background', () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final activeProvider =
          game.debugShadowCollectionProviderForMap('shadow-actor-test');
      final inactiveProvider =
          game.debugShadowCollectionProviderForMap('connected-map');

      expect(activeProvider, isNotNull);
      expect(inactiveProvider, isNotNull);
      expect(activeProvider!(), isNotNull);
      expect(inactiveProvider!(), isNull);
    });

    test('internal provider can return a different collection after movement',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
      );

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      game.update(0);
      final provider =
          game.debugShadowCollectionProviderForMap('shadow-actor-test')!;
      final first = provider()!.actorContact.single;
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 1, y: 0),
        facing: Direction.south,
      );
      game.update(0);
      final second = provider()!.actorContact.single;

      expect(second.worldLeft, isNot(first.worldLeft));
    });

    test('RuntimeMapGame remains passive for actor shadows', () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(96, 96));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });
  });
}

RuntimeMapBundle _bundle({bool includeNpc = false}) {
  final entities = <MapEntity>[
    const MapEntity(
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
    if (includeNpc)
      const MapEntity(
        id: 'npc-one',
        name: 'NPC One',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 1),
        npc: MapEntityNpcData(
          characterId: 'npc',
        ),
      ),
  ];
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Actor Contact Shadow Test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      characters: const <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 2,
          frameHeight: 2,
        ),
        ProjectCharacterEntry(
          id: 'npc',
          name: 'NPC',
          tilesetId: 'npc',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: MapData(
      id: 'shadow-actor-test',
      name: 'Shadow Actor Test',
      size: const GridSize(width: 4, height: 4),
      layers: const [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: entities,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-actor-contact-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
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

Pour `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`, le fichier est volumineux; le diff complet réel du lot et les sections modifiées complètes sont inclus ci-dessous.

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 50959a58..40a18b6d 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -59,7 +59,9 @@ import '../../application/story_flags_manager.dart';
 import '../../application/trainer_battle_request.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
 import '../../infrastructure/tile_image_loader.dart';
+import '../../shadow/runtime_actor_contact_shadow_collection.dart';
 import '../../shadow/shadow_runtime_collection_provider.dart';
+import '../../shadow/shadow_runtime_instruction_collection.dart';
 import 'battle_bag_menu_model.dart';
 import 'battle_bag_item_icon_resolver.dart';
 import 'battle_overlay_component.dart';
@@ -122,6 +124,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     RuntimeMapBundleLoader? runtimeMapBundleLoader,
     RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
     this.shadowCollectionProvider,
+    this.enableActorContactShadows = true,
   })  : _bundle = bundle,
         _gameState = normalizeLoadedGameState(
           saveData == null
@@ -154,10 +157,12 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
   final List<RuntimeCutsceneAsset> runtimeCutscenes;
   final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
+  final bool enableActorContactShadows;
   RuntimeMapBundle _bundle;
   GameState _gameState;
   late GameplayWorldState _world;
   late PlayerComponent _player;
+  bool _actorContactShadowRuntimeReady = false;
   String _activeMapId = '';
   String? _previousMapId;
   _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
@@ -174,6 +179,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   WarpTransitionOverlayComponent? _warpTransitionOverlay;
   TextComponent? _notification;
   final List<OverworldActorComponent> _npcActors = [];
+  final ShadowRuntimeCollectionController _actorShadowCollectionController =
+      ShadowRuntimeCollectionController();
   final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
   final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
   final RuntimeDialogueSessionLoader _dialogueSessionLoader;
@@ -552,6 +559,13 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     return _player.footPoint - debugCameraWorldTopLeft;
   }
 
+  @visibleForTesting
+  ShadowRuntimeInstructionCollectionProvider?
+      debugShadowCollectionProviderForMap(
+    String mapId,
+  ) =>
+          _shadowCollectionProviderForMap(mapId);
+
   @visibleForTesting
   Vector2 get debugMapOriginWorldTopLeft => _player.mapOrigin;
 
@@ -1302,6 +1316,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       mapOrigin: _originPixelsOf(rootMap),
     );
     await world.add(_player);
+    _actorContactShadowRuntimeReady = true;
+    _refreshActorContactShadowCollection();
     _syncGameStateFromWorld();
     _configureCameraViewport();
     _syncCameraToPlayer();
@@ -1507,6 +1523,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     _runtimeClockMs += dt * 1000;
     _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
     _updateActorDepthOrdering();
+    _refreshActorContactShadowCollection();
     final pendingConnectionEntryAnimation = _pendingConnectionEntryAnimation;
     if (pendingConnectionEntryAnimation != null &&
         pendingConnectionEntryAnimation.holdInitialCameraFrame) {
@@ -1609,6 +1626,72 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
   }
 
+  ShadowRuntimeInstructionCollectionProvider? _shadowCollectionProviderForMap(
+    String mapId,
+  ) {
+    final externalProvider = shadowCollectionProvider;
+    if (externalProvider != null) {
+      return externalProvider;
+    }
+    if (!enableActorContactShadows) {
+      return null;
+    }
+    return () => _provideActorContactShadowCollectionForMap(mapId);
+  }
+
+  ShadowRuntimeInstructionCollection?
+      _provideActorContactShadowCollectionForMap(
+    String mapId,
+  ) {
+    if (mapId != _activeMapId) {
+      return null;
+    }
+    return _actorShadowCollectionController.provide();
+  }
+
+  void _refreshActorContactShadowCollection() {
+    if (shadowCollectionProvider != null ||
+        !enableActorContactShadows ||
+        !_actorContactShadowRuntimeReady) {
+      _actorShadowCollectionController.clear();
+      return;
+    }
+    _actorShadowCollectionController.replace(
+      buildRuntimeActorContactShadowCollection(
+        sources: _actorContactShadowSources(),
+      ),
+    );
+  }
+
+  List<RuntimeActorContactShadowSource> _actorContactShadowSources() {
+    final sources = <RuntimeActorContactShadowSource>[
+      RuntimeActorContactShadowSource(
+        id: 'player',
+        footWorldX: _player.footPoint.x,
+        footWorldY: _player.footPoint.y,
+        visualWidth: _player.size.x,
+        visualHeight: _player.size.y,
+        isVisible: _player.parent != null,
+      ),
+    ];
+    final active = _loadedMapsById[_activeMapId];
+    if (active != null) {
+      for (final actor in active.npcActors) {
+        sources.add(
+          RuntimeActorContactShadowSource(
+            id: actor.character.id,
+            footWorldX: actor.position.x + actor.size.x / 2,
+            footWorldY: actor.depthSortY,
+            visualWidth: actor.size.x,
+            visualHeight: actor.size.y,
+            isVisible: actor.parent != null && actor.isGameplayPresent,
+          ),
+        );
+      }
+    }
+    return sources;
+  }
+
   bool _isMovementControl(RuntimeInputControl control) {
     return control == RuntimeInputControl.up ||
         control == RuntimeInputControl.down ||
@@ -6395,7 +6478,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       tileImagesByTilesetId: tileImagesById,
       showCollisionOverlay: _showCollisionOverlay,
       npcMapPresencePredicate: npcPred,
-      shadowCollectionProvider: shadowCollectionProvider,
+      shadowCollectionProvider: _shadowCollectionProviderForMap(bundle.map.id),
     );
     backgroundLayers.position = _originPixels(
       originCellX: originCellX,
```

## 24. Diffs complets ou équivalents /dev/null pour fichiers créés

Les trois nouveaux fichiers Dart sont présentés en contenu complet dans la section 23. Pour chaque fichier créé, ce contenu complet correspond à l’équivalent `/dev/null -> nouveau fichier`.

Le rapport lui-même est ce fichier :

```text
reports/shadows/shadow_lot_19_runtime_actor_contact_shadow_collection.md
```

Il est créé par Shadow-19 et contient l’Evidence Pack demandé.
