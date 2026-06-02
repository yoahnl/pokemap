# NS-SCENES-V1-53 — Cinematic Timeline Transport Controls Placeholder V0

Date : 2026-06-02  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0`  
Prochain lot recommande : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`

## 1. Resume executif

V1-53 ajoute les controles de transport visuels du Cinematic Builder : `Reset`, `Play`, `Stop`.

Ces controles sont volontairement des placeholders disabled. Chaque bouton utilise `PokeMapButton` avec `onPressed = null`, un label visible externe, un tooltip informatif et le badge `Controles de lecture a venir`.

L'UI s'inspire de l'image de reference fournie par Karim : timeline dense, preview sandbox reduite, controles centres sous la timeline et proportions conservees en Visual Gate 1663x926.

Phrase canonique : V1-53 ajoute les boutons de transport. V1-53 ne branche pas le moteur.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md`.

## 2. Gate 0

Gate 0 execute avant edits V1-53 :

- repo : `/Users/karim/Project/pokemonProject`
- branche : `main`
- working tree propre avant edits V1-53
- dernier commit : `df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)`

Sorties exactes dans l'Evidence Pack.

## 3. Fichiers lus

Instructions et contexte :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/brainstorming/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `/Users/karim/.codex/attachments/4c4d8023-8002-4d98-97fa-7d365f332696/pasted-text.txt`
- `/Users/karim/Desktop/assets/pokeMap/définitive/3 - cinématique/2 - constructeur de cinématique.png`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_evidence_pack.md`

Editor / core :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

## 4. Design Gate — Cinematic Timeline Transport Controls Placeholder V0

