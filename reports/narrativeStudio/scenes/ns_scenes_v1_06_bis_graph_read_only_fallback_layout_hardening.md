# NS-SCENES-V1-06-bis — Graph Read-only Fallback Layout Hardening

## Résumé exécutif

Verdict : DONE.

Le fallback layout de `SceneGraphReadOnlyView` ne peut plus boucler indéfiniment sur un cycle. La propagation non bornée des niveaux a été remplacée par un parcours borné avec `visited`, gestion des roots, puis passage sur les composants non visités.

Le lot ne change pas le modèle core, ne modifie pas `ProjectManifest`, n'ajoute aucun authoring, aucun node inspector, aucun runtime et ne démarre pas V1-07.

## Problème corrigé

Le fallback layout V1-06 faisait progresser des niveaux tant qu'un edge pouvait augmenter le niveau du node cible. Sur un cycle atteignable :

```text
node_a -> node_b
node_b -> node_a
```

les niveaux pouvaient croître sans borne. Résultat : risque de freeze du renderer read-only.

## Algorithme retenu

Nouvelle stratégie :

- construire un set de node IDs connus ;
- construire une adjacency list uniquement avec les edges dont `fromNodeId` et `toNodeId` existent ;
- calculer les roots sans incoming edge connu ;
- parcourir les roots avec une queue BFS et un set `visited` ;
- ignorer les edges vers nodes déjà visités ;
- parcourir ensuite les nodes non visités dans l'ordre stable du graph pour couvrir les cycles purs et composants déconnectés ;
- placer les nodes par niveau puis rangée, sans muter `SceneAsset.layout`.

Garanties :

- boucle bornée par le nombre de nodes + edges ;
- cycles supportés ;
- graphes partiellement déconnectés supportés ;
- nodes affichés une seule fois ;
- layout déterministe ;
- layout persisté complet toujours prioritaire.

## Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_06_bis_graph_read_only_fallback_layout_hardening.md`

## Tests ajoutés

Test ajouté :

```text
uses bounded derived layout for cyclic and disconnected graph
```

Fixture test locale :

```text
node_a -> node_b
node_b -> node_a
node_c -> node_d
```

Le test vérifie :

- graph cyclique rendu en layout dérivé ;
- nodes `node_a`, `node_b`, `node_c`, `node_d` visibles ;
- edges cycliques et déconnectés visibles ;
- `ProjectManifest` non muté ;
- aucun node inspector complet rendu.

Rouge TDD pertinent avant correction :

```text
TIMEOUT after 15s: cyclic fallback layout did not terminate before fix
```

## Résultats exacts

```text
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: NS-SCENES-V1-06 graph read-only skeleton Narrative Studio exposes a real Scenes navigation entry
00:02 +0: NS-SCENES-V1-06 graph read-only skeleton Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-06 graph read-only skeleton Narrative Studio exposes a real Scenes navigation entry
00:02 +1: NS-SCENES-V1-06 graph read-only skeleton shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-06 graph read-only skeleton shows an honest empty state when ProjectManifest.scenes is empty
00:02 +2: NS-SCENES-V1-06 graph read-only skeleton disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-06 graph read-only skeleton disabled actions do not mutate ProjectManifest
00:02 +3: NS-SCENES-V1-06 graph read-only skeleton shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-06 graph read-only skeleton shows real SceneAsset data in the read-only tree and summary
00:02 +4: NS-SCENES-V1-06 graph read-only skeleton uses a derived layout for scenes with incomplete layout
00:02 +5: NS-SCENES-V1-06 graph read-only skeleton uses a derived layout for scenes with incomplete layout
00:02 +5: NS-SCENES-V1-06 graph read-only skeleton uses bounded derived layout for cyclic and disconnected graph
00:02 +6: NS-SCENES-V1-06 graph read-only skeleton uses bounded derived layout for cyclic and disconnected graph
00:02 +6: NS-SCENES-V1-06 graph read-only skeleton local scene selection updates summary without mutating project
00:02 +7: NS-SCENES-V1-06 graph read-only skeleton local scene selection updates summary without mutating project
00:02 +7: NS-SCENES-V1-06 graph read-only skeleton Storylines workspace remains selectable
00:02 +8: NS-SCENES-V1-06 graph read-only skeleton Storylines workspace remains selectable
00:02 +8: NS-SCENES-V1-06 graph read-only skeleton writes V1-06 visual gate screenshot
00:02 +9: NS-SCENES-V1-06 graph read-only skeleton writes V1-06 visual gate screenshot
00:02 +9: All tests passed!
```

## Analyze exact

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart test/scenes_workspace_shell_test.dart
Analyzing 2 items...

No issues found! (ran in 1.5s)
```

## Visual Gate

Visual Gate inchangé : correction algorithmique du fallback layout, pas de changement visuel attendu.

Aucun nouveau screenshot produit.

## Git status initial

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git log --oneline -n 10
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
a85fc3c4 docs(scenes): add scene system audit and roadmap v1.0.0
af6c491b feat(storylines): update structure layout and tests v1.1.1
04cce3b7 feat(storylines): add structure layout chapter/step readability v1.1.0
2c536dbd feat(storylines): fix graph focus layout canvas priority
```

## Git status final

```text
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_06_bis_graph_read_only_fallback_layout_hardening.md
```

## Git diff --stat

```text
 .../canvas/scenes/scene_graph_read_only_view.dart  | 65 +++++++++++----
 .../test/scenes_workspace_shell_test.dart          | 94 ++++++++++++++++++++++
 reports/narrativeStudio/scenes/road_map_scenes.md  | 10 ++-
 3 files changed, 153 insertions(+), 16 deletions(-)
```

## Git diff --name-only

```text
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check

```text
Sortie : <vide>
```

## Auto-review critique

- Le freeze potentiel est corrigé au bon endroit : dans le fallback layout editor read-only.
- Le test cyclique aurait pu bloquer sans timeout externe ; le rouge TDD documente bien le risque.
- Le layout dérivé reste simple ; il n'est pas destiné à produire une belle topologie finale pour gros graphes.
- Aucun comportement produit n'a été ajouté.
- Le prochain vrai travail UX reste l'inspecteur read-only, pas un élargissement du fallback layout.
