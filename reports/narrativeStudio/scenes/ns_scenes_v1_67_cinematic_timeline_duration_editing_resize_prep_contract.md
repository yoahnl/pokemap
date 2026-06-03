# NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract

Date : 2026-06-03
Statut : DONE
Type : documentaire / interaction-contract / roadmap correction
Lot precedent : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0`
Prochain lot recommande : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`

## 1. Resume executif

V1-67 corrige la trajectoire post V1-66 : on ne part pas tout de suite sur le polish de scroll/visibility. Le besoin produit prioritaire devient l'edition de duree des blocs cinematic.

Phrase canonique :

```text
V1-67 definit comment modifier la duree des blocs.
V1-67 ne code pas encore le resize.
```

Decision principale : retenir **Option C — Inspecteur d'abord, resize souris ensuite**.

Ordre recommande :

```text
NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0
NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0
```

Le polish scroll/visibility precedemment recommande pour V1-67 est deplace en backlog futur, recommande ici comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`.

## 2. Gate 0

Commande executee depuis la racine avant toute modification V1-67 :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
e67e71c7 feat(narrative): add cinematic timeline mouse probe help selection explanation v0 (NS-SCENES-V1-66)
46cc0eb4 feat(narrative): add cinematic timeline mouse probe UX polish clear controls v0 (NS-SCENES-V1-65)
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
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
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime. Le working tree etait propre et V1-66 etait committe en tete locale.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_66_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_49_cinematic_actor_movement_block_v0.md`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`

## 4. Pourquoi ce lot remplace le Scroll / Visibility Polish

V1-66 a ferme l'ambiguite UX autour du repere souris : probe local, snap, clear, aide repere et aide clavier sont maintenant comprehensibles et non mutants.

Le prochain blocage produit n'est plus de rendre la selection plus visible par scroll automatique. Le blocage est de commencer a authorer le rythme : raccourcir une attente, allonger un fondu, ralentir un actorMove. Avant d'ajouter un geste de resize, il faut definir exactement ce que ce geste modifie.

Le remplacement est donc volontaire :

```text
Ancien V1-67 : Cinematic Timeline Scroll / Visibility Polish V0
Nouveau V1-67 : Cinematic Timeline Duration Editing / Resize Prep Contract
```

## 5. Pourquoi ce lot est documentaire

Modifier une duree semble local, mais le layout temporel est derive lineairement :

```text
step 1 startMs = 0
step 1 endMs = duration
step 2 startMs = step1.endMs
step 3 startMs = step2.endMs
```

Changer `durationMs` sur un bloc decale donc tous les blocs suivants. Ce n'est pas encore une timeline libre avec positions absolues, overlaps et pistes persistantes. V1-67 doit fixer ce contrat avant V1-68/V1-69.

V1-67 ne modifie aucun package, aucun test, aucun modele et aucun widget.

## 6. Etat actuel apres V1-66

Acquis :

- timeline par pistes ;
- axe temporel ;
- barres proportionnelles ;
- `startMs` / `endMs` derives dans le read model ;
- selection locale ;
- probe souris local click/drag ;
- snap local du probe ;
- clear explicite `Effacer le repère` ;
- aide `Aide repère` ;
- aide clavier ;
- navigation clavier ;
- hover details ;
- transports disabled.

Gaps produit :

- pas de champ numerique de duree ;
- pas de validation min/max no-code dans l'inspecteur ;
- pas de resize souris ;
- pas de contrat de handle droit ;
- pas de decision sur le probe apres changement de duree ;
- pas de bornes max strictes au-dela de `durationMs > 0`.

## 7. Pass A — Audit durationMs / CinematicTimelineStep

`durationMs` vit aujourd'hui sur `CinematicTimelineStep` :

```text
final int? durationMs;
```

Il est lu/ecrit dans le JSON de chaque step via la cle `durationMs`. Le modele ne stocke pas `startMs` ni `endMs` sur le step. Ces deux valeurs sont derivees par le read model.

Le modele accepte techniquement `durationMs` sur tout kind de step, car le champ est commun. En revanche, les operations authoring V0 limitent ce qui peut etre cree ou modifie proprement.

Validation actuelle cote operations authoring : `_validateDuration` refuse uniquement `durationMs <= 0`. Il n'existe pas encore de min par type, max global, snap/pas, champ numerique ou validation UI detaillee.

## 8. Pass B — Audit des blocs authoring-owned

Un bloc authoring-owned est un step cree par le Cinematic Builder V0 et marque par metadata :

```text
authoring.source = cinematic-builder-v0
authoring.kind = draft ou basicBlock
authoring.block = wait / fade / camera / actorFace / actorMove
```

Predicats actuels :

- `isCinematicTimelineDraftStep`
- `isCinematicTimelineBasicBlockStep`
- `isCinematicTimelineActorFacingStep`
- `isCinematicTimelineActorMoveStep`
- `isCinematicTimelineAuthoringStep`

Blocs authoring-owned actuels :

| Bloc | Kind | Duree explicite actuelle | Operation update actuelle | Editable duree V1-68 recommande |
|---|---|---:|---|---|
| Attente | `wait` | oui, defaut `1000 ms` | `updateCinematicTimelineBasicBlockStep` | oui |
| Fondu | `fade` | oui, defaut `1000 ms` | `updateCinematicTimelineBasicBlockStep` | oui |
| Camera | `camera` | oui, defaut `500 ms` | `updateCinematicTimelineBasicBlockStep` | oui |
| Orientation acteur | `actorFace` | non, fallback visuel `300 ms` | update acteur/direction seulement | oui, mais V1-68 doit etendre explicitement l'operation |
| Deplacement acteur | `actorMove` | oui, defaut `1000 ms` | `updateCinematicTimelineActorMoveStep` | oui |
| Brouillon marker | `marker` | non, `durationMs == null` | suppression seulement | non en V1-68 sauf contrat futur explicite |

Blocs non-owned/non editables V0 :

- steps legacy/bridge sans metadata authoring ;
- `dialogueLine` ;
- `sound` ;
- `music` ;
- `shake` ;
- `fx` ;
- `actorEmote` ;
- `marker` sans duree explicite ;
- tout step dont l'id/metadata ne passe pas les predicats authoring V0.

## 9. Pass C — Audit du time layout derive

`buildCinematicTimelineTimeLayoutReadModel` parcourt `cinematic.timeline.steps` dans l'ordre lineaire. Pour chaque step :

```text
visualDurationMs = durationMs si durationMs > 0, sinon fallback 300 ms
startMs = currentMs
endMs = startMs + visualDurationMs
currentMs = endMs
```

Constante actuelle :

```text
cinematicTimelineFallbackVisualDurationMs = 300
```

Implications :

- changer `durationMs` d'un step ne deplace pas ce step par position absolue ;
- les blocs suivants se recalculent automatiquement parce que leurs `startMs` sont derives ;
- `totalDurationMs` change ;
- ticks et largeurs de barres se recalculent ;
- aucun champ `startMs` / `endMs` n'est persiste.

## 10. Pass D — Audit probe souris / snap / clear / aide

Le probe souris actuel est local au widget editor :

- `timelineProbeTimeMs` ;
- `timelineProbeSnapHint` ;
- clear via selection bloc/clavier/Escape/controle `Effacer le repère` ;
- snap V1-64 sur 0, fin totale, debuts/fins de blocs ;
- aide V1-66 visible seulement avec probe actif.

Contrat V1-67 : toute modification reelle de duree en V1-68/V1-69 doit clear le probe, pas le clampler.

Raison :

- une duree modifiee peut invalider la position temporelle inspectee ;
- clear est simple, comprehensible et deja coherent avec la selection de bloc ;
- clamp peut donner l'impression d'un current time suivi par le runtime.

## 11. Design Gate — Cinematic Timeline Duration Editing / Resize Prep Contract

1. `durationMs` vit aujourd'hui sur `CinematicTimelineStep` comme `int?`, serialise en JSON par step.
2. Les blocs authoring-owned actuels avec duree explicite sont `wait`, `fade`, `camera` et `actorMove`. Des steps non-owned peuvent techniquement porter `durationMs`, mais ne sont pas authoring-owned.
3. Les blocs avec fallback actuel sont ceux dont `durationMs == null` ou `durationMs <= 0`, notamment `actorFace`, `marker` draft et les legacy/non-owned sans duree.
4. Peuvent etre edites sans changer le schema : `wait`, `fade`, `camera`, `actorMove`; `actorFace` peut aussi recevoir `durationMs` sans schema, mais demande d'etendre son operation authoring.
5. Ne doivent pas etre editables : non-owned, legacy bridge, dialogueLine, sound/music/fx/shake/actorEmote, marker sans duree explicite.
6. Un bloc authoring-owned est un step cree par le Builder V0 et reconnu par metadata `authoring.source`, `authoring.kind`, `authoring.block`.
7. Ne pas modifier les steps non-owned evite de corrompre des donnees importees/bridgees dont le contrat d'authoring n'est pas possede par le Builder.
8. `startMs` doit rester derive pour conserver le modele lineaire simple et eviter une timeline libre trop tot.
9. `endMs` doit rester derive pour eviter de stocker deux sources de verite (`durationMs` et `endMs`).
10. Une duree modifiee change `visualDurationMs`; le read model recalcule ensuite tous les `startMs` suivants.
11. Duree minimale : `100 ms` pour wait/fade/camera/actorFace, `200 ms` pour actorMove.
12. Duree maximale : `30 000 ms` par bloc en V0.
13. Les durees doivent combiner presets no-code et saisie numerique bornee, pas etre uniquement libres ni uniquement presets.
14. L'inspecteur V1-68 doit proposer champ numerique en ms, presets rapides et boutons `-100` / `+100` si l'UI reste lisible.
15. Le resize souris V1-69 doit modifier seulement le bord droit.
16. Le bord gauche reste interdit car le deplacer reviendrait a modifier `startMs`.
17. Le deplacement complet du bloc reste interdit car il impliquerait start libre, reorder ou gap/overlap.
18. Le resize doit snapper legerement.
19. Snap recommande : quantification au pas `100 ms` avec presets visibles ; pas de snap aux blocs voisins en V0. Les ticks visuels restent informatifs.
20. Le snap du repere souris V1-64 est preserve : il reste un snap d'inspection, separe du snap de duration.
21. Le probe souris V1-62 est preserve : il reste local, et sera clear apres changement de duree.
22. Navigation clavier V1-57/V1-59 preservee : selectionner un bloc reste selectionner un step, pas une position temps libre.
23. Aide repere V1-66 preservee : elle continue d'expliquer le repere local, pas la duree.
24. Pas de playback : aucune horloge, aucun bouton Play actif, aucune interpolation.
25. Pas de seek runtime : aucun `currentTimeMs`, `playbackTimeMs` ou position runtime n'est introduit.
26. Pas de timeline libre : pas de `startMs` persiste, pas d'`endMs` persiste, pas d'overlap authorable.
27. Tests V1-68 : edition inspecteur, min/max, invalid input, recalcul layout, clear probe, transports disabled.
28. Tests V1-69 : handle droit, drag augmente/diminue, clamp, pas de drag body/gauche/lane, clear probe, pas de start/end persist.
29. Prochain lot exact recommande : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`.

