# NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0

## 1. Resume executif

V1-91 construit la projection testable des acteurs. V1-91 ne rend toujours aucun acteur dans l interface.

Le lot ajoute dans `map_core` un read model pur `CinematicActorDisplayPreviewModel` et son builder. Il couvre l inventaire `requiredActors`, les bindings player/mapEntity/cinematicOnly/unbound, les positions initiales explicites, les apparences Character Library/player/mapEntity, les directions statiques issues de `actorFace`, les render hints abstraits et les diagnostics locaux.

## 2. Gate 0

Commande executee au depart :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie utile observee :

```text
/Users/karim/Project/pokemonProject
main
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides au Gate 0.

## 3. Fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/geometry.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_core/test/cinematic_stage_map_source_catalog_test.dart`
- `packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 4. Synthese des sub-agents et arbitrages

- A / Core Model Design : style map_core confirme (`@immutable`, `final class`, listes unmodifiable, builder pur), sources canoniques et risque principal de confondre read model et renderer.
- B / Actor Sources : `requiredActors.actorId` est canonique ; ne jamais resoudre depuis `CinematicActorRef.entityId`; orphelins et doublons a diagnostiquer en first-wins.
- C / Position : `fromMapEntity` lit `CinematicActorBinding.mapEntityId -> MapData.entities.pos`; `fromMovementTarget` lit `movementTargetBindings` vers entity/event; `abstractPoint`, `target_center`, `target_exit` ne portent aucune coordonnee implicite.
- D / Appearance : player via `ProjectSettings.defaultPlayerCharacterId`, mapEntity via `MapEntityNpcData.characterId` puis trainer fallback, cinematicOnly via `actorAppearanceBindings`; tileset/idle purement metadata.
- E / Direction : premier `actorFace` lu en data-only via `metadata['actor.direction']`; mapping up/down/left/right vers north/south/west/east; `actorMove` ignore.
- F / Tests / Anti-scope : tests read model compacts + checks anti imports/runtime/playback/renderer/fake position ; evidence pack avec code complet.

Arbitrage retenu : suivre le prompt final avec un builder recevant `ProjectManifest`, pour garder les apparences player/mapEntity/cinematicOnly resolubles sans eparpiller le contrat en listes separees.

## 5. Design Gate — Cinematic Actor Display Preview Read Model V0

- 1. Quel contrat V1-90 est implemente ? Option C : un read model pur precede tout renderer actor display.
- 2. Pourquoi le read model vit-il dans map_core ? Il projette des donnees projet/cinematic sans UI, asset image, runtime ni etat editor.
- 3. Pourquoi ne pas coder le renderer maintenant ? V1-91 doit rendre les acteurs projetables/testables avant de les dessiner.
- 4. Pourquoi ne pas charger de sprite maintenant ? Le chargement image appartient au futur renderer editor-only, pas a map_core.
- 5. Quelle signature de builder est retenue ? `buildCinematicActorDisplayPreviewModel({cinematic, project, stageMap, mapData, stageMapSourceCatalog})`.
- 6. Comment requiredActors est-il utilise ? Inventaire canonique, ordre stable, doublons first-wins diagnostiques.
- 7. Comment actorBindings est-il utilise ? Source logique player/mapEntity/cinematicOnly/unbound ; manquants/orphelins/duplicates diagnostiques.
- 8. Comment actorAppearanceBindings est-il utilise ? Uniquement pour cinematicOnly afin de pointer vers Character Library.
- 9. Comment initialPlacements est-il utilise ? Source unique de position initiale ; absent = missingInitialPlacement.
- 10. Comment movementTargetBindings est-il utilise ? Resolution des placements fromMovementTarget vers mapEntity/mapEvent/abstractPoint.
- 11. Comment player est-il represente ? Binding logique player, apparence via defaultPlayerCharacterId, aucune GameState.
- 12. Comment mapEntity est-il represente ? Binding mapEntity vers `MapData.entities`, position et apparence NPC/trainer.
- 13. Comment cinematicOnly est-il represente ? Acteur authoring-only avec placement explicite et appearance binding Character Library.
- 14. Comment unbound est-il represente ? Non-renderable, position unbound, appearance notRequired, renderHint hidden.
- 15. Comment les bindings orphelins sont-ils diagnostiques ? `actorDisplayOrphanBinding` warning.
- 16. Comment les placements orphelins sont-ils diagnostiques ? `actorDisplayOrphanPlacement` warning.
- 17. Comment les appearances orphelines sont-elles diagnostiquees ? `actorDisplayOrphanAppearance` warning.
- 18. Comment fromMapEntity est-il resolu ? Depuis binding mapEntity -> entity id -> `MapData.entities.pos`.
- 19. Comment fromMovementTarget est-il resolu ? Depuis targetId -> movementTargetBinding -> entity/event coordinates.
- 20. Comment abstractPoint est-il traite ? Status `abstractOnly`, aucune coordonnee.
- 21. Comment target_center / target_exit sont-ils traites ? Comme ids ordinaires ; sans binding, aucune coordonnee.
- 22. Comment eviter le centre map implicite ? Aucun fallback numerique ; missing placement/source garde x/y null.
- 23. Comment eviter GameState ? Le builder ne prend aucun etat runtime et ne lit que ProjectManifest/MapData.
- 24. Comment les apparences Character Library sont-elles resolues ? Lookup `ProjectCharacterEntry` puis tileset present et idle exploitable.
- 25. Comment missing tileset / missing idle sont-ils diagnostiques ? `actorDisplayCharacterMissingTileset` et `actorDisplayCharacterMissingIdleAnimation`.
- 26. Comment actorFace est-il utilise comme direction hint ? Premier step actorFace de l acteur, `actor.direction` mappe vers direction preview.
- 27. Comment actorMove est-il ignore ? Les steps actorMove ne sont jamais lus par la resolution position/direction.
- 28. Comment garantir aucun Flutter/Flame/runtime ? Imports limites a meta + modeles map_core ; rg anti-scope vide.
- 29. Quels tests prouvent la purete ? Test source scan + commandes rg anti Flutter/runtime/playback/renderer.
- 30. Quel prochain lot exact est recommande ? NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0.

## 6. Scope realise

- Nouveau read model pur dans `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`.
- Nouveau test TDD dans `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`.
- Export public dans `packages/map_core/lib/map_core.dart`.
- Roadmaps V1 mises a jour : V1-91 DONE, V1-92 renderer recommande, V1-93 scroll polish repousse.

## 7. Contrat V1-90 implemente

V1-90 demandait un read model avant renderer. V1-91 materialise ce contrat sans UI, sans runtime, sans sprite charge, sans playback, sans position inventee et sans simulation `actorMove`.

## 8. Modele CinematicActorDisplayPreviewModel

Le modele expose `status`, `summary`, `actors`, `diagnostics`, `renderableActorCount` et `actorById`. Chaque acteur expose binding, position, appearance, direction, renderHint et diagnostics locaux.

## 9. Builder pur

Signature retenue :

```dart
CinematicActorDisplayPreviewModel buildCinematicActorDisplayPreviewModel({
  required CinematicAsset cinematic,
  required ProjectManifest project,
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
})
```

## 10. Inventaire acteurs

`CinematicAsset.requiredActors` est l inventaire canonique. Les doublons sont first-wins et diagnostiques, les bindings/placements/appearances hors inventaire sont orphelins.

## 11. Resolution bindings

- `player` : logique auteur, sans GameState.
- `mapEntity` : `mapEntityId` vers `MapData.entities`.
- `cinematicOnly` : acteur authoring-only avec appearance binding.
- `unbound` : non-renderable volontaire.
- binding manquant : diagnostic warning.

## 12. Resolution positions

- `fromMapEntity` : lit la position reelle de `MapData.entities`.
- `fromMovementTarget` : lit `movementTargetBindings` vers mapEntity/mapEvent.
- `abstractPoint` : `abstractOnly`, x/y null.
- missing placement/source : aucun centre implicite.
- out-of-bounds : diagnostic warning.

## 13. Resolution apparences

- player : `ProjectSettings.defaultPlayerCharacterId`.
- cinematicOnly : `CinematicActorAppearanceBinding.characterId`.
- mapEntity : `MapEntityNpcData.characterId`, puis `trainerId -> ProjectTrainerEntry.characterId`, puis placeholder si seulement visualElement.
- Character Library : character present, tileset existant, idle exploitable.

## 14. Direction static hints

Le premier `actorFace` explicite de l acteur est lu comme hint statique. `actorMove` est ignore. Fallback : facing NPC puis south.

## 15. Render hints abstraits

`sprite`, `placeholder`, `hidden`, `missing`. Aucun sprite reel n est charge.

## 16. Diagnostics locaux

Diagnostics locaux `CinematicActorDisplayPreviewDiagnostic` avec severites info/warning/error et codes dedies actor display.

## 17. Cas non resolus / fallbacks

`target_center`, `target_exit`, missing placement et abstractPoint ne creent aucune coordonnee. Player sans default character et mapEntity sans character restent placeholder/incomplete.

## 18. Purete map_core / anti-UI / anti-runtime

Imports du read model : `meta`, modeles `map_core`, source catalog. Aucun import Flutter, dart:ui, Flame, runtime, editor ou image.

## 19. Tests ajoutes ou modifies

- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart` avec 25 tests.

