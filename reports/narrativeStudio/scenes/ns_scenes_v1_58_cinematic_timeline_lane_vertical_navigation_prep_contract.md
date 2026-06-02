# NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract

Date : 2026-06-03  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0`  
Prochain lot recommande : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`

## 1. Résumé exécutif

V1-58 est un lot documentaire / architecture / interaction contract. Il ne code pas `ArrowUp` ni `ArrowDown`; il fixe le comportement attendu pour le futur lot d'implementation.

Decision V0 retenue : Option B — prochaine lane non vide. Depuis un bloc selectionne, `ArrowUp` cherchera la premiere lane non vide au-dessus, `ArrowDown` cherchera la premiere lane non vide en dessous, puis le bloc cible sera choisi par proximite temporelle de centre :

```text
centerMs = startMs + visualDurationMs / 2
```

Les lanes vides seront ignorees en V0. Aux bords, si aucune lane non vide n'existe dans la direction demandee, la selection restera stable. Sans selection, `ArrowUp` selectionnera le dernier bloc de la derniere lane non vide et `ArrowDown` selectionnera le premier bloc de la premiere lane non vide.

Le contrat preserve V1-57 : `ArrowLeft` / `ArrowRight` restent lineaires par `stepIndex`, `Home` / `End` restent globaux, le focus reste local a la timeline et les `TextField` restent proteges.

## 2. Gate 0

Commande executee depuis la racine :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
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
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides dans cette sortie. Gate 0 : working tree propre, dernier commit V1-57.

## 3. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/verification-before-completion/SKILL.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_56_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_timeline_lane_read_model_test.dart`

Tous les chemins obligatoires existent dans `git ls-files`.

## 4. Pourquoi ce lot est documentaire

La navigation horizontale V1-57 etait simple : elle suit l'ordre lineaire `stepIndex`. La navigation verticale est plus ambigue, car elle doit choisir une lane cible, gerer les lanes vides, choisir un bloc dans la lane cible, traiter les bords, definir le cas sans selection et rester compatible avec la geometrie V1-56.

Coder directement `ArrowUp` / `ArrowDown` sans contrat risquerait de creer une navigation magique, difficile a predire, ou de confondre selection verticale et seek temporel. V1-58 dessine donc la carte avant de coder la route.

## 5. État actuel après V1-57

Etat valide :

- timeline par pistes derivees ;
- lanes stables ;
- axe temporel et ticks ;
- barres proportionnelles avec origine commune ticks / barres / curseur ;
- curseur de selection derive de `selectedStepId` ;
- hover details locaux ;
- transport controls placeholders disabled ;
- navigation clavier horizontale locale ;
- `ArrowLeft`, `ArrowRight`, `Home`, `End` ;
- focus timeline local ;
- `TextField` proteges.

Gaps restants :

- pas de contrat vertical avant V1-58 ;
- pas de `ArrowUp` / `ArrowDown` actif ;
- pas d'algorithme de "closest block in lane" ;
- pas de tests de navigation verticale.

## 6. Pass A — Audit du modèle de lanes

Le read model `buildCinematicTimelineLaneReadModel` cree des lanes dans un ordre stable :

```text
camera              sortOrder 0
actor:<actorId>     sortOrder 100 + index acteur requis
dialogue            sortOrder 200
fx                  sortOrder 300
audio               sortOrder 400
transitions         sortOrder 500
time-global         sortOrder 600
other               sortOrder 700
```

Les lanes acteurs inconnus sont ajoutees comme lanes acteurs, avec un `sortOrder` apres les acteurs requis connus. Les lanes vides existent et sont affichees : elles servent a rendre la structure lisible meme quand une piste n'a pas encore de bloc.

Conclusion Pass A : l'ordre vertical existe deja et peut etre reutilise tel quel. V1-58 ne doit pas inventer un autre ordre.

## 7. Pass B — Audit du time layout

Le read model `buildCinematicTimelineTimeLayoutReadModel` derive les timings depuis l'ordre lineaire :

- `startMs` = position courante ;
- `visualDurationMs` = `durationMs` si positive, sinon fallback visuel ;
- `endMs = startMs + visualDurationMs` ;
- `blocks` globaux tries par `stepIndex` ;
- `timeLayout.lanes` conserve l'ordre des lanes derivees.

Le futur contrat vertical peut donc calculer un centre temporel sans persistance :

```text
centerMs = startMs + visualDurationMs / 2
```

