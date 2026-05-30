# NS-SCENES-V1-22 — Payload Pickers V0

## 1. Résumé du lot

Le lot `NS-SCENES-V1-22 — Payload Pickers V0` ajoute le premier authoring de payloads métier dans le Scene Builder en consommant les contrats publics introduits par V1-21.

Résultat livré :

- picker Dialogue Yarn depuis `DialoguePublicContract` ;
- picker Battle trainer depuis `BattlePublicContract` ;
- création de nodes `yarnDialogue` et `battle` via une opération pure dédiée ;
- mise à jour en mémoire de `ProjectManifest.scenes` côté editor ;
- sélection automatique du node ajouté ;
- affichage de diagnostics contractuels dans les pickers ;
- `cinematic`, `action` et `branchByOutcome` restent désactivés honnêtement.

Le lot ne lance aucune scène, ne branche aucun runtime et ne crée aucune donnée produit Selbrume.

## 2. Rappel du scope

Objectif canonique :

```text
Asset -> Public Contract -> Picker / Draft -> Scene Node Payload
```

Décision appliquée :

- Dialogue et Battle sont activés car leurs contrats V1-21 portent des refs réelles et suffisantes.
- Cinematic reste désactivé dans l’UI, même si un contrat bridgeOnly existe, car le bridge `ScenarioAsset` ne doit pas être présenté comme un `CinematicAsset` final.
- Action reste désactivé jusqu’à un futur `ActionPublicContract` / `ConsequencePublicContract`.
- BranchByOutcome reste désactivé jusqu’au mapping explicite `outcome -> edge`.

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

Sorties exactes :

```text
/Users/karim/Project/pokemonProject
main
Sortie git status initial : <vide>
Sortie git diff --stat initial : <vide>
Sortie git diff --name-only initial : <vide>
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
3f9e2671 refactor(editor): route narrative modes to empty inspector
a87ba24a feat(scenes): add world rule model and authoring pipeline
1d5738d9 feat(scenes): add narrative fact registry and integrate into scene authoring
0d8f2b7c feat(scenes): implement scene condition authoring v0 and update workspace tests
```

## 4. Changements préexistants vs changements du lot

Le worktree était propre au démarrage du lot.

Changements introduits par `NS-SCENES-V1-22` :

- opération pure `addSceneLinkedAssetNodeDraft` dans `map_core` ;
- tests core de création/refus de nodes payload-linked ;
- intégration `LinkedAssetContractsSnapshot` dans le workspace Scènes ;
- pickers Dialogue/Battle ;
- états désactivés Cinematic/Action/Branch ;
- tests widget Scene Builder ;
- mise à jour des deux roadmaps ;
- création du présent rapport.

## 5. Fichiers créés/modifiés