1. Placement : sous les lanes et sous la zone scrollable de la timeline, dans le panel timeline, centre horizontalement.
2. Mode choisi : boutons disabled.
3. Pourquoi disabled : c'est le signal le plus honnete ; aucun callback, aucune mutation possible, aucun faux feedback.
4. No-op non retenu : inutile puisque `PokeMapButton` supporte `onPressed = null`.
5. Controles affiches : uniquement Reset, Play, Stop.
6. Labels : `Reset`, `Play`, `Stop`, choisis car le prompt les propose et les icones de transport sont universelles.
7. Icones : `CupertinoIcons.arrow_counterclockwise`, `CupertinoIcons.play_fill`, `CupertinoIcons.stop_fill`.
8. Message : badge visible `Controles de lecture a venir`.
9. Anti-promesse : pas de texte `Lecture en cours`, pas de preview runtime, pas d'etat de lecture.
10. Test selection : apres taps sur les trois controles, le bloc `step_face` reste selectionne.
11. Test curseur : apres taps, le curseur V1-52 reste aligne sur la meme position.
12. Test timer : recherche anti-scope sans `Timer(`, `Ticker`, `AnimationController`.
13. Test runtime : recherche sans `PlayableMapGame`, `SceneRuntimeExecutor`, `playCinematic`.
14. Preservation V1-52 : test curseur historique conserve, plus test transport.
15. Preservation V1-51 : suite Builder conserve axe/ticks/barres/proportions.
16. Preservation authoring V1-44 a V1-50 : suite Builder `+30` et Library `+10`.
17. Pas de seek : aucun handler sur axe ou controle, aucune API seek.
18. Pas de scrubber : aucun widget, aucun texte, aucun etat scrub.
19. Pas de transport fonctionnel : chaque bouton a `onPressed = null`.
20. Pas de preview runtime : preview reste sandbox, aucun package runtime modifie.
21. Visual Gate : screenshot `ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png`, 1663x926.
22. Prochain lot recommande : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`.

## 5. Scope realise

- Ajout d'une section `_TimelineTransportControlsPlaceholder` sous la timeline.
- Ajout de trois actions visuelles Reset / Play / Stop.
- Boutons disabled via `PokeMapButton(onPressed: null)`.
- Labels visibles hors boutons pour respecter un rendu icon-first.
- Message visible `Controles de lecture a venir`.
- Tooltips `indisponible dans ce lot`.
- Test widget de non-mutation, selection preservee et curseur preserve.
- Capture Visual Gate inspiree de l'image de reference fournie.
- Roadmaps mises a jour vers V1-54.

## 6. Contrat Transport Controls Placeholder V0

Contrat :

- visible dans le Builder canonique uniquement ;
- editor-only ;
- disabled ;
- non persistant ;
- non runtime ;
- sans callback parent ;
- sans horloge ;
- sans deplacement du curseur ;
- sans mutation `ProjectManifest`.

## 7. UI Reset / Play / Stop

La section affiche :

- badge : `Controles de lecture a venir`;
- bouton Reset icon-only + label externe ;
- bouton Play icon-only + label externe ;
- bouton Stop icon-only + label externe.

Les boutons sont places dans un `Wrap` centre, sous la grille temporelle, avec spacing compact.

## 8. Etat disabled ou no-op

Mode retenu : disabled.

Preuve code :

```dart
PokeMapButton(
  key: buttonKey,
  onPressed: null,
  variant: PokeMapButtonVariant.secondary,
  size: PokeMapButtonSize.large,
  leading: Icon(icon),
  child: const SizedBox.shrink(),
)
```

Preuve test : `tester.widget<PokeMapButton>(...).onPressed` vaut `null` pour les trois boutons.

## 9. Compatibilite Timeline V1-51 / V1-52

V1-51 reste preserve :

- axe temporel ;
- ticks ;
- lanes ;
- barres proportionnelles ;
- fallback visuel ;
- proportions preview/timeline.

V1-52 reste preserve :

- badge `Selection : 500 ms` ;
- curseur vertical ;
- handle decoratif ;
- position derivee de `selectedBlock.startMs` ;
- absence de seek.

## 10. Restrictions anti-playback / anti-runtime

Confirme :

- pas de playback ;
- pas de timer ;
- pas de seek ;
- pas de scrubber ;
- pas de transport fonctionnel ;
- pas de preview runtime ;
- pas de drag/drop ;
- pas de resize ;
- pas de reorder ;
- pas de persistance temporelle ;
- pas de changement JSON ;
- pas de `build_runner` ;
- pas de modification `map_runtime`, `map_gameplay`, `map_battle`, `examples`.

## 11. Legacy bridge policy inchangee

Les bridges legacy restent exclus du Builder canonique. V1-53 ne modifie pas la Library, ne promeut aucun `ScenarioAsset` et n'ajoute aucune migration.

## 12. Design system

UI ajoutee avec primitives/tokens PokeMap :

- `PokeMapPanel` existant pour le panel timeline ;
- `PokeMapBadge` ;
- `PokeMapButton` ;
- `context.pokeMapColors` ;
- `CupertinoIcons`.

Recherche anti-couleurs hardcodees sur le fichier UI modifie : sortie vide.

## 13. Tests ajoutes ou modifies

Modifie :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Tests ajoutes :

- `shows disabled transport placeholders without changing selection`
- `captures V1-53 timeline transport controls placeholder when requested`

Le test principal couvre :

- controles visibles ;
- labels Reset / Play / Stop visibles ;
- message `Controles de lecture a venir` visible ;
- boutons disabled ;
- taps sans changement de selection ;
- curseur V1-52 immobile ;
- aucune mutation `ProjectManifest` ;
- absence des textes `Lecture en cours`, `Playing`, `Scrubber`, `Seek`.

## 14. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```

Preuve image :

```text
PNG 1663 x 926
SHA1 51ce0a05a501ba129fada044aec8d33a56a4b8e3
SHA256 c9b40a137c5c2ce2947374cad4f62bf61d9e205618bc1c170ceaafb597fc6d33
```

La capture montre Builder, palette, preview sandbox reduite, timeline par pistes, axe/ticks/barres, curseur V1-52, badge `Selection : 500 ms`, boutons Reset / Play / Stop disabled et inspecteur synchronise.

## 15. Commandes executees

Voir Evidence Pack pour les sorties exactes.

Commandes principales :

- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows disabled transport placeholders without changing selection'` RED puis GREEN.
- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `flutter test --update-goldens --dart-define=NS_SCENES_V1_53_CAPTURE_CINEMATIC_TIMELINE_TRANSPORT_CONTROLS=true --reporter=compact test/cinematic_builder_workspace_test.dart`
- `dart test test/cinematic_timeline_time_layout_read_model_test.dart`
- `dart test test/cinematic_timeline_lane_read_model_test.dart`
- `dart analyze`
- `flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`
- checks anti-scope.

