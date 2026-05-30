# NS-SCENES-V1-23 — Event to Scene Trigger Prep

## 1. Resume du lot

`NS-SCENES-V1-23 — Event to Scene Trigger Prep` est realise en architecture prep / documentation-first.

Decision principale : le plus petit contrat honnete pour relier un Event local de map a une Scene V1 n'est pas un `sceneId` pose directement sur `MapEventDefinition`. Le bon niveau cible est la page/action active de l'event : une action explicite `startScene` ou un `sceneTarget` equivalent porte par `MapEventPage`, avec reference vers une `SceneAsset` reelle dans `ProjectManifest.scenes`.

Le lot ne code pas ce lien persistant, parce que `MapEventDefinition` est un modele Freezed/JSON genere et que le changement doit etre isole, teste et assume dans un lot dedie. Le prochain lot recommande est donc :

```text
NS-SCENES-V1-23-bis — Event to Scene Link V0
```

## 2. Rappel du scope

Objectif du lot :

```text
Map/Event local -> reference vers Scene V1
```

Ce lot devait preparer la liaison sans :

- lancer une Scene en runtime ;
- creer `SceneRuntimePlan` ;
- creer `SceneRuntimeExecutor` ;
- brancher `StorylineStep.sceneLinkIds` ;
- migrer ou promouvoir `ScenarioAsset` ;
- ajouter une fixture Selbrume ;
- inventer une scene, un event ou une ref.

Scope realise :

- audit des modeles Event, Scene et manifest ;
- audit du flux editor actuel des map events ;
- audit du flux runtime legacy Event / Script / Scenario ;
- comparaison des options A/B/C/D ;
- decision de contrat ;
- mise a jour des roadmaps.

## 3. Gate 0 complet

Commande executee depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties exactes :

```text
/Users/karim/Project/pokemonProject
main
git status initial :
Sortie : <vide>
git diff --stat initial :
Sortie : <vide>
git diff --name-only initial :
Sortie : <vide>
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
```

## 4. Changements preexistants vs changements du lot

Changements preexistants :

```text
Sortie : <vide>
```

Changements introduits par `NS-SCENES-V1-23` :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_23_event_to_scene_trigger_prep.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Aucun fichier Dart, widget, modele, runtime, gameplay, battle ou example n'est modifie.

## 5. Fichiers lus

Fichiers d'instructions et prompt :

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/3193132c-4429-4573-9b75-880b214d1045/pasted-text.txt
```

Roadmaps et rapports :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
```

Modeles et operations core :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart
packages/map_core/lib/src/authoring/narrative_event_source_authoring_operations.dart
```

Editor :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
```

