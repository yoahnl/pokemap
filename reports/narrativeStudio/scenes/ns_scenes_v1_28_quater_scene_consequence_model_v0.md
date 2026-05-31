# NS-SCENES-V1-28-quater — Scene Consequence Model V0

## 1. Résumé du lot

V1-28-quater ajoute le modèle authoring pur des conséquences Scene V1 dans `map_core`.

Décision livrée :

- `SceneConsequence` V0 existe ;
- V0 supporte uniquement `setFact(factId, true/false)` et `markEventConsumed(mapId, eventId)` ;
- `SceneActionPayload` peut porter une conséquence typée ;
- les anciens `actionKind` libres restent lisibles pour rétrocompatibilité, mais ne deviennent pas le contrat final ;
- les diagnostics project-aware valident les refs Fact/map/event ;
- `buildSceneRuntimePlan` continue de refuser ActionNode ;
- aucun write runtime, aucune mutation `GameState`, aucune World Rule appliquée.

Prochain lot recommandé : `NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0`.

## 2. Pourquoi V1-28-quater existe

V1-28-ter a posé le contrat produit : une conséquence persistante ne doit pas être déduite d’un `EndNode`, d’une edge, d’une metadata, d’une page d’event ou d’un `StorylineStep`.

Ce lot code le modèle pur nécessaire avant toute exécution. Il permet de représenter proprement :

```text
Battle.victory -> Action/Consequence setFact(fact_test_gate_unlocked, true) -> End
```

Mais il ne l’exécute pas.

## 3. Rappel du scope

Réalisé :

- modèle `SceneConsequence` ;
- `SceneSetFactConsequence` ;
- `SceneMarkEventConsumedConsequence` ;
- JSON roundtrip ;
- intégration typée dans `SceneActionPayload` ;
- rétrocompatibilité des payloads `actionKind` legacy ;
- diagnostics pour refs Fact/map/event ;
- tests core ciblés ;
- roadmaps mises à jour.

Non réalisé :

- pas de runtime write ;
- pas de mutation `GameState` ;
- pas de Fact écrit au runtime ;
- pas de `markEventConsumed` runtime ;
- pas de World Rule runtime application ;
- pas de modification `map_runtime` ;
- pas de modification `map_editor` ;
- pas de modification `map_battle` ;
- pas de modification `map_gameplay` ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de battle adapter ;
- pas de BranchByOutcome ;
- pas de donnée produit.

## 4. Gate 0 complet

Commande exécutée avant modification :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
```

Interprétation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n’ont produit aucune ligne au Gate 0. Le worktree était propre.

## 5. Changements préexistants vs changements du lot

Changements préexistants : aucun changement non commit au Gate 0.

Changements introduits par V1-28-quater :

- `packages/map_core/lib/src/models/scene_consequence.dart` créé ;
- `packages/map_core/test/scene_consequence_model_test.dart` créé ;
- `packages/map_core/lib/src/models/scene_asset.dart` modifié ;
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart` modifié ;
- `packages/map_core/lib/map_core.dart` modifié ;
- `packages/map_core/test/scene_asset_json_test.dart` modifié ;
- `packages/map_core/test/scene_diagnostics_test.dart` modifié ;
- `packages/map_core/test/scene_runtime_plan_test.dart` modifié ;
- `reports/narrativeStudio/scenes/road_map_scenes.md` modifié ;
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` modifié ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md` créé.

## 6. Fichiers lus

Instructions :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `superpowers:test-driven-development`
- `superpowers:verification-before-completion`
- `karpathy-guidelines`
- `/Users/karim/.codex/attachments/5d28c8fe-da3f-4956-ba9e-4c4ce9ca6b3b/pasted-text.txt`

Rapports et roadmaps :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`

Core :

- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/map_core.dart`

Runtime lu sans modification :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Tests lus :

- `packages/map_core/test/scene_asset_json_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/golden_slice_readiness_test.dart`
- `packages/map_core/test/world_rule_diagnostics_test.dart`

## 7. Fichiers créés/modifiés

Créés :

- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`

Modifiés :

- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/scene_asset_json_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Design retenu

Design retenu : nouveau fichier modèle `scene_consequence.dart` + intégration optionnelle dans `SceneActionPayload`.

Justification :

- le contrat de conséquence est un objet public réutilisable ;
- `scene_asset.dart` reste lisible ;
- aucun modèle Freezed ou generated n’est requis ;
- `SceneActionPayload` conserve les anciens `actionKind` pour lecture legacy ;
- le nouveau contrat n’utilise ni metadata magique ni `Map<String, dynamic>` libre.

## 9. Modèle SceneConsequence V0

Modèles publics :

```dart
enum SceneConsequenceKind {
  setFact,
  markEventConsumed,
}

