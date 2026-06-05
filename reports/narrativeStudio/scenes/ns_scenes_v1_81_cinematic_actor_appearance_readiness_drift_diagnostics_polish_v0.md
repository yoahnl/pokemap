# NS-SCENES-V1-81 — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0

## 1. Résumé exécutif

V1-81 est réalisé à la demande de Karim. Le Builder explique maintenant les apparences Character Library cassées ou incompatibles après V1-80, sans suppression silencieuse et sans preview réelle.

Le lot ajoute des messages humains, des actions explicites de nettoyage, une readiness `Apparences acteurs` plus précise, un résumé Library `apparence à corriger`, des tests widget et une Visual Gate Flutter.

## 2. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 15
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
fe619092 feat(narrative): add cinematic stage map context editor and diagnostics preview readiness polish v0 (NS-SCENES-V1-73-V1-74)
632e3747 feat(narrative): add cinematic stage map context core model v0 (NS-SCENES-V1-72)
e77212ff feat(narrative): add cinematic stage map context prep contract (NS-SCENES-V1-71)
edf3d1bd feat(narrative): add cinematic timeline duration validation diagnostics polish v0 (NS-SCENES-V1-70)
875404af feat(narrative): add cinematic timeline duration resize handles v0 (NS-SCENES-V1-69)
263233b4 feat(narrative): add cinematic timeline duration inspector editing v0 (NS-SCENES-V1-68)
c8bb19a2 feat(narrative): add cinematic timeline duration editing resize prep contract (NS-SCENES-V1-67)
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
```

## 3. Fichiers lus

`AGENTS.md`, `agent_rules.md`, les deux roadmaps Narrative Studio, les rapports V1-77/V1-79/V1-80, les modèles et diagnostics core cinéma, les workspaces Builder/Library/readiness editor, et les tests `cinematic_builder_workspace_test.dart` / `cinematics_library_workspace_test.dart`.

Recherches obligatoires exécutées : bindings d'apparence, libellés Apparence/Character Library, readiness, primitives design-system.

## 4. Design Gate — Cinematic Actor Appearance Readiness / Drift Diagnostics Polish V0

1. V1-80 fournit déjà le picker Character Library, la sélection/clear et les états empty/broken.
2. V1-79 fournit déjà les diagnostics core `actorAppearanceBinding*`, `cinematicOnlyCharacterMissing`, `characterLibraryUnavailable`, `characterAssetMissing*`.
3. Les messages trop techniques étaient les refs orphelines, le kind incompatible, le personnage absent et les assets incomplets.
4. Une ref character cassée s'affiche dans la section Apparence de l'acteur concerné.
5. Elle se corrige via `removeCinematicActorAppearanceBinding`.
6. Un actor kind incompatible affiche que l'acteur n'est plus en `Cinématique uniquement`.
7. Il se corrige par l'action explicite `Retirer l'apparence`.
8. Un acteur supprimé mais référencé s'affiche comme référence orpheline globale dans la section Acteurs.
9. Il se corrige via `Nettoyer la référence`.
10. Une Character Library vide affiche `La Character Library est vide.` et n'ouvre aucun panneau externe.
11. Un character sans tileset affiche un warning humain.
12. Un character sans données preview affiche dimensions ou animation idle manquantes.
13. La ligne readiness `Apparences acteurs` distingue OK, à compléter et à corriger.
14. Blocking : actor inconnu, character inconnu, kind incompatible.
15. Incomplete : aucun character choisi, library vide, sprite/dimensions/idle manquants.
16. Warning non bloquant : données preview futures incomplètes, sans bloquer l'édition du draft.
17. Le picker V1-80 est conservé pour `cinematicOnly`.
18. Les pickers V1-77 restent hors de cette logique et couverts par la suite builder.
19. Timeline/duration/resize/probe restent inchangés et testés.
20. La non-suppression automatique est prouvée par le test RED/GREEN qui garde la ref jusqu'au clic.
21. Les checks anti-characterId prouvent que `CinematicActorBinding` reste inchangé.
22. Aucun appel de mutation Character Library n'a été ajouté.
23. Pas de preview réelle : la capture reste `Aperçu sandbox`.
24. Pas de runtime : aucun fichier runtime ni symbole playback n'est modifié.
25. Visual Gate produite dans `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png`.
26. Prochain lot recommandé : `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.

## 5. Scope réalisé

Le scope est local au Builder, à la readiness editor et au résumé Library. Aucun nouveau modèle core, aucun helper source séparé, aucune mutation Character Library.

## 6. Problème UX après V1-80

Après V1-80, un utilisateur pouvait choisir un personnage puis se retrouver avec une ref devenue absente, incompatible ou orpheline. V1-81 rend ces cas lisibles et corrigeables.

## 7. Diagnostics apparence humanisés

Les codes techniques restent consommés par les diagnostics, mais le Builder et la readiness affichent des phrases comme `Cet acteur n’est plus en “Cinématique uniquement”.`, `La Character Library est vide.` ou `Une apparence référence un acteur supprimé.`

## 8. Ref character cassée

Une ref vers un `characterId` absent affiche un message humain et garde l'ID en secondaire. La correction reste explicite via clear, sans remplacement automatique.

## 9. Actor kind incompatible

Si une apparence existe mais que le binding acteur n'est plus `cinematicOnly`, le Builder affiche l'incompatibilité et propose `Retirer l’apparence`.

## 10. Actor supprimé / unknown actor

Les `actorAppearanceBindings` dont `actorId` n'existe plus dans `requiredActors` apparaissent comme `Référence orpheline` avec action `Nettoyer la référence`.

## 11. Character Library vide

Le Builder affiche `La Character Library est vide.` et `Crée un personnage dans la Character Library pour l’utiliser ici.` Aucun bouton de création n'est ajouté.

## 12. Character incomplet pour future preview

Les characters sans tileset, dimensions valides ou animation idle affichent des warnings humains. Ces warnings restent de la préparation preview, pas du rendu.

## 13. Readiness apparences acteurs

La readiness calcule `Apparences acteurs` en priorité avant les acteurs manquants : actor orphelin, kind incompatible, library vide, character absent, sprite/dimensions/idle incomplets, puis OK.

## 14. Actions de correction explicites

Actions ajoutées ou clarifiées : `Retirer la référence`, `Retirer l’apparence`, `Nettoyer la référence`. Elles appellent toutes le clear d'appearance binding et ne changent ni actor binding ni timeline.

## 15. Relation avec picker Character Library V1-80

Le picker reste disponible uniquement pour `cinematicOnly`. Les états inherited/player/mapEntity/unbound restent non éditables en V0.

## 16. Relation avec pickers map-aware V1-77

La suite Builder complète continue de couvrir actor mapEntity, movement target mapEntity et movement target mapEvent.

## 17. Relation avec timeline / duration / resize

Tests conservés et rejoués : timeline intacte, `durationMs` intact, duration editor, resize handle, probe, navigation clavier et transports disabled.

## 18. Relation avec preview sandbox

La preview reste une sandbox visuelle. Aucune horloge, aucun playback, aucun sprite rendering, aucun runtime.

## 19. Restrictions anti-runtime / anti-preview / anti-Character mutation

Checks anti-scope exécutés : pas de symboles playback/runtime ajoutés, pas de `currentTimeMs`, pas de `Ticker`, pas de `AnimationController`, pas de mutation Character Library, pas de `stageContext.mapId`, pas d'image IA.

## 20. Design system

L'UI ajoutée réutilise les composants et helpers existants : `_KeyValue`, `_MutedText`, `PokeMapButton`, readiness items et tokens existants. Aucun `Color(0x...)` ni `Colors.*` ajouté.

## 21. Tests ajoutés ou modifiés

Tests clés :

- `shows incompatible character appearance drift when actor is no longer cinematic only`
- `shows orphan actor appearance binding and cleans it explicitly`
- extensions readiness pour character absent, kind incompatible, actor orphelin, sprite manquant et idle manquante
- `shows preview summary for actor appearance drift`
- Visual Gate `captures V1-81 cinematic actor appearance drift diagnostics polish when requested`

## 22. Visual Gate

Capture générée :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  243866 Jun  5 18:01 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
e958dfd44a0ed345df1ee356d0d1c08c0d7d0a505684dcc17652038cd048da11
```

