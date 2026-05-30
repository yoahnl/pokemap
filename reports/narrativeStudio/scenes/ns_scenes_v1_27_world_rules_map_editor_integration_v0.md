# NS-SCENES-V1-27 — World Rules Map Editor Integration V0

## 1. Résumé du lot

Le lot V1-27 rend les World Rules retrouvables depuis leurs cibles naturelles dans le Map Editor, sans brancher le runtime :

- read model pur côté `map_core` pour filtrer les World Rules par cible `mapEvent`, `mapEntity` et `npcDialogue` ;
- section contextuelle dans `EventPropertiesPanel` ;
- affichage contextuel dans `EntityPropertiesPanel` pour entité et dialogue PNJ ;
- diagnostics World Rules surfacés au niveau de la cible ;
- toggle enabled/disabled en mémoire ;
- création V0 bornée depuis un Event : source Fact existante -> effet event enabled/disabled/hidden, avec `mapId` et `eventId` auto-remplis depuis le contexte.

## 2. Rappel du scope

Scope réalisé :

- authoring-context Map Editor ;
- read model pur ;
- diagnostics surfacing ;
- mise à jour mémoire de `ProjectManifest.worldRules` via `EditorNotifier.applyInMemoryProjectManifest`.

Non-objectifs respectés :

- pas de runtime Scene ;
- pas d’application runtime des World Rules ;
- pas de `PlayableMapGame` ;
- pas de mutation `GameState` ;
- pas de collision, warp ou tile dynamique ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de promotion `ScenarioAsset` ;
- pas de donnée Selbrume.

## 3. Gate 0 complet

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
Sortie git status : <vide>
Sortie git diff --stat : <vide>
Sortie git diff --name-only : <vide>
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add linked asset contracts and scene V0 node deletion
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
```

## 4. Changements préexistants vs changements du lot

Gate 0 était propre : aucun changement préexistant.

Changements du lot :

- nouveaux fichiers `world_rule_target_context_read_model.dart`, `world_rule_target_context_read_model_test.dart`, `world_rule_target_section.dart` ;
- modifications ciblées de `map_core.dart`, `EventPropertiesPanel`, `EntityPropertiesPanel`, tests editor, roadmaps ;
- screenshot V1-27.

Pendant les tests, des modifications hors-scope ont été générées dans `selbrume/`. Elles ont été inspectées puis annulées avant finalisation. Le diff final ne contient aucune modification Selbrume.

## 5. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/world_rule_test.dart`
- `packages/map_core/test/world_rule_authoring_operations_test.dart`
- `packages/map_core/test/world_rule_diagnostics_test.dart`
- `packages/map_core/test/world_rule_projection_test.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `packages/map_editor/test/event_properties_panel_scene_target_test.dart`
- `packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart`

Fichier attendu absent :

```text
Fichier absent : packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
Impact : la commande demandée par le gabarit historique ne peut pas être exécutée ; les tests réels disponibles de shell/overview/projection ont été exécutés.
```

## 6. Fichiers créés/modifiés

Créés :

- `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart`
- `packages/map_core/test/world_rule_target_context_read_model_test.dart`
- `packages/map_editor/lib/src/ui/panels/world_rule_target_section.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_27_world_rules_map_editor_integration_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`

Modifiés :

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_editor/test/event_properties_panel_scene_target_test.dart`
- `packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 7. Audit Map Editor des cibles World Rules

- `EventPropertiesPanel` existe et connaît `activeMap`, `selectedEvent`, `ProjectManifest` et `EditorNotifier`.
- `EntityPropertiesPanel` existe et connaît `activeMap`, `selectedEntity`, `ProjectManifest` et `EditorNotifier`.
- `EditorNotifier.applyInMemoryProjectManifest` remplace le manifest projet en mémoire, marque le projet dirty et ne force pas d’écriture disque.
- `WorldRuleTargetKind.mapEvent` requiert `target.mapId` + `target.eventId`.
- `WorldRuleTargetKind.mapEntity` et `npcDialogue` requièrent `target.mapId` + `target.entityId`.
- `addWorldRule` / `updateWorldRule` valident les sources, targets, effets et maps passées.
- `diagnoseWorldRules(project, maps: [map])` sait produire les diagnostics nécessaires sans runtime.

## 8. Design retenu

Décision : ajouter un read model cible pur côté `map_core`, puis consommer ce read model dans les panels Map Editor.

Raisons :

- éviter que l’UI filtre à la main avec de la logique dupliquée ;
- garder une source testée et déterministe pour `mapEvent`, `mapEntity`, `npcDialogue` ;
- ne pas dépendre de `GameState` ou d’une projection runtime ;
- permettre aux panels de rester authoring-only.

## 9. Read model ajouté

API publique ajoutée :

```dart
WorldRuleTargetContextReadModel buildWorldRuleTargetContextReadModel(
  ProjectManifest project, {
  required WorldRuleTargetKind targetKind,
  required String mapId,
  String? entityId,
  String? eventId,
  List<MapData> maps = const <MapData>[],
})
```

Classes ajoutées :

```dart
final class WorldRuleTargetContextReadModel {
  final WorldRuleTargetKind targetKind;
  final String mapId;
  final String? entityId;
  final String? eventId;
  List<WorldRuleTargetContextRuleView> get rules;
  int get ruleCount;
  bool get isEmpty;
  List<WorldRuleDiagnostic> get diagnostics;
  bool get hasDiagnostics;
}

