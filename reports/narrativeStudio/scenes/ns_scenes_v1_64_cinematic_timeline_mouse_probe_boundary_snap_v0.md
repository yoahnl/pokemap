# NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0

Date : 2026-06-03
Statut : DONE
Type : editor / UI locale / interaction non persistante
Lot precedent : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`
Prochain lot recommande : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0`

## 1. Resume executif

V1-64 implemente le magnetisme local du repere souris de la timeline Cinematic Builder. Le contrat repris de V1-63 est l'Option E : snap aux bords `0 ms` / `totalDurationMs` et aux debuts/fins de blocs, avec seuil fixe de `8 px`, sans snap aux ticks arbitraires.

Le lot reste strictement editor-only : aucune mutation `ProjectManifest`, aucun runtime, aucun playback, aucun seek runtime, aucun scrubber runtime, aucun drag/resize/reorder de blocs.

## 2. Gate 0

Commande executee depuis la racine avant toute modification V1-64 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides avant V1-64. Le commit V1-63 est deja present dans l'historique local.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

## 4. Design Gate — Cinematic Timeline Mouse Probe Boundary Snap V0

1. Contrat V1-63 implemente : Option E, snap hybride bords de timeline + starts/ends de blocs, jamais ticks.
2. `timelineProbeTimeMs` vit aujourd'hui dans `_CinematicBuilderWorkspaceState` comme etat local editor-only.
3. Le hint de snap local vit au meme niveau que `timelineProbeTimeMs`, dans un etat local non persistant.
4. Le hint doit rester editor-local car il decrit seulement une inspection souris temporaire, pas une donnee du cinematic.
5. Snap targets utilisees : `0 ms`, `totalDurationMs`, `block.startMs`, `block.endMs`.
6. Les ticks sont exclus car ils sont des reperes de lecture visuelle, pas des bornes semantiques du contenu.
7. `snapThresholdPx` est constant a `8`.
8. Une distance temps devient une distance pixels via `abs(targetTimeMs - freeTimeMs) * pixelsPerMs`.
9. La comparaison souris/target se fait en pixels dans le contenu horizontal scrollable : `abs(targetX - freeX) <= 8`.
10. Les targets identiques sont dedupliquees par `timeMs` avec priorite semantique stable.
11. `0 ms` gagne contre `block.startMs` identique.
12. `totalDurationMs` gagne contre `block.endMs` identique.
13. Deux cibles proches sont departagees par distance pixels, puis start avant end, puis plus petit `stepIndex`, puis ordre stable.
14. Un bloc fallback 300 ms participe via `block.startMs` et `block.endMs` visuel.
15. Une timeline vide ne crashe pas et conserve le comportement existant sans snap absurde.
16. Une timeline tres courte utilise le meme seuil pixels, avec dedupe pour eviter les hints incoherents.
17. Une timeline tres longue garde un seuil pixels stable, donc pas de seuil temps fixe.
18. Le scroll horizontal est gere car les gestures fournissent une position locale dans le contenu scrollable, pas dans l'ecran.
19. Le badge affiche `Repere : <temps>` libre et `Repere : <temps> · <hint>` quand snap actif.
20. Le vocabulaire playback/seek/scrub est evite dans l'UI ajoutee ; les termes restent seulement dans les non-objectifs/tests anti-scope.
21. `selectedStepId` est preserve : le snap ne selectionne aucun bloc.
22. L'inspecteur est preserve : il reste derive de `selectedStepId`.
23. La preview sandbox reste non-runtime et affiche seulement le repere temporel.
24. Hover V1-55 est preserve : hover ne definit pas probe/snap et reste informatif.
25. Aide clavier V1-60 est preservee sans nouvelle aide souris.
26. Transports V1-53 restent disabled, `onPressed` reste `null`.
27. La non-mutation `ProjectManifest` est prouvee par tests `project.toJson()` et compteur `onProjectChanged`.
28. Il n'y a pas de playback car aucun etat/commande de lecture n'est ajoute.
29. Il n'y a pas de seek runtime car le temps calcule reste un repere local non transmis au runtime.
30. Il n'y a pas de drag/drop de blocs car les handlers restent sur le fond/axe du probe, pas sur les cartes.
31. Visual Gate : capture Flutter du Builder avec badge `Repere` snappe, timeline dense, inspecteur stable et transports disabled.
32. Prochain lot exact recommande : `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0`.

