# Evidence Pack — DS‑06 « Resize impact plan »

- Date : 2026-07-28
- Branche : `main`
- Base du lot : `294ec75060eef157fcd5768a0a6046e9d360760d`
- Commit fonctionnel : `3adc66a5d5fa718f63d43bfd7229942566d4429f` (`feat(map-editor): add safe resize impact planning`)
- Verdict : **DS‑06 peut être marqué DONE** ; **Gate 0 peut être proposé DONE** au regard des scénarios de perte silencieuse connus couverts par DS‑00 à DS‑06.

## 1. Demande, source et critères de sortie

La demande était d’implémenter le lot DS‑06 « Resize impact plan », puis de commit et push.

Source de cadrage : `reports/ui/world_map_editor_audit_2026-07-28/world_map_editor_ultra_complete_audit.md`, notamment les lignes 471–485 et 1193–1199.

Critères retenus :

- produire un plan pur et immuable avant toute mutation ;
- laisser les agrandissements et réductions prouvées sans perte directement applicables ;
- bloquer par défaut toute réduction destructive ou ambiguë ;
- lister les données et objets affectés avant mutation ;
- couvrir les couches, footprints multi-cellules, références générées, entités, événements, warps, triggers, zones et connexions ;
- présenter ce plan dans une UI no-code du design system ;
- revalider le plan dans la couche application au moment d’exécuter, sans faire de la modale une frontière de sûreté.

## 2. Audit initial

État observé avant DS‑06 :

- le redimensionnement partait directement vers l’opération de mutation ;
- les diagnostics Border existaient, mais il n’existait pas de contrat unique couvrant toutes les collections auteur ;
- l’ancienne feuille demandait seulement largeur et hauteur ;
- une réduction pouvait supprimer des cellules ou objets sans inventaire préalable compréhensible ;
- la résolution des footprints d’éléments dépend du manifeste projet et devait donc être propagée jusqu’au Core ;
- l’arbre Git contenait déjà 62 entrées sans rapport avec DS‑06, à préserver intégralement.

Verdict initial : **BLOCKING pour Gate 0** tant qu’une réduction destructive pouvait atteindre la mutation sans plan exhaustif.

## 3. Résultat livré

### 3.1 Contrat pur dans `map_core`

`MapResizePlan` et `MapResizeImpact` forment désormais un aperçu déterministe, immuable et indépendant de Flutter. Le plan expose une taxonomie stable, le nombre exact d’éléments affectés et au plus huit coordonnées d’exemple par impact afin de ne pas allouer une liste proportionnelle à une immense carte pendant la prévisualisation live.

La couverture comprend :

| Famille | Cas couverts | Politique |
|---|---|---|
| Cellules | tile, collision, terrain, path | bloque si des cellules non vides seraient rognées |
| Surfaces et environnement | surface placements, masks | bloque si position ou zone sort de la cible |
| Border | diagnostics, warnings et erreurs de clipping/structure | intégrés dans le même plan ; contexte manquant = fail-closed |
| Éléments placés | origine, footprint projet multi-cellules | bloque si footprint hors carte ou impossible à résoudre |
| Références générées | `generatedPlacementIds` | bloque toute référence qui deviendrait pendante |
| Entités | footprint, patrol waypoints | bloque position, footprint ou waypoint hors cible |
| Warps | source, padding d’activation, cible locale | bloque source/zone/cible locale invalidée |
| Logique auteur | triggers, gameplay zones, events | bloque rectangles ou positions rognés |
| Topologie | connections | toute réduction est bloquée conservativement si une connexion existe |

### 3.2 Garde applicative

`ResizeMapUseCase.plan(...)` expose le même plan à l’UI. `execute(...)` reconstruit le plan juste avant la mutation et retourne un résultat typé avec `map == null` si le plan ou Border bloque. Le notifier ne crée ni mutation ni entrée d’historique dans ce cas et propage le `ProjectManifest` pour résoudre les footprints.

### 3.3 Modale no-code

La feuille historique est remplacée par une modale dédiée du design system : champs largeur/hauteur validés, prévisualisation live débouncée à 120 ms, état no-op, résumé des impacts, coordonnées échantillonnées, fermeture Escape et bouton d’application désactivé tant que le plan n’est pas prouvé sûr. Aucun override destructif n’est exposé.

## 4. Inventaire des fichiers

| Fichier | Statut | Zones / responsabilité |
|---|---:|---|
| `packages/map_core/lib/src/operations/map_resize.dart` | modifié | lignes 14, 20–163 et 174–585 : taxonomie, contrat et plan pur ; lignes 587–649 et 855–945 : géométrie/échantillonnage |
| `packages/map_core/test/map_resize_plan_test.dart` | créé | lignes 1–407 : 6 tests du plan pur |
| `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` | modifié | lignes 236–306 : résultat typé, planification, revalidation avant mutation |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | modifié | lignes 3114–3194 : aperçu sans effet de bord et exécution fail-closed |
| `packages/map_editor/lib/src/ui/design_system/design_system.dart` | modifié | ligne 25 : export public de la modale |
| `packages/map_editor/lib/src/ui/design_system/pokemap_resize_impact_dialog.dart` | créé | lignes 1–456 : modale design system et preview live |
| `packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart` | modifié | lignes 378–399 : branchement de la nouvelle modale |
| `packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart` | modifié | lignes 11–220 : garde use case/notifier, Border, no-op et historique |
| `packages/map_editor/test/ui/design_system/pokemap_resize_impact_dialog_test.dart` | créé | lignes 1–170 : 3 scénarios widget |
| `reports/ui/world_map_editor_ds_06_resize_impact_plan_2026-07-28.md` | créé | présent Evidence Pack ; son contenu complet est nécessairement le fichier lui-même et n’est pas répliqué récursivement |
| `docs/superpowers/plans/2026-07-28-world-map-ds-06-resize-impact-plan.md` | créé, ignoré par `/docs/*` | plan d’exécution local imposé par le workflow ; contenu complet en annexe |

