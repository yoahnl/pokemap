# World Map Editor — Gate 3 Direct manipulation

Date : 2026-07-29
Lots : `SEL-01 — Hit-test commun`, `MOV-01 — Déplacement transactionnel`,
`LAY-01 — Groupes de calques visibles`
Package : `packages/map_editor`
Baseline : `7fb9e9d52bfd96a293d677078b1e3963fb9545d7`
Dernier commit produit avant clôture : `3d0aac55f`

## 1. Résumé exécutif

Gate 3 peut être proposée comme **DONE**.

Le World Map Editor sait maintenant :

- sélectionner depuis le canvas les six familles d'objets éditoriaux discrets ;
- respecter la visibilité, la pile visuelle canonique et les superpositions ;
- cycler de façon déterministe entre des objets superposés ;
- prévisualiser un déplacement par ghost sans muter `MapData` ;
- committer le déplacement au relâchement en exactement une transaction ;
- annuler le geste avec `Escape`, pointer cancel, perte des boutons ou dérive de
  contexte sans dirty state ni historique parasite ;
- préserver l'identité et toutes les propriétés hors géométrie ;
- refuser explicitement le déplacement direct des placements Environment
  générés ;
- déplacer atomiquement les projections `tile_index` et empêcher les collisions
  d'IDs lors d'une future resynchronisation ;
- présenter et réordonner les groupes visibles `Tile + Environment attachés`
  sans séparer leurs membres ;
- refuser toute reconstruction de groupe qui ne conserve pas chaque instance
  sérialisée exactement une fois, même sur une map legacy déjà invalide ;
- conserver une sélection technique Environment à travers move, undo et redo.

La validation finale fraîche donne :

```text
flutter test (package complet)
04:39 +4627 ~6: All tests passed!

flutter analyze
No issues found! (ran in 5.1s)

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/PokeMap.app
```

Les six tests ignorés appartiennent à leur configuration propre ; aucun test
Gate 3 n'est ignoré.

## 2. Confirmation du scope

### 2.1 Scope livré

`SEL-01` couvre :

- `MapPlacedElement` ;
- `MapEntity` ;
- `MapEventDefinition` ;
- `MapWarp` ;
- `MapTrigger` ;
- `MapGameplayZone` ;
- visibilité de calque et d'objet ;
- ordre top-first issu de Gate 1 ;
- priorité conforme au painter ;
- cycle déterministe des superpositions ;
- sélection Border spécialisée conservée en fallback.

`MOV-01` couvre :

- les six familles ci-dessus ;
- snap par cellules sans saut lorsque la prise ne commence pas sur l'ancre ;
- empreinte visuelle animée courante pour le ghost et les bounds ;
- plan pur, preview sans mutation et commit unique ;
- destination identique, hors limites, occupée ou source stale ;
- placement authored/legacy ;
- placement `tile_index` déplacé avec son motif de tuiles ;
- placement Environment généré protégé ;
- gardes Entity/Trigger et invariant Event `v2Only` existants ;
- undo/redo en une étape.

`LAY-01` couvre :

- groupe visible ancré par un Tile ;
- un ou plusieurs Environment valides, même intercalés dans l'entrée ;
- ordre interne et instances `MapLayer` préservés ;
- IDs Environment dupliqués invalides traités par identité sans duplication ;
- Environment orphelin, cible absente ou cible non-Tile autonome ;
- flèches Haut/Bas, drag avant une row et sentinel de fin ;
- bornes calculées sur les groupes visibles ;
- une mutation et une entrée d'historique ;
- sélection technique Environment ;
- navigation clavier, sémantique de position/composition et design system.

### 2.2 Interprétation du prompt auditée

L'audit initial a constaté qu'aucune roadmap suivie ne définissait formellement
un fichier « Gate 3 ». Les IDs `SEL-01`, `MOV-01` et `LAY-01` provenaient du
rapport d'audit du World Map Editor comme lots proposés. L'instruction a donc
été interprétée comme l'exécution de ces trois lots, après confirmation de leurs
critères et de leurs dépendances Gate 1/Gate 2.

Un plan dédié a été créé :

```text
docs/superpowers/plans/2026-07-29-world-map-gate-3-direct-manipulation.md
```

Ce fichier est volontairement local car `.gitignore:7` ignore `/docs/*`. Il
n'est pas présenté comme un artefact versionné.

### 2.3 Non-objectifs conservés

- multisélection ;
- déplacement au clavier par pas ;
- duplication ou suppression directe depuis le canvas ;
- déplacement générique des Border features ;
- manipulation des connexions de cartes ;
- refonte de l'inspecteur contextuel complet ;
- cache, recherche, dossiers, récents, favoris et mémoire de palette par
  calque, qui relèvent de Gate 4 ;
- recomposition complète canvas-first du workspace, qui relève de Gate 5 ;
- certification matérielle Magic Mouse et VoiceOver, qui relève de Gate 6 ;
- changement de schéma `map_core`.

## 3. Audit initial

### 3.1 État fonctionnel observé

Les passes initiales ont confirmé :

1. l'outil Selection ne sélectionnait génériquement que Border ;
2. les six familles rendues n'avaient pas de hit-test commun ;
3. un clic dans un outil de placement pouvait confondre sélectionner et créer ;
4. les placements posés étaient principalement sélectionnables depuis une
   liste ;
5. aucune transaction de drag générique n'existait ;
6. le statut des placements `tile_index` et Environment empêchait un simple
   `copyWith(pos:)` sûr ;
7. la liste des calques groupait déjà visuellement certains Environment, mais
   les flèches et le drag utilisaient encore les indices sérialisés bruts ;
8. un groupe affiché pouvait donc être séparé par un réordonnancement.

Verdict initial : **FAIL / Gate 3 non livrable**.

### 3.2 Contrats existants réutilisés

- Gate 1 : pile visuelle canonique top-first, peinte bottom-to-top ;
- Gate 2 : arbitre exclusif du pointeur, terminaux idempotents, rollback et
  interlocks historique ;
- `EditorNotifier._applyMapMutation` : mutation et historique centralisés ;
- `MapValidator` et gardes de dépendance Entity/Trigger ;
- `PlacedElementInstanceIndexer` : projection des motifs `tile_index` ;
- contrôleur Border spécialisé ;
- primitives `PokeMapCard`, `PokeMapBadge`, `PokeMapButton` et
  `PokeMapIconButton`.

### 3.3 Risques identifiés avant code

- divergence hit-test/painter sur la visibilité ou l'animation ;
- inversion accidentelle de l'ordre top-first ;
- cycle de sélection poursuivi après changement de cellule ou de pile ;
- mutation du document pendant le ghost ;
- plusieurs entrées undo pour un seul drag ;
- perte silencieuse de payloads de `GameplayZone` ;
- désynchronisation d'un placement `tile_index` et de ses cellules ;
- collision d'ID après déplacement puis repeinture à l'ancienne position ;
- déplacement direct d'une sortie Environment générée ;
- Border consommant un clic alors qu'un objet est peint au-dessus ;
- groupe Tile/Environment séparé par un indice raw ;
- sélection technique Environment remplacée par l'ID du Tile ;
- UI responsive débordante après migration vers les primitives DS.

### 3.4 Rapports et tests de caractérisation relus

L'audit n'est pas reparti d'hypothèses neuves. Les trois Evidence Packs
antérieurs directement pertinents ont été relus :

- `reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md` ;
- `reports/ui/world_map_editor_gate_1_wysiwyg_2026-07-28.md` ;
- `reports/ui/world_map_editor_gate_2_interactions_2026-07-29.md`.

Les tests présents au baseline `7fb9e9d52` qui caractérisaient déjà les
contrats réutilisés ont également été inventoriés avant modification :

- `test/border_map_editing/map_canvas_border_selection_test.dart` ;
- `test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart` ;
- `test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart` ;
- `test/features/editor/application/map_canvas_interaction_controller_test.dart` ;
- `test/map_canvas_interaction_arbitration_test.dart` ;
- `test/map_canvas_pointer_navigation_test.dart` ;
- `test/placed_element_instance_delete_origin_test.dart` ;
- `test/placed_element_instance_indexer_test.dart` ;
- `test/placed_element_instance_opacity_notifier_test.dart`.

Verdict de caractérisation : ces preuves sécurisaient les contrats Gate 1 et
Gate 2, le Border, l'indexation et la présentation de groupes, mais aucune ne
prouvait la sélection commune des six familles, leur déplacement transactionnel
ou le réordonnancement atomique d'un groupe visible.

## 4. État Git initial

Commande :

```bash
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git status --short --untracked-files=all
```

Résultat :

```text
branch=main
HEAD=7fb9e9d52bfd96a293d677078b1e3963fb9545d7
origin_main=7fb9e9d52bfd96a293d677078b1e3963fb9545d7
status_count=62
```

Les 62 entrées ci-dessous préexistaient à Gate 3 et ont été maintenues hors de
tous les commits :

```text
 M .github/workflows/pokemap_hub_product_certification.yml
 M apps/pokemap_hub/integration_test/runtime_owned_player_flow_test.dart
 M apps/pokemap_hub/test/saves/hub_save_store_atomic_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/narrative_command_descriptor.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/lib/src/read_models/narrative_command_catalog.dart
 M packages/map_core/lib/src/tooling/gameplay_roadmap_dashboard.dart
 M packages/map_core/test/gameplay_roadmap_dashboard_test.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/narrative_command_catalog_test.dart
 M packages/map_core/test/narrative_command_contract_parity_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/tool/generate_gameplay_roadmap_dashboard.dart
 M packages/map_editor/lib/game_export.dart
 M packages/map_editor/lib/src/application/services/narrative_template_catalog.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_profile.dart
 M packages/map_editor/lib/src/features/game_export/application/game_package_export_service.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_controller.dart
 M packages/map_editor/lib/src/features/game_export/presentation/game_package_export_dialog.dart
 M packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_action_builder.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/cinematic_builder_characterization_performance_test.dart
 M packages/map_editor/test/event_builder_v2_template_sheet_test.dart
 M packages/map_editor/test/event_registry_persistence_performance_test.dart
 M packages/map_editor/test/game_export/game_export_test_fixture.dart
 M packages/map_editor/test/game_export/game_package_export_controller_test.dart
 M packages/map_editor/test/game_export/game_package_export_dialog_test.dart
 M packages/map_editor/test/game_export/game_package_export_service_test.dart
 M packages/map_editor/test/game_export/runtime_project_projection_builder_test.dart
 M packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart
 M packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart
 M packages/map_editor/test/narrative_global_search_performance_test.dart
 M packages/map_editor/test/narrative_large_project_workspace_performance_test.dart
 M packages/map_editor/test/narrative_template_catalog_test.dart
 M packages/map_editor/test/personalization/phase_6_personalization_studio_export_e2e_test.dart
 M packages/map_editor/test/scene_action_builder_test.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
 D packages/map_runtime/test/le_train_m00_external_runtime_smoke_test.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
 M reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json
 M tool/pokemap_product_certification/pubspec.lock
?? packages/gamepads_darwin/macos/gamepads_darwin/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/gamepads_ios/ios/gamepads_ios/.swiftpm/xcode/xcuserdata/karim.xcuserdatad/xcschemes/xcschememanagement.plist
?? packages/map_core/lib/src/tooling/gameplay_roadmap_evidence.dart
?? packages/map_editor/dart_test.yaml
?? packages/map_editor/lib/src/features/game_export/application/game_package_gameplay_readiness_gate.dart
?? packages/map_runtime/test/rendered_map_pixel_smoke_test.dart
?? reports/gameplay/audit/avelune_pokemap_ultra_complete_product_audit_2026-07-28.md
?? reports/gameplay/avelune_pokemap_product_roadmap_2026-07-28.md
?? reports/gameplay/evidence/README.md
?? reports/gameplay/phase_0_truth_and_contract_gates_implementation_2026-07-28.md
```

## 5. Passes indépendantes et verdicts

### 5.1 Sub-agent Audit / Architecture

Verdict initial : **READY sous plan dédié**.

Il a confirmé les trois lots, les dépendances Gate 1/Gate 2, le contrat
clic/ghost/commit/rollback et les limites de scope. Il a aussi identifié les
deux pièges structurants de MOV-01 : une projection `tile_index` ne peut pas
être déplacée sans ses cellules, et les helpers génériques de zone peuvent
renormaliser des payloads non géométriques.

Verdict final code :

```text
SEL-01 : aucun blocker/important restant
MOV-01 : PASS — aucun blocker ni finding important
LAY-01 : PASS — aucun blocker/important
```

### 5.2 Sub-agent Implémentation

Verdict : **PASS**.

Les sous-tâches indépendantes ont produit :

- le durcissement déterministe de l'indexeur `tile_index` avec preuve RED/GREEN ;
- le nouveau propriétaire d'interaction `draggingSelection` et ses terminaux
  idempotents ;
- le service pur `MapLayerGroupService` et sa matrice de neuf tests.

Chaque contribution a été relue et intégrée sans commit autonome parasite.

### 5.3 Sub-agent Tests / UX / Design system

Les premières passes ont trouvé puis fait corriger :

- la divergence de visibilité des événements sans layer ;
- la priorité Border contre les objets peints au-dessus ;
- le cycle poursuivi entre deux cellules ;
- l'empreinte animée différente entre hit-test, painter et déplacement ;
- l'absence de feedback persistant/live sur un drop invalide ;
- les commandes de calques fondées sur les indices raw ;
- les interactions imbriquées et `Colors.transparent` dans le panneau ;
- l'absence de semantics selected/position/composition ;
- les tests drag, clavier, bornes et sélection Environment manquants.

Verdict final Tests / UX / Design system : **PASS** sur SEL-01, MOV-01 et
LAY-01, sans blocker ni finding important. Trois dettes mineures restent :

- un drop sur soi affiche encore un hover positif avant de devenir un no-op ;
- le focus disabled de `PokeMapIconButton` reste une dette transverse du DS ;
- VoiceOver natif et continuité exacte du focus ne sont pas certifiés.

### 5.4 Sub-agent Build / Validation

La première passe indépendante a rendu **PASS** sur
`63cd18ba822a05c4b9cd47fe65627e76467eb3de`.

La passe a vérifié :

```text
3 commits linéaires
20 fichiers distincts
4993 insertions, 284 suppressions
git diff --check baseline..HEAD : clean
git show --check sur chaque commit : clean
intersection Gate 3 / changements étrangers : vide
```

Commande ciblée indépendante :

```bash
flutter test \
  test/features/editor/application/map_canvas_object_hit_test_test.dart \
  test/features/editor/application/map_canvas_object_move_planner_test.dart \
  test/features/editor/application/map_layer_grouping_test.dart \
  test/features/editor/application/map_canvas_interaction_controller_test.dart \
  test/placed_element_instance_indexer_test.dart \
  test/map_canvas_object_selection_test.dart \
  test/border_map_editing/map_canvas_border_selection_test.dart \
  test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart \
  test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart \
  test/map_canvas_interaction_arbitration_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/ui/shell/pokemap_inspector_shell_migration_test.dart \
  test/ui/shell/pokemap_map_navigation_responsive_test.dart \
  test/ui/shell/pokemap_right_inspector_resize_test.dart
```

```text
+133: All tests passed!
flutter analyze : No issues found! (ran in 4.1s)
flutter build macos --debug :
  ✓ Built build/macos/Build/Products/Debug/PokeMap.app
exit 0
```

Limite signalée : validation dans le worktree partagé, mais aucun des 20
fichiers Gate 3 n'a de changement non commité et l'intersection avec les 62
entrées étrangères est vide.

Après le correctif issu de la critique, la certification fraîche sur
`3d0aac55fa507ab307f8ebb8f85bfe9dd81bbf60` a de nouveau exécuté la suite
complète, l'analyse et le build. Les résultats exacts sont consignés en
section 10 : `+4627 ~6`, analyse sans issue et application macOS construite.

