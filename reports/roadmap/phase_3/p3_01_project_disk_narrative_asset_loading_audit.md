# P3-01 — Project Disk Narrative Asset Loading Audit

## 1. Résumé exécutif

Verdict : le chemin disque `project.json -> ProjectManifest -> RuntimeMapBundle -> PlayableMapGame` existe et expose bien les assets narratifs au runtime, mais la preuve Level 4 reste partielle pour le narratif complet.

Ce qui est prouvé :

- `project.json` est chargé par `loadProjectManifestFromFile`, migré par `migrateProjectManifestJson`, désérialisé en `ProjectManifest`, puis validé par `ProjectValidator`.
- `RuntimeMapBundle` expose `manifest`, `map`, `projectRootDirectory` et les chemins tilesets résolus.
- `PlayableMapGame` reçoit le bundle, lit directement `_bundle.manifest.scenarios`, `_bundle.manifest.dialogues` et `_bundle.manifest.trainers`, et sait résoudre les dialogues Yarn via `ProjectDialogueEntry.relativePath`.
- Le host jouable charge un `runtime_host_launch_save.json` adjacent au `project.json` si présent.
- Le slice disque existant `examples/playable_runtime_host/golden_battle_slice` prouve un vrai projet disque battle-ready avec `project.json`, map externe, trainer, Pokémon config et save de lancement.

Ce qui n'est pas prouvé :

- Aucun projet disque versionné ne prouve aujourd'hui `scenarios + dialogues + trainers` ensemble.
- Aucun fichier `.yarn` versionné n'a été trouvé dans le repo.
- Aucun flux narratif disque complet n'est prouvé de bout en bout depuis le host.
- Les `ScenarioAsset` sont accessibles depuis un `ProjectManifest` disque si le JSON les contient, mais le slice disque existant ne contient pas de scénarios.

Recommandation : garder le prochain lot exact `P3-02 — ScenarioAsset Runtime Execution Golden Path`. P3-02 devra créer ou utiliser une fixture technique minimale non-Selbrume si son prompt l'autorise, car P3-01 montre que le loader sait porter les données mais qu'aucune fixture narrative disque complète n'existe encore.

## 2. Scope du lot

Inclus :

- audit du chemin disque `project.json` ;
- audit de `ProjectManifest`, `ScenarioAsset`, dialogues, trainers et save de lancement ;
- audit de `RuntimeMapBundle` et de l'accès `PlayableMapGame` ;
- inventaire des fixtures/projets disque existants ;
- distinction Level 1 / 2 / 3 / 4 ;
- mise à jour de `MVP Selbrume/road_map_phase_3.md`.

Exclus :

- code de production ;
- runtime harness ;
- smoke test ;
- fixture narrative ;
- projet Selbrume ;
- migration JSON ;
- UI ;
- P3-02.

## 3. Sources lues

Fichiers de gouvernance :

- `AGENTS.md`
- `skills/README.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md`
- `reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md`
- `reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md`

Fichiers modèles / validation :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/operations/project_json_migrations.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/validation/dialogue_validation.dart`

Fichiers runtime / host :

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/resolve_dialogue.dart`
- `packages/map_runtime/lib/src/application/load_dialogue_content.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `examples/playable_runtime_host/lib/main.dart`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`

Fixtures / tests lus :

- `examples/playable_runtime_host/golden_battle_slice/project.json`
- `examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`
- `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json`
- `examples/playable_runtime_host/golden_battle_slice/README.md`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- extraits ciblés de `packages/map_runtime/test/playable_map_game_input_test.dart`
- extraits ciblés de `packages/map_runtime/test/script_system_integration_test.dart`
- extraits ciblés de `packages/map_runtime/test/npc_interaction_scene_readiness_test.dart`

## 4. Chemin de chargement projet disque

Chemin observé :

```text
project.json
-> loadProjectManifestFromFile(projectFilePath)
-> jsonDecode(File(projectFilePath).readAsString())
-> migrateProjectManifestJson(raw)
-> ProjectManifest.fromJson(migrated)
-> _normalizeProjectElementCollisionProfiles(manifest)
-> ProjectValidator.validate(manifest)
-> loadRuntimeMapBundle(projectFilePath, mapId)
-> projectMapEntryForId(manifest, mapId)
-> loadMapDataFromFile(projectRoot + ProjectMapEntry.relativePath)
-> migrateMapDataJson(rawMap)
-> MapData.fromJson(migratedMap)
-> MapValidator.validate(map, projectDialogueContext: manifest)
-> collectAllRuntimeTilesetIds(map, manifest)
-> resolveTilesetAbsolutePaths(...)
-> RuntimeMapBundle(...)
-> PlayableMapGame(bundle: bundle, projectFilePath: projectFilePath, saveData: ...)
```

Réponses factuelles :

