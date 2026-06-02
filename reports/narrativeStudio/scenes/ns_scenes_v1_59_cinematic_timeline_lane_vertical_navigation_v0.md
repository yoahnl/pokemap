# NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0

Date : 2026-06-03  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`  
Prochain lot recommande : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`

## 1. Résumé exécutif

V1-59 implemente ArrowUp / ArrowDown dans la timeline du Cinematic Builder, strictement selon le contrat V1-58 : prochaine lane non vide, choix du bloc cible par proximite de `centerMs`, lanes vides ignorees, bords stables et cas sans selection traite.

La navigation reste locale au panneau timeline. Elle ne cree aucun playback, seek, scrubber, drag/drop, resize, reorder, runtime, persistence temporelle ou mutation `ProjectManifest`.

## 2. Gate 0

Commande executee depuis la racine :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides dans cette sortie. Gate 0 : working tree propre, dernier commit V1-58.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_evidence_pack.md`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

## 4. Design Gate — Cinematic Timeline Lane Vertical Navigation V0

1. Contrat V1-58 implemente : Option B, prochaine lane non vide et cible par `centerMs`.
2. `selectedStepId` vit dans `CinematicBuilderWorkspace`, en etat local editor.
3. Le `FocusNode` timeline vit dans `_TimelinePlaceholderState`.
4. V1-57 mappe deja ArrowLeft, ArrowRight, Home et End via `_timelineKeyboardNavigationForKey`.
5. ArrowUp / ArrowDown sont ajoutes comme intents separes, sans modifier `previous`, `next`, `first`, `last`.
6. La liste de lanes utilisee est `CinematicTimelineTimeLayoutReadModel.lanes`.
7. La liste de blocks utilisee est `CinematicTimelineTimeLayoutReadModel.blocks` et `lane.blocks`.
8. `centerMs` est calcule localement par `startMs + visualDurationMs / 2`.
9. La lane au-dessus est trouvee en scannant `timeLayout.lanes` vers le haut depuis la lane courante.
10. La lane en dessous est trouvee en scannant `timeLayout.lanes` vers le bas depuis la lane courante.
11. Le bloc cible est le block de la lane cible dont le centre est le plus proche du centre courant.
12. Le tie-break compare distance, puis `stepIndex`; l'ordre stable est preserve en ne remplacant pas le meilleur candidat a egalite de `stepIndex`.
13. Aux bords, le helper retourne le bloc courant.
14. Sans selection, ArrowDown retourne le premier bloc de la premiere lane non vide et ArrowUp le dernier bloc de la derniere lane non vide.
15. Si `selectedStepId` est introuvable, `_selectedTimeBlock` retourne null et le comportement est le meme que sans selection.
16. Si la timeline est vide, le helper retourne null et le handler reste non destructif.
17. `hoveredStepId` n'est pas lu par le helper de navigation verticale.
18. Les TextFields restent proteges car le handler reste local au Focus de la timeline.
19. La non-mutation `ProjectManifest` est prouvee par les tests qui comparent `project.toJson()` et `projectChangeCount`.
20. La geometrie V1-56 est preservee : aucune constante de lane, axe, barre, echelle ou largeur n'est modifiee.
21. Les hover details V1-55 sont preserves ; le hover est teste sans influencer la cible verticale.
22. Les transports V1-53 restent disabled ; aucun callback n'est ajoute.
23. Il n'y a pas de playback car aucun etat de lecture, timer, ticker ou player n'est ajoute.
24. Il n'y a pas de seek/scrubber car aucune position temporelle interactive n'est ajoutee.
25. Il n'y a pas de drag/drop/resize/reorder car aucun geste ou operation de montage n'est ajoute.
26. Visual Gate produite : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png`.
27. Prochain lot exact recommande : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`.

## 5. Scope réalisé

- Ajout des intents `_TimelineKeyboardNavigation.up` et `.down`.
- Mapping de `LogicalKeyboardKey.arrowUp` et `LogicalKeyboardKey.arrowDown`.
- Helper `_timelineVerticalKeyboardTargetBlock(...)`.
- Helper `_timelineVerticalFallbackTargetBlock(...)`.
- Helper `_timelineClosestBlockInLane(...)`.
- Helper `_timelineBlockCenterMs(...)`.
- Badge clavier mis a jour : `Navigation clavier : ← → ↑ ↓ Home End`.
- Hint semantic elargi aux fleches sans detailler un nouveau systeme global.
- Tests widget V1-59.
- Capture Visual Gate V1-59.
- Roadmaps mises a jour.

## 6. Contrat V1-58 implémenté

Le contrat implemente est Option B : ArrowUp / ArrowDown sautent les lanes vides et ciblent la prochaine lane non vide dans la direction demandee. La cible dans la lane est choisie par centre temporel derive.

## 7. Mapping ArrowUp / ArrowDown

`_timelineKeyboardNavigationForKey` retourne maintenant :

- `up` pour `LogicalKeyboardKey.arrowUp`
- `down` pour `LogicalKeyboardKey.arrowDown`

Le handler reste dans `_TimelinePlaceholderState._handleTimelineKeyEvent`.

## 8. Calcul centerMs

Le calcul reste local au fichier editor :

```text
centerMs = startMs + visualDurationMs / 2
```

Il n'est pas stocke dans le core, le model JSON, `ProjectManifest`, `CinematicAsset` ou `CinematicTimelineStep`.

## 9. Recherche de lane non vide

Depuis la lane du bloc selectionne, le helper scanne l'ordre `timeLayout.lanes` avec une direction `-1` ou `+1`. Les lanes dont `lane.blocks.isEmpty` est vrai sont ignorees.

## 10. Sélection du bloc cible

Pour chaque block candidat de la lane cible, le helper compare :

1. distance absolue entre centres ;
2. plus petit `stepIndex`.

L'ordre stable de lane est conserve lorsque les deux criteres sont egaux.

## 11. Bords / sans sélection / selectedStepId introuvable

- Bord haut ou bas avec selection : le bloc courant reste selectionne.
- Sans selection + ArrowDown : premier bloc de la premiere lane non vide.
- Sans selection + ArrowUp : dernier bloc de la derniere lane non vide.
- `selectedStepId` introuvable : meme comportement que sans selection.
- Timeline vide : null, aucun crash, aucune mutation.

## 12. Protection TextField / focus local

Le handler clavier reste local au `FocusNode` de la timeline. Le test `keeps vertical keyboard shortcuts local and protects text fields` focalise un champ de cible de mouvement, envoie ArrowDown puis ArrowUp, et verifie que la selection et le curseur restent sur `step_face`.

## 13. Compatibilité V1-57

ArrowLeft, ArrowRight, Home et End conservent leur comportement par ordre lineaire `stepIndex`. Le test V1-57 existant reste vert.

## 14. Compatibilité V1-56 / V1-55 / V1-53

- V1-56 : constantes, largeur, hauteur, echelle et placement X inchanges.
- V1-55 : hover details conserves ; le hover ne pilote pas la navigation.
- V1-53 : transport controls restent visibles et disabled.

## 15. Restrictions anti-playback / anti-runtime / anti-editor temporel

Confirme : aucun playback, timer, ticker, seek, scrubber, drag/drop, resize, reorder, preview runtime, mutation JSON, state `isPlaying`, `currentTimeMs`, `playbackTimeMs`, ou persistance temporelle.

## 16. Legacy bridge policy inchangée

V1-59 ne modifie pas la Library, les bridges legacy Scenario/Cutscene, les contrats publics Cinematic, Scene Builder ou Runtime Adapter. Les bridges legacy restent exclus du Builder canonique.

## 17. Design system

Aucune couleur hardcodee n'est ajoutee dans le code UI modifie. Le rendu continue d'utiliser les composants et tokens existants : `PokeMapPanel`, `PokeMapBadge`, `PokeMapCard`, `context.pokeMapColors`.

## 18. Tests ajoutés ou modifiés

Tests ajoutes :

- `navigates selected timeline blocks vertically with local keyboard focus`
- `uses step index as vertical navigation tie break`
- `handles vertical navigation without selection and empty timelines`
- `keeps vertical keyboard shortcuts local and protects text fields`
- `captures V1-59 cinematic timeline lane vertical navigation when requested`

Tests modifies :

- attente du badge V1-57 : `Navigation clavier : ← → ↑ ↓ Home End`.

## 19. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff  228485 Jun  3 01:00 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png
sha256 491f92d2ee245e92015d73ff6afc8b4d7356079045085606e23d2c15d06d1da9
```

