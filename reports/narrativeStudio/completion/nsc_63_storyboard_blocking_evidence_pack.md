# NSC-63 — Storyboard et blocking enrichis

Date : 2026-07-20

Statut proposé : **DONE**

## Audit initial

Le Cinematic Builder savait déjà éditer acteurs, points de scène, déplacements, caméra, transitions et timeline linéaire. Il manquait une lecture en plans, des diagnostics contextualisés par plan et un mécanisme de preset prévisualisable/atomique. L'état Git initial était propre après NSC-62 (`43710bae`).

## Verdict des passes

Aucun sub-agent n'a été lancé : l'instruction active interdit la délégation sans demande explicite.

1. Passe domaine : storyboard strictement dérivé, aucune seconde source de vérité — **GO**.
2. Passe authoring : cinq presets, validation préalable, IDs stables et application atomique — **GO**.
3. Passe UI : strip no-code, détails cadrage/acteurs/temps, diff confirmé avant écriture — **GO**.
4. Passe régression : la première intégration réduisait le stage ; elle a été remplacée par un volet superposé replié par défaut — **GO**.

Verdict cumulé : **GO**.

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_stage_panel_test.dart`

## Fichiers créés

- `packages/map_core/lib/src/read_models/cinematic_storyboard_read_model.dart`
- `packages/map_core/test/cinematic_storyboard_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/builder/cinematic_storyboard_strip.dart`
- `packages/map_editor/test/ui/canvas/cinematics/cinematic_storyboard_strip_test.dart`
- `reports/narrativeStudio/completion/nsc_63_storyboard_blocking_evidence_pack.md`

Le contenu complet des quatre fichiers source/test créés est versionné dans le même commit que cet Evidence Pack. Le présent fichier est lui-même intégralement reproduit par sa version Git ; aucun fichier généré ou binaire n'a été ajouté.

## Zones précises et décisions

- `buildCinematicStoryboardReadModel` segmente la timeline sur marker, caméra et fondu.
- Chaque plan expose lieu, cadrage, acteurs, début, durée, IDs des commandes et diagnostics.
- Les références acteur/cible/point/map supprimées restent lisibles et deviennent des diagnostics.
- Les presets `npcEntrance`, `dramaticArrival`, `cameraPan`, `fadeTransition` et `movingCrowd` produisent un diff avant application.
- `applyCinematicBlockingPresetToAsset` refuse un preview invalide ou obsolète et produit un seul nouvel asset.
- L'écriture projet conserve l'ancien projet comme undo exact ; aucune application partielle n'est possible.
- Le storyboard est replié par défaut au-dessus du stage pour préserver sa géométrie et toutes ses interactions historiques.
- Tous les composants de surface/action utilisent le design system et les tokens de thème.

## TDD

RED observé : read model, diagnostics et API de presets absents. Une première GREEN fonctionnelle a révélé une régression de hauteur du backdrop ; les tests historiques ont servi de seconde boucle RED/GREEN et imposé le volet superposé replié.

## Commandes et résultats exacts

```text
cd packages/map_core
dart test test/cinematic_storyboard_read_model_test.dart test/cinematic_authoring_operations_test.dart
+80: All tests passed!

dart analyze lib/src/read_models/cinematic_storyboard_read_model.dart lib/src/authoring/cinematic_authoring_operations.dart test/cinematic_storyboard_read_model_test.dart test/cinematic_authoring_operations_test.dart
No issues found!

cd packages/map_editor
flutter test --reporter compact test/cinematic_builder_workspace_test.dart test/ui/canvas/cinematics/cinematic_storyboard_strip_test.dart test/ui/canvas/cinematics/cinematic_stage_panel_test.dart
All tests passed! (code 0 ; sortie de progression tronquée par le transport)

flutter analyze lib/src/ui/canvas/cinematics/builder/cinematic_storyboard_strip.dart lib/src/ui/canvas/cinematics/builder/cinematic_stage_panel.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/ui/canvas/cinematics/cinematic_storyboard_strip_test.dart test/ui/canvas/cinematics/cinematic_stage_panel_test.dart
No issues found!

git diff --check
aucune sortie, code 0
```

## Non-objectifs

- Pas de branche narrative dans CinematicAsset.
- Pas de stockage d'un storyboard parallèle.
- Pas de média ou de nouveau kind runtime, réservés à NSC-65 à NSC-67.
- Pas de drag/reorder multi-sélection, réservé à NSC-64.

## Risques et auto-critique

Le découpage automatique prend caméra et fondu comme ruptures de plan ; les auteurs qui souhaitent regrouper plusieurs mouvements caméra dans un même plan doivent utiliser les markers avec soin. Le volet storyboard est volontairement replié pour ne pas masquer les contrôles du stage ; une future préférence d'affichage persistante pourra mémoriser son état. Les presets sélectionnent les premiers acteurs/points compatibles depuis le volet : le diff rend ce choix visible avant confirmation, mais un sélecteur avancé pourra ensuite offrir un sous-ensemble explicite.

## État Git

Avant lot : propre. Avant commit : uniquement les fichiers NSC-63 listés ci-dessus. Aucun changement utilisateur préexistant absorbé.