1. `project.json` est chargé par `loadProjectManifestFromFile` dans `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`.
2. Le JSON disque devient `ProjectManifest` via `migrateProjectManifestJson(raw)` puis `ProjectManifest.fromJson(migrated)`.
3. Les migrations existent mais sont actuellement des no-op : `migrateProjectManifestJson` et `migrateMapDataJson` retournent `raw`.
4. `ProjectValidator.validate(manifest)` est appelé immédiatement après désérialisation et normalisation collision.
5. La map active est chargée depuis un fichier externe référencé par `ProjectMapEntry.relativePath`.
6. Le loader ne charge pas tous les assets externes en avance : dialogues Yarn et assets Pokémon/battle restent résolus plus tard par leurs chemins relatifs.

## 5. Inventaire des assets narratifs disque

### ProjectManifest

`ProjectManifest` est embedded dans `project.json`. Il contient directement :

- `maps` sous forme de `ProjectMapEntry`, avec `relativePath` vers les fichiers map ;
- `dialogues` sous forme de `ProjectDialogueEntry`, avec `relativePath` vers `dialogues/*.yarn` ;
- `scripts` sous forme de `ProjectScriptEntry` ;
- `scenarios` sous forme de `ScenarioAsset` ;
- `trainers` sous forme de `ProjectTrainerEntry` ;
- `encounterTables`, `characters`, `settings`, `pokemon` et autres catalogues projet.

### Maps

Les maps ne sont pas embedded dans `project.json`. Elles sont chargées depuis `ProjectMapEntry.relativePath`, par exemple `maps/golden_field.json`.

### ScenarioAsset

Les `ScenarioAsset` sont embedded dans `ProjectManifest.scenarios`. Aucun loader séparé de `*scenario*.json` n'a été observé pour le runtime courant.

Preuve actuelle :

- Level 1 : champ `ProjectManifest.scenarios`.
- Level 2 : tests runtime/application in-memory et quelques tests écrivent des `project.json` temporaires avec manifest.
- Level 3 : `PlayableMapGame` dispatch sur `_bundle.manifest.scenarios`.
- Level 4 : non prouvé pour une fixture disque versionnée contenant des scénarios narratifs.

### Dialogues / Yarn refs

Le manifest contient des entrées `ProjectDialogueEntry`, pas le contenu Yarn. Chaque entrée porte un `relativePath`, validé comme chemin relatif sous `dialogues/`.

Le contenu est chargé à l'ouverture :

```text
DialogueRef / dialogueId
-> resolveDialogue(projectRootDirectory, manifest.dialogues)
-> ResolvedDialogue.absoluteFilePath
-> loadDialogueContent(...)
-> File(...).readAsString()
-> parseYarnFile(...)
-> DialogueSession.start(...)
```

Aucun fichier `.yarn` versionné n'a été trouvé pendant l'audit. Donc la capacité de chargement existe, mais la preuve disque versionnée d'un dialogue réel manque.

### Trainers

Les trainers PokeMap sont embedded dans `ProjectManifest.trainers`. Les fichiers `pokémon_sdk_test_project/Data/Studio/trainers/*.json` existent, mais ils appartiennent à un projet SDK de test séparé et ne prouvent pas le loader PokeMap `ProjectManifest.trainers`.

Le slice `golden_battle_slice/project.json` contient un trainer embedded `trainer_rookie` et le smoke test battle le consomme via `RuntimeMapBundle.manifest.trainers`.

### Battle refs

Deux sources de référence battle existent :

- maps : `MapEntity.npc.trainerId`, utilisé par `buildTrainerBattleRequestFromNpc` ;
- scenarios : action `startTrainerBattle` dans `ScenarioAsset`, binding `trainerId`, params `battleId` selon les cas.

La fixture disque actuelle prouve la voie map/NPC/trainer, pas encore la voie `ScenarioAsset.startTrainerBattle` depuis projet disque.

### Save de lancement

Le host cherche `runtime_host_launch_save.json` adjacent au `project.json`. Si présent, il charge `SaveData.fromJson(decoded).normalized()`.

La save de lancement peut contenir :

- `currentMapId`
- `playerPosition`
- `playerFacing`
- `party`
- `trainerProfile`
- `bag`
- `progression.storyFlags`
- `progression.completedStepIds`
- `progression.completedCutsceneIds`
- `properties`

`gameStateFromSaveData` migre `progression.storyFlags` vers `GameState.storyFlags.activeFlags`. En revanche, `SaveData` ne porte pas directement `scriptVariables` ni `consumedEventIds`; ceux-ci existent dans `GameState` mais ne sont pas prouvés par `runtime_host_launch_save.json`.

## 6. ProjectManifest comme source disque

`ProjectManifest` est aujourd'hui la source disque principale pour les références narratives. Il ne délègue pas les scénarios ni les trainers à des fichiers externes.

Réponses aux questions obligatoires :