## 23. Commandes exécutées

Toutes les commandes attendues ont été exécutées : core tests/analyze, editor tests ciblés, Visual Gate, analyze ciblée, analyze globale editor, checks anti-scope et commandes Git finales.

## 24. Résultats des tests

Core :

```text
dart test --reporter=compact test/cinematic_asset_test.dart
00:00 +14: All tests passed!

dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:00 +9: All tests passed!

dart test --reporter=compact test/cinematic_authoring_operations_test.dart
00:00 +47: All tests passed!

dart test --reporter=compact test/cinematic_diagnostics_test.dart
00:00 +34: All tests passed!
```

Editor :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows incompatible character appearance drift when actor is no longer cinematic only'
00:02 +1: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:18 +138: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:04 +14: All tests passed!

flutter test --update-goldens --dart-define=NS_SCENES_V1_81_CAPTURE_CINEMATIC_ACTOR_APPEARANCE_DRIFT=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:17 +138: All tests passed!
```

## 25. Analyze

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter analyze --no-fatal-infos ...
Analyzing 6 items...
No issues found! (ran in 2.1s)
```

Analyse globale editor :

```text
cd packages/map_editor && flutter analyze
344 issues found. (ran in 3.2s)
```

Rouge hors lot : erreurs préexistantes dans `pokemon_sdk_move_catalog_converter.dart` / `sync_pokemon_sdk_moves_catalog_use_case.dart` et infos/lints dispersés. Les fichiers V1-81 passent l'analyse ciblée.