Fichier créé :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
```

Fichiers modifiés :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Fichiers absents vérifiés :

```text
Fichier absent : packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
Impact : la commande historique de certains lots précédents n’est pas applicable dans l’état actuel du repo. Le test de navigation overview et le test de projection existants ont été exécutés à la place.
```

## 6. Design retenu

### Core

Une opération pure a été ajoutée :

```dart
SceneNodeDraftCreationResult addSceneLinkedAssetNodeDraft(
  SceneAsset scene, {
  required SceneNodePayload payload,
  String? title,
  String? afterNodeId,
})
```

Raison : `addSceneNodeDraft` V1-12 refuse encore les nodes métier pour éviter les fake refs. V1-22 a besoin d’une opération distincte qui accepte uniquement un payload déjà réel, choisi depuis un contrat public.

Garanties :

- la scène originale n’est pas mutée ;
- `nodes`, `edges`, `layout`, `declaredOutcomes`, `tags`, `metadata`, `description`, `storylineId` et `chapterId` sont préservés ;
- les IDs de nodes sont stables et suffixés ;
- aucune ref n’est générée dans l’opération ;
- les kinds hors scope sont refusés explicitement.

### Editor

`NarrativeWorkspaceCanvas` construit un `LinkedAssetContractsSnapshot` depuis le `ProjectManifest` courant et le passe à `ScenesWorkspace`.

`ScenesWorkspace` expose :

- bouton actif `Dialogue` si `contracts.dialogues` est non vide ;
- bouton actif `Combat` si `contracts.battles` est non vide ;
- bouton désactivé `Cinématique` avec raison `bridge Scenario uniquement` si un bridge existe ;
- bouton désactivé `Action` avec raison `contrat futur requis` ;
- bouton désactivé `Branche` avec raison `mapping futur requis`.

## 7. UI/UX ajoutée

Dialogue picker :

- titre `Choisir un dialogue` ;
- affiche le label lisible ;
- affiche l’id stable ;
- affiche `sourceRef` ;
- affiche le start node si présent ;
- affiche les diagnostics contractuels ;
- sélectionne une option réelle et crée un `SceneYarnDialoguePayload`.

Battle picker :

- titre `Choisir un combat` ;
- affiche le label lisible ;
- affiche `trainerId` ;
- affiche `battleKind` ;
- affiche `trainerLabel` ;
- affiche `victory / defeat` ;
- affiche le warning `Trainer battle has no authored team yet.` ;
- sélectionne une option réelle et crée un `SceneBattlePayload`.

Les options de picker sont rendues avec `PokeMapCard` afin d’accepter label + détails + diagnostics sans overflow dans un bouton compact.

## 8. Contrats publics consommés

Contrats consommés :

```text
LinkedAssetContractsSnapshot
DialoguePublicContract
BattlePublicContract
LinkedAssetContractDiagnostic
```

Contrats lus mais non activés en picker :

```text
CinematicPublicContract
```

Le `CinematicPublicContract` sert uniquement à afficher une raison honnête de désactivation lorsque le seul signal disponible est un bridge `ScenarioAsset`.

## 9. Ce qui reste disabled / bridgeOnly

`Cinematic` :

```text
disabled
raison : bridge Scenario uniquement ou bridge absent
```

`Action` :

```text
disabled
raison : contrat futur requis
```

`BranchByOutcome` :

```text
disabled
raison : mapping futur requis
```

`Start` :

```text
disabled
raison : déjà unique
```

## 10. Pourquoi aucun outcome n’a été inventé

Dialogue/Yarn :

```text
expectedOutcomes = []
```

Le picker n’affiche pas `confident`, `hesitant`, `aggressive`, `success` ou `failure`, car le contrat public V1-21 ne déclare pas encore d’outcomes Yarn.

Battle trainer :

```text
declaredOutcomes = ["victory", "defeat"]
```

Ces outcomes sont autorisés par V1-21 pour les battles trainer.

BranchByOutcome :

```text
disabled
```

Aucun mapping outcome -> edge n’est créé.

## 11. Pourquoi aucune fake ref n’a été créée

Les refs utilisées dans les tests sont neutres et déclarées dans le `ProjectManifest` de test :

```text
test_dialogue
test_trainer
test_cinematic_bridge
```

Refs interdites vérifiées absentes :

```text
dialogue_demo
battle_demo
cinematic_demo
mael_intro
lysa_rival
selbrume_port
trainer_lysa
```

L’opération core reçoit un payload déjà construit depuis un contrat réel et ne fabrique jamais d’identifiant métier.

## 12. Pourquoi aucune donnée Selbrume n’a été créée

Aucun fichier produit Selbrume n’a été modifié.

Les tests emploient uniquement :

```text
Scenes payload picker test
Payload Picker Test Scene
Test Dialogue
Test Trainer
Test Cinematic Bridge
```

Les assertions widget vérifient explicitement l’absence de :

```text
selbrume_port
trainer_lysa
mael_intro
lysa_rival
Annonce au port
```

## 13. Tests exécutés avec sorties exactes

### Core authoring

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie exacte :

```text
00:00 +25: All tests passed!
```

### Core linked asset contracts

Commande :

```bash
cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart
```

Sortie exacte :

```text
00:00 +8: All tests passed!
```

### Editor Scene Workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
00:09 +52: All tests passed!
```

