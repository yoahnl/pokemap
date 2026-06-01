# NS-SCENES-V1-51 — Cinematic Timeline Time Axis / Bar Layout V0

Date : 2026-06-02  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-50 — Cinematic Actor Movement Inspector Polish / Target Labels V0`  
Prochain lot recommande : `NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0`

## 1. Resume executif

V1-51 transforme la timeline du Cinematic Builder en projection temporelle lisible : axe horizontal, ticks, lanes derivees et barres proportionnelles aux durees visuelles.

La source de verite reste strictement `CinematicTimeline.steps`. Les champs `startMs` / `endMs` existent uniquement dans un read model derive, jamais dans le JSON, jamais dans un layout persiste.

Resultat produit :

- une regle temporelle est visible ;
- les blocs sont des barres horizontales dans leurs pistes ;
- les offsets viennent de l'ordre lineaire ;
- les largeurs viennent de `visualDurationMs` ;
- les durees absentes ou invalides utilisent un fallback visuel 300 ms ;
- la selection par barre synchronise preview sandbox et inspecteur ;
- les actions authoring V1-44 a V1-50 restent fonctionnelles ;
- aucun drag/drop, resize, reorder, playhead interactif, scrubber, transport playback ou runtime preview n'est ajoute.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_51_evidence_pack.md`.

## 2. Gate 0

Le Gate 0 a ete execute avant les edits V1-51. Le working tree n'etait pas propre : les changements V1-50 etaient deja presents et non commits. Ils ont ete preserves, non revert, et distingues des ajouts V1-51.

Sorties exactes reproduites dans l'Evidence Pack.

## 3. Fichiers lus

Instructions et contexte :

- `AGENTS.md`
- `agent_rules.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_48_cinematic_timeline_lane_grouping_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_49_cinematic_actor_movement_block_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_50_cinematic_actor_movement_inspector_polish_target_labels_v0.md`
- `/Users/karim/.codex/attachments/64f940d2-f2c6-460a-81de-d618cb3f76f1/pasted-text.txt`

Core :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_core/test/cinematics_library_read_model_test.dart`

Editor :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. Design Gate — Cinematic Timeline Time Axis / Bar Layout V0

1. Le time layout est un nouveau read model core dedie, pas une extension directe du lane read model, pour separer grouping par piste et projection temporelle.
2. Purete preservee : le read model vit dans `map_core`, importe seulement les modeles Cinematic et le lane read model, sans Flutter, runtime, disque ni mutation.
3. `startMs` = somme des `visualDurationMs` des steps precedents dans l'ordre lineaire global.
4. `endMs` = `startMs + visualDurationMs`.
5. `visualDurationMs` = `durationMs` si `durationMs > 0`, sinon fallback.
6. Fallback retenu : `cinematicTimelineFallbackVisualDurationMs = 300`.
7. `durationSource` distingue `explicit` et `fallback`.
8. `totalDurationMs` = somme des `visualDurationMs`.
9. Les ticks sont generes par intervalle : <=3000 ms : 500 ms ; <=10000 ms : 1000 ms ; <=30000 ms : 5000 ms ; au-dela : 10000 ms.
10. Les ticks sont affiches sans zoom via une ligne d'axe et un scroll horizontal si besoin.
11. Le mapping ms -> pixels est local a l'UI : `contentWidth / totalDurationMs`.
12. La largeur minimale cliquable est garantie par `_timelineBarMinWidth = 96`.
13. Un `totalDurationMs` tres court garde un contenu minimal derive du fallback 300 ms.
14. Un `totalDurationMs` long augmente l'intervalle des ticks et autorise le scroll horizontal.
15. L'ordre lineaire reste source de verite : aucun tri temporel, aucune edition de temps, aucun overlap authorable.
16. Pour eviter de faire croire a un vrai parallele, les badges rappellent `Ordre lineaire conserve` et `Layout temporel derive`.
17. La selection locale reste basee sur `step.id`.
18. L'inspecteur existant reste alimente par le step selectionne.
19. Les actions authoring existantes continuent d'utiliser la selection courante et les callbacks precedents.
20. Pas de drag/drop : V1-51 est une lecture temporelle, pas un editeur de montage.
21. Pas de resize : aucune duree n'est modifiee par la barre.
22. Pas de playhead interactif : le lot suivant peut ajouter un curseur placeholder non runtime, mais V1-51 n'en lance pas.
23. Pas de preview runtime : la preview reste `Apercu sandbox`.
24. Visual Gate produite : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png`.

