# NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision

## 1. Résumé exécutif

V1-36 est réalisé en documentaire uniquement.

Décision canonique : Cinematic V1 ne doit pas être un `ScenarioAsset` renommé. Le futur modèle produit doit être un `CinematicAsset` dédié, linéaire, visuel, référençable par une Scene, diagnostiquable et organisé dans une Cinematics Library.

Le bridge existant reste utile, mais explicitement transitoire :

- Cutscene Studio continue de produire des `ScenarioAsset` marqués par metadata `authoring.cutsceneSchema`.
- `CinematicPublicContract.scenarioBridge` reste un bridge legacy avec statut `bridgeOnly`.
- `SceneRuntimePlanIntent.playCinematic(cinematicId)` reste le seam d'orchestration côté Scene, mais son implémentation runtime actuelle ne joue pas encore une vraie Cinematic V1.
- `ScenarioRuntimeExecutor` et `CutsceneRuntimeRunner` restent des outils legacy/runtime bridge, pas le contrat produit final.

Prochain lot exact recommandé :

```text
NS-SCENES-V1-37 — CinematicAsset Core Model V0
```

## 2. Pourquoi V1-36 existe

Après V1-35, Facts et World Rules ont un manager no-code centralisé. Le prochain trou produit majeur est Cinematic : l'ancien Cutscene Studio existe, mais il compile vers `ScenarioAsset`, qui est un graphe généraliste capable de branches, sources runtime, flags, outcomes, scripts, battle et progression locale.

Le risque serait de faire glisser ce legacy dans le produit final par inertie. V1-36 existe pour trancher avant toute Cinematics Library ou Cinematic Builder V2.

## 3. Rappel du scope

Scope autorisé :

- audit documentaire ;
- analyse produit ;
- analyse technique ;
- décision de bridge ;
- roadmap ;
- mise à jour des roadmaps.

Non-objectifs respectés :

- aucun code Dart ;
- aucun widget Flutter ;
- aucun modèle Freezed/JSON ;
- aucun generated file ;
- aucun runtime adapter ;
- aucune migration ;
- aucune donnée Selbrume ;
- aucun changement de `ProjectManifest` ou `SceneAsset`.

## 4. Gate 0 complet

Commande initiale exécutée depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all
Sortie : <vide>
git diff --stat
Sortie : <vide>
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
```

Commande de Gate 0 relancée avec libellés :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all
Sortie : <vide>
git diff --stat
Sortie : <vide>
git diff --name-only
Sortie : <vide>
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
df2998d3 feat(scenes): add node payload editing v0
84587492 feat(scenes): add storyline step scene links v0
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
```

## 5. Fichiers lus

Fichiers d'instructions :

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/ffc38d84-a22f-4df4-9fa2-3d12569e2282/pasted-text.txt
```

Roadmaps et rapports Scene :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_34_world_rules_runtime_projection_hook_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md
reports/narrativeStudio/scenes/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_prep_linked_asset_public_contracts_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
```

Documents produit :

```text
MVP Selbrume/narrative_studio.md
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/narrative_studio_readiness_audit.md
```

Fichier produit attendu mais absent :

```text
reports/gameplay/narrative_studio_canonical_product_model_v1.md
```

Fichiers core :

```text
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/map_core.dart
```

Fichiers editor :

```text
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_flow.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_flow_codec.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_flow_mutations.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_parser.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_runtime_advisories.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_templates.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
```

Fichiers runtime :