final class WorldRuleTargetContextRuleView {
  final WorldRuleDefinition rule;
  final String sourceLabel;
  final String targetLabel;
  final String effectLabel;
  String get id;
  String get label;
  bool get enabled;
  List<WorldRuleDiagnostic> get diagnostics;
  bool get hasDiagnostics;
}
```

Règles :

- filtre exact par `target.kind`, `target.mapId`, `target.eventId` ou `target.entityId` ;
- ordre stable par `priority`, puis `id` ;
- diagnostics attachés par `ruleId` ;
- labels source/target/effect lisibles ;
- aucune lecture `GameState` ;
- aucune écriture disque ;
- aucune mutation de `ProjectManifest`.

Export ajouté :

```dart
export 'src/read_models/world_rule_target_context_read_model.dart';
```

## 10. Section World Rules EventPropertiesPanel

Le panel Event affiche maintenant une section `Règles du monde` quand un projet et un event sont sélectionnés.

La section montre :

- nombre de rules liées ;
- empty state honnête ;
- label de règle ;
- statut Active/Inactive ;
- source lisible ;
- effet lisible ;
- diagnostics existants ;
- bouton Activer/Désactiver.

La création V0 est affichée seulement pour le contexte Event et seulement si le projet contient au moins un Fact.

## 11. Intégration mapEntity / npcDialogue

`EntityPropertiesPanel` affiche maintenant :

- rules ciblant `WorldRuleTargetKind.mapEntity` pour l’entité sélectionnée ;
- rules ciblant `WorldRuleTargetKind.npcDialogue` quand l’entité sélectionnée est un PNJ.

Cette intégration est volontairement lecture/toggle uniquement. La création contextuelle avancée pour entité/PNJ reste hors V1-27.

## 12. Création / édition V0

Création V0 faite pour Event uniquement :

- label lisible ;
- Fact source via picker ;
- prédicat `Fact vrai` / `Fact faux` ;
- effet `Event activé`, `Event désactivé`, `Event masqué` ;
- switch enabled ;
- `target.mapId` rempli depuis `activeMap.id` ;
- `target.eventId` rempli depuis l’event sélectionné ;
- `target.label` rempli depuis le titre de l’event.

Édition V0 faite :

- toggle enabled/disabled pour Event, entité et dialogue PNJ.

Non fait :

- création mapEntity ;
- création npcDialogue ;
- édition source/effect d’une règle existante ;
- suppression World Rule depuis la cible.

## 13. Diagnostics affichés

Les diagnostics proviennent de `diagnoseWorldRules(project, maps: [map])` et sont attachés aux rules filtrées par cible.

Exemples couverts par tests :

- source Fact absente ;
- rules d’autres events ignorées ;
- rules d’autres maps ignorées par le read model.

## 14. Design system / tokens utilisés

La nouvelle section `WorldRuleTargetSection` utilise :

- `context.pokeMapColors` pour couleurs ;
- primitives existantes `InspectorEmbeddedDropdown`, `InspectorEmbeddedPrimaryCapsule`, `InspectorEmbeddedSecondaryCapsule`, `InspectorEmbeddedFootnote`, `InspectorEmbeddedSectionLabel` ;
- aucun `Color(0x...)` ;
- aucun `Colors.*` ;
- aucun `CupertinoColors` dans le nouveau widget ;
- aucun import direct de `cupertino_editor_widgets.dart` dans le nouveau widget.

Le test `design_system_guardrail_test.dart` passe.

## 15. Visual Gate

Screenshot créé :

```text
/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_27_world_rules_map_editor_integration_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_27_CAPTURE_SCREENSHOT=true test/event_properties_panel_scene_target_test.dart --plain-name "captures V1-27 World Rules map editor screenshot when requested"
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/event_properties_panel_scene_target_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/event_properties_panel_scene_target_test.dart
00:01 +0: captures V1-27 World Rules map editor screenshot when requested
00:02 +0: captures V1-27 World Rules map editor screenshot when requested
00:02 +1: captures V1-27 World Rules map editor screenshot when requested
00:02 +1: All tests passed!
```

SHA-256 :

```text
52c0dd549ef97f7c14fe8eda7deec4d7ba84e9ff1c2089512dd0a25a1610b86c  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_27_world_rules_map_editor_integration_v0.png
```

## 16. Tests exécutés avec sorties exactes

Commande core finale :

```bash
cd packages/map_core && dart test test/world_rule_test.dart && dart test test/world_rule_authoring_operations_test.dart && dart test test/world_rule_diagnostics_test.dart && dart test test/world_rule_projection_test.dart && dart test test/world_rule_target_context_read_model_test.dart && dart analyze
```

Sortie exacte :

```text
test/world_rule_test.dart : All tests passed!
test/world_rule_authoring_operations_test.dart : All tests passed!
test/world_rule_diagnostics_test.dart : All tests passed!
test/world_rule_projection_test.dart : All tests passed!
test/world_rule_target_context_read_model_test.dart : All tests passed!
Analyzing map_core...
No issues found!
```

Commande editor finale :

```bash
cd packages/map_editor && flutter test --reporter=compact test/event_properties_panel_scene_target_test.dart && flutter test --reporter=compact test/map_canvas_entity_properties_smoke_test.dart && flutter test --reporter=compact test/ui/canvas/narrative_overview_workspace_test.dart && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart && flutter test --reporter=compact test/narrative_workspace_projection_test.dart && flutter test --reporter=compact test/design_system_guardrail_test.dart
```

Sortie exacte :

```text
test/event_properties_panel_scene_target_test.dart : All tests passed!
test/map_canvas_entity_properties_smoke_test.dart : All tests passed!
test/ui/canvas/narrative_overview_workspace_test.dart : All tests passed!
test/ui/canvas/narrative_overview_shell_navigation_test.dart : All tests passed!
test/narrative_workspace_projection_test.dart : All tests passed!
test/design_system_guardrail_test.dart : All tests passed!
```

Commande demandée mais fichier absent :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie exacte :

```text
Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart": Does not exist.
```

## 17. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/panels/event_properties_panel.dart lib/src/ui/panels/entity_properties_panel.dart lib/src/ui/panels/world_rule_target_section.dart test/event_properties_panel_scene_target_test.dart test/map_canvas_entity_properties_smoke_test.dart
```