## 5. Scope realise

- Ajout de `CinematicTimelineTimeLayoutReadModel` dans `map_core`.
- Export public via `packages/map_core/lib/map_core.dart`.
- Tests core dedies pour timing, fallback, ticks, lanes, actorMove et timeline vide.
- Remplacement de la zone timeline du Builder par un axe horizontal, ticks, lanes et barres.
- Selection depuis les barres preservee.
- Preview sandbox et inspecteur synchronises.
- Capture Visual Gate au ratio 1663x926 pour respecter la reference visuelle fournie.
- Roadmaps mises a jour vers V1-52.

### Ajustement proportionnel demande par l'utilisateur

Apres la premiere cloture V1-51, l'utilisateur a explicitement demande de reduire la taille de l'`Apercu sandbox` et d'augmenter la taille de la timeline pour se rapprocher de l'image de reference fournie.

Ajustement applique :

- hauteur timeline portee a 390 px ;
- preview sandbox laisse en zone flexible, donc visuellement reduit par la timeline agrandie ;
- header du Builder rendu responsive pour eviter les overflows sur la surface de test 1280x860 ;
- test widget ajoute pour verrouiller le ratio reference : timeline >= 360 px, preview <= 450 px ;
- capture Visual Gate regeneree apres ajustement.

## 6. Contrat Time Layout V0

Contrat ajoute :

- `CinematicTimelineTimeLayoutReadModel`
- `CinematicTimelineTimeLane`
- `CinematicTimelineTimeBlock`
- `CinematicTimelineTimeTick`
- `CinematicTimelineVisualDurationSource`
- `cinematicTimelineFallbackVisualDurationMs`
- `buildCinematicTimelineTimeLayoutReadModel(CinematicAsset cinematic)`

Le read model expose `lanes`, `blocks`, `ticks`, `totalDurationMs`, `stepCount`, `laneCount`, `isEmpty` et `laneById`.

## 7. Durees explicites et fallback visuel

Regle implementee :

```text
durationMs != null && durationMs > 0 -> explicit
durationMs absent ou <= 0 -> fallback 300 ms
```

Le fallback est visuel uniquement. Il ne mute pas `CinematicTimelineStep.durationMs` et ne devient pas une duree runtime.

## 8. Axe temporel et ticks

Les ticks affichent des labels courts :

```text
0 ms
500 ms
1 s
1.5 s
2 s
```

Pour les durees longues, les ticks deviennent plus grossiers afin de garder l'axe lisible.

## 9. Bar Layout UI

La section garde le titre `Timeline par pistes` et adopte le sous-titre :

```text
Projection temporelle derivee du deroule lineaire
```

Chaque piste affiche un label compact, un indicateur acteur/blocs, et des barres positionnees par `startMs`. Les barres affichent label, index, type, duree, fallback si pertinent, acteur/cible/mode quand disponible.

Le mapping pixel reste local a `cinematic_builder_workspace.dart` et n'est pas expose au core.

## 10. Selection depuis les barres

Cliquer une barre appelle le callback existant avec le `CinematicTimelineStep`. La selection reste locale, par `step.id`, et synchronise :

- l'etat visuel de la barre ;
- la preview sandbox ;
- l'inspecteur ;
- les actions authoring qui utilisent la selection.

## 11. Compatibilite V1-48 / V1-50

V1-48 reste la source du grouping par lanes. V1-51 enveloppe cette projection pour ajouter du temps derive.

V1-50 reste preserve :

- labels cibles actorMove visibles ;
- resume humain actorMove ;
- edition/suppression cible ;
- protection cible utilisee ;
- `pathMode=direct` toujours verrouille ;
- Library summary et bridge legacy inchanges.

## 12. Restrictions anti-drag / anti-runtime

Confirme :

- pas de drag/drop de blocs ;
- pas de resize ;
- pas de reorder ;
- pas d'overlap authorable ;
- pas de start/end persistés ;
- pas de playhead interactif ;
- pas de scrubber ;
- pas de transport playback ;
- pas de runtime preview ;
- pas de pathfinding ;
- pas de coordonnees libres ;
- pas de modification `map_runtime`, `map_gameplay`, `map_battle`, `examples`.

## 13. Legacy bridge policy inchangee

Les `ScenarioAsset` / bridges legacy restent exclus du Builder canonique. V1-51 n'a pas modifie la politique Library -> Builder et n'a ajoute aucune migration.

## 14. Design system