## 5. Scope realise

V1-64 ajoute uniquement le magnetisme local du repere souris de la timeline Cinematic Builder.

Scope livre :

- snap aux bords `0 ms` et `totalDurationMs` ;
- snap aux `block.startMs` et `block.endMs` derives du read model temporel ;
- seuil fixe `_timelineProbeSnapThresholdPx = 8.0` ;
- hint local de snap affiche dans le badge ;
- click, drag et release preserves depuis V1-62 ;
- selection, inspecteur, preview sandbox, hover, aide clavier et transports preserves ;
- tests widget cibles, Visual Gate et roadmaps.

## 6. Contrat V1-63 implemente

Le contrat implemente est l'Option E : snap hybride bords + blocs, jamais ticks. La phrase canonique du lot est respectee : V1-64 ajoute le magnetisme local du repere souris et ne transforme pas la timeline en editeur temporel.

## 7. Snap targets

Targets autorisees :

- `timelineStart` a `0 ms` ;
- `timelineEnd` a `totalDurationMs` ;
- `blockStart` a `block.startMs` ;
- `blockEnd` a `block.endMs`.

Les ticks, milieux de blocs, frames internes, grids arbitraires et positions runtime interpolees ne sont jamais crees comme targets.

## 8. Seuil 8 px

Le seuil est code comme constante locale :

```text
_timelineProbeSnapThresholdPx = 8.0
```

La comparaison se fait en pixels, pas en millisecondes fixes, pour conserver un ressenti stable quelle que soit la duree totale de la timeline.

## 9. Resolution du snap

La resolution suit le pipeline :

```text
position locale souris -> temps libre clampé -> targets temporelles -> distance pixels -> snap si <= 8 px
```

Le resultat transmis au widget parent est un `_TimelineProbeSnapResult` qui contient le `timeMs` local et un hint optionnel. Si aucune cible n'est assez proche, le hint vaut `null`.

## 10. Tie-breaks

Les targets identiques sont dedupliquees par `timeMs`. Les priorites stables sont :

1. debut timeline ;
2. debut bloc ;
3. fin timeline ;
4. fin bloc.

Quand plusieurs targets differentes sont proches, le choix se fait par distance pixels, puis priorite semantique, puis `stepIndex`, puis ordre stable.

## 11. Badge Repere et hint d'alignement

Badge libre :

```text
Repère : <temps>
```

Badge snappe :

```text
Repère : <temps> · début timeline
Repère : <temps> · fin timeline
Repère : <temps> · début bloc
Repère : <temps> · fin bloc
```

Aucun libelle `Lecture`, `Playback`, `Seek`, `Scrub`, `Temps courant` ou `Position runtime` n'est ajoute.

## 12. Click / drag / release

Le click et le drag sur l'axe/fond appellent la meme resolution. Le snap est donc immediat au click et vivant pendant le drag. La release conserve la derniere position calculee, libre ou snappee.

## 13. Edge cases bords / fallback / scroll

- Les bords `0` et `totalDurationMs` participent au snap.
- Les blocs a duree visuelle fallback participent via `block.startMs` et `block.endMs`.
- Le scroll horizontal est respecte car la position locale envoyee a `_resolveTimelineProbeSnap` est exprimee dans le contenu scrollable.
- Une timeline vide ou non positive retombe sur le temps libre clampé sans hint absurde.

## 14. Relation avec selectedStepId

Le snap ne change jamais `selectedStepId`. Le test principal selectionne d'abord un bloc, place ensuite un probe snappe, puis verifie que l'inspecteur reste sur le bloc selectionne.