### Editor navigation overview

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie exacte :

```text
00:06 +19: All tests passed!
```

### Editor projection

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:02 +3: All tests passed!
```

### Commande non applicable

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie exacte :

```text
Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart": Does not exist.
```

Impact : fichier absent dans ce repo.

## 14. Analyze avec sortie exacte

### map_core

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

### map_editor ciblé

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
Analyzing 3 items...
No issues found! (ran in 1.0s)
```

### map_editor global

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos
```

Résultat : échec hors scope sur erreurs préexistantes dans `lib/src/application/services/pokemon_sdk_move_catalog_converter.dart` et `lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`.

Premières erreurs exactes capturées :

```text
error • The named parameter 'dbSymbol' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'dbSymbol' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'battleEngineAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository'. Try correcting the name to the name of an existing method, or defining a method named 'fetchPokemonSdkStudioProjectPayload' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

Impact : ces fichiers ne font pas partie du scope V1-22.

## 15. Visual Gate

Visual Gate réalisé par tests widget robustes plutôt que capture dédiée, car le prompt V1-22 autorise un test golden existant, une capture locale ou une description précise si le mécanisme de screenshot dédié n’est pas requis.

Vérifications visuelles couvertes :

- le bouton `Dialogue` est actif quand un `DialoguePublicContract` existe ;
- le picker `Choisir un dialogue` affiche `Test Dialogue`, `test_dialogue`, `dialogues/test_dialogue.yarn`, `Start: Start` et le diagnostic d’outcomes absents ;
- le bouton `Combat` est actif quand un `BattlePublicContract` existe ;
- le picker `Choisir un combat` affiche `Trainer Test Trainer`, `test_trainer`, `trainer`, `victory / defeat` et le warning équipe vide ;
- `Cinématique` reste désactivé avec `bridge Scenario uniquement` ;
- `Action` reste désactivé avec `contrat futur requis` ;
- `Branche` reste désactivé avec `mapping futur requis` ;
- après sélection, le node ajouté apparaît dans le graph et devient sélectionné.

Tests concernés :

```text
dialogue payload picker creates a Yarn node from real contracts
battle payload picker creates trainer battle node from contracts
cinematic action and branch remain honestly disabled
```

## 16. git diff --check

Sortie finale à jour après création complète du rapport :

```text
Sortie : <vide>
```

## 17. git diff --stat

Sortie finale :

```text
 .../src/authoring/scene_authoring_operations.dart  | 112 ++++++
 .../test/scene_authoring_operations_test.dart      |  67 ++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  34 ++
 .../lib/src/ui/canvas/scenes_workspace.dart        | 381 ++++++++++++++++++++-
 .../test/scenes_workspace_shell_test.dart          | 191 +++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  16 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  21 +-
 7 files changed, 798 insertions(+), 24 deletions(-)
```

## 18. git diff --name-only

Sortie finale :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 19. git status final exact

Sortie finale :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
```

## 20. Evidence Pack

### Liste des fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_prep_linked_asset_public_contracts_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
```

### Contenu complet du fichier créé

Ce fichier est le rapport créé pour V1-22. Son contenu complet est le présent document.

### Hunk principal core

```diff
+SceneNodeDraftCreationResult addSceneLinkedAssetNodeDraft(
+  SceneAsset scene, {
+  required SceneNodePayload payload,
+  String? title,
+  String? afterNodeId,
+}) {
+  if (!_isSupportedLinkedAssetPayloadKind(payload.kind)) {
+    throw ArgumentError.value(
+      payload.kind,
+      'payload.kind',
+      'Scene node kind ${payload.kind.name} is not supported by Payload '
+          'Pickers V0.',
+    );
+  }
+  ...
+}
```

### Hunk principal editor

