# NS-SCENES-V1-76 — Cinematic Stage Map Source Catalog V0

## 1. Résumé exécutif

V1-76 construit le catalogue pur des sources map-aware pour les futures selections du Cinematic Builder.

Resultat livre :

- `CinematicStageMapSourceCatalog` dans `map_core` ;
- construction pure depuis `ProjectMapEntry? stageMap` et `MapData? mapData` ;
- projection de `MapData.entities` en sources entite ;
- projection de `MapData.events` en sources event ;
- labels no-code, ids techniques secondaires, `kindLabel`, `positionSummary` secondaire ;
- capabilities `canBindActor` / `canBeMovementTarget` ;
- statuts `missingStageMap`, `mapDataUnavailable`, `mapIdMismatch`, `available` ;
- diagnostics locaux du catalogue ;
- tests core + regressions core + tests editor cibles.

Phrase canonique respectee : V1-76 construit le catalogue des sources map-aware. V1-76 ne permet pas encore de les selectionner dans l'UI.

## 2. Gate 0

Commande executee depuis la racine :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie observee :

```text
/Users/karim/Project/pokemonProject
main
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
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
```

Interpretation : `git status`, `git diff --stat` et `git diff --name-only` etaient vides au Gate 0. Le workspace etait propre avant V1-76.

## 3. Fichiers lus

Fichiers d'instructions et rapports :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_75_cinematic_map_entity_event_source_audit_picker_prep_contract.md`
- rapports V1-72, V1-73, V1-74.

Fichiers core/editor lus :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/map_core.dart`
- tests core cinematics existants.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- tests editor Builder/Library.

## 4. Design Gate — Cinematic Stage Map Source Catalog V0

1. Decision V1-75 implementee : Option E, read model stage-aware pur depuis une `MapData` fiable.
2. Le catalogue vit en read model pur pour rester testable dans `map_core`, sans Flutter/editor/runtime.
3. Il ne charge pas `MapData` lui-meme pour ne pas coupler le core a un repository ou a `EditorNotifier`.
4. Fichier retenu : `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`.
5. Export public requis : oui, via `packages/map_core/lib/map_core.dart`, pour une future consommation editor propre.
6. Signature retenue : `buildCinematicStageMapSourceCatalog({required ProjectMapEntry? stageMap, required MapData? mapData})`.
7. Statuts retenus : `missingStageMap`, `mapDataUnavailable`, `mapIdMismatch`, `available`.
8. `missingStageMap` : aucune map stage selectionnee, listes vides, diagnostic `stageMapMissing`.
9. `mapDataUnavailable` : map stage connue, `MapData` absente, listes vides, diagnostic `stageMapDataUnavailable`.
10. `mapIdMismatch` : `mapData.id` different de `stageMap.id`, listes vides, diagnostic `stageMapDataIdMismatch`.
11. `available` : ids alignes, entities/events projetes.
12. Label `MapEntity` : `npc.displayName`, `sign.title`, `item.gameItemId`, `spawn.spawnKey`, `entity.name`, puis `entity.id`.
13. Label `MapEventDefinition` : `title`, puis `id`.
14. Id brut accepte seulement en fallback final quand aucun libelle metier n'existe.
15. `secondaryLabel` : `mapId:sourceId`.
16. `kindLabel` : mapping humain des enums `MapEntityKind` et `MapEventType`.
17. `positionSummary` : texte secondaire `Tuile x, y`, non authorable.
18. `canBindActor` : vrai pour une entite NPC (`kind == npc` ou payload `npc` present).
19. `canBeMovementTarget` entity : vrai car `MapEntity.pos` est requis dans le modele.
20. `canBeMovementTarget` event : vrai car `MapEventDefinition.position` est requis.
21. Les events ne bindent pas un acteur : ils sont des cibles/declencheurs, pas des acteurs cinematic.
22. Pas de coordonnees libres : `positionSummary` est une metadata de lecture.
23. Pas de fake refs : seules les sources venant de `MapData.entities/events` sont projetees.
24. `CinematicAsset.mapId` / `stageContext` preserves : aucun modele cinematic modifie.
25. `actorMove.targetId` preserve : aucun changement timeline.
26. Pas de picker actif : aucun fichier UI modifie.
27. Pas d'UI : aucune modification `map_editor`.
28. Pas de preview reelle : aucune integration preview.
29. Pas de runtime : aucun package runtime/gameplay/battle/examples touche.
30. Prochain lot recommande : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0`.

