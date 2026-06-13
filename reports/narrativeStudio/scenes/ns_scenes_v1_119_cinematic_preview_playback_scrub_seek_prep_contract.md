# NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract

## 1. Resume executif

Verdict : `NS-SCENES-V1-119` est un lot documentaire de cadrage.

Decision retenue : `Option C — Click-to-seek + drag Playback Playhead controle`.

Le futur V1-120 doit permettre de deplacer le temps de lecture preview dans le Cinematic Builder sans confondre les trois curseurs :

- `Selection Cursor` : selection auteur du bloc inspecte ou edite.
- `Mouse Time Probe` : repere temporel local d'inspection souris.
- `Playback Playhead` : temps courant de lecture preview editor-only.

V1-119 ne code pas le seek/scrub. Le lot cadre les interactions, la hierarchie de hit-test, le snapping, la conversion souris -> temps, les effets sur Play/Pause/Stop/Reset, le wording no-code, l'accessibilite et les tests futurs V1-120.

## 2. Gate 0

Commande executee au debut :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
```

Interpretation :

- branche : `main`;
- `git status --short --untracked-files=all` : sortie vide;
- `git diff --stat` : sortie vide;
- `git diff --name-only` : sortie vide;
- aucune modification externe initiale detectee, y compris `selbrume/project.json`.

## 3. Fichiers lus

Regles et skills :

- `AGENTS.md` : lu.
- `agent_rules.md` : lu.
- `codex_rule.md` : lu.
- `codex_rules.md` : absent (`MISSING codex_rules.md`).
- `skills/README.md` : lu.
- `skills/using-superpowers/SKILL.md` : lu.
- `skills/test-driven-development/SKILL.md` : lu.
- `skills/verification-before-completion/SKILL.md` : lu.

Rapports playback relus :

- `reports/narrativeStudio/scenes/ns_scenes_v1_109_cinematic_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_111_cinematic_preview_playback_transport_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_112_cinematic_actormove_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_113_cinematic_actor_playback_smooth_motion_subtile_overlay_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_actor_move_destination_isolation_bugfix_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_evidence_pack.md`

Rapports timeline/probe/transport relus :

- `reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_61_cinematic_timeline_mouse_playhead_scrub_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_62_cinematic_timeline_mouse_time_probe_playhead_drag_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_63_cinematic_timeline_mouse_probe_polish_boundary_snap_prep_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_64_cinematic_timeline_mouse_probe_boundary_snap_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_66_cinematic_timeline_mouse_probe_help_selection_explanation_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_68_cinematic_timeline_duration_inspector_editing_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_69_cinematic_timeline_duration_resize_handles_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_70_cinematic_timeline_duration_validation_diagnostics_polish_v0.md`

Roadmaps relues :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Code et tests lus en lecture seule :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`

## 4. Rappel V1-118

V1-118 a ferme les diagnostics/fallbacks no-code de la preview cinematic. Le Builder peut deja afficher des statuts lisibles comme `Animation partielle` et des details compacts sur les acteurs ou sprites concernes. V1-118 a explicitement laisse le scrub/seek hors scope.

V1-119 part donc d'un etat ou :

- le plan playback est pur et derive;
- `playbackTimeMs` est local au Builder;
- Play/Pause/Stop/Reset fonctionnent en editor-only;
- le Playback Playhead `Lecture` est visible;
- les acteurs peuvent bouger en direct/manual path;
- la cadence d'animation preview est polie;
- aucun seek interactif n'est encore disponible.

## 5. Probleme produit

L'utilisateur peut lire une preview, mais ne peut pas encore aller directement a `500 ms`, au debut d'un bloc, ou glisser la tete de lecture pour inspecter un moment precis.

Le futur V1-120 doit ajouter cette capacite sans transformer la timeline en un editeur confus ou destructif.

## 6. Definitions