Conclusion Pass B : `centerMs` doit rester derive a la demande. Il ne doit pas etre stocke dans `CinematicTimelineTimeBlock`, `CinematicTimelineStep`, `CinematicAsset` ou `ProjectManifest`.

## 8. Pass C — Audit de la navigation clavier horizontale V1-57

V1-57 introduit uniquement :

- `_TimelineKeyboardNavigation.previous`
- `_TimelineKeyboardNavigation.next`
- `_TimelineKeyboardNavigation.first`
- `_TimelineKeyboardNavigation.last`

Les touches mappees sont :

- `LogicalKeyboardKey.arrowLeft`
- `LogicalKeyboardKey.arrowRight`
- `LogicalKeyboardKey.home`
- `LogicalKeyboardKey.end`

Le handler est local au `FocusNode` de la timeline. Sans selection, `next` selectionne le premier bloc et `previous` selectionne le dernier bloc. `Home` et `End` restent globaux.

Conclusion Pass C : le futur V1-59 doit ajouter une navigation verticale sans redefinir la navigation horizontale V1-57.

## 9. Design Gate — Cinematic Timeline Lane Vertical Navigation Prep / Contract

1. Quelles lanes existent aujourd'hui ? `camera`, lanes acteurs, `dialogue`, `fx`, `audio`, `transitions`, `time-global`, `other`.
2. Dans quel ordre stable sont-elles affichees ? Par `sortOrder`, puis label : camera, acteurs requis/inconnus, dialogue, FX, audio, transitions, temps/global, autres.
3. Les lanes vides sont-elles affichees ? Oui, les lanes structurelles restent visibles meme sans bloc.
4. Les lanes vides doivent-elles etre navigables ? Non en V0 : elles doivent etre ignorees pour eviter une touche qui "ne fait rien" au milieu du parcours.
5. ArrowUp / ArrowDown doivent-ils cibler la lane immediatement voisine ou la prochaine lane non vide ? Prochaine lane non vide.
6. Quel est le temps de reference du bloc courant : startMs, centerMs ou cursorTimeMs ? `centerMs`.
7. Pourquoi retenir ce temps de reference ? Parce qu'un bloc long doit etre traite comme une zone visuelle, pas comme un point a son debut.
8. Comment trouver le bloc le plus proche dans la lane cible ? Calculer la distance absolue entre le `centerMs` courant et le `centerMs` de chaque bloc cible.
9. Faut-il comparer startMs, centerMs ou interval overlap ? `centerMs` en V0 ; interval overlap est plus complexe et peut attendre une timeline plus riche.
10. Que faire si plusieurs blocs sont a distance egale ? Tie-break par plus petit `stepIndex`, puis ordre stable de la liste de blocks.
11. Que faire si la lane cible n'a aucun bloc ? Elle est ignoree ; chercher la prochaine lane non vide dans la meme direction.
12. Que faire si toutes les lanes au-dessus/en dessous sont vides ? Garder la selection courante.
13. Que faire sans selection courante ? `ArrowUp` selectionne le dernier bloc de la derniere lane non vide ; `ArrowDown` selectionne le premier bloc de la premiere lane non vide.
14. Que faire si le `selectedStepId` n'existe plus ? Le futur handler doit traiter cela comme absence de selection, sans mutation et sans crash.
15. Que faire si la timeline n'a aucun bloc ? Retourner `handled` ou `ignored` selon le handler futur, mais ne rien selectionner et ne rien muter.
16. Comment preserver la navigation horizontale V1-57 ? Ne pas modifier `previous`, `next`, `first`, `last`; ajouter des intents verticaux separes.
17. Comment preserver le curseur V1-52 ? Continuer a deriver le curseur du bloc selectionne et de `selectedStepId`; aucun `cursorTimeMs` persiste.
18. Comment preserver le hover V1-55 ? Ne jamais utiliser `hoveredStepId` comme source de navigation verticale.
19. Comment preserver la geometrie V1-56 ? Ne pas modifier constantes, largeur de lane, hauteur de row/barre, echelle pixels/ms ou placement X.
20. Comment proteger les TextFields ? Garder le `FocusNode` local timeline ; ne pas installer de `Shortcuts` global ni handler hors timeline.
21. Pourquoi ne pas coder ArrowUp / ArrowDown dans ce lot ? Parce que le lot est explicitement documentaire et que le contrat doit etre stabilise avant code.
22. Quels tests seront necessaires dans le futur lot d'implementation ? Les tests listes en section 16.
23. Quel prochain lot exact est recommande ? `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`.

