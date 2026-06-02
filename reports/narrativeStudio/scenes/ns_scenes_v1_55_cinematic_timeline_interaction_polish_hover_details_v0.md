# NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0

Date : 2026-06-02  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`  
Prochain lot recommande : `NS-SCENES-V1-56 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`

## 1. Resume executif

V1-55 ajoute une inspection legere au survol des barres de timeline du Cinematic Builder.

Le resultat reste strictement editor-only : une barre survolee affiche un detail inline compact avec label humain, type, piste, debut, duree et infos metier utiles. Le survol ne selectionne pas le bloc, ne deplace pas le curseur, ne change pas l'inspecteur et ne mute pas `ProjectManifest`.

Le lot conserve la densite V1-54 demandee par Karim : preview sandbox compacte, timeline agrandie/lisible, lanes 28 px, axe 24 px, barres 22 px et capture 1663x926.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_55_evidence_pack.md`.

## 2. Gate 0

Etat avant V1-55 : le working tree contenait deja les changements V1-54 non commités.

Changements preexistants observes avant edits V1-55 :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png
```

Base git :

```text
/Users/karim/Project/pokemonProject
main
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
```

Decision : ne pas effacer V1-54, distinguer les ajouts V1-55 et documenter les deux couches.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

## 4. Design Gate — Cinematic Timeline Interaction Polish / Hover Details V0

1. Les hover details sont affiches inline entre les badges de timeline et les lanes.
2. L'inline est choisi plutot qu'un overlay/tooltip pour eviter timing, fragilite golden et positionnement magique.
3. L'etat local necessaire est `hoveredStepId`.
4. `hoveredStepId` sert seulement a l'inspection temporaire ; `selectedStepId` reste la selection durable locale.
5. Hover ne change pas la selection car aucun callback de selection n'est appele dans `MouseRegion`.
6. Hover ne deplace pas le curseur car le curseur est toujours derive de `selectedStepId`.
7. Hover ne change pas l'inspecteur car l'inspecteur lit le bloc selectionne, pas le bloc survole.
8. Le hover est nettoye sur `onExit` de la barre et de la grille timeline.
9. Les details utilisent labels humains actor/cible et helpers no-code, pas les IDs bruts en premier niveau.
10. `actorMove` affiche label, type, piste, debut, duree, mode mouvement et chemin.
11. `actorFace` affiche label, type, piste, debut, duree visuelle/fallback et direction.
12. `wait`, `fade` et `camera` affichent type, debut, duree et mode si disponible.
13. Les fallback/unknown affichent label, kind traduit si connu, debut et duree visuelle.
14. Le detail reste compact avec un strip horizontal de 22 px et scroll horizontal si necessaire.
15. Le layout V1-54 est preserve : lanes 28 px, axe 24 px, barres 22 px, timeline grande.
16. Le hover est teste via `PointerDeviceKind.mouse`, sans timer ni overlay.
17. La non-mutation est testee via `project.toJson()` et compteur `projectChangeCount`.
18. Il n'y a pas de playback car aucun player, timer, ticker ou controle actif n'est ajoute.
19. Il n'y a pas de seek/scrubber car l'axe et le hover ne modifient aucune position temporelle.
20. Il n'y a pas de drag/drop/resize/reorder car aucune primitive de drag ni gesture timeline n'est ajoutee.
21. Visual Gate produite : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png`.
22. Prochain lot recommande : `NS-SCENES-V1-56 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`.

## 5. Scope realise

- `_TimelinePlaceholder` devient stateful pour stocker `hoveredStepId`.
- Ajout de `_TimelineHoverDetails` et `_TimelineHoverDetailText`.
- Ajout du detail inline `Survol : ...`.
- Ajout d'un highlight hover doux via l'etat hover de `PokeMapCard` et une key testable.
- Ajout de labels semantics compacts sur les barres.
- Ajout de helpers de resume no-code par type de bloc.
- Test widget hover actorFace/actorMove sans selection ni mutation.
- Visual Gate V1-55.
- Roadmaps mises a jour vers V1-56.

## 6. Contrat Hover Details V0

Confirme :

- hover local editor-only ;
- aucune persistance hover dans core/model ;
- detail derive de `CinematicTimeline.steps` et du read model time layout ;
- selection/cursor/inspector derives de la selection, pas du hover ;
- tap/clic selectionne toujours comme avant ;
- sortie hover nettoie detail et highlight.

