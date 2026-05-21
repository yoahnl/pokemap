# Shadow Lot 18 — Runtime Shadow Collection Provider Host Wiring V0

## 1. Résumé du lot

Shadow-18 ajoute un seam runtime pour fournir une `ShadowRuntimeInstructionCollection` déjà prête au host runtime, puis à `MapLayersComponent`.

Le lot :

- déplace le typedef provider Shadow dans un fichier neutre `map_runtime/lib/src/shadow` ;
- ajoute un `ShadowRuntimeCollectionController` minimal ;
- ajoute un provider optionnel à `RuntimeMapGame` ;
- ajoute un provider optionnel à `PlayableMapGame` ;
- transmet le provider uniquement au `MapLayersComponent` background ;
- ne génère aucune instruction Shadow ;
- n'appelle aucun resolver Shadow ;
- ne lit pas `MapData`, `ProjectManifest`, `ProjectElementEntry` ou `MapPlacedElement` pour produire des ombres ;
- ne modifie pas `PlayerComponent`, `OverworldActorComponent` ou `PlacedElementOcclusionPatchComponent` ;
- ne crée aucun nouveau `Flame Component`.

## 2. Design retenu

Design validé avant implémentation :

- `MapLayersComponent` garde le comportement Shadow-17 : il consomme une collection prête et appelle le provider une seule fois par render background.
- Le typedef `ShadowRuntimeInstructionCollectionProvider` sort de `map_layers_component.dart` pour devenir partageable par le host runtime.
- `RuntimeMapGame` et `PlayableMapGame` acceptent un provider optionnel, sans imposer de controller.
- `PlayableMapGame` transmet ce provider uniquement aux layers background.
- Le foreground pass ne reçoit pas de provider.
- Le controller reste un holder mutable extrêmement simple : `current`, `provide`, `replace`, `clear`.
- `replace(null)` est traité comme un clear.

## 3. Fichiers créés

Créés par Shadow-18 :

- `packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart`
- `reports/shadows/shadow_lot_18_runtime_shadow_collection_provider_host_wiring.md`

## 4. Fichiers modifiés