```text
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/scenario_runtime_completion_gate.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

## 6. Audit produit Cinematic cible

Le document `MVP Selbrume/narrative_studio.md` pose la séparation produit :

- Event = quand / pourquoi quelque chose démarre.
- Scene = orchestration logique en graph.
- Cinematic = séquence visuelle linéaire.
- Dialogue Yarn = texte, choix, outcomes.
- Fact = état persistant lisible.
- World Rule = changement visible du monde selon l'état.

Point canonique : une Scene peut brancher ; une Cinematic ne branche pas.

Une Cinematic cible contient caméra, mouvements PNJ, emotes, sons, musique, FX, dialogue simple si besoin, fondu, shake caméra, attente, placement d'acteurs et timeline. Elle n'est pas le moteur de progression.

## 7. Audit technique Cutscene Studio

Cutscene Studio porte un modèle d'authoring déjà riche :

- `kCutsceneStudioSchemaVersion = cutscene_studio_v2`.
- Metadata `authoring.cutsceneSchema`.
- Metadata `authoring.cutsceneFlow`.
- Blocs dialogue, narration, mouvement, follow, face, transition map, starter choice, wait, scene result, script, flags, outcome, player question, camera placeholders.
- Compilation vers `ScenarioAsset`.
- Branches Oui/Non dans le flow et nodes `choice` / merge.

Conclusion : Cutscene Studio est utile, mais trop large pour définir Cinematic V1. Il contient déjà de la logique de branchement et des effets de progression/flags/outcomes. Le garder comme bridge est sain ; le promouvoir comme modèle canonique serait incohérent avec la vision produit.

## 8. Audit technique ScenarioAsset

`ScenarioAsset` expose :

- `scope` (`globalStory`, `localEventFlow`) ;
- `entryNodeId` ;
- `declaredOutcomes` ;
- `activationCondition` ;
- `nodes` / `edges` ;
- `metadata`.

`ScenarioNode` expose des types `start`, `dialogue`, `action`, `condition`, `choice`, `reference`, `end`.

`ScenarioNodeBinding` porte map/event/entity/warp/trigger/trainer/dialogue/script/outcome/flag/variable.

Conclusion : `ScenarioAsset` est un graphe généraliste legacy/bridge. Il sait représenter beaucoup plus qu'une Cinematic linéaire. Il reste une source de compatibilité, pas le produit final Cinematic.

## 9. Audit technique ScenarioRuntimeExecutor

`ScenarioRuntimeExecutor` supporte :

- sources `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived` ;
- effets `dialogue`, `script`, `message`, `battle`, `none` ;
- actions runtime `runScript`, `openDialogue`, `showMessage`, `moveCharacter`, `followCharacter`, `faceCharacter`, `transitionMap`, `setFlag`, `clearFlag`, `emitOutcome`, `startTrainerBattle`, `givePokemon`, `giveItem`, `completeStep`, `flowMerge`, `authoringPlaceholder`.

Conclusion : ce runtime bridge est trop gameplay/progression pour devenir runtime Cinematic V1. Une Cinematic canonique ne doit pas directement donner un item, compléter une étape ou écrire un Fact.

## 10. Audit technique SceneRuntimePlan / playCinematic

`SceneRuntimePlanIntentKind` contient `playCinematic`.

`SceneRuntimePlanIntent.playCinematic` porte seulement :

```text
cinematicId
```

`buildSceneRuntimePlan` transforme un `SceneNodeKind.cinematic` en intent `playCinematic`, mais ajoute un warning `cinematicBridgeOnly`.

Dans `PlayableMapGame`, le callback `playCinematic` actuel vérifie l'id et retourne `completed` après log :

```text
[scene_runtime] cinematic bridge acknowledged id=<id>
```

Conclusion : le seam Scene existe, mais il n'y a pas encore de vrai runtime Cinematic V1. Le contrat actuel confirme le besoin d'un asset canonique avant d'aller plus loin.

## 11. Audit CinematicPublicContract / scenarioBridge

`CinematicPublicContract` existe déjà dans `linked_asset_public_contracts.dart`.

Caractéristiques :

- `sourceKind = scenarioBridge` ;
- `status = bridgeOnly` ;
- `linear = null` ;
- `requiredActors = []` ;
- `mapId = null` ;
- `declaredOutputs = completed` ;
- diagnostic `legacyBridge`.

Le builder ne lit que les `ScenarioAsset` marqués par metadata `authoring.cutsceneSchema`.

Conclusion : ce contrat est honnête. Il expose un bridge, pas un asset final. La suite doit ajouter une source canonique distincte au lieu de changer silencieusement la signification de `scenarioBridge`.

## 12. Frontières Scene / Cinematic / Event / Yarn / Fact / World Rule

| Élément | Responsabilité | Ne doit pas faire |
|---|---|---|
| Event | Déclenchement local : quand et pourquoi une Scene démarre. | Orchestrer toute la narration ou remplacer Scene. |
| Scene | Graph d'orchestration : dialogues, battles, cinematics, conditions, actions et outcomes. | Devenir un outil de montage visuel frame/timeline. |
| Cinematic | Séquence visuelle linéaire jouée à l'écran. | Brancher, écrire Facts, lancer battle, gérer progression globale. |
| Dialogue Yarn | Texte, choix et outcomes de dialogue. | Piloter seul le monde persistant. |
| Fact | État persistant lisible. | Contenir une chorégraphie ou un script. |
| World Rule | Projection visible/active du monde depuis Facts/conditions. | Être exécutée directement par une Cinematic. |

## 13. Options comparées

### Option A — Promouvoir ScenarioAsset comme Cinematic V1

Avantage : réutilise l'existant.

Rejet : `ScenarioAsset` est trop large, branchable, source-driven et progression-capable.

### Option B — Faire de Cutscene Studio le Cinematic Builder final

Avantage : UI déjà présente.

Rejet : Cutscene Studio compile vers `ScenarioAsset` et contient des branches/flags/outcomes. Il peut inspirer, pas définir.

### Option C — Créer CinematicAsset sans bridge legacy

Avantage : modèle propre immédiatement.

Rejet partiel : supprimer le bridge maintenant casserait la continuité et ignorerait le travail existant.

### Option D — Rester bridgeOnly durablement

Avantage : pas de modèle nouveau.

Rejet : Cinematic resterait ambigu et la Cinematics Library ne pourrait pas devenir no-code propre.

### Option E — Hybride progressif

Décision retenue.

Principe : créer un `CinematicAsset` canonique dédié, tout en gardant Cutscene Studio / `ScenarioAsset` comme bridge legacy explicite jusqu'à migration volontaire.

## 14. Matrice de décision

| Critère | A Scenario final | B Cutscene final | C Pur sans bridge | D Bridge durable | E Hybride |
|---|---:|---:|---:|---:|---:|
| Respect Scene vs Cinematic | Faible | Moyen | Fort | Moyen | Fort |
| Compatibilité existante | Fort | Fort | Faible | Fort | Fort |
| No-code clair | Faible | Moyen | Fort | Faible | Fort |
| Risque de fake model | Fort | Fort | Faible | Moyen | Faible |
| Migration contrôlable | Faible | Moyen | Moyen | Faible | Fort |
| Prépare Cinematics Library | Faible | Moyen | Fort | Faible | Fort |

Verdict : Option E.

## 15. Décision canonique Cinematic V1

Cinematic V1 = future entité produit `CinematicAsset`.

Elle est :

- linéaire ;
- visuelle ;
- localisable dans un contexte de map/actors ;
- référençable par `cinematicId` ;
- diagnostiquable ;
- organisable en library ;
- jouable par un runtime Cinematic dédié plus tard.

Elle n'est pas :

- `ScenarioAsset` ;
- SceneGraph bis ;
- StorylineStep ;
- Event ;
- Script libre ;
- moteur de Facts ou World Rules ;
- moteur de battle.

## 16. Contrat conceptuel Cinematic V1

Champs conceptuels recommandés pour V1-37 :

```text
id
title
description
storylineId?
chapterId?
mapId?
tags
requiredActors
timeline
tracks?
durationEstimate?
notes
metadata
legacyBridge?
```

Timeline V0 recommandée :

```text
orderedSteps
step.kind
step.label
step.actorRef?
step.target?
step.durationMs?
step.dialogueLine?
step.soundRef?
step.cameraInstruction?
```

Sorties V1 :

```text
completed
```

Les états techniques `failed`, `cancelled`, `skipped` peuvent exister côté runtime plus tard, mais ne sont pas des branches narratives en V1.

## 17. Place du bridge legacy Cutscene/Scenario

Le bridge reste :

- lisible ;
- diagnostiquable ;
- visible comme legacy/bridge ;
- utilisable pour transition contrôlée.

Le bridge ne devient pas :

- stockage final ;
- picker canonique par défaut ;
- modèle cible Cinematics Library ;
- runtime Cinematic V1.

La règle produit est stricte : `scenarioBridge` doit garder son nom et son statut tant qu'une vraie migration n'existe pas.

## 18. Conséquences pour Scene Builder

Le `CinematicNode` doit continuer à référencer un `cinematicId` réel. En l'absence de `CinematicAsset`, il ne doit pas faire croire que le bridge est final.

Après V1-37, le Scene Builder pourra afficher deux familles de contrats :

- Cinematic canonique disponible ;
- Bridge legacy disponible mais warning.

La Scene reste le lieu de branchement : elle choisit quelle Cinematic lancer, puis reprend sur `completed`.

## 19. Conséquences pour Cinematics Library

La Library doit être dédiée aux cinématiques, pas fusionnée avec Scenes.

Elle doit afficher :

- titre ;
- contexte narratif ;
- map/lieu ;
- acteurs requis ;
- durée/estimation ;
- diagnostics ;
- scènes qui la référencent ;
- statut canonique ou bridge legacy.

Elle ne doit pas exposer `ScenarioAsset` comme type utilisateur principal.

## 20. Conséquences pour Cinematic Builder V2

Builder V2 doit être un outil de montage/chorégraphie :

- storyboard ;
- preview viewport ;
- timeline ;
- tracks ;
- actors ;
- camera ;
- mouvements ;
- dialogue simple ;
- FX/son/musique ;
- diagnostics locaux.

Il ne doit pas devenir un autre Scene Builder.

## 21. Conséquences pour runtime

Le runtime doit conserver la séparation :

- Scene runtime orchestre ;
- Cinematic runtime joue une séquence ;
- Facts/World Rules sont écrits/projetés par les mécanismes dédiés ;
- battle/dialogue restent des adapters séparés.

Le callback `playCinematic` actuel est un ack bridge. Il doit évoluer plus tard vers un adapter qui charge un `CinematicAsset` canonique et retourne `completed` quand la séquence finit réellement.

## 22. Conséquences pour Selbrume / golden slice

Selbrume a besoin de cinématiques comme :

- cinematic_rival_smiles ;
- cinematic_rival_teases ;
- panic_port ;
- reassure_port.

Ces éléments doivent devenir des Cinematic assets réels, pas des `ScenarioAsset` camouflés. Le bridge peut aider à tester une transition, mais le golden slice produit doit viser la Cinematic Library et le contrat canonique.

## 23. Risques et garde-fous

Risques :

- promouvoir `ScenarioAsset` par fatigue ;
- créer une timeline trop ambitieuse en V1-37 ;
- confondre dialogue simple dans une Cinematic et Dialogue Yarn ;
- laisser une Cinematic écrire un Fact ;
- faire de Cutscene Studio un deuxième Scene Builder.

Garde-fous :

- `CinematicAsset` dédié ;
- output narratif unique `completed` ;
- aucun branch dans Cinematic V1 ;
- aucun write Fact/World Rule depuis Cinematic ;
- bridge toujours nommé `scenarioBridge` ;
- diagnostic `legacyBridge` conservé ;
- migration future volontaire, jamais implicite.

## 24. Prochain lot recommandé

```text
NS-SCENES-V1-37 — CinematicAsset Core Model V0
```

Scope recommandé :

- ajouter le modèle core `CinematicAsset` ;
- ajouter `ProjectManifest.cinematics` ou stockage canonique équivalent ;
- ajouter JSON/serialization ;
- ajouter read model public canonique ;
- préserver `CinematicPublicContract.scenarioBridge` ;
- ajouter diagnostics refs Cinematic canonique vs bridge ;
- tests core uniquement.

Non-objectifs V1-37 :

- pas de Cinematic Builder V2 ;
- pas de runtime cinematic avancé ;
- pas de migration `ScenarioAsset` ;
- pas de refonte Cutscene Studio ;
- pas de SceneGraph bis.

Fichiers créés/modifiés par V1-36 :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 25. Commandes exécutées avec sorties exactes

Gate 0 : voir section 4.

Recherche obligatoire principale :

```bash
rg -n "CinematicPublicContract|scenarioBridge|legacyBridge|playCinematic|SceneCinematicPayload|ScenarioAsset|ScenarioRuntimeExecutor|Cutscene|cutscene|cinematic" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib
```

Résultat : 2185 lignes de hits. Les fichiers principaux trouvés sont :

```text
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Tests/analyze :

