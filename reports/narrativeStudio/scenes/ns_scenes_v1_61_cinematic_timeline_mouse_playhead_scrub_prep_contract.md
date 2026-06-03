# NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract

Date : 2026-06-03
Statut : DONE
Lot precedent : `NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0`
Prochain lot recommande : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`

## 1. Resume executif

V1-61 est un lot documentaire / interaction-contract. Il cadre le futur comportement d'un repere temporel souris dans la timeline du Cinematic Builder, avec un feeling proche d'un outil de montage, sans coder le scrubber.

Phrase canonique :

```text
V1-61 dessine le contrat du playhead souris.
V1-61 ne code pas encore le scrubber.
```

Decision retenue : Option B, un `Mouse Time Probe` local, editor-only, separe de la selection de bloc et du playback runtime.

## 2. Gate 0

Commande executee depuis la racine avant toute modification V1-61 :

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
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
```

Interpretation : les sorties `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides.

## 3. Fichiers lus

Inventaire obligatoire :

```text
AGENTS.md
agent_rules.md
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Skills lus ou deja actifs dans cette session : `brainstorming` pour cadrage conceptuel et `verification-before-completion` pour evidence avant completion. TDD non applique car le lot interdit les tests et le code produit.

## 4. Pourquoi ce lot est documentaire

Le comportement souhaite par Karim implique un repere temporel de timeline qui suit la souris. Coder directement cette interaction ouvrirait plusieurs decisions non tranchees : relation avec `selectedStepId`, relation avec le curseur V1-52, conversion position souris -> temps, scroll horizontal, zones de drag, comportement de cancel, relation avec preview sandbox et frontiere runtime.

V1-61 sert donc a fixer le contrat avant implementation. Il ne modifie aucun package, aucun widget, aucun test et ne genere aucun screenshot.

## 5. Etat actuel apres V1-60

- V1-51 fournit une projection temporelle derivee : lanes, blocks, ticks, `totalDurationMs`.
- V1-52 affiche un curseur de selection derive de `selectedStepId` et du `startMs` du bloc selectionne.
- V1-56 garantit l'origine X commune ticks/barres/curseur et les proportions utiles.
- V1-57/V1-59 ajoutent la navigation clavier locale.
- V1-60 explique cette navigation avec `Aide clavier`, sans nouveau pouvoir temporel.

## 6. Pass A — Audit du cursor de selection V1-52

Le curseur actuel V1-52 est une aiguille de selection. Son contrat est :

```text
selectedStepId + timeLayout.blocks -> selectedBlock
selectedBlock.startMs -> badge + cursor x
null -> pas de badge, pas de curseur
```

Il est derive, non interactif, non persistant. Il n'est pas un playback playhead, pas un temps courant runtime et pas un scrubber.

Conclusion Pass A : le futur repere souris doit etre separe du curseur de selection pour eviter de transformer implicitement `selectedStepId` en temps courant.

## 7. Pass B — Audit de la geometrie timeline V1-56

V1-56 fixe la geometrie utile :

- colonne pistes a 128 px ;
- axe temporel a 34 px ;
- rangees a 48 px ;
- barres a 36 px ;
- `startMs` mappe en X ;
- `visualDurationMs` mappe en largeur ;
- origine X commune entre ticks, barres et curseur ;
- scroll horizontal via viewport temporel.

Le futur probe doit reutiliser la meme origine X et le meme `pixelsPerMs`. Il ne doit pas recreer une echelle parallele.

Conclusion Pass B : la conversion souris -> temps doit partir du point local dans la grille temporelle, corriger le scroll horizontal, puis diviser par `pixelsPerMs`.

## 8. Pass C — Audit des interactions clavier V1-57 / V1-59

La navigation clavier vit dans le `FocusNode` local de la timeline :

- ArrowLeft / ArrowRight / Home / End : navigation lineaire V1-57 ;
- ArrowUp / ArrowDown : navigation verticale par lane V1-59 ;
- TextFields proteges ;
- selection, preview sandbox et inspecteur synchronises par `selectedStepId`.