Runtime audite en lecture seule :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
```

Chemins obligatoires absents :

```text
Sortie : <vide>
```

## 6. Audit des modeles Event existants

### MapEventDefinition

Extrait audite :

```dart
@freezed
class MapEventDefinition with _$MapEventDefinition {
  @JsonSerializable(explicitToJson: true)
  const factory MapEventDefinition({
    required String id,
    @Default('') String title,
    required List<MapEventPage> pages,
    required EventPosition position,
    @Default(MapEventType.actor) MapEventType type,
    @Default({}) Map<String, String> metadata,
  }) = _MapEventDefinition;
}
```

Analyse :

- L'event est un conteneur positionne sur la map.
- Il peut avoir plusieurs pages.
- Le champ `metadata` existe, mais l'utiliser comme contrat produit `sceneId` serait trop implicite et non no-code.
- Ajouter `sceneId` a ce niveau serait trop large : une Scene peut dependre de la page active et donc des conditions de page.

### MapEventPage

Extrait audite :

```dart
@freezed
class MapEventPage with _$MapEventPage {
  @JsonSerializable(explicitToJson: true)
  const factory MapEventPage({
    required int pageNumber,
    ScriptCondition? condition,
    ScriptRef? script,
    String? spriteId,
    String? message,
    @Default(false) bool isHidden,
    @Default(false) bool isDisabled,
    @Default({}) Map<String, String> metadata,
  }) = _MapEventPage;
}
```

Analyse :

- La page est le niveau naturel de resolution : conditions, script, message, hidden/disabled.
- Le futur lien Scene doit etre au niveau page ou action de page, pas au niveau event global.
- V1-23-bis devra decider si le champ s'appelle `sceneTarget`, `action`, `interaction`, ou si un petit modele `MapEventPageAction.startScene(sceneId)` est preferable.

### ScriptRef

Extrait audite :

```dart
@freezed
class ScriptRef with _$ScriptRef {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptRef({
    required String scriptId,
    String? startNode,
  }) = _ScriptRef;
}
```

Analyse :

- Le chemin script existe deja pour les pages d'event.
- Le futur lien Scene ne doit pas etre encode comme un `scriptId`.
- Un Event peut garder `script` et `message` pour legacy/flows simples, mais la liaison Scene V1 doit etre explicite.

### MapData

Extrait audite :

```dart
@freezed
class MapData with _$MapData {
  @JsonSerializable(explicitToJson: true)
  const factory MapData({
    required String id,
    required String name,
    required GridSize size,
    @Default([]) List<MapEventDefinition> events,
  }) = _MapData;
}
```

Analyse :

- Les events sont stockes dans les maps, pas dans `ProjectManifest`.
- Les scenes sont stockees dans `ProjectManifest.scenes`.
- Un diagnostic Event -> Scene devra donc croiser `MapData.events` et `ProjectManifest.scenes`.

### ProjectManifest.scenes

Extrait audite :

```dart
@Default([])
@JsonKey(
  name: 'scenes',
  fromJson: _scenesFromJson,
  toJson: _scenesToJson,
)
List<SceneAsset> scenes,
```

Analyse :

- `ProjectManifest.scenes` est le stockage canonique des Scene V1.
- Le futur lien Event -> Scene doit pointer vers ces scenes, pas vers `ScenarioAsset`.

## 7. Audit des liens legacy Event / Scenario / Script

### Editor map events

Extrait audite dans `EditorNotifier` :

```dart
void addMapEventAt(GridPos pos) {
  final created = MapEventDefinition(
    id: eventId,
    title: eventId,
    position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
    pages: const [
      MapEventPage(
        pageNumber: 0,
        message: '',
      ),
    ],
  );
}
```

Extrait audite dans `EventPropertiesPanel` :

```dart
final updatedScript = _buildScriptRefFromDraft();
nextPages[safePageIndex] = selectedPage.copyWith(
  pageNumber: pageNumber,
  message: _normalizeOptional(_pageMessageController.text),
  condition: updatedCondition,
  script: updatedScript,
);
```

Analyse :

- L'UI event actuelle sait editer le message, la condition et le script d'une page.
- Elle ne connait pas `ProjectManifest.scenes` comme cible event.
- V1-23-bis devra ajouter un picker Scene depuis `ProjectManifest.scenes`, sans champ texte libre comme workflow principal.

### Runtime map event

Extrait audite :

```dart
void _handleMapEventInteraction(
  MapEventDefinition event,
  ActiveEventPage page,
) {
  if (page.page.script != null) {
    final message = page.page.message?.trim();
    if (message != null && message.isNotEmpty) {
      _showNotification(message);
    }
    _executeEventScript(event, page, page.page.script!);
  } else if (page.page.message != null && page.page.message!.isNotEmpty) {
    _showNotification(page.page.message!);
  } else {
    _showNotification('...');
  }
}
```

Analyse :

- Le runtime actuel execute seulement `script` ou affiche `message` pour les map events.
- V1-23 ne modifie pas ce runtime.
- V1-23-bis doit rester authoring/validation sans execution ; le branchement runtime viendra apres `SceneRuntimePlan V0`.

### ScenarioRuntimeExecutor

Extrait audite :

```dart
enum ScenarioRuntimeSourceType {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}
```

Extrait audite :

```dart
/// Bridge d'execution runtime du Scenario Graph (MVP).
///
/// Portee volontairement limitee du MVP :
/// - sources supportees: map enter / trigger enter / entity interact
///   + outcome recu (pont local -> global),
/// - nodes supportes: start, reference(source uniquement), dialogue, action,
///   condition simple (via ScriptConditionEvaluator), end
class ScenarioRuntimeExecutor {
```

Analyse :

- ScenarioRuntimeExecutor confirme qu'un pattern source runtime existe deja.
- Il reste un bridge Scenario, pas le modele produit Scene V1.
- Option D est donc refusee : utiliser ScenarioRuntimeExecutor directement pour Event -> Scene recreerait la confusion que Scene V1 essaie de dissoudre.

## 8. Options comparees

| Option | Verdict | Pourquoi |
|---|---|---|
| A — `sceneId` direct dans `MapEventDefinition` | Rejetee pour V1-23 et deconseillee comme cible | Simple, mais ignore les pages conditionnelles. Un event peut changer de comportement selon `MapEventPage.condition`; le lien scene doit suivre la page active. Changement Freezed/JSON/generated sensible. |
| B — action/event target dediee `startScene` | Retenue comme contrat cible | Explicite, no-code, proche de la grammaire produit `Quand / Si / Alors Scene`, compatible avec futur runtime, et distinct de Script/Scenario. |
| C — read model / draft non persistant | Retenue comme posture de V1-23 uniquement | Faible risque, respecte audit-first, evite generated files. Ne ferme pas encore le lien authorable, donc V1-23-bis est necessaire. |
| D — utiliser `ScenarioAsset` ou legacy | Rejetee | Risque de faire de `ScenarioAsset.localEventFlow` le modele final de Scene V1. Contredit les decisions canoniques V1-10/V1-21. |

## 9. Decision retenue

Option retenue :

```text
V1-23 = Option C pour le lot actuel, avec Option B comme cible d'implementation.
```

Contrat cible recommande pour V1-23-bis :

```text
MapEventPage
  -> scene target explicite
  -> kind: startScene
  -> sceneId: <id de SceneAsset existante>
  -> aucun runtime implicite
```

Regles recommandees :

- le lien vit au niveau de la page active ou d'une action explicite de page ;
- `sceneId` reference une `SceneAsset` reelle dans `ProjectManifest.scenes` ;
- event sans scene target reste valide ;
- scene target vers scene inconnue = diagnostic error ;
- scene cible avec diagnostics Scene errors = diagnostic error ou warning bloquant runtime selon maturite V1-25 ;
- `ScriptRef` et `message` restent legacy/simples, mais ne sont pas convertis en Scene ;
- aucune conversion automatique `SceneAsset -> ScenarioAsset` ;
- aucune conversion automatique `ScenarioAsset -> SceneAsset`.

## 10. Risques et limites

Risques identifies :

- toucher `MapEventDefinition` implique Freezed/JSON generated et tests de compatibilite ;
- ajouter une action `startScene` trop vite peut creer un deuxieme systeme de script cache si elle n'est pas bornee ;
- mixer `script`, `message` et `sceneTarget` sans regle UI claire peut rendre l'event ambigu ;
- diagnostiquer Event -> Scene necessite de croiser maps chargees et `ProjectManifest.scenes`.

Limites du lot :

- aucun champ persiste Event -> Scene n'est ajoute ;
- aucun picker Scene dans l'Event panel ;
- aucun diagnostic Event -> Scene code ;
- aucun test Dart/Flutter execute, car aucun code n'est modifie ;
- `git diff --check` reste le check obligatoire du lot documentation-only.

## 11. Ce qui n'a pas ete code et pourquoi

Non code :

- `MapEventDefinition.sceneId` ;
- `MapEventPage.sceneTarget` ;
- `MapEventPageAction.startScene` ;
- diagnostics Event -> Scene ;
- picker editor Scene dans `EventPropertiesPanel` ;
- branchement runtime dans `PlayableMapGame` ;
- `SceneRuntimePlan` ;
- `SceneRuntimeExecutor`.

Pourquoi :

- le modele Event est genere et le prompt demandait de ne pas forcer un changement lourd JSON/generated ;
- l'audit montre que le bon niveau est la page/action, pas l'event global ;
- l'implementation persistante merite un lot separe avec tests JSON, operations pures, validation et UI bornee.

## 12. Impact sur Event -> Scene

Impact direct :

- la roadmap est alignee sur un lien `MapEventPage -> Scene V1` explicite ;
- `NS-SCENES-V1-23-bis — Event to Scene Link V0` est insere avant RuntimePlan ;
- les futures operations devront remplacer uniquement la map/page ciblee en memoire, sans toucher aux autres maps/scenes.

Contrat authoring futur recommande :

```text
Event local
  page active resolue par conditions existantes
  action startScene(sceneId)
  sceneId valide dans ProjectManifest.scenes
  execution runtime absente jusqu'a SceneRuntimePlan/Executor
```

## 13. Impact sur RuntimePlan V1-24

`SceneRuntimePlan V0` reste necessaire, mais il devient plus utile apres V1-23-bis :

- il saura compiler une Scene ciblee par un Event reel ;
- il ne dependra toujours pas de `SceneGraphLayout` ;
- il devra refuser les scenes avec diagnostics error ;
- il ne devra pas lire `MapEventDefinition` directement pour compiler la Scene, seulement la Scene cible.

Recommendation : garder `NS-SCENES-V1-24 — Scene Runtime Plan V0` apres `NS-SCENES-V1-23-bis`.

## 14. Impact sur Diagnostics V1-25

Diagnostics futurs requis :

| Code recommande | Severity | Quand |
|---|---|---|
| `eventSceneTargetUnknown` | error | Un event/page cible un `sceneId` absent de `ProjectManifest.scenes`. |
| `eventSceneTargetInvalid` | error | La Scene cible a des diagnostics Scene error. |
| `eventSceneTargetLegacyScenario` | warning/error | Un event/page tente de cibler un scenario legacy comme si c'etait une Scene V1. |
| `eventSceneTargetDisabledPage` | info/warning | Une page disabled porte un target scene ; non executable tant que disabled. |
| `eventSceneTargetAmbiguousAction` | error | Une page definit plusieurs actions principales incompatibles si V1-23-bis autorise une union exclusive. |

V1-25 devra aussi afficher ces diagnostics dans le Scene Builder et/ou l'Event panel sans corriger automatiquement.

## 15. Tests/checks executes

Documentation-only :

```text
dart analyze non requis
flutter analyze non requis
dart test non requis
flutter test non requis
```

Check execute :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 16. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
Sortie : <vide>
```

## 17. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 20 ++++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 23 ++++++++++++++++++----
 2 files changed, 36 insertions(+), 7 deletions(-)
```

## 18. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 19. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_23_event_to_scene_trigger_prep.md
```

## 20. Evidence Pack

### Sorties exactes des commandes Git

Gate 0 :

```text
/Users/karim/Project/pokemonProject
main
git status initial :
Sortie : <vide>
git diff --stat initial :
Sortie : <vide>
git diff --name-only initial :
Sortie : <vide>
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
```

Final :

```text
git diff --check :
Sortie : <vide>

git diff --stat :
 .../scenes/road_map_scene_builder_authoring.md     | 20 ++++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 23 ++++++++++++++++++----
 2 files changed, 36 insertions(+), 7 deletions(-)

git diff --name-only :
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status final :
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_23_event_to_scene_trigger_prep.md
```

### Contenu complet du rapport cree

Le fichier cree est :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_23_event_to_scene_trigger_prep.md
```

Le contenu complet du rapport est le present document, de la ligne de titre `# NS-SCENES-V1-23 — Event to Scene Trigger Prep` jusqu'a la section `22. Prochain lot recommande`.

### Extraits precis des modeles audites

`MapEventDefinition` :

```dart
const factory MapEventDefinition({
  required String id,
  @Default('') String title,
  required List<MapEventPage> pages,
  required EventPosition position,
  @Default(MapEventType.actor) MapEventType type,
  @Default({}) Map<String, String> metadata,
}) = _MapEventDefinition;
```

`MapEventPage` :

```dart
const factory MapEventPage({
  required int pageNumber,
  ScriptCondition? condition,
  ScriptRef? script,
  String? spriteId,
  String? message,
  @Default(false) bool isHidden,
  @Default(false) bool isDisabled,
  @Default({}) Map<String, String> metadata,
}) = _MapEventPage;
```

`ProjectManifest.scenes` :

```dart
@Default([])
@JsonKey(
  name: 'scenes',
  fromJson: _scenesFromJson,
  toJson: _scenesToJson,
)
List<SceneAsset> scenes,
```

Runtime map event :

```dart
if (page.page.script != null) {
  final message = page.page.message?.trim();
  if (message != null && message.isNotEmpty) {
    _showNotification(message);
  }
  _executeEventScript(event, page, page.page.script!);
} else if (page.page.message != null && page.page.message!.isNotEmpty) {
  _showNotification(page.page.message!);
} else {
  _showNotification('...');
}
```

### Diff complet de `road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 26e1ad50..2b594bcc 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -65,7 +65,8 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-21-prep — Linked Asset Public Contracts Audit | DONE | Audit documentaire des contrats publics exposes au Scene Builder par Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et outcomes avant pickers. |
 | NS-SCENES-V1-21 — Linked Asset Contracts V0 | DONE | Contrats/read models publics minimaux dans `map_core` : Dialogue, Battle trainer, Cinematic scenarioBridge, snapshot agrege, diagnostics, statuts et outcomes disponibles, sans runtime ni UI picker. |
 | NS-SCENES-V1-22 — Payload Pickers V0 | DONE | Ajouter des pickers/drafts honnetes pour Dialogue Yarn et Battle trainer depuis les contrats publics V1-21 ; Cinematic reste bridgeOnly/desactive, Action et Branch restent desactives. |
-| NS-SCENES-V1-23 — Event to Scene Trigger Prep | TODO | Preparer le lien Event local/runtime -> Scene V1, plus prioritaire que StorylineStep pour Selbrume, sans execution runtime complete. |
+| NS-SCENES-V1-23 — Event to Scene Trigger Prep | DONE | Decision Event -> Scene : viser un contrat explicite page/action `startScene`, ne pas ajouter `sceneId` direct sur l'event entier, ne pas reutiliser `ScenarioAsset`, et reporter l'implementation persistante a un bis cible. |
+| NS-SCENES-V1-23-bis — Event to Scene Link V0 | TODO | Implementer le lien authoring persistant minimal `MapEventPage -> Scene V1` avec refs validables et diagnostics, sans runtime Scene ni migration legacy. |
 | NS-SCENES-V1-24 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
 | NS-SCENES-V1-25 — Diagnostics / Validator Expansion | TODO | Etendre diagnostics aux refs, ports, outcomes non geres, unreachable/cycles, payloads incomplets, Facts et World Rules. |
 | NS-SCENES-V1-26 — Scene Runtime Executor MVP | TODO | Executer un sous-ensemble Scene V1 depuis un `SceneRuntimePlan`, sans passer par `ScenarioAsset` comme modele produit. |
@@ -75,14 +76,28 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-23 — Event to Scene Trigger Prep`
+`NS-SCENES-V1-23-bis — Event to Scene Link V0`
 
-Raison : V1-22 permet maintenant d'ajouter des nodes Dialogue Yarn et Battle trainer depuis des contrats publics reels, sans champ d'ID brut ni fake ref. La scene peut commencer a pointer vers du contenu metier honnete ; le prochain blocage produit est donc de preparer comment un Event local pourra cibler une Scene V1 sans brancher encore le runtime complet.
+Raison : V1-23 a tranche le contrat sans modifier les modeles sensibles. Le bon niveau n'est pas `MapEventDefinition.sceneId`, mais une cible explicite de page/action `startScene`, car les pages d'event portent deja conditions, message/script et activation. L'implementation doit maintenant etre isolee dans un lot V1-23-bis avec tests JSON/authoring/diagnostics, sans runtime Scene.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion et Runtime Executor MVP.
 
 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
+## Decisions V1-23
+
+- Lot architecture/audit uniquement : aucun code Dart, widget, modele persiste, generated file, runtime, test ou fixture Selbrume n'est ajoute.
+- Decision principale : le plus petit contrat honnete pour Event -> Scene doit vivre au niveau de la page/action active d'un event, sous une forme explicite `startScene` ou equivalente.
+- Option A `sceneId` directement sur `MapEventDefinition` est rejetee pour V1 : trop coarse pour un event a pages conditionnelles, et trop risquee comme changement JSON/generated.
+- Option B `startScene` dedie est retenue comme contrat cible : elle garde le declencheur Event distinct de la Scene, evite un script cache, et prepare le runtime futur.
+- Option C read model/draft non persistant est retenue seulement comme posture de V1-23 : documenter et cadrer sans migration.
+- Option D `ScenarioAsset`/legacy est rejetee : ScenarioRuntimeExecutor peut inspirer le flux, mais ne devient pas le modele produit Scene V1.
+- Le futur lien devra referencer une `SceneAsset` reelle dans `ProjectManifest.scenes`, produire diagnostics refs inconnues, et refuser execution tant que la scene cible a des erreurs bloquantes.
+- `StorylineStep.sceneLinkIds` reste desactive ; Event -> Scene reste prioritaire pour Selbrume.
+- Checks executes : `git diff --check`.
+
+Prochain lot exact : `NS-SCENES-V1-23-bis — Event to Scene Link V0`.
+
 ## Decisions V1-22
```

### Diff complet de `road_map_scene_builder_authoring.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index df4b9a68..40c801b3 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-23 — Event to Scene Trigger Prep
+NS-SCENES-V1-23-bis — Event to Scene Link V0
 ```
 
 ## Principes
@@ -44,7 +44,8 @@ NS-SCENES-V1-23 — Event to Scene Trigger Prep
 | NS-SCENES-V1-21-prep | Linked Asset Public Contracts Audit | doc-only / architecture-review | Auditer Dialogue Yarn, Cinematic/Cutscene, Battle, Action/Consequence et BranchByOutcome avant les pickers. | Pas de code, pas de widget, pas de modele, pas de tests, pas de build_runner. | rapport V1-21-prep, roadmaps. | DONE : `git diff --check`. | Lancer des pickers d'IDs bruts ; confondre contrats publics et implementation interne. | DONE : contrats publics recommandes, node verdicts, V1-21 ajuste vers Linked Asset Contracts V0. | V1-20-checkpoint. |
 | NS-SCENES-V1-21 | Linked Asset Contracts V0 | core / doc | Formaliser les contrats/read models publics minimaux consommes par Scene Builder : refs stables, labels, existence, diagnostics, outputs/outcomes et contraintes. | Pas de runtime, pas de UI picker complet, pas de CinematicAsset final improvise, pas de ScenarioAsset canonique pour Scene. | read models/contract docs selon decision, diagnostics refs si bornes. | DONE : tests contrats/read models purs + `dart analyze`. | Sur-modeliser ; exposer trop d'internals ; retarder inutilement Yarn/Battle prets. | DONE : Dialogue/Battle/Cinematic bridge exposent contrats publics ; Action/Branch restent disabled. | V1-21-prep. |
 | NS-SCENES-V1-22 | Payload Pickers V0 | editor / core | Remplacer IDs libres par pickers/drafts honnetes en consommant les contrats publics : Dialogue Yarn et Battle trainer V0 ; Cinematic bridgeOnly reste desactive prudemment. | Pas de runtime, pas de full payload editor, pas de seed Selbrume, pas de refs tapees a la main en workflow normal, pas d'Action/Branch actifs. | workspace Scenes, operations authoring, tests Scene Builder. | DONE : tests pickers refs reelles, diagnostics visibles, outcomes Yarn non inventes, battle victory/defeat, boutons honnetes. | Faux contenus Selbrume, refs tapees a la main, branch nodes actifs sans outcome source. | DONE : Dialogue/Battle configurables avec vraies refs, Cinematic/Action/Branch restent honnetement desactives, aucun fake ref. | V1-21. |
-| NS-SCENES-V1-23 | Event to Scene Trigger Prep | core / editor / doc | Preparer le lien Event local/runtime -> Scene V1. | Pas encore runtime complet, pas StorylineStep link, pas de migration ScenarioAsset. | event models/authoring si decide, reports, tests refs. | Tests Event ref scene, conditions, no migration legacy. | Brancher trop tot sur MapEventDefinition legacy ; cibler des scenes incompletes. | Un Event peut referencer une Scene de maniere valide/honnete, sans execution si runtime absent. | V1-21, V1-22. |
+| NS-SCENES-V1-23 | Event to Scene Trigger Prep | doc / architecture-review | Auditer les events existants et decider le contrat minimal Event local -> Scene V1. | Pas de modele persiste, pas de generated files, pas de runtime, pas de StorylineStep link, pas de migration ScenarioAsset. | rapport V1-23, roadmaps. | DONE : `git diff --check`. | Coder trop vite un champ `sceneId` au mauvais niveau ; recreer un script cache. | DONE : decision `startScene` page/action retenue, implementation reportee a un bis. | V1-21, V1-22. |
+| NS-SCENES-V1-23-bis | Event to Scene Link V0 | core / editor | Implementer le lien authoring persistant minimal `MapEventPage -> Scene V1` avec refs reelles, diagnostics et UI/picker bornes, sans execution runtime. | Pas de SceneRuntimePlan, pas de runtime Scene, pas de StorylineStep link, pas de ScenarioAsset final, pas de fake event/scene. | `map_event_definition.dart` ou contrat dedie si valide, operations map events, validators/diagnostics, event properties panel, tests. | Tests JSON/ops/validator/editor cible : scene existante OK, scene manquante error, event sans scene OK, refs legacy non promues. | Toucher Freezed/JSON/generated ; melanger script/message/scene ; rendre le runtime implicite. | Un event/page peut cibler une Scene reelle de facon visible et validable, sans execution. | V1-23. |
 | NS-SCENES-V1-24 | Scene Runtime Plan V0 | core | Ajouter `SceneRuntimePlan`, intents, builder pur depuis `SceneAsset` valide. | Pas d'execution runtime, pas de Flutter, pas de `ScenarioAsset` auto. | `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`, tests core. | Draft minimal, yarn/battle/cinematic/action intents, diagnostics error bloque, layout ignore. | Figer trop tot un executor ; dupliquer ScenarioRuntime ; ignorer Event -> Scene. | Plan pur testable, ignore layout, refuse scenes invalides. | V1-22, V1-23 utile. |
 | NS-SCENES-V1-25 | Diagnostics / Validator Expansion | core / editor | Etendre diagnostics aux refs, ports requis, outcomes non geres, unreachable, cycles, sources conditions, facts, world rules et Event -> Scene. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, diagnostics world rules/event, UI diagnostics. | Tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | Builder guide l'auteur sans empecher draft minimal valide, erreurs runtime bloquantes explicites. | V1-22, V1-23, V1-24. |
 | NS-SCENES-V1-26 | Scene Runtime Executor MVP | runtime / core | Executer un sous-ensemble `SceneRuntimePlan` : start/end/dialogue/cinematic/battle/action via callbacks limites. | Pas de full bridge ScenarioAsset, pas StorylineStep link, pas de consequences persistantes implicites. | `map_runtime` scene executor, tests runtime. | Tests invalid scene blocked, dialogue/action/end outcomes, no layout dependency. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites. | Executor lance un plan minimal, callbacks explicites, aucun ScenarioAsset canonique. | V1-24, V1-25. |
@@ -247,6 +248,18 @@ Limites : pas de runtime, pas de Event -> Scene, pas de SceneRuntimePlan, pas de
 
 Prochain lot exact : `NS-SCENES-V1-23 — Event to Scene Trigger Prep`.
 
+## Mise a jour V1-23
+
+Statut : `NS-SCENES-V1-23 — Event to Scene Trigger Prep` est DONE.
+
+Decision : V1-23 ne code pas encore le lien persistant. L'audit montre que `MapEventDefinition` est un modele Freezed/JSON genere et que le bon niveau produit n'est pas l'event entier, mais la page/action active. Le contrat cible devient donc une action explicite `startScene` ou un `sceneTarget` equivalent porte par `MapEventPage`, avec reference vers une `SceneAsset` reelle et diagnostics refs inconnues.
+
+Options rejetees : `MapEventDefinition.sceneId` direct, car il ignore les pages conditionnelles ; metadata string libre, car trop implicite ; `ScenarioAsset`, car il resterait un bridge legacy et deviendrait trop facilement le modele final.
+
+Limites : aucun code, aucun widget, aucun modele, aucun generated file, aucun runtime et aucune donnee Selbrume ne sont ajoutes.
+
+Prochain lot exact : `NS-SCENES-V1-23-bis — Event to Scene Link V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
@@ -256,7 +269,8 @@ Avant le golden slice, il faut au minimum :
 - Visual Port Connection UX V0 pour rendre la construction de graph utilisable sans ambiguite.
 - Linked Asset Contracts V0 avant Payload Pickers, pour eviter que les pickers ne soient de simples selecteurs d'IDs bruts.
 - Payload Pickers V0 pour Yarn, battle, cinematic/action.
-- Event to Scene Trigger Prep pour relier map/event et Scene V1 sans StorylineStep comme declencheur.
+- Event to Scene Trigger Prep pour decider le contrat Event local -> Scene V1 sans StorylineStep comme declencheur.
+- Event to Scene Link V0 pour authorer et valider ce lien avant toute execution.
 - Scene Runtime Plan V0 pour compiler une Scene valide en intents sans layout.
 - Diagnostics Expansion.
 - World Rules V0 pour les consequences visibles controlees.
```

## 21. Auto-review critique

- Est-ce que j'ai modifie le runtime ? Non.
- Est-ce que j'ai modifie `map_battle` ? Non.
- Est-ce que j'ai modifie `map_gameplay` ? Non.
- Est-ce que j'ai modifie `examples` ? Non.
- Est-ce que j'ai modifie `MapEventDefinition`, `MapData`, `ProjectManifest` ou des generated files ? Non.
- Est-ce que j'ai branche `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j'ai fait de `ScenarioAsset` le modele final de Scene ? Non, il est explicitement rejete comme cible.
- Est-ce que j'ai cree une fixture Selbrume ? Non.
- Est-ce que j'ai invente une scene/event/ref ? Non.
- Est-ce que j'ai lance l'execution runtime d'une Scene ? Non.
- Est-ce que la decision Event -> Scene est claire ? Oui : `startScene` page/action, pas `sceneId` event global.
- Est-ce que le prochain lot est coherent ? Oui : V1-23-bis implemente le lien authoring/validation avant RuntimePlan.

Regard critique :

- Le lot est volontairement plus prudent que productif en code. C'est le bon arbitrage car le changement persistant touche un modele Freezed/JSON sensible.
- La roadmap ajoute un bis, ce qui ralentit legerement l'arrivee de `SceneRuntimePlan`, mais evite de figer un contrat event au mauvais niveau.
- V1-23-bis devra etre tres strict : une seule action principale de scene si possible, picker Scene obligatoire, diagnostics refs inconnues, et aucune execution runtime.

## 22. Prochain lot recommande

```text
NS-SCENES-V1-23-bis — Event to Scene Link V0
```

Objectif recommande :

- ajouter le plus petit contrat persiste et testable `MapEventPage -> Scene V1` ;
- choisir une forme explicite `startScene` / `sceneTarget` ;
- exposer un picker Scene dans l'Event panel ;
- valider `sceneId` contre `ProjectManifest.scenes` ;
- conserver `script`/`message` sans migration ;
- ne pas executer la Scene ;
- ne pas creer `SceneRuntimePlan` dans ce bis.