Sortie exacte :

```text
Analyzing 5 items...

   info • 'minSize' is deprecated and shouldn't be used. Use minimumSize instead. This feature was deprecated after v3.28.0-3.0.pre. Try replacing the use of the deprecated member with the replacement • lib/src/ui/panels/event_properties_panel.dart:691:19 • deprecated_member_use
   info • 'minSize' is deprecated and shouldn't be used. Use minimumSize instead. This feature was deprecated after v3.28.0-3.0.pre. Try replacing the use of the deprecated member with the replacement • lib/src/ui/panels/event_properties_panel.dart:1287:17 • deprecated_member_use

2 issues found. (ran in 1.3s)
```

Exit code : `0` grâce à `--no-fatal-infos`. Les deux infos sont une dette préexistante du fichier `event_properties_panel.dart`.

## 18. Pourquoi aucun runtime n’a été branché

Le lot ne modifie aucun fichier `map_runtime`, ne lit pas `SceneRuntimeExecutor` depuis l’éditeur et ne déclenche aucune scène. Les World Rules restent authoring/read model.

## 19. Pourquoi aucune World Rule n’a été appliquée au monde

Le read model filtre des définitions déclaratives. Il ne consomme pas `GameState` et n’appelle pas `projectWorldRuleEffects`. Les panels affichent, créent ou togglent des définitions, mais n’appliquent aucun effet à une map runtime.

