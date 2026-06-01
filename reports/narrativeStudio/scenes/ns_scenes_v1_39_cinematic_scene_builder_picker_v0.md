# NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0

Date : 2026-06-01

## 1. Resume executif

Le lot `NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0` est realise.

Le Scene Builder peut maintenant creer et editer un `CinematicNode` depuis un vrai `CinematicAsset` canonique :

- aucun `cinematicId` libre dans le workflow normal ;
- aucun bridge `ScenarioAsset` promu silencieusement ;
- picker canonical-only ;
- inspector cinematic avec details, diagnostics et statut legacy/unknown ;
- sortie `cinematic.completed` authorable, diagnostiquee et connectable ;
- mise a jour en memoire de `ProjectManifest.scenes` uniquement ;
- aucun runtime cinematic, aucun Builder V2, aucune migration legacy et aucune donnee Selbrume.

## 2. Pourquoi V1-39 existe

V1-38 a rendu les `CinematicAsset` canoniques visibles dans Narrative Studio via une Cinematics Library. V1-39 branche cette source canonique dans le Scene Builder, afin que les scenes puissent orchestrer une cinematic reelle sans revenir a un ID tape a la main ni a un bridge legacy ambigu.

## 3. Scope

Inclus :

- operation pure `addSceneCinematicNodeDraft` ;
- operation pure `updateSceneCinematicPayload` ;
- picker UI `SceneCinematicPickerDialog` ;
- palette Scene Builder active seulement si `ProjectManifest.cinematics` contient au moins un asset canonique ;
- details canonical/bridge/unknown dans l'inspecteur ;
- port `completed` pour `SceneNodeKind.cinematic` ;
- tests core/editor et visual gate.

Exclus :

- runtime cinematic ;
- Cinematic Builder V2 ;
- timeline editor ;
- migration `ScenarioAsset`/Cutscene Studio ;
- promotion des bridges legacy ;
- donnees Selbrume.