```text
Non requis et non exécutés : lot documentation-only.
```

## 26. Recherches effectuées

Recherches ciblées :

```bash
rg -n "V1-35|V1-36|V1-37|Cinematic|Cutscene|Scenario|DONE|NEXT|prochain|roadmap" reports/narrativeStudio/scenes/road_map_scenes.md
rg -n "V1-35|V1-36|V1-37|Cinematic|Cutscene|Scenario|DONE|NEXT|prochain|roadmap" reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
rg -n "class|enum|ScenarioAsset|SceneCinematicPayload|SceneNodeKind|SceneEdgeKind|SceneRuntimePlan|playCinematic|CinematicPublicContract|scenarioBridge|legacyBridge|ProjectManifest|scenarios|cinematics|cinematic|cutscene" packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/scene_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/runtime/scene_runtime_plan.dart packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart packages/map_core/lib/src/diagnostics/scene_diagnostics.dart packages/map_core/lib/map_core.dart
rg -n "class|enum|ScenarioRuntimeExecutor|ScenarioRuntime|ScenarioAsset|Cutscene|cutscene|playCinematic|playScenario|battle|dialogue|choice|flag|outcome|completed|failed|script|branch" packages/map_runtime/lib/src/application/cutscene_runtime_models.dart packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart packages/map_runtime/lib/src/application/scenario_runtime_completion_gate.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
rg -n "ScenarioAsset|ScenarioNode|ScenarioEdge|authoring.cutsceneSchema|cutsceneSchema|compile|metadata|choice|branch|goto|outcome|flag|dialogue|battle|script|motion|camera|timeline" packages/map_editor/lib/src/features/narrative/application/cutscene_studio packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart packages/map_editor/lib/src/ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart
rg -n "Cinematic|cinematic|Cutscene|cutscene|Scenario|scenario|Scene|Event|Fact|World Rule|Dialogue|Battle" "MVP Selbrume/narrative_studio.md" reports/gameplay/audit/narrative_studio_product_model_v0.md reports/gameplay/audit/narrative_studio_readiness_audit.md reports/narrativeStudio/scenes/ns_scenes_v1_20_checkpoint_narrative_studio_direction.md reports/narrativeStudio/scenes/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
```