## 20. Pourquoi aucune collision/warp dynamique n’a été ajoutée

Les effets V0 manipulés sont uniquement `eventEnabled`, `eventDisabled`, `eventHidden` en authoring. Aucun système de collision, warp, tile, map overlay ou gameplay zone n’est modifié.

## 21. Pourquoi aucune donnée Selbrume n’a été créée

Les tests utilisent des fixtures locales `map_test`, `event_gate`, `npc_1`, `fact_gate_unlocked`. Les modifications générées accidentellement dans `selbrume/` pendant les tests ont été annulées. Le diff final ne contient aucun fichier Selbrume.

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../lib/src/ui/panels/entity_properties_panel.dart | 105 +++++++++++
 .../lib/src/ui/panels/event_properties_panel.dart  | 156 +++++++++++++++-
 .../event_properties_panel_scene_target_test.dart  | 204 +++++++++++++++++++++
 .../map_canvas_entity_properties_smoke_test.dart   | 102 ++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  16 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  22 ++-
 7 files changed, 589 insertions(+), 17 deletions(-)
```

## 24. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
packages/map_editor/test/event_properties_panel_scene_target_test.dart
packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 25. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart
 M packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
 M packages/map_editor/test/event_properties_panel_scene_target_test.dart
 M packages/map_editor/test/map_canvas_entity_properties_smoke_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart
?? packages/map_core/test/world_rule_target_context_read_model_test.dart
?? packages/map_editor/lib/src/ui/panels/world_rule_target_section.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_27_world_rules_map_editor_integration_v0.png
```

## 26. Evidence Pack

### Contenu des nouveaux fichiers : signatures publiques et sections complètes nouvelles

Les trois fichiers créés côté code sont longs. La preuve ci-dessous reproduit toutes les signatures publiques, tous les widgets/classes ajoutés, toutes les fonctions helpers structurantes et tous les tests ajoutés, conformément à la clause Evidence Pack du prompt pour les fichiers longs.

#### `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart`

Signatures publiques et helpers structurants :

```dart
final class WorldRuleTargetContextReadModel
final class WorldRuleTargetContextRuleView
WorldRuleTargetContextReadModel buildWorldRuleTargetContextReadModel(
  ProjectManifest project, {
  required WorldRuleTargetKind targetKind,
  required String mapId,
  String? entityId,
  String? eventId,
  List<MapData> maps = const <MapData>[],
})
bool _matchesTargetContext(
  WorldRuleTarget target, {
  required WorldRuleTargetKind targetKind,
  required String mapId,
  required String? entityId,
  required String? eventId,
})
int _compareRules(WorldRuleDefinition a, WorldRuleDefinition b)
String _sourceLabel(
  WorldRuleSource source,
  Map<String, NarrativeFactDefinition> factById,
)
String _targetLabel(
  WorldRuleTarget target,
  Map<String, MapData> mapsById,
)
String _effectLabel(
  WorldRuleEffect effect,
  Map<String, ProjectDialogueEntry> dialogueById,
)
```

Sections opérationnelles :

- constructeur immuable avec listes unmodifiable ;
- getters `ruleCount`, `isEmpty`, `diagnostics`, `hasDiagnostics` ;
- filtre `_matchesTargetContext` ;
- tri `_compareRules` ;
- labels `_sourceLabel`, `_targetLabel`, `_effectLabel`.

#### `packages/map_core/test/world_rule_target_context_read_model_test.dart`

Tests ajoutés :

- `finds rules targeting a map event and filters other contexts` ;
- `finds map entity and npc dialogue rules when requested` ;
- `returns diagnostics attached to matching rules only` ;
- `orders rules deterministically by priority then id` ;
- `does not mutate ProjectManifest or require GameState`.