- `Playback Playhead` : tete de lecture visible `Lecture`, positionnee sur `playbackTimeMs`, future cible drag-to-scrub.
- `Playback Time` : temps local editor-only de preview, derive de l'`AnimationController` actuel ou du futur etat local de seek.
- `Seek` : action discrete qui place `Playback Time` a un temps cible.
- `Scrub` : deplacement continu de `Playback Time` pendant un drag.
- `Click-to-seek` : clic sur une zone autorisee de timeline qui place la lecture au temps correspondant.
- `Drag-to-scrub` : drag du handle du Playback Playhead qui met a jour la frame preview pendant le mouvement.
- `Selection Cursor` : curseur auteur lie au bloc selectionne, pas au temps de lecture.
- `Mouse Time Probe` : repere temporel d'inspection, pilote par interactions existantes, label `Marqueur` / `Repere`, pas un scrubber.
- `Timeline Bar` : barre d'un bloc cinematic; clic = selection du bloc.
- `Timeline Axis` : axe temporel horizontal; futur clic = seek.
- `Timeline Background` : fond vide d'une piste; futur clic = seek.
- `Transport Controls` : boutons Play/Pause/Stop/Reset.
- `Playback paused by seeking` : etat ou une interaction de seek/scrub suspend la lecture.
- `Playback resumed after seeking` : etat ou la lecture reprend si elle etait active avant le scrub, selon la regle retenue.
- `Snap target` : temps cible stable auquel un seek peut s'accrocher.
- `No-code time label` : libelle utilisateur tel que `Lecture : 500 ms / 2 s`, sans `playbackTimeMs`.

## 7. Audit du playback actuel

Pass Audit / Architecture :

- `_playbackController` porte la progression locale.
- `_playbackTimeMs(plan)` convertit `AnimationController.value` en millisecondes et clamp dans `0..plan.totalDurationMs`.
- `_togglePlayback(plan)` configure la duree du controller sur `plan.totalDurationMs`, lance ou pause.
- `_stopPlayback()` et `_resetPlayback()` appellent `_stopPlaybackWithoutSetState(resetTime: true)`.
- `playbackPlan.frameAt(playbackTimeMs)` fournit la frame preview.
- `CinematicPreviewPlaybackFrame.actorPoses` alimente l'overlay acteur preview.
- Le temps de lecture n'est pas persiste dans `CinematicAsset`, `ProjectManifest`, `MapData` ou runtime.

Conclusion : V1-120 doit rester dans cette logique editor-only et ne pas creer de source de verite concurrente dans `map_core` ou dans les donnees projet.

## 8. Audit timeline / Mouse Time Probe / Selection Cursor

Constats :

- `_timelineProbeTimeMs` et `_timelineProbeSnapHint` sont des etats locaux separes de `_selectedStepId`.
- Cliquer une barre appelle `onStepSelected(step)` et peut mettre la lecture en pause si elle etait active.
- Le fond des pistes et l'axe utilisent deja `_resolveTimelineProbeSnap(...)` pour positionner le Mouse Time Probe.
- Le snap existant utilise `_timelineProbeSnapThresholdPx = 8.0`.
- Les cibles snap existantes sont `0`, `totalDurationMs`, `block.startMs`, `block.endMs`.
- Le Selection Cursor s'affiche au debut du bloc selectionne quand aucun Mouse Time Probe n'est actif.
- Le Playback Playhead s'affiche independamment sur `playbackTimeMs`.
- Les handles de resize duration utilisent `GestureDetector` dedie sur la carte de bloc.

Risque principal : V1-120 doit deplacer une partie des interactions fond/axe du Mouse Time Probe vers le Playback Playhead sans supprimer la valeur d'inspection existante ni casser l'aide timeline/probe.

## 9. Options comparees

### Option A — Click-to-seek simple sur l'axe uniquement

Avantages :

- tres simple;
- faible risque de conflit avec les barres;
- implementation V0 facile a tester.

Limites :

- peu decouvrable;
- le fond timeline reste inactif;
- ne ressemble pas assez a un outil de montage;
- ne regle pas le besoin de scrub continu.

Verdict : trop limite pour V1-120.

### Option B — Drag uniquement sur le Playback Playhead

Avantages :

- separation conceptuelle forte;
- peu de seek accidentel;
- garde les interactions fond/probe presque intactes.

Limites :

- playhead fin, donc cible difficile;
- utilisateur bloque si la tete est hors viewport;
- ne permet pas le click-to-seek rapide.

Verdict : utile comme partie du systeme, insuffisant seul.

### Option C — Click-to-seek + drag Playback Playhead controle

Avantages :

- equilibre entre montage familier et prudence;
- clic axe/fond pour aller vite;
- drag du playhead pour scrub fin;
- clic barre conserve la selection auteur;
- compatible avec les controles existants si la hierarchie hit-test est stricte.

Limites :

- exige un arbitrage clair avec Mouse Time Probe;
- necessite un hit target confortable du playhead;
- demande des tests anti-mutation solides.

Verdict : option retenue.

### Option D — Fusionner Mouse Time Probe et Playback Playhead

Avantages :