## 27. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 28. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie globale :

```text
 .../application/runtime_battle_move_bridge.dart    |   7 ++
 .../test/runtime_battle_move_bridge_test.dart      | 136 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  20 ++-
 4 files changed, 175 insertions(+), 5 deletions(-)
```

Note : les deux fichiers `packages/map_runtime/...` sont des changements hors lot déjà présents au status final/concurrents et non modifiés par V1-36. Le diff scoped V1-36 est :

```text
 .../scenes/road_map_scene_builder_authoring.md       | 17 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md    | 20 +++++++++++++++++---
 2 files changed, 32 insertions(+), 5 deletions(-)
```

Le rapport créé est non suivi, donc absent de `git diff --stat` tant qu'il n'est pas ajouté à l'index.

## 29. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie globale :

```text
packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Diff scoped V1-36 :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Fichier créé non suivi :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
```

## 30. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
```

## 31. Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
```

### Contenu complet du rapport créé

Le présent fichier est le contenu complet du rapport créé :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
```

### git status final exact

```text
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
```

### git diff --stat final

```text
 .../application/runtime_battle_move_bridge.dart    |   7 ++
 .../test/runtime_battle_move_bridge_test.dart      | 136 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  20 ++-
 4 files changed, 175 insertions(+), 5 deletions(-)