#### `packages/map_editor/lib/src/ui/panels/world_rule_target_section.dart`

Classes/widgets ajoutés :

```dart
final class WorldRuleEventRuleDraft
class WorldRuleTargetSection extends StatefulWidget
class _WorldRuleTargetSectionState extends State<WorldRuleTargetSection>
class _RuleInfoLine extends StatelessWidget
class _StatusPill extends StatelessWidget
class _SectionDivider extends StatelessWidget
```

Sections complètes ajoutées :

- affichage count/empty state/rules ;
- cards de rules avec source/effect/status/diagnostics/toggle ;
- formulaire Event V0 avec label, fact picker, predicate picker, effect picker, switch enabled, bouton create ;
- utilisation de `context.pokeMapColors`.

### Sections modifiées principales

#### `EventPropertiesPanel`

- import `theme.dart` pour éviter un nouveau direct color ref ;
- import `world_rule_target_section.dart` ;
- insertion de `_buildEventWorldRulesSection` avant les pages d’event ;
- ajout de `_createWorldRuleForEvent` ;
- ajout de `_toggleWorldRuleEnabled`.

#### `EntityPropertiesPanel`

- import `world_rule_target_section.dart` ;
- passage de `map` au builder d’entité sélectionnée ;
- insertion de `_buildEntityWorldRuleSections` ;
- ajout de `_toggleWorldRuleEnabled`.

#### Tests editor

- `event_properties_panel_scene_target_test.dart` couvre empty state, affichage, diagnostics, toggle, création ciblée et screenshot V1-27 ;
- `map_canvas_entity_properties_smoke_test.dart` couvre affichage/toggle mapEntity et npcDialogue.

### Diff réel

Les commandes finales `git diff --stat`, `git diff --name-only` et `git diff --check` sont reproduites dans les sections 22 à 25.

### Preuve Visual Gate

Chemin :

```text
/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_27_world_rules_map_editor_integration_v0.png
```

Le screenshot montre :

- event sélectionné ;
- section World Rules visible ;
- règles liées affichées ;
- état Active ;
- source/effet lisibles ;
- diagnostic source Fact absent ;
- formulaire de création V0.

## 27. Auto-review critique

- Est-ce que j’ai modifié map_runtime ? Non.
- Est-ce que j’ai modifié map_battle ? Non.
- Est-ce que j’ai modifié map_gameplay ? Non.
- Est-ce que j’ai branché PlayableMapGame ? Non.
- Est-ce que j’ai branché Event -> Scene runtime ? Non.
- Est-ce que j’ai appliqué une World Rule au runtime ? Non.
- Est-ce que j’ai muté GameState ? Non.
- Est-ce que j’ai ajouté collision/warp/tile dynamique ? Non.
- Est-ce que j’ai créé une donnée Selbrume ? Non.
- Est-ce que les target ids sont auto-remplis depuis le contexte ? Oui pour création Event V0.
- Est-ce que l’utilisateur n’a pas à taper mapId/eventId comme workflow principal ? Oui.
- Est-ce que les diagnostics World Rules sont visibles ? Oui.
- Est-ce que les règles d’autres maps/events ne polluent pas le contexte courant ? Oui, test core et test editor.
- Est-ce que les couleurs/tokens respectent le design system ? Oui, guardrail vert.
- Est-ce que le prochain lot n’a pas été démarré ? Oui.

## 28. Limites restantes

- Création contextuelle avancée `mapEntity` / `npcDialogue` non faite en V1-27.
- Pas de suppression de World Rule depuis les cibles.
- Pas d’édition complète source/effect depuis les cibles.
- Pas d’application runtime des World Rules.
- Le test demandé `narrative_studio_header_test.dart` est absent du repo.
- L’analyse editor ciblée signale deux infos `minSize` préexistantes dans `event_properties_panel.dart`.

## 29. Prochain lot recommandé

`NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep`

Justification : V1-27 retire le blocage produit des World Rules abstraites uniquement en overview. Le prochain travail doit vérifier la chaîne complète via fixtures/tests contrôlés, sans seed produit Selbrume et sans brancher plus large que nécessaire.