- `ProjectManifest` contient directement les `ScenarioAsset` : oui, via `scenarios`.
- `ProjectManifest` contient directement les dialogues : oui pour les métadonnées `ProjectDialogueEntry`, non pour le contenu Yarn.
- `ProjectManifest` contient directement les trainers : oui, via `trainers`.
- Les maps sont chargées depuis fichiers externes : oui, via `ProjectMapEntry.relativePath`.
- Les scenarios sont chargés depuis `project.json` : oui.
- Les dialogues sont référencés depuis `project.json`, contenu chargé depuis fichiers externes : oui.
- Les trainers sont chargés depuis `project.json` : oui.
- Migrations : fonctions présentes, actuellement no-op.
- Validation : `ProjectValidator` pour manifest ; `MapValidator` pour map avec contexte dialogues du manifest.

Le point important pour Phase 3 : `ProjectManifest.scenarios` est un canal disque suffisant pour P3-02 si une fixture disque contient effectivement un scénario.

## 7. RuntimeMapBundle et disponibilité runtime

`RuntimeMapBundle` expose :

- `ProjectManifest manifest`
- `MapData map`
- `String projectRootDirectory`
- `Map<String, String> tilesetAbsolutePathsById`

Disponibilité :

- `ScenarioAsset` : disponible via `bundle.manifest.scenarios`.
- Dialogues : métadonnées disponibles via `bundle.manifest.dialogues`; contenu Yarn disponible seulement au moment de `loadDialogueContent`.
- Trainers : disponibles via `bundle.manifest.trainers`.
- Map active : disponible via `bundle.map`.
- Tilesets : chemins absolus collectés et exposés.
- Save de lancement : pas dans le bundle ; passée séparément à `PlayableMapGame`.

Limite : `RuntimeMapBundle` ne vérifie pas l'existence physique des fichiers Yarn référencés dans `ProjectDialogueEntry.relativePath`. Cette preuve reste au moment d'ouverture du dialogue.

## 8. PlayableMapGame et accès aux assets narratifs

`PlayableMapGame` lit bien les assets narratifs depuis le bundle :

- dispatch scénario : `_dispatchScenarioRuntimeSource` récupère `_bundle.manifest.scenarios` et appelle `ScenarioRuntimeExecutor`.
- dialogue scénario : `_openScenarioDialogueById` appelle `_tryOpenDialogue`.
- résolution dialogue : `_tryOpenDialogue` appelle `resolveDialogue(..., projectRootDirectory: _bundle.projectRootDirectory, dialogues: _bundle.manifest.dialogues)`.
- chargement contenu : `loadDialogueContent` lit le fichier Yarn et parse les nodes.
- trainers : les interactions trainer lisent `_bundle.manifest.trainers`.
- world/predicates : plusieurs chemins construisent des indexes depuis `_bundle.manifest.scenarios`.

Niveau de preuve :

- Level 3 code path : oui, `PlayableMapGame` est câblé à `RuntimeMapBundle.manifest`.
- Level 4 flux narratif disque complet : non prouvé, faute de fixture disque contenant scenario + dialogue Yarn réel.

## 9. Host jouable et save de lancement

Le host `examples/playable_runtime_host/lib/main.dart` :

1. sélectionne un `project.json` ;
2. charge les maps disponibles via manifest ;
3. appelle `loadRuntimeMapBundle(projectFilePath, mapId)` ;
4. appelle `loadRuntimeHostLaunchSaveData(projectFilePath)` ;
5. construit `PlayableMapGame(bundle: bundle, projectFilePath: projectFilePath, saveData: ...)`.

`runtime_host_launch_save.json` :

- est optionnel ;
- doit être adjacent à `project.json` ;
- s'il est absent, le host peut utiliser un seed de démo historique ;
- s'il est présent mais invalide, le loader lève une erreur explicite.

Le slice `golden_battle_slice` prouve le chargement d'une save de lancement réelle avec party, map courante et position. Il ne prouve pas encore story flags, completed steps, outcomes ou consumed events depuis un fichier disque versionné.

## 10. Fixtures/projets disque existants

Fixtures/projets trouvés par la recherche obligatoire :

```text
./examples/playable_runtime_host/golden_battle_slice/project.json
./examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_0.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_1.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_10.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_11.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_12.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_13.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_2.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_3.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_4.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_5.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_6.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_7.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_8.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_9.json
```

Contenu du slice PokeMap versionné :

- 1 `project.json`
- 1 map externe `maps/golden_field.json`
- 1 trainer embedded `trainer_rookie`
- 1 zone d'encounter
- Pokémon config et catalogues nécessaires au battle slice
- 1 `runtime_host_launch_save.json`

Manques du slice pour le narratif :

- pas de `dialogues` dans `project.json` ;
- pas de `scenarios` dans `project.json` ;
- pas de fichier `.yarn` ;
- pas de battle reference portée par `ScenarioAsset.startTrainerBattle` ;
- pas de flux Event -> Scenario -> Dialogue/Outcome/Step depuis disque.