```

### git diff --name-only final

```text
packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

### Diff complet de road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 4e1c4b0e..17efe709 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -90,14 +90,16 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-33 — Runtime State Persistence Gate V0 | DONE | Gate persistence runtime : les consequences Scene V1 `setFact` et `markEventConsumed` ecrites par `SceneEventRuntimeHook` survivent au save/reload et restent lisibles par Conditions Scene et World Rules en projection pure. |
 | NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0 | DONE | Hook runtime borne : World Rules projetees depuis `GameState` pilotent presence PNJ, dialogue override et disponibilite d'events sans muter `GameState`, `ProjectManifest` ou `MapData`. |
 | NS-SCENES-V1-35 — Facts & World Rules Manager UI V0 | DONE | Manager no-code centralise : Facts et Regles du monde actifs depuis Narrative Studio, creation/edition/suppression bornee, pickers reels, usages/diagnostics visibles, overview aligne. |
+| NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision | DONE | Decision canonique : Cinematic V1 devient un futur `CinematicAsset` lineaire dedie ; `ScenarioAsset`/Cutscene Studio restent bridge legacy explicite, jamais modele final implicite. |
+| NS-SCENES-V1-37 — CinematicAsset Core Model V0 | TODO | Ajouter le modele core/storage/read contract minimal `CinematicAsset` avant Cinematics Library et Builder V2, sans runtime cinematic avance ni migration legacy. |

 ## Prochain lot recommande