### 5.5 Sub-agent Critique finale

La première critique a rendu **FAIL avant clôture** sur un cas legacy précis :
deux Environment partageant le même ID mais visant deux Tile distincts
pouvaient être récupérés dans les deux groupes, puis aplatis plusieurs fois.
Elle a également demandé des preuves notifier directes pour la source stale,
`v2Only` et les gardes Entity/Trigger.

Le correctif a :

- remplacé les associations par ID par des collections d'identité ;
- ajouté un invariant non contournable de permutation des instances dans
  `_mapWithGroups` ;
- ajouté le test RED/GREEN avec deux Environment `duplicate` visant deux Tile ;
- ajouté trois preuves notifier directes couvrant source stale, Event
  `v2Only`, et revalidation des sources Entity/Trigger liées ;
- supprimé le rejet `sourceMapChanged` mort du planner et de ses switches.

Verdict final indépendant sur ce correctif : **PASS — aucun blocker ni finding
important**. La critique a confirmé que chaque instance est désormais présente
exactement une fois et que les quatre garde-fous demandés sont couverts.

Le seul risque important non bloquant conservé est la performance du double
`syncLayer` pendant le preview d'un grand placement `tile_index`. Il est
documenté en section 13.2 et ne remet pas en cause l'intégrité du document.

## 6. Décisions d'architecture

### 6.1 Une cible commune, pas six branches UI

`MapCanvasObjectTarget` porte le kind, l'ID, l'ancre, l'empreinte et le layer.
`MapCanvasObjectHitTest` construit une pile déterministe depuis les objets
visibles et réutilise la convention Gate 1. Le notifier applique ensuite une
sélection exclusive aux IDs spécialisés existants.

### 6.2 Le ghost est editor-only

Le drag ne démarre qu'après promotion de `pendingPrimary` vers
`draggingSelection`. La preview contient un plan pur et la référence exacte de
la map source. Aucune mutation progressive n'est faite ; le pointer-up appelle
une seule fois `commitCanvasObjectMove`.

### 6.3 Une mutation strictement géométrique

Le planner remplace l'objet à son index et ne modifie que :

- `pos` ;
- `position.x/y` pour Event ;
- `area.pos` pour Trigger et GameplayZone ;
- le motif Tile et `pos` ensemble pour `tile_index`.

Les tests restaurent la géométrie puis comparent l'objet complet, afin de
détecter toute perte de propriété.

### 6.4 Les erreurs préexistantes restent réparables

Le réordonnancement des groupes associe ses attachments par identité, conserve
chaque instance de layer exactement une fois et ne change que l'ordre.
`_mapWithGroups` vérifie longueur et multiensemble d'identités avant de
construire le candidat : cet invariant ne peut pas être contourné par la
tolérance du validator.

Si la map de départ est déjà invalide (par exemple Environment orphelin),
l'opération de permutation reste ensuite autorisée afin de ne pas rendre la row
de réparation immobile. Deux orphelins dont l'ordre change la première erreur
du validator et deux Environment aux IDs dupliqués visant des Tile distincts
sont couverts.

### 6.5 Le panneau manipule ce qu'il montre

La présentation et les commandes consomment le même
`MapLayerGroupService`. Les indices raw ne pilotent plus Haut/Bas ou le drop.
Une action aplatit les groupes une seule fois, puis passe par une seule
`_applyMapMutation`.

## 7. Inventaire complet des fichiers Gate 3

Diff de série :

```text
20 fichiers
5227 insertions
284 suppressions
```

### 7.1 Fichiers créés

| Fichier | Zones | Raison et impact |
|---|---|---|
| `docs/superpowers/plans/2026-07-29-world-map-gate-3-direct-manipulation.md` | plan complet Gate 3 | Cadrage local ignoré par `/docs/*`, inclus intégralement en annexe |
| `reports/ui/world_map_editor_gate_3_direct_manipulation_2026-07-29.md` | présent Evidence Pack | Audit, preuves, inventaire, critique et clôture ; auto-inclusion récursive impossible |
| `lib/src/features/editor/application/map_canvas_object_hit_test.dart` | `MapCanvasObjectKind`, `MapCanvasObjectTarget`, `MapCanvasObjectHitTest` | Contrat pur commun, visibilité, ordre, empreintes et cycle |
| `lib/src/features/editor/application/project_element_frame_resolver.dart` | `pickProjectElementFrame`, durée/animation | Même frame entre hit-test, rendu et outline |
| `test/features/editor/application/map_canvas_object_hit_test_test.dart` | matrice pure SEL-01 | Six familles, visibilité, ordre, footprints, cycles et vides |
| `test/map_canvas_object_selection_test.dart` | intégration widget/notifier SEL/MOV | Sélection exclusive, Border, ghost, commit, invalidité, Escape, source stale, `v2Only`, gardes Entity/Trigger et Environment |
| `lib/src/features/editor/application/map_canvas_object_move_planner.dart` | résultats/rejets/planner, branches six familles et `tile_index` | Preview pure, bounds, préservation stricte, projection atomique |
| `test/features/editor/application/map_canvas_object_move_planner_test.dart` | matrice pure MOV-01 | Six familles, propriétés, stale, invalidité, Environment et `tile_index` |
| `lib/src/features/editor/application/map_layer_grouping.dart` | `MapLayerGroup`, `MapLayerGroupService` | Projection visible, associations par identité et permutation atomique vérifiée |
| `test/features/editor/application/map_layer_grouping_test.dart` | matrice pure LAY-01 | attachments, interleaving, orphelins, IDs dupliqués, bornes, drag et no-op |

Le contenu intégral et le SHA-256 du plan local et des huit fichiers Dart
créés figurent en annexe 14. Le présent rapport est exclu de cette règle
récursive.

### 7.2 Fichiers modifiés

| Fichier | Repérage exact | Raison et impact |
|---|---|---|
| `lib/src/application/services/placed_element_instance_indexer.dart` | 3 hunks, listés intégralement ci-dessous | Réserver les IDs existants et suffixer `_2`, `_3` sans changer une instance déplacée |
| `lib/src/features/editor/application/map_canvas_interaction_controller.dart` | 2 hunks, listés intégralement ci-dessous | Ajouter/promouvoir le propriétaire exclusif `draggingSelection` |
| `lib/src/features/editor/state/editor_notifier.dart` | 9 hunks, listés intégralement ci-dessous | Imports, cycle/sélection exacte, commit move avec gardes, groupe de layers et nettoyage de contexte |
| `lib/src/ui/canvas/entity_editor_element_visual.dart` | 4 hunks, listés intégralement ci-dessous | Déléguer l'animation au resolver commun |
| `lib/src/ui/canvas/map_canvas.dart` | 29 hunks, listés intégralement ci-dessous | Imports, labels, session/ghost, routage pointeur, terminaux, lifecycle, feedback live et painter de preview |
| `lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | 4 hunks, listés intégralement ci-dessous | Outline animé cohérent et règle de visibilité Event commune |
| `lib/src/ui/panels/layers_panel.dart` | 26 hunks, listés intégralement ci-dessous | Import DS, indices visibles, drag groupé, composants DS, responsive, semantics, clés de test et suppression de l'ancienne row |
| `lib/src/ui/panels/layers_panel_presentation.dart` | 6 hunks, listés intégralement ci-dessous | Construire les rows depuis les groupes partagés |
| `test/border_map_editing/map_canvas_border_selection_test.dart` | 2 hunks, listés intégralement ci-dessous | Non-régression objet au-dessus de Border et exclusivité |
| `test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart` | 5 hunks, listés intégralement ci-dessous | Imports, flèches/drag, bornes, undo/redo, orphelins, clavier, semantics et helpers |
| `test/features/editor/application/map_canvas_interaction_controller_test.dart` | 1 hunk, listé intégralement ci-dessous | Promotion, ownership et terminaux idempotents du drag |
| `test/placed_element_instance_indexer_test.dart` | 1 hunk, listé intégralement ci-dessous | A→B puis repeinture A sans collision d'ID |

Hunks exacts du diff `7fb9e9d52b..3d0aac55f`, sans regroupement ni omission :

```text
lib/src/application/services/placed_element_instance_indexer.dart
  @@ -109,0 +110,3 @@
  @@ -208,4 +211,7 @@
  @@ -319,0 +326,11 @@
lib/src/features/editor/application/map_canvas_interaction_controller.dart
  @@ -109,0 +110 @@
  @@ -357 +358,2 @@
lib/src/features/editor/state/editor_notifier.dart
  @@ -64,0 +65,2 @@
  @@ -65,0 +68 @@
  @@ -210,0 +214,6 @@
  @@ -323,4 +332,9 @@
  @@ -333,0 +348,9 @@
  @@ -6090,0 +6114,339 @@
  @@ -10117,0 +10480,104 @@
  @@ -10283,0 +10750 @@
  @@ -10284,0 +10752,8 @@
lib/src/ui/canvas/entity_editor_element_visual.dart
  @@ -5,0 +6,2 @@
  @@ -10 +12,2 @@
  @@ -28,5 +31 @@
  @@ -39,25 +38 @@
lib/src/ui/canvas/map_canvas.dart
  @@ -44,0 +45,3 @@
  @@ -93,0 +97,96 @@
  @@ -192,0 +292,69 @@
  @@ -203,0 +372 @@
  @@ -212,0 +382 @@
  @@ -286,0 +457 @@
  @@ -818,19 +988,0 @@
  @@ -862,0 +1015,20 @@
  @@ -903,0 +1076,59 @@
  @@ -973,0 +1205,5 @@
  @@ -1023,0 +1260,13 @@
  @@ -1056,2 +1305,4 @@
  @@ -1086,3 +1337,5 @@
  @@ -1090,37 +1342,0 @@
  @@ -1128,18 +1344,68 @@
  @@ -1149,0 +1416,30 @@
  @@ -1493 +1789,17 @@
  @@ -1499,0 +1812,52 @@
  @@ -1546,0 +1911 @@
  @@ -1568,0 +1934 @@
  @@ -1610,0 +1977 @@
  @@ -1621,0 +1989 @@
  @@ -1772,0 +2141 @@
  @@ -1899,0 +2269,2 @@
  @@ -1962,0 +2334,2 @@
  @@ -2345,0 +2719,23 @@
  @@ -2350,2 +2746,6 @@
  @@ -2353,4 +2753,40 @@
  @@ -2357,0 +2794,13 @@
lib/src/ui/canvas/map_canvas/map_grid_painter.dart
  @@ -740,0 +741,13 @@
  @@ -754,2 +767,5 @@
  @@ -918,0 +935,3 @@
  @@ -921,0 +941,3 @@
lib/src/ui/panels/layers_panel.dart
  @@ -3 +3 @@
  @@ -325,0 +326 @@
  @@ -328 +329 @@
  @@ -330 +331 @@
  @@ -362,2 +363,2 @@
  @@ -366,0 +368 @@
  @@ -369 +371,4 @@
  @@ -393,0 +399 @@
  @@ -398 +404 @@
  @@ -441,3 +447,12 @@
  @@ -446,11 +461 @@
  @@ -458,19 +463,9 @@
  @@ -501,2 +496,9 @@
  @@ -511,0 +514,2 @@
  @@ -516,0 +521,6 @@
  @@ -522 +532,2 @@
  @@ -524,3 +535,13 @@
  @@ -548,42 +569,9 @@
  @@ -595,0 +584,44 @@
  @@ -617 +649,3 @@
  @@ -622,0 +657 @@
  @@ -624 +659 @@
  @@ -674 +709,4 @@
  @@ -676,9 +713,0 @@
  @@ -711,0 +741,25 @@
  @@ -773,24 +826,0 @@
lib/src/ui/panels/layers_panel_presentation.dart
  @@ -2,0 +3,2 @@
  @@ -6 +8 @@
  @@ -15 +17 @@
  @@ -39,18 +41,2 @@
  @@ -58,11 +44,4 @@
  @@ -77 +56 @@
test/border_map_editing/map_canvas_border_selection_test.dart
  @@ -52,0 +53 @@
  @@ -92,0 +94,31 @@
test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
  @@ -0,0 +1,2 @@
  @@ -2,0 +5 @@
  @@ -133,0 +137,283 @@
  @@ -228,0 +515,47 @@
  @@ -245,0 +579,61 @@
test/features/editor/application/map_canvas_interaction_controller_test.dart
  @@ -6,0 +7,103 @@
test/placed_element_instance_indexer_test.dart
  @@ -156,0 +157,53 @@
```

Commande de preuve :

```bash
git diff --unified=0 \
  7fb9e9d52bfd96a293d677078b1e3963fb9545d7..3d0aac55f \
  -- packages/map_editor
```

## 8. Tests créés ou modifiés

### 8.1 SEL-01

- pile topmost des six familles ;
- calques et objets masqués ;
- événements legacy sans layer ;
- empreinte multi-case et frame animée ;
- cycle stable et reset cellule/pile/map ;
- clic vide sans mutation ;
- exclusivité entre IDs de sélection ;
- priorité objet/Border ;
- live label et outline.

### 8.2 MOV-01

- six mutations strictement géométriques ;
- bounds source/destination et no-op ;
- capture de l'identité de la map source dans le plan ;
- métadonnées `tile_index` stale ;
- placement Environment protégé, y compris marker mensonger ;
- `tile_index` overlap-safe, destination occupée et resync stable ;
- collision déterministe après A→B puis repaint A ;
- ghost avant commit ;
- pointer-up, undo et redo ;
- Escape, pointer cancel, boutons perdus et dérive de contexte ;
- destination invalide et feedback persistant/live ;
- empreinte animée courante distincte de l'empreinte primaire.
- rejet notifier direct d'une map source remplacée pendant le drag ;
- blocage notifier direct d'un ancien Event en mode `v2Only` ;
- revalidation des sources narratives Entity et Trigger liées ;
- commit warp par le canvas et dérive du contexte d'interaction.

### 8.3 LAY-01

- un ou plusieurs attachments ;
- members interleaved et ordre interne stable ;
- cible absente ou non-Tile ;
- premier Haut et dernier Bas disabled sans historique ;
- flèches et clavier ;
- drag avant une row et sentinel final ;
- une transaction, undo/redo ;
- sélection technique Environment ;
- un puis deux orphelins réordonnables ;
- IDs Environment dupliqués vers deux Tile sans duplication d'instance ;
- semantics selected, position et composition ;
- breakpoints `800×600`, `1000×800`, `1280×800`, large.

## 9. TDD et corrections issues des revues

### 9.1 SEL-01

Le premier RED prouvait l'absence de l'API de hit-test commun. Les revues ont
ensuite trouvé quatre défauts réels : priorité Border, cycle inter-cellules,
Event sans layer et empreinte animée. Chacun a reçu une correction et un test
avant le commit.

### 9.2 MOV-01

Les cycles RED ont reproduit :

- enum `draggingSelection` absent ;
- promotion refusée ;
- collision de l'ID coordonnée après déplacement/repeinture ;
- drag intégré non committé pendant la construction du lifecycle.

La revue UX a ensuite bloqué sur l'empreinte animée et les feedbacks invalides.
Le planner a séparé empreinte visuelle de déplacement et empreinte primaire de
projection `tile_index`; le canvas garde maintenant la cause du rejet dans une
live region après le relâchement.

### 9.3 LAY-01

Les deux tests flèches étaient RED avec les résultats fautifs :

```text
Haut obtenu : [decor, top, env_decor, bottom]
Bas obtenu  : [top, env_decor, decor, bottom]
```

Ils passent après la projection groupée.

Un test à deux orphelins a ensuite révélé que comparer seulement la première
erreur `MapValidator` pouvait bloquer leur permutation. Le guard autorise
maintenant un reorder qui ne fait que permuter les mêmes instances si la map
source était déjà invalide.

La critique finale a ensuite construit un cas plus hostile : deux Environment
portant le même ID mais visant deux Tile différents. Le premier test était RED
avec `7` layers reconstruits depuis `5`. Les associations sont maintenant
fondées sur l'identité, et `_mapWithGroups` refuse toute sortie qui ne conserve
pas exactement le multiensemble d'instances source.

Enfin, un premier run complet a découvert deux overflows introduits par la
migration DS :

- 1 px vertical dans le bouton de sélection à deux lignes ;
- 7,4 px horizontal au breakpoint `1000×800`.

Le bouton est désormais mono-ligne avec métadonnées séparées, et le seuil
compact passe à 220 px. Les tests responsables puis la suite complète sont
verts.

### 9.4 Correctif de critique finale

Commande RED :

```bash
flutter test \
  test/features/editor/application/map_layer_grouping_test.dart \
  --plain-name \
  'duplicate Environment ids never duplicate serialized layer instances'