Conclusion Pass C : le futur probe souris ne doit pas intercepter les raccourcis clavier globaux. Apres navigation clavier, le contrat recommande est de conserver le probe visuel s'il existe, mais de remettre en avant le curseur de selection comme etat principal.

## 9. Pass D — Audit hover / aide / transports

V1-55 : hover details lit le bloc survole, sans selection automatique.
V1-60 : le panneau `Aide clavier` est local, toggle click, sans nouveau pouvoir timeline.
V1-53 : les transports Reset / Play / Stop restent disabled.

Conclusion Pass D : le futur probe souris doit coexister avec hover et aide. Le drag axe/fond ne doit pas ouvrir le panneau d'aide, le hover de barre reste informatif, et les transports restent disabled.

## 10. Design Gate — Cinematic Timeline Mouse Playhead / Scrub Prep Contract

1. Le curseur actuel V1-52 represente le debut du bloc selectionne.
2. Le curseur actuel est une selection, pas un playhead.
3. Le futur playhead souris doit etre separe de `selectedStepId`.
4. Nom produit retenu : `Mouse Time Probe` pour V0 ; `playhead` reste un terme visuel, `scrubber` est reserve a un futur plus avance.
5. Zone souris future autorisee : axe temporel et fond de grille temporelle.
6. Le drag doit etre autorise seulement sur l'axe/fond, pas sur les barres.
7. Un clic simple sur l'axe place le probe au temps clique.
8. Un drag sur l'axe deplace le probe en suivant la souris.
9. Un drag sur une barre ne deplace rien en V1-62.
10. Un clic sur une barre continue de selectionner le bloc.
11. Conversion position souris -> temps : `(localX + scrollX - timelineOriginX) / pixelsPerMs`.
12. Le scroll horizontal est ajoute avant conversion.
13. Le temps est clamp entre `0` et `totalDurationMs`.
14. Snap aux ticks : non en V0, pour eviter une sensation saccadee.
15. Snap aux debuts/fins de blocs : oui si proche, seuil futur recommande 6 px.
16. Timeline vide : aucun probe actif, clic/drag ignore.
17. Aucun bloc selectionne : clic/drag peut afficher un probe local, sans selectionner de bloc.
18. Bloc selectionne puis souris deplace le probe : `selectedStepId` reste intact.
19. La souris ne change pas l'inspecteur.
20. La souris ne change pas la selection sauf clic explicite sur une barre.
21. La souris peut changer une ligne de preview sandbox informative : `Repere temporel : 1.2 s`, sans preview reelle.
22. Navigation clavier preservee : handler clavier local inchange, probe non prioritaire sur selection.
23. Hover V1-55 preserve : hover barre reste informatif ; drag fond suspend seulement les hover details si necessaire.
24. Aide clavier V1-60 preservee : aucune interaction probe n'ouvre/ferme l'aide.
25. Transports V1-53 preserves : boutons toujours disabled.
26. Ne pas coder directement le scrubber en V1-61 car les frontieres selection/playback/runtime doivent etre tranchees avant.
27. Tests futurs requis : voir section 22.
28. Prochain lot exact recommande : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.

## 11. Concepts retenus : selection, repere temporel, playback playhead

`Selected block` : bloc selectionne dans la timeline, porte par `selectedStepId`, pilote inspecteur et preview placeholder.

`Selection cursor` : ligne verticale derivee de `selectedStepId` et du `startMs` du bloc selectionne.

`Mouse Time Probe` : repere temporel local futur, deplacable par souris sur axe/fond, sans modifier selection, modele ou runtime.

`Runtime playback playhead` : temps courant d'une vraie lecture cinematic. Hors V1-61 et hors V1-62 recommande.

## 12. Options comparees

| Option | Verdict | Raison |
|---|---|---|
| A — Ne rien faire cote souris | Rejetee | Ne repond pas au feeling demande et ne prepare pas le futur montage. |
| B — Mouse Time Probe local, sans playback | Retenue | Repond au geste souris, prepare la preview future, garde selection et runtime separes. |
| C — Scrub preview reelle | Rejetee maintenant | Impliquerait interpolation camera/acteurs/FX/son et frontiere runtime trop large. |
| D — Drag/resize des blocs temporels | Rejetee | Contredit la timeline derivee actuelle et requerrait persistance start/end ou modele timing riche. |