## 10. Pass D — Options comparées

### Option A — Lane voisine stricte

Contrat : `ArrowUp` cible la lane immediatement au-dessus, `ArrowDown` la lane immediatement en dessous. Si elle est vide, rien ne se passe.

Avantages : simple, previsible, ne saute pas de piste.

Inconvenients : avec les lanes vides structurelles (`dialogue`, `fx`, `audio`, etc.), l'utilisateur peut appuyer et croire que la navigation est cassee.

Verdict : rejetee pour V0, mais utile comme fallback mental si une future option de preference "strict lanes" existe.

### Option B — Prochaine lane non vide

Contrat : `ArrowUp` cherche la premiere lane non vide au-dessus, `ArrowDown` la premiere lane non vide en dessous.

Avantages : fluide, utile dans une timeline avec lanes vides visibles, evite les touches mortes.

Inconvenients : peut sauter visuellement plusieurs pistes, donc le bloc cible doit etre choisi de facon tres explicite.

Verdict : retenue pour V0.

### Option C — Navigation spatiale par bloc le plus proche

Contrat : choisir le bloc le plus proche verticalement et temporellement, meme en traversant plusieurs lanes.

Avantages : peut sembler naturel a terme dans une timeline dense.

Inconvenients : trop complexe, plus difficile a predire, risque d'effet magique.

Verdict : rejetee pour V0.

### Option D — Ne pas naviguer verticalement tant que les lanes vides restent visibles

Contrat : `ArrowUp` / `ArrowDown` restent desactives.

Avantages : aucune ambiguite.

Inconvenients : navigation clavier incomplete alors que V1-57 a deja pose un focus local robuste.

Verdict : rejetee pour V0.

## 11. Pass E — Contrat ArrowUp / ArrowDown recommandé

Contrat V0 retenu :

```text
ArrowUp :
  si un bloc courant existe,
  chercher la premiere lane non vide au-dessus de sa lane,
  selectionner dans cette lane le bloc dont centerMs est le plus proche du centerMs courant.

ArrowDown :
  meme logique vers le bas.
```

Definition :

```text
centerMs = startMs + visualDurationMs / 2
```

La navigation verticale est spatiale par lane. Elle ne devient pas :

- un seek ;
- un scrubber ;
- un playback ;
- un drag/drop clavier ;
- un reorder clavier ;
- une edition des lanes ;
- une persistence temporelle.

## 12. Règles de sélection du bloc cible

Pour chaque bloc candidat de la lane cible :

```text
candidateCenterMs = candidate.startMs + candidate.visualDurationMs / 2
distance = abs(candidateCenterMs - currentCenterMs)
```

Tri des candidats :

```text
1. plus petite distance
2. plus petit stepIndex
3. ordre stable des blocks dans la lane
```

Le resultat est un `stepId` cible, puis la selection utilise le chemin existant `onStepSelected`, comme V1-57.

## 13. Règles lanes vides / bords / sans sélection

Lanes vides :

- non navigables en V0 ;
- ignorees lors de la recherche verticale ;
- toujours affichees visuellement par la timeline.

Bords :

- `ArrowUp` sans lane non vide au-dessus conserve la selection ;
- `ArrowDown` sans lane non vide en dessous conserve la selection.

Sans selection :

- `ArrowUp` selectionne le dernier bloc de la derniere lane non vide ;
- `ArrowDown` selectionne le premier bloc de la premiere lane non vide.

`selectedStepId` introuvable :

- traiter comme absence de selection ;
- ne pas muter le projet ;
- ne pas utiliser le hover comme fallback.

Timeline vide :

- ne rien selectionner ;
- ne pas crasher ;
- ne pas muter.

## 14. Relation avec ArrowLeft / ArrowRight / Home / End

V1-57 reste inchangé :

- `ArrowRight` = bloc suivant par ordre lineaire `stepIndex` ;
- `ArrowLeft` = bloc precedent par ordre lineaire `stepIndex` ;
- `Home` = premier bloc global ;
- `End` = dernier bloc global.

V1-58 recommande :

- `ArrowUp` / `ArrowDown` ajoutent une navigation par lane ;
- ne pas transformer `ArrowLeft` / `ArrowRight` en navigation lane-local ;
- ne pas transformer `Home` / `End` en debut/fin de lane dans V0.