Les tests existants prouvent surtout :

- Level 4 battle/map/save : `phase_a_golden_battle_slice_smoke_test.dart` charge le vrai `golden_battle_slice/project.json`.
- Level 4 save de lancement : `phase_a_golden_slice_launch_test.dart` charge la vraie save.
- Level 2/3 narratif in-memory ou temp project : plusieurs tests manipulent `ScenarioAsset`, `ProjectDialogueEntry`, `PlayableMapGame` et `loadRuntimeMapBundle`, mais pas avec une fixture narrative versionnée complète.

## 11. Matrice de preuve Level 1 / 2 / 3 / 4

| Asset / donnée | Source disque | Modèle cible | Loader / chemin de chargement | Validation / migration | Disponible dans RuntimeMapBundle | Disponible dans PlayableMapGame | Preuve actuelle | Niveau prouvé | Gap restant | Lot concerné |
|---|---|---|---|---|---|---|---|---|---|---|
| ProjectManifest | `project.json` | `ProjectManifest` | `loadProjectManifestFromFile` -> `ProjectManifest.fromJson` | `migrateProjectManifestJson` no-op + `ProjectValidator.validate` | Oui, `bundle.manifest` | Oui via `_bundle.manifest` | code loader + tests temp + golden battle slice | Level 4 pour manifest battle slice | fixture narrative complète absente | P3-01 / P3-02 |
| MapData | `maps/*.json` via `ProjectMapEntry.relativePath` | `MapData` | `loadMapDataFromFile` | `migrateMapDataJson` no-op + `MapValidator.validate` | Oui, `bundle.map` | Oui via world/runtime | golden battle slice charge `maps/golden_field.json` | Level 4 | map narrative avec triggers/scenario non prouvée | P3-02 / P3-03 |
| Tilesets | `ProjectManifest.tilesets[].relativePath` | chemins absolus tilesets | `collectAllRuntimeTilesetIds` + `resolveTilesetAbsolutePaths` | validation manifest + asset existence au runtime selon usage | Oui, `tilesetAbsolutePathsById` | Oui pour rendu | code + tests runtime tilesets | Level 2/3, Level 4 selon slices surface/battle hors narratif | pas central P3-01 narratif | P3-05 / P3-07 |
| ScenarioAsset | embedded `project.json` dans `scenarios` | `ScenarioAsset` | inclus dans `ProjectManifest.fromJson` | `ProjectValidator._validateScenarios` | Oui via `bundle.manifest.scenarios` | Oui, dispatch `_bundle.manifest.scenarios` | tests executor/runtime in-memory ; pas de scenario dans golden slice | Level 3 code path, Level 2 tests | Level 4 narratif disque absent | P3-02 |
| Dialogue / Yarn refs | `project.json` pour `ProjectDialogueEntry`, puis `dialogues/*.yarn` | `ProjectDialogueEntry` + `DialogueSession` | `resolveDialogue` -> `loadDialogueContent` -> `parseYarnFile` | `assertValidProjectDialogueRelativePath`; existence lue au runtime | Métadonnées oui ; contenu non | Oui à l'ouverture | tests path resolution ; aucun `.yarn` versionné trouvé | Level 3 code path, Level 2 tests | Level 4 dialogue réel absent | P3-02 / P3-03 |
| Trainer definitions | embedded `project.json` dans `trainers` | `ProjectTrainerEntry` | inclus dans `ProjectManifest.fromJson` | `ProjectValidator._validateTrainers` | Oui via `bundle.manifest.trainers` | Oui pour trainer interactions/battle | golden battle slice contient `trainer_rookie` | Level 4 | voie `ScenarioAsset.startTrainerBattle` disque non prouvée | P3-04 |
| Battle references | map NPC `trainerId`, ou scenario action `startTrainerBattle` | `TrainerBattleRequest` / `ScenarioRuntimeEffect.battle` | map NPC via `buildTrainerBattleRequestFromNpc`; scenario via executor | ProjectValidator vérifie `startTrainerBattle` côté ScenarioAsset | Oui pour trainers ; battle refs scenario si scenario présent | Oui | map/NPC/trainer prouvé dans golden battle slice | Level 4 pour NPC trainer, Level 2/3 pour scenario battle | scenario battle depuis disque non prouvé | P3-04 |
| storyFlags / SaveData launch | `runtime_host_launch_save.json` `progression.storyFlags` si présent | `SaveData` -> `GameState.storyFlags` | `loadRuntimeHostLaunchSaveData` -> `gameStateFromSaveData` | `SaveData.normalized` | Non, hors bundle | Oui via `saveData` initial puis `GameState` | code + tests save launch ; golden save sans storyFlags | Level 3/4 pour save basics | flags narratifs disque non prouvés | P3-06 |
| completedStepIds | `runtime_host_launch_save.json` `progression.completedStepIds` si présent | `SaveData.progression` -> `GameState.progression` | idem save launch | `SaveData.normalized` | Non | Oui via `GameState` | code modèle ; pas dans golden save | Level 1/3 code path | Level 4 completed steps absent | P3-06 |
| consumedEventIds | pas dans `SaveData`; dans `GameState` | `GameState.consumedEventIds` | save/load GameState repository, pas launch save | `normalizeLoadedGameState` | Non | Oui si repository charge GameState | code modèle/use case | Level 1/2 | pas prouvé depuis launch save ou projet disque | P3-06 |
| runtime_host_launch_save.json | fichier adjacent au `project.json` | `SaveData` | `loadRuntimeHostLaunchSaveData` | `SaveData.fromJson(...).normalized()` | Non | Oui, passé au constructeur | golden battle slice + test host launch | Level 4 pour party/map/position | état narratif complet absent | P3-06 |