## 12. Pass E — Options comparees

| Option | Verdict | Avantages | Inconvenients |
|---|---|---|---|
| A — Edition inspecteur seulement | Insuffisant seul | simple, peu risque, facile a tester, preserve le lineaire | moins naturel qu'un outil de montage |
| B — Resize souris bord droit seulement | Trop tot seul | feeling montage immediat, garde start derive | fragile UI, risque confusion drag de bloc, hit testing/test plus difficiles |
| C — Inspecteur puis resize souris | Retenue | progressif, testable, pose le modele avant le geste | demande deux lots |
| D — Timeline libre complete | Rejetee | plus proche Final Cut | trop tot, casse le modele lineaire, ouvre overlap, migrations et runtime playback |

## 13. Option recommandee

Option C est retenue.

V1-68 implemente l'edition de `durationMs` depuis l'inspecteur pour les blocs authoring-owned supportes. V1-69 ajoute ensuite le resize souris par handle droit, en reutilisant le meme contrat de validation.

## 14. Pass F — Contrat Duration Editing Inspector V0

V1-68 doit :

- ajouter une edition inspecteur claire de `durationMs` ;
- rester no-code : champ numerique ms, presets, boutons incrementaux ;
- refuser les valeurs invalides inline ;
- appeler les operations authoring existantes ou les etendre minimalement ;
- clear le probe local apres toute modification acceptee ;
- ne pas activer les transports ;
- ne pas creer de `startMs` / `endMs` persistants ;
- ne pas modifier les steps non-owned.