## 15. Protection TextField / focus local

Le futur V1-59 doit conserver le modele V1-57 :

- un `FocusNode` local au panneau timeline ;
- pas de `Shortcuts` global ;
- pas de handler clavier installe au niveau workspace ;
- les `TextField` gardent leurs fleches quand ils sont focalises.

Le test futur doit focaliser un champ de la palette/inspecteur, envoyer `ArrowUp` ou `ArrowDown`, puis verifier que la selection timeline ne change pas.

## 16. Pass F — Tests futurs requis

Tests minimum pour V1-59 :

```text
ArrowDown from Camera selects closest block in next non-empty lane
ArrowUp from Actor lane selects closest block in previous non-empty lane
ArrowDown skips empty Dialogue/FX lanes if configured as non-navigable
ArrowUp at top keeps current selection
ArrowDown at bottom keeps current selection
tie-break uses smallest distance then stepIndex
vertical navigation updates cursor
vertical navigation updates inspector
vertical navigation updates preview sandbox
vertical navigation does not mutate ProjectManifest
vertical navigation does not use hoveredStepId
vertical navigation does not capture keys inside TextField
horizontal navigation V1-57 remains unchanged
bar geometry V1-56 remains unchanged
```

Tests additionnels utiles :

- sans selection + `ArrowUp` selectionne le dernier bloc de la derniere lane non vide ;
- sans selection + `ArrowDown` selectionne le premier bloc de la premiere lane non vide ;
- `selectedStepId` introuvable se comporte comme absence de selection ;
- timeline vide ne crashe pas et ne selectionne rien.

## 17. Pass G — Non-objectifs confirmés

V1-58 ne fait pas :

- pas de code Dart produit ;
- pas de widget Flutter ;
- pas de modification `map_core` ;
- pas de modification `map_editor` ;
- pas de modification `map_runtime` ;
- pas de modification `map_gameplay` ;
- pas de modification `map_battle` ;
- pas de modification `examples` ;
- pas de modification `ProjectManifest` ;
- pas de modification `CinematicAsset` ;
- pas de modification `CinematicTimeline` ;
- pas de modification read model ;
- pas de modification tests ;
- pas de screenshot obligatoire ;
- pas de Visual Gate ;
- pas de build_runner ;
- pas de `ArrowUp` / `ArrowDown` codes ;
- pas de navigation verticale implementee ;
- pas de focus traversal global ;
- pas de nouveau raccourci actif ;
- pas de playback ;
- pas de timer ;
- pas de seek ;
- pas de scrubber ;
- pas de drag/drop ;
- pas de resize ;
- pas de reorder ;
- pas de runtime preview ;
- pas de mutation JSON ;
- pas de donnees Selbrume.

## 18. Pass H — Roadmap post V1-58

V1-58 est propose DONE si les roadmaps et ce rapport restent les seuls changements.

Prochain lot exact recommande :

```text
NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0
```

Objectif futur : implementer `ArrowUp` / `ArrowDown` selon ce contrat, sans playback, seek, scrubber, drag/drop, resize, reorder, runtime ni mutation.

## 19. Commandes exécutées

Gate 0 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Audit chemins obligatoires :

```bash
git ls-files AGENTS.md agent_rules.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_56_evidence_pack.md reports/narrativeStudio/scenes/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

Audits de contenu :

```bash
rg -n "CinematicTimelineLaneKind|laneKind|laneId|blocks|stepIndex|buildCinematicTimelineLaneReadModel|buildCinematicTimelineTimeLayoutReadModel|startMs|visualDurationMs|ticks|laneById" packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
rg -n "_TimelineKeyboardNavigation|_timelineKeyboardTargetBlock|LogicalKeyboardKey|FocusNode|onKeyEvent|selectedStepId|hoveredStepId|timelineFocused|_timelineLaneHeaderWidth|_timelineLaneRowHeight|_timelineBarHeight" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
```

Validations finales executees apres redaction :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages
rg -n "ArrowUp|ArrowDown|LogicalKeyboardKey.arrowUp|LogicalKeyboardKey.arrowDown|FocusNode|onKeyEvent|Shortcuts|Actions" packages/map_editor packages/map_core || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Les sorties exactes finales sont en section 21.

## 20. Checks anti-scope

Interpretation attendue :

- `git diff --name-only -- packages` doit etre vide ;
- aucune nouvelle occurrence `ArrowUp` / `ArrowDown` dans les packages ;
- les termes runtime/playback ne sont autorises que dans les non-objectifs du rapport/roadmaps ;
- les mentions Selbrume ne doivent pas introduire de donnees produit.

Verdict : voir section 21.

## 21. Evidence Pack

### 21.1 Fichiers modifies

Fichiers attendus pour V1-58 :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

### 21.2 Sorties finales des checks

Les sorties finales sont capturees apres creation du rapport et mise a jour des roadmaps.

`git diff --check` :

```text
```

`git diff --stat && git diff --name-only && git status --short --untracked-files=all` :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 19 +++++++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  | 25 ++++++++++++++++++----
 2 files changed, 39 insertions(+), 5 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md
```

