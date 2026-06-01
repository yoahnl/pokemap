# NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0

## 1. Résumé exécutif

Le lot `NS-SCENES-V1-46` est réalisé comme brique timeline-first stricte : les `CinematicAsset` canoniques peuvent maintenant déclarer des acteurs requis, le Cinematic Builder peut ajouter un acteur minimal, créer un bloc `actorFace`, choisir l'acteur depuis `requiredActors` et choisir une direction bornée `up/down/left/right`.

Le lot ne donne pas de déplacement aux acteurs : aucun `actorMove`, aucune position cible, aucun pathfinding, aucun runtime cinematic, aucune preview jouable et aucune timeline multi-pistes complète.

## 2. Gate 0

Commandes exécutées avant modification depuis `/Users/karim/Project/pokemonProject` :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all

git diff --stat

git diff --name-only

git log --oneline -n 15
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
```

Le working tree était propre.

## 3. Fichiers lus

Fichiers d'instructions et de cadrage :

```text
AGENTS.md
agent_rules.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md
reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_45_bis_cinematic_wait_fade_camera_basic_blocks_evidence_closure.md
```

Fichiers core audités :

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/cinematics_library_read_model_test.dart
```

Fichiers editor audités :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## 4. Design Gate — Cinematic Actor References / Actor Facing V0

1. `CinematicActorRef` est un modèle core avec `actorId` requis et champs optionnels `label`, `entityId`, `role`.
2. `requiredActors` est stocké dans `CinematicAsset` sous forme de liste immuable sérialisée JSON.
3. `actorId` existe déjà sur `CinematicTimelineStep`.
4. `actorFace` existe déjà dans `CinematicTimelineStepKind`.
5. Aucune convention de direction cinematic authoring n'existait.
6. Oui : `CinematicTimelineActorFacingDirection` a été ajoutée dans `cinematic_authoring_operations.dart`.
7. Un bloc `actorFace` authoring-owned est identifié par `kind=actorFace`, `authoring.source=cinematic-builder-v0`, `authoring.kind=basicBlock`, `authoring.block=actorFace`.
8. Oui, le modèle permet un acteur requis minimal sans migration.
9. L'opération pure est `addCinematicRequiredActor`.
10. Sans objet : la création minimale est implémentée.
11. Le Builder désactive la création `actorFace` si `requiredActors` est vide et affiche `Ajoutez d'abord un acteur requis`.
12. Le picker acteur est construit uniquement depuis `asset.requiredActors`; aucun champ ID libre n'est exposé.
13. La timeline affiche un badge `Acteur: <label>` et un badge direction pour `actorFace`.
14. L'inspecteur expose des boutons acteur et direction, pas de `TextField`.
15. `Déplacement acteur` reste dans la palette verrouillée et aucune opération `actorMove` n'est ajoutée.
16. Les opérations core refusent un `actorId` inconnu; les diagnostics signalent aussi les refs inconnues.
17. Les diagnostics existants du Builder restent surfacés dans la timeline et l'inspecteur; `cinematicUnknownActorRef` complète le core.
18. Il n'y a pas de preview runtime car V1-46 est authoring-only et ne modifie pas `map_runtime`.
19. Il n'y a pas de multi-track editor complet car le lot ne pose qu'un lane hint acteur dans une timeline linéaire.
20. Les tests core/editor ciblés prouvent add/update/remove, diagnostics, widgets Builder et refresh Library.
21. La Visual Gate est `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png`.

## 5. Scope réalisé

- Acteurs requis visibles dans le Builder.
- Ajout d'un acteur requis minimal avec id stable.
- Bloc `Orientation acteur` activé si un acteur existe.
- Step `actorFace` authoring-owned ajouté après la sélection courante.
- Picker acteur depuis `requiredActors`.
- Direction bornée `Haut`, `Bas`, `Gauche`, `Droite`.
- Timeline avec acteur et direction.
- Inspecteur avec actor picker, direction controls, metadata et suppression protégée.
- Diagnostic core pour actorId inconnu.
- Roadmaps et capture mises à jour.