- moins d'elements visuels;
- moins d'etats locaux a afficher.

Limites :

- casse la separation `inspection souris` vs `lecture`;
- rend `clear probe` ambigu;
- risque de faire disparaitre le marqueur d'inspection;
- rend les tests de selection/playback plus flous.

Verdict : refuse.

### Option E — Full scrub partout, y compris barres

Avantages :

- rapide;
- interaction tres directe.

Limites :

- conflit avec selection de bloc;
- conflit avec resize/duration handles;
- risque de muter ou de deselectionner en cherchant seulement a lire;
- trop agressif pour V0.

Verdict : refuse pour V1-120.

## 10. Decision retenue

V1-120 doit implementer :

```text
Option C — Click-to-seek + drag Playback Playhead controle.
```

Regles :

1. Clic sur axe temporel : seek playback.
2. Clic sur fond timeline vide : seek playback.
3. Drag du Playback Playhead : scrub playback.
4. Clic sur une barre : selectionne le bloc, ne seek pas.
5. Drag sur une barre : conserve resize si handle actif; sinon pas de scrub V0.
6. Mouse Time Probe reste inspection-only.
7. Selection Cursor reste selection auteur.
8. Playback Playhead reste temps courant preview.

## 11. Hierarchie hit-test

Priorite V1-120 :

1. TextField / controles inspector / boutons : l'evenement reste au controle.
2. Resize handle de duree : resize existant, pas seek.
3. Timeline Bar : selection/hover existant, pas seek.
4. Playback Playhead handle : drag scrub.
5. Timeline Axis : click seek.
6. Timeline Background vide : click seek.
7. Mouse Time Probe zones existantes : inspection-only; ne pas les utiliser comme seek par defaut.

Comportements :

- clic simple axe/fond : seek local.
- clic simple barre : selection bloc.
- drag playhead : scrub local.
- drag barre sans handle : aucun scrub V0.
- drag handle duration : resize existant.
- double clic : aucun comportement V0.
- clic droit : aucun comportement V0.
- focus clavier : les TextField gardent leurs evenements; la timeline pourra exposer un focus semantique dedie plus tard.
- Escape : doit annuler une interaction drag/scrub en cours si elle existe; ne doit pas reset playback ni clear probe hors decision explicite.

## 12. Interaction Selection Cursor

Decision :

- seek ne selectionne pas automatiquement le bloc actif au temps `t`;
- `selectedStepId` reste stable lors d'un seek axe/fond;
- cliquer une barre conserve le comportement selection auteur;
- l'inspecteur reste sur la selection auteur, pas sur la lecture;
- Selection Cursor reste visible au bloc selectionne, sauf si le Mouse Time Probe existant le masque selon le comportement actuel.

Question critique tranchee : si l'utilisateur seek pendant qu'un autre bloc est selectionne, l'inspecteur ne suit pas la lecture.

## 13. Interaction Mouse Time Probe

Decision :

- Mouse Time Probe ne devient pas scrubber.
- Playback Playhead ne devient pas Mouse Time Probe.
- `clear probe` ne reset pas `playbackTimeMs`.
- Stop/Reset ne clear pas le Mouse Time Probe.
- Clic axe/fond en V1-120 deplace la lecture, pas le Mouse Time Probe.
- Labels distincts : `Repere` / `Marqueur` pour inspection, `Lecture` pour playback.

Risque V1-120 : le code actuel utilise axe/fond pour `onTimelineProbeChanged`; l'implementation devra separer les callbacks sans supprimer les aides existantes.

## 14. Interaction Play/Pause/Stop/Reset

Seek pendant Pause :

- `playbackTimeMs` change localement;
- `playbackPlan.frameAt(playbackTimeMs)` est reevalue;
- l'overlay acteur et l'animation frame se mettent a jour;
- `isPlaybackPlaying` reste `false`;
- statut visible : `Lecture en pause`.

Seek pendant Play :

- clic seek pendant Play repositionne et continue la lecture;
- drag scrub pendant Play met Pause pendant le drag;
- au release, reprend seulement si la lecture etait active avant le drag;
- si l'implementation V1-120 juge ce comportement trop fragile, alternative acceptable : tout seek pendant Play met Pause, mais elle doit etre documentee et testee.

Stop :

- `isPlaybackPlaying = false`;
- `playbackTimeMs = 0`;
- Playback Playhead revient a 0;
- Selection Cursor inchange;
- Mouse Time Probe inchange.

Reset :