```diff
+          linkedAssetContracts: editor.project == null
+              ? null
+              : buildLinkedAssetContractsSnapshot(editor.project!),
...
+          onAddLinkedAssetNodeDraft: ({
+            required String sceneId,
+            required SceneNodePayload payload,
+            String? title,
+          }) async {
+            ...
+              final result = addSceneLinkedAssetNodeDraft(
+                project.scenes[sceneIndex],
+                payload: payload,
+                title: title,
+              );
+            ...
+          },
```

### Hunk principal UI

```diff
+                  _NodeDraftButton(
+                    buttonKey: hasDialogues
+                        ? const ValueKey('scenes-add-node-yarn')
+                        : const ValueKey('scenes-add-node-yarn-disabled'),
+                    label: 'Dialogue',
+                    icon: CupertinoIcons.text_bubble,
+                    disabledReason: hasDialogues ? null : 'contrat absent',
+                    onPressed: hasDialogues
+                        ? () => _pickDialogueAndAddNode(
+                              context,
+                              contracts!.dialogues,
+                            )
+                        : null,
+                  ),
+                  _NodeDraftButton(
+                    buttonKey: hasBattles
+                        ? const ValueKey('scenes-add-node-battle')
+                        : const ValueKey('scenes-add-node-battle-disabled'),
+                    label: 'Combat',
+                    icon: CupertinoIcons.asterisk_circle,
+                    disabledReason: hasBattles ? null : 'contrat absent',
+                    onPressed: hasBattles
+                        ? () => _pickBattleAndAddNode(
+                              context,
+                              contracts!.battles,
+                            )
+                        : null,
+                  ),
```

### Hunk principal tests

```diff
+    testWidgets(
+        'dialogue payload picker creates a Yarn node from real contracts',
+        (tester) async {
+      ...
+      expect(payload.dialogueId, 'test_dialogue');
+      expect(payload.yarnNodeName, 'Start');
+      expect(payload.expectedOutcomes, isEmpty);
+      expect(find.text('dialogue_demo'), findsNothing);
+      expect(find.text('selbrume_port'), findsNothing);
+    });
```

## 21. Auto-review critique

- Est-ce que j’ai modifié du runtime ? Non.
- Est-ce que j’ai modifié `map_battle` ? Non.
- Est-ce que j’ai modifié `map_gameplay` ? Non.
- Est-ce que j’ai modifié `ProjectManifest` ? Non.
- Est-ce que j’ai modifié `SceneAsset` ? Non.
- Est-ce que j’ai inventé des refs ? Non.
- Est-ce que j’ai inventé des outcomes Yarn ? Non.
- Est-ce que j’ai créé des données Selbrume ? Non.
- Est-ce que j’ai activé BranchByOutcome ? Non.
- Est-ce que j’ai activé ActionNode sans contrat public Action/Consequence ? Non.
- Est-ce que j’ai présenté `ScenarioAsset` comme `CinematicAsset` final ? Non.
- Est-ce que les pickers consomment bien les contrats publics V1-21 ? Oui.
- Est-ce que le prochain lot reste bien V1-23 et n’a pas été démarré ? Oui.

Point critique : l’opération core accepte un payload `cinematic` si un appel futur lui fournit une vraie ref, mais l’UI V1-22 ne l’expose pas. Ce choix garde l’opération générique pour payloads liés tout en respectant la décision produit : Cinematic reste désactivé tant que le bridge Scenario n’est pas un modèle final.

## 22. Limites et prochain lot recommandé

Limites :

- pas de picker Cinematic actif ;
- pas d’Action Registry ;
- pas de Consequence authoring ;
- pas de BranchByOutcome mapping ;
- pas de validation project-aware des refs liées au moment de l’ajout, au-delà des contrats affichés ;
- pas de runtime ;
- pas d’Event -> Scene.

Prochain lot recommandé :

```text
NS-SCENES-V1-23 — Event to Scene Trigger Prep
```

Raison : les scènes peuvent maintenant pointer vers de vrais dialogues et combats. Le prochain blocage du golden slice est de préparer le lien Event local -> Scene V1 sans lancer encore l’exécution runtime.