## 20. Commandes executees

- `dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart` dans `packages/map_core`
- `dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart` dans `packages/map_core`
- `dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart` dans `packages/map_core`
- `dart test --reporter=compact test/cinematic_asset_test.dart` dans `packages/map_core`
- `dart test --reporter=compact test/project_manifest_cinematics_test.dart` dans `packages/map_core`
- `dart analyze` dans `packages/map_core`
- `set -o pipefail; dart test --reporter=compact 2>&1 | tail -n 1` dans `packages/map_core`
- `git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume` depuis la racine
- `rg -n "package:flutter|dart:ui|ui\.Image|Canvas|CustomPainter|Widget|BuildContext|package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime|map_editor" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true` depuis la racine
- `rg -n "startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\(|Ticker|AnimationController|seek|scrub|scrubber" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true` depuis la racine
- `rg -n "drawActor|renderActor|ActorSprite|CharacterSprite|spritePainter|actorRenderer|ImageProvider|Sprite|drawImageRect" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true` depuis la racine
- `rg -n "center.*map|map.*center|fallback.*center|default.*position|0\.5.*width|0\.5.*height|positionSummary" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true` depuis la racine
- `rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true` depuis la racine
- `rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true` depuis la racine
- `git diff --check` depuis la racine
- `git diff --stat` depuis la racine
- `git diff --name-only` depuis la racine
- `git status --short --untracked-files=all` depuis la racine