## 13. Contrat recommande pour Mouse Time Probe V0

V1-62 devra implementer seulement un repere local :

- champ d'etat editor local futur recommande : `timeProbeMs` ou `timelineProbeTimeMs` ;
- non persiste ;
- absent du core ;
- derive visuel depuis un temps local ;
- rendu distinct du curseur de selection ;
- aucun appel runtime ;
- aucun transport active.

## 14. Zones interactives futures

Autorise :

- axe temporel ;
- fond des lanes temporelles ;
- zone vide de grille.

Interdit en V0 :

- drag depuis une barre ;
- drag depuis le handle du curseur selection ;
- drag depuis le panneau d'aide ;
- drag depuis les transports ;
- drag depuis l'inspecteur.

## 15. Click / drag / release / cancel

Click axe/fond : positionne le probe au temps clique.
Drag axe/fond : met a jour le probe a chaque mouvement.
Release : garde la derniere valeur clamp/snap.
Cancel : restaure la derniere valeur stable ou supprime le probe si aucun stable n'existait.
Click barre : conserve la selection de bloc existante.
Drag barre : ignore en V1-62, aucun deplacement de bloc.

## 16. Relation avec selectedStepId

Le probe ne doit pas modifier `selectedStepId`. L'inspecteur reste attache au bloc selectionne. Si aucun bloc n'est selectionne, le probe peut exister seul mais ne cree pas de selection.

## 17. Relation avec preview sandbox

La preview sandbox peut afficher une information textuelle locale :

```text
Repere temporel : 1.2 s
Preview reelle a venir.
```

Elle ne doit pas jouer la cinematic, interpoler acteurs/camera, declencher FX/son ou deplacer le monde.

## 18. Conversion souris -> temps

Contrat recommande :

```text
rawX = localPointerX - timelineContentLeft
scrolledX = rawX + horizontalScrollOffset
timeMs = scrolledX / pixelsPerMs
clampedTimeMs = clamp(timeMs, 0, totalDurationMs)
```

`timelineContentLeft` doit etre la meme origine X que ticks/barres/curseur.

## 19. Snap / precision / scroll

Precision interne : double pendant le drag, arrondi final en int ms pour affichage local.
Scroll horizontal : toujours integre avant clamp.
Snap ticks : non en V0.
Snap blocs : oui si le probe est proche d'un `startMs` ou `endMs`, seuil recommande 6 px.
Total vide : aucun probe.

## 20. Relation avec transports disabled

Le probe ne rend pas Reset / Play / Stop actifs. Il ne cree pas `isPlaying`, `currentTimeMs`, `playbackTimeMs` ni controller.

## 21. Frontiere avec runtime playback

Le probe est une inspection editor locale. Il ne doit pas appeler `playCinematic`, `SceneRuntimeExecutor`, `PlayableMapGame`, `runtimePreview` ou `previewRuntime`. Le vrai playback runtime reste un lot separe.

## 22. Tests futurs requis

Tests V1-62 a ecrire :

```text
clicking time axis sets local time probe
dragging time axis moves local time probe
time probe clamps to 0 at left boundary
time probe clamps to totalDurationMs at right boundary
time probe shares X origin with ticks/bars/cursor
time probe accounts for horizontal scroll offset
dragging a block still does not move the block
clicking a block still selects the block
moving time probe does not change selectedStepId
moving time probe does not change inspector
moving time probe does not mutate ProjectManifest
moving time probe does not start playback
moving time probe does not enable transport controls
moving time probe does not call runtime
TextFields remain protected
keyboard navigation after manual probe selection preserves selectedStepId
hover details remain functional
keyboard help remains functional
transport controls remain disabled
```

## 23. Non-objectifs confirmes

Confirme hors V1-61 :

- code produit ;
- package `packages/` ;
- test ;
- screenshot ;
- outil image IA ;
- scrubber actif ;
- seek runtime ;
- playback ;
- timer / ticker / animation controller ;
- drag de blocs ;
- resize / reorder ;
- mutation JSON ;
- persistence temporelle ;
- donnees Selbrume.

## 24. Roadmap post V1-61

Prochain lot exact recommande :