## 26. Checks anti-scope

Résultat : aucun fichier core/runtime/gameplay/battle/examples/selbrume modifié. Les recherches exactes runtime/playback/characterId/Character Library mutation/couleurs/image IA/Selbrume sont vides, sauf faux positifs historiques documentés dans l'Evidence Pack (`freeX`, tests négatifs `stageContext.mapId`).

## 27. Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_81_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_81_cinematic_actor_appearance_readiness_drift_diagnostics_polish_v0.png`

## 28. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 29. Roadmaps mises à jour

Les deux roadmaps passent V1-81 en DONE et recommandent `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.

## 30. Limites connues

La Visual Gate montre le polish de drift, mais la preview reste une sandbox. Le bouton de correction est testé et présent ; le rendu réel des acteurs reste explicitement hors lot.

## 31. Non-objectifs confirmés

Pas de runtime, pas de preview réelle, pas de playback, pas de pathfinding, pas de mutation Character Library, pas de données Selbrume, pas de `gpt-image-2`.

## 32. Evidence Pack

Annexe créée : `reports/narrativeStudio/scenes/ns_scenes_v1_81_evidence_pack.md`. Elle contient les sorties Gate 0, RED/GREEN, Visual Gate, checks anti-scope et le code généré sous forme de hunks.

## 33. Auto-review critique

1. map_core modifié ? Non.
2. map_runtime modifié ? Non.
3. map_gameplay/map_battle/examples modifiés ? Non.
4. CharacterLibraryPanel modifié ? Non.
5. ProjectCharacterEntry créé/édité/supprimé ? Non.
6. Preview réelle ajoutée ? Non.
7. Playback ajouté ? Non.
8. `currentTimeMs`/`playbackTimeMs`/`isPlaying` ajoutés ? Non.
9. Pathfinding/collision/warp/spawn runtime ajoutés ? Non.
10. Données Selbrume ajoutées ? Non.
11. `characterId` ajouté dans `CinematicActorBinding` ? Non.
12. `characterId` ajouté dans `requiredActors` ? Non.
13. `stageContext.mapId` ajouté ? Non.
14. Refs character cassées visibles ? Oui.
15. Refs character cassées corrigeables explicitement ? Oui.
16. Actor kind incompatible expliqué ? Oui.
17. Actor kind incompatible corrigé sans mutation automatique ? Oui.
18. Character Library vide expliqué ? Oui.
19. Character incomplet expliqué ? Oui.
20. Readiness apparences mise à jour ? Oui.
21. Picker Character Library V1-80 encore fonctionnel ? Oui.
22. Pickers mapEntity/mapEvent V1-77 encore fonctionnels ? Oui.
23. `timeline.steps` préservé ? Oui.
24. `durationMs` préservé ? Oui.
25. Duration editor et resize encore fonctionnels ? Oui.
26. Transports disabled ? Oui.
27. Visual Gate prouve le drift polish ? Oui.
28. Evidence Pack sans placeholders ? Oui.
29. Prochain lot recommandé ? `NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.

## 34. Recommandation pour le prochain lot

`NS-SCENES-V1-82 — Cinematic Map Backdrop Preview Prep Contract`.