Observation visuelle : `step_face` est selectionne par ArrowDown, le curseur est aligne, l'inspecteur affiche `step_face`, la preview sandbox affiche `2. Professor turns • actorFace`, la timeline dense V1-56 est conservee et les transports restent placeholders.

## 20. Commandes exécutées

Les commandes completes et sorties utiles sont reprises dans l'Evidence Pack :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md
```

## 21. Résultats des tests

- RED cible initial : echoue sur selection attendue non active.
- GREEN cible principal : `+1: All tests passed!`
- TextFields vertical : `+1: All tests passed!`
- Tie-break : `+1: All tests passed!`
- Sans selection / timeline vide : `+1: All tests passed!`
- Suite Builder : `+44: All tests passed!`
- Suite Library : `+10: All tests passed!`
- Core time layout : `+4: All tests passed!`
- Core lane read model : `+2: All tests passed!`

## 22. Analyze

- `cd packages/map_core && dart analyze` -> `No issues found!`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart` -> `No issues found!`

## 23. Checks anti-scope

Resultats :

- `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples` -> sortie vide.
- anti-runtime sur fichiers code/test modifies -> sortie vide.
- anti-playback/seek/scrubber/timer sur fichiers code/test modifies -> sortie vide.
- anti-couleurs hardcodees sur fichier UI modifie -> sortie vide.
- anti-Selbrume sur fichiers code/test modifies -> sortie vide.
- anti-persistence temporelle/focus dans core -> sortie vide.
- anti-drag/resize/reorder ressort seulement deux lignes de tests preexistantes ou non-capability : `expect(find.text('resize'), findsNothing)` et un deplacement souris de test de hover.