Presets recommandes :

```text
100 ms
250 ms
500 ms
1000 ms
1500 ms
2000 ms
3000 ms
```

Pas d'increment recommande :

```text
-100 ms / +100 ms
```

## 15. Pass G — Contrat Timeline Resize Handles V0

V1-69 doit :

- afficher un handle uniquement sur le bord droit des barres editables ;
- drag horizontal du handle uniquement ;
- convertir `deltaX` en `deltaMs` via l'echelle temporelle courante ;
- calculer `durationMs = clamp(originalDurationMs + deltaMs)` ;
- quantifier la valeur finale au pas `100 ms` ;
- recalculer immediatement la barre et les blocs suivants ;
- conserver la duree au release ;
- restaurer la duree initiale au cancel ;
- ne jamais modifier lane, ordre, `selectedStepId`, `startMs` ou `endMs`.

Interdits V1-69 :

```text
drag du bloc entier
drag du bord gauche
resize vertical
changement de lane
overlap
reorder
startMs persiste
endMs persiste
transport fonctionnel
playback
```

## 16. Blocs editables / non editables

Editables V1-68 :

- `wait` authoring-owned ;
- `fade` authoring-owned ;
- `camera` authoring-owned ;
- `actorMove` authoring-owned ;
- `actorFace` authoring-owned, a condition d'etendre explicitement son operation update pour accepter `durationMs`.

