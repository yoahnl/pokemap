# NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0

Date : 2026-06-03
Statut : DONE
Type : documentaire / interaction-contract / prep
Lot precedent : `NS-SCENES-V1-62 — Cinematic Timeline Mouse Time Probe / Playhead Drag V0`
Prochain lot recommande : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`

## 1. Resume executif

V1-63 definit comment polir le repere temporel souris du Cinematic Builder sans coder ce polish. Le lot tranche le futur snap V0 : Option E, snap leger aux bords de timeline et aux starts/ends de blocs, jamais aux ticks arbitraires. Le seuil retenu est `8 px`, converti en temps via `pixelsPerMs`.

Phrase canonique :

```text
V1-63 definit comment polir le repere souris.
V1-63 ne code pas encore le polish avance.
```

V1-63 ne modifie aucun package, aucun test, aucun widget et ne produit aucun screenshot.

## 2. Gate 0

Commande executee depuis la racine avant modification V1-63 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
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
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides avant V1-63.

## 3. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
```

Skill applique : `writing-plans` adapte au format impose par le lot. Aucun plan separe n'a ete cree car la demande impose un rapport V1-63 comme artefact final. `verification-before-completion` est utilise pour la validation finale.

## 4. Pourquoi ce lot est documentaire

Le snap change le ressenti du probe : il peut rendre la timeline plus precise, mais aussi faire croire que le repere est un vrai seek runtime ou que les blocs deviennent editables. V1-63 verrouille donc les decisions avant implementation.

Regle V1-63 : ne rien coder dans `packages/`, ne modifier aucun test, ne produire aucun screenshot, ne lancer aucun build_runner.

## 5. Etat actuel apres V1-62

V1-62 fournit deja :

```text
timelineProbeTimeMs local
click/drag axe ou fond timeline
conversion X -> temps
scroll horizontal pris en compte
clamp 0..totalDurationMs
badge Repere : <temps>
preview sandbox informative
clear du probe sur selection bloc/clavier
ProjectManifest non mute
```

Ce qui reste ouvert : snap, seuils, libelles d'alignement, bords, fallback blocks, blocs proches, Escape/click hors timeline, et tests futurs.

## 6. Pass A — Audit du probe V1-62

`timelineProbeTimeMs` vit dans `_CinematicBuilderWorkspaceState`. Il est transmis a la preview et a la timeline, puis rendu en priorite sur le curseur de selection. Si le probe existe, le badge est `Repere : <temps>` ; sinon la selection peut afficher `Selection : <temps>`.

Le click/drag se fait sur l'axe ou le fond des pistes. Les barres restent prioritaires pour la selection. La conversion actuelle part de l'espace local du contenu temporel et clamp entre `0` et `totalDurationMs`.

Conclusion Pass A : le futur snap doit rester une transformation locale de la valeur du probe, jamais une mutation de selection ou de timeline.

## 7. Pass B — Audit de la geometrie V1-56

V1-56 garantit que ticks, barres, curseur de selection et probe partagent l'origine X du contenu temporel. Les barres utilisent `startMs` pour leur position et `visualDurationMs` pour leur largeur. Les rows gardent les proportions demandees par Karim.

Conclusion Pass B : le snap doit comparer des distances en pixels dans le meme espace que `_tickLeft(...)`, les barres et le probe. Un seuil en ms serait instable quand la duree totale change.

## 8. Pass C — Audit selection / clavier / hover

La selection de bloc reste portee par `selectedStepId`. La navigation clavier V1-57/V1-59 selectionne des blocs et clear le probe via `onStepSelected`. Le hover V1-55 est informatif et ne selectionne rien. L'aide clavier V1-60 reste un panneau local. Les transports V1-53 restent disabled.

Conclusion Pass C : le snap ne doit jamais modifier `selectedStepId`, ne doit pas changer l'inspecteur, ne doit pas ouvrir l'aide clavier et ne doit pas rendre les transports actifs.

## 9. Design Gate — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0