Numstat exact du commit fonctionnel :

```text
735	0	packages/map_core/lib/src/operations/map_resize.dart
407	0	packages/map_core/test/map_resize_plan_test.dart
57	2	packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
27	2	packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
1	0	packages/map_editor/lib/src/ui/design_system/design_system.dart
456	0	packages/map_editor/lib/src/ui/design_system/pokemap_resize_impact_dialog.dart
16	84	packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart
83	20	packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart
170	0	packages/map_editor/test/ui/design_system/pokemap_resize_impact_dialog_test.dart
```

Résumé Git exact : **9 fichiers, 1952 insertions, 108 suppressions**.

## 5. Zones de diff précises

- `map_resize.dart:14` borne les échantillons ; `:20–163` définit les contrats ; `:174–585` inspecte toutes les collections ; `:652` conserve l’opération de resize existante derrière le garde applicatif.
- `map_use_cases.dart:236–306` ajoute `ResizeMapUseCaseResult`, `plan(...)` et l’arrêt avant mutation.
- `editor_notifier.dart:3116` fournit l’aperçu ; `:3135` replannifie et refuse mutation/historique en cas d’impact.
- `pokemap_resize_impact_dialog.dart:56` ouvre la modale ; `:215` gère les raccourcis ; `:234–408` compose uniquement des primitives/tokens PokeMap.
- `top_toolbar_dialogs.dart:384–397` remplace l’ancienne feuille par preview puis exécution.
- Tests Core : `map_resize_plan_test.dart:6,33,103,161,184,204`.
- Tests application : `border_resize_editor_integration_test.dart:11,39,79,127,156,176,199`.
- Tests UI : `pokemap_resize_impact_dialog_test.dart:9,53,99`.

## 6. TDD et preuves RED → GREEN

RED observés avant implémentation :

- Core : symboles `planMapResize`, `MapResizeImpactKind` et `MapResizeImpactReason` absents ; deux erreurs de fixture (`TerrainType.water` et ancien argument `scriptId`) ont été corrigées avant le GREEN.
- Éditeur : `ResizeMapUseCaseResult`, paramètre `project` et `planActiveMapResize` absents.
- UI : fichier et API de modale absents.
- Une première exécution widget a révélé que le test ne laissait pas expirer le debounce ; le test a été corrigé avec un pump de 150 ms.
- L’analyseur a détecté `prefer_const_declarations` dans un test ; corrigé avant la suite complète.

GREEN final :

| Commande | Résultat exact |
|---|---|
| `cd packages/map_core && dart test test/map_resize_plan_test.dart` | `+6: All tests passed!` |
| `cd packages/map_core && dart test` | `+4522: All tests passed!` |
| `cd packages/map_core && dart analyze` | `No issues found!` |
| `cd packages/map_editor && flutter test test/border_map_editing/border_resize_editor_integration_test.dart test/ui/design_system/pokemap_resize_impact_dialog_test.dart` | `+10: All tests passed!` |
| `cd packages/map_editor && flutter test` | `+4452 ~6: All tests passed!` |
| `cd packages/map_editor && flutter analyze` | `No issues found!` |
| `cd packages/map_editor && flutter build macos --debug` | `✓ Built build/macos/Build/Products/Debug/PokeMap.app` |
| `dart format --output=none --set-exit-if-changed <9 fichiers DS-06>` | `Formatted 9 files (0 changed)` |
| `git diff --check -- <9 fichiers DS-06>` puis `git diff --cached --check` | code de sortie `0`, aucune sortie |

Le build macOS a seulement émis des warnings de dépréciation/optionality venant du package externe `video_player_avfoundation`; aucune erreur de build PokeMap.

## 7. Passes de revue

Une instruction de session de priorité supérieure interdisait de lancer des sub-agents. Le verdict demandé par `codex_rule.md` a donc été produit par cinq passes locales indépendantes et nommées :

1. **Conformité au lot — PASS** : tous les critères DS‑06 sont couverts, sans override destructif.
2. **Complétude du modèle de perte — PASS** : toutes les collections spatiales connues de `MapData` sont inspectées ; les footprints inconnus échouent fermés.
3. **Architecture et frontières packages — PASS** : règles pures dans `map_core`, orchestration dans `map_editor`, aucune dépendance Flutter/Flame ajoutée au Core.
4. **Design system et accessibilité — PASS** : couleurs issues des tokens, primitives PokeMap, validation explicite, Escape, état du bouton et libellés de barrière.
5. **Régression/performance — PASS après correction** : la passe a découvert le risque d’allocation proportionnelle au nombre de cellules rognées ; corrigé par compte exact + huit positions maximum. Recherche des appels directs : hors tests Core, seul le use case protégé appelle `resizeMapDataWithBorderDiagnostics`.

Verdict global des passes : **PASS**.

## 8. État Git initial et état de clôture

État initial à `294ec75060eef157fcd5768a0a6046e9d360760d` : 62 entrées préexistantes hors DS‑06. Après le commit fonctionnel, la sortie est redevenue strictement identique. Le commit de ce rapport ne touche qu’à ce fichier ; la vérification post-commit et le résultat du push sont fournis dans le handoff final afin d’éviter une auto-référence infinie dans l’Evidence Pack.