## 6. Contrat acteur V0

`addCinematicRequiredActor` prend un `ProjectManifest` et un `cinematicId`, refuse un label vide, génère `actor`, puis `actor_2`, `actor_3`, préserve timeline/metadata/autres assets et retourne `updatedProject`, `cinematic`, `actor`.

Le Builder ne demande pas à l'utilisateur de taper un ID : l'action crée un acteur minimal `Acteur` et l'affiche ensuite comme badge/picker.

## 7. Contrat Actor Facing V0

`addCinematicTimelineActorFacingStep` crée un step :

```text
kind = actorFace
id = step_actor_face, step_actor_face_2, ...
label = Orientation <label acteur>
actorId = acteur requis existant
targetId = null
dialogueText = null
assetRef = null
metadata authoring.source = cinematic-builder-v0
metadata authoring.kind = basicBlock
metadata authoring.block = actorFace
metadata actor.direction = up|down|left|right
```

`updateCinematicTimelineActorFacingStep` modifie uniquement `actorId` et/ou `actor.direction`, et seulement pour un step authoring-owned `actorFace`.

## 8. Opérations core ajoutées ou réutilisées

Ajouts dans `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` :

```text
CinematicRequiredActorResult
CinematicTimelineActorFacingDirection
cinematicTimelineActorDirectionMetadataKey
cinematicTimelineActorFaceBlockMetadataValue
addCinematicRequiredActor
addCinematicTimelineActorFacingStep
updateCinematicTimelineActorFacingStep
isCinematicTimelineActorFacingStep
cinematicTimelineActorFacingDirectionOf
```

Réutilisé :

```text
removeCinematicTimelineAuthoringStep
isCinematicTimelineAuthoringStep
```

`isCinematicTimelineAuthoringStep` accepte désormais `actorFace` uniquement si les metadata authoring correspondent.

## 9. Diagnostics acteur

Ajout de `CinematicDiagnosticCode.cinematicUnknownActorRef`.

`diagnoseCinematicAsset` construit l'ensemble des `requiredActors.actorId` puis signale une erreur si un `CinematicTimelineStep.actorId` pointe vers un acteur absent. Un `actorFace` valide ne produit pas de diagnostic gameplay.

## 10. Mutation ProjectManifest côté editor

`packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` ajoute trois callbacks :

```text
_addCinematicRequiredActor
_addCinematicTimelineActorFacing
_updateCinematicTimelineActorFacing
```

Chaque callback appelle une opération pure `map_core`, puis applique le manifest en mémoire via `editorNotifier.applyInMemoryProjectManifest`.

## 11. UI Palette

La palette garde `Attente`, `Fondu`, `Caméra` actifs. Elle ajoute :

```text
Acteurs requis
Ajouter acteur
Orientation acteur
```