## 12. Gaps et risques

Gaps principaux :

- Pas de fixture disque narrative complète.
- Pas de `.yarn` versionné trouvé.
- Pas de `ProjectManifest.scenarios` prouvé depuis le slice host réel.
- Pas de preuve disque Event source -> Scenario runtime.
- Pas de preuve disque scenario outcome ou battle outcome.
- Pas de preuve disque story flags / completed steps / consumed events en save de lancement.
- Pas de validation d'existence physique des fichiers Yarn au chargement du bundle.

Risques :

- Confondre `ProjectManifest.scenarios` présent dans le modèle avec une preuve Level 4.
- Confondre tests in-memory `ScenarioRuntimeExecutor` avec runtime Flutter/Flame.
- Croire que le golden battle slice couvre le narratif complet alors qu'il couvre map/trainer/battle/save.
- Introduire trop tôt une fixture Selbrume au lieu d'une fixture technique minimale.
- Démarrer P3-02 sans expliciter le format minimal de fixture narrative.

## 13. Recommandation pour P3-02

P3-02 peut rester :

```text
P3-02 — ScenarioAsset Runtime Execution Golden Path
```

Justification :

- Le chemin de chargement disque est suffisamment clair.
- Les `ScenarioAsset` sont déjà transportables dans `project.json`.
- `RuntimeMapBundle` et `PlayableMapGame` exposent déjà les scénarios.
- Le gap n'est pas un loader absent, mais une preuve golden path narrative absente.

Précondition recommandée pour P3-02 :

- utiliser une fixture technique minimale non-Selbrume contenant :
  - 1 `project.json` ;
  - 1 map externe ;
  - 1 `ProjectDialogueEntry` ;
  - 1 fichier `dialogues/*.yarn` ;
  - 1 `ScenarioAsset` embedded ;
  - optionnellement 1 trainer si le lot veut couvrir `startTrainerBattle`, sinon reporter à P3-04 ;
  - 1 `runtime_host_launch_save.json` seulement si nécessaire.

Si le prompt P3-02 interdit toute création de fixture technique, il faudra alors insérer un micro-lot :

```text
P3-02-prep — Minimal Disk Narrative Fixture Design
```

Mais P3-01 ne recommande pas ce micro-lot par défaut : P3-02 peut intégrer cette préparation si son contrat l'autorise.

## 14. Modifications effectuées

Fichiers créés :

- `reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_3.md`

Code modifié :

- Aucun.

Tests :

- Non exécutés. P3-01 est un audit documentaire et aucune modification de code n'a été effectuée. Les tests existants ont été lus uniquement pour classifier les niveaux de preuve.

## 15. Evidence Pack

### 15.1 git status initial exact

```text

```