### Sortie initiale exacte

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

### Sortie de clôture attendue et déjà vérifiée après le commit fonctionnel

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

Aucun de ces 62 chemins n’a été ajouté au commit fonctionnel.

## 9. Décisions et non-objectifs

- DS‑06 protège la réduction ; il n’ajoute pas encore un workflow guidé pour déplacer/supprimer volontairement chaque impact.
- Les connexions sont traitées conservativement pendant toute réduction : cela peut sur-bloquer, mais ne peut pas perdre silencieusement une topologie.
- Le plan n’inclut que huit coordonnées d’exemple par groupe, mais conserve toujours `affectedCount` exact.
- Aucun schéma JSON, format de sauvegarde, runtime Flame ou mécanique de gameplay n’a été modifié.
- La navigation souris, le déplacement d’objets, le filtrage/mémoire de tilesets et l’ordre visuel des layers appartiennent aux lots suivants de la refonte.

## 10. Risques et auto-critique

1. **API Core bas niveau encore publique** : `resizeMapDataWithBorderDiagnostics` reste intrinsèquement destructive si un futur consommateur la contourne. La recherche actuelle ne trouve aucun chemin produit non protégé, mais un lot ultérieur pourrait la rendre interne ou exiger un plan applicable.
2. **Sur-blocage des connexions** : faute d’une règle topologique plus fine, toute réduction avec connexion est refusée. C’est sûr mais moins ergonomique.
3. **Pas de test manuel d’interaction réelle** : les widget tests, suites complètes, analyseurs et build macOS sont verts ; une passe desktop réelle reste utile pour évaluer confort clavier, focus et lisibilité sur petits écrans.
4. **Arbre partagé fortement sale** : les validations ont été exécutées dans l’état partagé contenant 62 changements hors lot. Le commit DS‑06 a néanmoins été isolé chemin par chemin et contrôlé par `git diff --cached --name-status`.
5. **Rapport/push auto-référents** : le SHA du commit documentaire et le résultat final du push ne peuvent pas être inscrits dans ce même commit sans mutation récursive ; ils sont remis dans la réponse finale.

Auto-critique : le choix fail-closed est volontairement strict. Il remplit le critère de sûreté de Gate 0, mais le vrai gain ergonomique arrivera lorsque l’éditeur proposera des résolutions actionnables pour chaque impact au lieu de simplement refuser.

## 11. Proposition de statut

- **DS‑06 — Resize impact plan : DONE**.
- **Gate 0 — Foundations : proposé DONE**, sous réserve d’accepter la politique conservatrice sur les connexions.
- Lot recommandé ensuite : le premier lot d’interaction canvas de la roadmap UI (navigation souris/trackpad et séparation stricte navigation/peinture), car c’est le principal irritant utilisateur restant.

## Annexes — contenu complet des fichiers créés

Les trois nouveaux fichiers trackés et le plan local ignoré sont reproduits intégralement ci-dessous. Le présent rapport n’est pas inclus dans lui-même pour éviter une récursion impossible.


<details>
<summary>Plan local — <code>docs/superpowers/plans/2026-07-28-world-map-ds-06-resize-impact-plan.md</code></summary>

~~~~markdown
# DS-06 — Resize Impact Plan

> **For Codex:** Execute this plan with the repository `executing-plans`,
> `test-driven-development`, and `verification-before-completion` workflows.

**Goal:** Make every world-map resize previewable and loss-safe: expansion and
empty shrink remain applicable, while any destructive or semantically
ambiguous shrink is listed and blocked before mutation.

**Architecture:** Add a pure `MapResizePlan` read model to `map_core`, built
from `MapData`, the target size, project element footprints, and Border
preflight diagnostics. The editor use case owns the safe plan-then-apply
boundary and rechecks the plan even when called outside the dialog. A
design-system modal presents the target size and every affected authored
object before returning an applicable target.

**Tech Stack:** Dart, Flutter, Riverpod, PokeMap design system, `package:test`,
`flutter_test`.

---

## Task 1: Characterize the pure impact contract

**Files:**

- Create: `packages/map_core/test/map_resize_plan_test.dart`
- Modify: `packages/map_core/lib/src/operations/map_resize.dart`

1. Add failing tests proving that expansion and an empty shrink are directly
   applicable.
2. Add a composite failing test that expects complete impacts for meaningful
   clipped layer cells, surfaces, environment masks, placed-element
   footprints and generated ownership, entities and patrol points, warps,
   trigger rectangles, gameplay zones, events, and connections.
3. Add Border tests proving that clipping diagnostics become blocking impacts
   and that invalid Border content stays fail-closed.
4. Run `dart test test/map_resize_plan_test.dart` and retain the RED result.
5. Implement immutable `MapResizePlan`, `MapResizeImpact`, their enums, and the
   pure `planMapResize` traversal in the already-exported `map_resize.dart`.
6. Re-run the focused test until green, then run `dart format` on the changed
   files.

## Task 2: Enforce plan-before-mutation in the editor application layer

**Files:**

- Modify:
  `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart`
- Modify:
  `packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart`

1. Add failing tests for `ResizeMapUseCase.plan`, safe expansion, and blocked
   destructive shrink returning no map.
2. Introduce `ResizeMapUseCaseResult` carrying the plan, optional resized map,
   and Border diagnostics.
3. Make `execute` build the plan first and return without invoking the lossy
   resize operation when `plan.canApply` is false.