`Orientation acteur` est disabled si aucun acteur requis n'existe et affiche le message `Ajoutez d'abord un acteur requis`. `Déplacement acteur`, `Dialogue`, `FX` et `Son` restent verrouillés.

## 12. UI Actor Picker

L'inspecteur `actorFace` liste uniquement `asset.requiredActors`.

Chaque bouton affiche le label lisible (`Professor`, `Rival`, `Acteur`) et porte une key stable `cinematic-builder-actor-picker-<actorId>`. Aucun workflow normal ne permet de taper un `actorId` libre.

## 13. UI Inspecteur

Pour un step `actorFace`, l'inspecteur affiche les champs de bloc existants, puis une section `Acteur` et une section `Direction`. Les directions sont des boutons :

```text
Haut
Bas
Gauche
Droite
```

La suppression reste disponible seulement pour les steps authoring-owned.

## 14. Timeline et lane hint acteur

La timeline reste linéaire. Elle affiche un lane hint simple sous forme de badge :

```text
Acteur: <label acteur>
```

Le badge direction affiche `Haut`, `Bas`, `Gauche` ou `Droite`. Aucune lane éditable, aucun overlap et aucun scrubber ne sont introduits.

## 15. Suppression des steps authoring-owned

`removeCinematicTimelineAuthoringStep` supprime maintenant :

```text
draft
wait
fade
camera
actorFace
```

si, et seulement si, le step est authoring-owned. Les tests conservent la protection des steps non-owned.

## 16. Restrictions sur Actor Move / déplacement

V1-46 ne crée aucune opération de déplacement acteur. Aucun champ position, chemin, vitesse, cible, spawn/despawn ou follow actor n'est ajouté. Le texte `Déplacement acteur` reste uniquement un bloc verrouillé de palette.

## 17. Legacy bridge policy inchangée

Les bridges legacy `ScenarioAsset` restent visibles dans la Library comme bridges, mais ne peuvent toujours pas ouvrir le Builder canonique. Le test `keeps legacy bridge out of canonical builder shell` reste vert.

## 18. Design system

L'UI modifiée utilise les composants existants `PokeMapCard`, `PokeMapButton`, `PokeMapBadge`, `PokeMapIconTile`, les tokens `context.pokeMapColors` et les variantes de design system. Aucun `Color(`, `Colors.` ou `0xFF` n'a été ajouté dans les fichiers UI modifiés.

## 19. Tests ajoutés ou modifiés

Core :

```text
packages/map_core/test/cinematic_authoring_operations_test.dart
- addCinematicRequiredActor creates a minimal required actor
- addCinematicRequiredActor refuses empty labels
- addCinematicTimelineActorFacingStep creates an actorFace block
- addCinematicTimelineActorFacingStep validates actor ids and suffixes
- updateCinematicTimelineActorFacingStep changes actor and direction
- updateCinematicTimelineActorFacingStep refuses invalid updates
- remove authoring-owned couvre actorFace via la suite existante

packages/map_core/test/cinematic_diagnostics_test.dart
- accepts valid actorFace authoring block
- reports actorFace with unknown actorId
```

Editor :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart
- adds a required actor before enabling actor facing
- adds and edits actor facing with actor picker and direction
- captures V1-46 builder actor facing screenshot when requested

packages/map_editor/test/cinematics_library_workspace_test.dart
- adds an actor facing block from builder and refreshes summary
```

## 20. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
```

Preuve fichier :

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
-rw-r--r--  1 karim  staff   185K Jun  1 21:15 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
34ea185691452bfd09bd9b5c67ec64bae0fbd9235714da9c014fa69b41b814c0  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
```

La capture montre le Builder canonique, `Orientation acteur` actif, les acteurs requis `Professor` / `Rival`, un step `actorFace` sélectionné, l'acteur choisi, la direction dans l'inspecteur, le lane hint dans la timeline, les blocs verrouillés et le sandbox preview non-runtime.

## 21. Commandes exécutées

Format :

```text
dart format packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
Formatted 9 files (0 changed) in 0.04 seconds.
```

Tests et analyses :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_authoring_operations_test.dart
00:00 +26: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_diagnostics_test.dart
00:00 +10: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:02 +15: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:02 +10: All tests passed!

cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
No issues found! (ran in 1.0s)
```

Visual Gate :

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_46_CAPTURE_CINEMATIC_BUILDER_ACTOR_FACING=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:08 +15: All tests passed!
```

Analyse globale editor tentée :

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...
344 issues found. (ran in 2.7s)
```

Cette analyse globale échoue sur dette préexistante hors lot, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`. L'analyse ciblée des fichiers V1-46 passe.

## 22. Résultats des tests

Résultat RED initial :

```text
map_core cinematic_authoring_operations_test : compilation échouée car addCinematicRequiredActor, CinematicTimelineActorFacingDirection, addCinematicTimelineActorFacingStep, isCinematicTimelineActorFacingStep, cinematicTimelineActorFacingDirectionOf et updateCinematicTimelineActorFacingStep n'existaient pas.
map_core cinematic_diagnostics_test : compilation échouée car cinematicUnknownActorRef et les helpers actorFace n'existaient pas.
map_editor cinematic_builder_workspace_test : compilation échouée car les callbacks actor/actorFace et les helpers core n'existaient pas.
```

Résultat GREEN final :

```text
map_core authoring operations : +26, All tests passed.
map_core diagnostics : +10, All tests passed.
map_editor builder workspace : +15, All tests passed.
map_editor cinematics library workspace : +10, All tests passed.
visual gate builder : +15, All tests passed.
```

## 23. Analyze

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
No issues found! (ran in 1.0s)
```

Limite connue :

```text
cd packages/map_editor && flutter analyze
344 issues found. (ran in 2.7s)
```

Les erreurs globales sont hors fichiers V1-46.

## 24. Checks anti-scope

Packages runtime/gameplay/battle/examples :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie vide.

Recherche anti-runtime sur les fichiers code/test V1-46 :

```text
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
```

Sortie vide.

Recherche anti-déplacement acteur, commande stricte du prompt sur lignes ajoutées code/test :

```text
git diff --unified=0 -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -n "^\+.*(actorMove|moveActor|pathfinding|path|positionTarget|targetPosition|speed|velocity|walk|run|followActor|spawn|despawn)" || true
780:+              runSpacing: 6,
932:+          runSpacing: 6,
957:+          runSpacing: 6,
1289:+      matchesGoldenFile(screenshotFile.absolute.path),
```

Interprétation : les occurrences sont des faux positifs `runSpacing` et chemin de fichier de capture (`path`), pas du déplacement acteur. La recherche resserrée pour les vrais termes mouvement est vide :

```text
git diff --unified=0 -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -n "^\+.*(actorMove|moveActor|pathfinding|positionTarget|targetPosition|speed|velocity|\bwalk\b|\brun\b|followActor|spawn|despawn)" || true
```

Sortie vide.

Recherche anti-rich timeline editor :

```text
git diff --unified=0 -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -n "^\+.*(drag|drop|TimelineEditor|scrubber|keyframe|reorder|moveUp|moveDown|copyWith\(.*GameState|PlayableMapGame)" || true
```

Sortie vide.

Recherche anti-blocs métier hors scope :

```text
git diff --unified=0 -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -n "^\+.*(AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep|DialogueRuntime|BattleRuntime)" || true
```

Sortie vide.

Recherche anti-couleurs hardcodées sur les lignes ajoutées UI :

```text
git diff --unified=0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -n "^\+.*(Color\(|Colors\.|0xFF|0xff)" || true
```

Sortie vide.

Recherche anti-Selbrume sur les lignes ajoutées code/test :

```text
git diff --unified=0 -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg -ni "^\+.*(selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais)" || true
```

Sortie vide.

## 25. Fichiers créés

```text
reports/narrativeStudio/scenes/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
```

## 26. Fichiers modifiés

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 27. Roadmaps mises à jour

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent V1-46 `DONE`, ajoutent le résumé Actor References / Actor Facing V0, documentent les limites et recommandent un seul prochain lot :

```text
NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract
```

## 28. Limites connues

- `flutter analyze` global de `map_editor` reste rouge sur dette existante hors V1-46.
- `actorFace` n'a pas de durée exposée en UI.
- Les acteurs requis V0 n'ont pas de sprite picker, entity binding obligatoire, position map ou runtime resolver.
- La timeline reste linéaire avec lane hint simple, pas multi-lane.

## 29. Non-objectifs confirmés

Confirmé absent :

```text
map_runtime
map_gameplay
map_battle
examples
build_runner
actorMove
pathfinding
position cible
drag/drop
réordonnancement
timeline multi-track complète
preview runtime
dialogue cinematic
FX authorable
Son authorable
GameState write
WorldRule write
ScenarioAsset migration
bridge legacy ouvrable dans Builder
données Selbrume
```

## 30. Evidence Pack

Inventaire des changements par zone :

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
- lignes 25-37 : CinematicRequiredActorResult.
- lignes 113-118 : CinematicTimelineActorFacingDirection.
- lignes 246-272 : addCinematicRequiredActor.
- lignes 447-480 : addCinematicTimelineActorFacingStep.
- lignes 482-547 : updateCinematicTimelineActorFacingStep.
- lignes 648-658 : cinematicTimelineActorFacingDirectionOf.
- lignes 826-849 : construction du step actorFace.

packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
- ligne 22 : cinematicUnknownActorRef.
- lignes 330-350 : diagnostic actorId inconnu.

packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
- lignes 90-105 : callbacks acteurs/actorFace.
- lignes 266-301 : actions add actor, add actorFace, update actorFace.
- lignes 556-655 : carte acteurs requis et tuile Orientation acteur.
- lignes 980-986 : badges acteur/direction timeline.
- lignes 1197-1201 : inspecteur actorFace.
- lignes 1462-1536 : contrôles acteur/direction.

packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
- callbacks Library -> Builder pour acteur requis et actorFace.

packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
- callbacks applicatifs vers les opérations pures core.

tests core/editor
- tests listés en section 19.
```

Sorties git avant création de ce rapport :

```text
git diff --check

git diff --stat
 .../authoring/cinematic_authoring_operations.dart  | 264 +++++++++++++++-
 .../lib/src/diagnostics/cinematic_diagnostics.dart |  19 ++
 .../test/cinematic_authoring_operations_test.dart  | 246 ++++++++++++++-
 .../map_core/test/cinematic_diagnostics_test.dart  |  68 ++++
 .../cinematics/cinematic_builder_workspace.dart    | 350 ++++++++++++++++++++-
 .../cinematics/cinematics_library_workspace.dart   |  27 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  82 +++++
 .../test/cinematic_builder_workspace_test.dart     | 232 ++++++++++++++
 .../test/cinematics_library_workspace_test.dart    |  75 +++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 11 files changed, 1393 insertions(+), 10 deletions(-)

git diff --name-only
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status --short --untracked-files=all
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
```

Statut après création du rapport :

```text
git status --short --untracked-files=all
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_46_cinematic_actor_references_actor_facing_v0.png
```

## 31. Auto-review critique

1. V1-46 a-t-il modifié `map_runtime` ? Non.
2. V1-46 a-t-il modifié `map_gameplay`, `map_battle`, `examples` ? Non.
3. V1-46 a-t-il modifié le modèle JSON ? Non, les champs/enums existaient déjà.
4. V1-46 a-t-il lancé `build_runner` ? Non.
5. V1-46 a-t-il ajouté un vrai timeline editor ? Non.
6. V1-46 a-t-il ajouté du drag/drop ? Non.
7. V1-46 a-t-il ajouté du réordonnancement ? Non.
8. V1-46 a-t-il rendu Déplacement acteur authorable ? Non.
9. V1-46 a-t-il rendu Dialogue / FX / Son authorables ? Non.
10. Actor Facing utilise-t-il uniquement des acteurs requis ? Oui.
11. Un actorId libre peut-il être tapé dans le workflow normal ? Non.
12. Les actorId inconnus sont-ils refusés ou diagnostiqués ? Oui, refus en opérations et diagnostic core.
13. Camera / Wait / Fade restent-ils fonctionnels ? Oui, tests Builder et authoring operations verts.
14. Les steps non-owned restent-ils protégés ? Oui, tests existants et étendus verts.
15. ProjectManifest est-il muté uniquement via opérations pures ? Oui.
16. Les bridges legacy restent-ils exclus du Builder canonique ? Oui.
17. Le design system est-il respecté ? Oui, composants/tokens existants, aucune couleur hardcodée ajoutée.
18. La Visual Gate prouve-t-elle Actor Facing ? Oui.
19. L'Evidence Pack est-il complet sans jetons génériques ? Oui.
20. Prochain lot exact recommandé ? `NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract`.

## 32. Recommandation pour le prochain lot

Recommandation unique :

```text
NS-SCENES-V1-47 — Cinematic Actor Movement Block V0 Prep / Contract
```

Raison : les acteurs requis et l'orientation V0 sont maintenant posés. Avant tout `actorMove` authorable, il faut cadrer le contrat de mouvement : référentiel spatial, positions autorisées, absence de pathfinding implicite, diagnostics, durée, intégration future avec lane hints, et frontières runtime.