abstract base class SceneConsequence {
  const SceneConsequence();

  factory SceneConsequence.setFact({
    required String factId,
    required bool value,
    String? label,
    String? notes,
  }) = SceneSetFactConsequence;

  factory SceneConsequence.markEventConsumed({
    required String mapId,
    required String eventId,
    String? label,
    String? notes,
  }) = SceneMarkEventConsumedConsequence;

  factory SceneConsequence.fromJson(Map<String, dynamic> json);

  SceneConsequenceKind get kind;
  Map<String, dynamic> toJson();
}
```

`SceneSetFactConsequence` porte :

- `factId` ;
- `value` ;
- `label` optionnel ;
- `notes` optionnel.

`SceneMarkEventConsumedConsequence` porte :

- `mapId` ;
- `eventId` ;
- `label` optionnel ;
- `notes` optionnel.

## 10. Relation avec ActionNode

`SceneActionPayload` accepte maintenant :

- un `actionKind` legacy optionnel ;
- des `parameters` legacy conservés ;
- une `SceneConsequence? consequence`.

Le constructeur `SceneActionPayload.consequence(...)` crée un payload typé sans `actionKind`.

Les payloads legacy restent désérialisables :

```json
{
  "kind": "action",
  "actionKind": "setFlag",
  "parameters": {"flagId": "legacy_flag"}
}
```

Mais ils sont diagnostiqués comme `actionPayloadLegacyUnsupported`.

## 11. JSON / rétrocompatibilité

Rétrocompatibilité :

- les anciens `SceneActionPayload(actionKind: ...)` restent valides ;
- les anciens JSON avec `actionKind` et `parameters` continuent de se désérialiser ;
- les nouveaux JSON de conséquence roundtrip ;
- aucun champ n’est caché dans `metadata` ;
- aucun build_runner n’a été nécessaire.

JSON `setFact` :

```json
{
  "kind": "setFact",
  "factId": "fact_test_gate_unlocked",
  "value": true
}
```

JSON `markEventConsumed` :

```json
{
  "kind": "markEventConsumed",
  "mapId": "map_test",
  "eventId": "event_gate"
}
```

## 12. Diagnostics ajoutés

Codes ajoutés :

- `consequenceUnknownFact`
- `consequenceUnknownEvent`
- `consequenceMissingTarget`
- `consequenceWouldApplyWorldRuleDirectly`
- `actionPayloadLegacyUnsupported`
- `consequenceRuntimeUnsupported`

Implémentés dans ce lot :

- `consequenceMissingTarget` : cible vide côté forme de conséquence ;
- `consequenceUnknownFact` : `setFact` cible un Fact absent ;
- `consequenceUnknownEvent` : `markEventConsumed` cible une map ou un event absent ;
- `actionPayloadLegacyUnsupported` : ActionNode porte encore un `actionKind` libre.

Réservés pour lots suivants :

- `consequenceWouldApplyWorldRuleDirectly`
- `consequenceRuntimeUnsupported`

Sévérité :

- cible manquante : error ;
- ref Fact/map/event inconnue : error ;
- legacy `actionKind` libre : warning authoring ;
- runtime non supporté : le blocage reste dans `buildSceneRuntimePlan`.

## 13. Runtime plan : décision de non-exécution

`buildSceneRuntimePlan` reste inchangé côté exécution ActionNode : tout `SceneNodeKind.action` produit encore `SceneRuntimePlanDiagnosticCode.unsupportedAction`.

Même avec une conséquence typée :

```text
SceneActionPayload.consequence(SceneConsequence.setFact(...))
```

le plan reste non buildable. C’est volontaire : V1-28-quater ajoute le modèle authoring, pas le runtime write.

## 14. Authoring operations si ajoutées

Aucune opération d’authoring n’a été ajoutée.

Justification : le modèle, le JSON et les diagnostics suffisent pour V0. Ajouter `setSceneActionConsequence` maintenant aurait créé une API encore non utilisée par l’éditeur et aurait dépassé le besoin minimal.

## 15. Ce qui reste non exécuté

Restent non exécutés :

- `setFact` ;
- `markEventConsumed` ;
- toute application de World Rule ;
- toute complétion StorylineStep ;
- tout outcome dialogue détaillé ;
- tout battle result awaitable.

## 16. Pourquoi aucun runtime write n’a été codé

Le runtime write doit être un seam séparé, testé contre `GameState`, et branché explicitement après le modèle. Le coder ici aurait mélangé modèle authoring et effets runtime.

## 17. Pourquoi aucune World Rule n’est appliquée directement

Le contrat reste :

```text
Scene -> écrit plus tard un état persistant lisible
WorldRule -> lit cet état
Projection -> rend le monde visible/actif
```

Une Scene ne doit pas appeler une World Rule comme une action.

## 18. Pourquoi aucun StorylineStep n’est complété

`completeStoryStep` est reporté car `StorylineStep.sceneLinkIds` n’est pas encore stabilisé comme lien runtime. Le risque serait de confondre progression narrative, trigger et conséquence.

## 19. Pourquoi aucun battle adapter n’a été codé

Le battle adapter attend un retour runtime réel `victory/defeat`. Ce lot prépare le modèle de conséquence ; il ne doit pas inventer ou hardcoder un résultat de combat.

## 20. Pourquoi aucune donnée Selbrume n’a été créée

Tous les IDs de test sont neutres :

- `scene_test`
- `node_action_set_fact`
- `fact_test_gate_unlocked`
- `map_test`
- `event_gate`

Aucune donnée produit n’a été créée.

## 21. Tests exécutés avec sorties exactes

### `cd packages/map_core && dart test test/scene_consequence_model_test.dart`

```text
00:00 +8: All tests passed!
```

### `cd packages/map_core && dart test test/scene_diagnostics_test.dart`

```text
00:00 +24: All tests passed!
```

### `cd packages/map_core && dart test test/scene_asset_json_test.dart`

```text
00:00 +8: All tests passed!
```

### `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`

```text
00:00 +14: All tests passed!
```

### `cd packages/map_core && dart test test/golden_slice_readiness_test.dart`

```text
00:00 +2: All tests passed!
```

### `cd packages/map_core && dart test test/scene_project_diagnostics_test.dart`

```text
00:00 +5: All tests passed!
```

### `cd packages/map_core && dart test test/scene_authoring_operations_test.dart`

```text
00:00 +28: All tests passed!
```

## 22. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 23. Recherche anti-Selbrume

Commande :

```bash
rg -n "selbrume|mael|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src/models packages/map_core/lib/src/diagnostics packages/map_core/lib/src/authoring packages/map_core/test reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md || true
```

Sortie finale exacte :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md:75:54acda44 feat(scenes): add golden slice selbrume readiness
reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md:124:- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md:457:rg -n "selbrume|mael|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src/models packages/map_core/lib/src/diagnostics packages/map_core/lib/src/authoring packages/map_core/test reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md || true
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:257:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:258:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:259:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:208:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:209:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:210:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/beta_playability_validator_test.dart:255:      expect(text, isNot(contains('selbrume')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:244:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:245:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:246:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:185:                _area(id: 'forest_north', presetId: 'selbrume_dense_forest'),
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:197:      expect(d.presetId, 'selbrume_dense_forest');
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:200:        'Environment area "forest_north" on layer "env_layer" references missing preset "selbrume_dense_forest".',
packages/map_core/test/narrative_authoring_golden_path_test.dart:359:      expect(serializedEvidence, isNot(contains('selbrume')));
packages/map_core/test/narrative_authoring_golden_path_test.dart:360:      expect(serializedEvidence, isNot(contains('lysa')));
packages/map_core/test/narrative_authoring_golden_path_test.dart:361:      expect(serializedEvidence, isNot(contains('mael')));
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:230:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:231:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:232:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/environment_preset_json_codec_test.dart:23:  String id = 'selbrume_dense_forest',
packages/map_core/test/environment_preset_json_codec_test.dart:48:    'id': 'selbrume_dense_forest',
packages/map_core/test/environment_preset_json_codec_test.dart:75:      expect(p.id, 'selbrume_dense_forest');
packages/map_core/test/environment_preset_json_codec_test.dart:92:      expect(m['id'], 'selbrume_dense_forest');
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:263:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:264:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:265:      expect(serialized, isNot(contains('mael')));
```