4. Pass the project manifest into planning so multi-cell
   `ProjectElementEntry.frames.primarySource` footprints are exact.
5. Re-run the focused integration tests.

## Task 3: Guard direct notifier callers

**Files:**

- Modify:
  `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Modify:
  `packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart`

1. Add a failing notifier test proving that a direct destructive resize keeps
   the same map identity, creates no undo entry, and exposes a blocking error.
2. Add a synchronous `planActiveMapResize` preview method.
3. Pass the active project to the use case in both preview and execution.
4. Format a specific blocked-impact error instead of reporting zero Border
   diagnostics.
5. Re-run the focused notifier tests.

## Task 4: Replace the legacy resize sheet with a design-system preview

**Files:**

- Create:
  `packages/map_editor/lib/src/ui/design_system/pokemap_resize_impact_dialog.dart`
- Modify:
  `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- Modify:
  `packages/map_editor/lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart`
- Create:
  `packages/map_editor/test/ui/design_system/pokemap_resize_impact_dialog_test.dart`

1. Add widget tests for initial no-op, safe expansion, invalid dimensions, and
   destructive shrink with a visible impact list and disabled apply action.
2. Implement a token-driven, keyboard-accessible modal using
   `PokeMapPanel`, `PokeMapTextField`, `PokeMapDiagnosticCallout`,
   `PokeMapSectionHeader`, and `PokeMapButton`.
3. Keep all user-facing formatting in the editor; core impact records remain
   machine-readable.
4. Replace `showMacosSheet` in the toolbar wrapper with the new modal and call
   the notifier only when it returns an applicable target.
5. Re-run the widget test and the toolbar-adjacent tests.

## Task 5: Verify, review, and close DS-06

**Files:**

- Create:
  `reports/ui/world_map_editor_ds_06_resize_impact_plan_2026-07-28.md`

1. Run focused tests first, then:
   `cd packages/map_core && dart test && dart analyze`.
2. Run:
   `cd packages/map_editor && flutter test && flutter analyze`.
3. Run the relevant desktop build if the environment supports it.
4. Perform five named review passes: requirements, loss-model completeness,
   architecture/package boundaries, UI/accessibility/design system, and
   verification/regression risk. Fix every critical or important finding.
5. Write the Evidence Pack required by `codex_rule.md`, including initial and
   final Git state, exact commands/results, modified zones, full new-file
   contents, risks, and self-critique.
6. Stage only DS-06 paths, inspect the staged diff, commit with
   `feat(map-editor): add safe resize impact planning`, verify the remote tip,
   and push the current branch.

~~~~