### 15.2 Fichiers lus principaux

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/operations/project_json_migrations.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/validation/dialogue_validation.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/application/load_game_use_case.dart
packages/map_runtime/lib/src/application/save_game_use_case.dart
packages/map_runtime/lib/src/application/resolve_dialogue.dart
packages/map_runtime/lib/src/application/load_dialogue_content.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
examples/playable_runtime_host/lib/main.dart
examples/playable_runtime_host/lib/src/runtime_launch_save.dart
examples/playable_runtime_host/golden_battle_slice/project.json
examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json
examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
examples/playable_runtime_host/golden_battle_slice/README.md
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
examples/playable_runtime_host/test/runtime_launch_save_test.dart
packages/map_runtime/test/playable_map_game_input_test.dart
packages/map_runtime/test/script_system_integration_test.dart
packages/map_runtime/test/npc_interaction_scene_readiness_test.dart
```

### 15.3 Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,220p' AGENTS.md
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,320p' "MVP Selbrume/road_map_phase_3.md"
sed -n '1,340p' reports/roadmap/phase_3/p3_00_phase_3_roadmap_bootstrap_runtime_disk_validation_audit.md
sed -n '1,260p' reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md
find . -name project.json -o -name runtime_host_launch_save.json -o -name "*.map.json" -o -name "*scenario*.json" -o -name "*dialogue*.json" -o -name "*trainer*.json" | sort
rg -n "loadProjectManifestFromFile|migrateProjectManifestJson|ProjectManifest.fromJson|project.json|RuntimeMapBundle|loadRuntimeMapBundle|RuntimeMapBundle\(|PlayableMapGame\(|runtime_host_launch_save|loadLaunchSave|SaveData|scenarios|dialogues|trainers|trainerProfiles|ScenarioAsset|Dialogue|Yarn|battleId|startTrainerBattle" packages examples test . --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,320p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/runtime_map_bundle.dart
sed -n '1,260p' examples/playable_runtime_host/lib/main.dart
sed -n '1,180p' examples/playable_runtime_host/lib/src/runtime_launch_save.dart
sed -n '260,560p' examples/playable_runtime_host/lib/main.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,300p' packages/map_core/lib/src/models/scenario_asset.dart
rg --files packages/map_core/lib/src/models | rg "dialogue|trainer|save_data|game_state"
rg -n "ProjectDialogueEntry|ProjectDialogueFolder|ProjectScriptEntry|ProjectMapEntry" packages/map_core/lib/src/models/project_manifest.dart
sed -n '260,470p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,460p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,220p' packages/map_core/lib/src/models/game_state.dart
rg --files packages/map_core/lib/src/operations | rg "project_manifest|migration|migrations|project_json"
rg -n "migrateProjectManifestJson|migrateMapDataJson|ProjectValidator.validate|MapValidator.validate|ProjectDialogueEntry|dialogues|trainers|scenarios|relativePath" packages/map_core/lib/src/operations packages/map_core/lib/src/validation packages/map_runtime/lib/src/application packages/map_editor/lib/src/infrastructure packages/map_editor/lib/src/application
rg -n "dialogueId|ProjectDialogueEntry|load.*Dialogue|Yarn|relativePath|readAsString|DialogueRef|projectDialogue" packages/map_runtime packages/map_editor examples/playable_runtime_host packages/map_core --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,120p' packages/map_core/lib/src/operations/project_json_migrations.dart
sed -n '130,210p' packages/map_core/lib/src/validation/validators.dart && sed -n '740,880p' packages/map_core/lib/src/validation/validators.dart && sed -n '1118,1165p' packages/map_core/lib/src/validation/validators.dart
sed -n '1,90p' packages/map_core/lib/src/validation/dialogue_validation.dart
find examples/playable_runtime_host/golden_battle_slice -maxdepth 4 -type f | sort
rg -n "_openScenarioDialogueById|_openDialogueByRef|ProjectDialogueEntry|relativePath|parseYarn|Yarn|load.*Dialogue|dialogueId|RuntimeMapBundle|manifest" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/src/application packages/map_core/lib/src/operations/game_state_persistence.dart
rg -n "\"(maps|dialogues|scenarios|trainers|scripts|characters|tilesets|encounterTables|pokemon|battleId|startTrainerBattle|runtime_host|scenario|dialogue|trainer|storyFlags|completedStepIds|consumedEventIds)\"" examples/playable_runtime_host/golden_battle_slice/project.json examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
find packages/map_runtime/test examples/playable_runtime_host/test -type f -name '*test.dart' | sort
sed -n '2380,2465p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '4940,5015p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '5280,5325p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,140p' packages/map_runtime/lib/src/application/resolve_dialogue.dart
sed -n '1,120p' packages/map_runtime/lib/src/application/load_dialogue_content.dart
sed -n '1,220p' packages/map_core/lib/src/operations/game_state_persistence.dart
sed -n '1,220p' examples/playable_runtime_host/golden_battle_slice/project.json
sed -n '1,240p' examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json
sed -n '1,220p' examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
sed -n '1,180p' examples/playable_runtime_host/golden_battle_slice/README.md
sed -n '1,240p' packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
sed -n '1,220p' examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
rg -n "loadRuntimeMapBundle|loadProjectManifestFromFile|RuntimeMapBundle|PlayableMapGame\(|loadRuntimeHostLaunchSaveData|runtime_host_launch_save|projectFilePath|selectedProject" examples/playable_runtime_host/lib/main.dart
sed -n '1,220p' examples/playable_runtime_host/lib/src/runtime_launch_save.dart
sed -n '1,180p' packages/map_runtime/lib/src/application/load_game_use_case.dart
sed -n '1,180p' packages/map_runtime/lib/src/application/save_game_use_case.dart
rg -n "loadRuntimeMapBundle|project.json|golden_battle_slice|ProjectManifest.fromJson|RuntimeMapBundle|ScenarioAsset|dialogues|scenarios|trainers|runtime_host_launch_save" packages/map_runtime/test examples/playable_runtime_host/test --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '430,525p' examples/playable_runtime_host/lib/main.dart
sed -n '650,690p' examples/playable_runtime_host/lib/main.dart
sed -n '1,120p' packages/map_runtime/lib/src/application/runtime_map_bundle.dart
sed -n '1,160p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '1,140p' examples/playable_runtime_host/test/runtime_launch_save_test.dart
sed -n '1,260p' "MVP Selbrume/road_map_phase_3.md"
rg -n "class ProjectManifest|List<ScenarioAsset>|ProjectDialogueEntry|ProjectTrainerEntry|ProjectMapEntry|dialogues|scenarios|trainers" packages/map_core/lib/src/models/project_manifest.dart
rg -n "migrateProjectManifestJson|migrateMapDataJson" packages/map_core/lib/src/operations/project_json_migrations.dart packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
rg -n "ProjectValidator.validate|MapValidator.validate|_validateProjectDialogues|_validateScenarios|_validateTrainers|assertValidProjectDialogueRelativePath" packages/map_core/lib/src/validation/validators.dart packages/map_core/lib/src/validation/dialogue_validation.dart packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '260,340p' "MVP Selbrume/road_map_phase_3.md"
sed -n '2090,2185p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '2285,2325p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '5480,5555p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '5680,5725p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '130,180p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '257,310p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '150,190p' packages/map_core/lib/src/validation/validators.dart
sed -n '740,795p' packages/map_core/lib/src/validation/validators.dart
sed -n '1118,1150p' packages/map_core/lib/src/validation/validators.dart
sed -n '20,45p' packages/map_core/lib/src/validation/dialogue_validation.dart
find . -name "*.yarn" -o -name "*.dialogue" -o -name "*.dialogue.json" | sort
find . -path './build' -prune -o -path './.dart_tool' -prune -o -path '*/.dart_tool' -prune -o -path '*/build' -prune -o -type d \( -name dialogues -o -name scenarios -o -name trainers -o -name fixtures -o -name golden \) -print | sort
rg -n "ProjectManifest\(|ProjectManifest\.fromJson|scenarios: \[|dialogues: \[|trainers: \[|loadRuntimeMapBundle\(" packages/map_runtime/test/npc_interaction_scene_readiness_test.dart packages/map_runtime/test/outcome_scene_branch_readiness_test.dart packages/map_runtime/test/scenario_runtime_executor_test.dart packages/map_runtime/test/scenario_battle_from_scene_test.dart packages/map_runtime/test/script_system_integration_test.dart packages/map_runtime/test/playable_map_game_input_test.dart
sed -n '2420,2475p' packages/map_runtime/test/playable_map_game_input_test.dart
sed -n '130,170p' packages/map_runtime/test/playable_map_game_input_test.dart
sed -n '300,390p' packages/map_runtime/test/script_system_integration_test.dart
sed -n '1,100p' packages/map_runtime/test/npc_interaction_scene_readiness_test.dart
rg -n "loadProjectManifestFromFile|migrateProjectManifestJson|ProjectManifest.fromJson|project.json|RuntimeMapBundle|loadRuntimeMapBundle|RuntimeMapBundle\(|PlayableMapGame\(|runtime_host_launch_save|loadLaunchSave|SaveData|scenarios|dialogues|trainers|trainerProfiles|ScenarioAsset|Dialogue|Yarn|battleId|startTrainerBattle" packages examples . --glob '!build/**' --glob '!**/.dart_tool/**' --glob '!pokemon-showdown-client-master/**' --glob '!sprites-master/**'
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md" packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle examples/playable_runtime_host
git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md || true
rg -n "À compléter|P3-01 : 🔜|Prochain lot exact : P3-01|Lot courant : P3-01|P3-02-prep" reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md "MVP Selbrume/road_map_phase_3.md"
sed -n '1,60p' "MVP Selbrume/road_map_phase_3.md"
sed -n '330,470p' reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
```