Non editables V1-68/V1-69 :

- non-owned ;
- legacy bridge ;
- `dialogueLine` ;
- `sound` ;
- `music` ;
- `shake` ;
- `fx` ;
- `actorEmote` ;
- marker draft sans duree explicite ;
- tout bloc dont la metadata authoring est absente ou incoherente.

Cas marker draft : non editable dans V1-68, sauf futur lot dedie qui creerait explicitement des markers timed.

## 17. Durees min/max

Minima recommandes :

| Bloc | Min V0 |
|---|---:|
| wait | 100 ms |
| fade | 100 ms |
| camera | 100 ms |
| actorFace | 100 ms |
| actorMove | 200 ms |

Maximum recommande :

```text
30 000 ms
```

Raison : 30 secondes suffisent pour V0, limitent les erreurs no-code et gardent la timeline lisible. L'alternative 60 secondes est repoussee tant que le Builder n'a pas de zoom temporel/scroll polish dedie.

Valeurs interdites :

- `durationMs <= 0` ;
- valeur non numerique ;
- NaN/Infinity cote UI ;
- valeur hors min/max ;
- valeur qui cree un contournement de timeline libre.

## 18. Presets et saisie numerique

Les presets actuels dans l'UI sont :

```text
500, 1000, 1500, 2000, 3000
```

V1-68 doit les etendre pour couvrir les temps courts :

```text
100, 250, 500, 1000, 1500, 2000, 3000
```

Le champ numerique doit rester borne par les memes regles que les presets. Il ne doit pas exposer JSON brut ni ID technique.

## 19. Relation avec layout derive startMs/endMs

Le layout reste derive :

- `startMs` vient de l'accumulation des durees precedentes ;
- `endMs = startMs + visualDurationMs` ;
- `visualDurationMs = durationMs` si explicite et positif, sinon fallback ;
- les blocs suivants se recalent automatiquement.

V1-68/V1-69 ne doivent ajouter aucun stockage de position absolue. Le seul changement persistant autorise est `durationMs` sur un step authoring-owned supporte.

## 20. Relation avec probe souris

Decision : clear du probe apres modification de duree.

Rejet du clamp par defaut :

- clampler peut faire croire que le probe suit un temps courant ;
- la position inspectee avant changement n'est plus necessairement utile apres recalcul ;
- le clear est deja coherent avec plusieurs interactions de selection.

Le curseur de selection, lui, reste derive du bloc selectionne et se recale naturellement sur le nouveau `startMs`.

## 21. Relation avec preview future

Modifier `durationMs` prepare une future preview, mais ne joue rien.

V1-68/V1-69 ne doivent pas :

- interpoler l'apercu sandbox ;
- deplacer un acteur dans la preview ;
- lancer un timer ;
- activer Play ;
- maintenir un `currentTimeMs` runtime ;
- creer un playback.

## 22. Pass H — Tests futurs V1-68

Tests exacts recommandes :

```text
edits wait duration from inspector
edits fade duration from inspector
edits camera duration from inspector
edits actorFace duration from inspector
edits actorMove duration from inspector
rejects duration below minimum
rejects duration above maximum
rejects invalid numeric input
uses duration presets and +/-100 controls
updates timeline bar width after duration edit
recalculates following block startMs after duration edit
clears local probe after duration edit
preserves selectedStepId after duration edit
does not mutate non-selected blocks except derived layout
does not modify startMs/endMs persisted fields
does not enable transport controls
does not start playback
does not mutate runtime/gameplay
does not allow duration editing for non-owned steps
```

## 23. Tests futurs V1-69