1. V1-62 existe aujourd'hui : probe local click/drag axe/fond, clamp, scroll, badge, preview informative.
2. Problemes UX restants : viser exactement debut/fin de bloc, bords, libelles d'alignement, timelines longues/courtes, blocs proches.
3. Le probe doit rester fluide mais devenir legerement magnetique pres de cibles metier.
4. Snap aux ticks : non en V0.
5. Snap aux starts de blocs : oui en V1-64.
6. Snap aux ends de blocs : oui en V1-64.
7. Snap au start du bloc selectionne : pas comme cas special ; il est couvert par `block.startMs`.
8. Snap a `0 ms` et `totalDurationMs` : oui.
9. Seuil acceptable : `8 px`, derive en ms par `8 / pixelsPerMs`.
10. Click et drag utilisent le meme seuil pour rester predictibles.
11. Snap seulement au release : rejete pour V0, car le drag semblerait libre puis sauterait a la fin.
12. Indication visuelle : oui, badge suffixe sobre quand aligne.
13. Eviter le seek runtime : ne jamais employer `Lecture`, `Seek`, `Scrub`, `Temps courant`.
14. Eviter l'edition de bloc : ne jamais afficher de handle de resize, ne jamais changer les barres.
15. Scroll horizontal : calculer cibles et pointer dans l'espace du contenu temporel scrollable.
16. Timelines tres courtes : garder `8 px`, choisir la cible la plus proche, ne pas augmenter le seuil.
17. Timelines tres longues : `8 px` reste stable a l'ecran ; le temps derive varie naturellement.
18. Blocs fallback 300 ms : ils participent au snap avec leurs start/end visuels.
19. Blocs tres proches : tie-break distance px, puis priorite start avant end, puis `stepIndex`.
20. Bords gauche/droite : bords timeline prioritaires si meme position qu'un bloc.
21. Badge : conserver `Repere`.
22. Selection vs repere : selection pilote inspecteur, repere pilote seulement l'inspection temporelle locale.
23. Clear sur Escape : utile plus tard, mais hors V1-64 pour garder le lot snap borne.
24. Clear click hors timeline : non en V1-64, car cela ouvrirait une gestion globale fragile.
25. Navigation clavier : conserve son contrat et clear le probe comme V1-62.
26. Hover : reste informatif, ignore le snap.
27. Aide clavier : inchangee.
28. Transports disabled : inchanges.
29. Ne pas coder le snap dans V1-63 : le lot est un contrat de prep, et le prompt interdit le code.
30. Tests futurs : voir section 22.
31. Prochain lot exact : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`.

## 10. Options de snap comparees

| Option | Verdict | Analyse |
|---|---|---|
| A — Aucun snap, polish seulement | Rejetee | Simple et fluide, mais ne resout pas la precision aux debuts/fins de blocs. |
| B — Snap leger aux bords seulement | Rejetee pour V1-64 | Utile et peu intrusif, mais trop faible apres V1-62 : les blocs restent difficiles a viser. |
| C — Snap aux starts/ends de blocs | Rejetee seule | Utile, mais oublie les bords timeline qui sont les cibles les plus simples a comprendre. |
| D — Snap aux ticks | Rejetee | Les ticks sont une aide visuelle arbitraire, pas une cible metier fiable. |
| E — Snap hybride bords + blocs, jamais ticks | Retenue | Cibles utiles, lisibles, liees aux actions reelles, tout en evitant le snap aux graduations arbitraires. |

## 11. Option V0 recommandee

Option E est retenue : snap leger aux bords de timeline et aux starts/ends de blocs, jamais aux ticks.

Raison : cette option aide l'inspection sans transformer la timeline en editeur temporel. Elle suit les cibles que l'auteur comprend naturellement : debut, fin, debut de bloc, fin de bloc.

## 12. Contrat recommande pour V1-64

`NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0` devra implementer seulement le snap local du probe.

Contrat :

```text
pointer -> freeTimeMs
freeTimeMs -> freeX
snapTargets -> targetX
si distancePx <= 8 : snappedTimeMs + hint
sinon : freeTimeMs sans hint
```

Le resultat modifie seulement `timelineProbeTimeMs` et un hint visuel local eventuel.

## 13. Snap targets

Autorisees en V1-64 :

```text
0 ms
totalDurationMs
block.startMs
block.endMs
```

Interdites en V1-64 :

```text
ticks arbitraires
milieux de blocs
frames internes
timeline grid every N ms
positions interpolees runtime
```

Les targets doivent etre dedupliquees par `timeMs` avant tie-break final. Si `0 ms` et `block.startMs` sont identiques, le hint `debut timeline` gagne.

## 14. Seuils de snap

Seuil retenu :

```text
snapThresholdPx = 8
```

Pourquoi en pixels : le ressenti ecran reste stable quelle que soit la duree totale. En implementation, le seuil temps derive peut etre :

```text
snapThresholdMs = snapThresholdPx / pixelsPerMs
```

mais la comparaison recommandee reste en pixels.

## 15. Click / drag / release

Click : snap immediat si une cible est a `<= 8 px`, sinon position libre.

Drag : snap pendant le drag si proche, afin d'eviter un saut surprenant au release. Le badge peut afficher un hint d'alignement.

Release : conserve la derniere position calculee, libre ou snapped. Aucun commit, aucun playback, aucune mutation.

## 16. Edge cases de bords

Timeline vide : pas de probe, pas de snap, pas de crash.

Timeline duree 0 : ignorer le geste ou garder `0 ms` sans hint ; recommandation V1-64 : ignorer si aucun bloc utile n'existe.

Debut timeline : `0 ms` prioritaire sur un `block.startMs` identique.

Fin timeline : `totalDurationMs` prioritaire sur un `block.endMs` identique.

Blocs tres proches : choisir la distance px la plus faible ; egalite : start avant end ; nouvelle egalite : plus petit `stepIndex`.

## 17. Edge cases de scroll

Le snap doit utiliser le meme espace que V1-62 :

```text
contentX = pointer local dans le contenu temporel scrollable
targetX = targetTimeMs * pixelsPerMs
distancePx = abs(contentX - targetX)
```

Interdit : comparer contre une position ecran brute ou contre la colonne des pistes.

Timelines longues : le scroll ne change pas les `targetX`; il change seulement le viewport visible. Les tests doivent scroller puis cliquer pres d'une target visible.

## 18. Relation avec selectedStepId

Le snap ne change jamais `selectedStepId`. Le bloc selectionne reste selectionne, l'inspecteur reste stable et le probe reste une inspection temporelle temporaire.

Un clic sur une barre continue de selectionner le bloc et clear le probe, comme V1-62.

## 19. Relation avec preview sandbox

La preview sandbox reste informative :

```text
Repere temporel : <temps>
Preview reelle a venir.
```

Si un hint snap est ajoute, il peut rester dans le badge timeline plutot que dans la preview pour eviter de faire croire a une preview runtime.

## 20. Relation avec hover / aide / transports

Hover : ignore le snap et continue de decrire le bloc survole.

Aide clavier : inchangee. Ne pas transformer V1-64 en aide souris complete.

Transports : Reset / Play / Stop restent disabled. Le snap ne debloque rien.

## 21. Vocabulaire UI recommande

Badge principal :

```text
Repere : <temps>
```

Si snap actif :

```text
Repere : <temps> · aligné
Repere : <temps> · debut bloc
Repere : <temps> · fin bloc
Repere : <temps> · debut timeline
Repere : <temps> · fin timeline
```

Interdit :

```text
Lecture
Playback
Seek
Scrub
Temps courant
Position runtime
```

## 22. Tests futurs requis

Tests V1-64 recommandes :

```text
click near 0ms snaps to timeline start
drag near totalDurationMs snaps to timeline end
click near block start snaps to block start
click near block end snaps to block end
drag near block boundary updates badge with snap hint
click far from snap target remains free
drag far from snap target remains free
snap does not change selectedStepId
snap does not change inspector
snap does not mutate ProjectManifest
snap does not move or resize block
snap respects horizontal scroll offset
snap chooses nearest target when multiple targets are close
snap handles fallback 300ms blocks
snap handles empty timeline without crash
keyboard navigation clears snapped probe like free probe
hover details remain functional
transport controls remain disabled
```

## 23. Non-objectifs confirmes

V1-63 ne code pas de snap, ne modifie aucun package, ne modifie aucun test, ne genere aucun screenshot, ne lance aucun build_runner et n'appelle aucun outil image IA.

V1-63 n'ajoute aucun playback, seek runtime, scrubber runtime, timer, ticker, `AnimationController`, `isPlaying`, `currentTimeMs`, `playbackTimeMs`, transport fonctionnel, drag/resize/reorder de blocs, mutation JSON ou runtime.

## 24. Roadmap post V1-63

Prochain lot exact recommande :

```text
NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0
```

Objectif : implementer le snap leger du repere temporel souris selon ce contrat, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.

## 25. Commandes executees

Gate 0 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Audits :

```bash
sed -n '1,220p' AGENTS.md
sed -n '1,220p' agent_rules.md
sed -n '1,220p' skills/README.md
sed -n '1,220p' skills/writing-plans/SKILL.md
sed -n '1,220p' skills/verification-before-completion/SKILL.md
rg -n "V1-62|V1-63|V1-64|Prochain lot|Mise a jour V1-62|Mouse Probe|Boundary Snap" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
rg -n "Resume|Design Gate|Option|snap|Snap|timelineProbeTimeMs|Repere|Repère|scroll|clamp|keyboard|hover|transport|Auto-review|Prochain" reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md reports/narrativeStudio/scenes/ns_scenes_v1_62_evidence_pack.md reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md
rg -n "timelineProbeTimeMs|_timelineProbeTimeMsFromLocalX|_TimelineTimeProbeCursor|cinematic-builder-time-horizontal-scroll|onTimelineProbeChanged|selectedStepId|hoveredStepId|_timelineKeyboard|_tickLeft|visualDurationMs|fallback|laneById" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
```

Validation documentaire finale :

```bash
printf '%s\n' '-- git diff --check --'; git diff --check; printf '%s\n' '-- git diff --stat --'; git diff --stat; printf '%s\n' '-- git diff --name-only --'; git diff --name-only; printf '%s\n' '-- git status --short --untracked-files=all --'; git status --short --untracked-files=all; printf '%s\n' '-- git diff --name-only -- packages --'; git diff --name-only -- packages; printf '%s\n' '-- trailing whitespace check edited docs --'; if rg -n '[ \t]+$' reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md; then exit 1; else echo 'no trailing whitespace in edited V1-63 docs'; fi
```

Sortie :

```text
-- git diff --check --
-- git diff --stat --
 .../scenes/road_map_scene_builder_authoring.md     | 19 ++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 23 ++++++++++++++++++----
 2 files changed, 36 insertions(+), 6 deletions(-)