### 15.4 Sorties utiles des commandes

`find . -name project.json ... | sort` :

```text
./examples/playable_runtime_host/golden_battle_slice/project.json
./examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_0.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_1.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_10.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_11.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_12.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_13.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_2.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_3.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_4.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_5.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_6.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_7.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_8.json
./pokémon_sdk_test_project/Data/Studio/trainers/trainer_9.json
```

`find examples/playable_runtime_host/golden_battle_slice -maxdepth 4 -type f | sort` :

```text
examples/playable_runtime_host/golden_battle_slice/README.md
examples/playable_runtime_host/golden_battle_slice/assets/battle_backgrounds/trainer_rookie.png
examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sparkitten.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/learnsets/sproutle.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/001-sproutle.json
examples/playable_runtime_host/golden_battle_slice/data/pokemon/species/004-sparkitten.json
examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json
examples/playable_runtime_host/golden_battle_slice/project.json
examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json
```

`find . -name "*.yarn" -o -name "*.dialogue" -o -name "*.dialogue.json" | sort` :

```text

```

`find . -path ... -type d \( -name dialogues -o -name scenarios -o -name trainers -o -name fixtures -o -name golden \) -print | sort` :

```text
./packages/map_battle/test/fixtures
./packages/map_core/test/fixtures
./packages/map_editor/test/fixtures
./pokemon-showdown-client-master/play.pokemonshowdown.com/sprites/trainers
./pokémon_sdk_test_project/Data/Studio/trainers
./sprites-master/src/_uncategorized/canonical/trainers
./sprites-master/src/_uncategorized/noncanonical/trainers
```