`git diff --name-only -- packages` :

```text
```

`rg -n "ArrowUp|ArrowDown|LogicalKeyboardKey.arrowUp|LogicalKeyboardKey.arrowDown|FocusNode|onKeyEvent|Shortcuts|Actions" packages/map_editor packages/map_core || true` :

```text
packages/map_editor/reports/dialogue_studio_v1_implementation.md:86:  - Actions inspecteur : reformulation / raccourcir / générer 3 libellés (choix) — **même client**, clé requise.
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart:40:    // Brand / Actions
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart:185:  // Properties - Brand / Actions
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart:373:    // Brand / Actions
packages/map_editor/lib/src/theme/pokemap_color_tokens.dart:461:    // Brand / Actions
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1226:            _aiMiniActions(context, sel, kind: 'line'),
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1240:            _aiMiniActions(context, sel, kind: 'narration'),
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1273:            _aiMiniActions(context, sel, kind: 'choice'),
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1330:  Widget _aiMiniActions(BuildContext context, _StepSelection sel,
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart:1336:          'Actions IA',
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1489:  late final FocusNode _timelineFocusNode = FocusNode(
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart:1567:        onKeyEvent: (node, event) => _handleTimelineKeyEvent(
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart:91:    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart:100:    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart:154:    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
```

Interpretation : le grep est non vide a cause d'occurrences preexistantes hors V1-58, notamment `Actions`, les `FocusNode` existants et le handler V1-57 du Cinematic Builder. `git diff --name-only -- packages` est vide : V1-58 n'ajoute aucune occurrence dans un fichier package modifie.

`rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true` :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:80:Coder directement `ArrowUp` / `ArrowDown` sans contrat risquerait de creer une navigation magique, difficile a predire, ou de confondre selection verticale et seek temporel. V1-58 dessine donc la carte avant de coder la route.
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:252:- un seek ;
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:253:- un scrubber ;
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:389:- pas de seek ;
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:390:- pas de scrubber ;
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:408:Objectif futur : implementer `ArrowUp` / `ArrowDown` selon ce contrat, sans playback, seek, scrubber, drag/drop, resize, reorder, runtime ni mutation.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:94:| NS-SCENES-V1-58 | Cinematic Timeline Lane Vertical Navigation Prep / Contract | doc-only / interaction-contract | Definir le contrat futur ArrowUp/ArrowDown avant implementation. | Pas de code produit, pas de package, pas de test, pas de screenshot, pas de raccourci actif, pas de runtime, pas de playback, seek, scrubber, drag/drop, resize, reorder ou mutation JSON. | Rapport V1-58, roadmaps. | DONE : options A/B/C/D comparees, Option B retenue, `centerMs`, lanes vides, bords, sans selection, tie-breaks et tests futurs documentes, checks anti-scope. | Coder la navigation verticale trop tot ; creer un seek spatial ambigu ; casser la navigation horizontale V1-57 ou les proportions V1-56. | DONE : contrat clair pour V1-59, sans nouvelle capability. | V1-57. |
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:919:Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.
reports/narrativeStudio/scenes/road_map_scenes.md:115:| NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract | DONE | Lot documentaire : contrat ArrowUp/ArrowDown retenu avant implementation. Option B recommandee : chercher la prochaine lane non vide au-dessus/dessous, choisir le bloc au `centerMs` le plus proche, ignorer les lanes vides, garder la selection aux bords, definir le cas sans selection, tie-breaks et tests futurs, sans code produit, package, runtime, playback, seek, drag/drop, resize, reorder ni mutation. |
reports/narrativeStudio/scenes/road_map_scenes.md:121:Raison : V1-58 a defini le contrat vertical sans coder de raccourci. Le prochain verrou naturel est d'implementer ArrowUp/ArrowDown selon ce contrat, sans playback, seek, scrubber, drag/drop, resize, reorder, runtime ni mutation.
reports/narrativeStudio/scenes/road_map_scenes.md:235:Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.
```

Interpretation : les occurrences V1-58 sont des non-objectifs ou la definition du futur lot. Les autres occurrences historiques des roadmaps restent preexistantes et ne correspondent pas a un changement de code runtime.

`rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true` :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:396:- pas de donnees Selbrume.
reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md:453:- les mentions Selbrume ne doivent pas introduire de donnees produit.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:919:Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.
reports/narrativeStudio/scenes/road_map_scenes.md:31:- Ne pas hardcoder Selbrume ou des scenes de reference dans le code produit.
reports/narrativeStudio/scenes/road_map_scenes.md:115:| NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract | DONE | Lot documentaire : contrat ArrowUp/ArrowDown retenu avant implementation. Option B recommandee : chercher la prochaine lane non vide au-dessus/dessous, choisir le bloc au `centerMs` le plus proche, ignorer les lanes vides, garder la selection aux bords, definir le cas sans selection, tie-breaks et tests futurs, sans code produit, package, runtime, playback, seek, drag/drop, resize, reorder ni mutation. |
reports/narrativeStudio/scenes/road_map_scenes.md:235:Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.
```