```

```text
Expected: an object with length of <5>
Which: has length of <7>
00:00 +0 -1: Some tests failed.
exit_code=1
```

Après correction, le test isolé passe, puis la matrice de sécurité suivante
valide grouping, notifier, planner et panneau :

```bash
dart format \
  lib/src/features/editor/application/map_canvas_object_move_planner.dart \
  lib/src/features/editor/application/map_layer_grouping.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/map_canvas.dart \
  test/features/editor/application/map_layer_grouping_test.dart \
  test/map_canvas_object_selection_test.dart &&
flutter test \
  test/features/editor/application/map_layer_grouping_test.dart \
  test/map_canvas_object_selection_test.dart \
  test/features/editor/application/map_canvas_object_move_planner_test.dart \
  test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart &&
flutter analyze
```

```text
Formatted 6 files (0 changed) in 0.10 seconds.
00:02 +51: All tests passed!
No issues found! (ran in 4.9s)
exit_code=0
```

## 10. Commandes et résultats exacts

Toutes les commandes Flutter ont été exécutées depuis
`packages/map_editor`.

### 10.1 SEL-01 au commit de lot

```bash
dart format lib/src/ui/canvas/map_canvas.dart &&
flutter test \
  test/features/editor/application/map_canvas_object_hit_test_test.dart \
  test/map_canvas_object_selection_test.dart \
  test/border_map_editing/map_canvas_border_selection_test.dart \
  test/entity_editor_element_visual_test.dart \
  test/map_grid_painter_layer_order_test.dart &&
flutter analyze &&
git diff --check -- \
  lib/src/features/editor/application/map_canvas_object_hit_test.dart \
  lib/src/features/editor/application/project_element_frame_resolver.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/entity_editor_element_visual.dart \
  lib/src/ui/canvas/map_canvas.dart \
  lib/src/ui/canvas/map_canvas/map_grid_painter.dart \
  test/features/editor/application/map_canvas_object_hit_test_test.dart \
  test/map_canvas_object_selection_test.dart \
  test/border_map_editing/map_canvas_border_selection_test.dart
```

```text
00:01 +39: All tests passed!
No issues found! (ran in 5.0s)
git diff --check: clean
exit 0
```

### 10.2 MOV-01 au commit de lot

```bash
dart format \
  lib/src/application/services/placed_element_instance_indexer.dart \
  lib/src/features/editor/application/map_canvas_interaction_controller.dart \
  lib/src/features/editor/application/map_canvas_object_move_planner.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/map_canvas.dart \
  test/features/editor/application/map_canvas_interaction_controller_test.dart \
  test/features/editor/application/map_canvas_object_move_planner_test.dart \
  test/map_canvas_object_selection_test.dart \
  test/placed_element_instance_indexer_test.dart &&
flutter test \
  test/map_canvas_object_selection_test.dart \
  test/features/editor/application/map_canvas_object_move_planner_test.dart \
  test/features/editor/application/map_canvas_interaction_controller_test.dart \
  test/placed_element_instance_indexer_test.dart \
  test/features/editor/application/map_canvas_object_hit_test_test.dart \
  test/border_map_editing/map_canvas_border_selection_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/map_canvas_interaction_arbitration_test.dart &&
flutter analyze &&
git diff --check -- \
  lib/src/application/services/placed_element_instance_indexer.dart \
  lib/src/features/editor/application/map_canvas_interaction_controller.dart \
  lib/src/features/editor/application/map_canvas_object_move_planner.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/map_canvas.dart \
  test/features/editor/application/map_canvas_interaction_controller_test.dart \
  test/features/editor/application/map_canvas_object_move_planner_test.dart \
  test/map_canvas_object_selection_test.dart \
  test/placed_element_instance_indexer_test.dart
```

```text
00:02 +89: All tests passed!
No issues found! (ran in 5.4s)
git diff --check: clean
exit 0
```

### 10.3 LAY-01 au commit de lot, ciblé et responsive

```bash
flutter test \
  test/features/editor/application/map_layer_grouping_test.dart \
  test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart \
  test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

```text
33 tests ciblés passés
exit 0
```

```bash
flutter test \
  test/ui/shell/pokemap_map_navigation_responsive_test.dart \
  test/ui/shell/pokemap_inspector_shell_migration_test.dart \
  test/environment_studio/tile_layer_environment_layer_grouping_panel_test.dart
```

```text
00:02 +24: All tests passed!
exit 0
```

### 10.4 Suite complète

Le premier run complet de diagnostic a été interrompu après avoir localisé les
overflows ci-dessus. Deux processus de tests concurrents issus des passes
indépendantes ont ensuite été arrêtés explicitement, puis un unique run frais a
été lancé :

```bash
set -o pipefail
flutter test --reporter expanded 2>&1 |
  awk '/All tests passed!|Some tests failed!|\[E\]|TestFailure|The test description was:|EXCEPTION CAUGHT|Expected:|Actual:|Which:|unhandled error/{print; fflush()}'
```

```text
04:39 +4627 ~6: All tests passed!
exit 0
```

### 10.5 Analyse finale

```bash
flutter analyze
```

```text
Analyzing map_editor...
No issues found! (ran in 5.1s)
exit 0
```

### 10.6 Build final

```bash
flutter build macos --debug
```

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/PokeMap.app
exit 0
```

## 11. Commits par lot

```text
ce8e06a41 feat(map-editor): unify canvas object selection
6d6bbbe46 feat(map-editor): add transactional object dragging
63cd18ba8 feat(map-editor): reorder layer groups atomically
3d0aac55f fix(map-editor): harden Gate 3 safeguards
```

Le plan local n'a pas été forcé dans Git. Chaque lot produit possède un commit
isolé ; le quatrième commit est le correctif transversal imposé par la critique
finale. Le présent Evidence Pack reçoit un commit de clôture séparé.

## 12. État Git de clôture

Après le commit correctif et avant le commit du rapport :

```text
branch=main
HEAD=3d0aac55f
origin/main=7fb9e9d52
ahead=4
status_count_total=63
status_count_preexistant=62
status_count_gate_3_non_commité=1
```

L'unique entrée Gate 3 hors commit est :

```text
?? reports/ui/world_map_editor_gate_3_direct_manipulation_2026-07-29.md
```

Les 62 entrées préexistantes de la section 4 restent présentes et non staged.
La vérification post-commit et post-push est consignée dans le retour de
clôture ; elle ne peut pas être inscrite récursivement dans le commit qu'elle
vérifie.

## 13. Auto-critique, limites et risques restants

### 13.1 Auto-critique

- `EditorNotifier` et `MapCanvas` restent volumineux. Gate 3 ajoute des seams
  purs, mais ne prétend pas avoir résolu cette dette structurelle.
- La matrice widget est volontairement focalisée sur les risques Gate 3. Les
  six familles ont une preuve pure exhaustive, tandis que les parcours widget
  couvrent un ensemble représentatif et les branches fragiles.
- La tolérance de validation LAY-01 autorise le reorder d'une map déjà invalide.
  Elle est bornée par un invariant préalable de longueur et d'identité : le
  service refuse une duplication, une perte ou un remplacement d'instance.
  Cette tolérance ne doit pas être copiée vers une mutation de contenu.
- La preview est un ghost géométrique, pas un rendu bitmap complet de l'objet.
  Elle montre néanmoins empreinte, validité, destination et cause du rejet.

### 13.2 Risques non bloquants

- pour un placement `tile_index`, chaque changement de cellule pendant le drag
  exécute encore deux `syncLayer` complets. Ils rescannent la grille et les
  candidats ; aucun benchmark grande carte ne borne encore ce coût. Le prochain
  durcissement devra mettre en cache la validation source ou réserver la double
  synchronisation au commit ;
- un élément dont le manifest et les frames existent mais dont l'image ou le
  tileset ne peut pas être résolu peut encore intercepter le hit-test avant un
  objet effectivement peint ;
- la politique foreground/collision reste dupliquée entre hit-test et painter,
  même si les tests prouvent leur parité sur les cas Gate 3 ;
- en mode `v2Only`, un ancien Event peut afficher un ghost avant que le commit
  soit explicitement rejeté au relâchement ;
- seul le Border du layer actif reste géré par le contrôleur spécialisé ;
- un ancien Event reste volontairement immobile en mode `v2Only` ;
- un drop de groupe sur lui-même affiche un hover avant le no-op ;
- le focus disabled de `PokeMapIconButton` est une dette transverse ;
- Magic Mouse physique et VoiceOver réel n'ont pas été certifiés ;
- aucune multisélection, duplication, suppression ou nudging clavier n'est
  livré par Gate 3.

### 13.3 Prochaine étape proposée

Passer à **Gate 4 — contexte de palette/asset browser par calque** :

- mémoire A→B→A ;
- assets assignables seulement ;
- taxonomie et filtres utiles ;
- recherche, dossiers, récents et favoris ;
- incompatibilités expliquées.

Cette étape est proposée, pas implémentée dans Gate 3.

## 14. Contenu intégral des fichiers créés

Les huit contenus Dart ci-dessous correspondent exactement à `3d0aac55f`. Le
plan 14.1 est un fichier local ignoré par Git, identifié par sa propre
empreinte. Les hashes permettent de vérifier qu'aucune troncature n'a été
introduite.

### 14.1 Plan local ignoré par Git

SHA-256 :
`441a01132c58582082fc0f943ab1f96f191aede1e80150a005da5bec3a8946b8`

```markdown
# Gate 3 — Direct manipulation implementation plan

Date: 2026-07-29

## Goal

Make the world-map canvas select and move authored objects predictably, then make
the visible layer list reorder the same groups that it presents.

Gate 3 contains exactly three independently committable lots:

1. `SEL-01 — Hit-test commun`
2. `MOV-01 — Déplacement transactionnel`
3. `LAY-01 — Groupes de calques visibles`

## Shared acceptance contract

- Clicking empty canvas space does not mutate the map.
- Clicking an object selects it.
- Overlapping objects resolve to the deterministic topmost visible target.
- A drag shows a ghost without mutating the map.
- Pointer-up commits one transaction.
- An invalid destination does not commit.
- Identity and every non-position property are preserved.
- Escape rolls the gesture back.
- Undo and redo each require one step.
- Generated Environment placements cannot be moved independently from their
  owning Environment area.

## Scope decisions

- “All object families” means placed elements, entities, map events, warps,
  triggers, and gameplay zones. Border selection keeps its specialized
  controller.
- Selection is single-target. A repeated click at the same grid position cycles
  through the deterministic hit stack.
- Cells from Tile, Terrain, Collision, Path, and Surface layers are not direct
  object-selection targets.
- Connections, duplication, deletion, keyboard nudging, multi-selection, and
  Gate 4 palette work are out of scope.
- No schema change is planned.

## Lot SEL-01 — Common canvas hit test

### Production work

- Add a pure canvas-object target and hit-stack service under
  `packages/map_editor/lib/src/features/editor/application/`.
- Build the stack from the Gate 1 visual composition contract, layer visibility,
  painter family order, authored element footprints, and list paint order.
- Add one notifier entry point that applies a target as an exclusive selection
  while preserving the existing inspector-specific selection IDs.
- Connect Selection-tool primary clicks in `MapCanvas` to that service.
- Keep Border hit testing ahead of the generic path only when the specialized
  Border controller owns the active layer.

### Tests

- Pure tests: every family, hidden layer exclusion, element footprints,
  topmost order, deterministic overlap order, repeated-click cycling.
- Widget integration: canvas click selects the resolved object and empty click
  causes no map/history mutation.

### Commit

`feat(map-editor): unify canvas object selection`

## Lot MOV-01 — Transactional object movement

### Production work

- Add a pure move planner that:
  - resolves a target's current bounds and anchor;
  - produces a preview candidate without changing `MapData`;
  - rejects out-of-bounds destinations;
  - protects Environment-generated placed elements;
  - returns a map that changes position only.
- Extend the Gate 2 interaction arbiter with one exclusive object-move gesture.
- Add transient ghost state in `MapCanvas`; begin only after drag threshold.
- On pointer-up, pass the candidate through the existing map mutation/history
  coordinator exactly once.
- On Escape, pointer cancellation, lost buttons, context drift, or invalid
  destination, clear the ghost and leave the map/history untouched.

### Tests

- Pure tests for all six movable families, invalid bounds, property preservation,
  no-op destinations, and generated Environment protection.
- Arbiter tests for exclusive ownership and idempotent terminal events.
- Widget/notifier integration for ghost-before-commit, pointer-up commit,
  Escape rollback, and one-step undo/redo.

### Commit

`feat(map-editor): move map objects transactionally`

## Lot LAY-01 — Visible layer groups

### Production work

- Extend the existing layer presentation model into an explicit ordered group:
  one visible row owns its Tile layer and every valid attached Environment
  layer; orphan/invalid Environment layers remain independent warning rows.
- Add a pure group reorder service that maps visible row moves to serialized
  `MapData.layers` order without splitting a group.
- Route drag, Move up, and Move down through visible-group indices.
- Make movement availability derive from row position, not raw serialized layer
  indices.
- Preserve the active technical Environment selection when its Tile group moves.

### Tests

- Pure presentation/reorder tests for single/multiple attachments, interleaved
  serialized input, orphan Environment layers, first/last controls, drag before
  and after, and stable member order.
- Widget test that the visible list exposes one grouped row and dispatches
  group-consistent commands.

### Commit

`feat(map-editor): group visible map layers`

## Verification and closure

After each lot:

- format only touched Dart files;
- run the focused tests for the lot;
- run `flutter analyze` from `packages/map_editor`;
- run an independent spec review and code-quality review;
- stage only the lot's exact files and commit.

After all lots:

- run the full `flutter test` and `flutter analyze` suites in
  `packages/map_editor`;
- build the macOS editor;
- run the existing world-map interaction regression tests;
- write
  `reports/ui/world_map_editor_gate_3_direct_manipulation_2026-07-29.md`
  following `codex_rule.md`;
- commit the Evidence Pack separately;
- verify `origin/main` has not diverged;
- push `main` once, without force.
```

### 14.2 `map_canvas_object_hit_test.dart`

SHA-256 :
`034a9ad38c619757f35bc1bb7cb2c29ac71d5429fa6e45ecffaeda1f599e07d2`

```dart
import 'package:map_core/map_core.dart';

import 'project_element_frame_resolver.dart';

/// Object families that can be selected directly from the world-map canvas.
enum MapCanvasObjectKind {
  placedElement,
  entity,
  mapEvent,
  gameplayZone,
  trigger,
  warp,
}

/// Stable identity and grid bounds of one authorable canvas object.
final class MapCanvasObjectTarget {
  const MapCanvasObjectTarget({
    required this.kind,
    required this.id,
    required this.anchor,
    required this.size,
    this.layerId,
  });