## 15. Relation avec preview sandbox

La preview sandbox reste informative et non-runtime. Elle peut afficher le repere temporel courant, mais elle ne joue pas la cinematic, n'interpole aucun acteur et ne declenche aucun runtime.

## 16. Relation avec hover / aide / transport

Hover reste informatif, l'aide clavier V1-60 reste accessible, et les transports Reset / Play / Stop restent des placeholders disabled. V1-64 ne rend aucun bouton fonctionnel.

## 17. Restrictions anti-playback / anti-runtime / anti-editor temporel

Confirme :

- pas de playback ;
- pas de timer ;
- pas de seek runtime ;
- pas de scrubber runtime ;
- pas de transport fonctionnel ;
- pas de drag/resize/reorder de blocs ;
- pas de persistance temporelle ;
- pas de mutation `ProjectManifest` ;
- pas de modification `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.

## 18. Legacy bridge policy inchangee

Les cinematics legacy bridge restent exclues du Builder canonique. V1-64 ne modifie ni la Library ni la politique bridge ; la suite `cinematics_library_workspace_test.dart` confirme la non-regression.

## 19. Design system

Le lot reutilise les surfaces, badges, icons, tokens et couleurs existants. Aucune couleur hardcodee n'est ajoutee dans le fichier UI modifie ; la recherche `Color\(|Colors\.|0xFF|0xff` sur `cinematic_builder_workspace.dart` retourne vide.

## 20. Tests ajoutes ou modifies

Tests V1-64 principaux dans `packages/map_editor/test/cinematic_builder_workspace_test.dart` :

- `snaps local timeline time probe to block boundaries without changing selection` ;
- `snaps local timeline time probe to timeline start and end` ;
- `snaps local timeline time probe to shared block boundary` ;
- `snap chooses nearest semantic target when boundaries overlap` ;
- `snap respects horizontal scroll offset` ;
- `keeps hover help and disabled transports after snapped probe` ;
- `captures V1-64 cinematic timeline mouse probe snap when requested`.

Tests V1-62/V1-63 adaptes :

- le test drag/clamp attend maintenant les hints snappes aux bords et aux starts ;
- les tests de clear par selection et navigation clavier preservent le comportement existant.

## 21. Visual Gate

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  232656 Jun  3 14:49 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
f75ed00ff9a5ccce12c88fc66d9d1f7da12df80dc0aa007d3c6cff23414acb77  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png
```

## 22. Commandes executees

Commandes principales :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'snaps local timeline time probe to block boundaries without changing selection'
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart && dart test test/cinematic_timeline_lane_read_model_test.dart && dart analyze
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_64_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_SNAP=true --reporter=compact test/cinematic_builder_workspace_test.dart
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 23. Resultats des tests

RED cible avant implementation :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Repère : 500 ms · début bloc": []>
```

GREEN cible apres implementation :

```text
00:02 +1: All tests passed!
```

Suite Builder finale :

```text
00:09 +59: All tests passed!
```

Suite Library finale :

```text
00:03 +10: All tests passed!
```

Core non-regression :

```text
00:00 +4: All tests passed!
00:00 +2: All tests passed!
Analyzing map_core...
No issues found!
```

Visual Gate :

```text
00:09 +59: All tests passed!
```

## 24. Analyze

Analyse ciblee editor :

```text
Analyzing 2 items...
No issues found! (ran in 1.1s)
```

Analyse core :

```text
Analyzing map_core...
No issues found!
```

## 25. Checks anti-scope

Resultats importants :

- `git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples` : sortie vide ;
- recherche anti-runtime sur les deux fichiers Dart modifies : sortie vide ;
- recherche anti-playback/timer/transport fonctionnel sur les deux fichiers Dart modifies : sortie vide ;
- recherche anti-seek/scrub sur les deux fichiers Dart modifies : sortie vide ;
- recherche anti-persistance temporelle/probe dans `map_core/lib/src/models`, `authoring`, `diagnostics` : sortie vide ;
- recherche couleurs hardcodees dans le fichier UI modifie : sortie vide ;
- recherche image IA sur les fichiers V1-64 : sortie vide.

La recherche anti-drag/resize/reorder sur les deux fichiers Dart retourne uniquement des tests negatifs existants ou ajoutes :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:522:  testWidgets('snap chooses nearest semantic target when boundaries overlap',
packages/map_editor/test/cinematic_builder_workspace_test.dart:789:  testWidgets('dragging a timeline block does not move or resize it',
packages/map_editor/test/cinematic_builder_workspace_test.dart:823:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:824:    expect(find.text('reorder'), findsNothing);
```

La recherche Selbrume retourne des mentions historiques dans les roadmaps seulement ; aucun hit dans les deux fichiers Dart modifies et aucune donnee Selbrume n'est creee.

## 26. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_64_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.png`

## 27. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`

## 28. Roadmaps mises a jour

Les deux roadmaps marquent V1-64 en DONE et recommandent un seul prochain lot exact :

```text
NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0
```

## 29. Limites connues

- Le snap est une aide visuelle locale, pas un outil d'edition temporelle.
- `fin bloc` peut etre masque par `fin timeline` quand la fin du dernier bloc coincide avec la fin globale, ce qui suit les priorites de deduplication.
- Les controles d'effacement explicite du probe ne sont pas ajoutes ; ils sont reserves a V1-65.

## 30. Non-objectifs confirmes

Non faits :

- aucun runtime ;
- aucun playback ;
- aucun seek/scrub runtime ;
- aucun drag/resize/reorder ;
- aucun `build_runner` ;
- aucun changement `map_core` ;
- aucune donnee Selbrume ;
- aucune image IA.

## 31. Evidence Pack

Annexe creee :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_64_evidence_pack.md
```

Elle rassemble Gate 0, sorties RED/GREEN, Visual Gate, checks anti-scope, stats de diff, status final et auto-review.

## 32. Auto-review critique

1. `map_runtime` modifie ? Non.
2. `map_gameplay`, `map_battle`, `examples` modifies ? Non.
3. Modele JSON modifie ? Non.
4. `build_runner` lance ? Non.
5. Playback ajoute ? Non.
6. Timer ajoute ? Non.
7. `isPlaying/currentTimeMs/playbackTimeMs` ajoutes ? Non.
8. Seek runtime ajoute ? Non.
9. Scrubber runtime ajoute ? Non.
10. Transport controls fonctionnels ? Non.
11. Drag de bloc ajoute ? Non.
12. Resize ajoute ? Non.
13. Reorder ajoute ? Non.
14. Nouvelle capability authoring ? Non, inspection locale seulement.
15. Snap local editor-only ? Oui.
16. Snap non persiste ? Oui.
17. Ticks exclus ? Oui.
18. `0 ms` / `totalDurationMs` targets ? Oui.
19. `block.startMs` / `block.endMs` targets ? Oui.
20. Seuil `8 px` ? Oui.
21. Tie-breaks implementes ? Oui.
22. Badge indique le snap ? Oui.
23. `selectedStepId` stable ? Oui.
24. Inspecteur stable ? Oui.
25. Preview sandbox non-runtime ? Oui.
26. Hover/help/transport preserves ? Oui.
27. `ProjectManifest` non mute ? Oui, tests.
28. Design system respecte ? Oui.
29. Visual Gate prouve le snap ? Oui.
30. Evidence Pack cree ? Oui.
31. Prochain lot exact recommande ? `NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0`.

## 33. Recommandation pour le prochain lot

Recommandation unique :

```text
NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0
```

Justification : V1-64 a pose l'aimant local. La prochaine amelioration utile est de rendre l'etat du repere plus comprehensible et reversible pour l'utilisateur : clear explicite, eventuel Escape, libelles selection/repere, aide legere. Ce futur lot doit rester sans playback, seek runtime, drag de blocs, runtime ou mutation.
