# NS-SCENES-V1-136-bis — Cinematic Builder Legacy Widget Expectations Cleanup

## 1. Résumé exécutif

V1-136-bis est une maintenance de tests uniquement. Le lot réaligne les attentes widget legacy signalées par V1-136 avec l'UX no-code actuelle du Cinematic Builder et de la Cinematics Library.

Aucun code produit n'a été modifié. Aucun label technique n'a été réintroduit dans l'UI pour satisfaire les tests.

## 2. Verdict

`NS-SCENES-V1-136-bis : DONE`

`Cinematic Builder V1 : CLOSABLE SANS RÉSERVE DE TEST LEGACY BLOQUANTE`

## 3. Rappel V1-136

V1-136 avait conclu :

`Cinematic Builder V1 : CLOSABLE AVEC RÉSERVES NON BLOQUANTES`

La réserve concrète était limitée à 7 attentes widget historiques :

- 6 dans `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- 1 dans `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. Liste des 7 attentes legacy corrigées

1. `step_face` dans le test de probe souris local.
2. `step_face` dans le test de snap du probe souris local.
3. `step_camera` dans le test de navigation verticale clavier.
4. `step_camera_a` dans le test de tie-break par index.
5. `Statut` dans le test d'ajout de brouillon safe.
6. `Professor marche vers Centre scène en 1000 ms.` et sa variante renommée.
7. `Bloc authoring V0` dans le test Library.

## 5. Stratégie de correction

Les assertions ont été conservées significatives :

- sélection timeline vérifiée via `PokeMapCard.selected`;
- présence des cartes vérifiée par key stable `cinematic-builder-step-card-*`;
- absence d'IDs techniques visibles vérifiée avec `find.text(stepId), findsNothing`;
- résumé actorMove vérifié via le wording actuel `Professor → Centre scène`, destination, durée et mode;
- brouillon vérifié via `Bloc brouillon`, `Brouillon`, `marker`, sélection et mutation contrôlée du manifeste;
- Library vérifie toujours l'ajout du bloc `Attente`, le retour à la Library, `3 action(s)` et `1750 ms estimé(s)`.

## 6. Fichiers modifiés

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers créés :

- `reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_cinematic_builder_legacy_widget_expectations_cleanup.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_136_bis_evidence_pack.md`

## 7. Tests RED initiaux

Les deux suites complètes ont été relancées avant correction.

Builder :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:51 +285 -6: Some tests failed.
```

Library :

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:06 +20 -1: Some tests failed.
```

Les échecs reproduits correspondaient au périmètre V1-136 : attentes legacy sur IDs/libellés anciens.

## 8. Tests GREEN finaux

Tests ciblés Builder :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "sets a local timeline time probe from mouse interaction without changing selection|snaps local timeline time probe to block boundaries without changing selection|navigates selected timeline blocks vertically with local keyboard focus|uses step index as vertical navigation tie break|adds a safe draft after selected step and inspects it|polishes movement target labels and actor movement inspector"
00:06 +6: All tests passed!
```

Test ciblé Library :

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart --name "adds a basic block from builder and refreshes library summary"
00:03 +1: All tests passed!
```

Suites complètes :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:44 +291: All tests passed!
```

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:07 +21: All tests passed!
```

Régression récente :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-135|V1-134|V1-132|V1-129|V1-128|V1-124|V1-121|V1-120|V1-118|V1-117-bis|V1-116|V1-112|V1-108|V1-105|V1-102"
00:15 +73: All tests passed!
```

Analyse ciblée :

```text
flutter analyze --no-fatal-infos test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
23 issues found. (ran in 1.6s)
Exit code: 0
```

Les 23 issues sont des infos `prefer_const_*` préexistantes situées hors zones modifiées.

## 9. Anti-scope

Respecté :

- aucun fichier `packages/map_editor/lib/**`;
- aucun `map_core`;
- aucun runtime;
- aucun Flame;
- aucun GameState;
- aucun Selbrume;
- aucun asset;
- aucun pubspec;
- aucun screenshot;
- aucune Visual Gate;
- aucune feature;
- aucun commit.

## 10. Décision de fermeture

La réserve de tests legacy identifiée par V1-136 est levée.

Le Cinematic Builder V1 reste closable. V1-136-bis ne rouvre pas le produit et ne modifie que les attentes de test/documentation.

## 11. Prochain lot recommandé

`NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness / Selbrume Demo Content Plan`

V1-137 reste recommandé et non démarré.

## 12. Auto-critique finale

Le lot a volontairement préféré les assertions sur keys stables et libellés no-code plutôt que des phrases longues exactes. C'est plus robuste face aux petits ajustements UX, mais cela garde une dépendance forte aux keys widget du Builder. Cette dépendance est acceptable ici car les tests ciblent précisément la timeline et l'inspecteur, pas une API publique.

## Critique du prompt

Le prompt était bien cadré : il distinguait clairement dette de tests legacy et bug produit. Les échecs étaient effectivement des attentes legacy. Une modification produit aurait été moins honnête, car elle aurait réintroduit des informations techniques que l'UX actuelle cherche justement à masquer.

