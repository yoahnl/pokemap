# NS-SCENES-V1-30-bis — Scene Node Deletion UX V0

## 1. Résumé du lot

V1-30-bis rend les nodes Scene corrigibles depuis le Scene Builder : un node non-start peut être supprimé depuis l’inspecteur, avec suppression de ses edges entrants/sortants et nettoyage des layouts associés.

Le lot ne touche pas au runtime, ne reconnecte pas le graph automatiquement, ne modifie pas les payloads, ne supprime aucune SceneAsset entière, et ne crée aucune donnée produit Selbrume.

## 2. Pourquoi V1-30-bis existe

V1-30 a rendu les payloads Dialogue Yarn et Battle trainer éditables via des contrats publics réels. Il restait un trou UX : une mauvaise carte Dialogue/Battle pouvait être corrigée, mais pas supprimée proprement.

V1-30-bis ferme ce trou avant `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`.

## 3. Rappel du scope

Réalisé :

- suppression contrôlée des nodes non-start ;
- suppression des edges entrants/sortants ;
- suppression des `SceneNodeLayout` et `SceneEdgeLayout` liés ;
- protection du Start node ;
- protection du dernier End node ;
- confirmation destructive ;
- reset de sélection via le flow existant ;
- tests core/editor ;
- visual gate ;
- roadmaps mises à jour.

Non réalisé :

- pas de runtime ;
- pas de reconnexion automatique ;
- pas de suppression clavier ;
- pas de payload editing supplémentaire ;
- pas de Consequence UI ;
- pas de Storyline/Event/GameState mutation.

## 4. Gate 0 complet

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie : <vide>

Commande :

```bash
git diff --stat
```

Sortie : <vide>

Commande :

```bash
git diff --name-only
```

Sortie : <vide>

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
df2998d3 feat(scenes): add node payload editing v0
84587492 feat(scenes): add storyline step scene links v0
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
```

## 5. Changements préexistants vs changements du lot

Changements préexistants : aucun, le worktree était propre au Gate 0.

Changements introduits par V1-30-bis :

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png`

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_30_scene_node_payload_editing_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_visual_port_connection_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_14_blueprint_graph_canvas_foundation.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_13_edge_authoring_v0.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

## 7. Audit suppression actuelle

Avant V1-30-bis, `removeSceneNodeDraft` existait déjà et supprimait correctement un node, ses edges liés et ses layouts liés, mais `isSceneNodeDraftKindRemovable` limitait la suppression à `condition`, `merge` et `end`.

Conséquence : Dialogue Yarn et Battle pouvaient être créés/connectés/édités, mais pas supprimés depuis l’inspecteur.

## 8. Design retenu

Décision :

- garder `removeSceneNodeDraft` comme opération pure ;
- élargir la suppression à tous les node kinds non-start ;
- bloquer explicitement `scene.graph.startNodeId` ;
- bloquer le dernier `end` ;
- supprimer seulement node + edges entrants/sortants + layouts associés ;
- ne jamais reconnecter automatiquement ;
- afficher une `Zone dangereuse` dans l’inspecteur ;
- confirmer avant suppression via `CupertinoAlertDialog`, cohérent avec les dialogs déjà utilisés par les pickers de l’inspecteur.

## 9. Opération `removeSceneNodeDraft`

Évolution core :

- `removeSceneNodeDraft` refuse maintenant un `nodeId` vide ;
- `removeSceneNodeDraft` refuse le Start node et le `startNodeId` ;
- `removeSceneNodeDraft` refuse le dernier End ;
- `removeSceneNodeDraft` autorise les nodes non-start existants : `yarnDialogue`, `battle`, `condition`, `merge`, `end` si plusieurs End, `action`, `cinematic`, `branchByOutcome` si présents ;
- `removedEdges` contient les edges entrants/sortants supprimés ;
- `SceneGraph.nodes`, `SceneGraph.edges`, `SceneGraphLayout.nodeLayouts`, `SceneGraphLayout.edgeLayouts` sont reconstruits sans mutation de l’original.

Helper ajouté :

```dart
String? sceneNodeDraftRemovalBlocker(SceneGraph graph, SceneNode node)
bool canRemoveSceneNodeDraft(SceneGraph graph, SceneNode node)
```

## 10. Règles par node kind

- `start` : suppression interdite.
- `end` : suppression autorisée seulement si au moins un autre End reste.
- `yarnDialogue` : suppression autorisée.
- `battle` : suppression autorisée.
- `condition` : suppression autorisée.
- `merge` : suppression autorisée.
- `action` : suppression autorisée si le node existe déjà.
- `cinematic` : suppression autorisée si le node existe déjà.
- `branchByOutcome` : suppression autorisée si le node existe déjà.