Interpretation : les occurrences V1-58 indiquent explicitement l'absence de donnees Selbrume. Les autres occurrences sont historiques dans les roadmaps.

### 21.3 Hunk complet — road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 59a452f2..c94b320b 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -112,16 +112,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0 | DONE | Details inline au survol des barres : label no-code, type, piste, debut, duree et infos metier utiles, highlight doux, semantics, capture 1663x926, sans selection auto, seek, playback, drag/drop, resize, reorder, runtime ni mutation. |
 | NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0 | DONE | Correctif demande par Karim : barres temporelles basees sur `startMs`/`visualDurationMs`, origine X commune ticks/barres/curseur, colonne pistes lisible a 128 px, labels complets sans meta parasite, rangées 48 px, barres 36 px, chrome timeline compacte et ratio preview/timeline corrige, capture 1663x926, sans seek, playback, drag/drop, resize, reorder, runtime ni mutation. |
 | NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0 | DONE | Navigation clavier locale de la timeline : ArrowRight/ArrowLeft/Home/End selectionnent les blocs par `stepIndex`, initialisent la selection quand elle est vide, gardent curseur/preview/inspecteur synchronises, focus borne au panneau timeline, TextField proteges, capture 1663x926, sans seek, playback, scrubber, drag/drop, resize, reorder, runtime ni mutation. |
+| NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract | DONE | Lot documentaire : contrat ArrowUp/ArrowDown retenu avant implementation. Option B recommandee : chercher la prochaine lane non vide au-dessus/dessous, choisir le bloc au `centerMs` le plus proche, ignorer les lanes vides, garder la selection aux bords, definir le cas sans selection, tie-breaks et tests futurs, sans code produit, package, runtime, playback, seek, drag/drop, resize, reorder ni mutation. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`
+`NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`
 
-Raison : V1-57 ajoute seulement la navigation horizontale locale. Le prochain verrou utile est de cadrer la future navigation verticale par piste avant de l'implementer, afin de ne pas casser les proportions V1-56 ni ouvrir un vrai montage editable.
+Raison : V1-58 a defini le contrat vertical sans coder de raccourci. Le prochain verrou naturel est d'implementer ArrowUp/ArrowDown selon ce contrat, sans playback, seek, scrubber, drag/drop, resize, reorder, runtime ni mutation.
 
-Ordre apres V1-57 : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`.
+Ordre apres V1-58 : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -221,6 +222,22 @@ Preuve : test RED puis GREEN `navigates selected timeline blocks with local keyb
 
 Prochain lot exact : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`.
 