Tests exacts recommandes :

```text
shows right resize handle for editable authoring-owned block
does not show resize handle for non-owned block
dragging right handle increases duration
dragging right handle decreases duration
duration clamps to minimum
duration clamps to maximum
duration snaps to 100 ms increments
following blocks shift because layout is derived
dragging the bar body does not move the block
left edge is not draggable
resize does not change lane
resize does not change selectedStepId
resize clears local probe
resize does not enable transport controls
resize does not start playback
resize does not create persisted startMs/endMs
cancel restore original duration
```

## 24. Non-objectifs confirmes

V1-67 ne fait pas :

- code Dart produit ;
- widget Flutter modifie ;
- modification `map_core` ;
- modification `map_editor` ;
- modification `map_runtime` ;
- modification `map_gameplay` ;
- modification `map_battle` ;
- modification examples ;
- modification `ProjectManifest` ;
- modification `CinematicAsset` ;
- modification read model ;
- modification test ;
- screenshot ;
- Visual Gate ;
- build_runner ;
- duration editor code ;
- resize handle code ;
- drag de barre ;
- drag de bloc ;
- reorder ;
- move block ;
- `startMs` / `endMs` persistants ;
- timeline libre ;
- playback ;
- timer ;
- preview runtime ;
- image IA ;
- donnees produit Selbrume.

## 25. Pass I — Roadmap post V1-67

Suite recommandee :

```text
NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0
NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0
NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0
NS-SCENES-V1-71 — Cinematic Timeline Duration UX Evidence Sweep
NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0
```

Le scroll/visibility reste utile, mais apres le premier verrou de rythme authoring.

## 26. Commandes executees

Gate 0 :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Validation documentaire finale :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages
rg -n "resize|duration editor|durationMs.*TextField|onHorizontalDrag|onPanUpdate|Draggable|DragTarget|startMs|endMs|currentTimeMs|playbackTimeMs|isPlaying" packages/map_editor packages/map_core || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Les sorties exactes finales sont reprises dans la section Evidence Pack.

## 27. Checks anti-scope

Resultat attendu :

- `git diff --name-only -- packages` doit rester vide ;
- aucune modification package ;
- aucune modification test ;
- aucune image IA ;
- aucun screenshot ;
- les occurrences runtime/image/Selbrume dans les rapports doivent etre uniquement des non-objectifs, contexte ou anti-scope.

## 28. Evidence Pack

### 28.1 Diff complet des roadmaps modifiees

Commande :

```bash
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 2963733a..d42fee2b 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0
+NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0
 ```

 ## Principes
@@ -100,7 +100,10 @@ NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0
 | NS-SCENES-V1-64 | Cinematic Timeline Mouse Probe Boundary Snap V0 | editor / ui-readonly | Implementer le snap leger du repere souris selon le contrat V1-63. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, snap ticks, edition temporelle ou transport fonctionnel. | Builder cinematics, tests widget, rapport, screenshot. | DONE : snap 0/fin/starts/ends par seuil 8 px, badge aligne, scroll respecte, selection/inspecteur/projet preserves. | Confondre snap d'inspection et edition temporelle ; rendre le drag saccade ; casser V1-62. | DONE : snap local et reversible, sans nouveau pouvoir runtime/editor temporel. | V1-63. |
 | NS-SCENES-V1-65 | Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0 | editor / ui-polish | Polir l'experience du repere souris snappe : controles d'effacement/retour au repere lisibles, libelles courts et etats vides. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, snap ticks, edition temporelle ou transport fonctionnel. | Builder cinematics, tests widget, rapport, screenshot. | DONE : clear local explicite `Effacer le repère`, micro-explication `Repère local : inspection uniquement.`, Escape local timeline, TextFields proteges, selection/inspecteur/projet preserves, transports disabled preserves. | Confondre clear du probe avec reset playback ; ajouter un controle de lecture ; casser les proportions timeline. | DONE : polish local et reversible du probe, sans nouveau pouvoir runtime/editor temporel. | V1-64. |
 | NS-SCENES-V1-66 | Cinematic Timeline Mouse Probe Help / Selection Explanation V0 | editor / ui-polish | Expliquer clairement dans l'aide locale la difference entre `Selection` et `Repere`, et rappeler que le probe est une inspection non mutante. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | DONE : aide locale `Aide repère`, labels courts Selection/Repere/Alignement/Preview, selection/probe non ambigus, clear/Escape/aide clavier/transports preserves. | Transformer l'aide en tutoriel verbeux ; faire croire a un playhead runtime ; encombrer la timeline. | DONE : explication concise et no-code, sans nouveau pouvoir temporel. | V1-65. |