## 5. Scope réalisé

Code :

- ajout du read model pur ;
- ajout du test TDD catalogue ;
- export public dans `map_core.dart`.

Documentation :

- rapport V1-76 ;
- evidence pack V1-76 ;
- roadmaps mises a jour.

## 6. Contrat V1-75 implémenté

Le contrat V1-75 materialise est :

```text
ProjectManifest.maps = metadata / relativePath
MapData.entities = vraie source des entites
MapData.events = vraie source des events
CinematicStageMapSourceCatalog = projection pure consommable plus tard par le Builder
```

## 7. Modèle CinematicStageMapSourceCatalog

Le catalogue contient :

- `status`
- `stageMapId`
- `stageMapLabel`
- `stageMapRelativePath`
- `mapDataId`
- `entities`
- `events`
- `diagnostics`

Il expose aussi `entityById` et `eventById` pour les futurs pickers.

## 8. Statuts du catalogue

- `missingStageMap`
- `mapDataUnavailable`
- `mapIdMismatch`
- `available`

Tous les statuts sont testes.

## 9. Sources entités

Chaque source entite expose :

- `id`
- `label`
- `secondaryLabel`
- `kindLabel`
- `canBindActor`
- `canBeMovementTarget`
- `positionSummary`
- `diagnostics`

## 10. Sources events

Chaque source event expose :

- `id`
- `label`
- `secondaryLabel`
- `kindLabel`
- `canBindActor` toujours `false`
- `canBeMovementTarget`
- `positionSummary`
- `diagnostics`

## 11. Labels no-code

Les labels no-code sont testes pour NPC, sign et event avec title. Les fallbacks id sont testes pour entity custom sans nom et event sans title.

## 12. IDs secondaires discrets

`secondaryLabel` contient les ids techniques sous forme `mapId:sourceId`, et n'est jamais utilise comme label principal.

## 13. Capabilities canBindActor / canBeMovementTarget

- NPC : `canBindActor = true`.
- Entite non NPC : `canBindActor = false`.
- Event : `canBindActor = false`.
- Entites/events positionnes par le modele : `canBeMovementTarget = true`.

## 14. Diagnostics locaux du catalogue

Diagnostics ajoutes :

- `stageMapMissing`
- `stageMapDataUnavailable`
- `stageMapDataIdMismatch`
- `stageMapHasNoEntities`
- `stageMapHasNoEvents`
- `entityMissingLabelFallbackToId`
- `eventMissingTitleFallbackToId`

## 15. Relation avec ProjectManifest.maps

`ProjectMapEntry` fournit seulement `id`, `name`, `relativePath`, `groupId`, `role`, `sortOrder`. Le catalogue utilise `ProjectMapEntry` comme ancre metadata, pas comme source entities/events.

## 16. Relation avec MapData

`MapData.entities` et `MapData.events` sont les seules sources de contenu map-aware projetees.

## 17. Relation avec CinematicAsset.mapId / stageContext

Aucun changement `CinematicAsset`, `CinematicStageContext`, actor bindings, movement target bindings ou timeline.

## 18. Relation avec le futur Builder / V1-77

V1-77 pourra consommer ce catalogue pour activer :

- actor binding `mapEntity` ;
- movement target `mapEntity` ;
- movement target `mapEvent`.

## 19. Restrictions anti-picker / anti-preview / anti-runtime

Confirme :

- pas de picker actif ;
- pas de UI modifiee ;
- pas de preview reelle ;
- pas de runtime ;
- pas de pathfinding ;
- pas de donnees Selbrume.

## 20. Tests ajoutés ou modifiés

Ajout :

- `packages/map_core/test/cinematic_stage_map_source_catalog_test.dart`

## 21. Commandes exécutées

Commandes principales :

```bash
dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
dart format lib/src/read_models/cinematic_stage_map_source_catalog.dart lib/map_core.dart test/cinematic_stage_map_source_catalog_test.dart
dart test --reporter=compact test/cinematic_asset_test.dart
dart test --reporter=compact test/project_manifest_cinematics_test.dart
dart test --reporter=compact test/cinematic_authoring_operations_test.dart
dart test --reporter=compact test/cinematic_diagnostics_test.dart
dart analyze
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
flutter analyze
```

## 22. Résultats des tests

RED attendu :