## 4. Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
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
```

`git status --short --untracked-files=all` initial : sortie vide.

`git diff --stat` initial : sortie vide.

## 5. Changements preexistants vs V1-39

Changements preexistants detectes au debut : aucun.

Changements introduits par V1-39 : tous les fichiers listes dans ce rapport.

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- prompt V1-39 attache
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- rapports V1-21, V1-22, V1-24, V1-25-bis, V1-30, V1-35, V1-36, V1-37, V1-38
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 7. Fichiers crees

- `packages/map_core/test/scene_cinematic_authoring_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_cinematic_picker.dart`
- `packages/map_editor/test/scene_cinematic_picker_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.md`

## 8. Fichiers modifies

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_project_diagnostics_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- screenshots historiques Scene Builder rafraichis par `--update-goldens` pour conserver `scenes_workspace_shell_test.dart` vert apres l'ajout du port/input Cinematic.

## 9. Audit CinematicNode actuel

Avant V1-39 :

- `SceneCinematicPayload` existait deja ;
- `SceneRuntimePlan` savait produire `playCinematic(cinematicId)` ;
- `CinematicPublicContract` distinguait deja canonical et scenarioBridge ;
- la palette Scene Builder ne permettait pas encore une creation canonical-only ;
- `cinematic.completed` n'etait pas authorable cote canvas.

## 10. Design retenu

Le Scene Builder consomme `buildCinematicsLibraryReadModel(project)`.

Creation normale :

1. la palette verifie `library.canonicalEntries` ;
2. si aucune entree canonique n'existe, le bouton est disabled ;
3. si seuls des bridges existent, le message indique explicitement que ce sont des bridges legacy ;
4. le picker liste les assets canoniques comme options selectionnables ;
5. les bridges sont affiches en lecture informative, sans option normale de creation.

Edition :

1. l'inspecteur lit l'entree courante dans la library ;
2. canonical affiche les details ;
3. bridge affiche `Bridge legacy` ;
4. unknown affiche `Reference inconnue` ;
5. le bouton de changement ouvre le meme picker canonical-only.

## 11. Core authoring / update payload

`addSceneCinematicNodeDraft` :

- exige un `ProjectManifest` ;
- refuse `cinematicId` vide ;
- refuse tout id absent de `ProjectManifest.cinematics` ;
- refuse donc les bridges `ScenarioAsset` dans le workflow normal ;
- delegue la creation structurelle a l'operation linked asset existante ;
- conserve graph, layout, outcomes, tags, metadata et n'ajoute aucun edge automatique.

`updateSceneCinematicPayload` :

- refuse node inconnu ;
- refuse node non-cinematic ;
- refuse id vide ;
- si un `ProjectManifest` est fourni, refuse tout id non canonique ;
- remplace seulement le payload cinematic.

## 12. Port Cinematic.completed

`authorableSceneOutputPortsForKind(SceneNodeKind.cinematic)` expose :

```text
completed -> SceneEdgeKind.cinematicCompleted
```

`diagnoseScene` connait maintenant ce port :

- edge kind correct accepte ;
- port manquant signale en warning ;
- port inconnu signale en error ;
- duplicate depuis `completed` signale en error.

## 13. Palette Scene Builder

Etat de la palette :

- active si au moins un `CinematicAsset` canonique existe ;
- disabled si aucun canonical n'existe ;
- disabled avec message bridge legacy si seuls des bridges existent.

La palette ne cree jamais un node cinematic a partir d'un bridge legacy.

## 14. Picker Cinematic canonical

Le nouveau `SceneCinematicPickerDialog` :

- liste `library.canonicalEntries` comme cartes selectionnables ;
- affiche les bridges en lecture seule ;
- montre titre, id, map, storyline, chapitre, timeline, acteurs, usages et diagnostics ;
- ne propose pas d'edition timeline ;
- ne lance aucun runtime.

## 15. Gestion bridge legacy

Les refs existantes vers un bridge restent lisibles afin de ne pas mentir sur les scenes historiques. Elles ne deviennent pas des `CinematicAsset` et ne sont pas selectionnables comme workflow normal.

## 16. Inspecteur CinematicNode

L'inspecteur affiche :

- `cinematicId` ;
- statut `CinematicAsset`, `Bridge legacy` ou `Reference inconnue` ;
- details canonical ;
- diagnostics ;
- bouton de changement vers picker canonical-only.

## 17. Diagnostics

`cinematicRefUnknown` est maintenant une erreur : une scene avec un CinematicNode inconnu ne doit pas etre executable.

Les bridges restent avertis explicitement par le diagnostic legacy existant.

## 18. Runtime plan non-regression

`SceneRuntimePlan` n'est pas modifie. Le test existant confirme encore que le payload cinematic devient un intent declaratif `playCinematic`.

## 19. Relation avec Cinematics Library

La Cinematics Library reste la source de visibilite et d'edition metadata-only des assets. Le Scene Builder ne duplique pas cette edition : il ne fait que choisir un asset canonique et stocker sa reference dans `SceneCinematicPayload`.

## 20. Visual Gate

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scene_cinematic_picker_test.dart
```

Resultat :

```text
00:04 +5: All tests passed!
```

## 21. Pourquoi aucun runtime n'a ete modifie

V1-39 est un lot authoring/picker. Il prepare une reference canonique propre. Le branchement runtime est garde pour `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`.

## 22. Pourquoi aucun Builder V2 n'a ete commence

Le lot ne devait pas construire la salle de montage. Aucune timeline, aucun storyboard, aucun step editor cinematic n'a ete ajoute.

## 23. Pourquoi aucune migration legacy n'a ete faite

Les bridges `ScenarioAsset` restent lisibles comme legacy. V1-39 ne convertit pas, ne copie pas et ne promeut pas les scenarios Cutscene Studio.

## 24. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests et screenshots utilisent des ids neutres : `cinematic_intro`, `cinematic_second`, `scene_picker`. Aucun contenu produit Selbrume n'est cree.

## 25. Tests executes

Core :

```text
cd packages/map_core && dart test test/scene_cinematic_authoring_test.dart
Resultat : 00:00 +5: All tests passed!

cd packages/map_core && dart test test/scene_authoring_operations_test.dart
Resultat : 00:00 +40: All tests passed!

cd packages/map_core && dart test test/scene_diagnostics_test.dart
Resultat : 00:00 +26: All tests passed!

cd packages/map_core && dart test test/scene_project_diagnostics_test.dart
Resultat : 00:00 +7: All tests passed!

cd packages/map_core && dart test test/linked_asset_public_contracts_test.dart
Resultat : 00:00 +9: All tests passed!

cd packages/map_core && dart test test/scene_runtime_plan_test.dart
Resultat : 00:00 +15: All tests passed!
```