-| NS-SCENES-V1-67 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | V1-66. |
+| NS-SCENES-V1-67 | Cinematic Timeline Duration Editing / Resize Prep Contract | doc-only / interaction-contract | Cadrer l'edition de duree des blocs cinematic avant implementation : `durationMs`, blocs authoring-owned, min/max, presets, relation avec layout derive, probe souris et resize futur. | Pas de code produit, pas de package, pas de test, pas de screenshot, pas de resize actif, pas de playback, pas de timeline libre, pas de `startMs/endMs` persistants. | Rapport V1-67, roadmaps. | DONE : contrat inspecteur V1-68 puis resize bord droit V1-69, checks anti-scope, aucun package modifie. | Coder le resize trop tot ; modifier des steps non-owned ; transformer la timeline lineaire en timeline libre. | DONE : Option C retenue, V1-68 et V1-69 cadres, scroll/visibility repousse en backlog V1-72. | V1-66. |
+| NS-SCENES-V1-68 | Cinematic Timeline Duration Inspector Editing V0 | editor / authoring | Ajouter l'edition no-code de `durationMs` depuis l'inspecteur pour les blocs authoring-owned supportes. | Pas de resize souris, pas de drag de bloc, pas de playback, pas de seek runtime, pas de timeline libre, pas de `startMs/endMs` persistants. | Builder cinematics, operations authoring si extension `actorFace`, tests widget/core cibles, rapport. | TODO : presets courts, champ numerique borne, +/-100, validation min/max, recalcul layout derive, clear probe, non-owned non editables. | Ouvrir trop de blocs non possedes ; exposer JSON/IDs ; faire croire a un playback. | TODO : durees editables depuis l'inspecteur, non-mutation runtime, transports disabled. | V1-67. |
+| NS-SCENES-V1-69 | Cinematic Timeline Duration Resize Handles V0 | editor / authoring | Ajouter un handle de resize uniquement sur le bord droit des barres editables, reutilisant les bornes et validations V1-68. | Pas de drag du bloc entier, pas de bord gauche, pas de changement de lane, pas de reorder, pas de playback, pas de `startMs/endMs` persistants. | Builder cinematics, tests widget drag/resize, rapport, screenshot si lot UI. | TODO : handle droit, augmentation/diminution/clamp/snap 100 ms, clear probe, selection preservee, non-owned sans handle. | Hit testing trop large ; confusion avec probe souris ; casser les proportions de timeline. | TODO : resize borne et lisible, sans timeline libre. | V1-68. |
+| NS-SCENES-V1-72 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | V1-69 ou lot de polish dedie. |

 ## Mise a jour V1-66

@@ -108,7 +111,17 @@ Statut : `NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Ex

 Decision : le Builder affiche maintenant une aide locale `Aide repère`, visible uniquement avec un repere souris actif. Elle explique la difference entre selection inspectee et repere temporel local, avec un rappel d'alignement et de preview future, sans mutation ni nouveau controle temporel.

-Preuve : tests widget cibles et suite Builder/Library verts, Visual Gate V1-66, tests core time layout/lane et analyses ciblees. Le prochain lot recommande devient `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0`.
+Preuve : tests widget cibles et suite Builder/Library verts, Visual Gate V1-66, tests core time layout/lane et analyses ciblees. La trajectoire immediate est corrigee a la demande de Karim : le lot suivant devient `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`.
+
+## Mise a jour V1-67
+
+Statut : `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract` est DONE.
+
+Decision : V1-67 est documentaire et remplace le scroll/visibility polish immediat. Le contrat retient l'edition inspecteur d'abord, puis le resize souris par bord droit. `durationMs` reste la seule valeur persistante autorisee ; `startMs` et `endMs` restent derives.
+
+Preuve : rapport V1-67, roadmaps corrigees, checks anti-scope documentaires. Aucun code produit, package, test, screenshot, runtime, playback ou timeline libre n'est ajoute.
+
+Prochain lot exact recommande : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`.

 ## Options comparees

diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index fc8bada8..d0f2dd45 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -121,16 +121,21 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0 | DONE | Snap local du repere souris implemente : cibles `0 ms`, `totalDurationMs`, `block.startMs`, `block.endMs`, seuil `8 px`, badge `Repere : <temps> · <hint>`, click/drag/release, scroll horizontal, non-mutation, Visual Gate 1663x926, sans playback, seek runtime, scrubber runtime, drag de blocs, runtime ni mutation. |
 | NS-SCENES-V1-65 — Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0 | DONE | Controle explicite `Effacer le repère` visible seulement quand un probe local existe, micro-explication `Repère local : inspection uniquement.`, clear de `timelineProbeTimeMs`/`timelineProbeSnapHint`, retour au curseur `Selection` ou etat vide, Escape local timeline, TextFields proteges, transports disabled preserves, Visual Gate, sans playback, seek runtime, scrubber runtime, drag de blocs, runtime ni mutation. |
 | NS-SCENES-V1-66 — Cinematic Timeline Mouse Probe Help / Selection Explanation V0 | DONE | Aide locale `Aide repère` visible seulement avec un repere actif, panneau court expliquant Selection/Repere/Alignement/Preview, coexistence aide clavier, clear/Escape preserves, Visual Gate, sans playback, seek runtime, scrubber runtime, drag de blocs, runtime ni mutation. |
+| NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract | DONE | Lot documentaire demande par Karim : contrat d'edition de `durationMs`, blocs authoring-owned editables, min/max, relation avec `startMs/endMs` derives, clear du probe apres modification, et trajectoire inspecteur V1-68 puis resize droit V1-69, sans code produit ni package modifie. |
+| NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0 | TODO | Ajouter l'edition no-code de duree depuis l'inspecteur pour les blocs authoring-owned supportes, avec presets courts, saisie numerique bornee, validation inline, recalcul layout derive et clear du probe, sans playback ni timeline libre. |
+| NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0 | TODO | Ajouter un handle de resize uniquement sur le bord droit des barres editables, quantifie au pas 100 ms et borne min/max, sans drag du bloc entier, bord gauche, changement de lane, reorder, `startMs/endMs` persistants ni playback. |
+| NS-SCENES-V1-70 — Cinematic Timeline Duration Validation / Diagnostics Polish V0 | TODO | Consolider messages d'erreur, bornes et feedback no-code apres les premieres editions de duree, sans elargir le modele temporel. |
+| NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur : polir le scroll automatique et la visibilite des blocs/selection/probe apres les lots de duree, en preservant les proportions de timeline demandees par Karim. |

 ## Prochain lot recommande

-`NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0`
+`NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`

-Raison : V1-66 ferme l'explication locale du repere souris. Le prochain verrou naturel est de polir la visibilite/scroll des elements de timeline quand la navigation locale ou les interactions souris placent la selection hors de la vue utile.
+Raison : V1-67 corrige la trajectoire a la demande de Karim. Avant le scroll/visibility polish, le verrou produit prioritaire est de rendre la duree des blocs editables de facon bornee et no-code depuis l'inspecteur.

-Ordre apres V1-66 : `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0`.
+Ordre apres V1-67 : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`, puis `NS-SCENES-V1-69 — Cinematic Timeline Duration Resize Handles V0`.

-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0, puis Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0, puis Cinematic Timeline Mouse Playhead / Scrub Prep Contract, puis Cinematic Timeline Mouse Time Probe / Playhead Drag V0, puis Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0, puis Cinematic Timeline Mouse Probe Boundary Snap V0, puis Cinematic Timeline Mouse Probe UX Polish / Clear Controls V0, puis Cinematic Timeline Mouse Probe Help / Selection Explanation V0, puis Cinematic Timeline Scroll / Visibility Polish V0.
+Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract` et deplace en backlog futur comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`.

 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

@@ -356,7 +361,19 @@ Limites : pas de playback, seek runtime, scrubber runtime, transport fonctionnel

 Preuve : test RED puis GREEN `shows local time probe help explaining selection and probe`, test `clears local time probe with Escape after probe help is open`, suite Builder, suite Library, Visual Gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.png`, tests core time layout/lane, `dart analyze` core, analyse cible editor et checks anti-scope. L'analyse globale `map_editor` reste rouge par dette preexistante hors lot.