</details>
<details>
<summary>Tests Core — <code>packages/map_core/test/map_resize_plan_test.dart</code></summary>

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('planMapResize', () {
    test('keeps expansion and empty shrink directly applicable', () {
      final map = MapData(
        id: 'quiet-map',
        name: 'Quiet map',
        size: const GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tiles: List<int>.filled(9, 0),
          ),
        ],
      );

      final expansion = planMapResize(map, width: 5, height: 4);
      final emptyShrink = planMapResize(map, width: 2, height: 2);

      expect(expansion.isExpansion, isTrue);
      expect(expansion.hasShrink, isFalse);
      expect(expansion.canApply, isTrue);
      expect(expansion.impacts, isEmpty);
      expect(emptyShrink.isExpansion, isFalse);
      expect(emptyShrink.hasShrink, isTrue);
      expect(emptyShrink.canApply, isTrue);
      expect(emptyShrink.impacts, isEmpty);
    });

    test('lists every affected authored collection before destructive shrink',
        () {
      final map = _compositeMap();

      final plan = planMapResize(
        map,
        width: 2,
        height: 2,
        project: _project(),
      );

      expect(plan.canApply, isFalse);
      expect(plan.hasDestructiveImpacts, isTrue);
      expect(
        plan.impacts.map((impact) => impact.kind).toSet(),
        containsAll(<MapResizeImpactKind>{
          MapResizeImpactKind.tileLayer,
          MapResizeImpactKind.collisionLayer,
          MapResizeImpactKind.terrainLayer,
          MapResizeImpactKind.pathLayer,
          MapResizeImpactKind.surfaceLayer,
          MapResizeImpactKind.environmentArea,
          MapResizeImpactKind.placedElement,
          MapResizeImpactKind.generatedPlacementReference,
          MapResizeImpactKind.entity,
          MapResizeImpactKind.entityWaypoint,
          MapResizeImpactKind.warp,
          MapResizeImpactKind.warpTriggerArea,
          MapResizeImpactKind.localWarpTarget,
          MapResizeImpactKind.trigger,
          MapResizeImpactKind.gameplayZone,
          MapResizeImpactKind.event,
          MapResizeImpactKind.connection,
        }),
      );

      final tileImpact = plan.impacts.singleWhere(
        (impact) => impact.kind == MapResizeImpactKind.tileLayer,
      );
      expect(tileImpact.subjectId, 'ground');
      expect(tileImpact.affectedCount, 1);
      expect(tileImpact.positions, const <GridPos>[GridPos(x: 3, y: 3)]);

      final wideElementImpact = plan.impacts.singleWhere(
        (impact) =>
            impact.kind == MapResizeImpactKind.placedElement &&
            impact.subjectId == 'wide-house',
      );
      expect(
        wideElementImpact.reason,
        MapResizeImpactReason.footprintOutside,
      );
      expect(wideElementImpact.positions, contains(const GridPos(x: 2, y: 2)));

      final generatedReference = plan.impacts.singleWhere(
        (impact) =>
            impact.kind == MapResizeImpactKind.generatedPlacementReference,
      );
      expect(generatedReference.subjectId, 'forest');
      expect(generatedReference.relatedIds, const <String>['outside-tree']);

      final connectionImpact = plan.impacts.singleWhere(
        (impact) => impact.kind == MapResizeImpactKind.connection,
      );
      expect(
        connectionImpact.reason,
        MapResizeImpactReason.connectionTopologyChanged,
      );
    });

    test('turns Border clipping diagnostics into blocking impacts', () {
      final map = MapData(
        id: 'border-map',
        name: 'Border map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 3, height: 2),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border',
            name: 'Border',
            content: BorderLayerContent(
              features: <BorderFeature>[
                BorderFeature(
                  id: 'coast',
                  name: 'Coast',
                  blueprintId: 'coast-blueprint',
                  seed: BorderSignedInt64.zero,
                  geometry: BorderRegionGeometry(
                    width: 3,
                    height: 2,
                    cells: const <bool>[
                      false,
                      false,
                      true,
                      false,
                      false,
                      false,
                    ],
                  ),
                  overrides: const <BorderSlotOverride>[],
                  keepOutRegions: const <BorderKeepOutRegion>[],
                ),
              ],
            ),
          ),
        ],
      );

      final plan = planMapResize(
        map,
        width: 2,
        height: 2,
        tileSizePx: const GridSize(width: 16, height: 16),
      );

      expect(plan.canApply, isFalse);
      expect(
        plan.borderDiagnostics.diagnostics.map((value) => value.code),
        contains('region_cell_clipped'),
      );
      final impact = plan.impacts.singleWhere(
        (value) => value.kind == MapResizeImpactKind.borderLayer,
      );
      expect(impact.subjectId, 'coast');
      expect(impact.diagnosticCode, 'region_cell_clipped');
      expect(impact.affectedCount, 1);
    });

    test('keeps exact counts while bounding coordinate samples', () {
      final map = MapData(
        id: 'large-row',
        name: 'Large row',
        size: const GridSize(width: 20, height: 1),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            tiles: List<int>.filled(20, 1),
          ),
        ],
      );

      final plan = planMapResize(map, width: 1, height: 1);
      final impact = plan.impacts.single;

      expect(impact.affectedCount, 19);
      expect(impact.positions, hasLength(8));
      expect(impact.positions.first, const GridPos(x: 1, y: 0));
      expect(impact.positions.last, const GridPos(x: 8, y: 0));
    });

    test('fails closed when a Border layer has no project tile size', () {
      final map = MapData(
        id: 'border-map',
        name: 'Border map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 2, height: 2),
        layers: const <MapLayer>[
          MapLayer.border(id: 'border', name: 'Border'),
        ],
      );

      final plan = planMapResize(map, width: 3, height: 3);

      expect(plan.canApply, isFalse);
      expect(
        plan.impacts.single.reason,
        MapResizeImpactReason.missingContext,
      );
    });

    test('rejects non-positive target dimensions', () {
      expect(
        () => planMapResize(_emptyMap(), width: 0, height: 2),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _emptyMap() => const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 1, height: 1),
    );

MapData _compositeMap() => MapData(
      id: 'composite',
      name: 'Composite',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'ground',
          name: 'Ground',
          tiles: _cells<int>(0, const <GridPos>[GridPos(x: 3, y: 3)], 7),
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions:
              _cells<bool>(false, const <GridPos>[GridPos(x: 2, y: 0)], true),
        ),
        MapLayer.terrain(
          id: 'terrain',
          name: 'Terrain',
          terrains: _cells<TerrainType>(
            TerrainType.none,
            const <GridPos>[GridPos(x: 0, y: 3)],
            TerrainType.grass,
          ),
        ),
        MapLayer.path(
          id: 'path',
          name: 'Path',
          cells:
              _cells<bool>(false, const <GridPos>[GridPos(x: 3, y: 2)], true),
        ),
        const MapLayer.surface(
          id: 'surface',
          name: 'Surface',
          placements: <SurfaceCellPlacement>[
            SurfaceCellPlacement(
              x: 3,
              y: 0,
              surfacePresetId: 'grass',
            ),
          ],
        ),
        MapLayer.environment(
          id: 'environment',
          name: 'Environment',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'ground',
            areas: <EnvironmentArea>[
              EnvironmentArea(
                id: 'forest',
                name: 'Forest',
                presetId: 'forest-preset',
                mask: EnvironmentAreaMask(
                  width: 4,
                  height: 4,
                  cells: _cells<bool>(
                    false,
                    const <GridPos>[GridPos(x: 2, y: 1)],
                    true,
                  ),
                ),
                seed: 7,
                generatedPlacementIds: const <String>['outside-tree'],
              ),
            ],
          ),
        ),
      ],
      placedElements: const <MapPlacedElement>[
        MapPlacedElement(
          id: 'outside-tree',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 3, y: 3),
        ),
        MapPlacedElement(
          id: 'wide-house',
          layerId: 'ground',
          elementId: 'house',
          pos: GridPos(x: 1, y: 1),
        ),
      ],
      entities: const <MapEntity>[
        MapEntity(
          id: 'large-npc',
          name: 'Large NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
          npc: MapEntityNpcData(
            movement: MapEntityNpcMovementConfig(
              waypoints: <GridPos>[GridPos(x: 3, y: 1)],
            ),
          ),
        ),
      ],
      connections: const <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'north-map',
        ),
      ],
      warps: const <MapWarp>[
        MapWarp(
          id: 'outside-warp',
          pos: GridPos(x: 3, y: 0),
          targetMapId: 'other-map',
          targetPos: GridPos(x: 0, y: 0),
        ),
        MapWarp(
          id: 'self-warp',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'composite',
          targetPos: GridPos(x: 3, y: 3),
          triggerPadding: WarpTriggerPadding(right: 3),
        ),
      ],
      triggers: const <MapTrigger>[
        MapTrigger(
          id: 'trigger',
          name: 'Trigger',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 2, height: 2),
          ),
        ),
      ],
      gameplayZones: const <MapGameplayZone>[
        MapGameplayZone(
          id: 'zone',
          name: 'Zone',
          kind: GameplayZoneKind.special,
          area: MapRect(
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 2, height: 2),
          ),
          special: SpecialZonePayload(scriptKey: 'zone-script'),
        ),
      ],
      events: const <MapEventDefinition>[
        MapEventDefinition(
          id: 'event',
          title: 'Event',
          pages: <MapEventPage>[MapEventPage(pageNumber: 0)],
          position: EventPosition(layerId: 'ground', x: 3, y: 1),
        ),
      ],
    );