## 16. Resultats des tests

Tous les tests cibles passent :

- core time layout : `+4`
- core lane read model : `+2`
- Builder : `+30`
- Library : `+10`
- Visual Gate : `+30`

Incident documente : une tentative de lancer deux commandes Flutter en parallele a fait echouer temporairement la suite Library sur un lock/native asset (`objective_c.dylib`). La suite Library a ete relancee seule ensuite et passe `+10`.

## 17. Analyze

- `map_core` : `No issues found!`
- `map_editor` cible : `No issues found! (ran in 1.2s)`

## 18. Checks anti-scope

Sorties vides :

- diff runtime/gameplay/battle/examples ;
- runtime symbols ;
- playback/timer/seek/scrubber ;
- drag cursor / drag-drop / resize / reorder dans le code produit modifie ;
- persistance temporelle ;
- couleurs hardcodees ;
- Selbrume/Mael/Lysa/Port des Brisants dans le code/test modifie.

## 19. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png`

## 20. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 21. Roadmaps mises a jour

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Elles marquent V1-53 DONE et recommandent V1-54.

## 22. Limites connues

- Reset ne reinitialise rien.
- Play ne lance rien.
- Stop n'arrete rien.
- Le curseur reste un repere de selection, pas un playhead runtime.
- La preview sandbox reste une sandbox.
- Aucun moteur cinematic visuel n'est branche.

## 23. Non-objectifs confirmes

Non realises volontairement :

- playback cinematic ;
- timer/ticker/animation controller ;
- seek/scrubber ;
- runtime preview ;
- modification `map_runtime` ;
- pathfinding ;
- edition temporelle ;
- drag/drop ou resize ;
- migration `ScenarioAsset` ;
- modification JSON.

## 24. Evidence Pack

Evidence Pack detaille :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md
```

## 25. Auto-review critique

1. V1-53 a-t-il modifie `map_runtime` ? Non.
2. V1-53 a-t-il modifie `map_gameplay` / `map_battle` / `examples` ? Non.
3. V1-53 a-t-il modifie le modele JSON ? Non.
4. V1-53 a-t-il lance `build_runner` ? Non.
5. V1-53 a-t-il ajoute un timer ? Non.
6. V1-53 a-t-il ajoute `isPlaying/currentTimeMs/playbackTimeMs` ? Non.
7. V1-53 a-t-il ajoute start/stop/pause/resume playback ? Non.
8. V1-53 a-t-il ajoute du seek ? Non.
9. V1-53 a-t-il ajoute un scrubber ? Non.
10. V1-53 a-t-il ajoute une preview runtime ? Non.
11. V1-53 a-t-il ajoute des boutons transport fonctionnels ? Non, disabled.
12. Si les boutons sont no-op, est-ce prouve par tests ? Non applicable.
13. Si les boutons sont disabled, est-ce clair dans l'UI ? Oui : disabled + badge `Controles de lecture a venir`.
14. La selection V1-52 reste-t-elle fonctionnelle ? Oui.
15. Le curseur V1-52 reste-t-il fonctionnel ? Oui.
16. Le bar layout V1-51 reste-t-il fonctionnel ? Oui.
17. Wait/Fade/Camera restent-ils fonctionnels ? Oui, suite Builder.
18. ActorFace reste-t-il fonctionnel ? Oui, suite Builder.
19. ActorMove reste-t-il fonctionnel ? Oui, suite Builder.
20. Les labels cible V1-50 restent-ils fonctionnels ? Oui, suite Builder.
21. Le design system est-il respecte ? Oui.
22. La Visual Gate prouve-t-elle les controls placeholders ? Oui.
23. L'Evidence Pack est-il complet sans placeholders ? Oui.
24. Prochain lot exact recommande : `NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`.

## 26. Recommandation pour le prochain lot

`NS-SCENES-V1-54 — Cinematic Timeline Visual Polish / Density Pass V0`

Objectif : polir la densite visuelle de la timeline : hauteur des lanes, taille des barres, labels, badges, spacing et lisibilite, sans ajouter de pouvoir runtime ni d'edition temporelle.

## 27. Statut Git final

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.png
```