## 7. Etat local hover/focus

Etat ajoute :

```dart
String? _hoveredStepId;
```

Le focus clavier avance n'est pas implemente dans V1-55. La base accessible minimale est un label semantic sur chaque barre. V1-56 est recommande pour la navigation clavier/focus.

## 8. UI Hover Details

Forme retenue : Option A inline.

Exemple affiche sur actorMove :

```text
Survol : Professor -> Centre scene
Type : Deplacement acteur
Piste : Acteur: Professor
Debut : 1.1 s
Duree : 1000 ms
Mode : Marche
Chemin : Direct
```

Dans l'UI reelle, les labels conservent les accents francais.

## 9. Highlight hover vs selection

Regle appliquee : selected > hovered.

Si la barre est selectionnee et survolee, l'etat selected domine. Si une autre barre est survolee, elle recoit seulement un hover doux et temporaire.

## 10. Accessibilite / semantics

Ajout d'un label `Semantics` sur les barres, construit avec le meme resume no-code que le detail hover.

Non fait : roving focus clavier, raccourcis clavier ou navigation au clavier entre barres. C'est le prochain verrou recommande.

## 11. Compatibilite V1-51 / V1-52 / V1-53 / V1-54

Preserve :

- axe temporel ;
- ticks ;
- barres proportionnelles ;
- duree fallback visuelle ;
- badge `Selection : <temps>` ;
- curseur vertical derive de `selectedStepId` ;
- transport controls visibles et disabled ;
- densite V1-54 ;
- preview sandbox compacte.

## 12. Restrictions anti-playback / anti-runtime

Confirme :

- pas de `map_runtime` ;
- pas de `map_gameplay` ;
- pas de `map_battle` ;
- pas de `examples` ;
- pas de `PlayableMapGame` ;
- pas de `playCinematic` ;
- pas de timer/ticker/animation playback ;
- pas de `isPlaying/currentTimeMs/playbackTimeMs` ;
- pas de seek/scrubber ;
- pas de transport fonctionnel ;
- pas de drag/drop/resize/reorder.

## 13. Legacy bridge policy inchangee

Le Builder reste reserve aux `CinematicAsset` canoniques. Les bridges legacy restent exclus du Builder canonique, comme dans les lots precedents.

## 14. Design system

UI ajoutee avec :

- `PokeMapPanel`
- `PokeMapCard`
- `PokeMapBadge`
- `PokeMapButton`
- `context.pokeMapColors`
- `CupertinoIcons`

Recherche anti-couleurs hardcodees sur le fichier UI modifie : sortie vide.

## 15. Tests ajoutes ou modifies

Ajoute :

- `shows hover details without selecting or moving cursor`
- `captures V1-55 timeline hover details polish when requested`

Le test hover verifie :

- detail absent avant hover ;
- detail actorFace visible au hover ;
- detail actorMove visible au hover ;
- labels humains au lieu d'IDs acteur/cible ;
- highlight hover sur actorMove ;
- selection conservee sur actorFace ;
- curseur conserve sur actorFace ;
- inspecteur conserve sur actorFace ;
- `ProjectManifest` non mute ;
- sortie hover nettoie detail et highlight.

## 16. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
sha256 669ecd8053d3e199392fc09a15899362a420f5aa591442ad940d0f9726d06720
taille 236791 octets
```

## 17. Commandes executees

Voir Evidence Pack pour les sorties exactes.

Principales commandes :

- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows hover details without selecting or moving cursor'`
- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `flutter test --update-goldens --dart-define=NS_SCENES_V1_55_CAPTURE_CINEMATIC_TIMELINE_HOVER_DETAILS=true --reporter=compact test/cinematic_builder_workspace_test.dart`
- `flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `dart test test/cinematic_timeline_time_layout_read_model_test.dart`
- `dart test test/cinematic_timeline_lane_read_model_test.dart`
- `dart analyze`
- `flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart`
- `flutter analyze`
- checks anti-scope `rg` / `git diff --name-only`

## 18. Resultats des tests

Verts :

- test hover cible : `00:02 +1: All tests passed!`
- suite Builder : `00:05 +34: All tests passed!`
- Visual Gate V1-55 : `00:11 +34: All tests passed!`
- suite Library : `00:03 +10: All tests passed!`
- core time layout : `00:00 +4: All tests passed!`
- core lane read model : `00:00 +2: All tests passed!`
- core analyze : `No issues found!`

## 19. Analyze

Analyse ciblee editor :

```text
Analyzing 2 items...
No issues found! (ran in 2.7s)
```

Analyse complete `map_editor` :

```text
344 issues found. (ran in 3.2s)
```

Signal principal hors scope :

- `pokemon_sdk_move_catalog_converter.dart` references des parametres/classes non disponibles.
- `sync_pokemon_sdk_moves_catalog_use_case.dart` reference `fetchPokemonSdkStudioProjectPayload`.
- Nombreux infos/warnings historiques non lies aux fichiers V1-55.

Decision : ne pas corriger cette dette hors scope dans V1-55.

## 20. Checks anti-scope

Sorties utiles :

- `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples` : vide.
- recherche anti-runtime sur fichiers modifies : vide.
- recherche anti-playback/timer/transport fonctionnel : vide.
- recherche anti-persistance temporelle core : vide.
- recherche anti-couleurs hardcodees UI : vide.
- recherche anti-Selbrume code/test V1-55 : vide.

Le check drag/resize ne remonte que :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:481:    await gesture.moveTo(timelineRect.topLeft - const Offset(16, 16));
```