ProjectManifest _project() => const ProjectManifest(
      name: 'Resize project',
      version: ProjectVersion.v2,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
      elements: <ProjectElementEntry>[
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'nature',
          categoryId: 'nature',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0),
            ),
          ],
        ),
        ProjectElementEntry(
          id: 'house',
          name: 'House',
          tilesetId: 'buildings',
          categoryId: 'buildings',
          frames: <TilesetVisualFrame>[
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            ),
          ],
        ),
      ],
    );

List<T> _cells<T>(T empty, List<GridPos> positions, T value) {
  final cells = List<T>.filled(16, empty);
  for (final position in positions) {
    cells[position.y * 4 + position.x] = value;
  }
  return cells;
}
~~~~

</details>
<details>
<summary>Modale design system — <code>packages/map_editor/lib/src/ui/design_system/pokemap_resize_impact_dialog.dart</code></summary>

~~~~dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_diagnostic_callout.dart';
import 'pokemap_panel.dart';
import 'pokemap_section_header.dart';
import 'pokemap_text_field.dart';

const pokeMapResizeImpactDialogKey =
    ValueKey<String>('pokemap-resize-impact-dialog');
const pokeMapResizeWidthFieldKey =
    ValueKey<String>('pokemap-resize-width-field');
const pokeMapResizeHeightFieldKey =
    ValueKey<String>('pokemap-resize-height-field');
const pokeMapResizeApplyButtonKey =
    ValueKey<String>('pokemap-resize-apply-button');

typedef PokeMapResizePlanBuilder = MapResizePlan Function(
  int width,
  int height,
);