## 21. Resultats des tests

Tous les tests cibles et la suite complete map_core sont verts. Voir l Evidence Pack pour les sorties.

## 22. Analyze

`dart analyze` dans `packages/map_core` : `No issues found!`

## 23. Checks anti-scope

Checks anti packages hors lot, anti Flutter/runtime, anti playback, anti renderer actor, anti fake position, anti donnees projet specifiques et anti image IA executes. Voir l Evidence Pack.

## 24. Fichiers crees

- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_91_evidence_pack.md`

## 25. Fichiers modifies

- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 26. Roadmaps mises a jour

V1-91 est DONE. V1-92 est maintenant `Cinematic Actor Display Preview Renderer V0`. Le polish timeline scroll/visibility est repousse en V1-93.

## 27. Limites connues

Aucun acteur n est dessine. Le futur renderer devra brancher ce read model au Builder, resoudre/afficher placeholders ou sprites editor-only, et produire une preuve visuelle.

## 28. Non-objectifs confirmes

Pas de UI editor, pas de renderer, pas de sprite charge, pas de runtime, pas de Flame, pas de GameState, pas de playback, pas de pathfinding/collision, pas de donnees de projet hardcodees, pas d image IA.

## 29. Evidence Pack

Voir `reports/narrativeStudio/scenes/ns_scenes_v1_91_evidence_pack.md`.

## 30. Auto-review critique

- 1. Est-ce que V1-91 a modifie map_editor ? Non.
- 2. Est-ce que V1-91 a modifie map_runtime ? Non.
- 3. Est-ce que V1-91 a modifie map_gameplay/map_battle/examples ? Non.
- 4. Est-ce que V1-91 a modifie selbrume ? Non.
- 5. Est-ce que V1-91 a importe Flutter ? Non.
- 6. Est-ce que V1-91 a importe dart:ui ? Non.
- 7. Est-ce que V1-91 a importe Flame ? Non.
- 8. Est-ce que V1-91 a importe map_runtime ? Non.
- 9. Est-ce que V1-91 a utilise GameState ? Non.
- 10. Est-ce que V1-91 a ajoute une UI ? Non.
- 11. Est-ce que V1-91 a rendu un acteur ? Non.
- 12. Est-ce que V1-91 a charge un sprite ? Non.
- 13. Est-ce que V1-91 a ajoute du playback ? Non.
- 14. Est-ce que V1-91 a ajoute currentTimeMs/playbackTimeMs/isPlaying ? Non.
- 15. Est-ce que requiredActors reste l inventaire canonique ? Oui.
- 16. Est-ce que les bindings orphelins sont diagnostiques ? Oui.
- 17. Est-ce que les placements orphelins sont diagnostiques ? Oui.
- 18. Est-ce que les appearances orphelines sont diagnostiquees ? Oui.
- 19. Est-ce que fromMapEntity est teste ? Oui.
- 20. Est-ce que fromMovementTarget mapEntity est teste ? Oui.
- 21. Est-ce que fromMovementTarget mapEvent est teste ? Oui.
- 22. Est-ce que abstractPoint est teste sans coordonnee inventee ? Oui.
- 23. Est-ce que missing placement n invente pas le centre de map ? Oui.
- 24. Est-ce que actorMove est ignore pour la position initiale ? Oui.
- 25. Est-ce que actorFace est utilise seulement comme direction hint ? Oui.
- 26. Est-ce que Character Library missing/tileset/idle est teste ? Oui.
- 27. Est-ce que map_core analyze passe ? Oui, No issues found.
- 28. Est-ce que l Evidence Pack est complet sans placeholders ? Oui : code source complet inclus et sorties commande capturees.
- 29. Quel est le prochain lot exact recommande ? NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0.

## 31. Recommandation pour le prochain lot

`NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`

Objectif : brancher le read model V1-91 dans le Cinematic Builder pour afficher des acteurs statiques sous forme de placeholders ou sprites si les assets sont resolus, par-dessus le decor V1-89, sans playback, sans actorMove interpolation, sans runtime et sans Flame.