Interpretation : assertion anti-resize et mouvement souris de test pour sortir du hover ; aucune capability drag/resize.

## 21. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_55_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png`

## 22. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Note : ces fichiers contenaient deja les changements V1-54 au Gate 0.

## 23. Roadmaps mises a jour

- V1-55 ajoute comme DONE dans `road_map_scenes.md`.
- V1-55 ajoute comme DONE dans `road_map_scene_builder_authoring.md`.
- Prochain lot recommande mis a jour vers V1-56.

## 24. Limites connues

- Pas de navigation clavier/focus avance.
- Pas de second inspecteur hover.
- Pas de tooltip overlay.
- Pas de zoom temporel.
- Analyse complete `map_editor` encore rouge sur dette hors scope Pokemon SDK.

## 25. Non-objectifs confirmes

Non realises :

- playback ;
- preview runtime ;
- seek ;
- scrubber ;
- drag/drop ;
- resize ;
- reorder ;
- nouveau bloc authorable ;
- mutation JSON ;
- build_runner ;
- runtime/gameplay/battle/examples.

## 26. Evidence Pack

Evidence Pack cree :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_55_evidence_pack.md
```

## 27. Auto-review critique

1. `map_runtime` modifie ? Non.
2. `map_gameplay/map_battle/examples` modifies ? Non.
3. Modele JSON modifie ? Non.
4. `build_runner` lance ? Non.
5. Playback ajoute ? Non.
6. Timer ajoute ? Non.
7. `isPlaying/currentTimeMs/playbackTimeMs` ajoute ? Non.
8. Seek ajoute ? Non.
9. Scrubber ajoute ? Non.
10. Transport controls rendus fonctionnels ? Non.
11. Drag/drop ajoute ? Non.
12. Resize ajoute ? Non.
13. Reorder ajoute ? Non.
14. Nouvelle capability authoring ajoutee ? Non.
15. Hover change la selection ? Non, test vert.
16. Hover deplace le curseur ? Non, test vert.
17. Hover modifie l'inspecteur ? Non, test vert.
18. Hover mute `ProjectManifest` ? Non, test vert.
19. Timeline V1-51 fonctionnelle ? Oui, tests core/editor verts.
20. Curseur V1-52 fonctionnel ? Oui, tests Builder verts.
21. Transports V1-53 disabled ? Oui, tests Builder verts.
22. Densite V1-54 fonctionnelle ? Oui, test densite preserve.
23. Wait/Fade/Camera fonctionnels ? Oui, suite Builder verte.
24. ActorFace fonctionnel ? Oui, test hover actorFace vert.
25. ActorMove fonctionnel ? Oui, test hover actorMove vert.
26. Labels cible V1-50 fonctionnels ? Oui, labels humains preserves.
27. Design system respecte ? Oui, tokens/primitives existants.
28. Visual Gate prouve les hover details ? Oui, screenshot V1-55.
29. Evidence Pack complet sans placeholders ? Oui.
30. Prochain lot exact recommande ? `NS-SCENES-V1-56 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`.

## 28. Recommandation pour le prochain lot

`NS-SCENES-V1-56 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`

Objectif : ameliorer la navigation clavier/focus entre les barres de timeline, sans playback, seek, drag/drop, mutation ni runtime.