Interprétation attendue : les éventuels résultats dans des tests historiques ou dans le rapport sont documentaires ou anti-fake ; aucun code/test créé par V1-28-quater ne contient de donnée produit.

## 24. Recherche anti-runtime imports

Commande :

```bash
rg -n "map_runtime|map_battle|PlayableMapGame|GameState|SceneEventRuntimeHook" packages/map_core/lib/src packages/map_core/test/scene_consequence_model_test.dart || true
```

Sortie finale exacte :

```text
packages/map_core/lib/src/projection/world_rule_projection.dart:24:  GameState gameState, {
packages/map_core/lib/src/projection/world_rule_projection.dart:67:  GameState gameState,
packages/map_core/lib/src/projection/world_rule_projection.dart:81:  GameState gameState,
packages/map_core/lib/src/projection/world_rule_projection.dart:104:  GameState gameState,
packages/map_core/lib/src/projection/world_rule_projection.dart:122:  GameState gameState,
packages/map_core/lib/src/models/map_entity_payloads.dart:34:// Ces types sont consommés par map_runtime (évaluation) et map_editor (UI
packages/map_core/lib/src/models/project_trainer.freezed.dart:356:  ///   runtime + `map_battle`, pas dans ce modèle data.
packages/map_core/lib/src/models/project_trainer.freezed.dart:363:  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
packages/map_core/lib/src/models/project_trainer.freezed.dart:624:  ///   runtime + `map_battle`, pas dans ce modèle data.
packages/map_core/lib/src/models/project_trainer.freezed.dart:632:  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
packages/map_core/lib/src/models/project_trainer.freezed.dart:769:  ///   runtime + `map_battle`, pas dans ce modèle data.
packages/map_core/lib/src/models/project_trainer.freezed.dart:777:  /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
packages/map_core/lib/src/models/pokemon_move.dart:152:///   sans pour autant signifier que tout est déjà branché côté `map_battle`.
packages/map_core/lib/src/models/game_state.g.dart:80:_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
packages/map_core/lib/src/models/game_state.g.dart:81:    _$GameStateImpl(
packages/map_core/lib/src/models/game_state.g.dart:128:Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
packages/map_core/lib/src/models/project_trainer.dart:50:    ///   runtime + `map_battle`, pas dans ce modèle data.
packages/map_core/lib/src/models/project_trainer.dart:57:    /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
packages/map_core/lib/src/models/game_state.freezed.dart:935:GameState _$GameStateFromJson(Map<String, dynamic> json) {
packages/map_core/lib/src/models/game_state.freezed.dart:936:  return _GameState.fromJson(json);
packages/map_core/lib/src/models/game_state.freezed.dart:940:mixin _$GameState {
packages/map_core/lib/src/models/game_state.freezed.dart:977:  /// Serializes this GameState to a JSON map.
packages/map_core/lib/src/models/game_state.freezed.dart:980:  /// Create a copy of GameState
packages/map_core/lib/src/models/game_state.freezed.dart:983:  $GameStateCopyWith<GameState> get copyWith =>
packages/map_core/lib/src/models/game_state.freezed.dart:988:abstract class $GameStateCopyWith<$Res> {
packages/map_core/lib/src/models/game_state.dart:68:class GameState with _$GameState {
packages/map_core/lib/src/models/game_state.dart:70:  const factory GameState({
packages/map_core/lib/src/models/game_state.dart:106:  }) = _GameState;
packages/map_core/lib/src/models/game_state.dart:108:  factory GameState.fromJson(Map<String, dynamic> json) =>
packages/map_core/lib/src/models/game_state.dart:109:      _$GameStateFromJson(json);
packages/map_core/lib/src/operations/game_state_persistence.dart:5:GameState gameStateFromSaveData(SaveData saveData) {
packages/map_core/lib/src/operations/game_state_persistence.dart:17:  return GameState(
packages/map_core/lib/src/operations/game_state_persistence.dart:35:SaveData saveDataFromGameState(GameState gameState) {
packages/map_core/lib/src/operations/game_state_persistence.dart:62:GameState normalizeLoadedGameState(GameState state) {
packages/map_core/lib/src/operations/game_state_persistence.dart:96:GameState markSpeciesSeenInGameState(
packages/map_core/lib/src/operations/game_state_persistence.dart:97:  GameState state,
packages/map_core/lib/src/operations/game_state_persistence.dart:102:    return normalizeLoadedGameState(state);
```