-`NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision`
+`NS-SCENES-V1-37 — CinematicAsset Core Model V0`

-Raison : V1-35 ferme le trou UX central Facts / World Rules. Le prochain blocage produit majeur est Cinematic : l'ancien Cutscene Studio existe encore comme bridge scenario, mais Cinematic V1 canonique doit etre decide avant Cinematics Library et Cinematic Builder V2.
+Raison : V1-36 a tranche le contrat produit. Le prochain verrou est maintenant de donner a Cinematic V1 un modele core dedie, lineaire et diagnostiquable, avant de construire une Cinematics Library ou un Cinematic Builder V2.

-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0.

 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

@@ -173,6 +175,18 @@ Limites : pas de runtime modifie, pas de nouveau type de Fact ou World Rule, pas

 Prochain lot exact : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision`.

+## Mise a jour V1-36
+
+Statut : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision` est DONE.
+
+Decision : Cinematic V1 est un futur asset canonique dedie, lineaire, visuel, referencable par Scene et diagnostiquable. Il ne branche pas, ne produit pas directement des Facts ou World Rules, ne lance pas de combat et ne remplace pas Dialogue Yarn. `ScenarioAsset` reste un bridge legacy explicite ; Cutscene Studio reste utilisable comme source/bridge transitoire, mais son schema plus large ne dicte pas Cinematic V1.
+
+Scope realise : audit documentaire du modele cible, de Cutscene Studio, `ScenarioAsset`, `ScenarioRuntimeExecutor`, `SceneRuntimePlan.playCinematic`, `CinematicPublicContract.scenarioBridge`, et decision de roadmap avant Cinematics Library / Cinematic Builder V2.
+
+Limites : aucun code, aucun widget, aucun modele Dart, aucune migration, aucun runtime cinematic nouveau, aucun seed Selbrume et aucune promotion implicite de `ScenarioAsset`.
+
+Prochain lot exact : `NS-SCENES-V1-37 — CinematicAsset Core Model V0`.
+
 ## Mise a jour V1-30-bis

 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