Editor :

```text
cd packages/map_editor && flutter test --reporter=compact test/scene_cinematic_picker_test.dart
Resultat : 00:03 +5: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
Resultat : 00:07 +69: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
Resultat : 00:02 +5: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
Resultat : 00:01 +3: All tests passed!
```

Note : une premiere tentative de tests Flutter paralleles a produit un lock Flutter/native_assets transitoire. Les tests ont ensuite ete relances sequentiellement et sont verts.

## 26. Analyze

```text
cd packages/map_core && dart analyze
Resultat :
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart lib/src/ui/canvas/scenes/scene_cinematic_picker.dart test/scene_cinematic_picker_test.dart test/scenes_workspace_shell_test.dart
Resultat :
Analyzing 7 items...
No issues found! (ran in 1.3s)
```

## 27. Recherches anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_battle packages/map_gameplay examples selbrume
```

Sortie : `<vide>`

Recherche large sur fichiers touches :

```text
WorldRuleEffect / BranchByOutcome hits detectes uniquement dans du code preexistant des fichiers touches, pas ajoutes par V1-39.
```

## 28. Recherche anti-Selbrume

Commande sur fichiers touches :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" <fichiers touches>
```

Sortie pertinente :

```text
packages/map_editor/test/scenes_workspace_shell_test.dart: lignes de non-regression existantes qui verifient findsNothing sur selbrume_port, trainer_lysa, mael_intro, lysa_rival.
```

Aucune nouvelle donnee Selbrume n'est creee par V1-39.

## 29. Design system check

Commande :

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff|BoxDecoration\\(|TextStyle\\(" packages/map_editor/lib/src/ui/canvas/scenes packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart || true
```

Resultat : des occurrences preexistantes dans `scenes_workspace.dart`, `scene_node_read_only_inspector.dart` et `scene_graph_read_only_view.dart`. Le nouveau fichier `scene_cinematic_picker.dart` n'ajoute pas de `Color(...)`, `Colors.*`, `0xFF`, `BoxDecoration` ou `TextStyle`.

## 30. Evidence Pack

### Nouveaux fichiers

Les nouveaux fichiers source/test sont :

- `packages/map_core/test/scene_cinematic_authoring_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_cinematic_picker.dart`
- `packages/map_editor/test/scene_cinematic_picker_test.dart`

Ils sont ajoutes dans le diff V1-39 et couverts par les tests listes ci-dessus.

### Hunk principaux modifies

- `scene_authoring_operations.dart` : ajoute result/update cinematic, creation canonical-only et port `cinematic.completed`.
- `scene_diagnostics.dart` : rend unknown cinematic error et ajoute spec output `cinematic.completed`.
- `narrative_workspace_canvas.dart` : injecte `CinematicsLibraryReadModel`, creation/update cinematic via operations core.
- `scenes_workspace.dart` : palette cinematic canonical-only et callback update.
- `scene_node_read_only_inspector.dart` : panneau cinematic canonical/bridge/unknown.
- `scene_graph_read_only_view.dart` : input visuel pour cinematic.
- `scenes_workspace_shell_test.dart` : adapte Cinematic completed authorable et bridge-only disabled.

## 31. Auto-review critique

Points positifs :

- le workflow normal ne peut pas selectionner de bridge legacy ;
- les operations core refusent les refs inconnues ;
- le runtime n'est pas touche ;
- le port completed est couvert par authoring, diagnostics et editor.

Risques restants :

- les screenshots historiques Scene Builder ont ete rafraichis pour conserver les goldens exacts ; la difference visuelle etait tres faible mais attendue par les tests.
- le test `scene_cinematic_picker_test.dart` declenche le callback du bouton actif pour ouvrir le picker dans un viewport de test ou la palette complete peut depasser horizontalement.

## 32. Limites restantes

- pas de runtime cinematic canonique ;
- pas d'attente reelle de fin cinematic ;
- pas de Builder V2 ;
- pas de timeline editor ;
- pas de migration Cutscene Studio ;
- pas de skipped/failed/outcomes cinematic.

## 33. Prochain lot recommande

`NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`

Raison : le builder sait maintenant produire une reference canonique. Le prochain verrou est d'executer proprement cette reference au runtime en attendant `completed`, sans retomber sur l'ack bridge historique.