  final MapCanvasObjectKind kind;
  final String id;
  final String? layerId;
  final GridPos anchor;
  final GridSize size;

  @override
  bool operator ==(Object other) {
    return other is MapCanvasObjectTarget &&
        other.kind == kind &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Resolves object hits in the same bottom-to-top phases as [MapGridPainter].
///
/// The result is topmost-first. Layer order and visibility come from the shared
/// visual-composition plan; editor-only overlays keep the painter's explicit
/// order (zone, event, trigger, then warp).
final class MapCanvasObjectHitTest {
  const MapCanvasObjectHitTest();

  List<MapCanvasObjectTarget> hitStack({
    required MapData map,
    required ProjectManifest? project,
    required GridPos position,
    int editorAnimationTimeMs = 0,
  }) {
    if (!_containsCell(
      position,
      const GridPos(x: 0, y: 0),
      map.size,
    )) {
      return const <MapCanvasObjectTarget>[];
    }

    final plan = buildMapVisualCompositionPlan(map).plan;
    if (plan == null) {
      return const <MapCanvasObjectTarget>[];
    }

    final painted = <MapCanvasObjectTarget>[];
    final elementsById = project == null
        ? const <String, ProjectElementEntry>{}
        : <String, ProjectElementEntry>{
            for (final entry in project.elements) entry.id: entry,
          };

    for (final step in plan.steps) {
      switch (step.kind) {
        case MapVisualCompositionStepKind.placedElements:
          _appendPlacedElementHits(
            painted,
            map: map,
            layer: step.layer! as TileLayer,
            elementsById: elementsById,
            position: position,
            foregroundPass: false,
            editorAnimationTimeMs: editorAnimationTimeMs,
          );
        case MapVisualCompositionStepKind.backgroundEntities:
          _appendEntityHits(
            painted,
            map: map,
            position: position,
            foregroundPass: false,
          );
        case MapVisualCompositionStepKind.foregroundTilesAndPlacedElements:
          for (final layer in plan.visibleTileLayersInPaintOrder) {
            _appendPlacedElementHits(
              painted,
              map: map,
              layer: layer,
              elementsById: elementsById,
              position: position,
              foregroundPass: true,
              editorAnimationTimeMs: editorAnimationTimeMs,
            );
          }
        case MapVisualCompositionStepKind.foregroundEntities:
          _appendEntityHits(
            painted,
            map: map,
            position: position,
            foregroundPass: true,
          );
        case MapVisualCompositionStepKind.terrainLayer:
        case MapVisualCompositionStepKind.pathLayer:
        case MapVisualCompositionStepKind.surfaceLayer:
        case MapVisualCompositionStepKind.tileBackgroundLayer:
        case MapVisualCompositionStepKind.borderLayer:
        case MapVisualCompositionStepKind.shadows:
        case MapVisualCompositionStepKind.collisionOverlay:
        case MapVisualCompositionStepKind.objectNoop:
        case MapVisualCompositionStepKind.environmentNoop:
          break;
      }
    }

    _appendGameplayZoneHits(painted, map: map, position: position);
    _appendMapEventHits(painted, map: map, position: position);
    _appendTriggerHits(painted, map: map, position: position);
    _appendWarpHits(painted, map: map, position: position);

    return painted.reversed.toList(growable: false);
  }

  MapCanvasObjectTarget? cycleTarget({
    required List<MapCanvasObjectTarget> hits,
    required MapCanvasObjectTarget? current,
  }) {
    if (hits.isEmpty) {
      return null;
    }
    if (current == null) {
      return hits.first;
    }
    final index = hits.indexOf(current);
    if (index < 0) {
      return hits.first;
    }
    return hits[(index + 1) % hits.length];
  }

  void _appendPlacedElementHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required TileLayer layer,
    required Map<String, ProjectElementEntry> elementsById,
    required GridPos position,
    required bool foregroundPass,
    required int editorAnimationTimeMs,
  }) {
    if (layer.opacity <= 0) {
      return;
    }
    final explicitForeground = _isExplicitForegroundLayer(layer);
    for (final instance in map.placedElements) {
      if (instance.layerId.trim() != layer.id.trim() || instance.opacity <= 0) {
        continue;
      }
      final entry = elementsById[instance.elementId.trim()];
      if (entry == null || entry.frames.isEmpty) {
        continue;
      }
      final source =
          pickProjectElementFrame(entry.frames, editorAnimationTimeMs).source;
      final size = GridSize(
        width: source.width <= 0 ? 1 : source.width,
        height: source.height <= 0 ? 1 : source.height,
      );
      if (!_containsCell(position, instance.pos, size)) {
        continue;
      }
      final localX = position.x - instance.pos.x;
      final localY = position.y - instance.pos.y;
      if (!_isPlacedCellInPass(
        instance: instance,
        entry: entry,
        localX: localX,
        localY: localY,
        explicitForeground: explicitForeground,
        foregroundPass: foregroundPass,
      )) {
        continue;
      }
      out.add(
        MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.placedElement,
          id: instance.id,
          layerId: layer.id,
          anchor: instance.pos,
          size: size,
        ),
      );
    }
  }

  void _appendEntityHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
    required bool foregroundPass,
  }) {
    for (final entity in map.entities) {
      if (entity.shouldRenderProjectElementInForeground != foregroundPass ||
          !_containsCell(position, entity.pos, entity.size)) {
        continue;
      }
      out.add(
        MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.entity,
          id: entity.id,
          anchor: entity.pos,
          size: entity.size,
        ),
      );
    }
  }

  void _appendGameplayZoneHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    for (final zone in map.gameplayZones) {
      if (!_containsCell(position, zone.area.pos, zone.area.size)) {
        continue;
      }
      out.add(
        MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.gameplayZone,
          id: zone.id,
          anchor: zone.area.pos,
          size: zone.area.size,
        ),
      );
    }
  }

  void _appendMapEventHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    final layerVisibility = <String, bool>{
      for (final layer in map.layers) layer.id: layer.isVisible,
    };
    for (final event in map.events) {
      final layerId = event.position.layerId.trim();
      if (layerVisibility[layerId] != true ||
          event.position.x != position.x ||
          event.position.y != position.y) {
        continue;
      }
      out.add(
        MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.mapEvent,
          id: event.id,
          layerId: layerId.isEmpty ? null : layerId,
          anchor: GridPos(x: event.position.x, y: event.position.y),
          size: const GridSize(width: 1, height: 1),
        ),
      );
    }
  }

  void _appendTriggerHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    for (final trigger in map.triggers) {
      if (!_containsCell(position, trigger.area.pos, trigger.area.size)) {
        continue;
      }
      out.add(
        MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.trigger,
          id: trigger.id,
          anchor: trigger.area.pos,
          size: trigger.area.size,
        ),
      );
    }
  }

  void _appendWarpHits(
    List<MapCanvasObjectTarget> out, {
    required MapData map,
    required GridPos position,
  }) {
    for (final warp in map.warps) {
      if (warp.pos != position) {
        continue;
      }
      out.add(
        MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.warp,
          id: warp.id,
          anchor: warp.pos,
          size: const GridSize(width: 1, height: 1),
        ),
      );
    }
  }

  bool _isPlacedCellInPass({
    required MapPlacedElement instance,
    required ProjectElementEntry entry,
    required int localX,
    required int localY,
    required bool explicitForeground,
    required bool foregroundPass,
  }) {
    if (explicitForeground) {
      return foregroundPass;
    }
    final collisionCells =
        instance.applyCollision ? entry.collisionProfile?.cells : null;
    if (collisionCells == null || collisionCells.isEmpty) {
      return !foregroundPass;
    }
    final isCollisionCell = collisionCells.any(
      (cell) => cell.x == localX && cell.y == localY,
    );
    return foregroundPass ? !isCollisionCell : isCollisionCell;
  }

  bool _isExplicitForegroundLayer(TileLayer layer) {
    final id = layer.id.trim().toLowerCase();
    final name = layer.name.trim().toLowerCase();
    const markers = <String>{
      'foreground',
      'fg',
      'above',
      'overlay',
      'front',
      'roof',
      'toit',
      'overhead',
      'occlusion',
    };
    return markers.any(
      (marker) =>
          _containsLayerMarker(id, marker) ||
          _containsLayerMarker(name, marker),
    );
  }

  bool _containsLayerMarker(String value, String marker) {
    return value == marker ||
        value.startsWith('${marker}_') ||
        value.endsWith('_$marker') ||
        value.contains('_${marker}_');
  }

  bool _containsCell(GridPos cell, GridPos anchor, GridSize size) {
    return cell.x >= anchor.x &&
        cell.y >= anchor.y &&
        cell.x < anchor.x + size.width &&
        cell.y < anchor.y + size.height;
  }
}
```

### 14.3 `project_element_frame_resolver.dart`

SHA-256 :
`37ee130d1bf3c61b112885f21b5324b4cad953fd742d73ad15d95db6ce13775d`

```dart
import 'package:map_core/map_core.dart';

const int kProjectElementFrameDurationFallbackMs = 200;

int projectElementFrameDurationMs(TilesetVisualFrame frame) {
  final duration = frame.durationMs;
  if (duration == null || duration <= 0) {
    return kProjectElementFrameDurationFallbackMs;
  }
  return duration;
}

TilesetVisualFrame pickProjectElementFrame(
  List<TilesetVisualFrame> frames,
  int elapsedMs,
) {
  if (frames.isEmpty) {
    throw StateError('ProjectElementEntry.frames must not be empty');
  }
  if (frames.length == 1) {
    return frames.first;
  }
  var total = 0;
  for (final frame in frames) {
    total += projectElementFrameDurationMs(frame);
  }
  if (total <= 0) {
    return frames.first;
  }
  var remaining = elapsedMs % total;
  if (remaining < 0) {
    remaining = (remaining % total + total) % total;
  }
  for (final frame in frames) {
    final duration = projectElementFrameDurationMs(frame);
    if (remaining < duration) {
      return frame;
    }
    remaining -= duration;
  }
  return frames.last;
}
```

### 14.4 `map_canvas_object_hit_test_test.dart`

SHA-256 :
`2a78a6bc73a1b2248a93d4ee3e3f4784207529eb9893f714d13bba31700d12ed`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';

void main() {
  const hitTest = MapCanvasObjectHitTest();
  const overlap = GridPos(x: 2, y: 2);

  group('MapCanvasObjectHitTest', () {
    test('returns all object families in painter topmost-first order', () {
      final hits = hitTest.hitStack(
        map: _mapWithEveryFamily,
        project: _project,
        position: overlap,
      );

      expect(
        hits.map((target) => target.kind),
        <MapCanvasObjectKind>[
          MapCanvasObjectKind.warp,
          MapCanvasObjectKind.trigger,
          MapCanvasObjectKind.mapEvent,
          MapCanvasObjectKind.gameplayZone,
          MapCanvasObjectKind.entity,
          MapCanvasObjectKind.placedElement,
        ],
      );
    });

    test('uses canonical layer order and later list entries', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'top-first',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
          MapPlacedElement(
            id: 'bottom',
            layerId: 'bottom',
            elementId: 'element-2x2',
            pos: overlap,
          ),
          MapPlacedElement(
            id: 'top-last',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
        ],
      );

      final hits = hitTest.hitStack(
        map: map,
        project: _project,
        position: overlap,
      );

      expect(
        hits.map((target) => target.id),
        <String>['top-last', 'top-first', 'bottom'],
      );
    });

    test('excludes objects attached to hidden layers', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'hidden-placement',
            layerId: 'hidden',
            elementId: 'element-2x2',
            pos: overlap,
          ),
        ],
        events: const <MapEventDefinition>[
          MapEventDefinition(
            id: 'hidden-event',
            pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
            position: EventPosition(layerId: 'hidden', x: 2, y: 2),
          ),
          MapEventDefinition(
            id: 'missing-layer-event',
            pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
            position: EventPosition(layerId: 'missing', x: 2, y: 2),
          ),
        ],
      );

      expect(
        hitTest.hitStack(map: map, project: _project, position: overlap),
        isEmpty,
      );
    });

    test('uses the authored element footprint and ignores missing assets', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'large',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
          MapPlacedElement(
            id: 'missing',
            layerId: 'top',
            elementId: 'unknown',
            pos: overlap,
          ),
        ],
      );

      final inside = hitTest.hitStack(
        map: map,
        project: _project,
        position: const GridPos(x: 3, y: 3),
      );
      final outside = hitTest.hitStack(
        map: map,
        project: _project,
        position: const GridPos(x: 4, y: 3),
      );

      expect(inside.map((target) => target.id), <String>['large']);
      expect(inside.single.size, const GridSize(width: 2, height: 2));
      expect(outside, isEmpty);
    });

    test('uses the currently painted animation frame footprint', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'animated',
            layerId: 'top',
            elementId: 'animated-element',
            pos: overlap,
          ),
        ],
      );

      expect(
        hitTest.hitStack(
          map: map,
          project: _project,
          position: const GridPos(x: 3, y: 2),
          editorAnimationTimeMs: 0,
        ),
        isEmpty,
      );
      expect(
        hitTest
            .hitStack(
              map: map,
              project: _project,
              position: const GridPos(x: 3, y: 2),
              editorAnimationTimeMs: 100,
            )
            .single
            .id,
        'animated',
      );
    });

    test('respects background and foreground object passes', () {
      final map = _baseMap.copyWith(
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'background-placement',
            layerId: 'top',
            elementId: 'element-2x2',
            pos: overlap,
          ),
        ],
        entities: const <MapEntity>[
          MapEntity(
            id: 'background-entity',
            kind: MapEntityKind.custom,
            pos: overlap,
          ),
          MapEntity(
            id: 'foreground-entity',
            kind: MapEntityKind.custom,
            pos: overlap,
            editorVisual: MapEntityEditorVisual(
              elementId: 'element-2x2',
              renderInForeground: true,
            ),
          ),
        ],
      );

      expect(
        hitTest
            .hitStack(map: map, project: _project, position: overlap)
            .map((target) => target.id),
        <String>[
          'foreground-entity',
          'background-entity',
          'background-placement',
        ],
      );
    });

    test('cycles deterministically and restarts when current is absent', () {
      const first = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.warp,
        id: 'warp',
        anchor: overlap,
        size: GridSize(width: 1, height: 1),
      );
      const second = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.trigger,
        id: 'trigger',
        anchor: overlap,
        size: GridSize(width: 1, height: 1),
      );
      const absent = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.entity,
        id: 'absent',
        anchor: overlap,
        size: GridSize(width: 1, height: 1),
      );
      const hits = <MapCanvasObjectTarget>[first, second];

      expect(hitTest.cycleTarget(hits: hits, current: null), first);
      expect(hitTest.cycleTarget(hits: hits, current: first), second);
      expect(hitTest.cycleTarget(hits: hits, current: second), first);
      expect(hitTest.cycleTarget(hits: hits, current: absent), first);
      expect(hitTest.cycleTarget(hits: const [], current: first), isNull);
    });

    test('empty and out-of-map positions return no target', () {
      expect(
        hitTest.hitStack(
          map: _baseMap,
          project: _project,
          position: overlap,
        ),
        isEmpty,
      );
      expect(
        hitTest.hitStack(
          map: _mapWithEveryFamily,
          project: _project,
          position: const GridPos(x: -1, y: 2),
        ),
        isEmpty,
      );
    });
  });
}

const _project = ProjectManifest(
  name: 'Hit test',
  version: ProjectVersion.v3,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element-2x2',
      name: 'Element 2x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
        ),
      ],
    ),
    ProjectElementEntry(
      id: 'animated-element',
      name: 'Animated element',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2),
          durationMs: 100,
        ),
      ],
    ),
  ],
);

const _baseMap = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v3,
  visualStack: MapVisualStackConfig.canonicalV1,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(id: 'top', name: 'Top', tilesetId: 'tiles'),
    TileLayer(
      id: 'hidden',
      name: 'Hidden',
      tilesetId: 'tiles',
      isVisible: false,
    ),
    TileLayer(id: 'bottom', name: 'Bottom', tilesetId: 'tiles'),
  ],
);

final _mapWithEveryFamily = _baseMap.copyWith(
  placedElements: const <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed',
      layerId: 'top',
      elementId: 'element-2x2',
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  entities: const <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 2),
    ),
  ],
  events: const <MapEventDefinition>[
    MapEventDefinition(
      id: 'event',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'top', x: 2, y: 2),
    ),
  ],
  gameplayZones: const <MapGameplayZone>[
    MapGameplayZone(
      id: 'zone',
      kind: GameplayZoneKind.special,
      special: SpecialZonePayload(),
      area: MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  triggers: const <MapTrigger>[
    MapTrigger(
      id: 'trigger',
      type: TriggerType.custom,
      area: MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
    ),
  ],
  warps: const <MapWarp>[
    MapWarp(
      id: 'warp',
      pos: GridPos(x: 2, y: 2),
      targetMapId: 'map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);
```