+## Mise a jour V1-58
+
+Statut : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract` est DONE.
+
+Decision : V1-58 est un lot documentaire. Il ne code pas ArrowUp/ArrowDown ; il fixe le contrat du futur lot. L'option retenue est Option B : ArrowUp/ArrowDown cherchent la prochaine lane non vide dans la direction verticale, puis selectionnent dans cette lane le bloc dont le centre temporel est le plus proche du centre du bloc courant.
+
+Regles retenues : `centerMs = startMs + visualDurationMs / 2`, comparaison par distance absolue entre centres, tie-break par plus petit `stepIndex` puis ordre stable de blocks, lanes vides ignorees, bords sans lane non vide = selection conservee. Sans selection, ArrowUp selectionnera le dernier bloc de la derniere lane non vide et ArrowDown le premier bloc de la premiere lane non vide. Si `selectedStepId` est introuvable ou si la timeline est vide, le futur handler restera non destructif.
+
+Tests futurs requis : ArrowDown Camera -> lane non vide suivante, ArrowUp acteur -> lane non vide precedente, skip lanes vides, bords top/bottom, tie-break distance puis `stepIndex`, synchro curseur/inspecteur/preview, non-mutation `ProjectManifest`, hover ignore, TextField proteges, navigation horizontale V1-57 et geometrie V1-56 preservees.
+
+Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.
+
+Preuve : rapport `reports/narrativeStudio/scenes/ns_scenes_v1_58_cinematic_timeline_lane_vertical_navigation_prep_contract.md`, Gate 0 propre, audit lanes/time layout/V1-57, roadmaps mises a jour, `git diff --check`, anti-scope packages vide et Evidence Pack inclus.
+
+Prochain lot exact : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`.
+
 ## Mise a jour V1-31
 
 Statut : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0` est DONE.
```

### 21.4 Hunk complet — road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index fbc002ff..fd56c3e9 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract
+NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0
 ```
 
 ## Principes
@@ -91,6 +91,7 @@ NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract
 | NS-SCENES-V1-55 | Cinematic Timeline Interaction Polish / Hover Details V0 | editor / ui-readonly | Ajouter une inspection legere au survol des barres de timeline. | Pas de playback, seek, scrubber, selection auto, drag/drop, resize, reorder, mutation JSON, runtime ou focus clavier avance. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : detail inline no-code, highlight hover, semantics, hover exit, selection/curseur/inspecteur preserves, ProjectManifest non mute, Visual Gate et analyses ciblees. | Confondre hover et selection ; creer un tooltip fragile ou un controle temporel implicite ; afficher des IDs techniques. | DONE : hover lisible et temporaire sans nouveau pouvoir. | V1-54. |
 | NS-SCENES-V1-56 | Cinematic Timeline Bar Geometry / Duration Scale Correction V0 | editor / ui-readonly | Corriger la geometrie visuelle des barres et le ratio utile preview/timeline. | Pas de playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON, runtime, persistence temporelle ou focus clavier avance. | Builder cinematics, design system card, tests widget, rapport, screenshot 1663x926. | DONE : origine X commune ticks/barres/curseur, largeur par `visualDurationMs`, colonne pistes 128 px, labels complets sans meta parasite, rangées 48 px, barres 36 px, chrome compacte, hover overlay stable, transport icon-only, Visual Gate et analyses ciblees. | Confondre correction visuelle et edition temporelle ; deplacer le curseur ; stocker du layout derive ; laisser le sandbox ou les pistes ecraser la timeline. | DONE : barres temporelles rectangulaires, proportionnelles et non editables, avec timeline lisible, sans nouveau pouvoir. | V1-55. |
 | NS-SCENES-V1-57 | Cinematic Timeline Keyboard Navigation / Selection Polish V0 | editor / ui-readonly | Ajouter une navigation clavier locale entre blocs de timeline par ordre lineaire. | Pas de navigation verticale par piste, pas de playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON, runtime, persistence temporelle ou modele core. | Builder cinematics, design system card focus, tests widget, rapport, screenshot 1663x926. | DONE : ArrowRight/ArrowLeft/Home/End, demarrage premier/dernier sans selection, focus local timeline, TextField proteges, curseur/preview/inspecteur synchronises, Visual Gate et analyses ciblees. | Capturer les fleches globalement ; confondre selection avec seek/playhead ; casser les proportions V1-56. | DONE : selection clavier locale et non destructive, sans nouveau pouvoir runtime/editor. | V1-56. |
+| NS-SCENES-V1-58 | Cinematic Timeline Lane Vertical Navigation Prep / Contract | doc-only / interaction-contract | Definir le contrat futur ArrowUp/ArrowDown avant implementation. | Pas de code produit, pas de package, pas de test, pas de screenshot, pas de raccourci actif, pas de runtime, pas de playback, seek, scrubber, drag/drop, resize, reorder ou mutation JSON. | Rapport V1-58, roadmaps. | DONE : options A/B/C/D comparees, Option B retenue, `centerMs`, lanes vides, bords, sans selection, tie-breaks et tests futurs documentes, checks anti-scope. | Coder la navigation verticale trop tot ; creer un seek spatial ambigu ; casser la navigation horizontale V1-57 ou les proportions V1-56. | DONE : contrat clair pour V1-59, sans nouvelle capability. | V1-57. |
 
 ## Options comparees
 
@@ -905,6 +906,22 @@ Preuve : tests clavier locaux, suite Builder `+39`, suite Library `+10`, tests c
 
 Prochain lot exact : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`.
 