La UI utilise les tokens et primitives PokeMap existants : `context.pokeMapColors`, `PokeMapPanel`, `PokeMapCard`, `PokeMapBadge`, `PokeMapButton`, tons derives et icones Cupertino existantes.

Check `rg -n "Color\\(|Colors\\.|0xFF|0xff"` sur les fichiers UI modifies : sortie vide.

## 15. Tests ajoutes ou modifies

Ajoutes :

- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`

Modifies :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Tests principaux ajoutes :

- derive `startMs/endMs` depuis l'ordre lineaire ;
- `durationSource explicit/fallback` ;
- fallback 300 ms ;
- ticks courts et longs ;
- lanes acteur inconnues ;
- axe visible ;
- bar widths relatives ;
- offsets par ordre ;
- selection depuis barre ;
- proportions preview sandbox / timeline conformes a la demande utilisateur ;
- absence visible de drag/resize ;
- capture V1-51.

## 16. Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png
```

Preuve image :

```text
PNG 1663 x 926
SHA1 c7abc4442a6ce9ae5a2bdfab7f43d5ae7f3f2ef2
SHA256 f2a4e6446eba9a19080afe5ae5cff1de20ac708059818bf9f1575af7e41c2380
```

La capture montre Builder, palette, preview sandbox reduit, timeline agrandie avec axe/ticks/barres, bloc selectionne et inspecteur synchronise.

## 17. Commandes executees

Voir Evidence Pack pour les sorties exactes.

Commandes principales :

- `dart test test/cinematic_timeline_time_layout_read_model_test.dart`
- `dart test test/cinematic_timeline_lane_read_model_test.dart`
- `dart test test/cinematics_library_read_model_test.dart`
- `dart analyze`
- `flutter test --reporter=compact test/cinematic_builder_workspace_test.dart`
- `flutter test --reporter=compact test/cinematics_library_workspace_test.dart`
- `flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart`
- `flutter test --update-goldens --dart-define=NS_SCENES_V1_51_CAPTURE_CINEMATIC_TIMELINE_BAR_LAYOUT=true --reporter=compact test/cinematic_builder_workspace_test.dart`

## 18. Resultats des tests

Tous les tests cibles relances passent. Details exacts dans l'Evidence Pack.

## 19. Analyze

`map_core` : `No issues found!`  
`map_editor` cible : `No issues found! (ran in 1.1s)`

## 20. Checks anti-scope

Checks executes et documentes dans l'Evidence Pack :

- runtime/gameplay/battle/examples : sortie vide ;
- anti-runtime : sortie vide ;
- anti-playback : sortie vide ;
- anti-pathfinding strict : sortie vide ;
- anti-couleurs hardcodees : sortie vide ;
- anti-Selbrume : sortie vide ;
- occurrences `startMs/endMs` limitees au read model derive, au test core et au mapping UI.

## 21. Fichiers crees

- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.png`

## 22. Fichiers modifies

V1-51 :

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Changements V1-50 preexistants dans le working tree, preserves :

- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- rapport/screenshot V1-50 non suivis.

## 23. Roadmaps mises a jour

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Les roadmaps marquent V1-51 DONE et recommandent un seul prochain lot :

```text
NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0
```

## 24. Limites connues

- La preview reste sandbox.
- Les barres ne sont pas deplacables.
- Les barres ne sont pas redimensionnables.
- Les pistes ne representent pas encore du parallelisme runtime.
- Pas de zoom timeline.
- Pas de curseur/playhead interactif.
- Aucun son/FX/dialogue cinematic authorable nouveau.

## 25. Non-objectifs confirmes

Non faits : runtime, playback visuel, `PlayableMapGame`, pathfinding, coordonnees, migration `ScenarioAsset`, bridge legacy dans Builder, donnees Selbrume, Mael/Lysa/Port des Brisants, mini-editeur de montage.

## 26. Evidence Pack

Annexe : `reports/narrativeStudio/scenes/ns_scenes_v1_51_evidence_pack.md`.

## 27. Auto-review critique

Voir la section auto-review detaillee de l'Evidence Pack. Verdict : les criteres V1-51 sont couverts par tests, analyze, capture et checks anti-scope ; le lot reste une projection visuelle derivee, pas une timeline editable.

## 28. Recommandation pour le prochain lot

Un seul prochain lot exact :

```text
NS-SCENES-V1-52 — Cinematic Timeline Selection Cursor / Playhead Placeholder V0
```

Objectif : ajouter un curseur de selection / playhead placeholder non runtime, sans lecture reelle, sans scrubber et sans transport fonctionnel.