## 11. Nettoyage edges/layout

La suppression retire :

- tous les edges où `fromNodeId == nodeId` ;
- tous les edges où `toNodeId == nodeId` ;
- le `SceneNodeLayout` du node ;
- les `SceneEdgeLayout` des edges retirés.

Les autres nodes, edges, layouts, tags, metadata, declared outcomes, storylineId, chapterId et description sont préservés.

## 12. UI suppression

L’inspecteur affiche une section :

```text
Zone dangereuse
Supprimer le nœud
Supprime ce nœud et ses liens entrants/sortants. Aucune reconnexion automatique.
```

Pour le dernier End, l’action est désactivée avec :

```text
Une scène doit garder au moins une fin.
```

Le Start node n’affiche pas l’action de suppression.

## 13. Confirmation destructive

Une confirmation `CupertinoAlertDialog` est ajoutée :

```text
Supprimer ce nœud ?
Cette action supprime le nœud sélectionné et ses liens entrants/sortants. Le graph ne sera pas reconnecté automatiquement.
Annuler / Supprimer
```

La modal macOS existante n’a pas été utilisée car le shell de test actuel ne fournit pas `MacosTheme`; un essai a provoqué un crash de test Flutter. Le log de crash généré localement a été supprimé et la commande concernée a été relancée seule ensuite.

## 14. Diagnostics après suppression

Aucun nouveau diagnostic n’a été ajouté. Les diagnostics existants restent responsables de signaler :

- ports requis manquants ;
- nodes non atteignables ;
- End inatteignable ;
- erreurs de plan runtime si le graph devient incomplet.

La suppression ne masque aucune erreur et ne répare rien automatiquement.

## 15. Runtime plan après suppression

Aucun fichier runtime n’a été modifié. `scene_runtime_plan_test.dart` a été relancé pour vérifier que les changements d’authoring ne cassent pas la construction de plan.

## 16. Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "NS-SCENES-V1-09 scene validation diagnostics writes V1-30-bis scene node deletion UX screenshot"
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-30-bis scene node deletion UX screenshot
00:02 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-30-bis scene node deletion UX screenshot
00:02 +1: NS-SCENES-V1-09 scene validation diagnostics writes V1-30-bis scene node deletion UX screenshot
00:02 +1: All tests passed!
```

Note visuelle : comme les précédents screenshots widget-test, certaines glyphes apparaissent sous forme de blocs dans l’environnement de test, mais la structure Scene Builder, le node sélectionné, les edges et la zone de suppression sont visibles.

## 17. Pourquoi aucun runtime n’a été modifié

Le besoin est strictement authoring/editor. La suppression de node modifie uniquement `ProjectManifest.scenes` en mémoire via les callbacks editor existants. Le runtime consomme plus tard un graph déjà validé/diagnostiqué.

## 18. Pourquoi aucune donnée Selbrume n’a été créée

Les fixtures ajoutées sont neutres :

- `scene_dialogue_battle_ports`
- `node_dialogue`
- `node_battle`
- `trainer_test`
- `dialogue_test`
- `scene_single_end`

Aucun seed produit, aucun Maël/Lysa/Port des Brisants et aucune Scene Selbrume n’ont été créés.

## 19. Tests exécutés

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie finale :

```text
00:00 +34: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie finale :

```text
00:00 +24: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie finale :

```text
00:00 +15: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie finale :

```text
00:09 +64: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie finale :

```text
00:02 +3: All tests passed!
```

Commande relancée seule après crash Flutter causé par exécution parallèle :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie finale :

```text
00:05 +19: All tests passed!
```

Commande non exécutée :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scene_node_deletion_test.dart
```

Raison : aucun fichier dédié `test/scene_node_deletion_test.dart` n’a été créé. Les tests de suppression node sont intégrés dans `test/scenes_workspace_shell_test.dart`, qui couvre déjà le workspace Scene réel et le chemin `ProjectManifest.scenes` en mémoire.

Commande demandée par des lots précédents mais absente du checkout :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart": Does not exist.

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart -p vm --plain-name 'loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart'
00:00 +0 -1: Some tests failed.
```

Recherche du fichier :

```bash
rg --files packages/map_editor/test | rg 'narrative_studio_header|header_test|narrative.*header'
```

Sortie : <vide>

Impact : aucun test existant n’a été ignoré pour V1-30-bis ; le fichier demandé n’existe pas dans l’arborescence actuelle.

## 20. Analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 1.9s)
```