- `playbackTimeMs = 0`;
- `isPlaybackPlaying = false`;
- ne lance pas la lecture;
- ne change pas `selectedStepId`;
- ne change pas Mouse Time Probe.

## 15. Snapping

Decision V0 :

- snap aux bornes `0` et `totalDurationMs`;
- snap aux `block.startMs` et `block.endMs`;
- seuil : 8 px, ou seuil deja partage depuis le Mouse Time Probe;
- pas de snap aux ticks en V0;
- pas de snap aux frames d'animation;
- pas de snap aux waypoints actorMove;
- pas de snap runtime.

Justification : les bornes et debuts/fins de blocs sont des cibles auteur stables et lisibles. Les ticks, frames et waypoints creeraient une precision apparente non necessaire au V0.

## 16. Conversion souris -> temps

Source de verite :

- `CinematicTimelineTimeLayoutReadModel`;
- `totalDurationMs`;
- `timeLayout.blocks`;
- largeur de contenu calculee par `_timelineContentWidth`;
- `pixelsPerMs = contentWidth / totalDurationMs`.

Regles :

- utiliser la position locale dans le contenu timeline, pas dans l'ecran global;
- tenir compte du scroll horizontal via le widget/position locale deja dans le contenu scrollable;
- clamp `0..totalDurationMs`;
- round en millisecondes;
- afficher un label no-code avec `_shortTimeLabel`;
- ne pas persister de pixels;
- ne pas recalculer un layout temporel concurrent.

## 17. Mise a jour frame preview

A chaque seek futur, V1-120 devra :

1. mettre a jour le temps local preview;
2. appeler `playbackPlan.frameAt(playbackTimeMs)`;
3. mettre a jour les poses acteurs depuis `actorPoses`;
4. mettre a jour l'animation frame via le resolver/renderer V1-115/V1-116;
5. conserver les diagnostics/fallback details V1-118;
6. ne pas muter `CinematicAsset`;
7. ne pas muter `ProjectManifest`;
8. ne pas muter `MapData`;
9. ne pas toucher runtime, Flame ou GameState.

## 18. UX wording

Wording recommande :

- `Lecture`
- `Deplacer la lecture`
- `Glisser pour parcourir`
- `Cliquez dans le deroule pour previsualiser ce moment`
- `Lecture en pause`
- `Lecture en cours`
- `Retour debut`
- `Lire depuis ce moment`
- `Previsualiser ce moment`

A eviter comme UX principale :

- `playbackTimeMs`
- `seek`
- `scrub`
- `frameAt`
- `activeStepIds`
- `timelineItem`
- `probe`
- `runtime`

## 19. Accessibilite / semantics

Contrat V1-120 :

- handle du Playback Playhead avec label `Tete de lecture`;
- action semantique `Deplacer la lecture`;
- libelle de temps `Temps de lecture`;
- hit target minimal confortable, plus large que la ligne visible;
- impossible de seek depuis un TextField;
- boutons transport gardent leurs labels existants;
- les lecteurs d'ecran doivent distinguer `Repere` et `Lecture`;
- focus clavier ne doit pas voler les champs d'inspecteur.

## 20. Tests futurs V1-120

Tests seek simple :

- clic sur axe deplace `playbackTimeMs`;
- clic sur fond timeline vide deplace `playbackTimeMs`;
- clic sur barre selectionne le bloc et ne seek pas;
- clic hors timeline ne fait rien;
- seek clamp a 0;
- seek clamp a `totalDurationMs`;
- seek respecte le scroll horizontal.

Tests drag scrub :

- drag du Playback Playhead deplace `playbackTimeMs`;
- drag clamp aux bornes;
- drag met la preview a jour;
- release conserve le temps final;
- drag pendant Play applique la regle retenue;
- drag ne modifie pas `selectedStepId`.

Tests Selection Cursor :

- seek ne change pas `selectedStepId`;
- selectionner une barre reste possible;
- Selection Cursor reste au bloc selectionne;
- Playback Playhead bouge independamment.

Tests Mouse Time Probe :

- seek ne cree pas un Mouse Time Probe;
- clear probe ne reset pas `playbackTimeMs`;
- Stop/Reset ne supprime pas Mouse Time Probe;
- `Repere` et `Lecture` restent visibles/distincts si les deux existent.

Tests non-mutation :

- seek ne modifie pas `CinematicAsset`;
- seek ne modifie pas `ProjectManifest`;
- seek ne modifie pas `MapData`;
- seek ne modifie pas manual paths;
- seek ne modifie pas destinations actorMove.