```text
NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0
```

Objectif futur : implementer le probe local selon ce contrat, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.

## 25. Commandes executees

Les commandes finales documentaires sont capturees dans la section 27 apres creation du rapport :

```text
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages
checks anti-scope rg
```

## 26. Checks anti-scope

Les checks anti-scope doivent prouver :

- aucun fichier sous `packages/` modifie ;
- aucun code souris/scrub ajoute dans un fichier de production ;
- aucun runtime ajoute ;
- aucune image IA ;
- aucune donnee Selbrume.

## 27. Evidence Pack

### 27.1 Hunks complets des roadmaps modifiees

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 1199be04..ce3c5973 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande

 ```text
-NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract
+NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0
 ```

 ## Principes
@@ -94,7 +94,8 @@ NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract
 | NS-SCENES-V1-58 | Cinematic Timeline Lane Vertical Navigation Prep / Contract | doc-only / interaction-contract | Definir le contrat futur ArrowUp/ArrowDown avant implementation. | Pas de code produit, pas de package, pas de test, pas de screenshot, pas de raccourci actif, pas de runtime, pas de playback, seek, scrubber, drag/drop, resize, reorder ou mutation JSON. | Rapport V1-58, roadmaps. | DONE : options A/B/C/D comparees, Option B retenue, `centerMs`, lanes vides, bords, sans selection, tie-breaks et tests futurs documentes, checks anti-scope. | Coder la navigation verticale trop tot ; creer un seek spatial ambigu ; casser la navigation horizontale V1-57 ou les proportions V1-56. | DONE : contrat clair pour V1-59, sans nouvelle capability. | V1-57. |
 | NS-SCENES-V1-59 | Cinematic Timeline Lane Vertical Navigation V0 | editor / ui-readonly | Implementer ArrowUp/ArrowDown selon le contrat Option B V1-58 : prochaine lane non vide, bloc cible par `centerMs` le plus proche. | Pas de playback, seek, scrubber, drag/drop, resize, reorder, mutation JSON, runtime, persistence temporelle, nouvelle capability authoring ou modele core. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : ArrowUp/ArrowDown locaux, lanes vides ignorees, bords stables, sans selection, timeline vide, tie-break distance/`stepIndex`, TextFields proteges, curseur/preview/inspecteur synchronises, Visual Gate et analyses ciblees. | Capturer les fleches globalement ; utiliser hover/pixels comme source ; confondre navigation verticale avec seek temporel ; casser V1-56/V1-57. | DONE : navigation verticale locale et non destructive, sans nouveau pouvoir runtime/editor temporel. | V1-58. |
 | NS-SCENES-V1-60 | Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0 | editor / ui-polish | Remplacer le long badge clavier par une aide compacte locale qui explique les fleches, Home et End. | Pas de playback, seek, scrubber, drag/drop, resize, reorder, mouse playhead, mutation JSON, runtime, nouvelle capability temporelle ou modele core. | Builder cinematics, tests widget, rapport, screenshot 1663x926. | DONE : badge/bouton compact `Aide clavier`, panneau local toggle click, contenu horizontal/vertical/Home/End, mention selection-only, selection/curseur/inspecteur preserves, Visual Gate et analyses ciblees. | Faire croire a un scrubber ou playhead souris ; casser les proportions V1-56 ; melanger aide et statut. | DONE : aide clavier lisible et non intrusive, sans nouveau pouvoir timeline. | V1-59. |