+## Mise a jour V1-58
+
+Statut : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract` est DONE.
+
+Decision : V1-58 reste documentaire. La future navigation ArrowUp/ArrowDown utilisera Option B : prochaine lane non vide au-dessus ou en dessous, puis bloc cible choisi par proximite de centre temporel. La navigation horizontale V1-57 reste lineaire par `stepIndex`; Home/End restent globaux.
+
+Regles : temps de reference `centerMs = startMs + visualDurationMs / 2`; lanes vides non navigables en V0 ; bords sans lane non vide = selection conservee ; sans selection, ArrowUp va au dernier bloc de la derniere lane non vide et ArrowDown au premier bloc de la premiere lane non vide ; tie-break distance, puis plus petit `stepIndex`, puis ordre stable.
+
+Tests futurs requis : selection depuis Camera vers acteur/dialogue selon lane non vide, remontee vers lane precedente, skip lanes vides, bords stables, tie-breaks, cursor/inspector/preview synchronises, non-mutation, hover ignore, TextField proteges, V1-57/V1-56 preserves.
+
+Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun ArrowUp/ArrowDown actif, aucun runtime, playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON ou donnees Selbrume.
+
+Preuve : rapport V1-58 complet avec Gate 0, audit passes A-H, Design Gate, options comparees, Evidence Pack et checks anti-scope.
+
+Prochain lot exact : `NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

### 21.5 Rapport V1-58

Ce fichier est le rapport V1-58 complet. Il contient le Gate 0, les fichiers lus, les passes A-H, le Design Gate, les options comparees, le contrat recommande, les tests futurs, les non-objectifs, les commandes, les checks anti-scope, l'auto-review et le verdict.

## 22. Auto-review critique

1. Est-ce que V1-58 a modifie du code produit ? Non.
2. Est-ce que V1-58 a modifie un package ? Non.
3. Est-ce que V1-58 a code ArrowUp / ArrowDown ? Non.
4. Est-ce que V1-58 a modifie la navigation V1-57 ? Non.
5. Est-ce que V1-58 a modifie la geometrie V1-56 ? Non.
6. Est-ce que V1-58 a ajoute un runtime ? Non.
7. Est-ce que V1-58 a ajoute du playback ? Non.
8. Est-ce que V1-58 a ajoute du seek/scrubber ? Non.
9. Est-ce que V1-58 a ajoute du drag/drop, resize ou reorder ? Non.
10. Est-ce que V1-58 a mute ProjectManifest ? Non.
11. Est-ce que le contrat ArrowUp / ArrowDown est clair ? Oui : Option B, lane non vide, `centerMs`.
12. Est-ce que les lanes vides sont traitees ? Oui : ignorees en V0.
13. Est-ce que les bords sont traites ? Oui : selection conservee.
14. Est-ce que le cas sans selection est traite ? Oui : `ArrowUp` dernier bloc de la derniere lane non vide, `ArrowDown` premier bloc de la premiere lane non vide.
15. Est-ce que les tie-breaks sont definis ? Oui : distance, `stepIndex`, ordre stable.
16. Est-ce que les tests futurs sont listes ? Oui.
17. Est-ce que le prochain lot exact est recommande ? Oui : V1-59.
18. Est-ce que l'Evidence Pack est complet sans placeholders ? Oui : aucune balise placeholder n'est presente ; les sorties finales sont capturees dans ce rapport.

## 23. Verdict final

V1-58 est propose DONE.

Le lot a defini ce que feront `ArrowUp` et `ArrowDown`, comment traiter les lanes vides, les bords, l'absence de selection et les tie-breaks, sans coder de nouvelle capability.

Prochain lot exact :

```text
NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0
```