### Diff complet de road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index c19a4a0b..f0c68191 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision
+NS-SCENES-V1-37 — CinematicAsset Core Model V0
 ```

 ## Principes
@@ -69,7 +69,8 @@ NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision
 | NS-SCENES-V1-33 | Runtime State Persistence Gate V0 | runtime / integration | Prouver que les writes Scene V1 (`setFact`, `markEventConsumed`) survivent a save/reload et restent lisibles par Conditions/World Rules. | Pas de nouveau node, pas de payload picker, pas de projection World Rules runtime, pas de golden slice jouable complet. | `scene_runtime_state_persistence_gate_test.dart`, rapport, roadmaps. | DONE : Scene -> consequence write -> save -> reload -> condition/world rule source readable, regressions runtime ciblees. | Construire la projection monde avant d'avoir verrouille l'etat persistant ; confondre save generale et preuve Scene-specific. | DONE : gate save/reload Scene-specific vert, aucune production modifiee. | V1-32. |
 | NS-SCENES-V1-34 | World Rules Runtime Projection Hook V0 | runtime / integration | Appliquer prudemment au runtime jouable les effets World Rules projetes depuis le `GameState` recharge, apres le verrou persistence V1-33. | Pas de nouvelle consequence, pas de Scene payload, pas de World Rule editor avance, pas de StorylineStep runtime trigger. | runtime world rule projection hook, map runtime tests, rapport. | DONE : projection fact/event consomme lue depuis GameState, application runtime bornee aux entites/events/dialogue override, non-mutation du manifest/map/state et regressions save/load. | Appliquer les World Rules trop largement ; confondre projection pure et mutation definitive du monde. | DONE : hook runtime pur + branchement presence/dialogue/event, sans mutation durable ni nouvelle consequence. | V1-33. |
 | NS-SCENES-V1-35 | Facts & World Rules Manager UI V0 | editor / product | Donner un espace no-code dedie pour gerer Facts et World Rules au-dela des apercus contextuels, avec labels lisibles, diagnostics et navigation vers cibles. | Pas de runtime nouveau, pas de nouveaux effets, pas de Scene consequence supplementaire, pas de seed Selbrume. | manager Facts/World Rules, read models editor, tests widget, rapport. | DONE : read model pur, creation/edition/suppression Facts, creation/edition/toggle/suppression World Rules, diagnostics/usages, overview/sidebar, visual gate et analyzes. | Refaire un editeur de flags techniques ; dupliquer les panneaux contextuels map sans coherence. | DONE : Facts et Regles du monde actifs, aucun ID libre comme workflow principal, aucun runtime modifie. | V1-34. |
-| NS-SCENES-V1-36 | Cinematic V1 Contract / Bridge Decision | doc / architecture-review | Decider le contrat Cinematic V1 canonique et la place du bridge Cutscene/Scenario avant Cinematics Library et Builder V2. | Pas de runtime cinematic nouveau, pas de refonte Cutscene Studio, pas de Scene payload supplementaire. | rapport V1-36, roadmaps, audit Cutscene/Scenario/Cinematic. | Attendus : contrat tranche, frontieres legacy, prochain lot exact. | Promouvoir ScenarioAsset comme modele final ; coder une cinematic avant contrat. | TODO : ne pas demarrer avant V1-35 valide. | V1-35. |
+| NS-SCENES-V1-36 | Cinematic V1 Contract / Bridge Decision | doc / architecture-review | Decider le contrat Cinematic V1 canonique et la place du bridge Cutscene/Scenario avant Cinematics Library et Builder V2. | Pas de runtime cinematic nouveau, pas de refonte Cutscene Studio, pas de Scene payload supplementaire. | rapport V1-36, roadmaps, audit Cutscene/Scenario/Cinematic. | DONE : `git diff --check`, contrat tranche, frontieres legacy, prochain lot exact. | Promouvoir ScenarioAsset comme modele final ; coder une cinematic avant contrat. | DONE : CinematicAsset futur retenu, ScenarioAsset/Cutscene restent bridge legacy explicite. | V1-35. |
+| NS-SCENES-V1-37 | CinematicAsset Core Model V0 | core / contract | Ajouter le modele core/storage/read contract minimal de Cinematic V1 lineaire et diagnostiquable. | Pas de Cinematic Builder V2, pas de runtime cinematic avance, pas de migration Cutscene/Scenario automatique, pas de SceneGraph bis. | `scene/cinematic` core model selon convention, `ProjectManifest.cinematics`, public contract, diagnostics/tests core. | Tests JSON/manifest/read model/diagnostics + analyze core. | Sur-modeliser la timeline ; convertir le legacy trop tot ; laisser des actions qui ecrivent le monde. | TODO : modele dedie stable, bridge legacy conserve, Scene peut viser un contrat canonique futur. | V1-36. |

 ## Options comparees

@@ -594,6 +595,18 @@ Limites : pas de runtime nouveau, pas de nouvel effet World Rule, pas de nouvell

 Prochain lot exact : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision`.