-| NS-SCENES-V1-61 | Cinematic Timeline Mouse Playhead / Scrub Prep Contract | doc-only / interaction-contract | Cadrer le futur playhead souris type Final Cut avant toute implementation. | Pas de code produit, pas de seek actif, pas de drag, pas de playback, pas de scrubber, pas de mutation JSON, pas de runtime. | Rapport V1-61, roadmaps. | TODO : definir contrat UX, donnees derivees, risques, anti-scope, tests futurs et separation selection/playback. | Coder le playhead trop tot ; transformer le curseur V1-52 en scrubber sans contrat ; promettre un playback non implemente. | TODO : contrat futur clair, aucune capability ajoutee. | V1-60. |
+| NS-SCENES-V1-61 | Cinematic Timeline Mouse Playhead / Scrub Prep Contract | doc-only / interaction-contract | Cadrer le futur playhead souris type Final Cut avant toute implementation. | Pas de code produit, pas de seek actif, pas de drag, pas de playback, pas de scrubber, pas de mutation JSON, pas de runtime. | Rapport V1-61, roadmaps. | DONE : Option B retenue, `Mouse Time Probe` local separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps, scroll/clamp/snap, tests futurs, checks anti-scope. | Coder le playhead trop tot ; transformer le curseur V1-52 en scrubber sans contrat ; promettre un playback non implemente. | DONE : contrat futur clair, aucune capability ajoutee. | V1-60. |
+| NS-SCENES-V1-62 | Cinematic Timeline Mouse Time Probe / Playhead Drag V0 | editor / ui-readonly | Implementer le repere temporel souris local selon le contrat V1-61. | Pas de playback, seek runtime, scrubber runtime, drag de blocs, resize, reorder, mutation JSON, runtime, persistence temporelle ou model core. | Builder cinematics, tests widget. | TODO : click/drag axe/fond, clamp 0..totalDurationMs, scroll horizontal, selection/inspecteur preserves, hover/aide/clavier/transports preserves, non-mutation. | Confondre probe local et playback playhead ; deplacer les blocs ; casser V1-56/V1-57/V1-59/V1-60. | TODO : probe souris lisible et local, sans nouveau pouvoir runtime/editor temporel. | V1-61. |

 ## Options comparees

@@ -953,6 +954,20 @@ Preuve : RED cible du help clavier, suite Builder `+46`, suite Library `+10`, te

 Prochain lot exact : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`.

+## Mise a jour V1-61
+
+Statut : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract` est DONE.
+
+Decision : V1-61 retient l'Option B : un futur `Mouse Time Probe` local, visuel et editor-only, separe de `selectedStepId`. Il peut etre place par clic ou drag sur l'axe/fond temporel, jamais par drag sur une barre, et ne demarre aucun playback.
+
+Contrat futur : click sur axe/fond positionne le probe ; drag axe/fond le fait suivre la souris ; release fige la position locale ; cancel revient a la derniere position stable ; clic sur barre continue de selectionner le bloc ; drag sur barre reste interdit en V1-62 ; conversion souris -> temps via origine X commune, scroll horizontal, `pixelsPerMs`, clamp `0..totalDurationMs`, snap V0 aux debuts/fins de blocs seulement si proche.
+
+Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucune image IA, aucun scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnees Selbrume.
+
+Preuve : rapport V1-61 avec passes A-I, Design Gate 28 points, options comparees, tests futurs et checks anti-scope. `git diff --check` propre et `git diff --name-only -- packages` vide.
+
+Prochain lot exact : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.
+
 ## Selbrume golden slice

 Avant le golden slice, il faut au minimum :
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index b7a5f25f..28f349b4 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -115,16 +115,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract | DONE | Lot documentaire : contrat ArrowUp/ArrowDown retenu avant implementation. Option B recommandee : chercher la prochaine lane non vide au-dessus/dessous, choisir le bloc au `centerMs` le plus proche, ignorer les lanes vides, garder la selection aux bords, definir le cas sans selection, tie-breaks et tests futurs, sans code produit, package, runtime, playback, seek, drag/drop, resize, reorder ni mutation. |
 | NS-SCENES-V1-59 — Cinematic Timeline Lane Vertical Navigation V0 | DONE | ArrowUp/ArrowDown implementes selon Option B : prochaine lane non vide, cible par proximite `centerMs`, tie-break distance puis `stepIndex`, lanes vides ignorees, bords stables, cas sans selection et timeline vide traites, TextFields proteges, curseur/preview/inspecteur synchronises, Visual Gate 1663x926, sans playback, seek, drag/drop, resize, reorder, runtime ni mutation. |
 | NS-SCENES-V1-60 — Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0 | DONE | Aide clavier compacte de timeline : le long badge est remplace par `Aide clavier`, panneau local toggle click expliquant `← / →`, `↑ / ↓`, Home et End, mention selection-only, selection/curseur/inspecteur preserves, Visual Gate 1663x926, sans playback, seek, scrubber, mouse playhead, drag/drop, resize, reorder, runtime ni mutation. |
+| NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract | DONE | Lot documentaire : contrat futur `Mouse Time Probe` local type Final Cut, separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps avec scroll/clamp/snap, tests V1-62 listes, sans code produit, package, test, screenshot, image IA, playback, seek runtime, scrub actif, drag de blocs, runtime ni mutation. |

 ## Prochain lot recommande

-`NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`
+`NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`

-Raison : V1-60 explique proprement les raccourcis clavier sans ajouter de pouvoir timeline. Le prochain verrou naturel est de cadrer le futur playhead souris type Final Cut demande comme direction produit, sans coder de seek, scrubber, drag/drop, playback, runtime ni mutation.
+Raison : V1-61 a cadre le repere temporel souris sans implementation. Le prochain verrou naturel est d'implementer le `Mouse Time Probe` local selon ce contrat, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.

-Ordre apres V1-60 : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`.
+Ordre apres V1-61 : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.

-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0, puis Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0, puis Cinematic Timeline Mouse Playhead / Scrub Prep Contract.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0, puis Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0, puis Cinematic Timeline Mouse Playhead / Scrub Prep Contract, puis Cinematic Timeline Mouse Time Probe / Playhead Drag V0.

 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.

@@ -268,6 +269,20 @@ Preuve : RED/GREEN cible du help clavier, suite Builder `+46`, suite Library `+1

 Prochain lot exact : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract`.

+## Mise a jour V1-61
+
+Statut : `NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract` est DONE.
+
+Decision : V1-61 retient l'Option B : un futur `Mouse Time Probe` local, visuel et editor-only, distinct du curseur de selection V1-52 et de `selectedStepId`. Il prepare le feeling de montage type Final Cut sans coder le scrubber.
+
+Contrat futur : click axe/fond place le probe ; drag axe/fond le fait suivre la souris ; release fige le temps local ; cancel restaure la position stable ; clic barre selectionne toujours le bloc ; drag barre ne deplace pas le bloc. Conversion souris -> temps : origine X commune ticks/barres/curseur, scroll horizontal, `pixelsPerMs`, clamp `0..totalDurationMs`, snap V0 aux debuts/fins de blocs si proche.
+
+Limites : doc-only, pas de code produit, package, test, screenshot, image IA, scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnee Selbrume.
+
+Preuve : rapport V1-61 complet, Design Gate 28 points, options comparees, tests futurs V1-62, checks anti-scope, `git diff --check` propre et `git diff --name-only -- packages` vide.
+
+Prochain lot exact : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`.
+
 ## Mise a jour V1-31

 Statut : `NS-SCENES-V1-31 — Scene Consequence Authoring UI V0` est DONE.
```

### 27.2 Sorties finales

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
```

Commande whitespace dediee au rapport non suivi :

```bash
perl -ne 'print "$ARGV:$.: $_" if /[ \t]+$/' reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
```

Sortie exacte apres nettoyage :

```text
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../scenes/road_map_scene_builder_authoring.md     | 19 ++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 23 ++++++++++++++++++----
 2 files changed, 36 insertions(+), 6 deletions(-)
```