## 21. Recherche anti-Selbrume

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib packages/map_editor/test || true
```

Interprétation : les occurrences retournées appartiennent à des tests historiques, à des assertions négatives existantes ou à des fixtures Selbrume déjà présentes hors scope. Les fichiers modifiés par V1-30-bis ne créent aucune donnée Selbrume.

Contrôle ciblé des fichiers modifiés :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src/authoring/scene_authoring_operations.dart packages/map_core/test/scene_authoring_operations_test.dart packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart packages/map_editor/test/scenes_workspace_shell_test.dart || true
```

Résultat ciblé : seules les assertions négatives préexistantes de `scenes_workspace_shell_test.dart` restent présentes.

## 22. Recherche anti-runtime / anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

Sortie : <vide>

Commande :

```bash
rg -n "Color\(0x|[^A-Za-z]Colors\." packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart packages/map_editor/test/scenes_workspace_shell_test.dart || true
```

Sortie : <vide>

Commande :

```bash
rg -n "SceneEventRuntimeHook|PlayableMapGame|GameState|StorylineStep|sceneLinkIds|MapEventPage|sceneTarget|BranchByOutcome|accepted|refused|choice_|projectWorldRuleEffects|WorldRuleEffect|map_battle|ScenarioAsset|ScenarioRuntimeExecutor" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib packages/map_editor/test || true
```

Interprétation : les occurrences appartiennent au code existant de diagnostics/read models/storylines/world rules/runtime contracts ou à des tests préexistants. Le diff V1-30-bis ne modifie aucun fichier runtime, gameplay, battle, examples ou selbrume.

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie : <vide>

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../src/authoring/scene_authoring_operations.dart  |  51 ++++-
 .../test/scene_authoring_operations_test.dart      | 104 ++++++++-
 .../scenes/scene_node_read_only_inspector.dart     |  59 ++++-
 .../test/scenes_workspace_shell_test.dart          | 248 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  15 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  17 +-
 6 files changed, 468 insertions(+), 26 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis, dont le présent rapport et le screenshot.

## 25. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 26. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png
```

## 27. Evidence Pack

Fichiers créés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png`

Fichiers modifiés :

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Tests rouges observés :

- `removeSceneNodeDraft` refusait `node_yarn` ;
- `removeSceneNodeDraft` refusait `node_battle` ;
- `removeSceneNodeDraft` supprimait le dernier End ;
- l’UI n’affichait pas encore `Zone dangereuse`.

Corrections vérifiées :

- suppression Dialogue ;
- suppression Battle ;
- suppression Condition ;
- protection Start ;
- protection dernier End ;
- suppression edges entrants/sortants ;
- nettoyage layouts ;
- confirmation destructive ;
- update mémoire `ProjectManifest.scenes`.

## 28. Auto-review critique

- Est-ce que j’ai modifié `map_runtime` ? Non.
- Est-ce que j’ai modifié `PlayableMapGame` ? Non.
- Est-ce que j’ai supprimé ou modifié `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j’ai modifié `MapEventPage.sceneTarget` ? Non.
- Est-ce que j’ai muté `GameState` ? Non.
- Est-ce que j’ai supprimé une `SceneAsset` entière ? Non.
- Est-ce que j’ai supprimé le Start node ? Non, il est bloqué.
- Est-ce que j’ai reconnecté automatiquement le graphe ? Non.
- Est-ce que j’ai inventé des refs fake ? Non.
- Est-ce que j’ai activé BranchByOutcome ? Non, seulement suppression si node déjà existant.
- Est-ce que j’ai importé `map_battle` ? Non.
- Est-ce que j’ai créé des données Selbrume ? Non.
- Est-ce que les edges entrants/sortants du node supprimé sont bien retirés ? Oui, tests core/editor.
- Est-ce que les layouts associés sont nettoyés ? Oui, tests core/editor.
- Est-ce que les autres nodes/edges/layouts sont préservés ? Oui.
- Est-ce que la sélection UI est reset proprement ? Oui, elle revient au node préféré via le flow existant.
- Est-ce que le prochain lot a été démarré ? Non.

## 29. Limites restantes

- Pas de suppression via Delete/Backspace.
- Pas de reconnexion automatique.
- Pas de undo/redo spécifique node deletion.
- Pas de visual gate avec texte parfaitement rendu dans l’environnement de test, limite déjà connue des goldens Scene Builder.
- Pas de test dédié séparé `scene_node_deletion_test.dart`; couverture intégrée dans `scenes_workspace_shell_test.dart`.

## 30. Prochain lot recommandé

`NS-SCENES-V1-31 — Scene Consequence Authoring UI V0`

Raison : après création, connexion, déplacement, édition payload et suppression de nodes, le prochain manque no-code majeur est l’édition des `ActionNode` / `SceneConsequence` V0.