/// Validated target returned only after a loss-safe resize plan is applicable.
@immutable
final class PokeMapResizeTarget {
  const PokeMapResizeTarget({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokeMapResizeTarget &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Presents a live, fail-closed preview of every resize impact.
///
/// The modal never returns a destructive target. The application use case
/// still rebuilds the plan before mutation, so closing the dialog is not a
/// security or consistency boundary.
Future<PokeMapResizeTarget?> showPokeMapResizeImpactDialog(
  BuildContext context, {
  required int currentWidth,
  required int currentHeight,
  required PokeMapResizePlanBuilder buildPlan,
}) {
  final colors = context.pokeMapColors;
  return showGeneralDialog<PokeMapResizeTarget>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le redimensionnement de la carte',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _PokeMapResizeImpactDialog(
      currentWidth: currentWidth,
      currentHeight: currentHeight,
      buildPlan: buildPlan,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final class _PokeMapResizeImpactDialog extends StatefulWidget {
  const _PokeMapResizeImpactDialog({
    required this.currentWidth,
    required this.currentHeight,
    required this.buildPlan,
  });

  final int currentWidth;
  final int currentHeight;
  final PokeMapResizePlanBuilder buildPlan;

  @override
  State<_PokeMapResizeImpactDialog> createState() =>
      _PokeMapResizeImpactDialogState();
}

final class _PokeMapResizeImpactDialogState
    extends State<_PokeMapResizeImpactDialog> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  MapResizePlan? _plan;
  String? _widthError;
  String? _heightError;
  String? _planningError;
  Timer? _planDebounce;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.currentWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.currentHeight.toString(),
    );
    _rebuildPlan();
  }

  @override
  void dispose() {
    _planDebounce?.cancel();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _schedulePlanRebuild() {
    _planDebounce?.cancel();
    setState(() {
      _plan = null;
      _planningError = null;
    });
    _planDebounce = Timer(
      const Duration(milliseconds: 120),
      _rebuildPlan,
    );
  }

  void _submitCurrentTarget() {
    _planDebounce?.cancel();
    _rebuildPlan();
    _apply();
  }

  void _rebuildPlan() {
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    final widthError = width == null || width <= 0
        ? 'Utilisez un entier supérieur à 0.'
        : null;
    final heightError = height == null || height <= 0
        ? 'Utilisez un entier supérieur à 0.'
        : null;
    if (widthError != null || heightError != null) {
      setState(() {
        _widthError = widthError;
        _heightError = heightError;
        _planningError = null;
        _plan = null;
      });
      return;
    }

    try {
      final plan = widget.buildPlan(width!, height!);
      setState(() {
        _widthError = null;
        _heightError = null;
        _planningError = null;
        _plan = plan;
      });
    } on Object {
      setState(() {
        _widthError = null;
        _heightError = null;
        _planningError =
            'Le plan d’impact n’a pas pu être calculé. La carte reste intacte.';
        _plan = null;
      });
    }
  }

  void _apply() {
    final plan = _plan;
    if (plan == null || plan.isNoOp || !plan.canApply) return;
    Navigator.of(context).pop(
      PokeMapResizeTarget(
        width: plan.targetSize.width,
        height: plan.targetSize.height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(760.0, math.max(320.0, viewport.width - 48));
    final dialogHeight = math.min(760.0, math.max(420.0, viewport.height - 48));
    final plan = _plan;
    final canApply = plan != null && !plan.isNoOp && plan.canApply;

    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: pokeMapResizeImpactDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: 'Redimensionner la carte',
                explicitChildNodes: true,
                child: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: PokeMapPanel(
                    expandChild: true,
                    padding: EdgeInsets.zero,
                    header: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.aspect_ratio_rounded,
                            color: plan?.canApply == false
                                ? colors.error
                                : colors.mapAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Redimensionner la carte',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Taille actuelle : ${widget.currentWidth} × '
                                  '${widget.currentHeight} cases',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PokeMapButton(
                            onPressed: () => Navigator.of(context).pop(),
                            variant: PokeMapButtonVariant.secondary,
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          PokeMapButton(
                            key: pokeMapResizeApplyButtonKey,
                            onPressed: canApply ? _apply : null,
                            autofocus: canApply,
                            child: const Text('Appliquer'),
                          ),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: PokeMapTextField(
                                  label: 'Largeur (cases)',
                                  controller: _widthController,
                                  fieldKey: pokeMapResizeWidthFieldKey,
                                  errorText: _widthError,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => _schedulePlanRebuild(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PokeMapTextField(
                                  label: 'Hauteur (cases)',
                                  controller: _heightController,
                                  fieldKey: pokeMapResizeHeightFieldKey,
                                  errorText: _heightError,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => _schedulePlanRebuild(),
                                  onSubmitted: (_) => _submitCurrentTarget(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_planningError != null)
                            PokeMapDiagnosticCallout(
                              severity: PokeMapDiagnosticSeverity.error,
                              title: 'Prévisualisation indisponible',
                              message: _planningError!,
                            )
                          else if (plan != null)
                            _ResizePlanStatus(plan: plan),
                          if (plan != null && plan.impacts.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            PokeMapSectionHeader(
                              title: 'Objets concernés',
                              description:
                                  '${plan.impacts.length} impact${plan.impacts.length > 1 ? 's' : ''} à corriger avant de réduire la carte',
                            ),
                            const SizedBox(height: 4),
                            for (var index = 0;
                                index < plan.impacts.length;
                                index++) ...[
                              if (index > 0) const SizedBox(height: 8),
                              PokeMapDiagnosticCallout(
                                severity: PokeMapDiagnosticSeverity.warning,
                                title: plan.impacts[index].subjectLabel,
                                message:
                                    _resizeImpactMessage(plan.impacts[index]),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ResizePlanStatus extends StatelessWidget {
  const _ResizePlanStatus({required this.plan});

  final MapResizePlan plan;

  @override
  Widget build(BuildContext context) {
    if (plan.isNoOp) {
      return const PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Aucune modification',
        message: 'La taille cible est identique à la taille actuelle.',
      );
    }
    if (!plan.canApply) {
      final count = plan.impacts.length;
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.error,
        title: 'Redimensionnement bloqué',
        message: '$count impact${count > 1 ? 's' : ''} '
            'bloquant${count > 1 ? 's' : ''} détecté${count > 1 ? 's' : ''}. '
            'Corrigez ou déplacez les éléments listés ; aucune donnée ne sera '
            'supprimée automatiquement.',
      );
    }
    if (plan.isExpansion) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Aucune perte détectée',
        message: 'La carte sera agrandie à ${plan.targetSize.width} × '
            '${plan.targetSize.height} cases.',
      );
    }
    return PokeMapDiagnosticCallout(
      severity: PokeMapDiagnosticSeverity.info,
      title: 'Aucune perte détectée',
      message: 'Le contenu conservé tient entièrement dans '
          '${plan.targetSize.width} × ${plan.targetSize.height} cases.',
    );
  }
}

String _resizeImpactMessage(MapResizeImpact impact) {
  final count = impact.affectedCount;
  final cases = '$count case${count > 1 ? 's' : ''}';
  final detail = switch (impact.reason) {
    MapResizeImpactReason.clippedCells =>
      '$cases non vide${count > 1 ? 's' : ''} serait${count > 1 ? 'ent' : ''} supprimée${count > 1 ? 's' : ''}.',
    MapResizeImpactReason.positionOutside =>
      'Sa position sort de la nouvelle carte.',
    MapResizeImpactReason.footprintOutside =>
      '$cases de son emprise sort${count > 1 ? 'ent' : ''} de la nouvelle carte.',
    MapResizeImpactReason.footprintUnknown =>
      'Son emprise ne peut pas être résolue avec le manifeste actuel.',
    MapResizeImpactReason.areaOutside =>
      '$cases de sa zone sort${count > 1 ? 'ent' : ''} de la nouvelle carte.',
    MapResizeImpactReason.patrolWaypointOutside =>
      '$count point${count > 1 ? 's' : ''} de patrouille '
          'sort${count > 1 ? 'ent' : ''} de la nouvelle carte.',
    MapResizeImpactReason.localTargetOutside =>
      'Sa destination sur cette carte sort des nouvelles limites.',
    MapResizeImpactReason.triggerAreaClipped =>
      '$cases de sa zone d’activation deviendrai${count > 1 ? 'ent' : 't'} inaccessible${count > 1 ? 's' : ''}.',
    MapResizeImpactReason.danglingReference =>
      '$count référence${count > 1 ? 's' : ''} générée${count > 1 ? 's' : ''} deviendrai${count > 1 ? 'ent' : 't'} orpheline${count > 1 ? 's' : ''}.',
    MapResizeImpactReason.borderDiagnostic =>
      'La bordure serait modifiée de façon destructive'
          '${impact.diagnosticCode == null ? '.' : ' (${impact.diagnosticCode}).'}',
    MapResizeImpactReason.connectionTopologyChanged =>
      'Le bord source de la connexion changerait ; son alignement doit être revu.',
    MapResizeImpactReason.missingContext =>
      'Le contexte nécessaire à une prévisualisation sûre est indisponible.',
  };
  final coordinates = impact.positions.take(3).map(
        (position) => '(${position.x}, ${position.y})',
      );
  final coordinateSummary = coordinates.isEmpty
      ? ''
      : ' Positions : ${coordinates.join(', ')}'
          '${impact.positions.length > 3 ? ', …' : ''}.';
  return '$detail$coordinateSummary';
}
~~~~

</details>
<details>
<summary>Tests widget — <code>packages/map_editor/test/ui/design_system/pokemap_resize_impact_dialog_test.dart</code></summary>

~~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_resize_impact_dialog.dart';

void main() {
  testWidgets('starts as a no-op and applies a proven safe expansion',
      (tester) async {
    PokeMapResizeTarget? selected;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        selected = await showPokeMapResizeImpactDialog(
          context,
          currentWidth: 3,
          currentHeight: 3,
          buildPlan: _safePlan,
        );
      },
    );

    await tester.tap(find.text('Redimensionner'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapResizeImpactDialogKey), findsOneWidget);
    expect(find.text('Taille actuelle : 3 × 3 cases'), findsOneWidget);
    expect(find.text('Aucune modification'), findsOneWidget);
    expect(_applyButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(pokeMapResizeWidthFieldKey),
      '5',
    );
    await tester.enterText(
      find.byKey(pokeMapResizeHeightFieldKey),
      '4',
    );
    await _settlePlan(tester);

    expect(find.text('Aucune perte détectée'), findsOneWidget);
    expect(find.text('La carte sera agrandie à 5 × 4 cases.'), findsOneWidget);
    expect(_applyButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(pokeMapResizeApplyButtonKey));
    await tester.pumpAndSettle();

    expect(selected, const PokeMapResizeTarget(width: 5, height: 4));
    expect(find.byKey(pokeMapResizeImpactDialogKey), findsNothing);
  });

  testWidgets('lists destructive impacts and never exposes an override',
      (tester) async {
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapResizeImpactDialog(
        context,
        currentWidth: 3,
        currentHeight: 3,
        buildPlan: (width, height) => MapResizePlan(
          sourceSize: const GridSize(width: 3, height: 3),
          targetSize: GridSize(width: width, height: height),
          impacts: width < 3
              ? <MapResizeImpact>[
                  MapResizeImpact(
                    kind: MapResizeImpactKind.entity,
                    reason: MapResizeImpactReason.footprintOutside,
                    subjectId: 'house',
                    subjectLabel: 'Maison du joueur',
                    affectedCount: 2,
                    positions: const <GridPos>[
                      GridPos(x: 2, y: 1),
                      GridPos(x: 2, y: 2),
                    ],
                  ),
                ]
              : const <MapResizeImpact>[],
        ),
      ),
    );

    await tester.tap(find.text('Redimensionner'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(pokeMapResizeWidthFieldKey),
      '2',
    );
    await _settlePlan(tester);

    expect(find.text('Redimensionnement bloqué'), findsOneWidget);
    expect(find.textContaining('1 impact bloquant'), findsOneWidget);
    expect(find.text('Maison du joueur'), findsOneWidget);
    expect(find.textContaining('2 cases'), findsOneWidget);
    expect(_applyButton(tester).onPressed, isNull);
    expect(find.textContaining('Forcer'), findsNothing);
  });

  testWidgets('validates positive integer dimensions before planning',
      (tester) async {
    var planCalls = 0;
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapResizeImpactDialog(
        context,
        currentWidth: 3,
        currentHeight: 3,
        buildPlan: (width, height) {
          planCalls += 1;
          return _safePlan(width, height);
        },
      ),
    );

    await tester.tap(find.text('Redimensionner'));
    await tester.pumpAndSettle();
    final callsBeforeInvalidInput = planCalls;
    await tester.enterText(
      find.byKey(pokeMapResizeHeightFieldKey),
      '0',
    );
    await _settlePlan(tester);

    expect(
      find.text('Utilisez un entier supérieur à 0.'),
      findsOneWidget,
    );
    expect(planCalls, callsBeforeInvalidInput);
    expect(_applyButton(tester).onPressed, isNull);
  });
}

MapResizePlan _safePlan(int width, int height) => MapResizePlan(
      sourceSize: const GridSize(width: 3, height: 3),
      targetSize: GridSize(width: width, height: height),
      impacts: const <MapResizeImpact>[],
    );

PokeMapButton _applyButton(WidgetTester tester) => tester.widget<PokeMapButton>(
      find.byKey(pokeMapResizeApplyButtonKey),
    );

Future<void> _settlePlan(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pumpAndSettle();
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onLaunch(context),
            child: const Text('Redimensionner'),
          ),
        ),
      ),
    ),
  );
}
~~~~

</details>