Interprétation attendue : les éventuels résultats existants dans `game_state.dart`, projections ou commentaires historiques ne sont pas des imports ajoutés par ce lot ; les fichiers créés/modifiés du modèle de conséquence n’importent pas `map_runtime` ni `map_battle`.

## 25. git diff --check

Sortie finale exacte :

```text
Sortie : <vide>
```

## 26. git diff --stat

Sortie finale exacte :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../lib/src/diagnostics/scene_diagnostics.dart     | 192 ++++++++++++++++++--
 packages/map_core/lib/src/models/scene_asset.dart  |  53 +++++-
 packages/map_core/test/scene_asset_json_test.dart  |   7 +
 packages/map_core/test/scene_diagnostics_test.dart | 199 ++++++++++++++++++++-
 .../map_core/test/scene_runtime_plan_test.dart     |  26 +++
 .../scenes/road_map_scene_builder_authoring.md     |  21 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  27 ++-
 8 files changed, 491 insertions(+), 35 deletions(-)
```

## 27. git diff --name-only

Sortie finale exacte :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/test/scene_asset_json_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 28. git status final exact

Sortie finale exacte :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/scene_asset.dart
 M packages/map_core/test/scene_asset_json_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/scene_runtime_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/models/scene_consequence.dart
?? packages/map_core/test/scene_consequence_model_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md
```