+## Mise a jour V1-36
+
+Statut : `NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision` est DONE.
+
+Decision : Cinematic V1 ne doit pas heriter du graphe `ScenarioAsset`. Le futur contrat canonique est un `CinematicAsset` dedie, lineaire, visuel, referencable par un `SceneCinematicPayload.cinematicId`, expose par une Cinematics Library, puis editable dans un Cinematic Builder V2. Cutscene Studio et `ScenarioAsset` restent disponibles comme bridge/source transitoire, avec statut legacy explicite.
+
+Scope realise : audit documentaire Cutscene Studio, `ScenarioAsset`, `ScenarioRuntimeExecutor`, `RuntimeCutsceneAsset`, `SceneRuntimePlan.playCinematic`, `CinematicPublicContract.scenarioBridge` et frontieres produit Scene/Cinematic/Event/Yarn/Facts/World Rules.
+
+Limites : aucun code, aucun widget, aucun modele Dart, aucun runtime cinematic, aucune migration, aucune donnee Selbrume.
+
+Prochain lot exact : `NS-SCENES-V1-37 — CinematicAsset Core Model V0`.
+
 ## Selbrume golden slice

 Avant le golden slice, il faut au minimum :
```

## 32. Auto-review critique

Checklist :

- Aucun fichier de code modifié par V1-36 : oui, seulement rapports/roadmaps ont été édités par ce lot.
- Attention status final : deux fichiers `packages/map_runtime` sont modifiés hors lot ; ils ne font pas partie de V1-36 et n'ont pas été touchés dans cette passe documentaire.
- Aucun modèle Dart modifié par V1-36 : oui.
- Aucun runtime modifié par V1-36 : oui.
- Options comparées : oui.
- Décision claire : oui, Option E hybride progressif.
- Prochain lot exact : oui, V1-37.
- Roadmaps mises à jour : oui.
- Point faible : le rapport ne remplace pas une vraie specification JSON de `CinematicAsset`; c'est volontairement le prochain lot.

## 33. Regard critique sur le prompt

Le prompt est utilement strict : il évite de laisser l'ancien Cutscene Studio devenir le modèle final par défaut. La seule difficulté est la taille de l'Evidence Pack pour un lot doc-only, car elle pousse à recopier beaucoup de contexte dans un rapport qui doit surtout trancher une décision produit. Le fond est néanmoins juste : Cinematic est une frontière suffisamment dangereuse pour mériter ce verrou.

## 34. Conclusion

V1-36 ferme l'ambiguïté : Cinematic V1 sera un asset canonique dédié, linéaire et visuel. Le legacy Cutscene/Scenario reste un bridge explicite et diagnostiqué.

La suite ne doit pas construire tout de suite un studio de montage complet. Elle doit d'abord ajouter le noyau : `CinematicAsset Core Model V0`.