### 14.5 `map_canvas_object_selection_test.dart`

SHA-256 :
`35d3748e93c5cbcc7e09e1094e220da44e918e313d759a091de402e21d36d926`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
    'Selection tool cycles canvas objects exclusively without map mutation',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(
        editorNotifierProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
        selectedEntityId: 'stale-entity',
        selectedMapEventId: 'stale-event',
        selectedTriggerId: 'stale-trigger',
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final overlap = canvas.topLeft + const Offset(144, 144);

      await tester.tapAt(overlap);
      await tester.pump();

      var state = container.read(editorNotifierProvider);
      expect(state.selectedWarpId, 'warp');
      expect(state.selectedTriggerId, isNull);
      expect(state.selectedMapEventId, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.bySemanticsLabel(
          RegExp('Téléporteur warp sélectionné, x 4, y 4'),
        ),
        findsOneWidget,
      );

      await tester.tapAt(overlap);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.selectedWarpId, isNull);
      expect(state.selectedTriggerId, 'trigger');
      expect(state.selectedMapEventId, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);

      final adjacentOverlap = canvas.topLeft + const Offset(176, 144);
      await tester.tapAt(adjacentOverlap);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(
        state.selectedTriggerId,
        'trigger',
        reason: 'a new hit stack must restart from its topmost target',
      );
      expect(state.selectedMapEventId, isNull);

      await tester.tapAt(adjacentOverlap);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.selectedTriggerId, isNull);
      expect(state.selectedMapEventId, 'event-next');

      await tester.tapAt(canvas.topLeft + const Offset(208, 208));
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.selectedWarpId, isNull);
      expect(state.selectedTriggerId, isNull);
      expect(state.selectedMapEventId, isNull);
      expect(state.selectedEntityId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
    },
  );

  testWidgets(
    'selection drag previews without mutation then commits one undoable move',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(64, 32));
      await tester.pump();

      var state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(
        state.activeMap!.warps.single.pos,
        const GridPos(x: 6, y: 5),
        reason: 'status=${state.statusMessage}; error=${state.errorMessage}; '
            'undo=${state.mapUndoStack.length}',
      );
      expect(state.selectedWarpId, 'warp');
      expect(state.mapUndoStack, hasLength(1));
      expect(state.mapRedoStack, isEmpty);
      expect(state.isDirty, isTrue);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsNothing,
      );

      container.read(editorNotifierProvider.notifier).undoMap();
      state = container.read(editorNotifierProvider);
      expect(state.activeMap, _map);
      expect(state.selectedWarpId, 'warp');
      expect(state.mapUndoStack, isEmpty);
      expect(state.mapRedoStack, hasLength(1));

      container.read(editorNotifierProvider.notifier).redoMap();
      state = container.read(editorNotifierProvider);
      expect(state.activeMap!.warps.single.pos, const GridPos(x: 6, y: 5));
      expect(state.selectedWarpId, 'warp');
      expect(state.mapUndoStack, hasLength(1));
      expect(state.mapRedoStack, isEmpty);
    },
  );

  testWidgets(
    'selection drag keeps the selected overlap target and Escape rolls back',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
        selectedTriggerId: 'trigger',
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(32, 64));
      await tester.pump();

      var state = container.read(editorNotifierProvider);
      expect(state.selectedTriggerId, 'trigger');
      expect(state.selectedWarpId, isNull);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.selectedTriggerId, 'trigger');
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsNothing,
      );
      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'invalid selection destination never commits or creates history',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(-192, 0));
      await tester.pump();
      expect(
        find.bySemanticsLabel(
          RegExp('Déplacement.*impossible.*destination dépasse la carte'),
        ),
        findsOneWidget,
      );
      await gesture.up();
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.mapRedoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(state.errorMessage, contains('destination dépasse la carte'));
    },
  );

  testWidgets(
    'selection drag cancels when its map interaction context changes',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: _project,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _map,
        activeLayerId: 'objects',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _map,
      );
      final beforeJson = _map.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(144, 144),
      );
      await gesture.moveBy(const Offset(32, 0));
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsOneWidget,
      );

      final current = container.read(editorNotifierProvider);
      container.read(editorNotifierProvider.notifier).state = current.copyWith(
        activeTool: EditorToolType.eraser,
      );
      await gesture.moveBy(const Offset(32, 0));
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(
        find.byKey(
          const ValueKey<String>('map-canvas-object-move-preview'),
        ),
        findsNothing,
      );
      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'Environment generated placement stays protected with explicit feedback',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(subscription.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _environmentProject,
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: _environmentMap,
        activeLayerId: 'decor',
        activeTool: EditorToolType.selection,
        savedMapSnapshot: _environmentMap,
      );
      final beforeJson = _environmentMap.toJson();

      await _pumpCanvas(tester, container);
      final canvas = tester.getRect(find.byType(MapCanvas));
      final gesture = await tester.startGesture(
        canvas.topLeft + const Offset(80, 80),
      );
      await gesture.moveBy(const Offset(32, 0));
      await tester.pump();

      expect(
        find.bySemanticsLabel(
          RegExp('Déplacement.*impossible.*zone Environment'),
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      final state = container.read(editorNotifierProvider);
      expect(state.activeMap!.toJson(), beforeJson);
      expect(state.selectedPlacedElementInstanceId, 'generated');
      expect(state.mapUndoStack, isEmpty);
      expect(state.isDirty, isFalse);
      expect(state.errorMessage, contains('généré par une zone Environment'));
    },
  );

  test('direct move commit rejects a stale source map snapshot', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final changedMap = _map.copyWith(name: 'Map changed during drag');
    notifier.state = EditorState(
      project: _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: changedMap,
      activeLayerId: 'objects',
      activeTool: EditorToolType.selection,
      savedMapSnapshot: _map,
    );

    final committed = notifier.commitCanvasObjectMove(
      sourceMap: _map,
      target: const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.warp,
        id: 'warp',
        anchor: GridPos(x: 4, y: 4),
        size: GridSize(width: 1, height: 1),
      ),
      destinationAnchor: const GridPos(x: 5, y: 5),
    );

    expect(committed, isFalse);
    expect(notifier.state.activeMap, same(changedMap));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('carte a changé'));
  });

  test('direct MapEvent move stays blocked in v2Only mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      project: _project.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: const <NarrativeEventRecord>[],
          legacyClaims: const <LegacySourceClaim>[],
        ),
      ),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'objects',
      activeTool: EditorToolType.selection,
      savedMapSnapshot: _map,
    );

    final committed = notifier.commitCanvasObjectMove(
      sourceMap: _map,
      target: const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.mapEvent,
        id: 'event',
        layerId: 'objects',
        anchor: GridPos(x: 4, y: 4),
        size: GridSize(width: 1, height: 1),
      ),
      destinationAnchor: const GridPos(x: 5, y: 5),
    );

    expect(committed, isFalse);
    expect(notifier.state.activeMap, same(_map));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('Event Builder V2'));
  });

  test('linked Entity and Trigger moves request event revalidation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final project = _project.copyWith(
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
      eventRegistry: _linkedSourceRegistry,
    );
    notifier.state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'objects',
      activeTool: EditorToolType.selection,
      savedMapSnapshot: _map,
    );

    final entityCommitted = notifier.commitCanvasObjectMove(
      sourceMap: _map,
      target: const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.entity,
        id: 'entity',
        anchor: GridPos(x: 4, y: 4),
        size: GridSize(width: 1, height: 1),
      ),
      destinationAnchor: const GridPos(x: 5, y: 5),
    );

    expect(entityCommitted, isTrue);
    expect(notifier.state.activeMap!.entities.single.pos,
        const GridPos(x: 5, y: 5));
    expect(notifier.state.statusMessage, contains(_linkedEntityEventId));

    notifier.state = EditorState(
      project: project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'objects',
      activeTool: EditorToolType.selection,
      savedMapSnapshot: _map,
    );
    final triggerCommitted = notifier.commitCanvasObjectMove(
      sourceMap: _map,
      target: const MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.trigger,
        id: 'trigger',
        anchor: GridPos(x: 4, y: 4),
        size: GridSize(width: 2, height: 1),
      ),
      destinationAnchor: const GridPos(x: 5, y: 5),
    );

    expect(triggerCommitted, isTrue);
    expect(
      notifier.state.activeMap!.triggers.single.area.pos,
      const GridPos(x: 5, y: 5),
    );
    expect(notifier.state.statusMessage, contains(_linkedTriggerEventId));
  });
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: const MaterialApp(
          home: CupertinoPageScaffold(
            child: SizedBox.expand(child: MapCanvas()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const _project = ProjectManifest(
  version: ProjectVersion.v3,
  name: 'Canvas object selection',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _linkedEntityEventId = 'evt_019abcde-0000-7000-8000-000000000401';
const _linkedTriggerEventId = 'evt_019abcde-0000-7000-8000-000000000402';

final _linkedSourceRegistry = NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.dualRead,
  records: <NarrativeEventRecord>[
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: _linkedEntityEventId,
        name: 'Linked entity event',
        source: NarrativeEventSourceRef.entityInteract('map', 'entity'),
        conditions: const <NarrativeEventCondition>[],
        priority: 0,
        order: 0,
      ),
    ),
    NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: _linkedTriggerEventId,
        name: 'Linked trigger event',
        source: NarrativeEventSourceRef.triggerEnter('map', 'trigger'),
        conditions: const <NarrativeEventCondition>[],
        priority: 0,
        order: 1,
      ),
    ),
  ],
  legacyClaims: const <LegacySourceClaim>[],
);

const _map = MapData(
  version: ProjectVersion.v3,
  id: 'map',
  name: 'Map',
  visualStack: MapVisualStackConfig.canonicalV1,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    ObjectLayer(id: 'objects', name: 'Objects'),
  ],
  entities: <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 4, y: 4),
    ),
  ],
  events: <MapEventDefinition>[
    MapEventDefinition(
      id: 'event',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'objects', x: 4, y: 4),
    ),
    MapEventDefinition(
      id: 'event-next',
      pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
      position: EventPosition(layerId: 'objects', x: 5, y: 4),
    ),
  ],
  triggers: <MapTrigger>[
    MapTrigger(
      id: 'trigger',
      type: TriggerType.custom,
      area: MapRect(
        pos: GridPos(x: 4, y: 4),
        size: GridSize(width: 2, height: 1),
      ),
    ),
  ],
  warps: <MapWarp>[
    MapWarp(
      id: 'warp',
      pos: GridPos(x: 4, y: 4),
      targetMapId: 'map',
      targetPos: GridPos(x: 0, y: 0),
    ),
  ],
);

const _environmentProject = ProjectManifest(
  version: ProjectVersion.v3,
  name: 'Environment generated selection',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

final _environmentMap = MapData(
  version: ProjectVersion.v3,
  id: 'environment-map',
  name: 'Environment map',
  visualStack: MapVisualStackConfig.canonicalV1,
  size: const GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    const TileLayer(id: 'decor', name: 'Decor'),
    EnvironmentLayer(
      id: 'environment',
      name: 'Environment',
      content: EnvironmentLayerContent(
        targetTileLayerId: 'decor',
        areas: <EnvironmentArea>[
          EnvironmentArea(
            id: 'forest',
            name: 'Forest',
            presetId: 'forest',
            mask: EnvironmentAreaMask(
              width: 8,
              height: 8,
              cells: List<bool>.filled(64, true),
            ),
            seed: 1,
            generatedPlacementIds: <String>['generated'],
          ),
        ],
      ),
    ),
  ],
  placedElements: <MapPlacedElement>[
    const MapPlacedElement(
      id: 'generated',
      layerId: 'decor',
      elementId: 'tree',
      pos: GridPos(x: 2, y: 2),
      properties: <String, String>{
        'pokemapPlacementOrigin': 'environment',
      },
    ),
  ],
);
```

### 14.6 `map_canvas_object_move_planner.dart`

SHA-256 :
`7cbc568067693cd88ab1301ad4e0787f49214a9d1ebc9ef7d25994066665926d`

```dart
import 'package:map_core/map_core.dart';

import '../../../application/services/placed_element_instance_indexer.dart';
import 'map_canvas_object_hit_test.dart';

enum MapCanvasObjectMoveRejection {
  targetNotFound,
  boundsUnavailable,
  sourceOutOfBounds,
  destinationOutOfBounds,
  environmentGeneratedPlacement,
  tileIndexedSourceInvalid,
  tileIndexedDestinationOccupied,
  tileIndexedProjectionInvalid,
}

final class MapCanvasObjectMovePlan {
  const MapCanvasObjectMovePlan._({
    required this.sourceMap,
    required this.sourceTarget,
    required this.previewTarget,
    required this.candidateMap,
    required this.isNoOp,
    required this.rejection,
  });

  factory MapCanvasObjectMovePlan.ready({
    required MapData sourceMap,
    required MapCanvasObjectTarget sourceTarget,
    required MapCanvasObjectTarget previewTarget,
    required MapData candidateMap,
  }) {
    return MapCanvasObjectMovePlan._(
      sourceMap: sourceMap,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: candidateMap,
      isNoOp: false,
      rejection: null,
    );
  }

  factory MapCanvasObjectMovePlan.noOp({
    required MapData sourceMap,
    required MapCanvasObjectTarget sourceTarget,
  }) {
    return MapCanvasObjectMovePlan._(
      sourceMap: sourceMap,
      sourceTarget: sourceTarget,
      previewTarget: sourceTarget,
      candidateMap: null,
      isNoOp: true,
      rejection: null,
    );
  }

  factory MapCanvasObjectMovePlan.rejected({
    required MapData sourceMap,
    required MapCanvasObjectMoveRejection rejection,
    MapCanvasObjectTarget? sourceTarget,
    MapCanvasObjectTarget? previewTarget,
  }) {
    return MapCanvasObjectMovePlan._(
      sourceMap: sourceMap,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: null,
      isNoOp: false,
      rejection: rejection,
    );
  }

  final MapData sourceMap;
  final MapCanvasObjectTarget? sourceTarget;
  final MapCanvasObjectTarget? previewTarget;
  final MapData? candidateMap;
  final bool isNoOp;
  final MapCanvasObjectMoveRejection? rejection;

  bool get canCommit => candidateMap != null && !isNoOp && rejection == null;
}

final class MapCanvasObjectMovePlanner {
  const MapCanvasObjectMovePlanner({
    PlacedElementInstanceIndexer indexer = const PlacedElementInstanceIndexer(),
  }) : _indexer = indexer;

  final PlacedElementInstanceIndexer _indexer;