## 29. Evidence Pack

### Contenu complet — `packages/map_core/lib/src/models/scene_consequence.dart`

```dart
import 'package:meta/meta.dart' show immutable;

enum SceneConsequenceKind {
  setFact,
  markEventConsumed,
}

@immutable
abstract base class SceneConsequence {
  const SceneConsequence();

  factory SceneConsequence.setFact({
    required String factId,
    required bool value,
    String? label,
    String? notes,
  }) = SceneSetFactConsequence;

  factory SceneConsequence.markEventConsumed({
    required String mapId,
    required String eventId,
    String? label,
    String? notes,
  }) = SceneMarkEventConsumedConsequence;

  factory SceneConsequence.fromJson(Map<String, dynamic> json) {
    final kind = _readKind(json['kind']);
    return switch (kind) {
      SceneConsequenceKind.setFact => SceneSetFactConsequence.fromJson(json),
      SceneConsequenceKind.markEventConsumed =>
        SceneMarkEventConsumedConsequence.fromJson(json),
    };
  }

  SceneConsequenceKind get kind;

  Map<String, dynamic> toJson();
}

@immutable
final class SceneSetFactConsequence extends SceneConsequence {
  SceneSetFactConsequence({
    required String factId,
    required this.value,
    String? label,
    String? notes,
  })  : factId = factId.trim(),
        label = _trimOptional(label),
        notes = _trimOptional(notes);

  factory SceneSetFactConsequence.fromJson(Map<String, dynamic> json) {
    return SceneSetFactConsequence(
      factId: _readRequiredString(json, 'factId'),
      value: _readRequiredBool(json, 'value'),
      label: _readOptionalString(json, 'label'),
      notes: _readOptionalString(json, 'notes'),
    );
  }

  @override
  SceneConsequenceKind get kind => SceneConsequenceKind.setFact;

  final String factId;
  final bool value;
  final String? label;
  final String? notes;

  @override
  Map<String, dynamic> toJson() => _withoutNulls({
        'kind': _kindToJson(kind),
        'factId': factId,
        'value': value,
        'label': label,
        'notes': notes,
      });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneSetFactConsequence &&
          other.factId == factId &&
          other.value == value &&
          other.label == label &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(factId, value, label, notes);
}
```

La suite du fichier contient `SceneMarkEventConsumedConsequence`, le parsing de kind, les helpers JSON stricts et `_withoutNulls`.