## 24. Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.png`

## 25. Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 26. Roadmaps mises à jour

Les deux roadmaps Scenes declarent V1-59 DONE et recommandent un seul prochain lot :

```text
NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0
```

## 27. Limites connues

- La navigation verticale reste une selection locale, pas une edition temporelle.
- Les lanes vides sont sautees en V0.
- Aucun overlay d'aide riche n'est encore ajoute ; c'est le prochain lot recommande.
- Pas de test widget direct pour un `selectedStepId` introuvable force artificiellement, car l'etat du Builder nettoie deja une selection invalide au changement d'asset ; le helper traite tout de meme ce cas comme absence de selection.

## 28. Non-objectifs confirmés

Non ajoutes : playback, timer, ticker, seek, scrubber, transport fonctionnel, drag/drop, resize, reorder, keyframe, overlap authorable, zoom timeline, preview runtime, runtime map, gameplay, battle, examples, build_runner, JSON, ScenarioAsset migration, donnees Selbrume.

## 29. Evidence Pack

Evidence Pack :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md
```

## 30. Auto-review critique

1. map_runtime modifie ? Non.
2. map_gameplay/map_battle/examples modifies ? Non.
3. Modele JSON modifie ? Non.
4. build_runner lance ? Non.
5. Playback ajoute ? Non.
6. Timer ajoute ? Non.
7. `isPlaying/currentTimeMs/playbackTimeMs` ajoutes ? Non.
8. Seek ajoute ? Non.
9. Scrubber ajoute ? Non.
10. Transport controls rendus fonctionnels ? Non.
11. Drag/drop ajoute ? Non.
12. Resize ajoute ? Non.
13. Reorder ajoute ? Non.
14. Nouvelle capability authoring ajoutee ? Non.
15. ArrowUp / ArrowDown changent seulement la selection locale ? Oui.
16. ArrowUp / ArrowDown utilisent `centerMs` ? Oui.
17. Lanes vides ignorees ? Oui.
18. Bords stables ? Oui.
19. Cas sans selection traite ? Oui.
20. `selectedStepId` introuvable traite ? Oui dans le helper.
21. Curseur suit la selection verticale ? Oui, teste.
22. Inspecteur suit la selection verticale ? Oui, teste.
23. Preview sandbox suit la selection verticale ? Oui, teste.
24. TextFields proteges ? Oui, teste.
25. Navigation horizontale V1-57 intacte ? Oui, test existant vert.
26. Geometrie V1-56 intacte ? Oui, suite Builder et test proportions verts.
27. Hover V1-55 fonctionnel ? Oui, suite Builder verte et hover ignore teste.
28. Transports V1-53 disabled ? Oui, suite Builder verte.
29. Design system respecte ? Oui.
30. Visual Gate prouve la navigation verticale ? Oui.
31. Evidence Pack complet sans placeholders ? Oui.
32. Prochain lot exact recommande : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`.

## 31. Recommandation pour le prochain lot

`NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`

Justification : V1-57 et V1-59 rendent les fleches clavier fonctionnelles. La prochaine valeur utile est d'expliquer proprement les raccourcis, les bords, le skip de lanes vides et le caractere non-runtime/non-playback, sans ajouter de nouveau pouvoir temporel.