  MapCanvasObjectMovePlan plan({
    required MapData map,
    required ProjectManifest? project,
    required MapCanvasObjectTarget target,
    required GridPos destinationAnchor,
  }) {
    final placed = target.kind == MapCanvasObjectKind.placedElement
        ? _findPlacedElement(map, target.id)
        : null;
    if (placed != null && _isEnvironmentGenerated(map, placed.id)) {
      final moveSize = _placedElementMoveSize(
        project: project,
        placed: placed,
        requested: target,
      );
      final sourceTarget = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.placedElement,
        id: placed.id,
        layerId: placed.layerId,
        anchor: placed.pos,
        size: moveSize ?? const GridSize(width: 1, height: 1),
      );
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: _atAnchor(sourceTarget, destinationAnchor),
        rejection: MapCanvasObjectMoveRejection.environmentGeneratedPlacement,
      );
    }

    final sourceTarget = _resolveTarget(
      map: map,
      project: project,
      requested: target,
    );
    if (sourceTarget == null) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        rejection: placed == null
            ? MapCanvasObjectMoveRejection.targetNotFound
            : MapCanvasObjectMoveRejection.boundsUnavailable,
      );
    }
    final previewTarget = _atAnchor(sourceTarget, destinationAnchor);
    if (!_isInBounds(sourceTarget.anchor, sourceTarget.size, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.sourceOutOfBounds,
      );
    }
    if (!_isInBounds(destinationAnchor, sourceTarget.size, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
    }
    if (destinationAnchor == sourceTarget.anchor) {
      return MapCanvasObjectMovePlan.noOp(
        sourceMap: map,
        sourceTarget: sourceTarget,
      );
    }

    if (placed?.properties[pokemapPlacementOriginProperty] ==
        pokemapPlacementOriginTileIndex) {
      return _planTileIndexedMove(
        map: map,
        project: project!,
        placed: placed!,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        destinationAnchor: destinationAnchor,
      );
    }

    final candidate = _movePositionOnly(
      map: map,
      target: sourceTarget,
      destinationAnchor: destinationAnchor,
    );
    if (candidate == null) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.targetNotFound,
      );
    }
    return MapCanvasObjectMovePlan.ready(
      sourceMap: map,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: candidate,
    );
  }

  MapCanvasObjectMovePlan _planTileIndexedMove({
    required MapData map,
    required ProjectManifest project,
    required MapPlacedElement placed,
    required MapCanvasObjectTarget sourceTarget,
    required MapCanvasObjectTarget previewTarget,
    required GridPos destinationAnchor,
  }) {
    final tilePatternSize = _placedElementSize(project, placed);
    if (tilePatternSize == null ||
        !_isInBounds(placed.pos, tilePatternSize, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
    }
    if (!_isInBounds(destinationAnchor, tilePatternSize, map.size)) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
    }
    final tilePatternTarget = MapCanvasObjectTarget(
      kind: sourceTarget.kind,
      id: sourceTarget.id,
      layerId: sourceTarget.layerId,
      anchor: placed.pos,
      size: tilePatternSize,
    );
    final layerIndex =
        map.layers.indexWhere((entry) => entry.id == placed.layerId);
    if (layerIndex < 0 || map.layers[layerIndex] is! TileLayer) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
    }
    final layer = map.layers[layerIndex] as TileLayer;
    final synchronized = _indexer.syncLayer(
      map: map,
      project: project,
      layerId: layer.id,
    );
    final synchronizedPlaced = _findPlacedElement(synchronized, placed.id);
    if (synchronizedPlaced == null ||
        synchronizedPlaced.layerId != placed.layerId ||
        synchronizedPlaced.elementId != placed.elementId ||
        synchronizedPlaced.pos != placed.pos ||
        synchronizedPlaced.properties[pokemapPlacementOriginProperty] !=
            pokemapPlacementOriginTileIndex) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
    }

    for (var localY = 0; localY < tilePatternSize.height; localY++) {
      for (var localX = 0; localX < tilePatternSize.width; localX++) {
        final destination = GridPos(
          x: destinationAnchor.x + localX,
          y: destinationAnchor.y + localY,
        );
        if (_contains(tilePatternTarget, destination)) continue;
        if (_tileAt(layer.tiles, map.size, destination) != 0) {
          return MapCanvasObjectMovePlan.rejected(
            sourceMap: map,
            sourceTarget: sourceTarget,
            previewTarget: previewTarget,
            rejection:
                MapCanvasObjectMoveRejection.tileIndexedDestinationOccupied,
          );
        }
      }
    }

    final pattern = <int>[
      for (var localY = 0; localY < tilePatternSize.height; localY++)
        for (var localX = 0; localX < tilePatternSize.width; localX++)
          _tileAt(
            layer.tiles,
            map.size,
            GridPos(
              x: placed.pos.x + localX,
              y: placed.pos.y + localY,
            ),
          ),
    ];
    final expectedTileCount = map.size.width * map.size.height;
    final nextTiles = List<int>.filled(expectedTileCount, 0, growable: false);
    final copyCount = layer.tiles.length < expectedTileCount
        ? layer.tiles.length
        : expectedTileCount;
    for (var index = 0; index < copyCount; index++) {
      nextTiles[index] = layer.tiles[index];
    }
    for (var localY = 0; localY < tilePatternSize.height; localY++) {
      for (var localX = 0; localX < tilePatternSize.width; localX++) {
        final x = placed.pos.x + localX;
        final y = placed.pos.y + localY;
        nextTiles[y * map.size.width + x] = 0;
      }
    }
    for (var localY = 0; localY < tilePatternSize.height; localY++) {
      for (var localX = 0; localX < tilePatternSize.width; localX++) {
        final x = destinationAnchor.x + localX;
        final y = destinationAnchor.y + localY;
        final patternIndex = localY * tilePatternSize.width + localX;
        nextTiles[y * map.size.width + x] = pattern[patternIndex];
      }
    }

    final nextLayers = List<MapLayer>.from(map.layers, growable: false);
    nextLayers[layerIndex] = layer.copyWith(tiles: nextTiles);
    final withMovedTiles = map.copyWith(layers: nextLayers);
    final candidate = _movePositionOnly(
      map: withMovedTiles,
      target: sourceTarget,
      destinationAnchor: destinationAnchor,
    );
    if (candidate == null) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.targetNotFound,
      );
    }

    final verified = _indexer.syncLayer(
      map: candidate,
      project: project,
      layerId: layer.id,
    );
    final moved = _findPlacedElement(candidate, placed.id);
    final verifiedMoved = _findPlacedElement(verified, placed.id);
    if (moved == null || verifiedMoved != moved) {
      return MapCanvasObjectMovePlan.rejected(
        sourceMap: map,
        sourceTarget: sourceTarget,
        previewTarget: previewTarget,
        rejection: MapCanvasObjectMoveRejection.tileIndexedProjectionInvalid,
      );
    }
    return MapCanvasObjectMovePlan.ready(
      sourceMap: map,
      sourceTarget: sourceTarget,
      previewTarget: previewTarget,
      candidateMap: candidate,
    );
  }
}

MapCanvasObjectTarget? _resolveTarget({
  required MapData map,
  required ProjectManifest? project,
  required MapCanvasObjectTarget requested,
}) {
  switch (requested.kind) {
    case MapCanvasObjectKind.placedElement:
      final placed = _findPlacedElement(map, requested.id);
      final size = placed == null
          ? null
          : _placedElementMoveSize(
              project: project,
              placed: placed,
              requested: requested,
            );
      if (placed == null || size == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: placed.id,
        layerId: placed.layerId,
        anchor: placed.pos,
        size: size,
      );
    case MapCanvasObjectKind.entity:
      final entity = _findById(map.entities, requested.id, (entry) => entry.id);
      if (entity == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: entity.id,
        anchor: entity.pos,
        size: entity.size,
      );
    case MapCanvasObjectKind.mapEvent:
      final event = _findById(map.events, requested.id, (entry) => entry.id);
      if (event == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: event.id,
        layerId: event.position.layerId,
        anchor: GridPos(x: event.position.x, y: event.position.y),
        size: const GridSize(width: 1, height: 1),
      );
    case MapCanvasObjectKind.gameplayZone:
      final zone =
          _findById(map.gameplayZones, requested.id, (entry) => entry.id);
      if (zone == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: zone.id,
        anchor: zone.area.pos,
        size: zone.area.size,
      );
    case MapCanvasObjectKind.trigger:
      final trigger =
          _findById(map.triggers, requested.id, (entry) => entry.id);
      if (trigger == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: trigger.id,
        anchor: trigger.area.pos,
        size: trigger.area.size,
      );
    case MapCanvasObjectKind.warp:
      final warp = _findById(map.warps, requested.id, (entry) => entry.id);
      if (warp == null) return null;
      return MapCanvasObjectTarget(
        kind: requested.kind,
        id: warp.id,
        anchor: warp.pos,
        size: const GridSize(width: 1, height: 1),
      );
  }
}

MapData? _movePositionOnly({
  required MapData map,
  required MapCanvasObjectTarget target,
  required GridPos destinationAnchor,
}) {
  switch (target.kind) {
    case MapCanvasObjectKind.placedElement:
      final index =
          map.placedElements.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next =
          List<MapPlacedElement>.from(map.placedElements, growable: false);
      next[index] = next[index].copyWith(pos: destinationAnchor);
      return map.copyWith(placedElements: next);
    case MapCanvasObjectKind.entity:
      final index = map.entities.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapEntity>.from(map.entities, growable: false);
      next[index] = next[index].copyWith(pos: destinationAnchor);
      return map.copyWith(entities: next);
    case MapCanvasObjectKind.mapEvent:
      final index = map.events.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapEventDefinition>.from(map.events, growable: false);
      final event = next[index];
      next[index] = event.copyWith(
        position: event.position.copyWith(
          x: destinationAnchor.x,
          y: destinationAnchor.y,
        ),
      );
      return map.copyWith(events: next);
    case MapCanvasObjectKind.gameplayZone:
      final index =
          map.gameplayZones.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next =
          List<MapGameplayZone>.from(map.gameplayZones, growable: false);
      final zone = next[index];
      next[index] = zone.copyWith(
        area: zone.area.copyWith(pos: destinationAnchor),
      );
      return map.copyWith(gameplayZones: next);
    case MapCanvasObjectKind.trigger:
      final index = map.triggers.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapTrigger>.from(map.triggers, growable: false);
      final trigger = next[index];
      next[index] = trigger.copyWith(
        area: trigger.area.copyWith(pos: destinationAnchor),
      );
      return map.copyWith(triggers: next);
    case MapCanvasObjectKind.warp:
      final index = map.warps.indexWhere((entry) => entry.id == target.id);
      if (index < 0) return null;
      final next = List<MapWarp>.from(map.warps, growable: false);
      next[index] = next[index].copyWith(pos: destinationAnchor);
      return map.copyWith(warps: next);
  }
}

MapPlacedElement? _findPlacedElement(MapData map, String id) {
  return _findById(map.placedElements, id, (entry) => entry.id);
}

GridSize? _placedElementSize(
  ProjectManifest? project,
  MapPlacedElement placed,
) {
  if (project == null) return null;
  final element =
      _findById(project.elements, placed.elementId, (entry) => entry.id);
  if (element == null || element.frames.isEmpty) return null;
  final source = element.frames.primarySource;
  return GridSize(
    width: source.width <= 0 ? 1 : source.width,
    height: source.height <= 0 ? 1 : source.height,
  );
}

GridSize? _placedElementMoveSize({
  required ProjectManifest? project,
  required MapPlacedElement placed,
  required MapCanvasObjectTarget requested,
}) {
  final primarySize = _placedElementSize(project, placed);
  if (primarySize == null) return null;
  if (requested.size.width <= 0 || requested.size.height <= 0) {
    return primarySize;
  }
  return requested.size;
}

bool _isEnvironmentGenerated(MapData map, String placementId) {
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    for (final area in layer.content.areas) {
      if (area.generatedPlacementIds.contains(placementId)) return true;
    }
  }
  return false;
}

MapCanvasObjectTarget _atAnchor(
  MapCanvasObjectTarget source,
  GridPos anchor,
) {
  return MapCanvasObjectTarget(
    kind: source.kind,
    id: source.id,
    layerId: source.layerId,
    anchor: anchor,
    size: source.size,
  );
}

T? _findById<T>(List<T> entries, String id, String Function(T) readId) {
  for (final entry in entries) {
    if (readId(entry) == id) return entry;
  }
  return null;
}

bool _contains(MapCanvasObjectTarget target, GridPos position) {
  return position.x >= target.anchor.x &&
      position.y >= target.anchor.y &&
      position.x < target.anchor.x + target.size.width &&
      position.y < target.anchor.y + target.size.height;
}

int _tileAt(List<int> tiles, GridSize mapSize, GridPos position) {
  final index = position.y * mapSize.width + position.x;
  if (index < 0 || index >= tiles.length) return 0;
  return tiles[index];
}

