# NS-SCENES-V1-104-bis-scope-repair — Evidence Scope Split Closure

## 1. Résumé exécutif
Ce lot est un lot de **réparation documentaire / scope split** visant à clarifier et à scinder la clôture du lot `NS-SCENES-V1-104` de la mise à niveau technique de la cible minimum de déploiement macOS (`MACOSX_DEPLOYMENT_TARGET = 12.0`). Ce correctif d'environnement a été déplacé sous un lot technique distinct nommé `BUILD-MACOS-01`, conservant ainsi `NS-SCENES-V1-104-bis` comme un lot de preuve purement documentaire (evidence-only).

Aucun code logique Dart, widget produit ou fonctionnalité scènes n'a été altéré par cette réparation.

## 2. Diagnostic du problème
Lors de la réalisation du lot `NS-SCENES-V1-104-bis` (qui devait être strictement documentaire / evidence-only), des modifications de configuration Xcode ont été introduites et poussées pour résoudre une erreur de compilation locale sur macOS (target minimum à 12.0). 
Bien que ce changement soit indispensable pour compiler et faire passer les tests sur les machines macOS récentes, ces modifications de fichiers Xcode se trouvaient hors-scope du domaine `NS-SCENES-V1-104`. Elles devaient donc être isolées et suivies dans une catégorie de maintenance appropriée.

## 3. Décision retenue : split BUILD-MACOS-01
- La validation fonctionnelle de `NS-SCENES-V1-104` reste valide et inchangée.
- `NS-SCENES-V1-104-bis` est maintenu comme la clôture documentaire pure (evidence-only) du lot de scènes.
- Les changements de configuration Xcode (fichiers `.pbxproj`) sont formellement extraits du scope fonctionnel et placés sous le lot de maintenance technique `BUILD-MACOS-01 — macOS Deployment Target 12.0 Build Compatibility`.
- Les commits devront être appliqués de manière séparée (voir section 12).

## 4. Vérité sur V1-104
La fonctionnalité développée au lot V1-104 est valide :
- Liaison d'une cible `actorMove` vers un `CinematicStagePoint`.
- Résolution des coordonnées via le read model.
- Affichage correct des étiquettes résolues dans la timeline (ex : `Professor → Point 2`).
- Nettoyage automatique des valeurs `sourceId` zombies.
- Diagnostics d'absence ou d'incohérence de points de scène.

## 5. Vérité sur V1-104-bis
- Le lot `V1-104-bis` apporte toutes les preuves requises par la Quality Gate (checksums d'images, logs bruts de tests unitaires et widgets, diagnostics d'analyse statique).
- Les affirmations de type "Reste à 100% pur" ont été nuancées pour signaler le correctif Xcode initialement intégré et désormais déplacé sous `BUILD-MACOS-01`.

## 6. Fichiers lus
- [AGENTS.md](file:///Users/karim/Project/pokemonProject/AGENTS.md)
- [agent_rules.md](file:///Users/karim/Project/pokemonProject/agent_rules.md)
- [codex_rule.md](file:///Users/karim/Project/pokemonProject/codex_rule.md)
- [ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md)
- [ns_scenes_v1_104_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_evidence_pack.md)
- [ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md)
- [ns_scenes_v1_104_bis_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md)
- [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md)
- [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md)

## 7. Fichiers modifiés par ce scope repair
- [ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md)
- [ns_scenes_v1_104_bis_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md)
- [road_map_scenes.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scenes.md)
- [road_map_scene_builder_authoring.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md)

## 8. Fichiers Xcode exclus du scope scènes
- [playable_runtime_host/project.pbxproj](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj)
- [map_editor/project.pbxproj](file:///Users/karim/Project/pokemonProject/packages/map_editor/macos/Runner.xcodeproj/project.pbxproj)

Ces deux fichiers sont transférés sous le lot `BUILD-MACOS-01`.

## 9. Evidence Pack
Toutes les preuves (analyses, tests, signatures) sont consignées dans le rapport [ns_scenes_v1_104_bis_evidence_pack.md](file:///Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md) actualisé.

## 10. Commandes exécutées
```bash
git diff --check
```

Comme ce lot est purement documentaire et n'altère aucun code source Dart, aucune exécution de test Dart/Flutter ou de build n'est requise.

## 11. Git diff --check/stat/name-only/status final

### git diff --check
```text
(Aucune erreur de format ou d'espaces)
```

### git diff --stat
*(Diff du working tree non-engagé à la fin du lot de scope-repair)*
```text
 reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md | 20 +++++++++++---------
 reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md                                               | 14 ++++++++------
 reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md                                                 |  2 ++
 reports/narrativeStudio/scenes/road_map_scenes.md                                                                  |  2 ++
 4 files changed, 23 insertions(+), 15 deletions(-)
```

### git diff --name-only
```text
reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md
reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git status --short --untracked-files=all
```text
 M reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md
 M reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_scope_repair.md
```
*Note: Les fichiers sous `reports/build/` n'apparaissent pas dans `git status` car ils sont ignorés par la règle récursive `build/` (ligne 26 de `.gitignore`). Ils existent sur le disque et devront être indexés de force via `git add -f reports/build/`.*

## 12. Séparation de commit

Les modifications physiques en cours dans l'arbre de travail devront être validées et enregistrées séparément par le mainteneur :

### Groupe A — V1-104 / V1-104-bis scènes evidence
*Fichiers à inclure :*
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_actor_move_stage_point_target_evidence_quality_gate_closure.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_104_bis_scope_repair.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_104_cinematic_actor_move_target_from_stage_points_v0.png`

*Message recommandé :*
`doc(narrativeStudio): close NS-SCENES-V1-104 and compile evidence pack`

### Groupe B — BUILD-MACOS-01
*Fichiers à inclure :*
- `examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj`
- `packages/map_editor/macos/Runner.xcodeproj/project.pbxproj`
- `reports/build/ns_build_macos_01_macos_deployment_target_12_compatibility.md`
- `reports/build/road_map_build_maintenance.md`

*Message recommandé :*
`build(macos): bump minimum macOS deployment target to 12.0`

## 13. Verdict final
- **V1-104** : Fonctionnellement clos.
- **V1-104-bis** : Evidence closure et Quality Gate corrigées et conformes (evidence-only).
- **Correctif macOS/Xcode target** : Isolé proprement sous `BUILD-MACOS-01`.
- **Aucun V1-104-ter** fonctionnel n'est requis.
- **V1-105** n'a pas été démarré.

## 14. Confirmation explicite : aucun prompt ou travail V1-105 n’a été produit
Il est confirmé qu'aucun prompt, fichier de planification, modification de code ou autre artefact lié au lot `NS-SCENES-V1-105` n'a été rédigé ou produit dans le cadre de cette session.