Tests preview :

- seek met a jour actor position depuis `plan.frameAt`;
- seek met a jour animation frame;
- seek met a jour fallback details si applicable;
- seek a 0 revient a pose initiale;
- seek fin montre pose finale stable.

Tests anti-scope :

- pas de runtime/Flame/GameState;
- pas de scrub/seek persiste;
- pas de nouveau plan playback dans `map_editor`;
- pas de recalcul actorMove/manual path.

## 21. Risques

- confusion entre Mouse Time Probe et Playback Playhead;
- clic sur barre qui seek au lieu de selectionner;
- drag conflict avec duration resize handles;
- hit target de playhead trop fin;
- seek pendant Play qui cree un etat incoherent;
- tests flakys si bases sur un ticker reel;
- preview qui bouge mais inspecteur qui ne suit pas, volontaire mais a expliquer;
- wording trop technique;
- comportement non evident pour utilisateur no-code;
- camera/fade pas encore completes en preview playback.

## 22. Non-objectifs confirmes

V1-119 ne fait pas :

- code produit;
- tests Dart/Flutter nouveaux;
- screenshot;
- Visual Gate;
- runtime;
- Flame;
- GameState;
- pathfinding;
- collision;
- interpolation nouvelle;
- scrubber V1-120;
- persistance du temps;
- modification `map_core`;
- modification `map_editor`;
- modification `selbrume`.

## 23. Roadmap proposee

Prochain lot exact recommande :

```text
NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0
```

Suites candidates :

- `NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0`
- `NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract`
- `NS-SCENES-V1-123 — Cinematic Camera Preview Playback V0`

## 24. Commandes executees

Commandes de lecture/audit :

```bash
sed -n '1,260p' /Users/karim/.codex/attachments/6022b656-797b-4759-9d73-eb91b35e7ca1/pasted-text.txt
sed -n '261,520p' /Users/karim/.codex/attachments/6022b656-797b-4759-9d73-eb91b35e7ca1/pasted-text.txt
sed -n '521,1040p' /Users/karim/.codex/attachments/6022b656-797b-4759-9d73-eb91b35e7ca1/pasted-text.txt
sed -n '1041,1560p' /Users/karim/.codex/attachments/6022b656-797b-4759-9d73-eb91b35e7ca1/pasted-text.txt
sed -n '1,220p' AGENTS.md
sed -n '221,520p' AGENTS.md
sed -n '1,260p' agent_rules.md
sed -n '1,220p' codex_rule.md
sed -n '1,220p' skills/README.md
sed -n '1,260p' skills/using-superpowers/SKILL.md
sed -n '1,520p' skills/test-driven-development/SKILL.md
sed -n '1,260p' skills/verification-before-completion/SKILL.md
rg -n "playbackTimeMs|Playback Playhead|Lecture|timelineProbe|Mouse Time Probe|Repère|selectedStepId|Selection|seek|scrub|AnimationController|onTap|onPan|GestureDetector|MouseRegion" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
rg -n "CinematicTimelineTimeLayoutReadModel|startMs|endMs|visualDurationMs|totalDurationMs|timelineProbe|snap|resize|handle" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_core/lib/src/read_models
rg -n "playbackTimeMs|selectedStepId|timelineProbe|ProjectManifest|CinematicAsset|MapData|playhead|Lecture|Repère|seek|scrub" packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart packages/map_core/test/cinematic_preview_playback_plan_test.dart packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
rg -n "Prochain lot exact recommandé|Prochain lot exact recommande|NS-SCENES-V1-119|NS-SCENES-V1-120|NS-SCENES-V1-118" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Tests/analyse/build :

- Non lances par design : V1-119 est `doc-only`; le prompt interdit les tests nouveaux et toute modification de package.
- Validation retenue : `git diff --check` et checks anti-scope.

## 25. Fichiers modifies / crees

Fichiers modifies :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Fichiers crees :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_119_evidence_pack.md
```

Zones modifiees :