Modifiés par Shadow-18 :

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart`

Note factuelle : `dart format` a aussi compacté une ligne déjà existante dans `map_layers_component.dart` autour de `subtileSalt`. Cette ligne figure dans le diff complet ci-dessous.

## 5. Fichiers non modifiés explicitement

Non modifiés par Shadow-18 :

- `packages/map_core/**`
- `packages/map_editor/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
- `packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart`
- `packages/map_runtime/lib/map_runtime.dart`

Fichiers déjà présents avant Shadow-18 :

- les fichiers Shadow-11 à Shadow-17 sous `packages/map_runtime/lib/src/shadow` et `packages/map_runtime/test/shadow` ;
- `MapLayersComponent`, qui avait déjà l'intégration renderer Shadow-17 ;
- `RuntimeMapGame` et `PlayableMapGame`, qui existaient déjà comme hosts runtime.

## 6. API ajoutée

```dart
typedef ShadowRuntimeInstructionCollectionProvider
    = ShadowRuntimeInstructionCollection? Function();

final class ShadowRuntimeCollectionController {
  ShadowRuntimeCollectionController([
    ShadowRuntimeInstructionCollection? initialCollection,
  ]);

  ShadowRuntimeInstructionCollection? get current;

  ShadowRuntimeInstructionCollection? provide();

  void replace(ShadowRuntimeInstructionCollection? collection);

  void clear();
}
```

Ajouts host :

```dart
RuntimeMapGame({
  required RuntimeMapBundle bundle,
  ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider,
});

PlayableMapGame({
  ...
  ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider,
});
```

Le provider n'est pas exporté depuis `packages/map_runtime/lib/map_runtime.dart`. Audit : les autres briques Shadow runtime V0 restent internes, et `flutter analyze lib/map_runtime.dart lib/src/shadow/shadow_runtime_collection_provider.dart lib/src/presentation/flame/runtime_map_game.dart lib/src/presentation/flame/playable_map_game.dart` passe sans issue.

## 7. Câblage host réalisé

`RuntimeMapGame` :

- reçoit `ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider` ;
- expose le champ en lecture ;
- transmet le provider au `MapLayersComponent` unique monté dans `onLoad`.

`PlayableMapGame` :

- reçoit `ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider` ;
- expose le champ en lecture ;
- transmet le provider au `MapLayersComponent` background dans `_mountLoadedMap` ;
- ne transmet aucun provider au `MapLayersComponent` foreground.

Le provider reste optionnel. Aucun provider interne n'est créé par défaut.

## 8. Pourquoi le lot ne génère pas encore d'ombres

Shadow-18 branche seulement le tuyau entre host runtime et `MapLayersComponent`.

Il ne fabrique pas la collection :

- aucun appel à `resolveShadowConfig` ;
- aucun appel à `resolveShadowRuntimeInstruction` ;
- aucun appel à `resolveActorContactShadowRuntimeInstruction` ;
- aucun appel à `resolveStaticPlacedElementShadowRuntimeInstruction` ;
- aucun appel à `collectShadowRuntimeInstructions` depuis le host ;
- aucune inspection des acteurs ;
- aucune inspection des éléments placés ;
- aucune lecture manifest/map pour produire des ombres.

Une ombre ne devient visible que si un test ou un appelant injecte explicitement une collection contenant déjà des instructions.

## 9. Tests ajoutés

Ajoutés :

- `packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart`
  - controller vide -> null ;
  - controller initialisé -> collection ;
  - `replace(collection)` met à jour `current` et `provide` ;
  - `replace(null)` remet à null ;
  - `clear()` remet à null ;
  - aucune mutation, aucun tri, aucun culling, aucune déduplication, aucune suppression opacity 0.

- `packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart`
  - `RuntimeMapGame` constructible sans provider ;
  - `RuntimeMapGame` transmet le provider au layer monté ;
  - `RuntimeMapGame` peut utiliser une collection différente entre deux renders ;
  - `PlayableMapGame` constructible sans provider ;
  - `PlayableMapGame` transmet le provider uniquement aux background layers ;
  - foreground sans provider et sans appel provider.

Modifié :

- `packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart`
  - l'import du typedef pointe maintenant vers `shadow_runtime_collection_provider.dart`.

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
dart format packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_collection_provider_test.dart test/shadow/shadow_runtime_provider_host_wiring_test.dart test/shadow/shadow_runtime_renderer_integration_test.dart
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame/map_layers_component.dart lib/src/presentation/flame/runtime_map_game.dart lib/src/presentation/flame/playable_map_game.dart test/shadow
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame test/shadow
cd packages/map_runtime && flutter test
cd packages/map_runtime && flutter analyze lib/map_runtime.dart lib/src/shadow/shadow_runtime_collection_provider.dart lib/src/presentation/flame/runtime_map_game.dart lib/src/presentation/flame/playable_map_game.dart
cd packages/map_runtime && rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
cd packages/map_runtime && rg -n "resolveShadowConfig|resolveShadowRuntimeInstruction|resolveActorContactShadow|resolveStaticPlacedElementShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
cd packages/map_runtime && rg -n "ProjectManifest|ProjectElementEntry|MapPlacedElement|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" lib/src/presentation/flame lib/src/shadow
cd packages/map_runtime && rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveShadowConfig|resolveShadowRuntimeInstruction|resolveActorContactShadow|resolveStaticPlacedElementShadow|collectShadowRuntimeInstructions"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent|ProjectManifest|ProjectElementEntry|MapPlacedElement"
git diff --check
git diff --stat
git status --short --untracked-files=all
git diff --name-status
```

Commandes Git write non lancées :

- `git add`
- `git commit`
- `git push`
- `git reset`
- `git checkout`
- `git restore`
- `git stash`
- `git merge`
- `git rebase`
- `git tag`

## 11. Résultats complets des tests ciblés

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_collection_provider_test.dart test/shadow/shadow_runtime_provider_host_wiring_test.dart test/shadow/shadow_runtime_renderer_integration_test.dart
```

Sortie complète utile :

```text
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController starts empty and provides null by default
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController provides the initial collection without changing it
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController replace updates current and provide
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController replace can change collection between two provider calls
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController replace null clears the collection
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController clear removes the current collection
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart: ShadowRuntimeCollectionController does not sort cull deduplicate or remove opacity zero instructions
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration renders without shadow provider as existing no-op behavior
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration treats a null shadow collection as a no-op
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration treats an empty shadow collection as a no-op
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration renders groundStatic and actorContact shadows after surfaces
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration renders shadows before tile and placed element sprites
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration renders shadows before project element entities
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration calls the shadow collection provider once per render
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration uses a fresh provider collection on each render
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart: MapLayersComponent shadow renderer integration does not render shadows in the foreground pass
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart: runtime shadow provider host wiring RuntimeMapGame remains constructible without a provider
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart: runtime shadow provider host wiring RuntimeMapGame passes the provider to its mounted map layer
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart: runtime shadow provider host wiring RuntimeMapGame can use a different collection on later renders
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart: runtime shadow provider host wiring PlayableMapGame remains constructible without a provider
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart: runtime shadow provider host wiring PlayableMapGame passes the provider only to background layers
[runtime] Spawn resolution failed (GameplaySpawnResolutionException: No player spawn found: set defaultSpawnId on the map metadata, or add a spawn entity with role playerStart), falling back to (0,0)
00:00 +21: All tests passed!
```

La ligne `[runtime] Spawn resolution failed ... falling back to (0,0)` vient du fixture minimal du test `PlayableMapGame`; elle ne correspond pas à un échec.

## 12. Ligne finale exacte des tests globaux

`test/shadow` :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Résultat final exact :

```text
00:01 +144: All tests passed!
```

`flutter test` complet `map_runtime` :

```bash
cd packages/map_runtime && flutter test
```

Résultat final exact :

```text
00:18 +1065: All tests passed!
```

Analyse ciblée Shadow-18 :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame/map_layers_component.dart lib/src/presentation/flame/runtime_map_game.dart lib/src/presentation/flame/playable_map_game.dart test/shadow
```

Résultat final exact :

```text
No issues found! (ran in 3.1s)
```

Analyse barrel/hosts :

```bash
cd packages/map_runtime && flutter analyze lib/map_runtime.dart lib/src/shadow/shadow_runtime_collection_provider.dart lib/src/presentation/flame/runtime_map_game.dart lib/src/presentation/flame/playable_map_game.dart
```

Résultat final exact :

```text
No issues found! (ran in 1.2s)
```

Analyse large demandée :

```bash
cd packages/map_runtime && flutter analyze lib/src/shadow lib/src/presentation/flame test/shadow
```

Résultat final exact :

```text
152 issues found. (ran in 1.8s)
```

Classification : dette préexistante hors lot. Les 152 infos sont toutes des `prefer_const_constructors` dans `lib/src/presentation/flame/battle_move_visual_recipe_library.dart`. Ce fichier n'est pas modifié par Shadow-18.

## 13. Résultats des scans anti-dérive

AGENTS :

```bash
find .. -name AGENTS.md -print
```

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Scan composants :

```bash
cd packages/map_runtime && rg -n "ShadowLayerComponent|class .*Shadow.*Component|extends .*Component" lib/src/shadow lib/src/presentation/flame test/shadow
```

Résultat : occurrences préexistantes de composants Flame existants, aucun `ShadowLayerComponent`, aucun nouveau composant Shadow.

```text
lib/src/presentation/flame/battle_fx_sprite_sheet_component.dart:6:final class BattleFxSpriteSheetComponent extends PositionComponent {
lib/src/presentation/flame/warp_transition_overlay_component.dart:6:class WarpTransitionOverlayComponent extends PositionComponent {
lib/src/presentation/flame/encounter_overlay_component.dart:6:class EncounterOverlayComponent extends PositionComponent {
lib/src/presentation/flame/battle_rmxp_animation_component.dart:53:final class BattleRmxpAnimationComponent extends PositionComponent {
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:26:class PlacedElementOcclusionPatchComponent extends PositionComponent {
lib/src/presentation/flame/battle_command_panel_component.dart:83:class BattleCommandPanelComponent extends PositionComponent with DragCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:1848:class _BattleRootButtonComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:1942:class _BattleChoiceCardComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:2044:class _BattlePartyEntryComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:2179:class _BattleMedicineTargetEntryComponent extends PositionComponent
lib/src/presentation/flame/battle_command_panel_component.dart:2315:class _BattleBagEntryComponent extends PositionComponent with TapCallbacks {
lib/src/presentation/flame/battle_command_panel_component.dart:2900:class _BattleUtilityButtonComponent extends PositionComponent
lib/src/presentation/flame/battle_scene_hud_component.dart:16:class BattleSceneHudComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:35:final class BattleFxLayerComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:670:final class _BattleScreenFlashComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:705:final class _BattleBarrierPulseComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:898:final class _BattleWeatherAmbientComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_layer_component.dart:960:final class _BattlePseudoWeatherAmbientComponent extends PositionComponent {
lib/src/presentation/flame/battle_sdk_particle_component.dart:6:final class BattleSdkParticleComponent extends PositionComponent {
lib/src/presentation/flame/battle_debug_panel_component.dart:12:class BattleDebugPanelComponent extends PositionComponent {
lib/src/presentation/flame/battle_overlay_component.dart:421:class BattleOverlayComponent extends PositionComponent {
lib/src/presentation/flame/battle_scene_backdrop_component.dart:19:class BattleSceneBackdropComponent extends PositionComponent {
lib/src/presentation/flame/battle_scene_combatant_component.dart:12:class BattleSceneCombatantComponent extends PositionComponent {
lib/src/presentation/flame/battle_transition_overlay_component.dart:7:class BattleTransitionOverlayComponent extends PositionComponent {
lib/src/presentation/flame/battle_fx_sprite_component.dart:8:final class BattleFxSpriteComponent extends PositionComponent {
lib/src/presentation/flame/overworld_actor_component.dart:8:class OverworldActorComponent extends PositionComponent {
lib/src/presentation/flame/player_component.dart:18:class PlayerComponent extends PositionComponent {
lib/src/presentation/flame/dialogue_overlay_component.dart:8:class DialogueOverlayComponent extends PositionComponent {
lib/src/presentation/flame/map_layers_component.dart:35:class MapLayersComponent extends PositionComponent {
```

Scan resolver/collector :

```bash
cd packages/map_runtime && rg -n "resolveShadowConfig|resolveShadowRuntimeInstruction|resolveActorContactShadow|resolveStaticPlacedElementShadow|collectShadowRuntimeInstructions" lib/src/presentation/flame lib/src/shadow
```

Résultat : occurrences attendues dans les fichiers Shadow spécialisés existants, aucune occurrence dans `lib/src/presentation/flame`.

```text
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:91:ShadowRuntimeRenderInstruction? resolveActorContactShadowRuntimeInstruction(
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:109:  return resolveShadowRuntimeInstruction(
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:118:    resolveActorContactShadowRuntimeInstructions(
lib/src/shadow/actor_contact_shadow_runtime_resolver.dart:123:    final instruction = resolveActorContactShadowRuntimeInstruction(input);
lib/src/shadow/shadow_runtime_resolver.dart:69:ShadowRuntimeRenderInstruction? resolveShadowRuntimeInstruction(
lib/src/shadow/shadow_runtime_resolver.dart:96:List<ShadowRuntimeRenderInstruction> resolveShadowRuntimeInstructions(
lib/src/shadow/shadow_runtime_resolver.dart:101:    final instruction = resolveShadowRuntimeInstruction(input);
lib/src/shadow/shadow_runtime_instruction_collection.dart:110:ShadowRuntimeInstructionCollection collectShadowRuntimeInstructions(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:103:    resolveStaticPlacedElementShadowRuntimeInstruction(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:122:  return resolveShadowRuntimeInstruction(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:131:    resolveStaticPlacedElementShadowRuntimeInstructions(
lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart:137:        resolveStaticPlacedElementShadowRuntimeInstruction(input);
```

Scan manifest/map/actors :

```bash
cd packages/map_runtime && rg -n "ProjectManifest|ProjectElementEntry|MapPlacedElement|PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent" lib/src/presentation/flame lib/src/shadow
```

Résultat : occurrences préexistantes dans le runtime Flame. Shadow-18 ajoute seulement le provider host; les diff-only scans ci-dessous confirment qu'aucune nouvelle occurrence interdite n'est ajoutée.

Scan image/blur/z :

```bash
cd packages/map_runtime && rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex" lib/src/presentation/flame lib/src/shadow
```

Résultat : occurrences préexistantes de rendu sprite/image dans les composants runtime existants. Shadow-18 n'en ajoute aucune.

```text
lib/src/presentation/flame/battle_fx_sprite_sheet_component.dart:138:    canvas.drawImageRect(
lib/src/presentation/flame/battle_scene_combatant_component.dart:520:    canvas.drawImageRect(image, inputSubrect, outputSubrect, _spritePaint());
lib/src/presentation/flame/battle_scene_combatant_component.dart:564:    canvas.drawImageRect(
lib/src/presentation/flame/battle_rmxp_animation_component.dart:178:      canvas.drawImageRect(
lib/src/presentation/flame/battle_scene_backdrop_component.dart:153:    canvas.drawImageRect(image, inputSubrect, outputSubrect, Paint());
lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:147:        canvas.drawImageRect(tileImage, src, dst, paint);
lib/src/presentation/flame/battle_command_panel_component.dart:1791:  canvas.drawImageRect(
lib/src/presentation/flame/overworld_actor_component.dart:271:    image.drawImageRect(
lib/src/presentation/flame/map_layers_component.dart:388:      image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:471:    image.drawImageRect(
lib/src/presentation/flame/map_layers_component.dart:599:        image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:677:      image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:1020:    image.drawImageRect(canvas, src, dst, paint);
lib/src/presentation/flame/map_layers_component.dart:1218:    tilesetImage.drawImageRect(
lib/src/presentation/flame/map_layers_component.dart:1543:    tilesetImage.drawImageRect(
```

Diff-only resolver/collector :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "resolveShadowConfig|resolveShadowRuntimeInstruction|resolveActorContactShadow|resolveStaticPlacedElementShadow|collectShadowRuntimeInstructions"
```

Résultat :

```text
exit code 1, stdout vide
```

Diff-only image/blur/z :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|customShadowSprite|shadowTilesetId|shadowSource|WorldLightState|ShadowLightProfile|zOrder|zIndex"
```

Résultat :

```text
exit code 1, stdout vide
```

Diff-only manifest/map/actors :

```bash
git diff -U0 -- packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/shadow | rg -n "PlayerComponent|OverworldActorComponent|PlacedElementOcclusionPatchComponent|ProjectManifest|ProjectElementEntry|MapPlacedElement"
```

Résultat :

```text
exit code 1, stdout vide
```

`git diff --check` :

```text
exit code 0, stdout vide
```

## 14. git status initial

Commande initiale avant les edits Shadow-18 :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
exit code 0, stdout vide
```

## 15. git status final

Résultat final confirmé après création de ce rapport :

```text
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
 M packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
?? packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart
?? packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart
?? packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart
?? reports/shadows/shadow_lot_18_runtime_shadow_collection_provider_host_wiring.md
```

## 16. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat :

```text
 .../lib/src/presentation/flame/map_layers_component.dart          | 8 ++------
 .../map_runtime/lib/src/presentation/flame/playable_map_game.dart | 4 ++++
 .../map_runtime/lib/src/presentation/flame/runtime_map_game.dart  | 8 +++++++-
 .../test/shadow/shadow_runtime_renderer_integration_test.dart     | 1 +
 4 files changed, 14 insertions(+), 7 deletions(-)
```

`git diff --stat` liste les modifications suivies. Les fichiers créés non suivis apparaissent dans `git status final` et leurs diffs `/dev/null` complets sont inclus en section 22.

## 17. Non-objectifs respectés

- Aucun commit effectué.
- Aucun `git add`.
- Aucun `git commit`.
- Aucun `git push`.
- Aucun reset/checkout/restore/stash/merge/rebase/tag.
- Aucun `map_core` modifié.
- Aucun `map_editor` modifié.
- Aucun `map_gameplay` modifié.
- Aucun `map_battle` modifié.
- Aucun `PlayerComponent` modifié.
- Aucun `OverworldActorComponent` modifié.
- Aucun `PlacedElementOcclusionPatchComponent` modifié.
- Aucun `ShadowLayerComponent` créé.
- Aucun nouveau `Flame Component` créé.
- Aucun resolver Shadow appelé depuis le host.
- Aucun collector Shadow appelé depuis le host.
- Aucun tri ajouté.
- Aucun culling ajouté.
- Aucune déduplication ajoutée.
- Aucun `zOrder` ou `zIndex` ajouté.
- Aucun rendu image/atlas/blur ajouté.
- Aucune ombre générée automatiquement par défaut.

## 18. Risques / réserves

- Le provider est un seam interne V0 non exporté depuis `map_runtime.dart`. C'est cohérent avec les lots Shadow internes, mais si un host externe veut fournir une collection depuis l'API barrel seule, un futur lot devra décider d'exporter proprement les types Shadow runtime.
- `PlayableMapGame` transmet le même provider à chaque map background montée. C'est volontaire pour préparer des updates par frame, mais le prochain lot devra définir qui alimente la collection et à quelle fréquence.
- Le test host utilise des fixtures minimaux sans spawn joueur. Le runtime tombe alors sur `(0,0)` avec un log attendu; le test vérifie le wiring Shadow, pas la spawn policy.
- L'analyse large `lib/src/presentation/flame` reste rouge à cause de 152 infos préexistantes dans `battle_move_visual_recipe_library.dart`.

## 19. Auto-review finale

- Ai-je généré des instructions Shadow dans le host ? Non.
- Ai-je appelé un resolver Shadow ? Non.
- Ai-je lu `MapData` / `ProjectManifest` / `ProjectElementEntry` / `MapPlacedElement` pour produire des ombres ? Non.
- Ai-je modifié `PlayerComponent` / `OverworldActorComponent` ? Non.
- Ai-je créé un nouveau Flame Component ? Non.
- Ai-je conservé la compatibilité des constructeurs existants ? Oui, paramètres optionnels uniquement.
- Le provider peut-il être mis à jour entre deux renders ? Oui, testé avec `ShadowRuntimeCollectionController.replace(...)`.
- Le foreground pass peut-il appeler le provider ? Non, `PlayableMapGame` ne transmet pas le provider au foreground layer; test couvert.
- Le lot reste-t-il préparatoire, sans activer d'ombres par défaut ? Oui.

Problèmes réellement introduits par Shadow-18 en état final : aucun constaté par tests, analyses ciblées, scans diff-only et test runtime complet.

Problème rencontré pendant l'implémentation puis corrigé : le test host appelait `onLoad()` sans taille de jeu, ce qui déclenchait une erreur Flame `hasLayout`. Cause : setup test incomplet. Correction : `game.onGameResize(Vector2(32, 32))` avant `onLoad()`.

Dette préexistante hors lot : 152 infos `prefer_const_constructors` dans `battle_move_visual_recipe_library.dart`.

## 20. Regard critique sur le prompt

Le prompt demande un Evidence Pack très strict. C'est utile ici parce que le lot touche le host runtime, une zone où une petite fuite de responsabilité pourrait commencer à générer des ombres trop tôt.

Point de tension : l'analyse demandée sur tout `lib/src/presentation/flame` embarque un fichier de recettes battle très volumineux avec des infos `prefer_const_constructors` préexistantes. Pour rester dans le scope Shadow-18, ces infos sont documentées plutôt que corrigées.

Le choix de ne pas exporter le provider depuis `map_runtime.dart` est volontaire en V0. L'analyse ciblée du barrel passe; l'export public peut attendre un lot où l'API Shadow runtime deviendra officiellement consommable hors `src`.

## 21. Contenu complet des fichiers créés/modifiés

Le présent rapport est créé par Shadow-18; son contenu complet est ce document.

Pour les deux fichiers longs concernés, `map_layers_component.dart` fait 1784 lignes et `playable_map_game.dart` fait 7730 lignes. Toutes les lignes touchées sont couvertes par les sections modifiées complètes et le diff complet du lot en section 22.

### packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart

```dart
import 'shadow_runtime_instruction_collection.dart';

typedef ShadowRuntimeInstructionCollectionProvider
    = ShadowRuntimeInstructionCollection? Function();

final class ShadowRuntimeCollectionController {
  ShadowRuntimeCollectionController([
    ShadowRuntimeInstructionCollection? initialCollection,
  ]) : _current = initialCollection;

  ShadowRuntimeInstructionCollection? _current;

  ShadowRuntimeInstructionCollection? get current => _current;

  ShadowRuntimeInstructionCollection? provide() => _current;

  void replace(ShadowRuntimeInstructionCollection? collection) {
    _current = collection;
  }

  void clear() {
    _current = null;
  }
}
```

### packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeCollectionController', () {
    test('starts empty and provides null by default', () {
      final controller = ShadowRuntimeCollectionController();

      expect(controller.current, isNull);
      expect(controller.provide(), isNull);
    });

    test('provides the initial collection without changing it', () {
      final collection = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(renderPass: ShadowRenderPass.actorContact),
        ],
      );
      final controller = ShadowRuntimeCollectionController(collection);

      expect(controller.current, same(collection));
      expect(controller.provide(), same(collection));
      expect(controller.provide()!.actorContact, hasLength(1));
    });

    test('replace updates current and provide', () {
      final first = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: 'FF0000'),
        ],
      );
      final second = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: '00FF00'),
        ],
      );
      final controller = ShadowRuntimeCollectionController(first);

      controller.replace(second);

      expect(controller.current, same(second));
      expect(controller.provide(), same(second));
    });

    test('replace can change collection between two provider calls', () {
      final first = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: 'FF0000'),
        ],
      );
      final second = ShadowRuntimeInstructionCollection(
        instructions: [
          _shadow(colorHexRgb: '00FF00'),
        ],
      );
      final controller = ShadowRuntimeCollectionController(first);

      final before = controller.provide();
      controller.replace(second);
      final after = controller.provide();

      expect(before, same(first));
      expect(after, same(second));
    });

    test('replace null clears the collection', () {
      final controller = ShadowRuntimeCollectionController(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(),
          ],
        ),
      );

      controller.replace(null);

      expect(controller.current, isNull);
      expect(controller.provide(), isNull);
    });

    test('clear removes the current collection', () {
      final controller = ShadowRuntimeCollectionController(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(),
          ],
        ),
      );

      controller.clear();

      expect(controller.current, isNull);
      expect(controller.provide(), isNull);
    });

    test('does not sort cull deduplicate or remove opacity zero instructions',
        () {
      final zeroOpacity = _shadow(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 1,
        opacity: 0,
      );
      final firstGround = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
      );
      final duplicateGround = _shadow(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
      );
      final collection = ShadowRuntimeInstructionCollection(
        instructions: [
          zeroOpacity,
          firstGround,
          duplicateGround,
        ],
      );
      final controller = ShadowRuntimeCollectionController(collection);

      final provided = controller.provide();

      expect(provided, same(collection));
      expect(
          provided!.instructions, [zeroOpacity, firstGround, duplicateGround]);
      expect(provided.actorContact, [zeroOpacity]);
      expect(provided.groundStatic, [firstGround, duplicateGround]);
    });
  });
}

ShadowRuntimeRenderInstruction _shadow({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  String colorHexRgb = '000000',
  double worldLeft = 4,
  double opacity = 1,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}
```

### packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart

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
import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime shadow provider host wiring', () {
    test('RuntimeMapGame remains constructible without a provider', () {
      final game = RuntimeMapGame(bundle: _bundle());

      expect(game.shadowCollectionProvider, isNull);
    });

    test('RuntimeMapGame passes the provider to its mounted map layer',
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

      final game = RuntimeMapGame(
        bundle: _bundle(),
        shadowCollectionProvider: provider,
      );

      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;
      final image = await _render(layer);

      expect(layer.shadowCollectionProvider, same(provider));
      expect(calls, 1);
      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('RuntimeMapGame can use a different collection on later renders',
        () async {
      final controller = ShadowRuntimeCollectionController(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: 'FF0000'),
          ],
        ),
      );
      final game = RuntimeMapGame(
        bundle: _bundle(),
        shadowCollectionProvider: controller.provide,
      );

      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;
      final firstImage = await _render(layer);
      controller.replace(
        ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '00FF00'),
          ],
        ),
      );
      final secondImage = await _render(layer);

      expect(await pixelAt(firstImage, 16, 16), rgba(255, 0, 0, 255));
      expect(await pixelAt(secondImage, 16, 16), rgba(0, 255, 0, 255));
    });

    test('PlayableMapGame remains constructible without a provider', () {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
      );

      expect(game.shadowCollectionProvider, isNull);
    });

    test('PlayableMapGame passes the provider only to background layers',
        () async {
      var calls = 0;
      ShadowRuntimeInstructionCollection? provider() {
        calls += 1;
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        );
      }

      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        shadowCollectionProvider: provider,
      );

      game.onGameResize(Vector2(32, 32));
      await game.onLoad();
      final layers = game.world.children.whereType<MapLayersComponent>();
      final background = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
      final foreground = layers.singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );
      await _render(foreground);
      final backgroundImage = await _render(background);

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(calls, 1);
      expect(await pixelAt(backgroundImage, 16, 16), rgba(0, 0, 0, 255));
    });
  });
}

RuntimeMapBundle _bundle() {
  return surfaceTestBundle(
    tilesets: const <ProjectTilesetEntry>[],
    map: const MapData(
      id: 'shadow-host-test',
      name: 'Shadow Host Test',
      size: GridSize(width: 1, height: 1),
      layers: [
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(32, 32);
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

### packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart

```dart
import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/tile_image_loader.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import 'map_layers_component.dart';

class RuntimeMapGame extends FlameGame {
  RuntimeMapGame({
    required this.bundle,
    this.shadowCollectionProvider,
  });

  final RuntimeMapBundle bundle;
  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;

  @override
  Future<void> onLoad() async {
    final images = await loadTilesetImagesById(
      bundle.tilesetAbsolutePathsById,
      transparentColorByTilesetId: _transparentColorByTilesetId(
        bundle.manifest,
      ),
    );
    await world.add(
      MapLayersComponent(
        bundle: bundle,
        tileImagesByTilesetId: images,
        shadowCollectionProvider: shadowCollectionProvider,
      ),
    );
    _applyView();
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyView();
  }

  void _applyView() {
    final mw = bundle.map.size.width * bundle.cellWidth;
    final mh = bundle.map.size.height * bundle.cellHeight;
    camera.viewfinder.visibleGameSize = Vector2(mw, mh);
    camera.viewfinder.position = Vector2(mw / 2, mh / 2);
  }

  Map<String, TilesetTransparentColor> _transparentColorByTilesetId(
    ProjectManifest manifest,
  ) {
    return <String, TilesetTransparentColor>{
      for (final tileset in manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    };
  }
}
```

### packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

import '../surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapLayersComponent shadow renderer integration', () {
    test('renders without shadow provider as existing no-op behavior',
        () async {
      final component = await _componentWithSurface();

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('treats a null shadow collection as a no-op', () async {
      final component = await _componentWithSurface(
        shadowCollectionProvider: () => null,
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('treats an empty shadow collection as a no-op', () async {
      final component = await _componentWithSurface(
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 255, 255));
    });

    test('renders groundStatic and actorContact shadows after surfaces',
        () async {
      final component = await _componentWithSurface(
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(
              renderPass: ShadowRenderPass.groundStatic,
              colorHexRgb: 'FF0000',
            ),
            _shadow(
              renderPass: ShadowRenderPass.actorContact,
              colorHexRgb: '00FF00',
            ),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 255, 0, 255));
    });

    test('renders shadows before tile and placed element sprites', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          map: surfaceTestMap(
            layers: [
              surfaceTestLayer(),
              const MapLayer.tile(
                id: 'tile',
                name: 'Tile',
                tilesetId: 'base',
                tiles: [1],
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'base': await runtimeTilesetImage([const Color(0xFFFF0000)]),
        },
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
    });

    test('renders shadows before project element entities', () async {
      final component = MapLayersComponent(
        bundle: surfaceTestBundle(
          elements: [surfaceTestElement()],
          map: surfaceTestMap(
            layers: [surfaceTestLayer()],
            entities: const [
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 0, y: 0),
                editorVisual: MapEntityEditorVisual(
                  elementId: 'entity-prop',
                ),
              ),
            ],
          ),
        ),
        tileImagesByTilesetId: {
          'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
          'entity': await runtimeTilesetImage([const Color(0xFF800080)]),
        },
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(128, 0, 128, 255));
    });

    test('calls the shadow collection provider once per render', () async {
      var calls = 0;
      final component = await _componentWithSurface(
        shadowCollectionProvider: () {
          calls += 1;
          return ShadowRuntimeInstructionCollection(
            instructions: [
              _shadow(
                renderPass: ShadowRenderPass.groundStatic,
                colorHexRgb: 'FF0000',
              ),
              _shadow(
                renderPass: ShadowRenderPass.actorContact,
                colorHexRgb: '00FF00',
              ),
            ],
          );
        },
      );

      final image = await renderSurfaceTestComponent(component);

      expect(calls, 1);
      expect(await pixelAt(image, 16, 16), rgba(0, 255, 0, 255));
    });

    test('uses a fresh provider collection on each render', () async {
      var calls = 0;
      final component = await _componentWithSurface(
        shadowCollectionProvider: () {
          calls += 1;
          return ShadowRuntimeInstructionCollection(
            instructions: [
              _shadow(
                renderPass: ShadowRenderPass.groundStatic,
                colorHexRgb: calls == 1 ? 'FF0000' : '00FF00',
              ),
            ],
          );
        },
      );

      final firstImage = await renderSurfaceTestComponent(component);
      final secondImage = await renderSurfaceTestComponent(component);

      expect(await pixelAt(firstImage, 16, 16), rgba(255, 0, 0, 255));
      expect(await pixelAt(secondImage, 16, 16), rgba(0, 255, 0, 255));
      expect(calls, 2);
    });

    test('does not render shadows in the foreground pass', () async {
      final component = await _componentWithSurface(
        renderPass: MapLayerRenderPass.foreground,
        shadowCollectionProvider: () => ShadowRuntimeInstructionCollection(
          instructions: [
            _shadow(colorHexRgb: '000000'),
          ],
        ),
      );

      final image = await renderSurfaceTestComponent(component);

      expect(await pixelAt(image, 16, 16), rgba(0, 0, 0, 0));
    });
  });
}

Future<MapLayersComponent> _componentWithSurface({
  MapLayerRenderPass renderPass = MapLayerRenderPass.background,
  ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider,
}) async {
  return MapLayersComponent(
    bundle: surfaceTestBundle(
      map: surfaceTestMap(layers: [surfaceTestLayer()]),
    ),
    tileImagesByTilesetId: {
      'surface-water': await runtimeTilesetImage([const Color(0xFF0000FF)]),
    },
    renderPass: renderPass,
    shadowCollectionProvider: shadowCollectionProvider,
  );
}

ShadowRuntimeRenderInstruction _shadow({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  String colorHexRgb = '000000',
}) {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: colorHexRgb,
  );
}
```

### packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart — sections modifiées

```dart
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_manifest_tilesets.dart';
import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import '../../shadow/shadow_runtime_renderer.dart';
import '../../surface/surface_runtime_resolver.dart';
import 'path_pattern_runtime_render_resolution.dart';
import 'runtime_path_autotile.dart';

const int _kEntityFrameDurationFallbackMs = 200;

enum MapLayerRenderPass {
  background,
  foreground,
}
```

```dart
    final (offsetX, offsetY) = terrainPresetSubtileOffsetsForMapCell(
      x,
      y,
      frameWidthTiles: width,
      frameHeightTiles: height,
      layout: chosen.multiTileLayout,
      subtileSalt: frameSource.x * 73856093 + frameSource.y * 19349663,
    );
```

### packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart — sections modifiées

```dart
import '../../application/trainer_battle_request.dart';
import '../../infrastructure/runtime_tileset_image.dart';
import '../../infrastructure/tile_image_loader.dart';
import '../../shadow/shadow_runtime_collection_provider.dart';
import 'battle_bag_menu_model.dart';
```

```dart
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
    RuntimeDialogueSessionLoader? dialogueSessionLoader,
    RuntimeMapBundleLoader? runtimeMapBundleLoader,
    RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
    this.shadowCollectionProvider,
  })  : _bundle = bundle,
```

```dart
  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
  RuntimeMapBundle _bundle;
```

```dart
    final backgroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
      npcMapPresencePredicate: npcPred,
      shadowCollectionProvider: shadowCollectionProvider,
    );
```

## 22. Diffs complets ou équivalents /dev/null pour fichiers créés

### Diff complet des fichiers suivis modifiés

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart b/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
index 04d9e1e8..885d1923 100644
--- a/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
@@ -7,7 +7,7 @@ import '../../application/runtime_character_refs.dart';
 import '../../application/runtime_manifest_tilesets.dart';
 import '../../application/runtime_map_bundle.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
-import '../../shadow/shadow_runtime_instruction_collection.dart';
+import '../../shadow/shadow_runtime_collection_provider.dart';
 import '../../shadow/shadow_runtime_renderer.dart';
 import '../../surface/surface_runtime_resolver.dart';
 import 'path_pattern_runtime_render_resolution.dart';
@@ -20,9 +20,6 @@ enum MapLayerRenderPass {
   foreground,
 }
 
-typedef ShadowRuntimeInstructionCollectionProvider
-    = ShadowRuntimeInstructionCollection? Function();
-
 @visibleForTesting
 bool shouldRenderProjectElementEntityInForegroundPass(
   MapEntity entity, {
@@ -1270,8 +1267,7 @@ class MapLayersComponent extends PositionComponent {
       frameWidthTiles: width,
       frameHeightTiles: height,
       layout: chosen.multiTileLayout,
-      subtileSalt:
-          frameSource.x * 73856093 + frameSource.y * 19349663,
+      subtileSalt: frameSource.x * 73856093 + frameSource.y * 19349663,
     );
     final frameTilesetId = resolvedFrame.tilesetId.trim();
     final resolvedTilesetId =
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 095de1d0..50959a58 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -59,6 +59,7 @@ import '../../application/story_flags_manager.dart';
 import '../../application/trainer_battle_request.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
 import '../../infrastructure/tile_image_loader.dart';
+import '../../shadow/shadow_runtime_collection_provider.dart';
 import 'battle_bag_menu_model.dart';
 import 'battle_bag_item_icon_resolver.dart';
 import 'battle_overlay_component.dart';
@@ -120,6 +121,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     RuntimeDialogueSessionLoader? dialogueSessionLoader,
     RuntimeMapBundleLoader? runtimeMapBundleLoader,
     RuntimeTilesetImageLoader? runtimeTilesetImageLoader,
+    this.shadowCollectionProvider,
   })  : _bundle = bundle,
         _gameState = normalizeLoadedGameState(
           saveData == null
@@ -151,6 +153,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   final String projectFilePath;
   final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
   final List<RuntimeCutsceneAsset> runtimeCutscenes;
+  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
   RuntimeMapBundle _bundle;
   GameState _gameState;
   late GameplayWorldState _world;
@@ -6392,6 +6395,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       tileImagesByTilesetId: tileImagesById,
       showCollisionOverlay: _showCollisionOverlay,
       npcMapPresencePredicate: npcPred,
+      shadowCollectionProvider: shadowCollectionProvider,
     );
     backgroundLayers.position = _originPixels(
       originCellX: originCellX,
diff --git a/packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
index 9c865ab6..12d505e1 100644
--- a/packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
@@ -3,12 +3,17 @@ import 'package:map_core/map_core.dart';
 
 import '../../application/runtime_map_bundle.dart';
 import '../../infrastructure/tile_image_loader.dart';
+import '../../shadow/shadow_runtime_collection_provider.dart';
 import 'map_layers_component.dart';
 
 class RuntimeMapGame extends FlameGame {
-  RuntimeMapGame({required this.bundle});
+  RuntimeMapGame({
+    required this.bundle,
+    this.shadowCollectionProvider,
+  });
 
   final RuntimeMapBundle bundle;
+  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
 
   @override
   Future<void> onLoad() async {
@@ -22,6 +27,7 @@ class RuntimeMapGame extends FlameGame {
       MapLayersComponent(
         bundle: bundle,
         tileImagesByTilesetId: images,
+        shadowCollectionProvider: shadowCollectionProvider,
       ),
     );
     _applyView();
diff --git a/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart b/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
index 669c7005..1166bc2e 100644
--- a/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
+++ b/packages/map_runtime/test/shadow/shadow_runtime_renderer_integration_test.dart
@@ -2,6 +2,7 @@ import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
 import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
 import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
 
```

### /dev/null diff — packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart

```diff
diff --git a/packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart b/packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart
new file mode 100644
index 00000000..38fad6a0
--- /dev/null
+++ b/packages/map_runtime/lib/src/shadow/shadow_runtime_collection_provider.dart
@@ -0,0 +1,24 @@
+import 'shadow_runtime_instruction_collection.dart';
+
+typedef ShadowRuntimeInstructionCollectionProvider
+    = ShadowRuntimeInstructionCollection? Function();
+
+final class ShadowRuntimeCollectionController {
+  ShadowRuntimeCollectionController([
+    ShadowRuntimeInstructionCollection? initialCollection,
+  ]) : _current = initialCollection;
+
+  ShadowRuntimeInstructionCollection? _current;
+
+  ShadowRuntimeInstructionCollection? get current => _current;
+
+  ShadowRuntimeInstructionCollection? provide() => _current;
+
+  void replace(ShadowRuntimeInstructionCollection? collection) {
+    _current = collection;
+  }
+
+  void clear() {
+    _current = null;
+  }
+}
```

### /dev/null diff — packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart b/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart
new file mode 100644
index 00000000..dc0282d7
--- /dev/null
+++ b/packages/map_runtime/test/shadow/shadow_runtime_collection_provider_test.dart
@@ -0,0 +1,150 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
+
+void main() {
+  group('ShadowRuntimeCollectionController', () {
+    test('starts empty and provides null by default', () {
+      final controller = ShadowRuntimeCollectionController();
+
+      expect(controller.current, isNull);
+      expect(controller.provide(), isNull);
+    });
+
+    test('provides the initial collection without changing it', () {
+      final collection = ShadowRuntimeInstructionCollection(
+        instructions: [
+          _shadow(renderPass: ShadowRenderPass.actorContact),
+        ],
+      );
+      final controller = ShadowRuntimeCollectionController(collection);
+
+      expect(controller.current, same(collection));
+      expect(controller.provide(), same(collection));
+      expect(controller.provide()!.actorContact, hasLength(1));
+    });
+
+    test('replace updates current and provide', () {
+      final first = ShadowRuntimeInstructionCollection(
+        instructions: [
+          _shadow(colorHexRgb: 'FF0000'),
+        ],
+      );
+      final second = ShadowRuntimeInstructionCollection(
+        instructions: [
+          _shadow(colorHexRgb: '00FF00'),
+        ],
+      );
+      final controller = ShadowRuntimeCollectionController(first);
+
+      controller.replace(second);
+
+      expect(controller.current, same(second));
+      expect(controller.provide(), same(second));
+    });
+
+    test('replace can change collection between two provider calls', () {
+      final first = ShadowRuntimeInstructionCollection(
+        instructions: [
+          _shadow(colorHexRgb: 'FF0000'),
+        ],
+      );
+      final second = ShadowRuntimeInstructionCollection(
+        instructions: [
+          _shadow(colorHexRgb: '00FF00'),
+        ],
+      );
+      final controller = ShadowRuntimeCollectionController(first);
+
+      final before = controller.provide();
+      controller.replace(second);
+      final after = controller.provide();
+
+      expect(before, same(first));
+      expect(after, same(second));
+    });
+
+    test('replace null clears the collection', () {
+      final controller = ShadowRuntimeCollectionController(
+        ShadowRuntimeInstructionCollection(
+          instructions: [
+            _shadow(),
+          ],
+        ),
+      );
+
+      controller.replace(null);
+
+      expect(controller.current, isNull);
+      expect(controller.provide(), isNull);
+    });
+
+    test('clear removes the current collection', () {
+      final controller = ShadowRuntimeCollectionController(
+        ShadowRuntimeInstructionCollection(
+          instructions: [
+            _shadow(),
+          ],
+        ),
+      );
+
+      controller.clear();
+
+      expect(controller.current, isNull);
+      expect(controller.provide(), isNull);
+    });
+
+    test('does not sort cull deduplicate or remove opacity zero instructions',
+        () {
+      final zeroOpacity = _shadow(
+        renderPass: ShadowRenderPass.actorContact,
+        worldLeft: 1,
+        opacity: 0,
+      );
+      final firstGround = _shadow(
+        renderPass: ShadowRenderPass.groundStatic,
+        worldLeft: 2,
+      );
+      final duplicateGround = _shadow(
+        renderPass: ShadowRenderPass.groundStatic,
+        worldLeft: 2,
+      );
+      final collection = ShadowRuntimeInstructionCollection(
+        instructions: [
+          zeroOpacity,
+          firstGround,
+          duplicateGround,
+        ],
+      );
+      final controller = ShadowRuntimeCollectionController(collection);
+
+      final provided = controller.provide();
+
+      expect(provided, same(collection));
+      expect(
+          provided!.instructions, [zeroOpacity, firstGround, duplicateGround]);
+      expect(provided.actorContact, [zeroOpacity]);
+      expect(provided.groundStatic, [firstGround, duplicateGround]);
+    });
+  });
+}
+
+ShadowRuntimeRenderInstruction _shadow({
+  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
+  String colorHexRgb = '000000',
+  double worldLeft = 4,
+  double opacity = 1,
+}) {
+  return ShadowRuntimeRenderInstruction(
+    shape: ShadowRuntimeShapeKind.ellipse,
+    renderPass: renderPass,
+    worldLeft: worldLeft,
+    worldTop: 4,
+    width: 24,
+    height: 24,
+    opacity: opacity,
+    colorHexRgb: colorHexRgb,
+  );
+}
```

### /dev/null diff — packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart b/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart
new file mode 100644
index 00000000..0fbe36a8
--- /dev/null
+++ b/packages/map_runtime/test/shadow/shadow_runtime_provider_host_wiring_test.dart
@@ -0,0 +1,176 @@
+import 'dart:ui' as ui;
+
+import 'package:flame/components.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_runtime/src/application/runtime_map_bundle.dart';
+import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
+import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
+import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
+import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_collection_provider.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
+import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
+
+import '../surface/surface_runtime_test_support.dart';
+
+void main() {
+  TestWidgetsFlutterBinding.ensureInitialized();
+
+  group('runtime shadow provider host wiring', () {
+    test('RuntimeMapGame remains constructible without a provider', () {
+      final game = RuntimeMapGame(bundle: _bundle());
+
+      expect(game.shadowCollectionProvider, isNull);
+    });
+
+    test('RuntimeMapGame passes the provider to its mounted map layer',
+        () async {
+      var calls = 0;
+      ShadowRuntimeInstructionCollection? provider() {
+        calls += 1;
+        return ShadowRuntimeInstructionCollection(
+          instructions: [
+            _shadow(colorHexRgb: 'FF0000'),
+          ],
+        );
+      }
+
+      final game = RuntimeMapGame(
+        bundle: _bundle(),
+        shadowCollectionProvider: provider,
+      );
+
+      game.onGameResize(Vector2(32, 32));
+      await game.onLoad();
+      final layer = game.world.children.whereType<MapLayersComponent>().single;
+      final image = await _render(layer);
+
+      expect(layer.shadowCollectionProvider, same(provider));
+      expect(calls, 1);
+      expect(await pixelAt(image, 16, 16), rgba(255, 0, 0, 255));
+    });
+
+    test('RuntimeMapGame can use a different collection on later renders',
+        () async {
+      final controller = ShadowRuntimeCollectionController(
+        ShadowRuntimeInstructionCollection(
+          instructions: [
+            _shadow(colorHexRgb: 'FF0000'),
+          ],
+        ),
+      );
+      final game = RuntimeMapGame(
+        bundle: _bundle(),
+        shadowCollectionProvider: controller.provide,
+      );
+
+      game.onGameResize(Vector2(32, 32));
+      await game.onLoad();
+      final layer = game.world.children.whereType<MapLayersComponent>().single;
+      final firstImage = await _render(layer);
+      controller.replace(
+        ShadowRuntimeInstructionCollection(
+          instructions: [
+            _shadow(colorHexRgb: '00FF00'),
+          ],
+        ),
+      );
+      final secondImage = await _render(layer);
+
+      expect(await pixelAt(firstImage, 16, 16), rgba(255, 0, 0, 255));
+      expect(await pixelAt(secondImage, 16, 16), rgba(0, 255, 0, 255));
+    });
+
+    test('PlayableMapGame remains constructible without a provider', () {
+      final game = PlayableMapGame(
+        bundle: _bundle(),
+        projectFilePath: '/tmp/project.json',
+      );
+
+      expect(game.shadowCollectionProvider, isNull);
+    });
+
+    test('PlayableMapGame passes the provider only to background layers',
+        () async {
+      var calls = 0;
+      ShadowRuntimeInstructionCollection? provider() {
+        calls += 1;
+        return ShadowRuntimeInstructionCollection(
+          instructions: [
+            _shadow(colorHexRgb: '000000'),
+          ],
+        );
+      }
+
+      final game = PlayableMapGame(
+        bundle: _bundle(),
+        projectFilePath: '/tmp/project.json',
+        runtimeTilesetImageLoader: _emptyImageLoader,
+        shadowCollectionProvider: provider,
+      );
+
+      game.onGameResize(Vector2(32, 32));
+      await game.onLoad();
+      final layers = game.world.children.whereType<MapLayersComponent>();
+      final background = layers.singleWhere(
+        (layer) => layer.renderPass == MapLayerRenderPass.background,
+      );
+      final foreground = layers.singleWhere(
+        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
+      );
+      await _render(foreground);
+      final backgroundImage = await _render(background);
+
+      expect(background.shadowCollectionProvider, same(provider));
+      expect(foreground.shadowCollectionProvider, isNull);
+      expect(calls, 1);
+      expect(await pixelAt(backgroundImage, 16, 16), rgba(0, 0, 0, 255));
+    });
+  });
+}
+
+RuntimeMapBundle _bundle() {
+  return surfaceTestBundle(
+    tilesets: const <ProjectTilesetEntry>[],
+    map: const MapData(
+      id: 'shadow-host-test',
+      name: 'Shadow Host Test',
+      size: GridSize(width: 1, height: 1),
+      layers: [
+        MapLayer.object(id: 'objects', name: 'Objects'),
+      ],
+    ),
+  );
+}
+
+Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
+  Map<String, String> absolutePathByTilesetId, {
+  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
+      const <String, TilesetTransparentColor>{},
+}) async {
+  return const <String, RuntimeTilesetImage>{};
+}
+
+Future<ui.Image> _render(MapLayersComponent component) {
+  final recorder = ui.PictureRecorder();
+  final canvas = Canvas(recorder);
+  component.render(canvas);
+  return recorder.endRecording().toImage(32, 32);
+}
+
+ShadowRuntimeRenderInstruction _shadow({
+  String colorHexRgb = '000000',
+}) {
+  return ShadowRuntimeRenderInstruction(
+    shape: ShadowRuntimeShapeKind.ellipse,
+    renderPass: ShadowRenderPass.groundStatic,
+    worldLeft: 4,
+    worldTop: 4,
+    width: 24,
+    height: 24,
+    opacity: 1,
+    colorHexRgb: colorHexRgb,
+  );
+}
```