Note : `git diff --stat` ne liste pas le rapport V1-61 car il est encore non suivi ; il apparait dans `git status --short --untracked-files=all`.

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
```

Commande :

```bash
git diff --name-only -- packages
```

Sortie exacte :

```text
```

Commande anti-code packages :

```bash
git diff --unified=0 -- packages | rg -n "onPanStart|onPanUpdate|onHorizontalDrag|GestureDetector|Listener|PointerMoveEvent|MouseRegion|Draggable|DragTarget|scrub|scrubber|seek|currentTimeMs|playbackTimeMs|isPlaying|Timer\(|Ticker|AnimationController" || true
```

Sortie exacte :

```text
```

Interpretation : aucun code produit sous `packages/` n'a ete modifie et aucune occurrence souris/scrub/runtime n'a ete ajoutee dans le diff packages.

Commande anti-runtime sur le diff roadmaps :

```bash
git diff --unified=0 -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md | rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" || true
```

Sortie exacte :

```text
9:-| NS-SCENES-V1-61 | Cinematic Timeline Mouse Playhead / Scrub Prep Contract | doc-only / interaction-contract | Cadrer le futur playhead souris type Final Cut avant toute implementation. | Pas de code produit, pas de seek actif, pas de drag, pas de playback, pas de scrubber, pas de mutation JSON, pas de runtime. | Rapport V1-61, roadmaps. | TODO : definir contrat UX, donnees derivees, risques, anti-scope, tests futurs et separation selection/playback. | Coder le playhead trop tot ; transformer le curseur V1-52 en scrubber sans contrat ; promettre un playback non implemente. | TODO : contrat futur clair, aucune capability ajoutee. | V1-60. |
10:+| NS-SCENES-V1-61 | Cinematic Timeline Mouse Playhead / Scrub Prep Contract | doc-only / interaction-contract | Cadrer le futur playhead souris type Final Cut avant toute implementation. | Pas de code produit, pas de seek actif, pas de drag, pas de playback, pas de scrubber, pas de mutation JSON, pas de runtime. | Rapport V1-61, roadmaps. | DONE : Option B retenue, `Mouse Time Probe` local separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps, scroll/clamp/snap, tests futurs, checks anti-scope. | Coder le playhead trop tot ; transformer le curseur V1-52 en scrubber sans contrat ; promettre un playback non implemente. | DONE : contrat futur clair, aucune capability ajoutee. | V1-60. |
11:+| NS-SCENES-V1-62 | Cinematic Timeline Mouse Time Probe / Playhead Drag V0 | editor / ui-readonly | Implementer le repere temporel souris local selon le contrat V1-61. | Pas de playback, seek runtime, scrubber runtime, drag de blocs, resize, reorder, mutation JSON, runtime, persistence temporelle ou model core. | Builder cinematics, tests widget. | TODO : click/drag axe/fond, clamp 0..totalDurationMs, scroll horizontal, selection/inspecteur preserves, hover/aide/clavier/transports preserves, non-mutation. | Confondre probe local et playback playhead ; deplacer les blocs ; casser V1-56/V1-57/V1-59/V1-60. | TODO : probe souris lisible et local, sans nouveau pouvoir runtime/editor temporel. | V1-61. |
21:+Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucune image IA, aucun scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnees Selbrume.
32:+| NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract | DONE | Lot documentaire : contrat futur `Mouse Time Probe` local type Final Cut, separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps avec scroll/clamp/snap, tests V1-62 listes, sans code produit, package, test, screenshot, image IA, playback, seek runtime, scrub actif, drag de blocs, runtime ni mutation. |
37:-Raison : V1-60 explique proprement les raccourcis clavier sans ajouter de pouvoir timeline. Le prochain verrou naturel est de cadrer le futur playhead souris type Final Cut demande comme direction produit, sans coder de seek, scrubber, drag/drop, playback, runtime ni mutation.
38:+Raison : V1-61 a cadre le repere temporel souris sans implementation. Le prochain verrou naturel est d'implementer le `Mouse Time Probe` local selon ce contrat, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.
50:+Decision : V1-61 retient l'Option B : un futur `Mouse Time Probe` local, visuel et editor-only, distinct du curseur de selection V1-52 et de `selectedStepId`. Il prepare le feeling de montage type Final Cut sans coder le scrubber.
54:+Limites : doc-only, pas de code produit, package, test, screenshot, image IA, scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnee Selbrume.
```

Interpretation : ces occurrences sont documentaires, negatives ou d'analyse de contrat ; aucun code runtime n'est ajoute.

Commande anti-runtime sur le corps du rapport avant l'Evidence Pack :

```bash
awk '/^## 27\. Evidence Pack/{exit} {print}' reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md | rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" || true
```

Sortie exacte :

```text
10:V1-61 est un lot documentaire / interaction-contract. Il cadre le futur comportement d'un repere temporel souris dans la timeline du Cinematic Builder, avec un feeling proche d'un outil de montage, sans coder le scrubber.
16:V1-61 ne code pas encore le scrubber.
106:Il est derive, non interactif, non persistant. Il n'est pas un playback playhead, pas un temps courant runtime et pas un scrubber.
151:4. Nom produit retenu : `Mouse Time Probe` pour V0 ; `playhead` reste un terme visuel, `scrubber` est reserve a un futur plus avance.
173:26. Ne pas coder directement le scrubber en V1-61 car les frontieres selection/playback/runtime doivent etre tranchees avant.
271:Le probe ne rend pas Reset / Play / Stop actifs. Il ne cree pas `isPlaying`, `currentTimeMs`, `playbackTimeMs` ni controller.
275:Le probe est une inspection editor locale. Il ne doit pas appeler `playCinematic`, `SceneRuntimeExecutor`, `PlayableMapGame`, `runtimePreview` ou `previewRuntime`. Le vrai playback runtime reste un lot separe.
312:- scrubber actif ;
313:- seek runtime ;
330:Objectif futur : implementer le probe local selon ce contrat, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.
350:- aucun code souris/scrub ajoute dans un fichier de production ;
```

Interpretation : toutes les occurrences sont dans le contrat, les limites ou les non-objectifs.

Commande anti-image sur le corps du rapport avant l'Evidence Pack :

```bash
awk '/^## 27\. Evidence Pack/{exit} {print}' reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md | rg -n "gpt-image-2|image_generation|generate image|AI image|image model|image IA|outil image" || true
```

Sortie exacte :

```text
311:- outil image IA ;
352:- aucune image IA ;
```

Interpretation : occurrences negatives uniquement ; aucun outil image n'a ete utilise.

Commande anti-image sur les roadmaps :

```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model|image IA|outil image" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:965:Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucune image IA, aucun scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnees Selbrume.
reports/narrativeStudio/scenes/road_map_scenes.md:118:| NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract | DONE | Lot documentaire : contrat futur `Mouse Time Probe` local type Final Cut, separe de `selectedStepId`, zones axe/fond, click/drag/release/cancel, conversion souris -> temps avec scroll/clamp/snap, tests V1-62 listes, sans code produit, package, test, screenshot, image IA, playback, seek runtime, scrub actif, drag de blocs, runtime ni mutation. |
reports/narrativeStudio/scenes/road_map_scenes.md:280:Limites : doc-only, pas de code produit, package, test, screenshot, image IA, scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnee Selbrume.
```

Interpretation : occurrences negatives uniquement.

Commande anti-Selbrume sur le diff roadmaps :

```bash
git diff --unified=0 -- reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md | rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" || true
```

Sortie exacte :

```text
21:+Limites : doc-only, aucun code produit, aucun package, aucun test, aucun screenshot, aucune image IA, aucun scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnees Selbrume.
54:+Limites : doc-only, pas de code produit, package, test, screenshot, image IA, scrub actif, seek runtime, playback, timer, drag/drop de blocs, resize, reorder, runtime, mutation JSON, persistence temporelle ou donnee Selbrume.
```

Interpretation : occurrences negatives uniquement ; aucune donnee Selbrume n'est ajoutee.

Commande anti-Selbrume sur le corps du rapport avant l'Evidence Pack :

```bash
awk '/^## 27\. Evidence Pack/{exit} {print}' reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md | rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" || true
```

Sortie exacte :

```text
320:- donnees Selbrume.
353:- aucune donnee Selbrume.
```

Interpretation : occurrences negatives uniquement.

## 28. Auto-review critique

- Ai-je modifie du code produit ? Non, seulement roadmaps et rapport.
- Ai-je lance des tests alors que le lot documentaire les exclut ? Non.
- Ai-je defini selection vs probe vs playback ? Oui, sections 10, 11, 16 et 21.
- Ai-je laisse une ambiguite sur le drag de barre ? Non, interdit en V1-62.
- Ai-je promis une preview runtime ? Non, preview sandbox informative seulement.
- Risque restant : V1-62 devra etre strictement TDD pour ne pas transformer le probe en seek runtime.

## 29. Verdict final

V1-61 est DONE : aucun package modifie, rapport complet, roadmaps a jour, `git diff --check` propre, anti-scope confirme. Le lot dessine le contrat du playhead souris ; il ne code pas encore le scrubber.