bool _isInBounds(GridPos anchor, GridSize size, GridSize mapSize) {
  return size.width > 0 &&
      size.height > 0 &&
      anchor.x >= 0 &&
      anchor.y >= 0 &&
      anchor.x + size.width <= mapSize.width &&
      anchor.y + size.height <= mapSize.height;
}
```

### 14.7 `map_canvas_object_move_planner_test.dart`

SHA-256 :
`d3e9b9f7fb5042e7f09b2755ef90a1fbdda668887be8c1e0979287fc68b59989`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/placed_element_instance_indexer.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_move_planner.dart';

void main() {
  const planner = MapCanvasObjectMovePlanner();

  group('MapCanvasObjectMovePlanner', () {
    test('moves an entity by changing its position only', () {
      const entity = MapEntity(
        id: 'npc',
        name: '  Preserved name  ',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        size: GridSize(width: 2, height: 2),
        npc: MapEntityNpcData(
          displayName: '  Preserved display name  ',
          visualElementId: 'npc-visual',
        ),
        editorVisual: MapEntityEditorVisual(
          elementId: 'npc-visual',
          renderInForeground: true,
        ),
        blocksMovement: false,
        properties: <String, String>{' padded ': ' value '},
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 8, height: 8),
        entities: <MapEntity>[entity],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: const MapCanvasObjectTarget(
          kind: MapCanvasObjectKind.entity,
          id: 'npc',
          anchor: GridPos(x: 7, y: 7),
          size: GridSize(width: 1, height: 1),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(plan.canCommit, isTrue);
      expect(plan.rejection, isNull);
      expect(plan.sourceMap, same(map));
      expect(plan.sourceTarget?.anchor, entity.pos);
      expect(plan.sourceTarget?.size, entity.size);
      final moved = plan.candidateMap!.entities.single;
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.copyWith(pos: entity.pos), entity);
      expect(map.entities.single, entity);
    });

    test('moves an authored placed element without normalizing its data', () {
      final shadow = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );
      final placed = MapPlacedElement(
        id: 'placed',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: const GridPos(x: 1, y: 1),
        applyCollision: false,
        opacity: 0.4,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          speed: 1.5,
          randomStart: true,
        ),
        shadowOverride: shadow,
        behaviors: const <MapPlacedElementBehavior>[
          MapPlacedElementBehavior(
            id: '  behavior id  ',
            cooldownMs: 42,
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: '  preserved message  ',
            ),
          ),
        ],
        properties: const <String, String>{
          'pokemapPlacementOrigin': 'authored',
          ' padded ': ' value ',
        },
      );
      final map = _emptyMap.copyWith(
        placedElements: <MapPlacedElement>[placed],
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          placed.id,
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(plan.canCommit, isTrue);
      expect(plan.sourceTarget?.size, const GridSize(width: 2, height: 2));
      final moved = plan.candidateMap!.placedElements.single;
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.copyWith(pos: placed.pos), placed);
      expect(moved.shadowOverride, same(shadow));
    });

    test('keeps the visible animated-frame footprint from selection', () {
      const animatedProject = ProjectManifest(
        name: 'Animated move footprint',
        version: ProjectVersion.v3,
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tiles',
            name: 'Tiles',
            relativePath: 'assets/tiles.png',
          ),
        ],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'animated',
            name: 'Animated',
            tilesetId: 'tiles',
            categoryId: 'decor',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 1, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
      );
      final map = _emptyMap.copyWith(
        size: const GridSize(width: 4, height: 4),
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'animated-placement',
            layerId: 'decor',
            elementId: 'animated',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      const visibleFrameTarget = MapCanvasObjectTarget(
        kind: MapCanvasObjectKind.placedElement,
        id: 'animated-placement',
        layerId: 'decor',
        anchor: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 2),
      );

      final rejected = planner.plan(
        map: map,
        project: animatedProject,
        target: visibleFrameTarget,
        destinationAnchor: const GridPos(x: 3, y: 3),
      );
      final ready = planner.plan(
        map: map,
        project: animatedProject,
        target: visibleFrameTarget,
        destinationAnchor: const GridPos(x: 2, y: 2),
      );

      expect(
        rejected.rejection,
        MapCanvasObjectMoveRejection.destinationOutOfBounds,
      );
      expect(ready.canCommit, isTrue);
      expect(
        ready.previewTarget?.size,
        const GridSize(width: 2, height: 2),
      );
    });

    test('moves an event while preserving its layer, pages, and metadata', () {
      const event = MapEventDefinition(
        id: 'event',
        title: '  Preserved title  ',
        pages: <MapEventPage>[
          MapEventPage(pageNumber: 0, message: '  Preserved page  '),
        ],
        position: EventPosition(layerId: 'decor', x: 1, y: 2),
        type: MapEventType.effect,
        metadata: <String, String>{' padded ': ' value '},
      );
      final map = _emptyMap.copyWith(
        events: const <MapEventDefinition>[event],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.mapEvent, event.id),
        destinationAnchor: const GridPos(x: 5, y: 4),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.events.single;
      expect(
        moved.position,
        const EventPosition(layerId: 'decor', x: 5, y: 4),
      );
      expect(moved.copyWith(position: event.position), event);
    });

    test('moves a warp without changing its destination contract', () {
      const warp = MapWarp(
        id: 'warp',
        pos: GridPos(x: 1, y: 2),
        targetMapId: 'target',
        targetPos: GridPos(x: 7, y: 8),
        triggerMode: MapWarpTriggerMode.onBump,
        allowedApproachFacings: <EntityFacing>[
          EntityFacing.north,
          EntityFacing.west,
        ],
        triggerPadding: WarpTriggerPadding(
          top: 1,
          right: 2,
          bottom: 3,
          left: 4,
        ),
      );
      final map = _emptyMap.copyWith(warps: const <MapWarp>[warp]);

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.warp, warp.id),
        destinationAnchor: const GridPos(x: 5, y: 4),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.warps.single;
      expect(moved.pos, const GridPos(x: 5, y: 4));
      expect(moved.copyWith(pos: warp.pos), warp);
    });

    test('moves a trigger while preserving its area size and properties', () {
      const trigger = MapTrigger(
        id: 'trigger',
        name: '  Preserved name  ',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        properties: <String, String>{' padded ': ' value '},
      );
      final map = _emptyMap.copyWith(
        triggers: const <MapTrigger>[trigger],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.trigger, trigger.id),
        destinationAnchor: const GridPos(x: 4, y: 5),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.triggers.single;
      expect(moved.area.pos, const GridPos(x: 4, y: 5));
      expect(moved.copyWith(area: trigger.area), trigger);
    });

    test('moves a gameplay zone without clearing any typed payload', () {
      const zone = MapGameplayZone(
        id: 'zone',
        name: '  Preserved name  ',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 3, height: 2),
        ),
        priority: 9,
        encounter: EncounterZonePayload(encounterTableId: 'table'),
        movement: MovementZonePayload(),
        movementEffect: MovementEffectZonePayload(movementCost: 3),
        hazard: HazardZonePayload(damagePerStep: 4),
        special: SpecialZonePayload(
          scriptKey: 'script',
          properties: <String, String>{' padded ': ' value '},
        ),
      );
      final map = _emptyMap.copyWith(
        gameplayZones: const <MapGameplayZone>[zone],
      );

      final plan = planner.plan(
        map: map,
        project: null,
        target: _target(MapCanvasObjectKind.gameplayZone, zone.id),
        destinationAnchor: const GridPos(x: 4, y: 5),
      );

      expect(plan.canCommit, isTrue);
      final moved = plan.candidateMap!.gameplayZones.single;
      expect(moved.area.pos, const GridPos(x: 4, y: 5));
      expect(moved.copyWith(area: zone.area), zone);
    });

    test('returns a no-op without creating a candidate map', () {
      final plan = planner.plan(
        map: _mapWithEntity,
        project: null,
        target: _target(MapCanvasObjectKind.entity, 'entity'),
        destinationAnchor: const GridPos(x: 1, y: 1),
      );

      expect(plan.isNoOp, isTrue);
      expect(plan.canCommit, isFalse);
      expect(plan.candidateMap, isNull);
      expect(plan.rejection, isNull);
    });

    test('rejects missing targets without changing the source map', () {
      final plan = planner.plan(
        map: _emptyMap,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          'missing',
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 2, y: 2),
      );

      expect(plan.canCommit, isFalse);
      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.targetNotFound,
      );
      expect(plan.candidateMap, isNull);
      expect(plan.sourceMap, same(_emptyMap));
    });

    test('rejects destinations using each resolved multi-cell footprint', () {
      final cases = <({
        MapData map,
        MapCanvasObjectTarget target,
        ProjectManifest? project,
      })>[
        (
          map: _emptyMap.copyWith(
            placedElements: const <MapPlacedElement>[
              MapPlacedElement(
                id: 'placed',
                layerId: 'decor',
                elementId: 'element-2x2',
                pos: GridPos(x: 1, y: 1),
              ),
            ],
          ),
          target: _target(
            MapCanvasObjectKind.placedElement,
            'placed',
            size: const GridSize(width: 2, height: 2),
          ),
          project: _project,
        ),
        (
          map: _emptyMap.copyWith(
            entities: const <MapEntity>[
              MapEntity(
                id: 'entity',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 1, y: 1),
                size: GridSize(width: 2, height: 2),
              ),
            ],
          ),
          target: _target(MapCanvasObjectKind.entity, 'entity'),
          project: null,
        ),
        (
          map: _emptyMap.copyWith(
            triggers: const <MapTrigger>[
              MapTrigger(
                id: 'trigger',
                type: TriggerType.custom,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 2, height: 2),
                ),
              ),
            ],
          ),
          target: _target(MapCanvasObjectKind.trigger, 'trigger'),
          project: null,
        ),
        (
          map: _emptyMap.copyWith(
            gameplayZones: const <MapGameplayZone>[
              MapGameplayZone(
                id: 'zone',
                kind: GameplayZoneKind.special,
                area: MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 2, height: 2),
                ),
              ),
            ],
          ),
          target: _target(MapCanvasObjectKind.gameplayZone, 'zone'),
          project: null,
        ),
      ];

      for (final entry in cases) {
        final plan = planner.plan(
          map: entry.map,
          project: entry.project,
          target: entry.target,
          destinationAnchor: const GridPos(x: 7, y: 7),
        );

        expect(
          plan.rejection,
          MapCanvasObjectMoveRejection.destinationOutOfBounds,
          reason: entry.target.kind.name,
        );
        expect(plan.previewTarget?.size, const GridSize(width: 2, height: 2));
        expect(plan.candidateMap, isNull);
      }
    });

    test('protects an Environment-owned placement before reading its marker',
        () {
      const placed = MapPlacedElement(
        id: 'generated',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: GridPos(x: 1, y: 1),
        properties: <String, String>{
          'pokemapPlacementOrigin': 'tile_index',
        },
      );
      final map = _emptyMap.copyWith(
        layers: <MapLayer>[
          EnvironmentLayer(
            id: 'environment',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'decor',
              areas: <EnvironmentArea>[
                EnvironmentArea(
                  id: 'area',
                  name: 'Area',
                  presetId: 'forest',
                  mask: EnvironmentAreaMask(
                    width: 8,
                    height: 8,
                    cells: List<bool>.filled(64, true),
                  ),
                  seed: 1,
                  generatedPlacementIds: <String>['generated'],
                ),
              ],
            ),
          ),
          ..._emptyMap.layers,
        ],
        placedElements: const <MapPlacedElement>[placed],
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          placed.id,
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.environmentGeneratedPlacement,
      );
      expect(plan.candidateMap, isNull);
    });

    test('moves a tile-index placement and its tile pattern atomically', () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
      );
      final original = map.placedElements.single;

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          original.id,
          size: const GridSize(width: 2, height: 2),
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(plan.canCommit, isTrue);
      final candidate = plan.candidateMap!;
      final moved = candidate.placedElements.single;
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.copyWith(pos: original.pos), original);
      expect(_tileAt(candidate, 1, 1), 0);
      expect(_tileAt(candidate, 2, 1), 0);
      expect(_tileAt(candidate, 1, 2), 0);
      expect(_tileAt(candidate, 2, 2), 0);
      expect(_tileAt(candidate, 4, 3), 1);
      expect(_tileAt(candidate, 5, 3), 2);
      expect(_tileAt(candidate, 4, 4), 3);
      expect(_tileAt(candidate, 5, 4), 4);
      expect(_tileAt(map, 1, 1), 1);

      final resynced = const PlacedElementInstanceIndexer().syncLayer(
        map: candidate,
        project: _project,
        layerId: 'decor',
      );
      expect(
        resynced.placedElements.singleWhere((entry) => entry.id == original.id),
        moved,
      );
    });

    test('moves an overlapping tile-index pattern without erasing its result',
        () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
        destinationAnchor: const GridPos(x: 2, y: 1),
      );

      expect(plan.canCommit, isTrue);
      final candidate = plan.candidateMap!;
      expect(_tileAt(candidate, 1, 1), 0);
      expect(_tileAt(candidate, 1, 2), 0);
      expect(_tileAt(candidate, 2, 1), 1);
      expect(_tileAt(candidate, 3, 1), 2);
      expect(_tileAt(candidate, 2, 2), 3);
      expect(_tileAt(candidate, 3, 2), 4);
    });

    test('rejects a tile-index move that would overwrite destination tiles',
        () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
        extraTiles: <GridPos, int>{
          const GridPos(x: 4, y: 3): 9,
        },
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.tileIndexedDestinationOccupied,
      );
      expect(plan.candidateMap, isNull);
      expect(_tileAt(map, 1, 1), 1);
      expect(_tileAt(map, 4, 3), 9);
    });

    test('rejects stale tile-index metadata whose source pattern is absent',
        () {
      final map = _tileIndexedMap(
        source: const GridPos(x: 1, y: 1),
        includeSourcePattern: false,
      );

      final plan = planner.plan(
        map: map,
        project: _project,
        target: _target(
          MapCanvasObjectKind.placedElement,
          map.placedElements.single.id,
        ),
        destinationAnchor: const GridPos(x: 4, y: 3),
      );

      expect(
        plan.rejection,
        MapCanvasObjectMoveRejection.tileIndexedSourceInvalid,
      );
      expect(plan.candidateMap, isNull);
    });
  });
}

MapCanvasObjectTarget _target(
  MapCanvasObjectKind kind,
  String id, {
  GridSize size = const GridSize(width: 1, height: 1),
}) {
  return MapCanvasObjectTarget(
    kind: kind,
    id: id,
    anchor: const GridPos(x: 99, y: 99),
    size: size,
  );
}

const _project = ProjectManifest(
  name: 'Move planner',
  version: ProjectVersion.v3,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element-2x2',
      name: 'Element 2x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
        ),
      ],
    ),
  ],
);

const _emptyMap = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v3,
  size: GridSize(width: 8, height: 8),
  layers: <MapLayer>[
    TileLayer(
      id: 'decor',
      name: 'Decor',
      tilesetId: 'tiles',
      tiles: <int>[],
    ),
  ],
);

final _mapWithEntity = _emptyMap.copyWith(
  entities: const <MapEntity>[
    MapEntity(
      id: 'entity',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

MapData _tileIndexedMap({
  required GridPos source,
  bool includeSourcePattern = true,
  Map<GridPos, int> extraTiles = const <GridPos, int>{},
}) {
  const size = GridSize(width: 8, height: 8);
  final tiles = List<int>.filled(size.width * size.height, 0);
  if (includeSourcePattern) {
    tiles[source.y * size.width + source.x] = 1;
    tiles[source.y * size.width + source.x + 1] = 2;
    tiles[(source.y + 1) * size.width + source.x] = 3;
    tiles[(source.y + 1) * size.width + source.x + 1] = 4;
  }
  for (final entry in extraTiles.entries) {
    tiles[entry.key.y * size.width + entry.key.x] = entry.value;
  }
  return MapData(
    id: 'tile-index-map',
    name: 'Tile index map',
    version: ProjectVersion.v3,
    size: size,
    layers: <MapLayer>[
      TileLayer(
        id: 'decor',
        name: 'Decor',
        tilesetId: 'tiles',
        tiles: tiles,
      ),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'stable-derived-id',
        layerId: 'decor',
        elementId: 'element-2x2',
        pos: source,
        applyCollision: false,
        opacity: 0.6,
        animation: const MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
        ),
        behaviors: const <MapPlacedElementBehavior>[
          MapPlacedElementBehavior(
            id: 'behavior',
            effect: MapPlacedElementEffect(
              type: MapPlacedElementEffectType.showMessage,
              message: 'Keep me',
            ),
          ),
        ],
        properties: const <String, String>{
          'pokemapPlacementOrigin': 'tile_index',
          'custom': 'keep',
        },
      ),
    ],
  );
}

int _tileAt(MapData map, int x, int y) {
  final layer = map.layers.whereType<TileLayer>().single;
  return layer.tiles[y * map.size.width + x];
}
```

### 14.8 `map_layer_grouping.dart`

SHA-256 :
`f93978db5e024ba1ef4af5b52b872830443beb9b45110c516f8bdd2e81c24d73`