```text
Failed to load "test/cinematic_stage_map_source_catalog_test.dart":
Error: Method not found: 'buildCinematicStageMapSourceCatalog'.
Error: Undefined name 'CinematicStageMapSourceCatalogStatus'.
Error: Undefined name 'CinematicStageMapSourceDiagnosticCode'.
Some tests failed.
```

GREEN :

```text
00:00 +7: All tests passed!
```

Regressions core :

```text
test/cinematic_asset_test.dart: 00:00 +8: All tests passed!
test/project_manifest_cinematics_test.dart: 00:00 +6: All tests passed!
test/cinematic_authoring_operations_test.dart: 00:00 +37: All tests passed!
test/cinematic_diagnostics_test.dart: 00:00 +24: All tests passed!
```

Regressions editor ciblees :

```text
test/cinematic_builder_workspace_test.dart: 00:17 +125: All tests passed!
test/cinematics_library_workspace_test.dart: 00:03 +12: All tests passed!
```

## 23. Analyze

`packages/map_core` :

```text
Analyzing map_core...
No issues found!
```

`packages/map_editor` :

```text
Analyzing map_editor...
344 issues found. (ran in 3.0s)
```

La sortie rouge editor est une dette preexistante hors lot, principalement autour de `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`. Aucun fichier `map_editor` n'a ete modifie par V1-76.

## 24. Checks anti-scope

Les checks anti-scope finaux sont reproduits dans l'evidence pack.

## 25. Fichiers créés

- `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`
- `packages/map_core/test/cinematic_stage_map_source_catalog_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_76_cinematic_stage_map_source_catalog_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_76_evidence_pack.md`

## 26. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 27. Roadmaps mises à jour

V1-76 est marque DONE. Le prochain lot recommande est :

```text
NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0
```

## 28. Limites connues

- pas de chargement async editor branche ;
- pas de picker actif ;
- pas d'UI ;
- pas de preview reelle ;
- pas de runtime ;
- `flutter analyze` editor reste rouge hors lot.

## 29. Non-objectifs confirmés

Tous les non-objectifs du prompt sont confirmes : aucun runtime, playback, pathfinding, UI picker, ID libre, JSON brut UI, `stageContext.mapId`, donnees Selbrume ou image IA.

## 30. Evidence Pack

Voir :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_76_evidence_pack.md
```

## 31. Auto-review critique

1. V1-76 a modifie `map_runtime` ? Non.
2. V1-76 a modifie `map_gameplay/map_battle/examples` ? Non.
3. V1-76 a modifie `PlayableMapGame` ? Non.
4. V1-76 a ajoute une preview reelle ? Non.
5. V1-76 a ajoute du playback ? Non.
6. V1-76 a ajoute `currentTimeMs/playbackTimeMs/isPlaying` ? Non.
7. V1-76 a ajoute pathfinding/collision/warp/spawn runtime ? Non.
8. V1-76 a ajoute des donnees Selbrume ? Non.
9. V1-76 a ajoute `stageContext.mapId` ? Non.
10. `CinematicAsset.mapId` reste l'ancre stage map unique ? Oui.
11. V1-76 a active un picker mapEntity ? Non.
12. V1-76 a active un picker mapEvent ? Non.
13. V1-76 a expose un ID libre ? Non.
14. V1-76 a expose du JSON brut ? Non.
15. Le catalogue est pur Dart ? Oui.
16. Le catalogue ne charge pas lui-meme MapData ? Oui.
17. Les entites viennent de `MapData.entities` ? Oui.
18. Les events viennent de `MapData.events` ? Oui.
19. Les labels no-code sont testes ? Oui.
20. Les IDs techniques sont secondaires ? Oui.
21. `canBindActor` est teste ? Oui.
22. `canBeMovementTarget` entity est teste ? Oui.
23. `canBeMovementTarget` event est teste ? Oui.
24. Les statuts missing/unavailable/mismatch/available sont testes ? Oui.
25. `map_core analyze` passe ? Oui.
26. L'Evidence Pack est complet sans placeholders ? Oui.
27. Prochain lot exact recommande : `NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0`.

## 32. Recommandation pour le prochain lot

`NS-SCENES-V1-77 — Cinematic Stage Map Entity/Event Pickers V0`

Objectif : brancher le catalogue V1-76 au Cinematic Builder pour activer les vrais pickers map-aware, sans ID libre, sans JSON brut, sans preview reelle et sans runtime.