-Prochain lot exact : `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0`.
+Trajectoire corrigee par demande Karim : le lot suivant devient `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, et le scroll/visibility polish est repousse en backlog futur.
+
+## Mise a jour V1-67
+
+Statut : `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract` est DONE.
+
+Decision : V1-67 remplace le scroll/visibility polish immediat par un contrat documentaire de rythme cinematic. Le contrat retient l'Option C : edition de `durationMs` depuis l'inspecteur en V1-68, puis resize souris par bord droit en V1-69.
+
+Scope realise : audit du modele `CinematicTimelineStep.durationMs`, des blocs authoring-owned, du time layout derive `startMs/endMs`, du probe souris V1-62/V1-64/V1-65/V1-66, definition des blocs editables/non editables, bornes min/max, presets, relation avec le probe et tests futurs.
+
+Limites : pas de code produit, pas de package modifie, pas de test, pas de screenshot, pas de resize actif, pas de playback, pas de timeline libre, pas de `startMs/endMs` persistants.
+
+Prochain lot exact : `NS-SCENES-V1-68 — Cinematic Timeline Duration Inspector Editing V0`.

 ## Mise a jour V1-31
```

### 28.2 Checks Git finaux

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 19 ++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 27 ++++++++++++++++++----
 2 files changed, 38 insertions(+), 8 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md
```

Commande :

```bash
git diff --name-only -- packages
```

Sortie :

```text
```

Interpretation : aucun fichier `packages/` n'a de diff. Les seules modifications tracked sont les deux roadmaps autorisees, et le nouveau rapport V1-67 est le troisieme fichier autorise.

### 28.3 Checks anti-scope

Commandes executees :

```bash
rg -n "resize|duration editor|durationMs.*TextField|onHorizontalDrag|onPanUpdate|Draggable|DragTarget|startMs|endMs|currentTimeMs|playbackTimeMs|isPlaying" packages/map_editor packages/map_core || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_67_cinematic_timeline_duration_editing_resize_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Resultat :

- La recherche packages retourne uniquement des occurrences preexistantes dans `map_core` / `map_editor` : read model temporel V1-51/V1-56, tests existants, widgets existants et autres modules non modifies. Ce verdict est corrobore par `git diff --name-only -- packages`, vide.
- La recherche runtime dans les rapports retourne des occurrences historiques de roadmap, des non-objectifs et des lignes de commande documentees ; aucun runtime n'est ajoute par V1-67.
- La recherche image retourne seulement la ligne de commande documentee dans ce rapport ; aucune generation d'image ou modele image n'est ajoute.
- La recherche Selbrume retourne des occurrences historiques de roadmap et des non-objectifs ; aucune donnee produit Selbrume n'est ajoutee.

Note de preuve : ces commandes scannent le rapport V1-67 lui-meme. Coller leur sortie brute complete dans cette section modifierait mecaniquement la sortie future de la meme commande. Le verdict stable retenu est donc l'absence de diff package et la classification des occurrences comme historiques, non-objectifs ou lignes de commande.

## 29. Auto-review critique

1. Est-ce que V1-67 a modifie du code produit ? Non.
2. Est-ce que V1-67 a modifie un package ? Non.
3. Est-ce que V1-67 a modifie un test ? Non.
4. Est-ce que V1-67 a code l'edition de duree ? Non.
5. Est-ce que V1-67 a code un resize handle ? Non.
6. Est-ce que V1-67 a code un drag de bloc ? Non.
7. Est-ce que V1-67 a ajoute `startMs/endMs` persistants ? Non.
8. Est-ce que V1-67 a ajoute une timeline libre ? Non.
9. Est-ce que V1-67 a ajoute un playback ? Non.
10. Est-ce que V1-67 a ajoute `currentTimeMs/playbackTimeMs/isPlaying` ? Non.
11. Est-ce que V1-67 a modifie le runtime ? Non.
12. Est-ce que V1-67 a mute `ProjectManifest` ? Non.
13. Est-ce que les blocs editables sont listes ? Oui.
14. Est-ce que les blocs non editables sont listes ? Oui.
15. Est-ce que les durees min/max sont definies ? Oui.
16. Est-ce que le contrat inspecteur V1-68 est clair ? Oui.
17. Est-ce que le contrat resize V1-69 est clair ? Oui.
18. Est-ce que la relation avec le layout derive est claire ? Oui.
19. Est-ce que la relation avec le probe souris est claire ? Oui.
20. Est-ce que les tests futurs sont listes ? Oui.
21. Est-ce que le prochain lot exact est recommande ? Oui, V1-68.
22. Est-ce que l'Evidence Pack est complet sans placeholders ? Oui.

## 30. Verdict final

V1-67 est DONE si les checks finaux confirment que seuls ce rapport et les roadmaps sont modifies. Le contrat recommande inspecteur puis resize, garde `startMs/endMs` derives, refuse la timeline libre et prepare V1-68/V1-69 sans code produit.