-- git diff --name-only --
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
-- git status --short --untracked-files=all --
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md
-- git diff --name-only -- packages --
-- trailing whitespace check edited docs --
no trailing whitespace in edited V1-63 docs
```

Note : le rapport V1-63 est un fichier non suivi tant qu'il n'est pas ajoute a Git ; `git diff --stat` liste donc seulement les roadmaps deja suivies.

## 26. Checks anti-scope

Checks requis :

```bash
git diff --name-only -- packages
rg -n "snap|snapThreshold|onPanStart|onPanUpdate|onHorizontalDrag|GestureDetector|Listener|PointerMoveEvent|MouseRegion|Draggable|DragTarget|scrub|scrubber|seek|currentTimeMs|playbackTimeMs|isPlaying|Timer\\(|Ticker|AnimationController" packages/map_editor packages/map_core || true
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|playCinematic|runtimePreview|previewRuntime|startPlayback|seek|scrub|scrubber|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md || true
```

Interpretation attendue : aucune modification dans `packages/`. Les occurrences dans `packages/` sont preexistantes et ne viennent pas de V1-63. Les occurrences dans les rapports sont des non-objectifs, analyses ou contrats futurs, pas du code.

## 27. Evidence Pack

Hunks roadmaps complets releves :

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index afa1379c..87781a5d 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -12 +12 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
-NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0
+NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0
@@ -99 +99,2 @@ NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V
-| NS-SCENES-V1-63 | Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0 | doc / ui-polish-prep | Cadrer le polish futur du probe souris : lisibilite, bords, snap optionnel aux bornes, edge cases de scroll et libelles. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, implementation snap si le contrat reste ambigu. | Rapport V1-63, roadmaps, eventuels tests futurs. | TODO : options snap/no snap comparees, seuils et edge cases documentes, contraintes V1-62 preservees. | Rendre le probe trop proche d'un playhead runtime ; introduire un snap saccade sans contrat. | TODO : contrat polish/snap clair avant implementation. | V1-62. |
+| NS-SCENES-V1-63 | Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0 | doc / ui-polish-prep | Cadrer le polish futur du probe souris : lisibilite, bords, snap optionnel aux bornes, edge cases de scroll et libelles. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, implementation snap si le contrat reste ambigu. | Rapport V1-63, roadmaps. | DONE : Option E retenue, snap futur aux bords et starts/ends de blocs, seuil `8 px`, click/drag/release cadres, bords/scroll/fallback/tie-breaks/vocabulaire/tests futurs documentes. | Rendre le probe trop proche d'un playhead runtime ; introduire un snap saccade sans contrat. | DONE : contrat polish/snap clair avant implementation, sans code produit ni package modifie. | V1-62. |
+| NS-SCENES-V1-64 | Cinematic Timeline Mouse Probe Boundary Snap V0 | editor / ui-readonly | Implementer le snap leger du repere souris selon le contrat V1-63. | Pas de playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, mutation JSON, runtime, snap ticks, edition temporelle ou transport fonctionnel. | Builder cinematics, tests widget. | TODO : snap 0/fin/starts/ends par seuil 8 px, badge alignement, scroll respecte, selection/inspecteur/projet preserves. | Confondre snap d'inspection et edition temporelle ; rendre le drag saccade ; casser V1-62. | TODO : snap local et reversible, sans nouveau pouvoir runtime/editor temporel. | V1-63. |
@@ -985,0 +987,14 @@ Prochain lot exact : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish
+## Mise a jour V1-63
+
+Statut : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0` est DONE.
+
+Decision : V1-63 reste documentaire. L'option V0 retenue pour le futur est l'Option E : snap leger aux bords `0 ms` / `totalDurationMs` et aux `block.startMs` / `block.endMs`, jamais aux ticks arbitraires. Le seuil recommande est `8 px`, converti en temps via `pixelsPerMs`, pour conserver une sensation stable a l'ecran.
+
+Contrat futur V1-64 : click snap immediat si proche d'une cible ; drag snap pendant le drag si proche, avec indication subtile ; release conserve la derniere position libre ou alignee. Le snap ne modifie jamais `selectedStepId`, l'inspecteur, les barres, `visualDurationMs`, `CinematicTimeline.steps` ou `ProjectManifest`.
+
+Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun snap actif, aucun playback, seek runtime, scrubber runtime, drag de blocs, resize, reorder, runtime, mutation JSON, build_runner, image IA ou donnees Selbrume.
+
+Preuve : rapport V1-63 avec passes A-I, Design Gate 31 points, options A-E comparees, edge cases bords/scroll/fallback/blocs proches, tests futurs V1-64 et checks anti-scope documentaires.
+
+Prochain lot exact : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`.
+
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index d80498c2..5d1b5a98 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -119,0 +120 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
+| NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0 | DONE | Lot documentaire : Option E retenue pour le futur snap du probe, cibles `0 ms`, `totalDurationMs`, `block.startMs`, `block.endMs`, seuil `8 px`, click/drag/release cadres, edge cases bords/scroll/fallback/blocs proches et tests V1-64 definis, sans code produit, package, screenshot, snap actif, playback, seek runtime, drag de blocs, runtime ni mutation. |
@@ -123 +124 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
-`NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`
+`NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`
@@ -125 +126 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
-Raison : V1-62 a implemente le repere souris local sans playback. Le prochain verrou naturel est de cadrer le polish du probe, les bords, les eventuels seuils de snap et les edge cases de scroll avant toute sensation de montage plus avancee.
+Raison : V1-63 a cadre le snap futur sans le coder. Le prochain verrou naturel est d'implementer ce snap leger du probe selon le contrat, en gardant la timeline strictement editor-only et non mutante.
@@ -127 +128 @@ Raison : V1-62 a implemente le repere souris local sans playback. Le prochain ve
-Ordre apres V1-62 : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0`.
+Ordre apres V1-63 : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`.
@@ -129 +130 @@ Ordre apres V1-62 : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish /
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0, puis Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0, puis Cinematic Timeline Mouse Playhead / Scrub Prep Contract, puis Cinematic Timeline Mouse Time Probe / Playhead Drag V0, puis Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0, puis Cinematic Actor References / Actor Facing V0, puis Cinematic Actor Movement Block V0 Prep / Contract, puis Cinematic Timeline Lane Grouping V0, puis Cinematic Actor Movement Block V0, puis Cinematic Actor Movement Inspector Polish / Target Labels V0, puis Cinematic Timeline Time Axis / Bar Layout V0, puis Cinematic Timeline Selection Cursor / Playhead Placeholder V0, puis Cinematic Timeline Transport Controls Placeholder V0, puis Cinematic Timeline Visual Polish / Density Pass V0, puis Cinematic Timeline Interaction Polish / Hover Details V0, puis Cinematic Timeline Bar Geometry / Duration Scale Correction V0, puis Cinematic Timeline Keyboard Navigation / Selection Polish V0, puis Cinematic Timeline Lane Vertical Navigation Prep / Contract, puis Cinematic Timeline Lane Vertical Navigation V0, puis Cinematic Timeline Keyboard Navigation Polish / Help Overlay V0, puis Cinematic Timeline Mouse Playhead / Scrub Prep Contract, puis Cinematic Timeline Mouse Time Probe / Playhead Drag V0, puis Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0, puis Cinematic Timeline Mouse Probe Boundary Snap V0.
@@ -300,0 +302,14 @@ Prochain lot exact : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish
+## Mise a jour V1-63
+
+Statut : `NS-SCENES-V1-63 — Cinematic Timeline Mouse Probe Polish / Boundary Snap Prep V0` est DONE.
+
+Decision : V1-63 reste un lot documentaire / interaction-contract. Le futur snap V0 recommande est l'Option E : bords `0 ms` / `totalDurationMs` + starts/ends de blocs, jamais ticks arbitraires. Le seuil retenu est `8 px`, derive en ms via `pixelsPerMs`.
+
+Contrat futur : click snap immediat si proche ; drag snap pendant le drag avec indication subtile ; release conserve la derniere position libre ou alignee. Le badge reste `Repere : <temps>`, avec suffixe sobre possible `aligné`, `debut bloc`, `fin bloc`, `debut timeline` ou `fin timeline`.
+
+Limites : aucun code produit, aucun package, aucun test, aucun screenshot, aucun snap actif, aucun playback, timer, seek runtime, scrubber runtime, preview runtime, transport fonctionnel, drag/drop de blocs, resize, reorder, changement JSON/core, runtime, build_runner, image IA ou donnees Selbrume.
+
+Preuve : rapport V1-63 complet avec passes A-I, Design Gate 31 points, options A-E comparees, edge cases de bords/scroll/fallback/blocs proches, tests futurs requis et checks anti-scope documentaires.
+
+Prochain lot exact : `NS-SCENES-V1-64 — Cinematic Timeline Mouse Probe Boundary Snap V0`.
```