### Contenu complet — `packages/map_core/test/scene_consequence_model_test.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneConsequence V0', () {
    test('setFact stores factId and value', () {
      final consequence = SceneConsequence.setFact(
        factId: 'fact_test_gate_unlocked',
        value: true,
        label: 'Unlock test gate',
      );

      expect(consequence.kind, SceneConsequenceKind.setFact);
      expect(consequence, isA<SceneSetFactConsequence>());
      final setFact = consequence as SceneSetFactConsequence;
      expect(setFact.factId, 'fact_test_gate_unlocked');
      expect(setFact.value, isTrue);
      expect(setFact.label, 'Unlock test gate');
    });

    test('markEventConsumed stores mapId and eventId', () {
      final consequence = SceneConsequence.markEventConsumed(
        mapId: 'map_test',
        eventId: 'event_gate',
        label: 'Gate event consumed',
      );

      expect(consequence.kind, SceneConsequenceKind.markEventConsumed);
      expect(consequence, isA<SceneMarkEventConsumedConsequence>());
      final consumed = consequence as SceneMarkEventConsumedConsequence;
      expect(consumed.mapId, 'map_test');
      expect(consumed.eventId, 'event_gate');
      expect(consumed.label, 'Gate event consumed');
    });

    test('setFact JSON round-trips', () {
      final consequence = SceneConsequence.setFact(
        factId: 'fact_test_gate_unlocked',
        value: false,
        label: 'Close test gate',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'setFact');
      expect(json['factId'], 'fact_test_gate_unlocked');
      expect(json['value'], isFalse);
      expect(decoded, equals(consequence));
    });

    test('markEventConsumed JSON round-trips', () {
      final consequence = SceneConsequence.markEventConsumed(
        mapId: 'map_test',
        eventId: 'event_gate',
        label: 'Gate event consumed',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'markEventConsumed');
      expect(json['mapId'], 'map_test');
      expect(json['eventId'], 'event_gate');
      expect(decoded, equals(consequence));
    });
  });
}
```

Le fichier contient aussi les tests d’échec kind inconnu, payload Action typé `setFact`, payload Action typé `markEventConsumed`, et rétrocompatibilité `actionKind`.

### Hunk public — `SceneActionPayload`

```dart
final class SceneActionPayload extends SceneNodePayload {
  SceneActionPayload({
    String? actionKind,
    Map<String, String> parameters = const <String, String>{},
    this.consequence,
  });

  factory SceneActionPayload.consequence(
    SceneConsequence consequence, {
    String? actionKind,
    Map<String, String> parameters = const <String, String>{},
  });

  final String? actionKind;
  final Map<String, String> parameters;
  final SceneConsequence? consequence;
}
```

### Hunk diagnostic — refs project-aware

```dart
SceneDiagnosticsReport diagnoseSceneAgainstProject(
  SceneAsset scene,
  ProjectManifest project, {
  Map<String, MapData> mapsById = const {},
});
```

Le diagnostic valide `setFact` contre `project.facts` et `markEventConsumed` contre `ProjectManifest.maps` puis `MapData.events` quand la map est fournie.

### Diff roadmaps

Les roadmaps marquent V1-28-quater DONE et ajoutent V1-28-quinquies TODO. Les sections ajoutées indiquent explicitement :

- modèle authoring pur ;
- conséquences typées ;
- diagnostics refs ;
- ActionNode encore bloqué runtime ;
- prochain lot runtime write V0.

## 30. Auto-review critique

- Est-ce que j’ai modifié `map_runtime` ? Non.
- Est-ce que j’ai modifié `map_editor` ? Non.
- Est-ce que j’ai modifié `map_battle` ? Non.
- Est-ce que j’ai modifié `map_gameplay` ? Non.
- Est-ce que j’ai muté `GameState` ? Non.
- Est-ce que j’ai écrit un Fact au runtime ? Non.
- Est-ce que j’ai marqué un event consumed au runtime ? Non.
- Est-ce que j’ai appliqué une World Rule au runtime ? Non.
- Est-ce que j’ai complété une StorylineStep ? Non.
- Est-ce que j’ai activé BranchByOutcome ? Non.
- Est-ce que j’ai inventé des outcomes Yarn ? Non.
- Est-ce que j’ai hardcodé victory/defeat runtime ? Non.
- Est-ce que les conséquences restent typées et bornées ? Oui.
- Est-ce que `setFact` valide les Facts côté diagnostics ? Oui.
- Est-ce que `markEventConsumed` valide map/event côté diagnostics ? Oui, quand les `MapData` sont fournis.
- Est-ce que les anciens `actionKind` libres ne deviennent pas le contrat final ? Oui, ils restent legacy/unsupported authoring.
- Est-ce que le prochain lot n’a pas été démarré ? Oui.

## 31. Limites restantes

- Pas de runtime write.
- Pas d’opération authoring dédiée pour poser/retirer une conséquence sur un ActionNode.
- Pas d’UI éditeur.
- `markEventConsumed` ne peut valider l’existence de l’event que si le `MapData` correspondant est fourni aux diagnostics.
- `completeStoryStep`, `giveItem`, `teleport`, battle adapter et Dialogue outcomes restent hors V0.

## 32. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0
```

Raison : le modèle authoring pur existe. Le prochain verrou est d’appliquer explicitement les conséquences V0 au runtime, sans appliquer directement les World Rules, sans battle adapter et sans StorylineStep link.