Commande obligatoire `rg ... packages examples test . ...` :

```text
rg: test: No such file or directory (os error 2)
```

Note : la commande obligatoire contient le chemin racine `test`, qui n'existe pas dans ce repo. Elle a quand même produit des signaux utiles avant l'erreur, puis une recherche corrigée a été exécutée sans ce chemin.

Recherche corrigée `rg ... packages examples . ...` :

```text
Sortie très longue : 9578 lignes.
Signaux utiles retenus :
- packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:31 loadProjectManifestFromFile
- packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart:99 loadRuntimeMapBundle
- packages/map_runtime/lib/src/application/runtime_map_bundle.dart:3 RuntimeMapBundle
- packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart lit _bundle.manifest.scenarios, _bundle.manifest.dialogues, _bundle.manifest.trainers
- examples/playable_runtime_host/lib/main.dart construit PlayableMapGame avec RuntimeMapBundle et save de lancement
- examples/playable_runtime_host/lib/src/runtime_launch_save.dart charge runtime_host_launch_save.json
- packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart charge le vrai golden_battle_slice/project.json
```

### 15.5 Fichiers créés

```text
reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
```

### 15.6 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_3.md
```

### 15.7 Tests

```text
Non exécutés — P3-01 est un audit documentaire, aucun code n'a été modifié.
Les tests existants ont été lus pour classifier les preuves, notamment :
- packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
- examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart
- examples/playable_runtime_host/test/runtime_launch_save_test.dart
```

### 15.8 git diff --check exact

```text

```

### 15.9 git diff --stat exact

```text
 MVP Selbrume/road_map_phase_3.md | 45 +++++++++++++++++++++++++++++++++-------
 1 file changed, 38 insertions(+), 7 deletions(-)
```

### 15.10 git diff --name-only exact

```text
MVP Selbrume/road_map_phase_3.md
```

### 15.11 git status final exact

```text
 M "MVP Selbrume/road_map_phase_3.md"
?? reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md
```

### 15.12 Contrôles explicites

```text
Contrôle hors scope :
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md" packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle examples/playable_runtime_host
Sortie exacte : sortie vide.

git diff --no-index --check /dev/null reports/roadmap/phase_3/p3_01_project_disk_narrative_asset_loading_audit.md || true
Sortie exacte : sortie vide.

Aucun code modifié : confirmé par le contrôle hors scope vide.
road_map_global.md non modifié : confirmé par le contrôle hors scope vide.
P3-02 non exécuté : aucune fixture, aucun test, aucun rapport P3-02 créé.
Selbrume final non créé : aucun fichier de contenu Selbrume ajouté.
```

## 16. Auto-review critique

- Le lot a-t-il modifié uniquement ce qui était autorisé ? Oui : rapport P3-01 + roadmap Phase 3 uniquement.
- Le rapport P3-01 existe-t-il ? Oui.
- `road_map_phase_3.md` est-elle mise à jour ? Oui, prévue dans ce lot.
- `road_map_global.md` est-elle restée intacte ? Oui, contrôle hors scope vide.
- Aucun code n'a-t-il été modifié ? Oui, contrôle hors scope vide.
- Aucun runtime n'a-t-il été implémenté ? Oui.
- Aucun smoke test n'a-t-il été créé ? Oui.
- Aucun projet Selbrume final n'a-t-il été créé ? Oui.
- P3-02 n'a-t-il pas été exécuté ? Oui.
- Le chemin `project.json -> ProjectManifest -> RuntimeMapBundle -> PlayableMapGame` est-il clair ? Oui.
- La disponibilité disque des `ScenarioAsset` / dialogues / trainers est-elle claire ? Oui : scénarios et trainers embedded, dialogues métadonnées embedded + contenu Yarn externe.
- Les fixtures existantes sont-elles listées ? Oui.
- Les niveaux Level 1 / 2 / 3 / 4 sont-ils distingués ? Oui.
- Les gaps sont-ils explicites ? Oui.
- Le prochain lot exact est-il fixé ? Oui : P3-02, sauf si le prochain prompt interdit la fixture technique minimale.

## 17. Regard critique sur le prompt

Le prompt est bien cadré : il force à distinguer disponibilité du modèle, preuve application, preuve runtime et preuve disque réelle. Le point le plus délicat est la commande `rg` obligatoire qui inclut le chemin `test`, absent à la racine du repo ; cela produit une erreur de chemin malgré des résultats utiles. Pour les prochains lots, remplacer ce chemin par les dossiers de test package-scoped éviterait une ambiguïté inutile.