Fichier cree :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md
```

Ce rapport est l'Evidence Pack V1-63 : il contient Gate 0, fichiers lus, audit, Design Gate, options, contrat futur, tests futurs, anti-scope et auto-review.

## 28. Auto-review critique

1. Code produit modifie ? Non.
2. Package modifie ? Non.
3. Test modifie ? Non.
4. Snap code ? Non.
5. Drag souris code ? Non.
6. Seek code ? Non.
7. Scrubber code ? Non.
8. Playback ajoute ? Non.
9. `currentTimeMs/playbackTimeMs/isPlaying` ajoutes ? Non.
10. Runtime modifie ? Non.
11. `ProjectManifest` mute ? Non.
12. Option de snap claire ? Oui, Option E.
13. Snap targets definies ? Oui : `0`, `totalDurationMs`, `block.startMs`, `block.endMs`.
14. Seuil defini ? Oui : `8 px`.
15. Click/drag/release definis ? Oui.
16. Edge cases de bords definis ? Oui.
17. Scroll horizontal traite ? Oui.
18. Relation `selectedStepId` / probe claire ? Oui.
19. Vocabulaire UI defini ? Oui.
20. Tests futurs listes ? Oui.
21. Prochain lot exact recommande ? Oui, V1-64.
22. Evidence Pack complet sans marqueur a remplacer ? Oui.

## 29. Verdict final

V1-63 peut etre marque DONE : il prepare le magnetisme du repere souris sans installer l'aimant. Le futur V1-64 devra implementer le snap leger selon ce contrat, avec tests, sans playback, seek runtime, drag de blocs, resize, reorder, runtime ni mutation.