- `road_map_scenes.md`
  - Ajout de la ligne `NS-SCENES-V1-119 ... | DONE`.
  - Header `Prochain lot exact recommande` bascule vers `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.
  - Liste d'ordre apres V1-102 ajoute V1-119 DONE et V1-120 recommande/non demarre.
  - Section `Mise a jour V1-119` ajoutee.
  - Mentions historiques recentes du prochain lot global alignees sur V1-120.
  - Raison : fermer le lot documentaire et eviter que la roadmap recommande encore V1-119.
  - Impact attendu : prochain prompt coherent vers V1-120 sans demarrer l'implementation.

- `road_map_scene_builder_authoring.md`
  - Header global bascule vers `NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0`.
  - Ajout d'une ligne roadmap detaillee V1-119.
  - Section `Mise a jour V1-119` ajoutee.
  - Mentions historiques recentes du prochain lot global alignees sur V1-120.
  - Raison : aligner la roadmap authoring avec le rapport V1-119.
  - Impact attendu : V1-120 devient le seul prochain lot recommande; V1-119 reste DONE documentaire.

- `ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md`
  - Rapport principal cree.
  - Zones : Gate 0, fichiers lus, audit playback/timeline, options comparees, decision, hit-test, interactions, snapping, conversion temps, tests futurs, risques, non-objectifs, roadmap, auto-critique, verdict.
  - Raison : cadrer V1-120 avant toute implementation.
  - Impact attendu : contrat seek/scrub suffisamment precis pour coder V1-120 sans ambiguite.

- `ns_scenes_v1_119_evidence_pack.md`
  - Evidence Pack cree.
  - Zones : Gate 0, regles lues, fichiers lus, commandes d'audit, options, decision, fichiers, tests/build non lances, git final, anti-scope, verdict.
  - Raison : fournir les preuves exactes et verifier le scope documentaire.
  - Impact attendu : cloture V1-119 traçable et auditable.

Diff documentaire resume :

```text
road_map_scenes.md : V1-119 DONE, V1-120 prochain, section V1-119 ajoutee.
road_map_scene_builder_authoring.md : V1-119 DONE, V1-120 prochain, ligne/section V1-119 ajoutees.
Rapport V1-119 : nouveau fichier.
Evidence Pack V1-119 : nouveau fichier.
```

## 26. Git final

Les sorties finales exactes sont reprises dans l'Evidence Pack V1-119 apres creation des artefacts et mise a jour des roadmaps.

## 27. Sub-agents / passes separees

- Sub-agent Audit / Architecture : PASS. L'existant montre un playback local editor-only, un plan pur, un Mouse Time Probe local et un Playback Playhead distinct.
- Sub-agent Implementation documentaire : PASS. Le lot est garde doc-only; aucun fichier `packages/`, `examples/`, `assets/` ou `selbrume/` ne doit etre modifie.
- Sub-agent Tests : PASS avec reserve. Aucun test n'est cree ni execute car le prompt l'interdit; les tests futurs V1-120 sont cadres.
- Sub-agent Build / Validation : PASS documentaire. Validation par `git diff --check` et anti-scope final.
- Sub-agent Critique finale : PASS avec risques. Le comportement Play pendant scrub reste le point le plus delicat pour V1-120.

## 28. Auto-critique

Bien tranche :

- distinction Selection Cursor / Mouse Time Probe / Playback Playhead;
- Option C retenue;
- hit-test strict;
- non-mutation;
- next lot V1-120.

Reste risque :

- reutiliser les interactions axe/fond actuellement liees au Mouse Time Probe sans les casser;
- rendre le drag playhead confortable;
- eviter un ticker flaky dans les tests;
- garder le wording no-code assez clair;
- choisir en implementation si seek pendant Play continue ou met Pause si le comportement recommande est trop ambitieux.

Bis documentaire recommande : non, pas necessaire. Le contrat est assez precis pour lancer V1-120.

## 29. Verdict final

```text
NS-SCENES-V1-119 : DONE documentaire.
Scrub / Seek : contrat cadre.
Selection Cursor : reste selection auteur.
Mouse Time Probe : reste inspection-only.
Playback Playhead : devient futur seek/scrub target.
Runtime / Flame / GameState : non touches.
Aucun code produit modifie.
Aucun screenshot.
V1-120 recommande, non demarre.
```

## 30. Prochain lot recommande

```text
NS-SCENES-V1-120 — Cinematic Preview Playback Scrub / Seek UI V0
```

## 31. Contenu complet des fichiers crees

Fichier cree : `reports/narrativeStudio/scenes/ns_scenes_v1_119_cinematic_preview_playback_scrub_seek_prep_contract.md`.

Contenu complet : le present document.

Fichier cree : `reports/narrativeStudio/scenes/ns_scenes_v1_119_evidence_pack.md`.

Contenu complet : voir l'Evidence Pack V1-119, cree dans le meme lot et contenant les sorties exactes de verification.