```dart
import 'package:map_core/map_core.dart';

enum MapLayerGroupMoveDirection {
  up,
  down,
}

/// One visible top-first layer row and every serialized layer it owns.
///
/// A valid Environment attachment belongs to its target Tile group. Other
/// layer kinds, including orphan or invalid Environment layers, remain
/// standalone groups.
final class MapLayerGroup {
  MapLayerGroup._({
    required this.primaryLayer,
    required List<MapLayer> membersTopFirst,
    required List<EnvironmentLayer> attachedEnvironmentLayersTopFirst,
  })  : membersTopFirst = List<MapLayer>.unmodifiable(membersTopFirst),
        attachedEnvironmentLayersTopFirst = List<EnvironmentLayer>.unmodifiable(
          attachedEnvironmentLayersTopFirst,
        );

  final MapLayer primaryLayer;
  final List<MapLayer> membersTopFirst;
  final List<EnvironmentLayer> attachedEnvironmentLayersTopFirst;

  String get id => primaryLayer.id;

  bool get isTileEnvironmentGroup =>
      primaryLayer is TileLayer && attachedEnvironmentLayersTopFirst.isNotEmpty;

  bool containsLayerId(String layerId) {
    return membersTopFirst.any((layer) => layer.id == layerId);
  }
}

/// Builds and atomically reorders the visible top-first layer groups.
final class MapLayerGroupService {
  const MapLayerGroupService();

  List<MapLayerGroup> groupsTopFirst(MapData map) {
    final layersById = <String, MapLayer>{
      for (final layer in map.layers) layer.id: layer,
    };
    final attachmentsByTarget =
        Map<TileLayer, List<EnvironmentLayer>>.identity();
    final attachedEnvironments = Set<EnvironmentLayer>.identity();

    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      final targetId = layer.content.targetTileLayerId?.trim();
      final target =
          targetId == null || targetId.isEmpty ? null : layersById[targetId];
      if (target is! TileLayer) {
        continue;
      }
      attachmentsByTarget
          .putIfAbsent(target, () => <EnvironmentLayer>[])
          .add(layer);
      attachedEnvironments.add(layer);
    }

    final groups = <MapLayerGroup>[];
    for (final layer in map.layers) {
      if (layer is EnvironmentLayer && attachedEnvironments.contains(layer)) {
        continue;
      }
      final attachments = layer is TileLayer
          ? attachmentsByTarget[layer] ?? const <EnvironmentLayer>[]
          : const <EnvironmentLayer>[];
      if (attachments.isEmpty) {
        groups.add(
          MapLayerGroup._(
            primaryLayer: layer,
            membersTopFirst: <MapLayer>[layer],
            attachedEnvironmentLayersTopFirst: const <EnvironmentLayer>[],
          ),
        );
        continue;
      }

      final attachmentSet = Set<EnvironmentLayer>.identity()
        ..addAll(attachments);
      groups.add(
        MapLayerGroup._(
          primaryLayer: layer,
          membersTopFirst: <MapLayer>[
            for (final candidate in map.layers)
              if (identical(candidate, layer) ||
                  candidate is EnvironmentLayer &&
                      attachmentSet.contains(candidate))
                candidate,
          ],
          attachedEnvironmentLayersTopFirst: attachments,
        ),
      );
    }
    return List<MapLayerGroup>.unmodifiable(groups);
  }

  MapData moveAdjacent({
    required MapData map,
    required String layerId,
    required MapLayerGroupMoveDirection direction,
  }) {
    final groups = groupsTopFirst(map);
    final sourceIndex = _groupIndexForLayerId(groups, layerId);
    final destinationIndex = switch (direction) {
      MapLayerGroupMoveDirection.up => sourceIndex - 1,
      MapLayerGroupMoveDirection.down => sourceIndex + 1,
    };
    if (destinationIndex < 0 || destinationIndex >= groups.length) {
      return map;
    }

    final reordered = List<MapLayerGroup>.from(groups, growable: false);
    final destination = reordered[destinationIndex];
    reordered[destinationIndex] = reordered[sourceIndex];
    reordered[sourceIndex] = destination;
    return _mapWithGroups(map, reordered);
  }

  /// Moves the group containing [layerId] before a top-first group slot.
  ///
  /// [beforeGroupIndex] follows `ReorderableListView` insertion semantics:
  /// zero is the top and `groups.length` is the slot after the last group.
  MapData moveBeforeGroupIndex({
    required MapData map,
    required String layerId,
    required int beforeGroupIndex,
  }) {
    final groups = groupsTopFirst(map);
    if (beforeGroupIndex < 0 || beforeGroupIndex > groups.length) {
      throw RangeError.range(
        beforeGroupIndex,
        0,
        groups.length,
        'beforeGroupIndex',
      );
    }
    final sourceIndex = _groupIndexForLayerId(groups, layerId);
    var insertionIndex = beforeGroupIndex;
    if (insertionIndex > sourceIndex) {
      insertionIndex -= 1;
    }
    if (insertionIndex == sourceIndex) {
      return map;
    }

    final reordered = List<MapLayerGroup>.from(groups, growable: true);
    final source = reordered.removeAt(sourceIndex);
    reordered.insert(insertionIndex, source);
    return _mapWithGroups(map, reordered);
  }

  /// Moves one group before the group containing [beforeLayerId].
  MapData moveBeforeGroup({
    required MapData map,
    required String layerId,
    required String beforeLayerId,
  }) {
    final groups = groupsTopFirst(map);
    final beforeGroupIndex = _groupIndexForLayerId(groups, beforeLayerId);
    return moveBeforeGroupIndex(
      map: map,
      layerId: layerId,
      beforeGroupIndex: beforeGroupIndex,
    );
  }
}

int _groupIndexForLayerId(
  List<MapLayerGroup> groups,
  String layerId,
) {
  final index = groups.indexWhere((group) => group.containsLayerId(layerId));
  if (index < 0) {
    throw ArgumentError.value(
      layerId,
      'layerId',
      'Layer does not belong to a map layer group',
    );
  }
  return index;
}

MapData _mapWithGroups(
  MapData map,
  List<MapLayerGroup> groups,
) {
  final layers = <MapLayer>[
    for (final group in groups) ...group.membersTopFirst,
  ];
  if (!_hasSameIdentityMembers(map.layers, layers)) {
    throw StateError(
      'Layer group reorder must preserve every serialized layer instance '
      'exactly once.',
    );
  }
  if (_hasSameIdentityOrder(map.layers, layers)) {
    return map;
  }
  return map.copyWith(layers: layers);
}

bool _hasSameIdentityMembers(
  List<MapLayer> previous,
  List<MapLayer> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  final remaining = List<MapLayer>.of(next);
  for (final previousLayer in previous) {
    final matchIndex = remaining.indexWhere(
      (nextLayer) => identical(nextLayer, previousLayer),
    );
    if (matchIndex < 0) {
      return false;
    }
    remaining.removeAt(matchIndex);
  }
  return remaining.isEmpty;
}

bool _hasSameIdentityOrder(
  List<MapLayer> previous,
  List<MapLayer> next,
) {
  if (previous.length != next.length) {
    return false;
  }
  for (var index = 0; index < previous.length; index++) {
    if (!identical(previous[index], next[index])) {
      return false;
    }
  }
  return true;
}
```

### 14.9 `map_layer_grouping_test.dart`

SHA-256 :
`6f3693834e1c88a2e9b905f0a4c5f2f776fe23edd8d94181c263f34c756ff61b`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_layer_grouping.dart';

void main() {
  const service = MapLayerGroupService();

  group('MapLayerGroupService', () {
    test(
      'exposes top-first groups with every valid Environment attachment',
      () {
        final map = _interleavedMap();

        final groups = service.groupsTopFirst(map);

        expect(
          groups.map((group) => group.primaryLayer.id),
          const <String>['top', 'middle', 'tile-a', 'orphan', 'bottom'],
        );
        final tileGroup =
            groups.singleWhere((group) => group.primaryLayer.id == 'tile-a');
        expect(tileGroup.isTileEnvironmentGroup, isTrue);
        expect(
          tileGroup.attachedEnvironmentLayersTopFirst.map((layer) => layer.id),
          const <String>['env-a-2', 'env-a-1'],
        );
        expect(
          tileGroup.membersTopFirst.map((layer) => layer.id),
          const <String>['env-a-2', 'tile-a', 'env-a-1'],
        );
        expect(
          tileGroup.membersTopFirst.map((layer) => map.layers.indexOf(layer)),
          orderedEquals(<int>[1, 3, 5]),
        );
      },
    );

    test('keeps every orphan or invalid Environment as a standalone group', () {
      final map = _mapWithInvalidEnvironments();

      final groups = service.groupsTopFirst(map);

      expect(
        groups.map((group) => group.primaryLayer.id),
        const <String>[
          'no-target',
          'missing-target',
          'non-tile-target',
          'objects',
          'tile-a',
        ],
      );
      for (final id in const <String>[
        'no-target',
        'missing-target',
        'non-tile-target',
      ]) {
        final group =
            groups.singleWhere((entry) => entry.primaryLayer.id == id);
        expect(group.membersTopFirst, hasLength(1), reason: id);
        expect(group.primaryLayer, isA<EnvironmentLayer>(), reason: id);
        expect(group.isTileEnvironmentGroup, isFalse, reason: id);
      }
      expect(
        groups
            .singleWhere((entry) => entry.primaryLayer.id == 'tile-a')
            .attachedEnvironmentLayersTopFirst,
        isEmpty,
      );
    });

    test('moves a whole Tile and Environment group one row up or down', () {
      final map = _orderedMap();

      final movedUp = service.moveAdjacent(
        map: map,
        layerId: 'tile-a',
        direction: MapLayerGroupMoveDirection.up,
      );
      final movedDown = service.moveAdjacent(
        map: map,
        layerId: 'tile-a',
        direction: MapLayerGroupMoveDirection.down,
      );
      final movedByAttachedId = service.moveAdjacent(
        map: map,
        layerId: 'env-a-1',
        direction: MapLayerGroupMoveDirection.down,
      );

      expect(
        _layerIds(movedUp),
        const <String>[
          'tile-a',
          'env-a-1',
          'env-a-2',
          'top',
          'middle',
          'bottom',
        ],
      );
      expect(
        _layerIds(movedDown),
        const <String>[
          'top',
          'middle',
          'tile-a',
          'env-a-1',
          'env-a-2',
          'bottom',
        ],
      );
      expect(movedByAttachedId, movedDown);
    });

    test('does not move the first group up or the last group down', () {
      final map = _orderedMap();

      final aboveTop = service.moveAdjacent(
        map: map,
        layerId: 'top',
        direction: MapLayerGroupMoveDirection.up,
      );
      final belowBottom = service.moveAdjacent(
        map: map,
        layerId: 'bottom',
        direction: MapLayerGroupMoveDirection.down,
      );

      expect(aboveTop, same(map));
      expect(belowBottom, same(map));
    });

    test(
      'an interleaved group becomes one block without changing member order',
      () {
        final map = _interleavedMap();

        final moved = service.moveAdjacent(
          map: map,
          layerId: 'tile-a',
          direction: MapLayerGroupMoveDirection.up,
        );

        expect(
          _layerIds(moved),
          const <String>[
            'top',
            'env-a-2',
            'tile-a',
            'env-a-1',
            'middle',
            'orphan',
            'bottom',
          ],
        );
        expect(moved.copyWith(layers: map.layers), map);
        expect(
          moved.layers.map((layer) => layer.id).toSet(),
          map.layers.map((layer) => layer.id).toSet(),
        );
        for (final original in map.layers) {
          expect(
            moved.layers.singleWhere((layer) => layer.id == original.id),
            same(original),
            reason: original.id,
          );
        }
      },
    );

    test('drag before an index or a group matches the adjacent move', () {
      final map = _orderedMap();
      final adjacent = service.moveAdjacent(
        map: map,
        layerId: 'tile-a',
        direction: MapLayerGroupMoveDirection.down,
      );

      final beforeIndex = service.moveBeforeGroupIndex(
        map: map,
        layerId: 'tile-a',
        beforeGroupIndex: 3,
      );
      final beforeGroup = service.moveBeforeGroup(
        map: map,
        layerId: 'tile-a',
        beforeLayerId: 'bottom',
      );

      expect(beforeIndex, adjacent);
      expect(beforeGroup, adjacent);
    });

    test('supports drag slots at the very top and bottom', () {
      final map = _orderedMap();

      final atTop = service.moveBeforeGroupIndex(
        map: map,
        layerId: 'middle',
        beforeGroupIndex: 0,
      );
      final groupCount = service.groupsTopFirst(map).length;
      final atBottom = service.moveBeforeGroupIndex(
        map: map,
        layerId: 'tile-a',
        beforeGroupIndex: groupCount,
      );

      expect(
        _layerIds(atTop),
        const <String>[
          'middle',
          'top',
          'tile-a',
          'env-a-1',
          'env-a-2',
          'bottom',
        ],
      );
      expect(
        _layerIds(atBottom),
        const <String>[
          'top',
          'middle',
          'bottom',
          'tile-a',
          'env-a-1',
          'env-a-2',
        ],
      );
    });

    test('same-group drag targets are exact no-ops', () {
      final map = _orderedMap();

      final beforeSelf = service.moveBeforeGroup(
        map: map,
        layerId: 'env-a-2',
        beforeLayerId: 'tile-a',
      );
      final alreadyBeforeNext = service.moveBeforeGroup(
        map: map,
        layerId: 'tile-a',
        beforeLayerId: 'middle',
      );

      expect(beforeSelf, same(map));
      expect(alreadyBeforeNext, same(map));
    });

    test(
      'duplicate Environment ids never duplicate serialized layer instances',
      () {
        final firstEnvironment = _environment('duplicate', 'tile-a');
        final secondEnvironment = _environment('duplicate', 'tile-b');
        final map = MapData(
          id: 'invalid-duplicate-environment-ids',
          name: 'Invalid duplicate Environment ids',
          size: const GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            _tile('tile-a'),
            firstEnvironment,
            _tile('tile-b'),
            secondEnvironment,
            const ObjectLayer(id: 'bottom', name: 'Bottom'),
          ],
        );

        final moved = service.moveAdjacent(
          map: map,
          layerId: 'tile-b',
          direction: MapLayerGroupMoveDirection.down,
        );

        expect(moved.layers, hasLength(map.layers.length));
        expect(
          moved.layers,
          orderedEquals(<MapLayer>[
            map.layers[0],
            firstEnvironment,
            map.layers[4],
            map.layers[2],
            secondEnvironment,
          ]),
        );
        for (final original in map.layers) {
          expect(
            moved.layers.where((layer) => identical(layer, original)),
            hasLength(1),
          );
        }
      },
    );

    test('rejects stale identifiers and invalid drag slots', () {
      final map = _orderedMap();

      expect(
        () => service.moveAdjacent(
          map: map,
          layerId: 'missing',
          direction: MapLayerGroupMoveDirection.up,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.moveBeforeGroup(
          map: map,
          layerId: 'tile-a',
          beforeLayerId: 'missing',
        ),
        throwsArgumentError,
      );
      expect(
        () => service.moveBeforeGroupIndex(
          map: map,
          layerId: 'tile-a',
          beforeGroupIndex: -1,
        ),
        throwsRangeError,
      );
      expect(
        () => service.moveBeforeGroupIndex(
          map: map,
          layerId: 'tile-a',
          beforeGroupIndex: service.groupsTopFirst(map).length + 1,
        ),
        throwsRangeError,
      );
    });
  });
}

MapData _orderedMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    properties: const <String, String>{'preserve': 'exactly'},
    layers: <MapLayer>[
      const ObjectLayer(id: 'top', name: 'Top'),
      _tile('tile-a'),
      _environment('env-a-1', 'tile-a'),
      _environment('env-a-2', 'tile-a'),
      const ObjectLayer(id: 'middle', name: 'Middle'),
      const ObjectLayer(id: 'bottom', name: 'Bottom'),
    ],
  );
}

MapData _interleavedMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    properties: const <String, String>{'preserve': 'exactly'},
    layers: <MapLayer>[
      const ObjectLayer(id: 'top', name: 'Top'),
      _environment('env-a-2', 'tile-a'),
      const ObjectLayer(id: 'middle', name: 'Middle'),
      _tile('tile-a'),
      _environment('orphan', 'missing'),
      _environment('env-a-1', 'tile-a'),
      const ObjectLayer(id: 'bottom', name: 'Bottom'),
    ],
  );
}

MapData _mapWithInvalidEnvironments() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      _environment('no-target', null),
      _environment('missing-target', 'missing'),
      _environment('non-tile-target', 'objects'),
      const ObjectLayer(id: 'objects', name: 'Objects'),
      _tile('tile-a'),
    ],
  );
}

TileLayer _tile(String id) {
  return TileLayer(id: id, name: id, tiles: const <int>[0]);
}

EnvironmentLayer _environment(String id, String? targetLayerId) {
  return EnvironmentLayer(
    id: id,
    name: id,
    content: EnvironmentLayerContent(targetTileLayerId: targetLayerId),
  );
}

List<String> _layerIds(MapData map) {
  return map.layers.map((layer) => layer.id).toList(growable: false);
}
```
